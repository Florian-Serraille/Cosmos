#!/bin/bash

## Pensar no caso de duas compressoes no mesmo dia, a segunda vai sobreescrever a primeira

source "${RAIZ}/cosmos_import.sh"

_compressao_logs(){

	_log -a 1 -q -p ">>> " "Iniciando a compressao dos logs"

	prioridade="ionice -c $IONICE nice -n $NICE"

	while read registro; do

		 _ler_variaveis_do_registro "$registro"

		_log -a 3 -p "> " "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

		_construcao_caminho_compressao

		_selecao_regex

		_log -a 3 -p ">> " "Compressao dos logs servidor"

		_compressar_logs_srv

		if [ ! "$LOG_APLIC" = "-" ]; then

			_log -a 3 -p ">> " "Compressao dos logs aplicacao"
			_compressar_logs_aplic

		fi
		
	done < "$BANCO_DE_DADO"

	_log -a 1 -q -p ">>> " "Fim da compressao dos logs"
}

_construcao_caminho_compressao(){

	CAMINHO_DESTINO="$(dirname ${RAIZ_SRV})/logs/${SISTEMA}"

	# Conferindo se o caminho de destinho dos logs existe, se não criar-lo
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "[ -d ${CAMINHO_DESTINO} ]"
	if [ "$?" -ne 0 ]; then
		_log "Criacao do diretorio ${CAMINHO_DESTINO}"
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mkdir -p ${CAMINHO_DESTINO}"
	fi
}

_compressar_logs_srv(){

	# Testando se Zip está instalado
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "zip -v > /dev/null"
	if [ "$?" -ne 0 ]; then
		_log -a 2 "Zip nao instalado"		
		_log -a 3 "Instalando zip..."		
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo apt update && sudo apt install zip -y"
		[ "$?" -ne 0 ] && return 1
	fi	

	# Compressão logs servidor

	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "ls ${CAMINHO_DESTINO}" > "${TMP_DIR}/tmp"
	grep -E "$REGEX" "${TMP_DIR}/tmp" > "${TMP_DIR}/arquivos_para_compressao"
	
	if [ $(wc -l "${TMP_DIR}/arquivos_para_compressao" | awk '{print $1}') -eq 0 ]; then
		_log -a 3 "Warning: Nenhum log servidor para compressar"
		return 1
	fi

	_confira_duplicado

	while read arquivo; do
		
		# Extraire les dates et tester l existance du zip puis s il exite du fichier dans le zip
		local dataDoArquivo=$(grep -Eo "$REGEX_DATA" <<< "$arquivo")
		
		local anoArquivo=$(cut -d "-" -f 1 <<< $dataDoArquivo)
		local mesArquivo=$(cut -d "-" -f 2 <<< $dataDoArquivo)

		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "test -f ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip"

		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "${prioridade} sudo zip -jTm ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip ${CAMINHO_DESTINO}/${arquivo}")
		[ "$?" -ne 0 ] && _log -a 2 -s "[ Erro: Arquivo: ${arquivo} ] Erro ao compressar"
		info=$(sed s/%/\ percent/ <<< $info)
		_log "$info"
	
	done <	"${TMP_DIR}/arquivos_para_compressao" 	

}

_compressar_logs_aplic(){

	for indice in ${LOG_APLIC[@]}; do

		indice=$(sed s/ANO/$REGEX_ANO/ <<< $indice) 
		indice=$(sed s/MES/$REGEX_MES/ <<< $indice) 
		indice=$(sed s/DIA/$REGEX_DIA/ <<< $indice) 
		indice=$(sed s/HORA/$REGEX_HORA/ <<< $indice) 2> /dev/null 

		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "ls $(dirname ${indice})" > "${TMP_DIR}/tmp" 2> /dev/null
		if [ "$?" -ne 0 ]; then
			_log -a 2 -s "[ Erro: Log de aplicacao: ${arquivo} ] Diretorio inexistante"
			continue
		fi

		REGEX="^$(basename "$indice")$"
		grep -E "$REGEX" "${TMP_DIR}/tmp" > "${TMP_DIR}/arquivos_para_compressao"
		
		if [ $(wc -l "${TMP_DIR}/arquivos_para_compressao" | awk '{print $1}') -eq 0 ]; then
			_log -a 3 -s "[ Aviso: Log de aplicacao: ${arquivo} ] Nenhum arquivo correspondente"
			continue
		fi

		while read arquivo; do

			local dataDoArquivo=$(grep -Eo "$REGEX_DATA" <<< "$arquivo")
			local anoArquivo=$(cut -d "-" -f 1 <<< $dataDoArquivo)
			local mesArquivo=$(cut -d "-" -f 2 <<< $dataDoArquivo)

			info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "${prioridade} sudo zip -jTm ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip $(dirname ${indice})/${arquivo}")
			[ "$?" -ne 0 ] && _log -a 2 -s "[ Erro: Arquivo: ${arquivo} ] Erro ao compressar os logs de aplicacao"
			info=$(sed s/%/\ percent/ <<< $info)
			_log "$info"

		done <	"${TMP_DIR}/arquivos_para_compressao"

	done
}

_selecao_regex(){

        if [ "$SRV" = "jboss" ]; then
                REGEX="$REGEX_LOG_JBOSS"
        elif [ "$SRV" = "tomcat" ]; then
                REGEX="$REGEX_LOG_TOMCAT"
        fi
}

_confira_duplicado(){
	# Verificando se existe que foi arquivado durante o processo de rotação (devido a mv -b), ver cosmos_rotacao_thread.sh 
	if [ $(grep -cE "^.*~$" "${TMP_DIR}/arquivos_para_compressao") -ne 0 ]; then
		for registro in $(grep -E "^.*~$" "${TMP_DIR}/arquivos_para_compressao"); do

			# Deletando o "~" final
			registroTmp=$(echo ${registro%?})
			grep -qE "^$registroTmp$" "${TMP_DIR}/arquivos_para_compressao"
			[ "$?" -ne 0 ] && continue
			_log "Aviso: Existe dois arquivos com o mesmo nome: ${registroTmp} e ${registro}"

			# Verificando se os dois arquivos são iguais
			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "cmp -s ${CAMINHO_DESTINO}/${registro} ${CAMINHO_DESTINO}/${registroTmp}"
			if [ "$?" -eq 0 ]; then
				_log "Aviso: Conteudo dos arquivos iguais: supressao de ${registro}"
			else
				_log "Aviso: Conteudo differente: concatenacao dos arquivos"
				ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo bash -c 'cat ${CAMINHO_DESTINO}/${registroTmp} >> ${CAMINHO_DESTINO}/${registro}'"
			fi

			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo rm ${CAMINHO_DESTINO}/${registroTmp}"
			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mv ${CAMINHO_DESTINO}/${registro} ${CAMINHO_DESTINO}/${registroTmp}"
			sed -i "/${registro}/d" "${TMP_DIR}/arquivos_para_compressao"

		done < "${TMP_DIR}/arquivos_para_compressao"
	fi
}

_relatorio -a
_compressao_logs
_relatorio -f