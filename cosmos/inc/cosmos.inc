# _uso()
# Mostra as opções de execuções possiveis para o usuário
_uso(){
	echo -e "$messagem_uso\n"	
}
export -f _uso

_ler_variaveis_do_registro(){

	# Variavel SISTEMA
	[ "$array" ] && unset array
	array=$(cut -d "$DELIMITADOR" -f 1 <<< "$1")
	i=0
	for indice in $array; do
		SISTEMA["$i"]="$indice"
		((i++))
	done
	export SISTEMA

	# Variavel HOST
	HOST=$(cut -d "$DELIMITADOR" -f 2 <<< "$1")
	export HOST	
	
	# Variavel SRV
	SRV=$(cut -d "$DELIMITADOR" -f 3 <<< "$1")
	export SRV	

	# Variavel RAIZ
	RAIZ_SRV=$(cut -d "$DELIMITADOR" -f 4 <<< "$1")
	#export RAIZ_SRV	

	# Variavel INSTANCIA
	INSTANCIA=$(cut -d "$DELIMITADOR" -f 5 <<< "$1")
	export INSTANCIA

	# Variavel LOG_APLIC
	[ "$array" ] && unset array
	array=$(cut -d "$DELIMITADOR" -f 6 <<< "$1")
	i=0
	for caminho in $array; do
		LOG_APLIC[$i]="$caminho"
		((i++))
	done
	export LOG_APLIC	

}

# _limpa_tela()
# Limpa a tela e mostra o cabeçalho padrão da interface e a menssagem $1 se tiver
_limpa_tela(){

        clear
        [[ "$cabecalho_menu" ]] && echo -e "$cabecalho_menu"
        [[ "$1" ]] && echo -e "$1"
        
}

_filtra_db(){

	case "$1" in

		host )
			echo "Host: ${filtra_host}"
			numeroRegistro="1"
			;;

		servidor )
			echo "Servidor: ${filtra_servidor}"
			numeroRegistro="2"
			;;

		sistema )
			echo "Sistema: ${filtra_sistema}"
			numeroRegistro="0"
			;;

		instancia )
			echo "Instancia: ${filtra_instancia}"
			numeroRegistro="4"
			;;
	
		* )
			echo "erro"
			exit 1
			;;
	esac

	REGEX_FILTRO=$(sed s/numeroRegistro/$numeroRegistro/ <<< $REGEX_FILTRO)
	REGEX_FILTRO=$(sed s/alvo/$1/ <<< $REGEX_FILTRO)
	echo "$REGEX_FILTRO"

}