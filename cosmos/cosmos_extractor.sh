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
    echo "Bom dia $SUDO_USER, escolha uma aplicacao:" > "${TMP_DIR}/dialog_message"
	_db.ler_campo "1" > "${TMP_DIR}/dialog_tags"
    _dialog.menu
    #APP_NAME=$(echo "$DIALOG_ESCOLHA")
    #_check_exit $(echo $EXIT_STATUS)
}

##### MAIN #####

_check_part_mount
_app