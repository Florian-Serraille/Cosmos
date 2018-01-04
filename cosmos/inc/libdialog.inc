function _dialog.menu(){
	
	DIALOG_ESCOLHA=$(dialog --backtitle "$DIALOG_BACKGROUND" --stdout \
			--ascii-lines --title "$(cat ${TMP_DIR}/dialog_title)"	\
			--no-items --menu "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$DIALOG_OTHER_HEIGHT" \
			$(cat ${TMP_DIR}/dialog_tags))

	DIALOG_STATUS=$(echo "$?")
}

function _dialog.yes_no(){
	dialog 	--backtitle "$DIALOG_BACKGROUND" \
			--ascii-lines --title "$(cat ${TMP_DIR}/dialog_title)"	\
			--yesno "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH"

	DIALOG_ESCOLHA=$(echo "$?")
}

function _dialog.msgbox(){
	
	dialog 	--backtitle "$DIALOG_BACKGROUND" \
			--ascii-lines --title "$(cat ${TMP_DIR}/dialog_title)"	\
			--msgbox "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH"
}

function _dialog.calendar(){

	if [ "$1" ]; then
		dia=$(date -d ${1} +%d)
		mes=$(date -d ${1} +%m)
		ano=$(date -d ${1} +%Y)
	else
		dia="$DIA"
		mes="$MES"
		ano="$ANO"
	fi

	DIALOG_ESCOLHA=$(dialog --backtitle "$DIALOG_BACKGROUND" --stdout \
			--ascii-lines --title "$(cat ${TMP_DIR}/dialog_title)" \
			$(if [ -s ${TMP_DIR}/dialog_extra_button ]; then echo "--extra-button"; echo "--extra-label $(cat ${TMP_DIR}/dialog_extra_button)"; fi) \
			--date-format "$DIALOG_DATE_FORMAT" \
			--calendar "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH" \
			"$dia" "$mes" "$ano")
	
	EXIT_STATUS=$(echo "$?")
}

function _dialog.checklist(){

	DIALOG_ESCOLHA=$(dialog --backtitle "$DIALOG_BACKGROUND" \
			--ascii-lines --stdout --title "$(cat ${TMP_DIR}/dialog_title)"	\
			--no-items --checklist "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$DIALOG_OTHER_HEIGHT" \
			$(for word in $(cat "${TMP_DIR}/dialog_tags"); do echo "$word"; echo "off"; done))

	EXIT_STATUS=$(echo "$?")
}


function _dialog.buildlist(){

	DIALOG_ESCOLHA=$(dialog --backtitle "$DIALOG_BACKGROUND" \
			--ascii-lines --stdout --title "$(cat ${TMP_DIR}/dialog_title)"	\
			--visit-items --buildlist "$(cat ${TMP_DIR}/dialog_message)" \
			"$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$DIALOG_OTHER_HEIGHT" \
			$(for word in $(cat "${TMP_DIR}/dialog_tags"); do echo "$word"; echo "$word"; echo "off"; done))

	EXIT_STATUS=$(echo "$?")
}

function _dialog.wipe(){
	> "${TMP_DIR}/dialog_title"
	> "${TMP_DIR}/dialog_message"
	> "${TMP_DIR}/dialog_tags"
}

