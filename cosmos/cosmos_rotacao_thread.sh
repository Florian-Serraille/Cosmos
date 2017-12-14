#!/bin/bash

source "${RAIZ}/cosmos_import.sh"

_rotacionar(){

	local arquivo
	local info
	local retorno=0

	_relatorio -t
	_log -m -q "Thread iniciada (PID: $$)"

	_processar_catalina_out

	[ "$lista_arquivos" ] && unset lista_arquivos

	lista_arquivos=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo ls $LOG_ORIGEM")  
	lista_arquivos=$(tr " " "\n" <<< $lista_arquivos | grep -E "$REGEX"  )

	if [ $(wc -w <<< "$lista_arquivos") -eq 0 ]; then
		[ "$SRV" = "jboss" ] && _log -a 3 -s "Aviso: Nenhum arquivo a rotacionar"
		[ "$SRV" = "tomcat" ] && _log -a 2 -s "Critico: Nenhum arquivo a rotacionar"
		return 1
	fi

	for arquivo in $lista_arquivos; do

		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mv -bv ${LOG_ORIGEM}/${arquivo} ${CAMINHO_DESTINO}") 
		retorno=$?
	 	_log "$info"

	 	if [ "$retorno" -ne 0 ]; then
	 		_log -a 2 -s "Erro: Ocorreu um erro no rotacao"
	 		return 1
	 	fi

	done

	_log "Thread terminada (PID: $$)"

	return 0
}

_processar_catalina_out(){

	local info
	local retorno=0
	
	if [ "$SRV" = "tomcat" ]; then
		_log "Rotacionando catalina.out"
		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo cp -bv ${LOG_ORIGEM}/catalina.out ${LOG_ORIGEM}/catalina.${ANO}-${MES}-${DIA}.log" 2> /dev/null) 
		retorno=$?

		if [ "$retorno" -ne 0 ]; then
			_log -a 2 -s "Critico: Ocorreu um erro na rotacao de catalina.out"
			return 1
		else
			_log "$info"	
		fi

		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo truncate -s 0 ${LOG_ORIGEM}/catalina.out" 
	fi

	return 0

}

_rotacionar
