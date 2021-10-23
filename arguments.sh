 #!/bin/bash

# Script sourcé par hizoselect



################################################
## Système de chargement du fichier de config ##
################################################
function ConfigLoad
{
    # $1 : Nom du fichier de config à charger, si vide, utilisation de default.cfg

    # Chargement du fichier de config
    GroupName="Global"

    while read CfgLine
    do
        # Suppression des espaces
        CfgLine="${CfgLine/#*([[:space:]])/}"

        # Si la ligne est un nom de groupe
        if [[ ${CfgLine} =~ ^"["(.+)"]"$ ]]
        then
            GroupName="${BASH_REMATCH[1]}"

        elif [[ ${CfgLine} =~ ^([_a-Z][_a-Z0-9]*)=(.*) ]]
        then
            # Détection du séparateur " / ' / espace / aucun
            case "${BASH_REMATCH[2]:0:1}" in
                '"') Separator='"' ;;
                "'") Separator="'" ;;
                " ") Separator="" ;;
                *) Separator=" " ;;
            esac

            # Suppression du 1er séparateur
            Value="${BASH_REMATCH[2]/#${Separator}}"

            # Remplace le caractère séparateur s'il est échappé
            Value="${Value//\\${Separator}/@@@@Hizo@@@@}"

            # Supprime tout à partir du dernier séparateur, ainsi, on ne reprend pas les commentaires
            Value="${Value%%${Separator}*}"

            # Remet en place les caractères échappés
            Value="${Value//@@@@Hizo@@@@/${Separator}}"

            # Déclaration de la variable
            if [[ ${GroupName^} == "Global" ]]
            then
                # Variables globales
                declare -g ${BASH_REMATCH[1]}="${Value}"

            else
                # Variables de type tableau
                declare -g ${GroupName}[${BASH_REMATCH[1]}]="${Value}"
            fi
        fi
    done < "${1:-${HOME}/.config/HizoSelect/default.cfg}"
}



###############################################
## Gestion des arguments et des propositions ##
###############################################

ArgList=(-- -? -a -A -b -c -C -d -D -e -E -f -F -h -i -I -m -M -n -o -p -P -s -S -t -T -u -v --actions --answers --bar --clear --config --default --delimiter --effects --examples --force --help --input --id --input-delimiter --info --min --max --multi --name --output --prompt --proposals --several --sort --symbols --title --text --uniq-item --version)

# getopts ne sert qu'en cas d'utilisation de argument d'1 lettre et qu'on puisse les assembler, donc pas d’intérêt ici
# utilisation de ${*} et non de ${1} car si la variable est vide ça stoppe
while [[ ${*} ]]
do
    # Variable stoppant les arguments
    if [[ -z ${StopArg} ]]
    then
        ## Regarde si l'élément suivant est un argument ou une valeur
        ArgOrVal="Aucun"

        # Vide ne remplacera $2 que s'il n'existe vraiment pas, pas juste si la valeur est vide
        if [[ ${2-vide} != vide ]]
        then
            # Si l'élément commence par un -
            if [[ ${2:0:1} == "-" ]]
            then
                # Vérifie que $2 n'est pas le nom d'un argument, teste si la liste contient exactement $2
                ArgOrVal="Valeur"
                InArray "${2}" "${ArgList[*]}" && ArgOrVal="Argument"

            else
                ArgOrVal="Valeur"
            fi
        fi

        # Met en minuscule les arguments longs mais pas les courts dont la casse est importante
        Value="${1}"
        [[ ${1} == --* ]] && Value="${1,,}"

        # Traitement de l'argument
        case "${Value}" in
            # Valeur spéciale permettant d'indiquer que les arguments sont terminées
            "--") StopArg=1 ;;


            # Arguments nécessitants une valeur
            "-a"|"--answers"|"-d"|"--default"|"-D"|"--delimiter"|"-e"|"--effects"|"-f"|"--force"|"-i"|"--input"|"-I"|"--id"|"--input-delimiter"|"--info"|"-m"|"--min"|"-M"|"--max"|"-n"|"--name"|"-o"|"--output"|"-p"|"--prompt"|"-P"|"--proposals"|"-t"|"--text"|"-T"|"--title")
                # Message d'erreur si aucune valeur
                [[ ${ArgOrVal} != "Valeur" ]] && ExitErreur "argument@${1}"

                # Spécificité du nom de la variable
                case "${Value}" in
                    # Réponses par défaut
                    "-d"|"--default"|"-a"|"--answers") AnswersTemp="${2}" ;;

                    # Délimiteur à utiliser
                    "-D"|"--delimiter") Delimiter="${2}" ;;

                    # Effets de texte
                    "-e"|"--effects")
                        # echo pour ne pas ajouter de saut de ligne avec <<< $2
                        mapfile -t -d '%' Lettres < <(echo -n "${2}")

                        # Boucle sur les différents noms de couleur
                        for Effects in "${Lettres[@]}"
                        do
                            # Lettre utilisée et liste des effets
                            Letter=${Effects:0:1}
                            EffectsList="${Effects:2}"

                            # Si la valeur n'est pas bonne
                            [[ ${Letter} != [a-zA-Z] ]] && continue

                            # Si c'est un mot clé
                            if [[ ${Effects^} =~ ^(${EffectsKey})=(.*) ]]
                            then
                                Letter="${BASH_REMATCH[1]^}"
                                EffectsList="${BASH_REMATCH[2],,}"
                            fi

                            # Mise à jour de la liste des couleurs
                            DefineEffects[${Letter}]="${EffectsList}"
                        done

                        unset Effects ;;

                    # Réponses forcées
                    "-f"|"--force")
                        # Transformation de , ; + en espace
                        # mapfile -t -d ' ' ForceAnswers < <(printf "%s" "${2//[,;+]/ }")
                        ForceAnswersTemp="${2}" ;;

                    # Format de l'affichage des propositions
                    "-i"|"--input") InputText="${2}" ;;

                    # Délimiteur des propositions de stdin
                    "--id"|"--input-delimiter") InputDelimiter="${2}" ;;

                    # Information à afficher dans l'aide
                    "-I"|"--info") Info="${2}" ;;

                    # Nombre de réponse minimum
                    "-m"|"--min") Min="${2}" ;;

                    # Nombre de réponse maximum
                    "-M"|"--max") Max="${2}" ;;

                    # Nom de la commande en cas d'erreur
                    "-n"|"--name") Name="${2}" ;;

                    # Format du texte de sortie
                    "-o"|"--output") OutputText="${2}" ;;

                    # Texte du prompt
                    "-p"|"--prompt")
                        PromptText="${2}"

                        # Ajout d'un espace si la dernière valeur du texte est un nombre car ça va gêner le read
                        [[ ${PromptText: -1} == [0-9] ]] && PromptText+=" " ;;

                    # Origine des propositions
                    "-P"|"--proposals") ProposalsOrigin="${2}" ;;

                    # Texte suivant le titre
                    "-t"|"--text") Text="${2}" ;;

                    # Texte du titre
                    "-T"|"--title") Title="${2}" ;;
                esac

                shift ;;


            # Arguments nécessitants des valeurs de type %x valides
            "--sort"|"-u"|"--uniq-item")
                # Vérification de l'argument
                [[ ${ArgOrVal} != "Valeur" ]] && ExitErreur "argument@${1}"

                # Vérification de la validité des arguments
                mapfile -t -d '%' Lettres < <(printf "%s" "${2}")
                for Lettre in "${Lettres[@]}"
                do
                    [[ ${Lettre} && "${Lettre// }" != [a-zA-Z] ]] && ExitErreur "error_arg_value@${1}@${2}"
                done

                # Spécificité du nom de la variable
                case "${Value}" in
                    # Rangement des propositions
                    "--sort") SortType="${2}" ;;

                    # Mode proposition unique
                    "-u"|"--uniq-item")
                        # Le résultat ne peut être que composé de %x
                        Temp="${2// }"
                        (( ${#Temp} != 2 )) && ExitErreur "error_arg_value@${1}@${2}"

                        UniqueItem="${Temp}" ;;
                esac

                shift ;;


            # Actions activées au démarrage
            "-A"|"--actions")
                Columns=0
                Debug=0
                Effect=0

                if [[ ${ArgOrVal} == "Valeur" ]]
                then
                    [[ ${2} == *"c"* ]] && Effect=1
                    [[ ${2} == *"d"* ]] && Debug=1
                    (( ColumnExists )) && [[ ${2} == *"v"* ]] && Columns=1
                fi

                shift ;;

            # Gestion de la barre d'actions
            "-b"|"--bar")
                Bar=""

                if [[ ${ArgOrVal} == "Valeur" ]]
                then
                    Bar="${2// }"

                    # Vérifie que les lettres sont valables
                    for ((x=0; x<${#Bar}; x++ ))
                    do
                        [[ "${BarLetters}" != *${Bar:${x}:1}* ]] && ExitErreur "error_arg_value@${1}@${Bar:${x}:1}"
                    done
                fi ;;

            # Configuration à utiliser
            "-c"|"--config")
                # Si on indique un fichier de config
                if [[ ${ArgOrVal} == "Valeur" ]]
                then
                    # Si le fichier existe
                    if [[ -f "${2}" ]]
                    then
                        File="${2}"
                        shift

                    # Si le fichier n'existe pas
                    else
                        # Si on trouve un fichier portant ce nom dans le dossier de config
                        if [[ -f "${HOME}/.config/HizoSelect/${2/%.cfg}.cfg" ]]
                        then
                            File="${HOME}/.config/HizoSelect/${2/%.cfg}.cfg"
                            shift

                        else
                            ExitErreur "error_file_not_founded@${2}"
                        fi
                    fi
                fi

                # Si aucun fichier n'a été précisé, celui par défaut sera utilisé
                ConfigLoad "${File}" ;;

            # Gestion de la barre
            "-C"|"--clear") ClearTerminal=1 ;;

            # Exemples
            "-E"|"--ex"|"--eg"|"--examples")
                # Chargement des effets visuels
                EffectsSetUp ${Effect}

                # Choix de l'exemple
                mapfile -t Choice < <("${0}" --title "$(LangText example1)" --output "%n" --input "%n) %t : %c" \
"$(LangText example2)" \
"$(LangText example3)" \
"$(LangText example4)" \
"$(LangText example5)" \
"$(LangText example6)" \
"$(LangText example7)" \
"$(LangText example8)" \
"$(LangText example46)" \
"$(LangText example47)")

                ## Nettoyage de l'écran
#                 printf '\33[H\33[2J' >&2

                for Example in "${Choice[@]}"
                do
                    case "${Example}" in
                        "1") # Demande de mariage
                            echo -e "$(LangText example10)
${Effects["Maybe"]}${0} ${Effects["Error"]}--max ${Unset}\"${Effects["OK"]}1${Unset}\" ${Effects["Error"]}--title ${Unset}\"${Effects["OK"]}$(LangText example11)${Unset}\" ${Effects["Error"]}--default ${Unset}\"${Effects["OK"]}1${Unset}\" ${Effects["Error"]}--input ${Unset}\"${Effects["OK"]}%n) %t (%c)${Unset}\" ${Effects["Error"]}--output ${Unset}\"${Effects["OK"]}$(LangText example12)${Unset}\" \"${Effects["t"]}$(LangText example13)${Unset}\" ${Unset}\"${Effects["t"]}$(LangText example14)${Unset}\"\n"
                        ;;

                        2|"2") # Choix de menu
echo "ici" 1>&2
                            echo -e "$(LangText example10)
${Effects["Maybe"]}${0} ${Effects["Error"]}--default ${Unset}\"${Effects["OK"]}*${Unset}\" ${Effects["Error"]}--output ${Unset}\"${Effects["OK"]}$(LangText example15)${Unset} \"${Effects["Error"]} --title ${Unset}\"${Effects["OK"]}$(LangText example16)${Unset}\" \"${Effects["t"]}$(LangText example17)${Unset}\" \"${Effects["t"]}$(LangText example18)${Unset}\" \"${Effects["t"]}$(LangText example19)${Unset}\"\n"
                        ;;

                        "3") # Écriture d'un nom avec permission d’écrire plusieurs fois la même valeur et affichage en colonnes
                            echo -e "$(LangText example10)
${Effects["Maybe"]}${0} ${Effects["Error"]}--several --actions ${Unset}\"${Effects["OK"]}cdv${Unset}\" ${Effects["Error"]}--delimiter ${Unset}\"\" ${Effects["Error"]}--title ${Unset}\"${Effects["OK"]}$(LangText example20)${Unset}\" ${Effects["Error"]}--default ${Unset}\"${Effects["OK"]}2 5 12 12 5 7 21 9 3${Unset}\" ${Effects["t"]}{a..z}${Unset}\n"
                        ;;

                        "4") # Plage des âges des mineurs
                            echo -e "$(LangText example10)
${Effects["Maybe"]}${0} ${Effects["Error"]}--actions ${Unset}\"${Effects["OK"]}cdv${Unset}\" ${Effects["Error"]}--default ${Unset}\"${Effects["OK"]}1-17${Unset}\" ${Effects["Error"]}--title ${Unset}\"${Effects["OK"]}$(LangText example22)${Unset}\" ${Effects["t"]}{1..30}${Unset}\n"
                        ;;

                        "5") # Propositions uniques
                            echo -e "$(LangText example10)
${Effects["Maybe"]}${0} ${Effects["Error"]}--uniq-item --title ${Unset}\"${Effects["OK"]}$(LangText example24)${Unset}\" ${Effects["Error"]}--output ${Unset}\"${Effects["OK"]}$(LangText example25)${Unset}\" ${Effects["Error"]}--prompt ${Unset}\"${Effects["OK"]}$(LangText example26)${Unset} \" ${Effects["t"]}{a..f} {f..a}${Unset}\n"
                        ;;

                        "6") # Utilisation des formats
                            echo -e "$(LangText example10)
${Effects["Maybe"]}${0} ${Effects["Error"]}--default ${Unset}\"${Effects["OK"]}*${Unset}\" ${Effects["Error"]}--title ${Unset}\"${Effects["OK"]}$(LangText example27)${Unset}\" ${Effects["Error"]}--input ${Unset}\"${Effects["OK"]}$(LangText example28)${Unset}\" ${Effects["Error"]}--output ${Unset}\"${Effects["OK"]}$(LangText example29)${Unset}\" \"${Effects["t"]}%t=Bonjour %c=French %s=Hello${Unset}\" \"${Effects["t"]}%t=Buongiorno %c=Italiano${Unset}\" \"${Effects["t"]}%t=Hallo %s=Hello${Unset}\" \"${Effects["t"]}%c=Japness %s=Hello${Unset}\" \"${Effects["t"]}%t=안녕하세요${Unset}\" \"${Effects["t"]}%c=صباح الخير${Unset}\" \"${Effects["t"]}%s=ஹலோ${Unset}\"\n"
                        ;;

                        "7") # Utilisation d'une boucle for
                            echo -e "$(LangText example10)
mapfile -t Choice < <(${Effects["Maybe"]}${0}${Effects["Error"]} --title ${Unset}\"${Effects["OK"]}$(LangText example34)${Unset}\" *)

[[ \${Choice[*]} ]] && for Value in \"\${Choice[@]}\"; do printf \"$(LangText example39)\\\\n\" \"\${Value}\"; done\n"
                        ;;

                        "8") # Utilisation de %s
                            echo -e "$(LangText example10)
mapfile -t Choice < <(${Effects["Maybe"]}${0}${Effects["Error"]} --title ${Unset}\"${Effects["OK"]}$(LangText example48)${Unset}\" ${Effects["Error"]}-o ${Unset}\"${Effects["OK"]}%s${Unset}\" \"${Effects["t"]}%t=Video Lan Center %s=vlc${Unset}\" \"${Effects["t"]}%t=Libre Office %s=libreoffice${Unset}\" \"${Effects["t"]}%t=MKV Extractor Qt5 %s=mkv-extractor-qt${Unset}\" \"${Effects["t"]}%t=GNU Image Manipulation Program %s=gimp${Unset}\")

[[ \${Choice[*]} ]] && echo \"sudo apt install \${Choice[*]}\"\n"
                        ;;

                        "9") # Utilisation d'un array indexe
                            echo -e "$(LangText example10)
mapfile -t Choice < <(${Effects["Maybe"]}${0}${Effects["Error"]} --title ${Unset}\"${Effects["OK"]}$(LangText example49)${Unset}\" ${Effects["Error"]}-o ${Unset}\"${Effects["OK"]}%t@%c${Unset}\" \"${Effects["t"]}%t=Clara Morgan %c=Actress${Unset}\" \"${Effects["t"]}%t=Brigite Macron %c=First lady${Unset}\" \"${Effects["t"]}%t=Simone Veil %c=Great Lady${Unset}\" \"${Effects["t"]}%t=Marie Curie %c=Big scientist${Unset}\" \"${Effects["t"]}%t=Edith Piaf %c=Singer${Unset}\")

if [[ \${Choice[*]} ]]
then
    declare -Ag Women
    for Woman in \"\${Choice[@]}\"
    do
        Women[\"\${Woman%%@*}\"]=\"\${Woman##*@}\"
    done
    declare -p Women
fi\n"
                        ;;

                        # Permet d'éviter des ennuis
                        *) continue ;;
                    esac
                done

                exit 0 ;;

            # Affichage de l'aide
            "-h"|"-?"|"--help")
                # Chargement des effets visuels
                EffectsSetUp  ${Effect}

                # Affichage de l'aide
                source "help.sh"

                exit 0 ;;

            # Mode réponse non unique
            "-s"|"--several"|"--multi") Uniq=0 ;;

            # (dés)Activation des symboles ? - et *
            "-S"|"--symbols")
                All=0
                Random=0
                Range=0

                if [[ ${ArgOrVal} == "Valeur" ]]
                then
                    [[ ${2} == *"a"* ]] && All=1
                    [[ ${2} == *"r"* ]] && Random=1
                    [[ ${2} == *"R"* ]] && Range=1

                    shift
                fi ;;

            # Version du logiciel
            "-v"|"--version")
                echo -e "HizoSelect version ${Version}.\n${Licence}." >&2
                exit 0 ;;

            # Si un autre argument est donné
            -*) ExitErreur "error_unknow@${1}" ;;

            # Si c'est du texte sans argument, c'est que c'est une réponse possible
            *)
                # Si la variable est vide, on ne la prend pas
                if [[ ${1} ]]
                then
                    # Nettoyage des espaces
                    ProposalTemp="${1/#+( )}"
                    ProposalTemp="${ProposalTemp/%+( )}"

                    # Ajoute %t si besoin
                    [[ ${ProposalTemp:0:1} != "%" ]] && ProposalTemp="%t=${ProposalTemp}"

                    # Ajoute la valeur quelque soit le cas
                    Proposals+=("${ProposalTemp}")
                fi ;;
        esac

    # Si on est ici, c'est qu'on a utilisé --, du coup, tout ce qui suit sert de proposition
    else
        # Nettoyage des espaces
        ProposalTemp="${1/#+( )}"
        ProposalTemp="${ProposalTemp/%+( )}"

        # Ajoute %t si besoin
        [[ ${ProposalTemp:0:1} != "%" ]] && ProposalTemp="%t=${ProposalTemp}"

        # Ajoute la valeur quelque soit le cas
        Proposals+=("${ProposalTemp}")
    fi

    # On décale les arguments ${1} est détruit, ${2} devient ${1}, ${3} devient ${2}...
    shift
done

