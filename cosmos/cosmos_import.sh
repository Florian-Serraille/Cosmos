#!/bin/bash

for arquivo in $( ls ${RAIZ}/conf | grep -E ".*\.conf$"); do
	source "${RAIZ}/conf/${arquivo}"
done
for arquivo in $( ls ${RAIZ}/inc | grep -E ".*\.inc$"); do
	source "${RAIZ}/inc/${arquivo}"
done

[ -f "${TMP_DIR}/BD_TMP" ] && BANCO_DE_DADO="${TMP_DIR}/BD_TMP"
