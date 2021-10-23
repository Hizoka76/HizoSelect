#!/bin/bash

# Script sourcé par hizoselect

######################
## Gestion de stdin ##
######################

# S'il faut reprendre les propositions depuis stdin et que stdin n'est pas vide
if InArray "${ProposalsOrigin}" "1 2 3" && test ! -t 0
then
    # Découpage de stdin par les \0 : obligé de le faire si on ne veut pas perdre les \0
    mapfile -td '' stdinTemp < /dev/stdin

    # Suppression du dernier saut de ligne possiblement ajouté par l'echo du pipe
    (( ${#stdinTemp[@]} )) && stdinTemp[-1]="${stdinTemp[-1]/%$'\n'}"

    if [[ ${stdinTemp[*]} == *[[:alnum:]]* ]]
    then
        # Si le délimiteur est \0, on a déjà fait la séparation
        if [[ ${InputDelimiter} == "\0" ]]
        then
            ProposalsTemp2=("${stdinTemp[@]}")

        # Si pas de délimiteur ou si c'est \n,  on remplace les \0 par -----Hizo-----
        else
            # Gestion du délimiteur
            [[ ${InputDelimiter:-\\n} != "\n" ]] && opt="-d ${InputDelimiter}"

            mapfile -t ${opt} ProposalsTemp2 < <(printf '%s-----Hizo-----' "${stdinTemp[@]}")
        fi

        # Suppression du dernier -----Hizo----- ajouté par le printf
        ProposalsTemp2[-1]="${ProposalsTemp2[-1]/%-----Hizo-----}"

        for Temp in "${ProposalsTemp2[@]}"
        do
            # Nettoyage des espaces
            Temp="${Temp/#+( )}"
            Temp="${Temp/%+( )}"

            # Ajoute %t si besoin
            [[ ${Temp:0:1} != "%" ]] && Temp="%t=${Temp}"

            ProposalsTemp+=("${Temp}")
        done

        # S'il y a des propositions depuis stdin
        if [[ ${ProposalsTemp} ]]
        then
            # Lecture uniquement de stdin, on supprime les propositions de la commande
            (( ProposalsOrigin == 1 )) && Proposals=("")

            # Ajout des propositions de stdin en fin de liste
            (( ProposalsOrigin == 1 || ProposalsOrigin == 2 )) && Proposals=("${Proposals[@]}" "${ProposalsTemp[@]}")

            # Ajout des propositions de stdin en début de liste
            (( ProposalsOrigin == 3 )) && Proposals=("" "${ProposalsTemp[@]}" "${Proposals[@]:1}")
        fi
    fi

    unset stdinTemp Temp ProposalsTemp ProposalsTemp2
fi
