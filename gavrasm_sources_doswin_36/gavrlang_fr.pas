{ Fichier contenant les codes d'erreur pour le francais
  entregistrez ce fichier sous le nom de gavrlang.pas
  pour franciser les messages du compilateur.
  gavrasm version 1.0, last changed 20.12.2011
}

Unit gavrlang;

Interface

Var nMaxErr:Byte;

Function GetMsgM(nem:Byte):String;
Function GetMsgW(nem:Byte;s1,s2:String):String;
Function GetMsgE(nem:Byte;s1,s2:String):String;

Implementation

Uses gavrline;

Const
  nas=93;
  as:Array[1..nas] Of String[80]=(
    { 1} 'Option inconnue sur la ligne de commande : ', 
    { 2} 'Fichier source pas trouve : ', 
    { 3} 'Erreur ', 
    { 4} 'Fichier : ', 
    { 5} 'Ligne : ', 
    { 6} 'Ligne du code source : ', 
    { 7} 'Attention ', 
    { 8} 'Liste des symboles : ', 
    { 9} 'Type nDef nUsed Decimalval  Hexvalue Nom', 
    {10} 'Pas de symbole defini: ', 
    {11} 'liste des macros: ', 
    {12} 'nLines nUsed nParams Nom',
    {13} '   Pas de macros.', 
    {14} 'En ouvrant le fichier d''inclusion ', 
    {15} 'Continuation avec le fichier ', 
    {16} ' lignes traitees.',
    {17} 'Fichier source: ', 
    {18} 'Fichier hex : ', 
    {19} 'Fichier Eeprom : ', 
    {20} 'Compile : ', 
    {21} 'Passe :        ', 
    {22} 'Compilation en cours ', 
    {23} ' mots de code, ', 
    {24} ' constantes definies, total=', 
    {25} 'Pas d''avertissement !', 
    {26} 'Un avertissement !',
    {27} ' avertissements !', 
    {28} 'Compilation terminee, pas d''erreur.', 
    {29} 'Programme              : ',     
    {30} 'Constantes             : ',   
    {31} 'Memoire totale occupee : ', 
    {32} 'Taille en  Eeprom      : ',      
    {33} 'Segment de donnees     : ',      
    {34} 'Compilation terminee ',     
    {35} 'Compilation interrompue, ',     
    {36} 'une erreur !',
    {37} ' erreurs !', 
    {38} ' Au revoir...',
    {39} 'impair (instruction pour registres pairs) !', 
    {40} ' \\ L''instruction n''a pas de parametre !', 
    {41} 'registre dans la gamme de R0 a R31', 
    {42} 'ordinal de bit compris entre 0 et 7', 
    {43} 'etiquette de saut relatif de valeur comprise entre -64 et +63', 
    {44} 'etiquette de saut absolu a une adresse notee sur 16/22 bits', 
    {45} 'rien ou registre et Z ou registre et Z+ ',
    {46} 'etiquette de saut relatif de valeur dans la gamme +-2k', 
    {47} 'registre dans la gamme de R16 a R31',
    {48} 'registre double R24, R26, R28 ou R30', 
    {49} 'valeur des bits de poids faible du port entre 0 et 31', 
    {50} 'registre dans la gamme de R16 a R23', 
    {51} 'registre pair (R0, R2 ... R30)', {'even register (R0, R2 ... R30',}
    {52} 'valeur de port comprise entre 0 et 63', {'port value in the range from 0 to 63',}
    {53} 'X/Y/Z ou X+/Y+/Z+ ou -X/-Y/-Z', {'X/Y/Z or X+/Y+/Z+ or -X/-Y/-Z',}
    {54} 'Y+distance ou Z+distance, gamme dans 0..63', {'Y+distance or Z+distance, range 0..63',}
    {55} 'adresse SRAM sur 16 bits', {'16-bit SRAM adress',}
    {56} 'Constante de valeur comprise entre 0 et 63', {'Constant in the range 0..63',}
    {57} 'Constante de valeur comprise entre 0 et 255', {'Constant in the range 0..255',}
    {58} 'parametre', {'parameter',}
    {59} 'Erreur interne au compilateur ! Envoyez un mail a gavrasm@avr-asm-tutorial.net ?',
    {60} 'Voyez la liste de directives avec gavrasm -d !', 
    {61} 'Liste des directives supportees', 
    {62} '.BYTE x          : reserve x octets dans le segment de donnees (voyez .DSEG)', 
    {63} '.CSEG            : appartient au segment de code', 
    {64} '.DB x,y,z        : insere des octets, caracteres ou chaines (.CSEG, .ESEG)', 
    {65} '.DEF x=y         : le nom de symbole x est lie au registre y',
    {66} '.DEVICE x        : ce code doit etre verifie pour un AVR de type x',
    {67} '.DSEG            : segment de donnees (seulement etiquettes et directives .BYTE)', 
    {68} '.DW x,y,z        : insere des mots (.CSEG, .ESEG)',
    {69} '.ELIF x          : .ELSE avec condition x', 
    {70} '.ELSE            : code si la condition controlant le .IF est fausse', 
    {71} '.ENDIF           : ferme un .IF, .ELSE ou .ELIF', 
    {72} '.EQU x=y         : le symbole x est affecte de la valeur constante y',
    {73} '.ERROR x         : declenche une erreur avec message x', 
    {74} '.ESEG            : compile dans le segment Eeprom', 
    {75} '.EXIT [x]        : ferme le fichier source, x etant une expression logique', 
    {76} '.IF x            : compile le code si x est vrai',
    {77} '.IFDEF x         : compile le code si la variable x est definie',
    {78} '.IFDEVICE type   : compile le code si le type est correct', 
    {79} '.IFNDEF x        : compile le code si la variable x et indefinie',
    {80} '.INCLUDE x       : insere le fichier x (de la forme "chemin/nom") dans le source', 
    {81} '.MESSAGE x       : affiche le message x', 
    {82} '.LIST            : passe en mode listing',
    {83} '.LISTMAC         : passe en mode listing pour les macros',
    {84} '.MACRO x         : definit la macro nommee x',
    {85} '.ENDMACRO        : termine la definition de macro (voir .ENDM)',
    {86} '.ENDM            : idem .ENDMACRO',
    {87} '.NOLIST          : quitte le mode listing', 
    {88} '.ORG x           : initialise le compteur CSEG-/ESEG-/DSEG a la valeur x',
    {89} '.SET x=y         : initialise la variable x avec la valeur y', 
    {90} '.SETGLOBAL x,y,z : rend globaux les symboles x, y et z',
    {91} '.UNDEF x         : termine la definition de symbole x',
    {92} 'Constante de valeur comprise entre 0 et 15',
    {93} 'Pointeur Z');

  nasw=11;
  asw:Array[1..nasw] Of String[80]=(
    '001: %1 symbole(s) defini mais inutilise !', 
    '002: variable(s) initialisee(s) plus d''une fois !',
    '003: pas de parametre legal trouve !', 
    '004: Le nombre d''octets faible, ajoute des 00 de remplissage !',
    '005: Le segment de donnees (%1 octets) depasse la taille physique (%2 octets) !', 
    '006: Le materiel n''est pas specfie, le code ne sera pas verifie !',
    '007: Rebouclage !',
    '008: plus d''une initialisation sur variable globale (%1) !',
    '009: Inclure une definition est facultatif : emploi d''une definition interne !', 
    '010: Jeu d''instructions peu clair, pas de documentation !',
    '011: Style c dans l''assembleur, ligne ignoree !');

  nase=102;
  ase:Array[1..nase] Of String[80]=(
    '001: Caractere invalide (%1) dans un nom de symbole !', 
    '002: Le nom de symbole (%1) est une mnemonique : c''est illegal !',
    '003: Le nom de symbole (%1) ne commence pas par une lettre !',
    '004: Caractere illegal dans une valeur binaire (%1) !',
    '005: Caractere illegal dans une valeur hexa (%1) !',
    '006: Caractere illegal dans une valeur decimale (%1) !',
    '007: Constante, variable, etiquette ou materiel non defini (%1) !',
    '008: = inattendu dans l''expression; utilisez == a la place !',
    '009: Debordement de l''expression (%1) lors d''un decalage gauche(%2) !',
    '010: Debordement lors de la multiplication de (%1) par (%2) !',
    '011: Debordement lors de l''addition de (%1) et (%2) !',
    '012: Debordement en soustrayant (%2) de (%1) !',
    '013: Fonction inconnue %1 !',
    '014: Caractere illegal (%1) dans une expression !',
    '015: Il manque une parenthese ouvrante dans l''expression !',
    '016: Il manque une parenthese fermante dans l''expression !',
    '017: Valeur du registre (%1) hors gamme (%2) !',
    '018: Valeur indefinie pour le registre !',
    '019: Valeur manquante pour le registre !',
    '020: Valeur invalide sur le port !',
    '021: Valeur sur le port (%1) hors gamme (%2) !',
    '022: Valeur de bit (%1) hors gamme (0 .. 7) !',
    '023: Etiquette (%1) invalide ou hors gamme (%2) !',
    '024: Constante (%1) hors gamme (%2) !',
    '025: Expression de constante (%1) non lisible !',
    '026: Constante invalide !',
    '027: L''instruction %1 ne peut utiliser que -XYZ+, pas %2 !',
    '028: Il manque X/Y/Z dans l''instruction %1 !',
    '029: L''instruction %1 prend Y or Z comme parametre, pas %2 !',
    '030: Deplacement (%1) hors gamme (%2) !',
    '031: Parametre X+d/Y+d manquant !',
    '032: ''+'' attendu, il y a ''%1'' a la place !',
    '033: Registre et Z/Z+  attendu, %1 a la place !',
    '034: Registre manquant !',
    '035: Instruction illegale (%1) pour un materiel de type (%2) !',
    '036: Fichier d''inclusion (%1) pas trouve !',
    '037: Nom du fichier d''inclusion manquant !',
    '038: Erreur dans le parametre %1 (%2) dans la directive !',
    '039: ''='' manquant dans la directive !',
    '040: Le nom (%1) est deja utilise pour un %2 !',
    '041: Pas pu resoudre le membre droit de l''equation dans EQU/SET/DEF !',
    '042: Le nombe de bytes a reserver est absent !',
    '043: Constante de type BYTE invalide !',
    '044: Trop de parametres : seul le nombre de bytes est attendu !',
    '045: Adresse ORG absente, pas de parametre !',
    '046: L''adresse d''origine pointe vers l''arriere en %2 !',
    '047: Constante ORG indefinie',
    '048: Trop de parametres sur la ligne ORG, une seule adresse est attendue !',
    '049: Pas de litteraux dans une directive DW ! Utilisez plutot la directive DB !',
    '050: On attend des parametres mais il n''y a rien !',
    '051: On attend un nom de materiel  mais il n''y en a pas !',
    '052: Materiel deja defini !',
    '053: Materiel inconnu;  gavrasm -T donne la liste de materiels supportes !',
    '054: Trop de parametres, on n''attend que le nom du materiel !',
    '055: Sympbole ou registre %1 deja defini !',
    '056: Je ne peux pas initialiser un symbole non defini (%1) !',
    '057: La macro (%1) est deja definie !',
    '058: Trop de parametres, on n''attend que le nom d''une macro !',
    '059: Tentative de fermer une macro qui n''a pas ete ouverte, ou qui est vide !',
    '060: Condition .IF manquante !',
    '061: Constante ou variable pas encore definie dans la condition !',
    '062: Erreur dans la condition !',
    '063: Trop de parametres, on n''attend qu''une condition logique !',
    '064: .ENDIF sans .IF !',
    '065: .ELSE/.ELIF sans .IF !',
    '066: Condition illegale dans un segment-%1 ou une macro ',
    '067: Directive inconnue !',
    '068: Pas de macro ouverte a completer !',
    '069: Erreur dans les parametres d''une macro !',
    '070: Instruction ou macro inconnue !',
    '071: Chaune (string) sur plus d''une ligne !',
    '072: Fin de ligne inattendue dans une constante litterale !',
    '073: Constante litterale '''''''' attendue, mais fin de ligne trouvee !',
    '074: Constante litterale '''''''' attendue, mais caractere <> '' trouve !',
    '075: Second '' manquant dans une constante litterale !',
    '076: '':'' manquant apres etiquette ou instruction commencant a la colonne 1 !',
    '077: Multiples etiquettes sur la meme ligne !',
    '078: Parenthese fermante absente !',
    '079: Ligne ne commencant ni par une etiquette, une directive ou un separateur !',
    '080: Parametre de ligne de macro illegal (devrait etre @0 .. @9) !',
    '081: Le segment de code (%1 mots) depasse la limite (%2 mots) !',
    '082: Le segment Eeprom  (%1 bytes) depasse la limite (%2 bytes) !',
    '083: Nom de macro absent !',
    '084: Parametre indefini dans une directive .EXIT !',
    '085: Erreur dans l''expression logique de la directive .EXIT !',
    '086: Condition Break verifiee : arret de l''assemblage !',
    '087: Constante litterale illegale (%1) !',
    '088: Constante chaune illegale (%1) !',
    '089: Chaune ne commencant ni ne finissant par " !',
    '090: Parametre inattendu, ou code illisible en fin de ligne !',
    '091: Parametre manquant ou inconnu !',
    '092: Nom de materiel inconnu !',
    '093: La definition des symboles de base a echoue !',
    '094: La definition du vecteur des adresses d''interruption a echoue !',
    '095: La definition des symboles a echoue !',
    '096: La definition des noms de registres a echoue !',
    '097: Fichier d''inclusion non reconnu, utilisez plutot .DEVICE !',
    '098: Ce materiel ne supporte pas l''instruction d''auto [in/de]crementation !',
    '099: Instruction .IF sans .ENDIF !',
    '100: Definition .DEVICE multiple !',
    '101: Division par zero !',
    '102: L''instruction %1 prend Z comme parametre, pas %2 !');

Procedure ExchPars(sp,se:String;Var s:String);
Var p:Byte;
Begin
p:=Pos(sp,s);
If p>0 Then
  Begin
  Delete(s,p,Length(sp));
  Insert(se,s,p);
  End;
End;

Function GetMsg(c:Char;nem:Byte;s1,s2:String):String;
Begin
Case c Of
  'M':GetMsg:=as[nem];
  'W':GetMsg:=asw[nem];
  'E':GetMsg:=ase[nem];
  End;
ExchPars('%1',s1,GetMsg);
ExchPars('%2',s2,GetMsg);
End;

Function GetMsgW(nem:Byte;s1,s2:String):String;
Begin
GetMsgW:=GetMsg('W',nem,s1,s2);
End;

Function GetMsgE(nem:Byte;s1,s2:String):String;
Begin
If nem=0 Then
  GetMsgE:='Forced error: '+cl.sString Else
  GetMsgE:=GetMsg('E',nem,s1,s2);
End;

Function GetMsgM(nem:Byte):String;
Begin
GetMsgM:=as[nem];
End;

Begin
nMaxErr:=nase;
End.
