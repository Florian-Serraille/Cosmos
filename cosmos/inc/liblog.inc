#######################################################################################################################
### liblog.inc
###
### Arquivo de funções para gerenciar a produção de log e arqivos temporarios
### Use o comando "source" para inclui-lo em seu script
###
#######################################################################################################################

#################################################### FUNÇÕES ##########################################################

# _log.construir_caminho()
function _log.construir_caminho(){
	if [ "$1" -eq 1 ]; then
		LOG_DIR="${LOG_DIR}/$(date +%y%m)"
		[ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
	fi
}

# _log.relatorio()
function _log.relatorio(){

	local estado

	while test -n "$1"; do
		case "$1" in
			-a )
			estado=1
			shift
			;;

			-f )
			estado=0
			shift
			;;

			-t )
			estado=2
			shift
			;;

			-j )
			estado=3
			shift
			thread="$1"
			shift
			;;

			* )
			echo "Erro de uso da funcao _log.log.relatorio"
			return 1
			;;
		esac
	done


	case "$estado" in

		0)
		_log.log -m -q -s "${FIM_RELATORIO}"
		cat "$MAIN_LOG" >> "${LOG_DIR}/$(date +%d).cosmos.log"
		rm "$MAIN_LOG"
		;;

		1)
		export MAIN_LOG="${LOG_DIR}/$$"
		export PID_LOG="$MAIN_LOG"
		export ARRAY_DE_PID
		[ ! -f ${MAIN_LOG} ] && _log.log -m -q -s "$LOG_CABECALHO_RELATORIO"
		export ATIVIDADE=0
		;;

		2)
		PID_LOG="${LOG_DIR}/$$"
		ARRAY_DE_PID[${#ARRAY_DE_PID[@]}]="$PID_LOG"
		;;

		3)
		for thread in ${ARRAY_DE_PID[@]}; do
			cat "${LOG_DIR}/${thread}" >> "$MAIN_LOG"
			rm "${LOG_DIR}/${thread}"
		done
		;;

	esac
}

# _log.log()
# Escreve a messagem na tela e no arquivo de log
# -a | --alerta			Coloriza a menssagem
# -d | --arquivo 		Muda o arquivo alvo do saida
# -m | --mudo			Sem saída STDOUT
# -n | --sem-quebra		Sem quebra de linha após a messagem
# -p | --prefixo 		Prefixa STDOUT
# -q | --quebraDeLinhaInicio
# -s | --sem-prefixo 	Sem prefixo no arquivo alvo do saida
function _log.log(){

	export LOG="${LOG_DIR}/$$.log"
	export prefixoArquivo="[$(date +%d/%m/%Y\ %T) PID:$$] "


	local alerta					# Define o tipo de alerta, por padrão nenhum
	local mensagem					# A messagem a ser exibida
	local prefixoSTDOUT				# Vazio por padrão
	local quebraDeLinhaInicio		# Presencia de quebra de linha no incio da linha de log, por padrão nao
	local quebraDeLinhaFim="\n"		# Presencia de quebra de linha no fim da linha de log, por padrão sim

	local identificador="Sistema: ${SISTEMA} - Host: ${HOST} - Servidor: ${SRV} - Instancia: ${INSTANCIA}"

	# Nenhum argumento é considerado como erro
	[ -z "$1" ] && echo "Erro de uso da funcao _log.log" && return 1

	# Por padrão, não mudo
	local mudo=1

	while test -n "$1"; do
		case "$1" in

			-a | --alerta )
			shift
			[ "$1" -eq 0 ] && alerta="${BBLUE}"
			[ "$1" -eq 1 ] && alerta="[ INFO: ${identificador}]\n${LOG_SIMBOLO}"
			[ "$1" -eq 2 ] && alerta="${BYELLOW}[ AVISO: ${identificador}]\n${LOG_SIMBOLO}"
			[ "$1" -eq 3 ] && alerta="${BRED}[ CRITICO: ${identificador}]\n${LOG_SIMBOLO}"
			[ "$1" -eq 4 ] && alerta="${BRED}${LOG_SIMBOLO}"
			shift
			;;

			-d | --arquivo )
			shift
			PID_LOG="$1"
			shift
			;;

			-n | --sem-quebra )
			shift
			quebraDeLinhaFim=""
			;;

			-m | --mudo )
			shift
			mudo=0
			;;

			-p | --prefixo )
			shift
			prefixoSTDOUT="$1"
			shift
			;;

			-q | --quebra )
			quebraDeLinhaInicio="\n"
			shift
			;;

			-s | --sem-prefixo )
			prefixoArquivo=""
			shift
			;;

			* )
			mensagem="$1"
			shift
			;;
		esac
	done

	# STDOUT
	[ "$mudo" -eq 1 ] && printf "${quebraDeLinhaInicio}${alerta}${prefixoSTDOUT}${mensagem}${COLOR_OFF}${quebraDeLinhaFim}"

	# Arquivo de log

	alerta=$(sed s/e\\[.\;..m// <<< $alerta)
	alerta=$(sed s/\\\\// <<< $alerta)
	printf "${quebraDeLinhaInicio}${prefixoArquivo}${alerta}${mensagem}${quebraDeLinhaFim}" >> "$PID_LOG"


}

# _log.limpa_tmp
# Delete o arquivo ou todos os arquivos do diretorio em $1
function _log.limpa_tmp(){
	if [ -f "$1" ]; then
		rm "$1"
	else
		rm "$1"/* 2>/dev/null */
	fi
}

###################################################### MAIN ###########################################################

_log.construir_caminho "$COSMOS_LOG_ROTATE"
