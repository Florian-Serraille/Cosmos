#!/bin/bash

#######################################################################################################################
################################################# Inclusão e Configuração #############################################
#######################################################################################################################

source "${RAIZ}/cosmos_import.sh"

banco_de_dado_tmp="${TMP_DIR}/db_tmp"

#######################################################################################################################
######################################################## Função #######################################################
#######################################################################################################################

_rotacao_log(){

	_log.log -a 0 -q "$ROTACAO_1"

	########################################## Execução asíncrono da rotação ##############################################

	# O seguinte trecho está encarregado de cuidar da rotação dos arquivos catalina.out das instancias tomcat
	# Conferimos se existe instancia tomcat no DB aplicando um filtro nela. Se houver, então criamos para cada uma
	# dela um thread que copia o arquivo original, esvazia-lo e renomea o novo arquivo na forma catalina.ANO-MES-DIA.log
	# O uso das threads garante que a rotação será efetuada no tempo ~exato da execução (por padrão 00:00, cf crontab).

	if [ "$catalina" -eq 1 ]; then

		grep "tomcat" "$BANCO_DE_DADO" > "$banco_de_dado_tmp"

		if [ $(wc -l "$banco_de_dado_tmp" | awk '{print $1}') -ge 1 ]; then

			_log.log -a 0 -q "$ROTACAO_2"

			local ARRAY_DE_PID

			while read registro; do

				_cosmos.ler_variaveis_do_registro "$registro"
				export LOG_APLIC_OUTROS_DIAS

				_log.log -a 0 -q "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

				_make_diretorio_destino

				# Criação de um processo asíncrono
				# O argumento --catalina provoca a rotação dos arquivos catalina.out apenas
				"${RAIZ}/cosmos_rotacao_thread.sh" &

				# O PID do processo é armazendo no vetor ARRAY_DE_PID
				ARRAY_DE_PID[${#ARRAY_DE_PID[@]}]="$!"
				_log.log "${ROTACAO_3} $!"

			done < "$banco_de_dado_tmp"

			# Laço de sincronização que espera pelo útlimo processo asíncrono solto acabar
			for (( pid=0; pid < ${#ARRAY_DE_PID[@]}; pid++ )); do
				wait ${ARRAY_DE_PID[${pid}]}
			done

			# Junta os arquivos de logs de cada pid's no arquivo de log de processo pai
			_log.relatorio -j "$ARRAY_DE_PID"
			_log.log -a 0 -q "$ROTACAO_4"

		fi

	fi
	################################ Execução síncrono da rotação com thread única ########################################

	_log.log -a 0 -q "$ROTACAO_5"

	while read registro; do

		_cosmos.ler_variaveis_do_registro "$registro"

		_log.log -a 0 -q "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

		_make_diretorio_destino

		_log.log -a 0 "Rotacao dos logs servidor"
		_rotacao_logs_srv

		if [ ! "$LOG_APLIC_OUTROS_DIAS" = "-" ]; then
			_log.log -a 0 "Rotacao dos logs aplicacao"
			_rotacao_logs_aplic
		fi

	done < "$BANCO_DE_DADO"

	_log.log -a 0 -q "$ROTACAO_6"

	_log.log -a 0 -q "$ROTACAO_7"

}

_make_diretorio_destino(){

	# Se o retorno da função é 1, então esse tipo de servidor não produz log de servidor.
	_cosmos.get_diretorio_de_origem_log_servidor
	[ "$?" -eq 1 ] && return 1

	_cosmos.get_diretorio_destino_logs

	# Conferindo se o diretório de destinho dos logs existe, se não, criamos-lo.
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "[ -d ${DIRETORIO_DE_DESTINO_LOGS} ]"
	if [ "$?" -ne 0 ]; then
		_log.log "$ROTACAO_CONSTRUCAO_DESTINO ${DIRETORIO_DE_DESTINO_LOGS}"
		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mkdir -vp ${DIRETORIO_DE_DESTINO_LOGS}")
		_log.log "$info"
	fi
}

# Procura pelos arquivos de logs srv marcados com o formato do dia em $DIRETORIO_DE_ORIGEM_LOG_SERVIDOR
# e move ele até o diretório de armazenamento $DIRETORIO_DE_DESTINO_LOGS.
_rotacao_logs_srv(){

	[ "$lista_arquivos" ] && unset lista_arquivos

	_cosmos.selecao_regex

	lista_arquivos=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo ls $DIRETORIO_DE_ORIGEM_LOG_SERVIDOR")
	lista_arquivos=$(tr " " "\n" <<< $lista_arquivos | grep -E "$REGEX"  )

	# A ausência de arquivo de log formatado com a data em $DIRETORIO_DE_ORIGEM_LOG_SERVIDOR é considerado warning para Jboss, crítico para Tomcat. (catalina.out é gerado todo dia)
	if [ $(wc -w <<< "$lista_arquivos") -eq 0 ]; then

		[ "$SRV" = "jboss" ] && _log.log -a 2 -s "Nenhum arquivo a rotacionar"
		[ "$SRV" = "tomcat" ] && _log.log -a 3 -s "Nenhum arquivo a rotacionar"

	fi

	for arquivo in $lista_arquivos; do

		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mv -bv ${DIRETORIO_DE_ORIGEM_LOG_SERVIDOR}/${arquivo} ${DIRETORIO_DE_DESTINO_LOGS}")
		retorno=$?
		_log.log "$info"
		[ "$retorno" -ne 0 ] && _log.log -a 3 -s "Ocorreu um erro no rotacao"

	done

	return 0
}

_rotacao_logs_aplic(){

	for indice in ${LOG_APLIC_OUTROS_DIAS[@]}; do

		indice=$(sed s/ANO/$REGEX_ANO/ <<< $indice)
		indice=$(sed s/MES/$REGEX_MES/ <<< $indice)
		indice=$(sed s/DIA/$REGEX_DIA/ <<< $indice)
		indice=$(sed s/HORA/$REGEX_HORA/ <<< $indice) 2> /dev/null

		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "ls $(dirname ${indice})" > "${TMP_DIR}/tmp$$" 2> /dev/null
		if [ "$?" -ne 0 ]; then
			_log.log -a 3 -s "Diretorio indicado pela variavel 'LOG_APP_OUTROS_DIAS' inexistante ($(dirname ${indice}))"
			continue
		fi

		dir=$(dirname $indice)
		REGEX="^$(basename "$indice")$"
		grep -E "$REGEX" "${TMP_DIR}/tmp$$" > "${TMP_DIR}/rotacao_logs_aplic"
		if [ $(wc -l "${TMP_DIR}/rotacao_logs_aplic" | awk '{print $1}') -eq 0 ]; then
			_log.log -a 2 -s "Nenhum arquivo casando com o padrao ${LOG_APLIC_OUTROS_DIAS[$i]}"
			continue
		fi

		while read arquivo; do

			info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mv -bv ${dir}/${arquivo} ${DIRETORIO_DE_DESTINO_LOGS}")
			retorno=$?
			_log.log "$info"
			[ "$retorno" -ne 0 ] && _log.log -a 3 -s "Ocorreu um erro no rotacao"

		done <	"${TMP_DIR}/rotacao_logs_aplic"

	done

}

#######################################################################################################################
########################################################    Main    ###################################################
#######################################################################################################################

if [ "$1" = "--catalina" ]; then
	catalina=1
else
	catalina=0
fi

_log.relatorio -a

_cosmos.is_sessao_critica
if [ "$?" -eq 1 ]; then
	_log.log -a 4 "Sessao critica: Existe um processo concorrente."
	_log.relatorio -f
	exit 1
fi

_rotacao_log
_log.relatorio -f

exit 0
