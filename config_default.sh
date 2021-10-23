 #!/bin/bash

# Script sourcé par hizoselect

#########################################################
## Système de création du fichier de config par défaut ##
#########################################################

# Création du dossier si besoin
[[ ! -d "${HOME}/.config/HizoSelect/" ]] && mkdir -p "${HOME}/.config/HizoSelect/"

echo '[Global]
All=1 # Enable * answer
Bar="hcvdle" # Items of the bar
Columns=0 # Column mode
Debug=1 # Debug mode
Delimiter="\\n" # Output delimiter
Effect=1 # Enable color effects
InputText="%n) %t" # Input format
InputDelimiter= # Delimiter of the answers from stdin
Min=0 # Minimum answer number
Max=0 # Maximum answer number
OutputText="%t" # Output format
ProposalsOrigin=2 # Origin of the answers
Random=1 # Enable ? answer
Range=1 # Enable x-y answer
Uniq=1 # Enable uniq answer
UniqueItem= # Disable uniq proposal
SortType= # Disable answer sort
ClearTerminal=0 # Disable cleaning terminal before display texts


[DefineEffects]
# Color / Background Color / Style (bold|blink|dim|rev|smul|smso)
# eg: 25/bg12/bold
ActKey="185/bold" # Key actions
ActName="27" # Key descriptions
Error="197" # Error messages
n="97/bold" # Answer number
Prompt="31"
t="27" # Default answer
Title="167"
OK="35" # Answer OK
Maybe="131" # Answer can be update
Last="97"' > "${HOME}/.config/HizoSelect/default.cfg"
