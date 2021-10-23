 #!/bin/bash

# Script sourcé par hizoselect

###########################################
## Gestion de rangement des propositions ##
###########################################

# Liste de sortie
NewAnswers=()

# Traite les propositions de réponses
for Answer in "${Proposals[@]:1}"
do
    # Découpe les propositions en utilisant % => Il faut supprimer les \%
    mapfile -t -d '%' Arguments < <(printf "%s" "${Answer}")

    # Sert à savoir ce qu'il reste
    TempAnswer="${Answer}"

    # Nouvelle ligne de proposition
    NewAnswer=""

    # Traite chaque argument de la proposition
    for Argument in "${Arguments[@]}"
    do
        # Saute les arguments vides
        [[ -z ${Argument} ]] && continue

        # Affiche en 1er les éléments à trier
        for Type in "${SortType[@]}"
        do
            if [[ ${Argument:0:1} == ${Type//%} ]]
            then
                # Ajoute l'argument en fin de la nouvelle proposition
                NewAnswer+="%${Argument/% }"

                # Supprime l'argument de ce qu'il faudra ajouter à la fin
                TempAnswer="${TempAnswer/\%${Argument}}"

                # Arrêt de la boucle
                break
            fi
        done
    done

    # Ajoute la nouvelle proposition à la liste temporaire
    if [[ ${NewAnswer} ]]; then NewAnswers+=("${NewAnswer} ${TempAnswer}")
    else NewAnswers+=("${TempAnswer}"); fi # Pour ne pas ajouter l'espace en trop qui empêche la comparaison ci-dessous
done

# Nouvelle liste de proposition rangée si différentes
[[ "${Proposals[*]}" != "${NewAnswers[*]}" ]] && readarray -t Proposals < <(printf "\n%s" "${NewAnswers[@]}" | sort)

# Nettoyage
unset TempAnswer NewAnswer NewAnswers Answer
