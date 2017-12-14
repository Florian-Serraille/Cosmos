#!/bin/bash

for arquivo in $( ls ${RAIZ}/conf | grep -E ".*\.conf$"); do
	source "${RAIZ}/conf/${arquivo}"
done
for arquivo in $( ls ${RAIZ}/inc | grep -E ".*\.inc$"); do
	source "${RAIZ}/inc/${arquivo}"
done
