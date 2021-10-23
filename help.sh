#!/bin/bash

# Script sourcé par hizoselect

#######################
## Aide d'HizoSelect ##
#######################

Start="\t${Effects["Error"]}"

# Affichage de l'aide sur le stderr
echo -e "${Effects["OK"]}$(LangText "arg_help30")${Unset}
---------------------------------------

${Effects["n"]}$(LangText "arg_help1")${Unset}
${Start}-A, --actions${Unset}${Effects["t"]} c d v${Unset}\t\t\t\t$(LangText "arg_help3")
${Start}-b, --bar${Effects["t"]} h c v d l e${Unset}\t\t\t\t$(LangText "arg_help26")
${Start}-c, --config${Effects["t"]} $(LangText "arg_help33")${Unset}\t\t\t\t$(LangText "arg_help34")
${Start}-C, --clear${Unset}\t\t\t\t\t$(LangText "arg_help32")
${Start}-d, --default${Effects["t"]} $(LangText "arg_help23")${Unset}\t\t\t$(LangText "arg_help5")
${Start}-D, --delimiter${Effects["t"]} $(LangText "arg_help25")${Unset}\t\t\t\t$(LangText "arg_help28")
${Start}-e, --effects${Unset}\t\t\t\t\t$(LangText "arg_help2")
\t\t${Effects["t"]} %[a-Z] %(ActKey|ActName|Error|Prompt|Title)${Unset}
${Start}-E, --examples${Unset}\t\t\t\t\t$(LangText "arg_help6")
${Start}-f, --force${Effects["t"]} $(LangText "arg_help23")${Unset}\t\t\t$(LangText "arg_help8")
${Start}-h, -?, --help${Unset}\t\t\t\t\t$(LangText "arg_help7")
${Start}-i, --input${Effects["t"]} format${Unset}\t\t\t\t$(LangText "arg_help9")
${Start}--id, --input-delimiter${Effects["t"]} format${Unset}\t\t\t$(LangText "arg_help35")
${Start}-I, --info${Effects["t"]} $(LangText "arg_help25")${Unset}\t\t\t\t$(LangText "arg_help29")
${Start}-m, --min${Effects["t"]} $(LangText "arg_help24")${Unset}\t\t\t\t$(LangText "arg_help11")
${Start}-M, --max${Effects["t"]} $(LangText "arg_help24")${Unset}\t\t\t\t$(LangText "arg_help10")
${Start}-n, --name${Unset}\t\t\t\t\t$(LangText "arg_help31")
${Start}-o, --output${Effects["t"]} format${Unset}\t\t\t\t$(LangText "arg_help16")
${Start}-p, --prompt${Effects["t"]} $(LangText "arg_help25")${Unset}\t\t\t\t$(LangText "arg_help17")
${Start}-P, --proposals${Effects["t"]} [0-3]${Unset}${Unset}\t\t\t\t$(LangText "arg_help27")
${Start}-s, --several, --multi${Unset}\t\t\t\t$(LangText "arg_help12")
${Start}-S, --symbols${Effects["t"]} a r R${Unset}\t\t\t\t$(LangText "arg_help13")
${Start}--sort${Effects["t"]} %[a-Z]${Unset}\t\t\t\t\t$(LangText "arg_help15")
${Start}-t, --text${Effects["t"]} $(LangText "arg_help25")${Unset}\t\t\t\t$(LangText "arg_help14")
${Start}-T, --title${Effects["t"]} $(LangText "arg_help25")${Unset}\t\t\t\t$(LangText "arg_help18")
${Start}-u, --uniq-item${Unset}${Effects["t"]} %[a-Z]${Unset}\t\t\t\t$(LangText "arg_help19")
${Start}-v, --version${Unset}\t\t\t\t\t$(LangText "arg_help20")

${Effects["n"]}$(LangText "arg_help21")${Unset}
\t${Effects["Maybe"]}hizoselect${Effects["Error"]} --examples${Unset}

${Effects["n"]}$(LangText "arg_help22")${Unset}
\tman ${Effects["Maybe"]}hizoselect${Unset}\n" >&2
