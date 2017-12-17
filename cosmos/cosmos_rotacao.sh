#!/bin/bash

source "${RAIZ}/cosmos_import.sh"

_rotacao_logs(){

	_log -a 1 -q -p ">>> " "Iniciando a rotacao dos logs"

	_log -a 1 -q -p ">>> " "Rotacao de catalina.out (por thread)"

	local THREAD_ROTACAO

	while read registro; do

	 	_ler_variaveis_do_registro "$registro"

	 	[ "$SRV" != "tomcat" ] && continue
	
		_log -a 3 -p "> " "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

		_construcao_caminho_rotacao
		if [ "$?" -ne 0 ]; then
			_log -a 2 "Erro: Servidor de aplicacao desconhecido"
			continue
		fi

		_selecao_regex
		
		"${RAIZ}/cosmos_rotacao_core.sh" --catalina & 
		THREAD_ROTACAO[${#THREAD_ROTACAO[@]}]="$!"
		THREADS_LOG[${#THREADS_LOG[@]}]="$!"
		_log "Criacao da thread (PID: $!)"

	done < "$BANCO_DE_DADO"

	for (( threadRotacao=0; threadRotacao < ${#THREAD_ROTACAO[@]}; threadRotacao++ )); do
		wait ${THREAD_ROTACAO[${threadRotacao}]}
	done
	
	_relatorio -j "$THREADS_LOG"
	_log -a 1 -p ">>> " "Fim da rotacao de catalina.out"

	_log -a 1 -q -p ">>> " "Rotacao dos arquivos de logs"	

	while read registro; do

	 	_ler_variaveis_do_registro "$registro"
	
		_log -a 3 -p "> " "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

		_construcao_caminho_rotacao
		if [ "$?" -ne 0 ]; then
			_log -a 2 "Erro: Servidor de aplicacao desconhecido"
			continue
		fi

		_selecao_regex
		
		"${RAIZ}/cosmos_rotacao_core.sh" 

	done < "$BANCO_DE_DADO"

	_log -a 1 -q -p ">>> " "Fim da rotacao dos arquivos de logs"

	_log -a 1 -q -p ">>> " "Fim da rotacao"

}

_selecao_regex(){

	if [ "$SRV" = "jboss" ]; then
		REGEX="$REGEX_LOG_JBOSS"
	elif [ "$SRV" = "tomcat" ]; then
		REGEX="$REGEX_LOG_TOMCAT"
	fi

	export REGEX

}

_construcao_caminho_rotacao(){

	#Construção dos caminhos
	if [ "$SRV" = "tomcat"  ]; then
		export LOG_ORIGEM="${RAIZ_SRV}/${INSTANCIA}/logs"
	elif [ "$SRV" = "jboss"  ]; then
		export LOG_ORIGEM="${RAIZ_SRV}/${INSTANCIA}/log"
	else
		return 1
	fi
	
	export CAMINHO_DESTINO="$(dirname ${RAIZ_SRV})/logs/${SISTEMA}"

	#Conferindo se o caminho de destinho dos logs existe, se não criar-lo
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "[ -d ${CAMINHO_DESTINO} ]"
	if [ "$?" -ne 0 ]; then
		_log "Criacao do diretorio ${CAMINHO_DESTINO}"
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mkdir -p ${CAMINHO_DESTINO}"
	fi

}

_relatorio -a
_rotacao_logs
_relatorio -f
