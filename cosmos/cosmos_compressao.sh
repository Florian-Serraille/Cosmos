#!/bin/bash

#######################################################################################################################
################################################# Inclusão e Configuração #############################################
#######################################################################################################################

source "${RAIZ}/cosmos_import.sh"

prioridade="ionice -c $IONICE nice -n $NICE"

#######################################################################################################################
######################################################## Função #######################################################
#######################################################################################################################

_compressao_log(){

	_log.log -a 0 -q "Iniciando a compressao dos logs"

	while read registro_banco_dado; do

		_cosmos.ler_variaveis_do_registro "$registro_banco_dado"
		_log.log -a 0 -q "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

		_test_zip
		[ "$?" -ne 0 ] && continue

		_cosmos.get_diretorio_destino_logs

		_log.log -a 0 "Compressao dos logs servidor"
		_compressar_log_srv

		if [ ! "$LOG_APLIC_OUTROS_DIAS" = "-" ]; then
			_log.log -a 0 "Compressao dos logs aplicacao"
			_compressar_log_aplic
		fi

	done < "$BANCO_DE_DADO"

	_log.log -a 0 -q "Fim da compressao dos logs\n"

}

# Verifica se o pacote zip está instalado no host.
# Se não for instalado, atualiza o repositório e instala zip e unzip.
_test_zip(){

	# Testando se Zip está instalado
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "zip -v" > /dev/null

	if [ "$?" -ne 0 ]; then
		_log.log -a 2 "Zip nao instalado"
		_log.log -a 2 "Instalando zip..."
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo apt update && sudo apt install zip unzip -y"

		if [ "$?" -ne 0 ]; then
			_log.log -q -a 4 "Erro ao instalar o pacote zip !"
			return 1
		fi

		return 0
	fi

}

_compressar_log_srv(){

	_cosmos.selecao_regex
	# Procura por arquivos candidato a compressão.
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "ls ${DIRETORIO_DE_DESTINO_LOGS}" > "${TMP_DIR}/tmp$$"
	grep -E "$REGEX" "${TMP_DIR}/tmp$$" > "${TMP_DIR}/arquivos_para_compressao_srv"

	# Adaptar o nivel de alerta em função do tipo de servidor
	if [ $(wc -l "${TMP_DIR}/arquivos_para_compressao_srv" | awk '{print $1}') -eq 0 ]; then
		[ "$SRV" = "tomcat" ] && _log.log -a 3 "Nenhum log servidor a ser compressado"
		[ "$SRV" = "jboss" ] && _log.log -a 2 "Nenhum log servidor a ser compressado"
	fi

	_cosmos.check_duplicados "${DIRETORIO_DE_DESTINO_LOGS}" "${TMP_DIR}/arquivos_para_compressao_srv"
	_check_duplicados_em_zip "${TMP_DIR}/arquivos_para_compressao_srv"
	_zip_arquivos "${TMP_DIR}/arquivos_para_compressao_srv"

}

_compressar_log_aplic(){

	for indice in ${LOG_APLIC_OUTROS_DIAS[@]}; do
		indice=$(basename $indice)
		indice=$(sed s/ANO/$REGEX_ANO/ <<< $indice)
		indice=$(sed s/MES/$REGEX_MES/ <<< $indice)
		indice=$(sed s/DIA/$REGEX_DIA/ <<< $indice)
		indice=$(sed s/HORA/$REGEX_HORA/ <<< $indice) 2> /dev/null

		REGEX="^$indice~?$"
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "ls ${DIRETORIO_DE_DESTINO_LOGS}" > "${TMP_DIR}/tmp$$" 2> /dev/null
		grep -E "$REGEX" "${TMP_DIR}/tmp$$" > "${TMP_DIR}/arquivos_para_compressao_aplic"

		if [ $(wc -l "${TMP_DIR}/arquivos_para_compressao_aplic" | awk '{print $1}') -eq 0 ]; then
			_log.log -a 2 -s "Nenhum arquivo casando com o padrao ${LOG_APLIC_OUTROS_DIAS[$i]}"
			continue
		fi

		_cosmos.check_duplicados "${DIRETORIO_DE_DESTINO_LOGS}" "${TMP_DIR}/arquivos_para_compressao_aplic"
		_check_duplicados_em_zip "${TMP_DIR}/arquivos_para_compressao_aplic"
		_zip_arquivos "${TMP_DIR}/arquivos_para_compressao_aplic"

	done


}

# O proposito desse função comparar os conteudos dos arquivos com nomes iguais no zip e fora do zip
# Se for igual, extrai e concatena os dois, se nao for, apaga a copia do arquivo não zipado
# O comparação é feita pelo tamanho dos arquivos
_check_duplicados_em_zip(){

	# Os nomes de arquivos em "arquivos_para_compressao" são os arquivos em espera de ser zipado e que casam com "REGEX" em "DIRETORIO_DE_DESTINO_LOGS"
	# Para cada um deles, faz:

	arquivos_para_compressao="$1"

	while read arquivo; do

		# Extrai os dados do data do arquivo
		local dataDoArquivo=$(grep -Eo "$REGEX_DATA" <<< "$arquivo")
		local anoArquivo=$(cut -d "-" -f 1 <<< $dataDoArquivo)
		local mesArquivo=$(cut -d "-" -f 2 <<< $dataDoArquivo)

		tamanho_arquivo_zipado=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip -qql ${DIRETORIO_DE_DESTINO_LOGS}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip ${arquivo}" 2>/dev/null)
		tamanho_arquivo_zipado=$(awk '{print $1}' <<< $tamanho_arquivo_zipado)
		if [ -n "$tamanho_arquivo_zipado" ]; then

			_log.log -a 1 "Arquivo ${arquivo} ja existente em ${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip"
			tamanho_arquivo_nao_zipado=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo wc -m ${DIRETORIO_DE_DESTINO_LOGS}/${arquivo}")
			tamanho_arquivo_nao_zipado=$(awk '{print $1}' <<< $tamanho_arquivo_nao_zipado)
			_log.log "Tamanho dos arquivos: ${tamanho_arquivo_nao_zipado} chars. e ${tamanho_arquivo_zipado} chars."

			if [ "$tamanho_arquivo_zipado" -eq "$tamanho_arquivo_nao_zipado" ]; then

				# Arquivos zipados e nao zipados com conteúdo igual
				_log.log "Arquivos iguais, supressao do arquivo nao zipado."
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo rm -v ${diretorio}/${arquivo}")
				_log.log "$info"

			else

				# Arquivos zipados e nao zipados com conteúdo diferente
				_log.log "Arquivos diferentes, unzip e concatenacao dos dois."
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip -B ${DIRETORIO_DE_DESTINO_LOGS}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip ${arquivo} -d ${DIRETORIO_DE_DESTINO_LOGS}")
				_log.log "$info"
				ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo bash -c 'cat ${DIRETORIO_DE_DESTINO_LOGS}/${arquivo}~ >> ${DIRETORIO_DE_DESTINO_LOGS}/${arquivo}'"
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo rm -v ${diretorio}/${arquivo}~")
				_log.log "$info"

			fi
		fi
	done <	"$arquivos_para_compressao"

}

_zip_arquivos(){

	arquivos_para_compressao="$1"

	while read arquivo; do

		# Extraire les dates et tester l existance du zip puis s il exite du fichier dans le zip
		local dataDoArquivo=$(grep -Eo "$REGEX_DATA" <<< "$arquivo")
		local anoArquivo=$(cut -d "-" -f 1 <<< $dataDoArquivo)
		local mesArquivo=$(cut -d "-" -f 2 <<< $dataDoArquivo)

		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "${prioridade} sudo zip -jTm ${DIRETORIO_DE_DESTINO_LOGS}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip ${DIRETORIO_DE_DESTINO_LOGS}/${arquivo}")
		[ "$?" -ne 0 ] && _log.log -a 3 -s "Conteudo differente: concatenacao dos arquivos ${arquivo}"
		info=$(sed s/%/\ percent/ <<< $info)
		_log.log "Zip de ${arquivo} em ${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip"
		_log.log "$info"

	done <	"$arquivos_para_compressao"
}

#######################################################################################################################
######################################################### Main ########################################################
#######################################################################################################################

_log.relatorio -a

_cosmos.is_sessao_critica

if [ "$?" -eq 1 ]; then
	_log.log -a 4 "Sessao critica: Existe um processo concorrente."
	_log.relatorio -f
	exit 1
fi

_compressao_log
_log.relatorio -f
exit 0
