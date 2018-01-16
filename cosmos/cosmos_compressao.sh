#!/bin/bash

## Pensar no caso de duas compressoes no mesmo dia, a segunda vai sobreescrever a primeira

source "${RAIZ}/cosmos_import.sh"

_compressao_log(){

	_log.log -a 0 -q "$COMPRESSAO_1"

	prioridade="ionice -c $IONICE nice -n $NICE"

	while read registro_banco_dado; do

		 _cosmos.ler_variaveis_do_registro "$registro_banco_dado"

		_log.log -a 0 -q "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

		_test_zip
		[ "$?" -ne 0 ] && continue

		_construcao_caminho_compressao

		_cosmos.selecao_regex

		_log.log -a 0 "$COMPRESSAO_2"

		_compressar_log_srv

		if [ ! "$LOG_APLIC_OUTROS_DIAS" = "-" ]; then

			_log.log -a 0 "$COMPRESSAO_3"
			_compressar_log_aplic

		fi
		
	done < "$BANCO_DE_DADO"

	_log.log -a 0 -q "$COMPRESSAO_4"

}

_construcao_caminho_compressao(){

	CAMINHO_DESTINO="$(dirname ${RAIZ_SRV})/logs/${SISTEMA}"

	# Conferindo se o caminho de destinho dos logs existe, se não criar-lo
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "[ -d ${CAMINHO_DESTINO} ]"
	if [ "$?" -ne 0 ]; then
		_log.log "${COMPRESSAO_CONSTRUCAO_CAMINHO} ${CAMINHO_DESTINO}"
		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mkdir -vp ${CAMINHO_DESTINO}")
		_log.log "$info"
	fi
}

_test_zip(){

	# Testando se Zip está instalado
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "zip -v" > /dev/null

	if [ "$?" -ne 0 ]; then
		_log.log -a 2 "$COMPRESSAO_TESTE_ZIP_1"		
		_log.log -a 2 "$COMPRESSAO_TESTE_ZIP_2"		
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo apt update && sudo apt install zip -y"
		
		if [ "$?" -ne 0 ]; then
			_log.log -q -a 4 "$COMPRESSAO_TESTE_ZIP_3"
			return 1
		fi

		return 0
	fi	

}


_compressar_log_srv(){

	# Compressão logs servidor

	## Listando todos o nome de todos os arquivos cujo nome casa com a regex
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "ls ${CAMINHO_DESTINO}" > "${TMP_DIR}/tmp"
	grep -E "$REGEX" "${TMP_DIR}/tmp" > "${TMP_DIR}/arquivos_para_compressao"
	
	if [ $(wc -l "${TMP_DIR}/arquivos_para_compressao" | awk '{print $1}') -eq 0 ]; then
		if [ "$SRV" = "tomcat" ]; then
			_log.log -a 3 "$COMPRESSAO_LOG_SRV"
		else
			_log.log -a 2 "$COMPRESSAO_LOG_SRV"
		fi
		return 1
	fi

	
	_check_duplicados
	_unzip_duplicados

	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "ls ${CAMINHO_DESTINO}" > "${TMP_DIR}/tmp"
	grep -E "$REGEX" "${TMP_DIR}/tmp" > "${TMP_DIR}/arquivos_para_compressao"

	_check_duplicados
	_zip_arquivos

}

_compressar_log_aplic(){

	local i=0

	for indice in ${LOG_APLIC_OUTROS_DIAS[@]}; do
		indice=$(sed s/ANO/$REGEX_ANO/ <<< $indice) 
		indice=$(sed s/MES/$REGEX_MES/ <<< $indice) 
		indice=$(sed s/DIA/$REGEX_DIA/ <<< $indice) 
		indice=$(sed s/HORA/$REGEX_HORA/ <<< $indice) 2> /dev/null 
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "ls $(dirname ${indice})" > "${TMP_DIR}/tmp" 2> /dev/null
		if [ "$?" -ne 0 ]; then
			_log.log -a 3 -s "$COMPRESSAO_LOG_APLIC_1"
			continue
		fi
		REGEX="^$(basename "$indice")$"
		grep -E "$REGEX" "${TMP_DIR}/tmp" > "${TMP_DIR}/arquivos_para_compressao"
		
		if [ $(wc -l "${TMP_DIR}/arquivos_para_compressao" | awk '{print $1}') -eq 0 ]; then
			_log.log -a 2 -s "$COMPRESSAO_LOG_APLIC_2 ${LOG_APLIC_OUTROS_DIAS[$i]}"
			continue
		fi
		while read arquivo; do
			local dataDoArquivo=$(grep -Eo "$REGEX_DATA" <<< "$arquivo")
			local anoArquivo=$(cut -d "-" -f 1 <<< $dataDoArquivo)
			local mesArquivo=$(cut -d "-" -f 2 <<< $dataDoArquivo)


			# Procura por arquivos com mesmo nome no zip
			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip -l ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip ${arquivo}" >/dev/null 2>/dev/null
			if [ "$?" -eq 0 ]; then
				_log.log -a 1 "${COMPRESSAO_LOG_APLIC_3} (${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip --> ${arquivo})"
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mv -v $(dirname ${indice})/${arquivo} $(dirname ${indice})/${arquivo}~")
				_log.log "$info"
				info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip ${arquivo} -d $(dirname ${indice})")
				_log.log "$info"
			
				# Comparando os dois arquivos
				ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "cmp -s $(dirname ${indice})/${arquivo} $(dirname ${indice})/${arquivo}~"
				if [ "$?" -eq 0 ]; then
					_log.log "${COMPRESSAO_LOG_APLIC_4} ${arquivo}"
				else
					_log.log "$COMPRESSAO_LOG_APLIC_5"
					ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo bash -c 'echo -e ${messagem_concatenacao} >> $(dirname ${indice})/${arquivo}'"
					ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo bash -c 'cat $(dirname ${indice})/${arquivo}~ >> $(dirname ${indice})/${arquivo}'"
				fi

				ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo rm $(dirname ${indice})/${arquivo}~"

			fi

			info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "${prioridade} sudo zip -jTm ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip $(dirname ${indice})/${arquivo}")
			[ "$?" -ne 0 ] && _log.log -a 3 -s "${COMPRESSAO_5} ${arquivo}"
			info=$(sed s/%/\ percent/ <<< $info)
			_log.log "$info"
		done <	"${TMP_DIR}/arquivos_para_compressao"
	done
}

# Olha se existe dois arquivos com nome identico (com possivel "~" no final), compara o conteudo dos dois, se for igual deleta uma copia e se não for concatena os dois
# Pode acontecer em se houver duas rotações do arquivos consecutiva sem compreção (mv -b em cosmos_rotacao) 
_check_duplicados(){

	if [ $(grep -cE "^.*~$" "${TMP_DIR}/arquivos_para_compressao") -ne 0 ]; then
		for registro in $(grep -E "^.*~$" "${TMP_DIR}/arquivos_para_compressao"); do

			# Deletando o "~" final
			registroTmp=$(echo ${registro%?})
			grep -qE "^$registroTmp$" "${TMP_DIR}/arquivos_para_compressao"
			[ "$?" -ne 0 ] && continue
			_log.log -a 1 "${COMPRESSAO_CHECK_DUPLICADOS_1} ${registroTmp} ${registro}"

			# Verificando se os dois arquivos são iguais
			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "cmp -s ${CAMINHO_DESTINO}/${registro} ${CAMINHO_DESTINO}/${registroTmp}"
			if [ "$?" -eq 0 ]; then
				_log.log "${COMPRESSAO_LOG_APLIC_4} ${registro}"
			else
				_log.log "${COMPRESSAO_LOG_APLIC_5}"
				ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo bash -c 'echo -e ${messagem_concatenacao} >> ${CAMINHO_DESTINO}/${registro}'"
				ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo bash -c 'cat ${CAMINHO_DESTINO}/${registroTmp} >> ${CAMINHO_DESTINO}/${registro}'"
			fi

			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo rm ${CAMINHO_DESTINO}/${registroTmp}"
			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mv ${CAMINHO_DESTINO}/${registro} ${CAMINHO_DESTINO}/${registroTmp}"
			sed -i "/${registro}/d" "${TMP_DIR}/arquivos_para_compressao"

		done < "${TMP_DIR}/arquivos_para_compressao"
	fi
}

_unzip_duplicados(){

	while read arquivo; do

		# Extraire les dates et tester l existance du zip puis s il exite du fichier dans le zip
		local dataDoArquivo=$(grep -Eo "$REGEX_DATA" <<< "$arquivo")
		local anoArquivo=$(cut -d "-" -f 1 <<< $dataDoArquivo)
		local mesArquivo=$(cut -d "-" -f 2 <<< $dataDoArquivo)
		
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip -l ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip ${arquivo}" >/dev/null 2>/dev/null
		if [ "$?" -eq 0 ]; then
			_log.log "${COMPRESSAO_LOG_APLIC_3} ${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip --> ${arquivo}"
			info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mv -v ${CAMINHO_DESTINO}/${arquivo} ${CAMINHO_DESTINO}/${arquivo}~")
			_log.log "$info"
			info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo unzip ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip ${arquivo} -d ${CAMINHO_DESTINO}")
			_log.log "$info"
		fi

	done <	"${TMP_DIR}/arquivos_para_compressao" 
}

_zip_arquivos(){

		while read arquivo; do
			
			# Extraire les dates et tester l existance du zip puis s il exite du fichier dans le zip
			local dataDoArquivo=$(grep -Eo "$REGEX_DATA" <<< "$arquivo")
			local anoArquivo=$(cut -d "-" -f 1 <<< $dataDoArquivo)
			local mesArquivo=$(cut -d "-" -f 2 <<< $dataDoArquivo)

			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "test -f ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip"

			info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "${prioridade} sudo zip -jTm ${CAMINHO_DESTINO}/${SISTEMA}.log.${anoArquivo}-${mesArquivo}.zip ${CAMINHO_DESTINO}/${arquivo}")
			[ "$?" -ne 0 ] && _log.log -a 3 -s "${COMPRESSAO_5} ${arquivo}"
			info=$(sed s/%/\ percent/ <<< $info)
			_log.log "$info"
		
		done <	"${TMP_DIR}/arquivos_para_compressao" 	
}

_log.relatorio -a
_compressao_log
_log.relatorio -f