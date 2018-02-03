#!/bin/bash

#######################################################################################################################

################################################# Inclusão e Configuração #############################################

source "${RAIZ}/cosmos_import.sh"

######################################################## Função #######################################################

_informacoes_gerais(){

	_cosmos.limpa_tela "\nInformacoes Gerais:\n"

	_pegar_informacoes_gerais

}
export -f _informacoes_gerais

_pegar_informacoes_gerais(){

	echo -en "Numero de Sistema: "; _db.ler_campo 1 | sort -u | wc -l
	echo -n "Numero de Hosts: "; _db.ler_campo 2 | uniq | wc -l
	echo -n "Numero de Instancia: "; _db.ler_campo 4 | wc -l

	echo -e "\nLista dos Hosts gerenciados:\n$(echo -e $LISTA_HOSTS| tr ' ' '\n')\n"

}
export -f _pegar_informacoes_gerais

#######################################################################################################################
########################################################### Main ######################################################
#######################################################################################################################


_informacoes_gerais
