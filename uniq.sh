 #!/bin/bash

# Script sourcé par hizoselect

###############################################
## Gestion de dédoublonnage des propositions ##
###############################################

AntiDoublon=()
NewAnswers=()

# Traite les propositions de réponses
for Answer in "${Proposals[@]:1}"
do
    # Saute la proposition si elle n'a pas l'argument de tri
    if [[ "${Answer}" != *${UniqueItem}* ]]
    then
        NewAnswers+=("${Answer}")
        continue
    fi

    # Découpe les propositions en utilisant % => Il faut supprimer les \%
    mapfile -t -d '%' Arguments < <(printf "%s" "${Answer}")

    # Traite chaque argument de la proposition
    for Argument in "${Arguments[@]}"
    do
        Argument="${Argument/%+([[:space:]])}"

        # Saute les arguments vides
        [[ -z ${Argument} ]] && continue

        # Saute les arguments non concernés
        [[ "${UniqueItem}" != "%${Argument:0:1}" ]] && continue

        if ! InArray "${Argument}" "${AntiDoublon[*]}"
        then
            NewAnswers+=("${Answer}")
            AntiDoublon+=("${Argument}")
            break
        fi
    done
done

# Nouvelle liste de proposition rangée si différentes et non vide
[[ "${Proposals[*]}" != "${NewAnswers[*]}" ]] && readarray -t Proposals < <(printf "\n%s" "${NewAnswers[@]}")

# Nettoyage
unset AntiDoublon NewAnswers
