#!/bin/bash

#######################################################################################################################

################################################# Inclusão e Configuração #############################################

source "${RAIZ}/cosmos_import.sh"

######################################################## Função #######################################################

# _conferir_conformidade_do_arquivo_de_configuracao()
# Confere se cada arquivo de configuração de $HOST possui os requisitos necessários (APP_NOME, CAMINHO_LOG_APP)
# Caso não tiver, deleta o arquivo da lista de arquivo a inserir em cosmos.db
_conferir_conformidade_do_arquivo_de_configuracao(){

	local conformidade=0
	local mensagem_complementar
	
	if [ $(grep -Ec "$REGEX_CONFORMIDADE_APP_NOME" "$TMP_DIR/arquivo_configuracao") -ne 1 ]; then 
		conformidade=1
		mensagem_complementar="${mensagem_complementar} ${DB_CONFORMIDADE_1}"
	fi

	if [ $(grep -Ec "$REGEX_CONFORMIDADE_INSTANCIA" "$TMP_DIR/arquivo_configuracao") -ne 1 ]; then 
		conformidade=1
		mensagem_complementar="${mensagem_complementar} ${DB_CONFORMIDADE_2}"
	fi
	
	if [ $(grep -Ec "$REGEX_CONFORMIDADE_LOG_APP_HOJE" "$TMP_DIR/arquivo_configuracao") -lt 1 ]; then
		conformidade=1
		mensagem_complementar="${mensagem_complementar} ${DB_CONFORMIDADE_3}"
	fi

	if [ $(grep -Ec "$REGEX_CONFORMIDADE_LOG_APP_OUTROS_DIAS" "$TMP_DIR/arquivo_configuracao") -lt 1 ]; then
		conformidade=1
		mensagem_complementar="${mensagem_complementar} ${DB_CONFORMIDADE_4}"
	fi

	if (( $(grep -Ec "$REGEX_CONFORMIDADE_LOG_APP_HOJE" "$TMP_DIR/arquivo_configuracao") != $(grep -Ec "$REGEX_CONFORMIDADE_LOG_APP_OUTROS_DIAS" "$TMP_DIR/arquivo_configuracao") )); then
		conformidade=1;
		mensagem_complementar="${mensagem_complementar} ${DB_CONFORMIDADE_5}"
	fi

	if [ "$conformidade" -eq 1 ]; then
		sed -i "/$NOME_ARQUIVO_CONFIGURACAO/d" "$TMP_DIR/lista_instancias.tmp"
		_log.log -a 2 -s -q "${DB_CONFORMIDADE} ${mensagem_complementar}"
	fi

	return $conformidade

}

# _extrair_dados_do_arquivo_de_configuracao()
# Para cada arquivo de configuração do $HOST, procura pela variável APP_NOME correspondente.
# Armazena o nome do sistema, o tipo de servidor e o nome da instancia em array.
_extrair_dados_do_arquivo_de_configuracao(){

	array=$(grep "APP_NOME" "$TMP_DIR/arquivo_configuracao" | cut -d "\"" -f "2")
	unset APP_NOME
	i=0
	for indice in $array; do 
		APP_NOME[$i]=$indice
		((i++))
	done

	SRV_APLICACAO=$(cut -d "." -f 1 <<< "$NOME_ARQUIVO_CONFIGURACAO")

	RAIZ=$(dirname $(grep "INSTANCIA" "$TMP_DIR/arquivo_configuracao" | cut -d "\"" -f "2"))

	INSTANCIA=$(basename $(grep "INSTANCIA" "$TMP_DIR/arquivo_configuracao" | cut -d "\"" -f "2"))

	RAIZ=$(dirname $(grep "INSTANCIA" "$TMP_DIR/arquivo_configuracao" | cut -d "\"" -f "2"))
		
	array=$(grep "LOG_APP_HOJE" "$TMP_DIR/arquivo_configuracao" | cut -d "\"" -f "2")
	unset CAMINHO_LOG_APP_HOJE
	i=0
	for indice in $array; do 
		CAMINHO_LOG_APP_HOJE[$i]=$indice
		((i++))
	done

	array=$(grep "LOG_APP_OUTROS_DIAS" "$TMP_DIR/arquivo_configuracao" | cut -d "\"" -f "2")
	unset CAMINHO_LOG_APP_OUTROS_DIAS
	i=0
	for indice in $array; do 
		CAMINHO_LOG_APP_OUTROS_DIAS[$i]=$indice
		((i++))
	done

}

_baixar_arquivo_configuracao(){

	_log.log -n "$DB_BAIXAR_ARQUIVO"
	scp -qi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST":"${CAMINHO_CONFIGURACAO}/${NOME_ARQUIVO_CONFIGURACAO}" "${TMP_DIR}/arquivo_configuracao"
	if [ "$?" -ne 0 ]; then
		_log.log -a 3 "${DB_BAIXAR_ARQUIVO_ERRO}" 
		continue
	fi

}

_procurar_arquivo_configuracao(){

	ssh -qi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" ls "$CAMINHO_CONFIGURACAO" | grep -E "$REGEX_ARQUIVOS_DE_CONFIGURACAO" > "$TMP_DIR/lista_instancias.tmp"
	if [ "$?" -ne 0 ]; then
		_log.log -a 3 "nenhum arquivo encontrado" 
		continue
	else
		_log.log -a 0 -s "$(wc -l ${TMP_DIR}/lista_instancias.tmp | awk '{print $1}') ${DB_PROCURAR_ARQUIVO}"
	fi

}

# _reconstruir_db()
# Lê e analiza os arquivos de configuração casando com $REGEX_ARQUIVOS_DE_CONFIGURACAO em cada $LISTA_HOSTS, e gera um novo cosmos.db
_reconstruir_db(){

	_log.log -a 0 -q "$DB_1"
	_db.limpar_banco_de_dado

	for HOST in $LISTA_HOSTS; do
		
		_log.log -a 0 -q -n "${DB_RECONSTRUIR_DB_1} ${HOST}..."

		_procurar_arquivo_configuracao

		for NOME_ARQUIVO_CONFIGURACAO in $(cat "$TMP_DIR/lista_instancias.tmp"); do

			_baixar_arquivo_configuracao

			_log.log -s -n "${DB_RECONSTRUIR_DB_2}"
			_conferir_conformidade_do_arquivo_de_configuracao
			[ "$?" -ne 0 ] && continue
			_extrair_dados_do_arquivo_de_configuracao

			_log.log -s "${DB_RECONSTRUIR_DB_3}"

			_db.escrever_registro "${APP_NOME[*]}" "${HOST}" "${SRV_APLICACAO}" "${RAIZ}" "${INSTANCIA}" "${CAMINHO_LOG_APP_HOJE[*]}" "${CAMINHO_LOG_APP_OUTROS_DIAS[*]}"

		done
    	
	done

	_log.log -a 0 -q "${DB_2}" 
}

#######################################################################################################################
########################################################    MAIN    ###################################################
#######################################################################################################################


_log.relatorio -a
_reconstruir_db
_log.relatorio -f