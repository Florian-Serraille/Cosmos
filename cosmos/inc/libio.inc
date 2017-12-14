#######################################################################################################################
### libio.inc
###
### Funções para gerenciar interação Input/Output
### Use o comando "source" para inclui-lo em seu script
###
#######################################################################################################################

#################################################### FUNÇÕES ##########################################################



#_validacao_SSH()
# Avalia o sucesso e o erro de um comando SSH pelo seu codigo de retorno
_avaliacao_SSH(){

	[ -z "$1" ] && echo return 1

	if [ "$1" -eq 0 ]; then

		return 0

	else

		_log -s -a 2 "SSH Erro"
		return 1

	fi
}

### Criar a funcao _ctrl_c
_ctrl_c(){
	_log -a 2 ' PROCESSO INTEROMPIDO (CTRL + C)';
	_limpa_tmp ${TMP_DIR};
	_relatorio -f;
	exit 1 
}

