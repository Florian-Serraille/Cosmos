#######################################################################################################################
### libcosmos.inc
### Funções de uso comum aos diversos modulos de Cosmos.
#######################################################################################################################

# Mostra as opções de execuções possiveis para o usuário
function _cosmos.uso(){
	echo -e "$COSMOS_USO\n"
}
export -f _cosmos.uso

# Extrai de uma string passada em argumento as diversas variaveis necessárias à identificação da instancia.
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
	export RAIZ_SRV

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

# Limpa a tela e mostra o cabeçalho padrão da interface e assim como a string passado em argumento se tiver.
function _cosmos.limpa_tela(){

	clear
	[[ "$MENU_CABECALHO" ]] && echo -e "$MENU_CABECALHO"
	[[ "$1" ]] && echo -e "$1"

}

# Essa função filtra o arquivo de banco de dado afim de aplicar os modulos de rotação e de compressão sobre uma instancia, um host, um sistema em particular.
# Cada argumento passado na chamada da função deve corresponder a um campo exato de um registro.
# O novo banco de dado assim criado está armazenado em um arquivo temporário.
function _cosmos.filtra_db(){

	for palavra in $1; do
		regex=$(sed s/filtro/$palavra/ <<< $REGEX_FILTRO)
		grep -E "$regex" "$BANCO_DE_DADO" >> "$TMP_DIR/bd_tmp2"
	done

	sort -u "${TMP_DIR}/bd_tmp2" > "${TMP_DIR}/bd_tmp"

}

# A função seta as variáveis REGEX, REGEX_BASE e REGEX_SEM_ROTACAO em função do tipo de servidor.
# A variável REGEX é uma expressão regular que casa com todos os arquivos produzidos pelo servidor, com o formato do dia no nome. (ex: xxxx.2017-12-01.log)
# A variável REGEX_BASE é uma expressão regular que casa com todos os arquivos produzidos pelo servidor, com os padrões de rotação no nome. (ex: xxxx.ANO-MES-DIA-HORA.log)
# A variável REGEX_SEM_ROTACAO é uma expressão regular que casa com todos os arquivos produzidos pelo servidor do dia corrente. (ex: xxxx.log)
# Se o tipo de servidor nao produz log de servidor, ou é desconhecido, então o valor de retorno é 1.
function _cosmos.selecao_regex(){

	if [ "$SRV" = "jboss" ]; then
		REGEX="$REGEX_LOG_JBOSS"
		REGEX_BASE="$REGEX_LOG_JBOSS_BASE"
		REGEX_SEM_ROTACAO="$REGEX_LOG_JBOSS_BASE_SEM_ROTACAO"
	elif [ "$SRV" = "tomcat" ]; then
		REGEX="$REGEX_LOG_TOMCAT"
		REGEX_BASE="$REGEX_LOG_TOMCAT_BASE"
		REGEX_SEM_ROTACAO="$REGEX_LOG_TOMCAT_BASE_SEM_ROTACAO"
	else
		return 1
	fi

	return 0
}

# Gera uma variável global que aponta para o diretório onde estão produzidos os logs servidor, em função do tipo de servidor. (tomcat, jboss)
# Essa função é provalmente destinada a evoluir em função da inclusão futuro de novo tipo de servidor. (ex: NodeJS...)
# Se o tipo de servidor nao produz log de servidor, ou é desconhecido, então o valor de retorno é 1.
function _cosmos.get_diretorio_de_origem_log_servidor(){

	if [ "$SRV" = "tomcat"  ]; then
		export DIRETORIO_DE_ORIGEM_LOG_SERVIDOR="${RAIZ_SRV}/${INSTANCIA}/logs"
	elif [ "$SRV" = "jboss"  ]; then
		export DIRETORIO_DE_ORIGEM_LOG_SERVIDOR="${RAIZ_SRV}/${INSTANCIA}/log"
	else
		return 1
	fi

	return 0
}

# Gera uma variável global que aponta para o diretorio onde serão armazenados os logs, tanto de servidor como de aplicação.
function _cosmos.get_diretorio_destino_logs(){
	export DIRETORIO_DE_DESTINO_LOGS="$(dirname ${RAIZ_SRV})/logs/${SISTEMA}"
}

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

# Para não criar confilto na leitura e escrita de arquivos sensiveis, verificamos a existância de processos concorrente.
# Confere se existe uma outra intância de atualização do banco de dado, rotação ou compressão.
# Retorna 1 caso haja processo concorrente, 0 se não tiver.
function _cosmos.is_sessao_critica(){

	processo=0
	processo=$(( processo + $(pgrep -fc "/bin/bash ${RAIZ}/cosmos_banco_de_dado.sh") ))
	processo=$(( processo + $(pgrep -fc "/bin/bash ${RAIZ}/cosmos_rotacao.sh") ))
	processo=$(( processo + $(pgrep -fc "/bin/bash ${RAIZ}/cosmos_compressao.sh") ))

	[ "$processo" -gt 1 ] && return 1

	return 0
}

# Olha se existe dois arquivos com nome identico (com possivel "~" no final) no diretório passado em $1.
# A lista dos arquivos a conferir deve se encontrar no arquivo passado em $2, por motivo de desempenho.
# O ~ no final do nome do arquivo é colocado pelo argumento -b dos comandos cp e mv se já há um outro arquivo com o mesmo nome no diretório de destino.
# A função compara o conteudo dos dois arquivos, se for igual deleta uma copia e se não for concatena os dois
_cosmos.check_duplicados(){

	diretorio="$1"
	lista="$2"

	if [ $(grep -cE "^.*~$" "${lista}") -ne 0 ]; then
		for nome_arquivo in $(grep -E "^.*~$" "${lista}"); do

			# Deletando o "~" final
			nome_arquivo_troncado=$(echo ${nome_arquivo%?})
			grep -qE "^$nome_arquivo_troncado$" "${lista}"
			[ "$?" -ne 0 ] && continue
			_log.log -a 1 "Existe dois arquivos com o mesmo nome em ${diretorio}: ${nome_arquivo_troncado}"

			# Verificando se os dois arquivos são iguais
			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "cmp -s ${diretorio}/${nome_arquivo} ${diretorio}/${nome_arquivo_troncado}"
			if [ "$?" -eq 0 ]; then
				_log.log "Conteudo dos arquivos iguais: supressao de ${nome_arquivo}"
			else
				_log.log "Conteudo differente: concatenacao dos arquivos"
				ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo bash -c 'cat ${diretorio}/${nome_arquivo_troncado} >> ${diretorio}/${nome_arquivo}'"
			fi

			info=$(ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo rm -v ${diretorio}/${nome_arquivo_troncado}")
			_log.log "$info"
			ssh -nqi "$CHAVE_RSA" "$USUARIO_SSH"@"$HOST" "sudo mv ${diretorio}/${nome_arquivo} ${diretorio}/${nome_arquivo_troncado}"
			sed -i "/$nome_arquivo/d" "$lista"

		done < "$lista"
	fi
}
