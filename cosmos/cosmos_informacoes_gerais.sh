#!/bin/bash

source "${RAIZ}/cosmos_import.sh"

_informacoes_gerais(){

	_cosmos.limpa_tela "\nInformacoes Gerais:\n"

	_pegar_informacoes_gerais

	echo ""; read -p "Pressiona ENTER para continuar"

}
export -f _informacoes_gerais

_pegar_informacoes_gerais(){

	echo -n "Ultima atualizacao do Banco de Dado: "; stat -c %z "$BANCO_DE_DADO" | cut -d "." -f 1
	echo -n "Ultima rotacao dos logs: " 
	echo -en "\nUltima compressao dos logs: "

	echo -en "\n\nNumero de Sistema: "; _db.ler_campo 1 | sort -u | wc -l
	echo -n "Numero de Hosts: "; _db.ler_campo 2 | uniq | wc -l 
	echo -n "Numero de Instancia: "; _db.ler_campo 4 | wc -l 

}
export -f _pegar_informacoes_gerais

_informacoes_gerais
