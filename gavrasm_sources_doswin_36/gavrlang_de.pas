{ Deutschsprachige Uebersetzungsdatei
  Ersetze gavrlang.pas mit dieser Datei
  zur Erzeugung der deutschen Version,
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
    { 1} 'Unbekannte Option in der Aufrufzeile: ',
    { 2} 'Quelldatei nicht gefunden: ',
    { 3} 'Fehler ',
    { 4} 'Datei: ',
    { 5} 'Zeile: ',
    { 6} 'Quellzeile: ',
    { 7} 'Warnung ',
    { 8} 'Liste der Symbole:',
    { 9} 'Typ  nDef nNutz Dezimalwert  Hexwert Name',
    {10} 'Keine Symbole definiert.',
    {11} 'Liste der Makros:',
    {12} 'Zeilen nNutz nParam  Name',
    {13} '   Keine Makros.',
    {14} 'Datei einfuegen ',
    {15} 'Fortsetzung mit Datei ',
    {16} ' Zeilen verarbeitet.',
    {17} 'Quelldatei:  ',
    {18} 'Hexdatei:    ',
    {19} 'Eepromdatei: ',
    {20} 'Kompiliert:  ',
    {21} 'Durchgang:   ',
    {22} 'Kompiliere ',
    {23} ' Worte Code, ',
    {24} ' Worte Konstanten, Gesamt=',
    {25} 'Keine Warnungen!',
    {26} 'Eine Warnung!',
    {27} ' Warnungen!',
    {28} 'Kompilation fertig, keine Fehler.',
    {29} 'Programm        : ',
    {30} 'Konstanten      : ',
    {31} 'Programm Gesamt : ',
    {32} 'Eepromnutzung   : ',
    {33} 'Datensegment    : ',
    {34} 'Kompilation beendet ',
    {35} 'Kompilation abgebrochen, ',
    {36} 'ein Fehler!',
    {37} ' Fehler!',
    {38} ' Auf Wiederlesen ...',
    {39} 'nicht geradzahlig', { even register instruction! }
    {40} ' \\ Instruktion hat keine Parameter!',
    {41} 'Register im Bereich zwischen R0 und R31',
    {42} 'Bitwert im Bereich zwischen 0 und 7',
    {43} 'Relative Sprungadresse (Marke) im Bereich -64 bis +63',
    {44} 'Absolute Sprungadresse (Marke), 16/22-Bit-Adresse',
    {45} 'Keiner oder Register und Z oder Register und Z+',
    {46} 'Relative Sprungadresse (Marke) im Bereich +/- 2k',
    {47} 'Register im Bereich zwischen R16 und R31',
    {48} 'Doppelregister R24, R26, R28 oder R30',
    {49} 'Unterer Portwert zwischen 0 und 31',
    {50} 'Register im Bereich zwischen R16 und R23',
    {51} 'Gerades Register (R0, R2 ... R30)',
    {52} 'Port im Bereich zwischen 0 und 63',
    {53} 'X/Y/Z oder X+/Y+/Z+ oder -X/-Y/-Z',
    {54} 'Y+Distanzwert oder Z+Distanzwert, Bereich 0..63',
    {55} '16-Bit-SRAM-Adresse',
    {56} 'Konstante im Bereich 0..63',
    {57} 'Konstante im Bereich 0..255',
    {58} 'Parameter',
    {59} 'Interner Compiler Fehler! Bitte Bericht an gavrasm@avr-asm-tutorial.net!',
    {60} 'Siehe die Liste der Direktiven mit gavrasm -d!',
    {61} 'Liste der unterstuetzten Direktiven',
    {62} '.BYTE x   : reserviert x Bytes im Datensegment (siehe auch .DSEG)',
    {63} '.CSEG     : compiliert in das Code-Segment',
    {64} '.DB x,y,z : Byte(s) oder Zeichen(ketten) einfuegen (.CSEG, .ESEG)',
    {65} '.DEF x=y  : dem Symbol x ein Register y zuweisen',
    {66} '.DEVICE x : die Pruefung fuer den AVR-Typ x duerchfuehren',
    {67} '.DSEG     : Datensegment, nur Marken und .BYTE zulaessig',
    {68} '.DW x,y,z : Datenworte einfuegen (.CSEG, .ESEG)',
    {69} '.ELIF x   : .ELSE mit zusaetzlicher Bedingung x',
    {70} '.ELSE     : Alternativcode, wenn .IF nicht zutreffend war',
    {71} '.ENDIF    : schlieszt .IF bzw. .ELSE ab',
    {72} '.EQU x=y  : dem Symbol x einen festen Wert y zuweisen',
    {73} '.ERROR x  : erzwungener Fehler mit Fehlertext x',
    {74} '.ESEG     : compiliert in das Eeprom-Segment',
    {75} '.EXIT [x] : Beendet die Compilation, x ist ein logischer Ausdruck',
    {76} '.IF x     : compiliert den folgenden Code, wenn x erfuellt ist',
    {77} '.IFDEF x  : compiliert den Code, wenn Variable x definiert ist',
    {78} '.IFDEVICE typ : compiliert den folgenden Code fuer den AVR-Typ',
    {79} '.IFNDEF x : compiliert den Code, wenn Variable x undefiniert ist',
    {80} '.INCLUDE x: fuegt Datei "Name/Pfad" x in den Quellcode ein',
    {81} '.MESSAGE x: gibt die Meldung x aus',
    {82} '.LIST     : Schaltet die Ausgabe der Listdatei ein',
    {83} '.LISTMAC  : Schaltet die vollstaendige Ausgabe von Makrocode ein',
    {84} '.MACRO x  : Definition des Makros mit dem Namen x',
    {85} '.ENDMACRO : Beendet die Makrodefinition (siehe auch .ENDM)',
    {86} '.ENDM     : Beendet die Makrodefinition (siehe auch .ENMACRO)',
    {87} '.NOLIST   : Schaltet die Ausgabe der Listdatei aus',
    {88} '.ORG x    : Setzt den CSEG-/ESEG-/DSEG-Zaehler auf den Wert x',
    {89} '.SET x=y  : Dem Symbol x wird ein variabler Wert y zugewiesen',
    {90} '.SETGLOBAL x,y,z: globalisiere die lokalen Variablen x, y und z',
    {91} '.UNDEF x  : Setze definiertes Symbol x als undefiniert',
    {92} 'Konstante im Bereich 0..15',
    {93} 'Zeiger Z');

  nasw=11;
  asw:Array[1..nasw] Of String[80]=(
    '001: %1 Symbol(e) definiert, aber nicht benutzt!',
    '002: Mehr als ein SET bei Variable(n)!',
    '003: Keine gueltigen Parameter gefunden!',
    '004: Anzahl Bytes in der Zeile ist ungerade, 00 hinzugefuegt!',
    '005: Datensegment (%1 bytes) ueberschreitet Typgrenze (%2 bytes)!',
    '006: Keine DEVICE-Direktive, keine Typpruefung!',
    '007: Wrap-around!',
    '008: Mehr als ein SET bei einer Globalvariable (%1)!',
    '009: Include-Datei nicht erforderlich, interne Symbole verwendet!',
    '010: Instruktionsset unsicher, keine Dokumentation!',
    '011: C-Stil in Assemblerdatei, Zeilen ignoriert!');

  nase=102;
  ase:Array[1..nase] Of String[80]=(
    '001: Ungueltiges Zeichen (%1) in einem Symbolnamen!',
    '002: Symbolname (%1) ist eine Instruktion, ungueltig!',
    '003: Symbolname (%1) beginnt nicht mit einem Buchstaben!',
    '004: Ungueltiges Zeichen (%1) in einem Binaerwert!',
    '005: Ungueltiges Zeichen (%1) in einem Hexadezimalwert!',
    '006: Ungueltiges Zeichen (%1) in einem Dezimalwert!',
    '007: Undefinierte Konstante, Variable, Marke oder Device (%1)!',
    '008: Gleichheitszeichen im Ausdruck, benutze == anstatt =!',
    '009: Ueberlauf von (%1) waehrend des Linksschiebens (%2)!',
    '010: Ueberlauf bei der Multiplikation von (%1) mit (%2)!',
    '011: Ueberlauf beim Addieren von (%1) mit (%2)!',
    '012: Unterlauf bei der Subtraktion von (%2) von (%1)!',
    '013: Unbekannte Funktion %1!',
    '014: Ungueltiges Zeichen (%1) im Ausdruck!',
    '015: Fehlende eroeffnende Klammer im Ausdruck!',
    '016: Fehlende schliessende Klammer im Ausdruck!',
    '017: Registerwert (R%1) ausserhalb zulaessiger Bereich (%2)!',
    '018: Registerwert undefiniert!',
    '019: Registerangabe fehlt!',
    '020: Portwert unbekannt!',
    '021: Portwert (%1) ausserhalb des zulaessigen Bereichs (%2)!',
    '022: Bitwert (%1) ausserhalb des zulaessigen Bereichs (0..7)!',
    '023: Marke (%1) ungueltig/ausserhalb zulaessiger Bereich (%2)!',
    '024: Konstante (%1) ausserhalb zulaessiger Bereich (%2)!',
    '025: Konstantenausdruck (%1) nicht auswertbar!',
    '026: Konstante ungueltig!',
    '027: %1-Anweisung kann nur -XYZ+ verwenden, nicht %2!',
    '028: Fehlendes X/Y/Z bei %1-Anweisung!',
    '029: %1-Anweisung benoetigt Y oder Z als Parameter, nicht %2!',
    '030: Distanzangabe (%1) ausserhalb des zulaessigen Bereichs (%2)!',
    '031: Parameter X+d/Y+d erforderlich!',
    '032: ''+'' erwartet, aber ''%1'' gefunden!',
    '033: Registerangabe und Z/Z+ erwartet, aber %1 gefunden!',
    '034: Registerangabe fehlt!',
    '035: Nicht implementierte Anweisung (%1) fuer den Typ (%2)!',
    '036: Einfuegedatei (%1) nicht gefunden!',
    '037: Name der Einfuegedatei fehlt!',
    '038: Fehler in Parameter %1 (%2) der Direktive!',
    '039: Vermisse "=" in der Direktive!',
    '040: Name (%1) schon verwendet fuer eine %2!',
    '041: Kann die rechte Seite der EQU/SET/DEF-Direktive nicht aufloesen!',
    '042: Es fehlt die Angabe der zu reservierenden Bytes!',
    '043: Ungueltige BYTE-Konstante!',
    '044: Zu viele Parameter, nur die Anzahl Bytes wird erwartet!',
    '045: Fehlende ORG-Adresse, kein Parameter angegeben!',
    '046: Ursprungsadresse (%1) zeigt rueckwaerts (%2)!',
    '047: Undefinierte ORG-Konstante!',
    '048: Zu viele Parameter in der ORG-Zeile, nur die Adresse!',
    '049: Zeichenkonstanten in DW-Directive ungueltig! Nutze DB!',
    '050: Keine Parameter gefunden, erwarte Worte!',
    '051: Erwarte Typangabe, kein Typname gefunden!',
    '052: Typ schon definiert!',
    '053: Unbekannter Typ, Aufruf mit -T listet gueltige Typen!',
    '054: Zu viele Parameter, nur Typname erwartet!',
    '055: Symbolname/Registername (%1) schon definiert!',
    '056: Wert des undefinierten Symbols (%1) nicht setzbar!',
    '057: Makro (%1) schon definiert!',
    '058: Zu viele Parameter, nur den Makronamen!',
    '059: Schliessen eines nicht geoeffneten Makro oder leeres Makro!',
    '060: .IF-Bedingung fehlt!',
    '061: Undefiniertes Symbol in der Bedingung, muss definiert sein!',
    '062: Fehler in der Bedingung!',
    '063: Zu viele Parameter, erwarte nur ein logisches Ergebnis!',
    '064: .ENDIF ohne .IF',
    '065: .ELSE/ELIF ohne .IF!',
    '066: Ungueltige Direktive innerhalb des %1-Segments oder Makros!',
    '067: Unbekannte Directive!',
    '068: Kein Makro geoeffnet zur Aufnahme von Zeilen!',
    '069: Fehler bei den Makroparametern!',
    '070: Unbekannte Anweisung oder Makro!',
    '071: Zeichenkette ueberschreitet Zeilenende!',
    '072: Unerwartetes Zeilenende in Zeichenkonstante!',
    '073: Zeichenkonstante '''''''' erwarted, Zeilenende gefunden!',
    '074: Zeichenkonstante '''''''' erwartet, aber Zeichen <> '' gefunden!',
    '075: Vermisse zweites '' in Zeichenkonstante!',
    '076: Kein '':'' gefunden nach Marke oder Instruktion in Spalte 1!',
    '077: Doppelte Marke in Zeile!',
    '078: Vermisse schliessende Klammer!',
    '079: Zeile beginnt nicht mit Marke, Direktive oder Trenner!',
    '080: Parameterfehler in Makrozeile (sollte sein @0..@9)!',
    '081: Codesegment (%1 Worte) ueberschreitet Typgrenze (%2 Worte)!',
    '082: Eepromsegment (%1 Bytes) ueberschreitet Typgrenze (%2 Bytes)!',
    '083: Fehlender Makroname!',
    '084: Undefinierter Parameter in EXIT-Direktive!',
    '085: Logischer Ausdruck in EXIT-Direktive fehlerhaft!',
    '086: Abbruch-Bedingung erfuellt, assemblieren wird abgebrochen!',
    '087: Ungueltige Zeichenkonstante (%1)!',
    '088: Ungueltige Zeichenkette (%1)!',
    '089: Zeichenkette (%1) beginnt und endet nicht mit "!"',
    '090: Unerwarteter Parameter oder Muell am Zeilenende!',
    '091: Fehlende(r) oder falsche(r) Parameter!',
    '092: Unbekannter Device-Name (%1)!',
    '093: Definition der Basis-Symbole gescheitert!',
    '094: Definition der Int-Vektor-Addressen gescheitert!',
    '095: Definition der Symbole gescheitert!',
    '096: Definition der Registernamen gescheitert!',
    '097: Nicht erkannte Include-Datei, benutze .DEVICE!',
    '098: Device unterstuetzt Auto-Inc/Dec nicht!',
    '099: IF-Bedingung ohne ENDIF',
    '100: Mehrfache DEVICE-Definition',
    '101: Division durch Null',
    '102: %1-Anweisung benoetigt Z als Parameter, nicht %2!');

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
  GetMsgE:='Erzwungener Fehler: '+cl.sString Else
  GetMsgE:=GetMsg('E',nem,s1,s2);
End;

Function GetMsgM(nem:Byte):String;
Begin
GetMsgM:=as[nem];
End;

Begin
nMaxErr:=nase;
End.
