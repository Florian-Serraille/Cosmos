#!/bin/bash

#######################################################################################################################
########################################################    Main    ###################################################
#######################################################################################################################

# Carrega no ambiante as variáveis definidas nos arquivos de configuração do diretório conf/ e as funções definidas nos arquivos do diretório inc/

for arquivo in $( ls ${RAIZ}/conf | grep -E ".*\.conf$"); do
	source "${RAIZ}/conf/${arquivo}"
done
for arquivo in $( ls ${RAIZ}/inc | grep -E ".*\.inc$"); do
	source "${RAIZ}/inc/${arquivo}"
done

# Sobreescreve a váriavel BANCO_DE_DADO definida posteriormente caso um filtro foi aplicado no banco de dado pela função _cosmos.filtra_db()

[ -f "${TMP_DIR}/bd_tmp" ] && export BANCO_DE_DADO="${TMP_DIR}/bd_tmp"
