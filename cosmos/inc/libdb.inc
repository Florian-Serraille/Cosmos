#######################################################################################################################
### libdb.inc
###
### Funções para gerenciar banco de dado textual.
### Use o comando "source" para inclui-lo em seu script
###
#######################################################################################################################

###################################################### CONFIGURAÇÃO ###################################################

# DELIMITADOR:
# define o DELIMITADOR, se não tiver indicado fica por padrão ":"
[ -z "$DELIMITADOR" ] && DELIMITADOR=":"

#################################################### FUNÇÕES ##########################################################

# _db.ler_cabecalho()
# Mostra os nomes dos campos do banco de dado textual
#_db.ler_cabecalho(){
#
#	head -n 1 "$BANCO_DE_DADO"
#
#}

# _db.ler_campo()
# Parâmetro: o numero do campo desejado
# Mostra os campos DISTINTOS número 'x' de todos os registros, exepto o registro de definição.
# Se nenhum argumento for passado, é o campo numero 1 que é lido.
function _db.ler_campo(){
# Lembrando que a linha 1 é a definição dos campos
	
	if [ "$1" ];then
		CAMPO="$1"
	else
		CAMPO="1"
	fi

#	tail +2 "$BANCO_DE_DADO" | cut -d "$DELIMITADOR" -f "$CAMPO" | sort -u	
	cat "$BANCO_DE_DADO" | cut -d "$DELIMITADOR" -f "$CAMPO" # | sort -u	

}

# _db.ler_registro_pelo_campo()
# Parâmetro: uma string 
# Mostra os registros cujo a string indicada casa EXATAMENTE com um dos campos do registro
function _db.ler_registro_pelo_campo(){
	
	local string="$1"
	cat "$BANCO_DE_DADO" | grep -E "^(.*$DELIMITADOR)?$string$DELIMITADOR.*$" 

}

# _db.escrever_registro()
# Parâmetro: Cada argumento enviado é um campo do novo registro 
# Adiciona um registro ao banco de dado textual
function _db.escrever_registro(){
	
	REGISTRO=""
	while [ "$1" ]; do
		REGISTRO="$REGISTRO$1$DELIMITADOR"
		shift
	done
	
	[ "$REGISTRO" ] && echo "$REGISTRO" >> "$BANCO_DE_DADO"
}

# _db.remova_registros()
# Parâmetro: uma string
# Remova os registros cujo a string indicada casa EXATAMENTE com um dos campos do registro
function _db.remova_registros(){

	local string="$1"
	# Pode melhor a regex, ver as peculiaridade da implementação de regex com sed 
	# Não funciona: sed -iE "/^(.*$DELIMITADOR)?$string$DELIMITADOR.*$/d" "$BANCO_DE_DADO"
	sed -i "/$string$DELIMITADOR/d" "$BANCO_DE_DADO" 

}

function _db.limpar_banco_de_dado(){

	# Backup do antigo banco de dado textual
	echo -e "\nBackup $(date +%d/%m/%Y-%T)">> "$BANCO_DE_DADO_BKP"
	cat "$BANCO_DE_DADO" >> "$BANCO_DE_DADO_BKP"                                                                                                                                     
	
	# Limpeza
	> "$BANCO_DE_DADO"
}

function _db.adiciona_cabecalho(){

	cabecalho=""
	sort -r "$BANCO_DE_DADO" -o "$BANCO_DE_DADO"
		
	while [ "$1" ]; do
		cabecalho="$cabecalho$1$DELIMITADOR"
		shift
	done
	
	[ "$cabecalho" ] && echo "$cabecalho" >> "$BANCO_DE_DADO"
	tac "$BANCO_DE_DADO" > "$TMP_DIR/cosmos.tmp" && cat "$TMP_DIR/cosmos.tmp" > "$BANCO_DE_DADO"

}
