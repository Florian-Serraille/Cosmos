#!/bin/bash

source "${RAIZ}/cosmos_import.sh"

 _menu_principal(){

	local opcao_menu="1"

	while [ "$opcao_menu" != "0" ]; do
		
		_limpa_tela "\nMenu Principal:\n"
		
		for (( i=0; i < ${#menu_principal[@]}; i++ )){
			echo "$i) ${menu_principal[$i]}"
		}   

		echo -en "$menu_resposta"

		read opcao_menu

		case $opcao_menu in
			
			1) _menu_configuracao ;;

			2) _menu_administracao ;;

			3) _informacoes_gerais ;;
			
			0) return 0 ;;
			
			*) ;;
			
		esac	
	done	

}

 _menu_configuracao(){

	local opcao_menu="1"

	while [ "$opcao_menu" != "0" ]; do

		
		_limpa_tela "\nMenu Configuracao:\n"

		for (( i=0; i < ${#menu_configuracao[@]}; i++ )){
			echo "$i) ${menu_configuracao[$i]}"
		}   
		
		echo -en "$menu_resposta"

		read opcao_menu

		case $opcao_menu in
			
			1)
				"${RAIZ}/cosmos_banco_de_dado.sh"
				read -p "Pressiona ENTER para continuar"
				;;
			
			0) return 0 ;;
			
			*) ;;
			
		esac	
	done	

}

 _menu_administracao(){

	local opcao_menu="1"

	while [ "$opcao_menu" != "0" ]; do

		local lista_do_menu[0]="Sair"
		
		_limpa_tela "\nMenu Administracao:\n"

		for (( i=0; i < ${#menu_administracao[@]}; i++ )){
			echo "$i) ${menu_administracao[$i]}"
		}  
		
		echo -en "$menu_resposta"

		read opcao_menu

		case $opcao_menu in

			0) return 0 ;;
			
			*) ;;
			
		esac	
	done	

}

_informacoes_gerais(){
	"${RAIZ}/cosmos_informacoes_gerais.sh"
}


 _menu_principal
