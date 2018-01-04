#!/bin/bash

source "${RAIZ}/cosmos_import.sh"

function _check_part_mount(){

	if [ ! -d "$EXTRACTOR_PARTITION" ]; then
		_dialog.wipe
		echo "Partição $(basename "$EXTRACTOR_PARTITION") não montada, entrar em contato com a Infra (ramais: 9825/8952)" > "${TMP_DIR}/dialog_message"
		_dialog.msgbox

		exit 1
	fi
}

# O usuário escolha a(s) aplicação(ões)
function _app(){
	
	_dialog.wipe
    echo "Escolha uma ou mais aplicacoes:" > "${TMP_DIR}/dialog_title"
	_db.ler_campo "1" > "${TMP_DIR}/dialog_tags"
    
    _dialog.buildlist
    _check_exit
    EXTRACTOR_APP_ESCOLHA="$DIALOG_ESCOLHA"
    
    if  test -z "$EXTRACTOR_APP_ESCOLHA"; then
    	_dialog.wipe
        echo "Erro" > "${TMP_DIR}/dialog_title"
        echo -e "\nEscolha pelo menos uma aplicacao\n" > "${TMP_DIR}/dialog_message"
        _dialog.msgbox
        _app
    fi
}

function _check_exit(){
    if [ "$EXIT_STATUS" -eq 1 ]; then                                                                                                                                                                                        
        exit 1
    fi
}

function _data(){
  
	_dialog.wipe
	echo "Calendario" > "${TMP_DIR}/dialog_title"
	echo -e "\nEscolhe a data dos logs desejado.\nEscolher 'Intervalo' para obter um range de data." > "${TMP_DIR}/dialog_message"
	echo "Intervalo" > "${TMP_DIR}/dialog_extra_button"
	_dialog.calendar

}

##### MAIN #####

_check_part_mount
#_app
_data