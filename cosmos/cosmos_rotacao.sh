#!/bin/bash

#######################################################################################################################

################################################# Inclusão e Configuração #############################################

source "${RAIZ}/cosmos_import.sh"

######################################################## Função #######################################################

_rotacao_log(){

	_log.log -a 0 -q "$ROTACAO_1"

	_log.log -a 0 -q "$ROTACAO_2"

	local THREAD_ROTACAO

	while read registro; do

	 	_cosmos.ler_variaveis_do_registro "$registro"

	 	[ "$SRV" != "tomcat" ] && continue
	
		_log.log -a 0 -q "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

		_construcao_diretorio_destino
		
		"${RAIZ}/cosmos_rotacao_core.sh" --catalina & 
		THREAD_ROTACAO[${#THREAD_ROTACAO[@]}]="$!"
		THREADS_LOG[${#THREADS_LOG[@]}]="$!"
		_log.log "${ROTACAO_3} $!"

	done < "$BANCO_DE_DADO"

	for (( threadRotacao=0; threadRotacao < ${#THREAD_ROTACAO[@]}; threadRotacao++ )); do
		wait ${THREAD_ROTACAO[${threadRotacao}]}
	done
	
	_log.relatorio -j "$THREADS_LOG"
	_log.log -a 0 -q "$ROTACAO_4"
	_log.log -a 0 -q "$ROTACAO_5"	

	while read registro; do

	 	_cosmos.ler_variaveis_do_registro "$registro"
	
		_log.log -a 0 -q "[ Sistema: ${SISTEMA[*]} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA} ]"

		_construcao_diretorio_destino
		
		"${RAIZ}/cosmos_rotacao_core.sh" 

	done < "$BANCO_DE_DADO"

	_log.log -a 0 -q "$ROTACAO_6"

	_log.log -a 0 -q "$ROTACAO_7"

}

_construcao_diretorio_destino(){

	_cosmos.caminho_origem_log

	#Conferindo se o caminho de destinho dos logs existe, se não criar-lo
	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "[ -d ${CAMINHO_DESTINO} ]"
	if [ "$?" -ne 0 ]; then
		_log.log "$ROTACAO_CONSTRUCAO_DESTINO ${CAMINHO_DESTINO}"
		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mkdir -vp ${CAMINHO_DESTINO}")
		_log.log "$info"
	fi
}

#######################################################################################################################
########################################################    MAIN    ###################################################
#######################################################################################################################


_log.relatorio -a
_rotacao_log
_log.relatorio -f
