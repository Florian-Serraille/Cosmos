#######################################################################################################################
### libio.inc
###
### Funções para gerenciar interação Input/Output
### Use o comando "source" para inclui-lo em seu script
###
#######################################################################################################################

#################################################### FUNÇÕES ##########################################################

### Criar a funcao _io.ctrl_c
function _io.ctrl_c(){
	_log.log -a 2 ' PROCESSO INTEROMPIDO (CTRL + C)';
	_log.log.relatorio -f;
	_log.limpa_tmp ${TMP_DIR};
	exit 1 
}

