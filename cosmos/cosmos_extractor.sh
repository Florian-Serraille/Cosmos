#!/bin/bash

source "${RAIZ}/cosmos_import.sh"

function _check_part_mount(){

	if [ ! -d "$EXTRACTOR_PARTITION" ]; then
		_dialog.wipe
		echo "Partição $(basename "$EXTRACTOR_PARTITION") não montada, entrar em contato com a Infra (ramais: 9825/8952)" > "${TMP_DIR}/dialog_message"
		_dialog.msgbox

		exit 1
	fi
}

# O usuário escolha a(s) aplicação(ões)
function _app(){
	
	_dialog.wipe
    echo -e " Escolha uma ou mais aplicacoes " > "${TMP_DIR}/dialog_title"
    echo " " > "${TMP_DIR}/dialog_message"
	_db.ler_campo "1" | sort -u > "${TMP_DIR}/dialog_tags"
    _dialog.buildlist
    _check_exit
    EXTRACTOR_APP="$DIALOG_ESCOLHA"
    
    if  test -z "$EXTRACTOR_APP"; then
    	_dialog.wipe
        echo " Erro " > "${TMP_DIR}/dialog_title"
        echo -e "\nEscolha pelo menos uma aplicacao\n" > "${TMP_DIR}/dialog_message"
        _dialog.msgbox
        _app
    fi
}

function _check_exit(){
    if [ "$EXTRACTOR_EXIT_STATUS" -eq 1 ]; then                                                                                                                                                                                        
        exit 1
    fi
}

function _data(){
  
	_dialog.wipe
	echo " Calendario " > "${TMP_DIR}/dialog_title"
	echo -e "\nEscolhe a data dos logs desejado.\nEscolher 'Intervalo' para obter um range de data." > "${TMP_DIR}/dialog_message"
	echo "Intervalo" > "${TMP_DIR}/dialog_extra_button"
	_dialog.calendar
	_check_exit
	EXTRACTOR_DATA="$DIALOG_ESCOLHA"

	# Extra button return 3
	intervalo=1
	if [ "$EXTRACTOR_EXIT_STATUS" -eq 3 ]; then
		_dialog.wipe
		echo " Calendario " > "${TMP_DIR}/dialog_title"
		echo -e "\nPrimeira data : ${EXTRACTOR_DATA}.\nEscolhe segunda data para formar o intervalo." > "${TMP_DIR}/dialog_message"
		_dialog.calendar
		_check_exit
		EXTRACTOR_DATA_INTERVALO="$DIALOG_ESCOLHA"
		intervalo=0
	fi

	# Controle de validade da ou das datas
	local validade=0
	[ "$(date -d ${EXTRACTOR_DATA} +%Y%m%d)" -gt "$(date +%Y%m%d)" ] && validade=1
	if [ "$intervalo" -eq 0 ]; then
		[ "$(date -d ${EXTRACTOR_DATA_INTERVALO} +%Y%m%d)" -gt "$(date +%Y%m%d)" ] && validade=1
		if [ "$(date -d ${EXTRACTOR_DATA} +%Y%m%d)" -gt "$(date -d ${EXTRACTOR_DATA_INTERVALO} +%Y%m%d)" ]; then
			local tmp_date="$EXTRACTOR_DATA"
			EXTRACTOR_DATA="$EXTRACTOR_DATA_INTERVALO"
			EXTRACTOR_DATA_INTERVALO="$tmp_date"
		fi
	fi
	
	if [ "$validade" -eq 1 ]; then
		_dialog.wipe
	    echo " Erro " > "${TMP_DIR}/dialog_title"
	    echo -e "\nData: ${EXTRACTOR_DATA}$([ ${intervalo} -eq 0 ] && echo -e " ate ${EXTRACTOR_DATA_INTERVALO}")\n\nData posterior ao dia de hoje\n\n " > "${TMP_DIR}/dialog_message"
	    _dialog.msgbox
		_data
	else
		_dialog.wipe
		echo " Confirmar data ? " > "${TMP_DIR}/dialog_title"
		echo -e "\nData: ${EXTRACTOR_DATA}$([ ${intervalo} -eq 0 ] && echo -e " ate ${EXTRACTOR_DATA_INTERVALO}")\n " > "${TMP_DIR}/dialog_message"
		echo -e "Redefinir" > "${TMP_DIR}/dialog_no"
		_dialog.yes_no
		[ "$DIALOG_ESCOLHA" -eq 1 ] && _data
	fi
}

function _log(){

	_dialog.wipe
	echo " Tipo de log " > "${TMP_DIR}/dialog_title"
	echo -e "\nSelecione o tipo de log:\n " > "${TMP_DIR}/dialog_message"
	echo "Servidor Aplicacao" > "${TMP_DIR}/dialog_tags"
	_dialog.checklist
	_check_exit

	EXTRACTOR_TIPO_LOG="$DIALOG_ESCOLHA"

	if [ "$DIALOG_ESCOLHA" = "Servidor Aplicacao" ]; then
		EXTRACTOR_TIPO_LOG_CODE=0
	elif [ "$DIALOG_ESCOLHA" = "Servidor" ]; then
		EXTRACTOR_TIPO_LOG_CODE=1
	elif [ "$DIALOG_ESCOLHA" = "Aplicacao" ]; then
		EXTRACTOR_TIPO_LOG_CODE=2
	else
		EXTRACTOR_TIPO_LOG_CODE=-1		
		_dialog.wipe
		echo " Erro " > "${TMP_DIR}/dialog_title"
		echo -e "\nEscolha pelo menos um tipo de log\n" > "${TMP_DIR}/dialog_message"
	    _dialog.msgbox
		_log
	fi

}

function _ambiente(){

	_dialog.wipe
	echo " Ambiente " > "${TMP_DIR}/dialog_title"
	echo -e "\nSelecione o ambiente:\n " > "${TMP_DIR}/dialog_message"
	echo "Producao Homologacao" > "${TMP_DIR}/dialog_tags"
	_dialog.checklist
	_check_exit

	EXTRACTOR_AMBIENTE="$DIALOG_ESCOLHA"
	
	if [ "$DIALOG_ESCOLHA" = "Producao Homologacao" ]; then
		EXTRACTOR_AMBIENTE_CODE=0
	elif [ "$DIALOG_ESCOLHA" = "Producao" ]; then
		EXTRACTOR_AMBIENTE_CODE=1
	elif [ "$DIALOG_ESCOLHA" = "Homologacao" ]; then
		EXTRACTOR_AMBIENTE_CODE=2
	else
		EXTRACTOR_AMBIENTE_CODE=-1		
		_dialog.wipe
		echo " Erro " > "${TMP_DIR}/dialog_title"
		echo -e "\nEscolha pelo menos um ambiente\n" > "${TMP_DIR}/dialog_message"
	    _dialog.msgbox
		_ambiente
	fi


}

function _montar_resumo(){
	cat > "${TMP_DIR}/dialog_message" <<- EOF

		* Aplicacao: $(echo -e "\n ")
		$(for app in $(echo $EXTRACTOR_APP); do echo -e "\t ${app}"; done)
		$(echo -e "\n ")* Data: $(echo -e "\n ")
		$(echo -e "\t $EXTRACTOR_DATA") $([ $intervalo -eq 0 ] && echo "ate $EXTRACTOR_DATA_INTERVALO")
		$(echo -e "\n ")* Tipo de log: $(echo -e "\n ")
		$(for tipo in $(echo $EXTRACTOR_TIPO_LOG); do echo -e "\t ${tipo}"; done)
		$(echo -e "\n ")
	EOF
}
		#$(echo -e "\n ")* Ambiente: $(echo -e "\n ")
		#$(for ambiente in $(echo $EXTRACTOR_AMBIENTE); do echo -e "\t ${ambiente}"; done)

function _resumo(){

	_dialog.wipe

	_montar_resumo

	echo " Resumo " > "${TMP_DIR}/dialog_title"
	echo "Baixar" > "${TMP_DIR}/dialog_yes"
	echo "Cancelar" > "${TMP_DIR}/dialog_no"
	_dialog.yes_no
	EXTRACTOR_TIPO_LOG="$DIALOG_ESCOLHA"

	[ "$DIALOG_ESCOLHA" -ne 0 ] && exit 0
			
}

_criacao_diretorio_destino(){

	destino="${EXTRACTOR_PARTITION}/${SUDO_USER}/$(date +%Y-%m-%d_%H-%M)"
	destino_usuario="$(basename ${EXTRACTOR_PARTITION})/${SUDO_USER}/$(date +%Y-%m-%d_%H-%M)"

	if [ ! -d "$destino" ]; then
		_log.log -a 3 "Criando diretorio em ${destino}"
		mkdir -p "$destino"
	fi
}


_obtencao_registros(){
	
	# Selecionando os registros correspondante às aplicações desejadas.
	_cosmos.filtra_db "$EXTRACTOR_APP"
	
	# Filtro por ambientes
	#if [ "$EXTRACTOR_AMBIENTE_CODE" -eq 1 ]

}

_extrair_logs_outros_dias(){
	

	_cosmos.selecao_regex

	REGEX_BASE=$(sed s/ANO-MES-DIA/$(date "-d ${data}" +%Y-%m-%d)/ <<< $REGEX_BASE)
	REGEX_BASE=$(sed s/HORA/${REGEX_HORA}/ <<< $REGEX_BASE)

	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "test -e $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date "-d $data" +%Y-%m).zip"
	if [ "$?" -ne 0 ]; then
		_log.log -a 2 "Nenhum arquivo de log se encontra para a aplicacao ${SISTEMA} no mes de $(date "-d $data" +%h%Y)"
		return 1
	fi

	# Obtenção dos logs servidor

	> "${TMP_DIR}/arquivos_log_encontrados"

	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip -lqq $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date "-d $data" +%Y-%m).zip" > "${TMP_DIR}/tmp"
	
 	awk '{print $4}' "${TMP_DIR}/tmp" | grep -E "$REGEX_BASE" > "${TMP_DIR}/arquivos_log_encontrados"
	if [ -s "${TMP_DIR}/arquivos_log_encontrados" ]; then
 		while read arquivo_encontrado; do
			info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date "-d $data" +%Y-%m).zip ${arquivo_encontrado} -d ${EXTRACTOR_TMP_DIRECTORY}")
			_log.log "$info"
		done < "${TMP_DIR}/arquivos_log_encontrados"
	else
		_log.log -a 3 "Nenhum log servidor encontrado"
	fi


	# Obtenção dos logs de aplicação

	if [ "$LOG_APLIC_OUTROS_DIAS" != "-" ]; then

		for indice in ${LOG_APLIC_OUTROS_DIAS[@]}; do
			indice=$(sed s/ANO/$(date "-d $data" +%Y)/ <<< $indice) 
			indice=$(sed s/MES/$(date "-d $data" +%m)/ <<< $indice) 
			indice=$(sed s/DIA/$(date "-d $data" +%d)/ <<< $indice) 
			indice=$(sed s/HORA/*/ <<< $indice) 2> /dev/null 

			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip -l $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date "-d $data" +%Y-%m).zip $(basename ${indice})" > /dev/null	
			if [ "$?" -eq 0 ]; then
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date "-d $data" +%Y-%m).zip $(basename ${indice}) -d ${EXTRACTOR_TMP_DIRECTORY}")
				_log.log "$info"
			else
				_log.log -a 3 "Nao foi encontrado arquivo $(basename ${indice}) para esta o dia $(date -d $data +%Y-%m-%d)"
			fi

		done
	fi

}

_prepara_host(){

	# Criando diretorio temporario no host
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "test -d ${EXTRACTOR_TMP_DIRECTORY}"
	if [ "$?" -ne 0 ]; then
		_log.log -a 3 "Criando diretorio temporario no host"
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "mkdir ${EXTRACTOR_TMP_DIRECTORY}"
	fi

}

_compressar_logs(){

	_log.log -a 3 "Criacao de um zip dos arquivos extraidos"

	numero_arquivos=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo ls ${EXTRACTOR_TMP_DIRECTORY} | wc -l")

	if [ "$numero_arquivos" -gt 0 ]; then
		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo zip -jTm ${EXTRACTOR_TMP_DIRECTORY}/${SISTEMA}_${HOST}.zip ${EXTRACTOR_TMP_DIRECTORY}/* ")
		info=$(sed s/%/\ percent/ <<< $info)
		_log.log "$info"
		return 0
	else
		_log.log -a 3 "Nao ha arquivo para criar zip"
		return 1
	fi

}

_baixar_logs(){

	_log.log -a 3 "Transferindo o zip para o diretorio destino na particao compartilhada '${destino_usuario}' (@${COSMOS_HOST})"
	scp -pi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST":${EXTRACTOR_TMP_DIRECTORY}/${SISTEMA}_${HOST}.zip ${destino}
	if [ "$?" -eq 0 ]; then
		_log.log -a 2 "Arquivo transferido com sucesso"
	else
		_log.log -a 2 "Erro ao transferir o zip"
	fi

	_log.log -a 3 "Apagando os arquivos extraidos em ${HOST}"
	#set -x
	info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo rm -vrf ${EXTRACTOR_TMP_DIRECTORY}")
	#ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo rm -vrf ${EXTRACTOR_TMP_DIRECTORY}"
	_log.log "$info"
	#set +x

}

_extrair_logs_hoje(){

	_log.log -a 3 -p "> " "Obtencao dos logs do dia $(date "-d $data" +%Y-%m-%d)"

	# LOG SERVIDOR

	_cosmos.caminho_origem_log
	_cosmos.selecao_regex

	REGEX_BASE=$(sed s/ANO-MES-DIA/$(date +%Y-%m-%d)/ <<< $REGEX_BASE)
	REGEX_BASE=$(sed s/HORA/${REGEX_HORA}/ <<< $REGEX_BASE)

	### LOG SEM ROTAÇÂO NO DIRETORIO DE ORIGEM

	[ "$lista_arquivos" ] && unset lista_arquivos

	lista_arquivos=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo ls $LOG_ORIGEM")  
	lista_arquivos=$(tr " " "\n" <<< $lista_arquivos | grep -E "$REGEX_SEM_ROTACAO"  )

	if [ $(wc -w <<< "$lista_arquivos") -eq 0 ]; then
		[ "$SRV" = "jboss" ] && _log.log -a 3 -s "Aviso: Nenhum arquivo a rotacionar"
		[ "$SRV" = "tomcat" ] && _log.log -a 2 -s "Critico: Nenhum arquivo a rotacionar"
	fi

	for arquivo in $lista_arquivos; do

		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo cp -bv ${LOG_ORIGEM}/${arquivo} ${EXTRACTOR_TMP_DIRECTORY}") 
		retorno=$?
	 	_log.log "$info"

	 	if [ "$retorno" -ne 0 ]; then
	 		_log.log -a 2 -s "Erro: Ocorreu um erro no rotacao"
	 		return 1
	 	fi

	done

	### LOG COM ROTAÇÂO NO DIRETORIO DE ORIGEM

	[ "$lista_arquivos" ] && unset lista_arquivos

	lista_arquivos=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo ls $LOG_ORIGEM")  
	lista_arquivos=$(tr " " "\n" <<< $lista_arquivos | grep -E "$REGEX_BASE"  )

	for arquivo in $lista_arquivos; do

		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo cp -bv ${LOG_ORIGEM}/${arquivo} ${EXTRACTOR_TMP_DIRECTORY}") 
	 	_log.log "$info"

	done

	### LOG COM ROTAÇÂO NO DIRETORIO DO ZIP

	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "test -e $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date +%Y-%m).zip"
	if [ "$?" -eq 0 ]; then

		> "${TMP_DIR}/arquivos_log_encontrados"

		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip -lqq $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date +%Y-%m).zip" > "${TMP_DIR}/tmp"
			
		awk '{print $4}' "${TMP_DIR}/tmp" | grep -E "$REGEX_BASE" > "${TMP_DIR}/arquivos_log_encontrados"
		if [ -s "${TMP_DIR}/arquivos_log_encontrados" ]; then
			while read arquivo_encontrado; do
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date +%Y-%m).zip ${arquivo_encontrado} -d ${EXTRACTOR_TMP_DIRECTORY}")
				_log.log "$info"
			done < "${TMP_DIR}/arquivos_log_encontrados"
		fi
	fi

	# LOG DE APLICAÇÂO 

	### LOG SEM ROTAÇÂO NO DIRETORIO DE ORIGEM

	if [ "$LOG_APLIC_HOJE" != "-" ]; then

		for indice in ${LOG_APLIC_HOJE[@]}; do

			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo test -e ${indice}" > /dev/null	
			if [ "$?" -eq 0 ]; then
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo cp -v ${indice} ${EXTRACTOR_TMP_DIRECTORY}")
				_log.log "$info"
			else
				_log.log -a 3 "Nao foi encontrado arquivo $(basename ${indice}) pro dia $(date -d $data +%Y-%m-%d)"
			fi
		
		done 
	fi

	### LOG COM ROTAÇÂO NO DIRETORIO DE ORIGEM

	if [ "$LOG_APLIC_OUTROS_DIAS" != "-" ]; then

		for indice in ${LOG_APLIC_OUTROS_DIAS[@]}; do
			indice=$(sed s/ANO/$(date +%Y)/ <<< $indice) 
			indice=$(sed s/MES/$(date +%m)/ <<< $indice) 
			indice=$(sed s/DIA/$(date +%d)/ <<< $indice) 
			indice=$(sed s/HORA/*/ <<< $indice) 2> /dev/null 

			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo test -e ${indice}" > /dev/null	
			if [ "$?" -eq 0 ]; then
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo cp -v ${indice} ${EXTRACTOR_TMP_DIRECTORY}")
				_log.log "$info"
			fi

		done
	fi

	### LOG COM ROTAÇÂO NO DIRETORIO DO ZIP

	if [ "$LOG_APLIC_OUTROS_DIAS" != "-" ]; then

		for indice in ${LOG_APLIC_OUTROS_DIAS[@]}; do
			indice=$(sed s/ANO/$(date "-d $data" +%Y)/ <<< $indice) 
			indice=$(sed s/MES/$(date "-d $data" +%m)/ <<< $indice) 
			indice=$(sed s/DIA/$(date "-d $data" +%d)/ <<< $indice) 
			indice=$(sed s/HORA/*/ <<< $indice) 2> /dev/null 

			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo test -e $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date +%Y-%m).zip && sudo unzip -l $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date +%Y-%m).zip $(basename ${indice})" > /dev/null	
			if [ "$?" -eq 0 ]; then
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip $(dirname ${RAIZ_SRV})/logs/${SISTEMA}/${SISTEMA}.log.$(date +%Y-%m).zip $(basename ${indice}) -d ${EXTRACTOR_TMP_DIRECTORY}")
				_log.log "$info"
			fi

		done
	fi


}

##### MAIN #####

# Controle
_check_part_mount

# Aquisição de informação
_app
_data
_log
#_ambiente
_resumo

clear

# Aquisição dos logs
_log.relatorio -a

_log.log -a 1 -q -p ">>> " "Iniciando a extracao do logs (Usuario: ${SUDO_USER})"

_criacao_diretorio_destino
_obtencao_registros

[ "$intervalo" -eq 1 ] && EXTRACTOR_DATA_INTERVALO="$EXTRACTOR_DATA"

while read registro; do

	_cosmos.ler_variaveis_do_registro "$registro"
	_log.log -a 3 -p ">> " "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

	_prepara_host

	for (( data=$(date "-d ${EXTRACTOR_DATA}" +%Y%m%d) ; (data <= $(date "-d -1day" +%Y%m%d)) && (data <= $(date "-d ${EXTRACTOR_DATA_INTERVALO}" +%Y%m%d)); data=$(date "-d $data +1day" +%Y%m%d) )); do 
		_log.log -a 3 -p "> " "Obtencao dos logs do dia $(date "-d $data" +%Y-%m-%d)"
 		_extrair_logs_outros_dias
	done

	[ $(date "-d ${EXTRACTOR_DATA_INTERVALO}" +%Y%m%d) = $(date +%Y%m%d) ] && _extrair_logs_hoje

	_compressar_logs
	[ "$?" -eq 0 ] && _baixar_logs

done < "$TMP_DIR/bd_tmp2"

_log.log -a 1 -q -p ">>> " "Fim da extracao do logs"
_log.relatorio -f