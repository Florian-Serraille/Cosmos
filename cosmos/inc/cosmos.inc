# _cosmos.uso()
# Mostra as opções de execuções possiveis para o usuário
function _cosmos.uso(){
	echo -e "$COSMOS_USO\n"	
}
export -f _cosmos.uso

function _cosmos.ler_variaveis_do_registro(){

	# Variavel SISTEMA
	[ "$SISTEMA" ] && unset SISTEMA
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

	# Variavel LOG_APLIC_HOJE
	[ "$LOG_APLIC_HOJE" ] && unset LOG_APLIC_HOJE
	[ "$array" ] && unset array
	array=$(cut -d "$DELIMITADOR" -f 6 <<< "$1")
	i=0
	for caminho in $array; do
		LOG_APLIC_HOJE[$i]="$caminho"
		((i++))
	done
	export LOG_APLIC_HOJE

	# Variavel LOG_APLIC_OUTROS_DIAS
	[ "$LOG_APLIC_OUTROS_DIAS" ] && unset LOG_APLIC_OUTROS_DIAS
	[ "$array" ] && unset array
	array=$(cut -d "$DELIMITADOR" -f 7 <<< "$1")
	i=0
	for caminho in $array; do
		LOG_APLIC_OUTROS_DIAS[$i]="$caminho"
		((i++))
	done
	export LOG_APLIC_OUTROS_DIAS	

}

# _cosmos.limpa_tela()
# Limpa a tela e mostra o cabeçalho padrão da interface e a menssagem $1 se tiver
function _cosmos.limpa_tela(){

        clear
        [[ "$MENU_CABECALHO" ]] && echo -e "$MENU_CABECALHO"
        [[ "$1" ]] && echo -e "$1"
        
}

function _cosmos.filtra_db(){

	for palavra in $1; do 
		regex=$(sed s/filtro/$palavra/ <<< $REGEX_FILTRO)
		grep -E "$regex" "$BANCO_DE_DADO" >> "$TMP_DIR/bd_tmp2"
	done

	sort -u "${TMP_DIR}/bd_tmp2" > "${TMP_DIR}/bd_tmp"

}

function _cosmos.selecao_regex(){

	if [ "$SRV" = "jboss" ]; then
		REGEX="$REGEX_LOG_JBOSS"
		REGEX_BASE="$REGEX_LOG_JBOSS_BASE"
		REGEX_SEM_ROTACAO="$REGEX_LOG_JBOSS_BASE_SEM_ROTACAO"
	elif [ "$SRV" = "tomcat" ]; then
		REGEX="$REGEX_LOG_TOMCAT"
		REGEX_BASE="$REGEX_LOG_TOMCAT_BASE"
		REGEX_SEM_ROTACAO="$REGEX_LOG_TOMCAT_BASE_SEM_ROTACAO"
	fi
}

function _cosmos.caminho_origem_log(){

	if [ "$SRV" = "tomcat"  ]; then
		export LOG_ORIGEM="${RAIZ_SRV}/${INSTANCIA}/logs"
	elif [ "$SRV" = "jboss"  ]; then
		export LOG_ORIGEM="${RAIZ_SRV}/${INSTANCIA}/log"
	else
		return 1
	fi
	
	export CAMINHO_DESTINO="$(dirname ${RAIZ_SRV})/logs/${SISTEMA}"

}

### Criar a funcao _io.ctrl_c
function _cosmos.ctrl_c(){
	_log.log -a 4 ' PROCESSO INTEROMPIDO (CTRL + C)'
	_log.relatorio -f
	_log.limpa_tmp ${TMP_DIR}
	for arquivo_log in $(ls ${RAIZ}/log/$(date +%y%m) | grep -E "^[0-9]*$"); do
		echo "-------------------------------------------------------------------" >> "${RAIZ_SRV}/log/$(date +%y%m)/$(date +%d).cosmos.log"
		echo "INTERUMPCAO POR SINAL CTRL+C" >> "${RAIZ_SRV}/log/$(date +%y%m)/$(date +%d).cosmos.log"
		echo "-------------------------------------------------------------------" >> "${RAIZ_SRV}/log/$(date +%y%m)/$(date +%d).cosmos.log"
		cat "${RAIZ_SRV}/log/$(date +%y%m)/${arquivo_log}" >> "${RAIZ_SRV}/log/$(date +%y%m)/$(date +%d).cosmos.log"
		rm "${RAIZ_SRV}/log/$(date +%y%m)/${arquivo_log}"
	done
	
	exit 1 
}