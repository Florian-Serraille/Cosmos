#!/bin/bash

#######################################################################################################################
################################################# Inclusão e Configuração #############################################
#######################################################################################################################

source "${RAIZ}/cosmos_import.sh"

#######################################################################################################################
######################################################## Função #######################################################
#######################################################################################################################

_menu_principal(){

  local opcao_menu="1"

  while [ "$opcao_menu" != "0" ]; do

    _cosmos.limpa_tela "\nMenu Principal:\n"

    for (( i=0; i < ${#MENU_PRINCIPAL[@]}; i++ )){
      echo "$i) ${MENU_PRINCIPAL[$i]}"
    }

    echo -en "$MENU_RESPOSTA"

    read opcao_menu

    case $opcao_menu in

      1) _menu_configuracao ;;

      2) _menu_administracao ;;

      3) "${RAIZ}/cosmos_informacoes_gerais.sh"
      read -p "Pressiona ENTER para continuar"
      ;;

      0) return 0 ;;

      *) ;;

    esac
  done

}

_menu_configuracao(){

  local opcao_menu="1"

  while [ "$opcao_menu" != "0" ]; do


    _cosmos.limpa_tela "\nMenu Configuracao:\n"

    for (( i=0; i < ${#MENU_CONFIGURACAO[@]}; i++ )){
      echo "$i) ${MENU_CONFIGURACAO[$i]}"
    }

    echo -en "$MENU_RESPOSTA"

    read opcao_menu

    case $opcao_menu in

      1)
      "${RAIZ}/cosmos.sh" -a
      read -p "Pressiona ENTER para continuar"
      ;;

      0) return 0 ;;

      *) ;;

    esac
  done

}

_menu_administracao(){

  local opcao_menu="1"

  while [ "$opcao_menu" != "0" ]; do

    local lista_do_menu[0]="Sair"

    _cosmos.limpa_tela "\nMenu Administracao:\n"

    for (( i=0; i < ${#MENU_ADMINISTRACAO[@]}; i++ )){
      echo "$i) ${MENU_ADMINISTRACAO[$i]}"
    }

    echo -en "$MENU_RESPOSTA"

    read opcao_menu

    case $opcao_menu in

      0) return 0 ;;

      1)
      "${RAIZ}/cosmos.sh" -r -c
      read -p "Pressiona ENTER para continuar"
      ;;

      2)
      "${RAIZ}/cosmos.sh" -e
      read -p "Pressiona ENTER para continuar"
      ;;

      *) ;;

    esac
  done

}

#######################################################################################################################
########################################################    Main    ###################################################
#######################################################################################################################

_menu_principal
