_dialog.menu(){
	
	DIALOG_ESCOLHA=$(dialog --backtitle "$DIALOG_BACKGROUND" --stdout \
			--no-items --menu "$(cat ${TMP_DIR}/dialog_title)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$DIALOG_MENU_HEIGHT" \
			$(cat ${TMP_DIR}/dialog_tags))

	DIALOG_STATUS=$(echo "$?")
}

_dialog.yes_no(){
	dialog 	--backtitle "$CONF_BACKGROUND" \
			--yesno "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH"

	DIALOG_ESCOLHA=$(echo "$?")
}

_dialog.yes_no_title(){
	dialog 	--backtitle "$CONF_BACKGROUND" \
			--title "$(cat ${TMP_DIR}/dialog_title)"	\
			--yesno "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH"

	DIALOG_ESCOLHA=$(echo "$?")
}

_dialog.msgbox(){
	
	dialog 	--backtitle "$CONF_BACKGROUND" \
			--msgbox "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH"
}

_dialog.msgbox_title(){
	
	dialog 	--backtitle "$CONF_BACKGROUND" \
			--title "$(cat ${TMP_DIR}/dialog_title)"	\
			--msgbox "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH"
}

# _calendar
# Mostra um calendario e permite ao usuário escolher uma data
# Parâmetros: título da caixa(1), mensagem acima do calendário(MENSSAGEM), dia mostrado
# na chamada do calendário no formato $CONF_DATE_FORMAT(2) sendo o dia corrente 
# se o $3 estiver nulo.
# Retorno: $EXIT_STATUS, $chosenDate

#_calendar()
#	if [ -n "$2" ]; then
#		local day=$(date -d $3 +%d);
#		local month=$(date -d $3 +%m);
#		local year=$(date -d $3 +%Y);
#	fi
#
#	CHOICE=$(dialog --backtitle "$CONF_BACKGROUND" "$CONF_ENCODING" \
#			--date-format "$DIALOG_DATE_FORMAT" \
#			--calendar "$MENSSAGEM" \
#			"$CONF_HEIGHT" "$CONF_WIDTH" \
#			"$day" "$month" "$year")
#	
#	EXIT_STATUS=$(echo "$?")
#}

_dialog.wipe(){
	> "${TMP_DIR}/dialog_title)"
	> "${TMP_DIR}/dialog_message)"
	> "${TMP_DIR}/dialog_tags)"
}
