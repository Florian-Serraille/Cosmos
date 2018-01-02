#!/bin/bash

#######################################################################################################################
###
### cosmos.sh [-ah]
### 
### Executável de Cosmos
### Ver leiame.txt para mais informações
###
#######################################################################################################################

################################################# Inclusão e Configuração #############################################
                                                                                              
if [ "$UID" -ne "0" ]; then
	echo "Erro: Cosmos exige privilegio root"
	echo "Use: sudo cosmos.sh"
	exit 1
fi

export RAIZ="/usr/local/scripts/cosmos"

#Importação das variaveis e dos includes
source ${RAIZ}/cosmos_import.sh 

# Capturando sinal de interrupcao (CTRL+C)
trap _io.ctrl_c SIGINT

######################################################### Main ########################################################

# Chave para execução dos diferentes módulos, útil em caso de várias opções serem passadas na execução
menu=0
db=0
uso=0
informacao=0
rotacao=0
compressao=0

[ "$#" -eq 0 ] && menu=1

while test -n "$1"; do
	case "$1" in                                                                                                                                                                                           
		
		# Atualiza o banco de dado textual
		-a | --atualiza)
			db=1
			shift
			;;
		# Inicializa a compressão dos logs
		-c | --compressao)
			compressao=1
			shift
			;;

		# Mostra as informações gerais do sistema Cosmos
		-i | --informacao)
			informacao=1
			shift
			;;
		
		# Inicializa a rotação dos logs
		-r | --rotacao)
			rotacao=1
			shift
			;;	

		# Informe o(s) sistema(s) em que deve(m) ser aplicado(s) as demais opções, filtra no banco de dado
		-f | --filtra-db )
			shift
			export filtro="$1"
			shift
			;;

		# Mostra a ajuda e as opções de uso
		-u | --uso)
			uso=1
			shift
			;;

		*)
			echo "Opcao invalida" 
			_uso
			exit 1
			;;
	
	esac 
done

[ "$uso" -eq 1 ] && _uso

[ "$db" -eq 1 ] && "${RAIZ}/cosmos_banco_de_dado.sh"

[ "$filtro" ] && _cosmos.filtra_db

[ "$rotacao" -eq 1 ] && "${RAIZ}/cosmos_rotacao.sh"

[ "$compressao" -eq 1 ] && "${RAIZ}/cosmos_compressao.sh"

[ "$informacao" -eq 1 ] && "${RAIZ}/cosmos_informacoes_gerais.sh"

[ "$menu" -eq 1 ] && "${RAIZ}/cosmos_menu.sh"

######################################################### Fim ########################################################

_log.limpa_tmp "$TMP_DIR"

exit 0

