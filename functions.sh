 #!/bin/bash

# Script sourcé par hizoselect


#############################################
## Surveillance de l'utilisation de ctrl+c ##
#############################################
### Si ctrc+c est utilisé, on restaure le curseur avant de quitter en erreur
function ctrl_c { ExitErreur; }
trap ctrl_c INT


##########################################
## Recherche un élément dans un tableau ##
##########################################
# Fonctionne aussi pour rechercher une clé dans un tableau indexé si l'array est ${!x[*]}
function InArray
{
    # $1 : la valeur recherchée
    # $2 : l'array

    # Si on retrouve la valeur dans l'array, on renvoie 0
    [[ ${2} =~ (^|[[:space:]])${1}($|[[:space:]]) ]] && return 0

    # Sinon, on renvoie 1
    return 1
}



##################################
## Fonction de sortie en erreur ##
##################################
### Fonction arrêtant la commande en mode erreur avec le texte d'erreur
function ExitErreur
{
    # Message d'erreur
    [[ ${@} ]] && ErrorMessage 1 "${@}" 0

    # Renvoie le texte Exit avec saut de ligne esthétique
    (( ${Debug} )) && echo -e "\nExit" >&2

    echo >&2

    # Débloque l’expansion de ? et de *
    set +f

    # Arrêt "problématique"
    exit 1
}



######################
## Message d'erreur ##
######################
### Fonction affichant un message d'erreur
function ErrorMessage
{
    # $1 : 0 ou 1 : Si 1 pas de retour chariot mais un saut de ligne sinon retour chariot mais pas de saut de ligne
    # $2 : nom du message à afficher séparé de ses variables par @ : nom@variable1@variable2@Variable3
    # $3 : 0 ou 1 : Ajouter LastText

    # Si pas de nom de message ou qu'on n'affiche pas les messages d'erreur
    [[ -z ${2} || ${Debug} -eq 0 ]] && return 1

    # Chargement des couleurs si besoin
    [[ -z ${Effects} ]] && EffectsSetUp 1

    local Start End AllVar

    End="${Unset}"
    Start="${Effects["Error"]}"

    # S'il y a un message du genre LastText
    (( ${3} )) && End+=" ${LastText}"

    # Saut de ligne ou retour chariot
    if (( ${1} )); then End+="\n"
    else Start="\r${Clear}${Start}"; fi

    # Séparation du texte et de ses variables, echo évite l'ajout d'un saut de ligne au dernier item de la liste présent avec <<< "$2"
    mapfile -t -d "@" AllVar < <(echo -n "${2}")

    # Affichage du message d'erreur avec les différentes variables
    [[ ${Name} ]] && FinalName="${Name}: "

    printf "%b%s$(LangText "${AllVar[0]}")%b" "${Start}" "${FinalName}" "${AllVar[@]:1}" "${End}" >&2
}



#######################################
## Fonction de vérification de plage ##
#######################################
function RangeCheck
{
    # Retour 0 : La plage est valide
    # Retour 1 : La plage est invalide

    # ${1} : valeur à tester
    local MinValue=${1%-*} MaxValue=${1#*-}

    # Si Max n'existe pas
    if [[ -z ${MaxValue} ]]
    then
        ErrorMessage 0 "error_range_max" 1
        return 1

    # Min est plus grand que max
    elif (( ${MinValue} >= ${MaxValue} ))
    then
        ErrorMessage 0 "error_numbers" 1
        return 1

    # Min est obligatoirement dans la liste car sinon impossible de taper le -
    # Max n'existe pas dans la liste
    elif ! InArray "${MaxValue}" "${!Proposals[*]}"
    then
        ErrorMessage 0 "error_choice@${MaxValue}" 1
        return 1
    fi

    # Si tout s'est bien passé
    return 0
}



############################################################
## Création d'une liste numérique avec conservation des ? ##
############################################################
function AnswerNumbers
{
    # Variables locales
    local Answer

    # Destruction de la variable globale
    unset AnswerList

    # Teste les réponses une à une en commençant par les forcées
    for Answer in "${ForceAnswers[@]}" "${Answers[@]}"
    do
        # Si c'est un nombre ou un aléatoire, ajout de la valeur
        if [[ ${Answer} == +([0-9?]) ]]; then AnswerList+=("${Answer}")

        # Si c'est *, ajout de toutes les propositions
        elif [[ ${Answer} == "*" ]]; then AnswerList+=("${!Proposals[@]}")

        # Si c'est une plage, ajout de ses valeurs
        elif [[ ${Answer} == *"-"* ]]; then AnswerList+=($(seq "${Answer%-*}" "${Answer#*-}")); fi
    done

    # L'appelant de la fonction doit utiliser la liste AnswerList
}




###############################################
## Fonction recherchant les suites possibles ##
###############################################
function AnswerCheck
{
    # Code 0 : Le nombre peut avoir un nouveau chiffre ajouté et est lui-même disponible
    # Code 1 : Le nombre peut avoir un nouveau chiffre ajouté mais n'est lui-même plus disponible
    # Code 2 : Le nombre ne peut avoir un nouveau chiffre ajouté (car déjà tous utilisés) mais est lui-même disponible
    # Code 3 : Le nombre ne peut avoir un nouveau chiffre ajouté (car déjà tous utilisés) et n'est lui-même plus disponible
    # Code 4 : Le nombre n'existe pas
    # Code 5 : Le nombre commence par un 0

    ## Variables locales
    local BiggerNumbers Item Answer AlreadyUsed ND_Number="${1}"

    ## Arrêt de la fonction si le chiffre commence par 0
    if (( ! ${ND_Number:0:1} ))
    then
        ErrorMessage 0 "error_zero@$(LangText "answer")" 1
        return 5
    fi

    ## Arrêt de la fonction si le nombre n'existe pas
    if ! InArray "${ND_Number}" "${!Proposals[*]}"
    then
        ErrorMessage 0 "error_choice@${ND_Number}" 1
        return 4
    fi

    ## Regarde si la valeur est déjà utilisée
    InArray "${ND_Number}" "${AnswerList[*]}" && AlreadyUsed=1

    ## Création d'une liste contenant tous les nombres commençants par ${ND_Number}
    for Item in "${!Proposals[@]}"
    do
        [[ ${Item} == ${ND_Number}+([0-9]) ]] && BiggerNumbers+=("${Item}")
    done

    ## S'il est possible de créer des nombres commençants par ${ND_Number}
    if [[ ${BiggerNumbers[*]} ]]
    then
        # Si Uniq ne rentre pas en ligne de compte, pas de vérification à faire
        # Le nombre peut avoir un nouveau chiffre ajouté et est lui-même disponible
        (( ! ${Uniq} )) && return 0

        # Vérifie s'il reste des nombres plus grands non utilisés
        for Item in "${BiggerNumbers[@]}"
        do
            # Si un nombre est dispo
            if ! InArray "${Item}" "${AnswerList[*]}"
            then
                # Arrêt de la fonction en indiquant que le nombre peut avoir un nouveau chiffre associé et si le nombre est lui-même disponible
                [[ ${AlreadyUsed} ]] && return 1
                return 0
            fi
        done

        # Si le nombre est déjà donné
        if [[ ${AlreadyUsed} ]]
        then
            # Le nombre ne peut avoir un nouveau chiffre ajouté car déjà tous utilisés et n'est lui-même plus disponible
            ErrorMessage 0 "error_used@${ND_Number}" 1
            return 3
        fi

        # Le nombre ne peut avoir un nouveau chiffre ajouté car déjà tous utilisés mais est lui-même disponible
        return 2

    ## Le nombre ne peut avoir un nouveau chiffre ajouté et est déjà utilisé en mode unique
    elif (( ${#AlreadyUsed} && ${Uniq} ))
    then
        ErrorMessage 0 "error_used@${ND_Number}" 1
        return 3
    fi

    ## Le nombre ne peut avoir un nouveau chiffre ajouté mais est lui-même disponible
    return 2
}




########################
## Lecture de réponse ##
########################
### Fonction renvoyant un listing de réponses forcées ou par défaut
function AnswerRead
{
    # $1 : valeur de l'argument --force ou --answers
    # $2 : Argument concerné : default ou force
    # Nécessite ${Proposals[@]}

    # Variables locales
    local AnswersTemp Answers Answer Number AddAnswer Num SubNum RandomNb RandomMax Temp

    # Nombre de valeur aléatoire
    RandomMax="${1//[^?]}"
    RandomMax="${#RandomMax}"

    # Gestion des %d et %f présents dans les propositions
    for Number in "${!Proposals[@]}"
    do
        [[ ${Proposals[${Number}]} == *%${2:-vide}* ]] && Answers+=(${Number})
    done

    # protection des \| si présents dans les textes recherchés
    Temp="${1//|/&&&&&Hizo&&&&&/}"

    # Remplace les espaces protégés par _____Hizo_____
    Temp="${Temp//\\ /_____Hizo_____}"

    # Remplace les espaces par des |
    Temp="${Temp// /|}"

    # Création d'un tableau des réponses, echo pour ne pas ajouter de saut de ligne avec <<< $1
    mapfile -t -d '|' AnswersTemp < <(echo -n "${Temp}")

    # Lit chaque valeurs par défaut
    for Answer in "${AnswersTemp[@]}"
    do
        # Nettoyage de la réponse, suppression des espaces et remise en place du |
        Answer="${Answer/#+( )/}"
        Answer="${Answer/%+( )/}"
        Answer="${Answer/#+(0)/}"
        Answer="${Answer//&&&&&Hizo&&&&&/|}"
        Answer="${Answer//_____Hizo_____/ }"

        # Si utilisation de *, on les veut tous
        [[ ${Answer} == '*' ]] && Answer=

        # Mode numérique, Il peut y avoir plusieurs nombres avec ou non une plage, séparés par des , ou ; ou des espaces
        if [[ ${Answer} == +([-0-9 ,;?]) ]]
        then
            # Remplacement des , et ; par des espaces pour traiter séparément les nombres
            for SubNum in ${Answer//[,\;]/ }
            do
                SubNum="${SubNum/#*(0)/}"

                # Mode numéro simple
                if [[ ${SubNum} == [1-9]?([0-9]*) && ${Proposals[${SubNum}]} ]]
                then
                    AddAnswer+="${SubNum} "

                # Mode plage
                elif [[ ${SubNum} =~ ^([1-9][0-9]*)-([0-9]*)$ ]]
                then
                    # Suppression des 0 en début du nombre max
                    for ((Num = ${BASH_REMATCH[1]}; Num <= ${BASH_REMATCH[2]/#*(0)/}; Num++))
                    do
                        # Si le numéro correspond
                        [[ ${Num} == [1-9]?([0-9]*) && ${Proposals[${Num}]} ]] && AddAnswer+="${Num} "
                    done

                # Mode aléatoire
                elif [[ ${SubNum} == '?' && ${RandomMax} -gt ${RandomNb} ]]
                then
                    ((RandomNb++))
                    AddAnswer+="? "
                fi
            done

        # Mode Texte et *
        else
            # Tourne sur les propositions
            for Number in "${!Proposals[@]}"
            do
                [[ ${Proposals[${Number}]} == *"${Answer}"* ]] && AddAnswer+="${Number} "
            done
        fi

        # S'il faut ajouter une réponse
        if [[ ${AddAnswer} ]]
        then
            # Si la réponse est déjà présente
            if [[ ${Number} != '?' ]] && InArray "${Number}" "${Answers[*]}"
            then
                # On ne l'ajoute que si le mode Uniq est à 0
                (( ! ${Uniq} )) && Answers+=(${AddAnswer})

            # Si la réponse n'est pas présente, on l'ajoute
            else
                Answers+=(${AddAnswer})
            fi
        fi

        # Suppression de la variable temporaire
        unset AddAnswer
    done

    # Renvoi de la liste des réponses
    echo "${Answers[*]}"
}



###########################################################################################
## Fonction vérifiant qu'il est possible d'ajouter la réponse aux autres déjà existantes ##
###########################################################################################
function LimitCheck
{
    # Code 0 : OK on peut ajouter la valeur
    # Code 1 : On ne peut pas l'ajouter, car la limite est atteinte

    # Il reste de la place
    (( ! ${Max} || ${#AnswerList[@]} < ${Max} )) && return 0

    # Il n'y a plus la place pour ajouter la réponse
    ErrorMessage 0 "error_limit_max" 1
    return 1
}



#######################################################################
## Gestion vérification des valeurs des options --force et --answers ##
#######################################################################

function CheckArgValue
{
    # L'appelant doit créer la liste CAV_Answers avant
    # $1 : force ou answers

    local TempList

    # Vérifications en lien avec le mode all
    [[ ${CAV_Answers[*]} == *"*"* && ${#CAV_Answers[@]} -gt 1 ]] && ExitErreur "error_default_star@--${1}"

    (( ! ${All} )) && [[ ${CAV_Answers[*]} == *"*"* ]] && ExitErreur "error_default_mode@--${1}@*@all"

    # Vérification en lien avec le mode random
    (( ! ${Random} )) && [[ ${CAV_Answers[*]} == *"?"* ]] && ExitErreur "error_default_mode@--${1}@?@random"

    # Vérification en lien avec le mode range
    (( ! ${Range} )) && [[ ${CAV_Answers[*]} == *"-"* ]] && ExitErreur "error_default_mode@--${1}@-@range"

    # Vérifie les valeurs par défaut
    for Number in "${CAV_Answers[@]}"
    do
        # Si la valeur est ? ou *, on saute le tour
        [[ ${Number} == [?*] ]] && continue

        # Si le chiffre commence par un 0, on arrête là
        [[ ${Number:0:1} == "0" ]] && ExitErreur "error_zero@--${1}"

        # Si c'est une plage
        if [[ ${Number} == *-* ]]; then RangeCheck "${Number}" || ExitErreur "error_range@--${1}"

        # Vérifie que le nombre est bien dispo dans la liste
        elif ! InArray "${Number}" "${!Proposals[*]}"; then ExitErreur "error_default_check@--${1}@${Number}"; fi

        # Cas spécifique à --answers
        if [[ ${1} == "answers" ]]
        then
            # Remplissage de la liste temporaire qui ne contiendra pas de doublon avec --force
            (( ${Uniq} && ${#ForceAnswers[*]} )) && ! InArray "${Number}" "${AnswerList[*]}" && TempList+=("${Number}")
        fi
    done

    # Cas spécifique à --answers et au mode unique
    # Remplacement de ${answers} par ${TempList} qui ne contient pas de doublons avec --force
    (( ${Uniq} )) && [[ ${1} == "answers" && ${ForceAnswers[*]} ]] && Answers=("${TempList[@]}")

    # Récupération de la liste des réponses
    AnswerNumbers

    # Vérifie que le nombre de valeur par défaut ne dépasse pas le max
    (( ${Max} && ${#AnswerList[@]} > ${Max} )) && ExitErreur "error_default_limit@--${1}@${Number}"
}




#####################################
## Système de gestion des couleurs ##
#####################################

function EffectsSetUp
{
    # Remplacement de tput par les textes qui sont bien plus rapides

    # Destruction du tableau
    unset Effects Unset

    # Déclaration du tableau
    declare -Ag Effects

    # Si on active la couleur
    if (( ${1} ))
    then
        # Déclaration de la valeur de réinitialisation
        Unset="\e[0m"

        # Boucle sur les différents noms de couleur
        for Key in "${!DefineEffects[@]}"
        do
            # Boucle sur les effets, tput a été remplacé par les textes qui sont bien plus rapides
            for Effect in ${DefineEffects[$Key]//\// }
            do
                Effect="${Effect,,}"

                # Si c'est un nombre, c'est la couleur du texte
                if [[ ${Effect} == +([0-9]) ]]
                then
                    Effects[${Key}]+="\e[38;5;${Effect}m"

                # Si c'est un bg + un nombre
                elif [[ ${Effect} == bg+([0-9]) ]]
                then
                    Effects[${Key}]+="\e[48;5;${Effect/#bg}m"

                # Si c'est un effet de texte
                elif [[ ${Effect,,} == @(bold|blink|dim|rev|smul|smso) ]]
                then
                    case ${Effect,,} in
                        "bold") Effects[${Key}]+="\e[1m" ;;
                        "blink") Effects[${Key}]+="\e[5m" ;;
                        "dim") Effects[${Key}]+="\e[2m" ;;
                        "smso") Effects[${Key}]+="\e[7m" ;;
                        "smul") Effects[${Key}]+="\e[4m" ;;
                    esac

                # Dans les autres cas, message d'erreur
                else
                    (( ${Debug} )) && echo -e "${Effects["Error"]}$(LangText "error_effects")${Unset}" >&2; exit 1
                fi
            done
        done
    fi
}





#########################################
## Système de lecture des propositions ##
#########################################

function FormatReader
{
    # ${1} : Texte
    # ${2} : Variable à utiliser
    # ${3} : Sert à modifier les textes avec ces nouvelles valeurs

    # Vérifie que les variables sont là
    [[ -z ${1} || -z ${2} || -z ${3} ]] && return 1

    # Destruction de la variable
    unset Item

    # Déclaration du tableau global
    declare -Ag Item

    # Tout de suite car le nettoyage se fait en fonction des %
    local Line TextTemp Arguments Argument ProposalsNb

    # Découpe en fonction des %, utilisation de echo car sinon ça ajoute un saut de ligne en fin avec <<< $1
    mapfile -t -d '%' Arguments < <(echo -n "${1//\\%/¦¦¦¦¦Hizo¦¦¦¦¦}")

    # Remplissage du tableau
    for Argument in "${Arguments[@]}"
    do
        Argument="${Argument/%+( )}"
        [[ ${Argument:0:2} == [${LettresOK}]= ]] && Item["${Argument:0:1}"]="${Argument:2}"
    done

    # Si rien n'est indiqué, on utilise t
    [[ -z "${Item[*]}" ]] && Item["t"]="${1/%+( )}"

    # Si c'est pour input ou output
    local VarTemp="${InputText}"
    [[ ${2} == "OutputText" ]] && local VarTemp="${OutputText}"

    # Protection des < > et |
    VarTemp="${VarTemp//\\</@@@@@Hizo@@@@@}"
    VarTemp="${VarTemp//\\>/#####Hizo#####}"
    VarTemp="${VarTemp//\\|/&&&&&Hizo&&&&&}"

    # Si la variable contient un <
    if [[ ${VarTemp} == *"<"* ]]
    then
        # Ce qui se trouve avant <
        Lines=("${VarTemp%%<*}")

        # Maj de la variable
        VarTemp="<${VarTemp#*<}"

        # Traitement des textes entre <>
        while [[ ${VarTemp} == *[\<\>]* ]]
        do
            # Texte entre <>
            TextTemp="${VarTemp/#<}" TextTemp="${TextTemp%%>*}"

            # Ajout du texte en remettant les <>
            Lines+=("<${TextTemp}>")

            # Maj de la variable
            VarTemp="${VarTemp#*>}"

            # Ajout de ce qui se trouve après si autre
            if [[ ${VarTemp} == *"<"* ]]
            then
                TextTemp="${VarTemp%%<*}"
                Lines+=("${TextTemp}")
                VarTemp="<${VarTemp#*<}"
            fi
        done

        # Ce qui se trouve après les <>
        Lines+=("${VarTemp}")

    # Si la variable est simple
    else
        Lines=("${VarTemp}")
    fi

    # Nombre de proposition
    ProposalsNb=${#Proposals[@]}

    # Ajoute, si besoin, des espaces pour que toutes les propositions soient alignées
    Item["n"]=${3}
    [[ ${2} == "InputText" ]] && printf -v Item["n"] "%${#ProposalsNb}d" "${3}"

    # Texte d'entrée
    for Line in "${Lines[@]}"
    do
        # Si la ligne est vide on saute le tour
        [[ -z ${Line} ]] && continue

        # Nettoyage
        Line="${Line/#<}"
        Line="${Line/%>}"

        # Remplace les variables par leurs valeurs
        for val in "${!Item[@]}"
        do
            # Si la variable est présente dans la ligne
            if [[ ${Line} == *"%${val}"* ]]
            then
                # Pour le output, unset Effects ne suffit pas, ça peut planter si le texte commence par un u ?
                if [[ ${2} == "InputText" ]]; then Line="${Line//%${val}/${Effects[${val}]}${Item[${val}]}${Unset}}"
                else Line="${Line//%${val}/${Item[${val}]}}"; fi
            fi
        done

        # Si la ligne contient des "ou"
        if [[ ${Line} == *"|"* ]]
        then
            # Variables locales
            local VarTest Part

            # Découpe en fonction des | avec echo pour ne pas ajouter de saut de ligne avec <<< $Line
            mapfile -t -d "|" Part < <(echo -n "${Line}")

            # Traite chaque partie (séparée par |) tant qu'on trouve des variables
            for Value in "${Part[@]}"
            do
                # S'il n'y a plus de variable
                if [[ ${Value} != *%[${LettresOK}]* ]]
                then
                    Line="${Value}"
                    VarTest=1
                    break
                fi
            done

            # S'il reste des variables on n'ajoute pas le texte
            [[ -z ${VarTest} ]] && continue
        fi

        # Déprotection des < > et | et %
        Line="${Line//@@@@@Hizo@@@@@/<}"
        Line="${Line//#####Hizo#####/>}"
        Line="${Line//&&&&&Hizo&&&&&/|}"
        Line="${Line//¦¦¦¦¦Hizo¦¦¦¦¦/%}"

        if [[ ${2} == "InputText" ]]; then Line="${Line//-----Hizo-----/}"
        else Line="${Line//-----Hizo-----/\\0}"; fi

        # Ajout du texte
        Item["Line"]+="${Line}"
    done
}



###################################
## Système d'affichage du prompt ##
###################################

function LastText
{
    # $1 : Indique s'il faut l'afficher ou non

    # Texte de base, utilise PromptText ou LangText "prompt_text" et ajoute ${PromptTextForce} ici pour la gestion de la couleur
    TexteBase="${Unset}${Effects["Prompt"]}${PromptText:-$(LangText "prompt_text")}${Unset}${Effects["Error"]}${PromptTextForce}${Unset}"

    if [[ ${Answers[*]} && ${AnswerTemp} ]]
    then
        LastText="${Effects["t"]}${TexteBase}${Effects["OK"]}${Answers[*]} ${Effects["Maybe"]}${AnswerTemp}${Unset}"

    elif [[ ${#Answers[@]} -eq 1 ]]
    then
        if (( ${#AnswerList[@]} == ${Max} )); then LastText="${Effects["t"]}${TexteBase}${Effects["Last"]}${Answers[-1]}${Unset}"
        else LastText="${Effects["t"]}${TexteBase}${Effects["OK"]}${Answers[*]} ${Unset}"; fi

    elif [[ ${Answers[*]} ]]
    then
        if (( ${#AnswerList[@]} == ${Max} )); then LastText="${Effects["t"]}${TexteBase}${Effects["OK"]}${Answers[*]::$((${#Answers[@]} - 1))} ${Effects["Last"]}${Answers[-1]}${Unset}"
        else LastText="${Effects["t"]}${TexteBase}${Effects["OK"]}${Answers[*]} ${Unset}"; fi

    elif [[ ${AnswerTemp} ]]
    then
        LastText="${Effects["t"]}${TexteBase}${Effects["Maybe"]}${AnswerTemp}${Unset}"

    else
        LastText="${Effects["t"]}${TexteBase}${Unset}"
    fi

    if (( ${1} == 1 )); then echo -en "\r${Clear}${LastText}" >&2
    elif (( ${1} == 2 )); then echo -en "${LastText}" >&2; fi
}




####################################
## Système d'affichage des textes ##
####################################

function DisplayTexts
{
    ######################
    # Affichage du titre #
    ######################
    [[ ${Title} ]] && printf "%b%s%b" "${Effects["Title"]}" "${Title}" "${Unset}" >&2

    # S'il y a une limite basse et haute
    if (( ${Max} && ${Min} ))
    then
        if (( ${Min} == ${Max} )); then printf " (%b$(LangText "title_min_max_equal" ${Max})%b)\n" "${Effects["OK"]}" "${Max}" "${Unset}" >&2
        else printf " (%b$(LangText "title_min_max")%b)\n" "${Effects["OK"]}" "${Min}" "${Max}" "${Unset}" >&2; fi

    # S'il y a une limite haute
    elif (( ${Max} ))
    then
        printf " (%b$(LangText "title_max" "${Max}")%b)\n" "${Effects["OK"]}" "${Max}" "${Unset}" >&2

    # S'il y a une limite basse
    elif (( ${Min} ))
    then
        printf " (%b$(LangText "title_min" "${Min}")%b)\n" "${Effects["OK"]}" "${Min}" "${Unset}" >&2

    else
        printf "\n" >&2
    fi


    ######################
    # Affichage du texte #
    ######################
    [[ ${Text} ]] && printf "%b\n" "${Text}" >&2


    ##############################
    # Affichage des propositions #
    ##############################
    ## Mode colonnes
    if (( Columns ))
    then
        for Number in "${!Proposals[@]}"
        do
            # Remplissage du tableau
            FormatReader "${Proposals[${Number}]}" "InputText" "${Number}"

            # Affichage de la proposition
            echo -e "${Unset}${Item["Line"]}${Unset}"
        done | column -x >&2

    ## Mode sans colonnes
    else
        for Number in "${!Proposals[@]}"
        do
            # Remplissage du tableau
            FormatReader "${Proposals[${Number}]}" "InputText" "${Number}"

            # Affichage de la proposition
            echo -e "${Unset}${Item["Line"]}${Unset}" >&2
        done
    fi


    #########################
    # Affichage des actions #
    #########################
    # Si on ne doit pas utiliser la barre
    [[ -z ${Bar} ]] && return

    local Actions

    # Traitement des options une à une
    for ((x=0; x<${#Bar}; x++))
    do
        # Création de tableaux contenant les informations
        case "${Bar:${x}:1}" in
            "${HelpLetter}")
                DefaultText=$(LangText info_help_on) ;;

            "${EffectLetter}")
                DefaultText=$(LangText info_effect_on)
                [[ ${Effects["Exists"]} ]] && DefaultText=$(LangText info_effect_off) ;;

            "${ViewLetter}")
                if (( ${ColumnExists} ))
                then
                    DefaultText=$(LangText info_view_on)
                    (( ${Columns} )) && DefaultText=$(LangText info_view_off)

                else
                    continue
                fi ;;

            "${DebugLetter}")
                DefaultText=$(LangText info_debug_on)
                (( ${Debug} )) && DefaultText=$(LangText info_debug_off) ;;

            "${LangLetter}")
                if [[ ${LANGUAGE:0:2} == "en" ]]; then DefaultText=$(LangText info_lang_on)
                else DefaultText=$(LangText info_lang_off); fi ;;

            "${ExitLetter}")
                DefaultText=$(LangText info_exit_on) ;;
        esac

        # Remplissage de la ligne d'information
        Actions+=("${Unset}[${Effects["ActKey"]}${Bar:${x}:1}${Unset}] ${Effects["ActName"]}${DefaultText}${Unset} - ")
    done

    # Destruction du dernier -
    Actions[-1]="${Actions[-1]/% - }"

    # Affichage de l'aide
    echo -e "\n${Actions[*]}" >&2
}



###################################################
## Gestion des textes US et de leurs traductions ##
###################################################

# Variable importante pour le mode sans installation
[[ "${0,,}" != "/usr/bin/hizoselect" ]] && export TEXTDOMAINDIR="."
export TEXTDOMAIN=hizoselect
[[ -z ${LANGUAGE} ]] && export LANGUAGE="${LANG::2}"

function LangText
{
# Utilisation d'une fonction appelée à chaque besoin pour éviter le temps de chargement de toutes les valeurs
# Pour remplacer %s et %d par leurs valeurs, il faut utiliser printf

# https://www.gnu.org/software/gettext/manual/gettext.html
# http://pology.nedohodnik.net/doc/user/en_US/ch-poformat.html

# pour extraire les textes dans un fichier pot :
# xgettext --msgid-bugs-address=hizo@free.fr --package-name=hizoselect --copyright-holder="Belleguic terence <hizo@free.fr>" -L shell --add-comments=TranslationAssistance -o - hizoselect *.sh > fr/hizoselect.pot
# pour mettre à jour le fichier po (qui est une copie du pot à la base) : msgmerge --update fr/hizoselect.po fr/hizoselect.pot
# pour créer le fichier mo : msgfmt -o fr/LC_MESSAGES/hizoselect.mo fr/hizoselect.po

# Remplacement de eval_gettext par gettext
# gettext pour les traductions simples et ngettext lorsqu'il y a du pluriel

### Textes
case "${1,,}" in
#TranslationAssistance ==============================> Texts of the errors
    "argument") gettext "The %s argument needs a value." ;;
    "error_choice") gettext "The number %s is out of selection." ;;
    "error_arg_value") gettext "%s: %s is not an accepted value." ;;
    "error_default_check") gettext "%s: %s is not in the proposals list." ;;
    "error_default_limit") gettext "%s: The number of values is greater than the number of items." ;;
    "error_default_mode") gettext "%s: Impossible to use %s because %s mode is disabled." ;;
    "error_default_star") gettext "%s: Impossible to associate * with another value." ;;
    "error_effects") gettext "The effects are define by a number between 0 and 255 for effects or by bold dim smul smso." ;;
    "error_file_not_founded") gettext "%s: file not founded." ;;
    "error_input") gettext "The input argument must have %%n." ;;
    "error_insufficient") gettext "Insufficient number of items." ;;
    "error_key") gettext "%s key isn't usable." ;;
    "error_limit_max") gettext "Maximum limit reached." ;;
    "error_min") gettext "Number of answer insufficient." ;;
    "error_min_sup_max") gettext "The --min value cannot be greater than the --max value." ;;
    "error_range") gettext "%s: - needs a MIN value before and a MAX value after." ;;
    "error_numbers") gettext "The second number must be greater than the first." ;;
    "error_range_max") gettext "The range needs a second number." ;;
    "error_range_limit") gettext "The range will exceed the maximum answer number." ;;
    "error_sign") gettext "A number must precede the - sign." ;;
    "error_sign_already") gettext "Impossible to add more - signs." ;;
    "error_sign_duplicate") gettext "This value range will unnecessarily duplicate." ;;
    "error_unknow") gettext "The %s argument is unknow." ;;
    "error_used") gettext "%s number already entered." ;;
    "error_wtf") gettext "Please explain to hizo@free.fr how this error happened." ;;
    "error_zero") gettext "%s: A number cannot start by 0." ;;

#TranslationAssistance ==============================> Texts
    "prompt_text") gettext "Selection: " ;;
    "title_min_max_equal") ngettext "One expected answer" "%d expected answers" "${2}" ;;
    "title_min_max") gettext "Between %s and %s expected answers" ;;
    "title_min") ngettext "Minimum of %d expected answer" "Minimum of %d expected answers" "${2}" ;;
    "title_max") ngettext "Maximum of %d expected answer" "Maximum of %d expected answers" "${2}" ;;
    "answer") gettext "Answer" ;;

### Textes de l'aide dynamique
#TranslationAssistance ==============================> Texts of the dynamic help
    "help1") gettext "Help with the use of HizoSelect" ;;
    "help2") gettext "Number of expected answers:" ;;
    "help3") gettext "Possible answers:" ;;
    "help4") gettext "The numbers select their items." ;;
    "help5") gettext "The ? select random items." ;;
    "help6") gettext "The range select items starts from the first number to the second number included." ;;
    "help7") gettext "The * select all items." ;;
    "help8") gettext "Press any key for exiting the help." ;;
    "help9") gettext "It's possible to select several times a same item." ;;
    "help10") gettext "Each item can be only select one time." ;;
    "help11") gettext "Information:" ;;

### Textes de l'argument aide
#TranslationAssistance ==============================> Texts of the help argument
    "arg_help1") gettext "Options:" ;;
    "arg_help2") gettext "Effects of actions, commentaries, errors, numbers, prompt text, secret texts, texts and title." ;;
    "arg_help3") gettext "Enabled actions on start. If the action is visible in the bar, the user can change it." ;;
    "arg_help4") gettext "Hides error messages." ;;
    "arg_help5") gettext "Pre-filled answers." ;;
    "arg_help6") gettext "Demonstration of commands." ;;
    "arg_help7") gettext "Displays this help." ;;
    "arg_help8") gettext "Mandatory answers." ;;
    "arg_help9") gettext "Format of the items." ;;
    "arg_help10") gettext "Maximal number of answers." ;;
    "arg_help11") gettext "Minimal number of answers." ;;
    "arg_help12") gettext "Allows to return the same answer several times." ;;
    "arg_help13") gettext "Enables the use of symbols in the answers." ;;
    "arg_help14") gettext "Displayed text between the title and the list of items." ;;
    "arg_help15") gettext "Sort the proposals by the choiced argument." ;;
    "arg_help16") gettext "Format of the returned answers." ;;
    "arg_help17") gettext "Displayed text while waiting for the choice." ;;
    "arg_help18") gettext "First displayed text like a title." ;;
    "arg_help19") gettext "Delete redundant items by the choiced argument." ;;
    "arg_help20") gettext "Version of the hizoselect command." ;;
    "arg_help21") gettext "Examples:" ;;
    "arg_help22") gettext "More informations:" ;;
    "arg_help23") gettext "item(s)     " ;;
    "arg_help24") gettext "int   " ;;
    "arg_help25") gettext "text " ;;
    "arg_help26") gettext "Management of the content of the bar and its actions." ;;
    "arg_help27") gettext "Origin of the proposals, command AND/OR stdin." ;;
    "arg_help28") gettext "Delimiter to use between of the returned items." ;;
    "arg_help29") gettext "Text to add in the help screen." ;;
    "arg_help30") gettext "HizoSelect command help" ;;
    "arg_help31") gettext "Name of the command displayed in error messages." ;;
    "arg_help32") gettext "Clear the terminal before display the texts." ;;
    "arg_help33") gettext "file" ;;
    "arg_help34") gettext "Load a config file who contains some values." ;;
    "arg_help35") gettext "Delimiter between the proposals from stdin" ;;

### Textes des exemples
#TranslationAssistance ==============================> Texts of the examples
    "example1") gettext "What example(s) do you want see?" ;;
    "example2") gettext "%t=Would you marry me? %c=One number by default with a limit to 1 item and output change" ;;
    "example3") gettext "%t=Choose your menu %c=All by default with a input number for read command" ;;
    "example4") gettext "%t=Write the name 'Belleguic' %c=Numbers by default with columns format and several mode enable" ;;
    "example5") gettext "%t=What can be the age of a minor? %c=Range by default with no-all and no-random" ;;
    "example6") gettext "%t=I remove duplicates for you %c=Uniq item option and prompt text change" ;;
    "example7") gettext "%t=Advanced input/output argument %c=How-to use format" ;;
    "example8") gettext "%t=Traitment of files in a for loop %c=How-to use returns with for loop" ;;
    "example9") gettext "%t=Use multi read %c=How-to use multi while read loop" ;;
    "example10") gettext "Command:" ;;
    "example11") gettext "Would you marry me?" ;;
    "example12") gettext "The number %n is %t (%c) and his secret value is %s." ;;
    "example13") gettext "%t=Yes %c=I want it! %s=y" ;;
    "example14") gettext "%t=No %c=Sorry... %s=n" ;;
    "example15") gettext "I want eat a %t" ;;
    "example16") gettext "Choose your menu (All by default):" ;;
    "example17") gettext "%t=Entry %c=Vegetables" ;;
    "example18") gettext "%t=Dish %c=Steak and fries" ;;
    "example19") gettext "%t=Dessert %c=Flan" ;;
    "example20") gettext "Write the name 'Belleguic' (Numbers by default)" ;;
    "example21") gettext "You write:" ;;
    "example22") gettext "What can be the age of a minor?" ;;
    "example23") gettext "A minor may be aged: %s years" ;;
    "example24") gettext "I remove duplicates for you:" ;;
    "example25") gettext "You have choiced: %t" ;;
    "example26") gettext "I wait after you:" ;;
    "example27") gettext "Advanced input/output argument:" ;;
    "example28") gettext "[%n] (mandatory) <%t and %c and %s (text and commentary and secret text)|%t and %c (text and commentary)|%t and %s (text and secret text)|%c and %s (commentary and secret text)|%t (text)|%c (commentary)|%s (secret text)>" ;;
    "example29") gettext "\<%n\> (always exists) \| <%t and %c and %s (text and commentary and secret text)|%t and %c (text and commentary)|%t and %s (text and secret text)|%c and %s (commentary and secret text)|%t (text)|%c (commentary)|%s (secret text)>" ;;
    "example34") gettext "Select the files to update" ;;
    "example39") gettext "I choosen %s." ;;
    "example46") gettext "%t=Select software to install %c=Use the secret text" ;;
    "example47") gettext "%t=Select women as you know %c=Create an array indexed" ;;
    "example48") gettext "Select software to install" ;;
    "example49") gettext "Select women as you know" ;;

### Textes de la barre d'aide
#TranslationAssistance ==============================> h letter for help action
    "info_help_letter") gettext "h" ;;
    "info_help_on") gettext "Help" ;;
#TranslationAssistance ==============================> c letter for effects action
    "info_effect_letter") gettext "c" ;;
    "info_effect_on") gettext "Enable effects" ;;
    "info_effect_off") gettext "Disable effects" ;;
#TranslationAssistance ==============================> v letter for view action
    "info_view_letter") gettext "v" ;;
    "info_view_on") gettext "View in columns" ;;
    "info_view_off") gettext "View in lines" ;;
#TranslationAssistance ==============================> d letter for debug action
    "info_debug_letter") gettext "d" ;;
    "info_debug_on") gettext "Enable debug" ;;
    "info_debug_off") gettext "Disable debug" ;;
#TranslationAssistance ==============================> l letter for lang action
    "info_lang_letter") gettext "l" ;;
    "info_lang_on") gettext "French translation" ;;
    "info_lang_off") gettext "English translation" ;;
#TranslationAssistance ==============================> e letter for exit action
    "info_exit_letter") gettext "e" ;;
    "info_exit_on") gettext "Exit" ;;
esac
}
