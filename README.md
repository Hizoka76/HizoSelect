# HizoSelect

## Version Française :

### Histoire :
Cette commande a été créée suite à un besoin personnel. 
En effet la commande **select** est pratique mais ne permettait pas de choisir les infos à récupérer ni de faire des sélections multiples.


### Principe de base :
HizoSelect est un select boosté aux hormones. 

Pour fonctionner, il suffit de lui indiquer :
 - Une "question" ou un message à afficher.
 - Une liste de propositions de réponse qui contiendront des variables et des valeurs (ou simplement des textes).

L'utilisateur doit alors procéder à une séléction de nombre parmis les propositions, en fonction des réglages :
  - Réponse simple : 1
  - Réponse multiple simple : 1 3 4
  - Réponse multiple par plage : 1-3
  - Réponse aléatoire : ?
  - Réponse complet : *
  - Réponse mixée : 1 3-5 ? 8-9

De nombreuses vérifications sont faites pour éviter les réponses incompatibles ou déjà présente.
Afin que ce soit facilement compréhensible, un code couleur est appliqué aux nombres entrés par l'utilisateur :
 - Vert : Le nombre est correct.
 - Orange : La réponse est potentiellement incompléte :
   - 1- : Dans le cas d'une plage non précisée.
   - 1 : Alors qu'il est possible de réponse 10 ou 11...

Si des réponses erronées sont tapées par l'utilisateur, elles ne sont pas prises en compte.


### Arguments :
 Voici la liste des arguments possibles et leur explication :
- **--actions** : Actions actives au démarrage. Si l'action est visible dans la barre, l'utilisateur peut la modifier.
- **--bar** : Gestion du contenu de la barre et de ses actions.
- **--config** : Charge un fichier de config contenant divers valeurs.
- **--clear** : Nettoie le terminal avant d'afficher les textes.
- **--default** : Réponses pré-rentrées.
- **--delimiter** : Délimiteur à utiliser entre les propositions retournées.
- **--effects** : Effets visuels des actions, commentaires, des erreurs, des nombres, du texte du prompt, des textes secrets, des textes et du titre.
- **--examples** : Démonstration de commandes.
- **--force** : Réponses obligatoires.
- **--help** : Affiche cette aide.
- **--input** : Formatage des propositions.
- **--input-delimiter** : Délimiteur entre les propositions en provenance de stdin.
- **--info** : Texte additionnel à afficher dans l'aide.
- **--min** : Nombre minimal de réponse attendue.
- **--max** : Nombre maximal de réponse attendue.
- **--name** : Nom de la commande affichée dans les messages d'erreurs.
- **--output** : Formatage des réponses retournées.
- **--prompt** : Texte affiché lors de l'attente de réponse.
- **--proposals** : Origine des propositions, commande ET/OU stdin.
- **--multi** : Renvoi plusieurs fois la même réponse possible.
- **--symbols** : Active l'utilisation des symboles dans les réponses.
- **--sort** : Range les propositions de l'argument choisi.
- **--text** : Texte affiché entre le titre et la liste de propositions.
- **--title** : Premier texte affiché comme un titre.
- **--uniq-item** : Supprime les propositions en doublon en fonction de l'argument choisi.
- **--version** : Version de la commande hizoselect
 

### Exemples :
La commande à un argument examples : **hizoselect --examples**.

En voici un :
```
hizoselect \
  --title "Indiquez les femmes que vous connaissez" \
  --input "%n) %t : %c" \
  --output "%t, numéro %n, était une %c dont le code est %s." \
  "%t=Clara Morgan %c=Actrice %s=MorganClara" \
  "%t=Brigite Macron %c=Première Dame %s=MacronBrigite" \
  "%t=Simone Veil %c=Grande Dame %s=VeilSimone" \
  "%t=Marie Curie %c=Grande scientifique %s=CurieMarie" \
  "%t=Edith Piaf %c=Chanteuse %s=PiafEdith"
```
![Ex](https://user-images.githubusercontent.com/48289933/138558716-1eac2264-fb6a-47e6-8904-584fd8d417e2.png)
Résultat :
> Clara Morgan, numéro 1, était une Actrice dont le code est MorganClara.
> 
> Brigite Macron, numéro 2, était une Première Dame dont le code est MacronBrigite.
> 
> Marie Curie, numéro 4, était une Grande scientifique dont le code est CurieMarie.
> 
> Edith Piaf, numéro 5, était une Chanteuse dont le code est PiafEdith.
 
 
### Récupération des valeurs :
Pour récupérer une valeur unique :
```
Valeur=$(hizoselect --max 1 ...)
echo "Valeur => $Valeur"
```

Pour récupérer une liste de réponse :
```
mapfile -t Valeurs < <(hizoselect ...)
echo "Valeurs => ${Valeurs[*]}"
```

Pour récupérer une liste de réponse avec modification de l'IFS à \0 :
```
mapfile -td Valeurs < <(hizoselect --delimiter "\0" ...)
echo "Valeurs => ${Valeurs[*]}"
```

Pour récupérer un tableau indexé :
```
mapfile -t Choice < <(hizoselect -o "%t@%c" "%t=Clara Morgan %c=Actress" ...)

if [[ ${Choice[*]} ]]
then
    declare -Ag Women
    for Woman in "${Choice[@]}"
    do
        Women["${Woman%%@*}"]="${Woman##*@}"
    done
    declare -p Women
fi
```



### Aide :
La commande à un argument help : **hizoselect --help**.

La commande est livrée avec des manpages (fr et en).
Pour les lire : **man ./hizoselect1.fr.1**

*** ***
 

## English Version :

### History :
This command was created following a personal need.
Indeed the **select** command is convenient but did not allow to choose the information to retrieve or to make multiple selections.


### Basic principle:
HizoSelect is a select boosted with hormones. 

To work, you just have to tell it :
 - A "question" or a message to display.
 - A list of proposals of answer that will contain variables and values (or simply texts).

The user must then make a selection among the proposals, according to the settings:
 - Simple answer: 1
 - Simple multiple response: 1 3 4
 - Multiple answer by range: 1-3
 - Random answer: ?
 - Full answer: *
 - Mixed answer: 1 3-5 ? 8-9

Many checks are made to avoid incompatible or already present answers.
To make it easy to understand, a color code is applied to the numbers entered by the user:
 - Green: The number is correct.
 - Orange : The answer is potentially incomplete:
   - 1-: In the case of an unspecified range.
   - 1 : While it is possible to answer 10 or 11...
 
If wrong answers are typed by the user, they are not taken into account.


### Arguments :
Here is the list of possible arguments and their explanation: 
 - **--actions**: Enabled actions on start. If the action is visible in the bar, the user can change it.
 - **--bar**: Management of the content of the bar and its actions.
 - **--config**: Load a config file who contains some values.
 - **--clear**: Clear the terminal before display the texts.
 - **--default**: Pre-filled answers.
 - **--delimiter**: Delimiter to use between of the returned items.
 - **--effects**: Effects of actions, commentaries, errors, numbers, prompt text, secret texts, texts and title.
 - **--examples**: Demonstration of commands.
 - **--force**: Mandatory answers.
 - **--help**: Displays this help.
 - **--input**: Format of the items.
 - **--input-delimiter**: Delimiter between the proposals from stdin
 - **--info**: Text to add in the help screen.
 - **--min**: Minimal number of answers.
 - **--max**: Maximal number of answers.
 - **--name**: Name of the command displayed in error messages.
 - **--output**: Format of the returned answers.
 - **--prompt**: Displayed text while waiting for the choice.
 - **--proposals**: Origin of the proposals, command AND/OR stdin.
 - **--multi**: Allows to return the same answer several times.
 - **--symbols**: Enables the use of symbols in the answers.
 - **--sort**: Sort the proposals by the choiced argument.
 - **--text**: Displayed text between the title and the list of items.
 - **--title**: First displayed text like a title.
 - **--uniq-item**: Delete redundant items by the choiced argument.
 - **--version**: Version of the hizoselect command.
 

### Examples:
The command has one argument examples: **hizoselect --examples**.

Here's one:
```
hizoselect \
  --title "Select women as you know" \
  --input "%n) %t : %c" \
  --output "%t, number %n, was %c with code %s." \
  "%t=Clara Morgan %c=Actress %s=MorganClara" \
  "%t=Brigite Macron %c=First Lady %s=MacronBrigite" \
  "%t=Simone Veil %c=Great Lady %s=VeilSimone" \
  "%t=Marie Curie %c=Big scientist %s=CurieMarie" \
  "%t=Edith Piaf %c=Singer %s=PiafEdith"
```
![Eg](https://user-images.githubusercontent.com/48289933/138560191-59fa836d-6d32-43f9-8902-34c3e750e9e6.png)

Result :
> Clara Morgan, number 1, was Actress with code MorganClara.
> 
> Brigite Macron, number 2, was First Lady with code MacronBrigite.
> 
> Marie Curie, number 4, was Big scientist with code CurieMarie.
> 
> Edith Piaf, number 5, was Singer with code PiafEdith.
 
 
### Retrieving values:
To retrieve a single value:
```
Value=$(hizoselect --max 1 ...)
echo "Value => $Value"
```

To retrieve a list of responses:
```
mapfile -t Values < <(hizoselect ...)
echo "Values => ${Values[*]}"
```

To retrieve a response list with IFS modification to \0:
```
mapfile -td Values < <(hizoselect --delimiter "\0" ...)
echo "Values => ${Values[*]}"
```

To retrieve an indexed array:
```
mapfile -t Choice < <(hizoselect -o "%t@%c" "%t=Clara Morgan %c=Actress" ...)

if [[ ${Choice[*]} ]]
then
    declare -Ag Women
    for Woman in "${Choice[@]}"
    do
        Women["${Woman%%@*}"]="${Woman##*@}"
    done
    declare -p Women
fi
```


### Help:
The command has a help argument: **hizoselect --help**.

The command comes with manpages (fr and en).
To read them : **man ./hizoselect1.fr.1**
