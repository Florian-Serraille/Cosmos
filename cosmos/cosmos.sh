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
trap _ctrl_c SIGINT

######################################################### Main ########################################################

# Chave para execução dos diferentes módulos, útil em caso de várias opções serem passadas na execução
menu=0
db=0
uso=0
informacao=0
rotacao=0
compressao=0

[ "$#" -eq 0 ] && menu=1

while getopts ":achirt" OPCAO ; do
	case "$OPCAO" in                                                                                                                                                                                           
		
		a)
			db=1
			;;
		
		c)
			compressao=1
			;;

		h)
			uso=1
			;;

		i)
			informacao=1
			;;

		r)
			rotacao=1
			;;	

		t)
			teste=1
			;;
	
		\?)
		echo "Opcao invalida" 
		_uso 
		exit 1
		;;
	
	esac    
done

[ "$uso" -eq 1 ] && _uso

[ "$db" -eq 1 ] && "${RAIZ}/cosmos_banco_de_dado.sh"

[ "$rotacao" -eq 1 ] && "${RAIZ}/cosmos_rotacao.sh"

[ "$compressao" -eq 1 ] && "${RAIZ}/cosmos_compressao.sh"

[ "$informacao" -eq 1 ] && "${RAIZ}/cosmos_informacoes_gerais.sh"

[ "$menu" -eq 1 ] && "${RAIZ}/cosmos_menu.sh"

######################################################### Fim ########################################################

_limpa_tmp "$TMP_DIR"

exit 0
