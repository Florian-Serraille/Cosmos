#!/bin/bash

#######################################################################################################################

################################################# Inclusão e Configuração #############################################

source "${RAIZ}/cosmos_import.sh"

######################################################## Função #######################################################

_rotacionar(){

	local arquivo
	local info
	local retorno=0

	[ "$lista_arquivos" ] && unset lista_arquivos

	_cosmos.selecao_regex

	lista_arquivos=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo ls $LOG_ORIGEM")  
	lista_arquivos=$(tr " " "\n" <<< $lista_arquivos | grep -E "$REGEX"  )

	if [ $(wc -w <<< "$lista_arquivos") -eq 0 ]; then
		[ "$SRV" = "jboss" ] && _log.log -a 2 -s "$ROTACAO_CORE_1"
		[ "$SRV" = "tomcat" ] && _log.log -a 3 -s "$ROTACAO_CORE_1"
		return 1
	fi

	for arquivo in $lista_arquivos; do

		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mv -bv ${LOG_ORIGEM}/${arquivo} ${CAMINHO_DESTINO}") 
		retorno=$?
	 	_log.log "$info"

	 	if [ "$retorno" -ne 0 ]; then
	 		_log.log -a 3 -s "$ROTACAO_CORE_2"
	 		return 1
	 	fi

	done

	return 0
}

_processar_catalina_out(){

	_log.relatorio -t
	_log.log -a 0 -q "${ROTACAO_CORE_CATALINA_1} $$"

	local info
	local retorno=0
	
	info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo cp -bv ${LOG_ORIGEM}/catalina.out ${LOG_ORIGEM}/catalina.${ANO}-${MES}-${DIA}.log" 2> /dev/null) 
	retorno=$?

	if [ "$retorno" -ne 0 ]; then
		_log.log -a 2 -s "Critico: Ocorreu um erro na rotacao de catalina.out"
		exit 1
	else
		_log.log "$info"	
	fi

	ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo truncate -s 0 ${LOG_ORIGEM}/catalina.out" 

	_log.log "${ROTACAO_CORE_CATALINA_2} $$"

	exit 0
}

#######################################################################################################################
########################################################    MAIN    ###################################################
#######################################################################################################################


[ "$#" -eq 0 ] && _rotacionar

case "$1" in 

	--catalina )
		_processar_catalina_out
	;;

	\?)
		echo "${ROTACAO_CORE_3} $1"  
		exit 1
	;;

esac