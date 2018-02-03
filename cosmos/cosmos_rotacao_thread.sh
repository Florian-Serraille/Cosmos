#!/bin/bash

#######################################################################################################################
################################################# Inclusão e Configuração #############################################
#######################################################################################################################

source "${RAIZ}/cosmos_import.sh"

#######################################################################################################################
######################################################## Função #######################################################
#######################################################################################################################

# A seguinte função está encarregada de rotacionar o arquivo catalina.out das instancias Tomcat e de aplicar no seu nome o formato padrão de data.
# Desse modo catalina.out se torna catalina.ANO-MES-DIA.log
# O arquivo não é apenas renomeado pois Tomcat segue ele pelo inode, portanto copiamos e conteúdo e esvaziamos ele por fim.
_rotacao_catalina_out(){

	_log.relatorio -t
	_log.log -a 0 -q "Thread iniciada PID: $$"

	local info
	local retorno=0

	tamanho_catalina=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo wc -m ${DIRETORIO_DE_ORIGEM_LOG_SERVIDOR}/catalina.out" 2> /dev/null)
	tamanho_catalina="$(awk '{print $1}' <<< ${tamanho_catalina})"

	if [ ! "$tamanho_catalina" ]; then

		_log.log -a 3 "Arquivo ${DIRETORIO_DE_ORIGEM_LOG_SERVIDOR}/catalina.out inexistante"

	elif [ "$tamanho_catalina" -eq 0 ]; then

		_log.log -a 2 "Arquivo ${DIRETORIO_DE_ORIGEM_LOG_SERVIDOR}/catalina.out vazio"

	else

		info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo cp -bv ${DIRETORIO_DE_ORIGEM_LOG_SERVIDOR}/catalina.out ${DIRETORIO_DE_ORIGEM_LOG_SERVIDOR}/catalina.${ANO}-${MES}-${DIA}.log" 2> /dev/null)
		retorno=$?

		if [ "$retorno" -ne 0 ]; then

			_log.log -a 2 -s "Critico: Ocorreu um erro na rotacao de catalina.out"

		else

			_log.log "$info"

		fi

		# Esvaziamento de catalina.out. (Usamos o comando truncate para evitar as complições devidas aos redirecionamento via SSH )
		ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo truncate -s 0 ${DIRETORIO_DE_ORIGEM_LOG_SERVIDOR}/catalina.out"

	fi

	_log.log "Thread terminada PID: $$"

}

#######################################################################################################################
########################################################### Main ######################################################
#######################################################################################################################

# A existencia desse segundo arquivo de rotação é devido ao fato de dever poder criar várias threads, o que não é
# possivel com uma simples chamada de função.
# Rotação Core recebe todas as variáveis da instância que ele deve tratar do ambiante (definido no processo pai).

_rotacao_catalina_out
