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
    echo -e "Escolha uma ou mais aplicacoes:" > "${TMP_DIR}/dialog_title"
	_db.ler_campo "1" > "${TMP_DIR}/dialog_tags"
    _dialog.buildlist
    _check_exit
    EXTRACTOR_APP="$DIALOG_ESCOLHA"
    
    if  test -z "$EXTRACTOR_APP"; then
    	_dialog.wipe
        echo "Erro" > "${TMP_DIR}/dialog_title"
        echo -e "\nEscolha pelo menos uma aplicacao\n" > "${TMP_DIR}/dialog_message"
        _dialog.msgbox
        _app
    fi
}

function _check_exit(){
    if [ "$EXTRACTOR_EXIT_STATUS" -eq 1 ]; then                                                                                                                                                                                        
        exit 1
    fi
}

function _data(){
  
	_dialog.wipe
	echo "Calendario" > "${TMP_DIR}/dialog_title"
	echo -e "\nEscolhe a data dos logs desejado.\nEscolher 'Intervalo' para obter um range de data." > "${TMP_DIR}/dialog_message"
	echo "Intervalo" > "${TMP_DIR}/dialog_extra_button"
	_dialog.calendar
	_check_exit
	EXTRACTOR_DATA="$DIALOG_ESCOLHA"

	# Extra button return 3
	intervalo=1
	if [ "$EXTRACTOR_EXIT_STATUS" -eq 3 ]; then
		_dialog.wipe
		echo "Calendario" > "${TMP_DIR}/dialog_title"
		echo -e "\nPrimeira data : ${EXTRACTOR_DATA}.\nEscolhe segunda data para formar o intervalo." > "${TMP_DIR}/dialog_message"
		_dialog.calendar
		_check_exit
		EXTRACTOR_DATA_INTERVALO="$DIALOG_ESCOLHA"
		intervalo=0
	fi

	# Controle de validade da ou das datas
	local validade=0
	[ "$(date -d ${EXTRACTOR_DATA} +%Y%m%d)" -gt "$(date +%Y%m%d)" ] && validade=1
	if [ "$intervalo" -eq 0 ]; then
		[ "$(date -d ${EXTRACTOR_DATA_INTERVALO} +%Y%m%d)" -gt "$(date +%Y%m%d)" ] && validade=1
		if [ "$(date -d ${EXTRACTOR_DATA} +%Y%m%d)" -gt "$(date -d ${EXTRACTOR_DATA_INTERVALO} +%Y%m%d)" ]; then
			local tmp_date="$EXTRACTOR_DATA"
			EXTRACTOR_DATA="$EXTRACTOR_DATA_INTERVALO"
			EXTRACTOR_DATA_INTERVALO="$tmp_date"
		fi
	fi
	
	if [ "$validade" -eq 1 ]; then
		_dialog.wipe
	    echo "Erro" > "${TMP_DIR}/dialog_title"
	    echo -e "\nData: ${EXTRACTOR_DATA}$([ ${intervalo} -eq 0 ] && echo -e " ate ${EXTRACTOR_DATA_INTERVALO}")\n\nData posterior ao dia de hoje\n\n " > "${TMP_DIR}/dialog_message"
	    _dialog.msgbox
		_data
	else
		_dialog.wipe
		echo "Confirmar data ?" > "${TMP_DIR}/dialog_title"
		echo -e "\nData: ${EXTRACTOR_DATA}$([ ${intervalo} -eq 0 ] && echo -e " ate ${EXTRACTOR_DATA_INTERVALO}")\n " > "${TMP_DIR}/dialog_message"
		echo -e "Redefinir" > "${TMP_DIR}/dialog_no"
		_dialog.yes_no
		[ "$DIALOG_ESCOLHA" -eq 1 ] && _data
	fi
}

function _log(){

	_dialog.wipe
	echo "Tipo de log" > "${TMP_DIR}/dialog_title"
	echo -e "\nSelecione o tipo de log:\n " > "${TMP_DIR}/dialog_message"
	echo "Servidor Aplicacao" > "${TMP_DIR}/dialog_tags"
	_dialog.checklist
	EXTRACTOR_TIPO_LOG="$DIALOG_ESCOLHA"

}

function _ambiente(){

	_dialog.wipe
	echo "Ambiente" > "${TMP_DIR}/dialog_title"
	echo -e "\nSelecione o ambiente:\n " > "${TMP_DIR}/dialog_message"
	echo "Producao Homologacao" > "${TMP_DIR}/dialog_tags"
	_dialog.checklist
	EXTRACTOR_AMBIENTE="$DIALOG_ESCOLHA"

}

function _montar_resumo(){
	cat > "${TMP_DIR}/dialog_file" <<- EOF

		Aplicacao:		$EXTRACTOR_APP
		Data: 			$EXTRACTOR_DATA $([ $intervalo -eq 0] && echo "ate $EXTRACTOR_DATA_INTERVALO")
		Tipo de log:		$EXTRACTOR_TIPO_LOG
		Ambiente:		$EXTRACTOR_AMBIENTE
	EOF
}

function _resumo(){

	_dialog.wipe

	_montar_resumo

	echo "Resumo" > "${TMP_DIR}/dialog_title"
	_dialog.textbox
	EXTRACTOR_TIPO_LOG="$DIALOG_ESCOLHA"

}
##### MAIN #####

_check_part_mount
_app
_data
_log
_ambiente
_resumo