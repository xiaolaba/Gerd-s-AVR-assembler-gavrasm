{ Processes macros for gavrasm 
  Version 1.1, last change 06.01.2005 }
Unit gavrmacr;

Interface

Uses gavrsymb;

Type
  TParamArray=Array[1..50] Of String;

  PMacStr=^TMacStr; { One line in macro }
  TMacStr=Record
    sml:String; { line string }
    pnextsml:PMacStr; { pointer to next line }
    End;

  PMacro=^TMacro; { macro }
  TMacro=Record
    sMacName:String; { name string }
    nParam:Integer; { number of parameters expected }
    sParam:Array[0..9] Of String; { parameters on calling line }
    fParamUsed:Array[0..9] Of Boolean; { true if parameter used in macro }
    nMacUsed:LongInt; { times the macro is used in the program }
    pMacLbl1:PSList; { points to first local label in the macro }
    pMacLbl:PSList; { interim storage for macro label pointer }
    ipc0:LongInt; { adress at call of the macro }
    ipcc:LongInt; { relative pc to macro start }
    ipct:LongInt; { number of bytes of macro }
    nMacLines:LongInt; { total number of lines of the macro }
    pMacStr1:PMacStr; { pointer to the first line of the macro }
    pMacLine:PMacStr; { pointer to the next line to be outputted }
    pNextMac:PMacro; { pointer to the next macro in the chain }
    pPrevMac:PMacro; { pointer to the macro that called the macro }
    End;

Var
  fHasMacLines:Boolean; { True if any macro lines left to process }
  pcm:PMacro; { pointer for writing to and reading from a macro }

{ Creates a new macro with name sName, returns false if already defined }
Function WriteNewMacro(sName:String):Boolean;

{ Adds the line sLine to the currently storecd macro, returns false if not open for input }
Function WriteAddMacroLine(sLine:String):Boolean;

{ Closes the currently processed macro, returns false if none open for input }
Function WriteCloseMacro:Boolean;

{ Set macro parameters }
Function SetMacroParams(nmp:Byte;asp:TParamArray):Boolean;

{ Find the macro with name s and parameters sp and opens it for output,
  returns false if macro not found }
Function OpenReadMacro(s:String;ipc:LongInt):Boolean;

{ Get the next line of the macro s found, returns false if no macro open for output }
Function ReadGetMacroLine(Var s:String):Boolean;

{ Sets the macro pointer to the first macro stored, returns false if no macro found }
Function ResetMacroPointer:Boolean;

{ Enumerates the macros stored by their name, returns formatted
  listing entry in s, returns false if no more macros to list }
Function EnumMacroList(Var s:String):Boolean;

{ Find the macro named s and return its length in i, returns false
  if macro not found }
Function FindMacroLength(s:String;Var i:LongInt):Boolean;

{ Exports a macro symbol named s to a global variable, returns false if symbol not found }
Function ExportMacroSymbol(s:String):Boolean;

{ Attach all macro labels to the symbol list for listing them }
Procedure ConcatAllMacroLabels;

{ Detach all local macro symbols from the symbol list }
Procedure RemoveAllMacroLabels;

{ Clear the macro list in memory }
Procedure CloseAllMacros;

Implementation

Uses SysUtils,gavrline;

Var pm1:PMacro; { pointer to the first macro entry, NIL if none }
  pl0,pll:pSList; { first and last entry in the original symbol list }

{ ----------------------------------------------------------
  Macro write operations; macros organised in a concatenated
  list in memory space; the symbol list is watched for any
  symbols defined within that macro, during entry of lines,
  the symbol list adds the local symbols, on close these
  symbols are detached from the symbol list
  ----------------------------------------------------------}
{ define a new macro, returns false if macro already defined }
Function WriteNewMacro(sName:String):Boolean;
Var pm,pp:PMacro;
  k:Byte;
Begin
If pm1=NIL Then { no macro stored before }
  Begin
  New(pm1); { create first macro }
  pm:=pm1; { pm is pointer to that macro }
  pp:=NIL; { no previous macro }
  End Else
  Begin
  pm:=pm1; { point to first macro }
  While (pm<>NIL) And (sName<>pm^.sMacName) Do { name ok? }
    Begin
    pp:=pm; { remember previous macro }
    pm:=pm^.pNextMac; { point to next macro }
    End;
  If pm=NIL Then { end of list reached }
    Begin
    New(pm); { create next macro entry }
    pp^.pNextMac:=pm; { attach to the macro list }
    End Else
    pm:=NIL; { already a macro of that name }
  End;
WriteNewMacro:=pm<>NIL; { new macro fine? }
If WriteNewMacro Then With pm^ Do
  Begin
  sMacName:=sName; { set the macro's name }
  nParam:=0; { no parameters so far }
  nMacLines:=0; { no lines so far }
  nMacUsed:=0; { not used so far }
  ipc0:=0; { clear the instruction counter offset }
  ipcc:=0; { instruction counter clear }
  ipct:=0; { total instruction count clear }
  pMacLbl1:=NIL; { has no local symbols }
  pMacLbl:=NIL; { no symbol in symbol list }
  pMacStr1:=NIL; { no lines stored, clear pointer }
  pMacLine:=NIL; { current input line pointer clear }
  pNextMac:=NIL; { pointer to the next macro list entry clear }
  pPrevMac:=pp; { pointer the last defined macro }
  For k:=0 To 9 Do { clear parameter list of the macro }
    Begin
    fParamUsed[k]:=False;
    sParam[k]:='';
    End;
  pll:=FindSymbolLast; { point to currently last symbol }
  End;
pcm:=pm; { point to this macro entry for inputting lines }
End;

{ inputs the next macro line during definition, returns false
  if no macro is open for input }
Function WriteAddMacroLine(sLine:String):Boolean;
Begin
WriteAddMacroLine:=pcm<>NIL; { check if input pointer is fine }
If WriteAddMacroLine Then With pcm^ Do
  Begin
  If pMacStr1=NIL Then { so far no first line in this macro }
    Begin
    New(pMacStr1); { create first line }
    pMacLine:=pMacStr1; { point to this line entry }
    End Else
    Begin
    New(pMacLine^.pNextSml); { create next line entry }
    pMacLine:=pMacLine^.pNextSml; { point to this line entry }
    End;
  pMacLine^.sml:=sLine; { store line }
  pMacLine^.pNextSml:=NIL; { clear pointer to the next line }
  Inc(nMacLines); { count number of lines entered }
  ipcc:=ipcc+Inst.nw; { count the number of instruction words }
  ipct:=ipcc; { increase total length of instruction words }
  End;
End;

{ closes the macro for input, returns false if no macro open
  or number of lines is 0 }
Function WriteCloseMacro:Boolean;
Var pp:pMacro;
Begin
WriteCloseMacro:=(pcm<>NIL); { close only if opened }
If WriteCloseMacro Then
  Begin
  If pcm^.nMacLines>0 Then With pcm^ Do { at least one line }
    Begin
    pMacLbl:=FindSymbolLast; { last label in the symbol list }
    If pll=pMacLbl Then { no symbols defined within that macro }
      pMacLbl1:=NIL Else { clear the symbol pointer }
      Begin
      pMacLbl1:=pll^.pNext; { set the local symbol pointer }
      pll^.pNext:=NIL; { detach the local symbols from the list }
      End;
    End Else
    Begin { delete the empty macro from the list }
    pp:=pcm^.pPrevMac; { point to previous macro }
    If pp<>NIL Then pp^.pNextMac:=NIL; { clear the next pointer }
    Dispose(pcm); { clear mem space of the macro }
    WriteCloseMacro:=False; { return error }
    End;
  End;
pcm:=NIL; { no macro open for input }
End;

{ ------------------------------------------------------------
  Macro line read operations: Getting the stored macro lines
  back into the code, if a macro is called
  ------------------------------------------------------------}
{ sets the macro parameters }
Function SetMacroParams(nmp:Byte;asp:TParamArray):Boolean;
Var k:Byte;
Begin
SetMacroParams:=False;
If pcm<>NIL Then With pcm^ Do { pcm points to current macro }
  Begin
  If nmp<=10 Then { check number of parameters on that line }
    Begin
    For k:=1 To nmp Do sParam[k-1]:=asp[k]; { set the macro params }
    nParam:=nmp; { remember the number of params }
    SetMacroParams:=True;  { parameters fine }
    End;
  End;
End;

{ finds the macro with the name s and the parameters in sp,
  returns false if not found }
Function OpenReadMacro(s:String;ipc:LongInt):Boolean;
Var pm:PMacro;
  psl:pSList;
Begin
pm:=pm1; { start with the first macro }
While (pm<>NIL) And (pm^.sMacName<>s) Do { find macro with that name }
  pm:=pm^.pNextMac;
OpenReadMacro:=pm<>NIL; { macro found in list? }
If OpenReadMacro Then
  Begin
  pm^.pPrevMac:=pcm; { set the former pointer to step back one level }
  pcm:=pm; { Set the read pointer to the current macro }
  pcm^.pMacLine:=pcm^.pMacStr1; { set the line pointer to the first line }
  pcm^.ipc0:=ipc; { Remember the current pc counter }
  pcm^.pMacLbl:=FindSymbolLast; { go to end of current symbol table }
  psl:=pcm^.pMacLbl1; { point psl to the first symbol in the macro }
  If psl<>NIL Then { if there are symbols within the macro }
    Begin
    If pcm^.pMacLbl=NIL Then { are there symbols before? }
      pList0:=psl Else { nope, set the first symbol in the list }
      pcm^.pMacLbl^.pNext:=psl; { yes, concatenate the lists }
    While psl<>NIL Do
      Begin
      psl^.iValue:=psl^.iValue+pcm^.ipc0; { set the actual values }
      If psl^.fHasGlobal Then { set the value of the global copy }
        SetSymbol('G',psl^.sName,True,psl^.iValue);
      psl:=psl^.pNext; { move down the symbol list }
      End;
    End;
  fHasMacLines:=True; { macro has lines to be read }
  Inc(pcm^.nMacUsed); { count the times that the macro was used }
  End;
End;

{ get the next line of a macro during output, returns false if not open for output }
Function ReadGetMacroLine(Var s:String):Boolean;
Var pm:PMacro;
  psl:pSList;
  k,l:Integer;
Begin
s:=''; { s returns the next line, default is a blank line }
ReadGetMacroLine:=pcm<>NIL; { check if a macro is open for read }
If ReadGetMacroLine Then
  Begin
  If pcm^.pMacLine<>NIL Then With pcm^ Do { another line is available }
    Begin
    s:=pMacLine^.sml; { get the line }
    k:=1; { find and exchange parameters @0..@9 on that line }
    While ReadGetMacroLine And (k<=Length(s)) Do
      Begin
      Case s[k] Of
        '''': { ignore characters in literal constants }
          Repeat Inc(k) Until (k>Length(s)) Or (s[k]='''');
        '"': { ignore characters in strings }
          Repeat Inc(k) Until (k>Length(s)) Or (s[k]='"');
        '@': { found a @ character }
          Begin
          If (k<Length(s)) And (s[k+1]>='0') And (s[k+1]<='9') Then
            Begin
            l:=Byte(s[k+1])-48; { get the parameter number }
            Delete(s,k,2); { remove @x from string }
            Insert(sParam[l],s,k); { insert the parameter string }
            k:=k+Length(sParam[l])-2; { overread the inserted parameter string }
            End Else
            ReadGetMacroLine:=False; { not @0..@9, illegal }
          End;
        End;
      Inc(k); { next character in the string }
      End;
    pMacLine:=pMacLine^.pNextSml; { point to next string in macro }
    End Else { no more lines available within the current macro }
    Begin
    If pcm^.pMacLbl1<>NIL Then With pcm^ Do { remove the macro's symbols }
      Begin
      If pMacLbl=NIL Then { symbol list empty? }
        pList0:=NIL Else { clear the first pointer }
        pMacLbl^.pNext:=NIL; { clear the end of the list }
      psl:=pMacLbl1; { point to first symbol }
      While psl<>NIL Do
        Begin
        psl^.iValue:=psl^.iValue-ipc0; { remove the pc offset }
        psl:=psl^.pNext; { point to next value }
        End;
      End;
    pm:=pcm^.pPrevMac; { get the pointer to the previous macro }
    pcm^.pPrevMac:=NIL; { clear previous macro in the current macro }
    pcm^.pMacLine:=pcm^.pMacStr1; { line pointer to first entry }
    pcm:=pm; { point to previous macro }
    ReadGetMacroLine:=ReadGetMacroLine And ReadGetMacroLine(s);
      { get the next line from the prevous macro }
    If pcm=NIL Then fHasMacLines:=False; { no more macros to process }
    End;
  End;
End;

{ Find the macro named s and return its length in instruction words
  in i, returns false, if macro was not found }
Function FindMacroLength(s:String;Var i:LongInt):Boolean;
Var pm:pMacro;
Begin
pm:=pm1; { start with first macro }
While (pm<>NIL) And (s<>pm^.sMacName) Do { find that macro }
  pm:=pm^.pNextMac;
FindMacroLength:=pm<>NIL; { macro name found }
If FindMacroLength Then i:=pm^.ipct; { return its length }
End;

{ sets the macro pointer to the first macro in the list, returns
  false if no macros are stored }
Function ResetMacroPointer:Boolean;
Begin
pcm:=pm1; { point to first macro }
ResetMacroPointer:=(pm1<>NIL); { a macro defined }
If ResetMacroPointer Then
  pcm^.pMacLbl:=pcm^.pMacLbl1; { store symbol pointer }
End;

{ formats an integer value i to the length l with leading blanks }
Function Int2Str(i,l:LongInt):String;
Begin
Int2Str:=IntToStr(i);
While Length(Int2Str)<l Do Int2Str:=' '+Int2Str; { insert blanks }
End;

{ the next macro name for the macro list in s, returns false if none }
Function EnumMacroList(Var s:String):Boolean;
Begin
EnumMacroList:=pcm<>NIL; { check macro read pointer }
If EnumMacroList Then With pcm^ Do
  Begin  { returns list entry for the macro list }
  s:=Int2Str(nMacLines,6)+ { number of lines }
    Int2Str(nMacUsed Div 2,6)+ { number of times called }
    Int2Str(nParam,8)+' '+ { number of params used }
    sMacName; { the macro's name }
  pcm:=pNextMac; { point to next macro in the list }
  End;
End;

{ Exports a macro symbol named s to a global variable,
  returns false if symbol not found }
Function ExportMacroSymbol(s:String):Boolean;
Var plm:psList;
Begin
ExportMacroSymbol:=False;
If pcm<>NIL Then
  Begin
  plm:=pcm^.pMacLbl1;
  While (plm<>NIL) And (plm^.sName<>Uppercase(s)) Do plm:=plm^.pNext;
  If plm<>NIL Then
    Begin
    ExportMacroSymbol:=True;
    ConvertLocalToGlobal(s,plm);
    End;
  End;
End;

{ ---------------------------------------------------------
  Attach and remove the macro labels entries in the symbol
  list; all symbols are organised as a concatenated list
  ---------------------------------------------------------}
{ Concat all macro labels to the symbol list for listing them }
Procedure ConcatAllMacroLabels;
Var plla:pSList;
Begin
pcm:=pm1;
pl0:=pList0; { remember the original symbol list }
pll:=FindSymbolLast;
plla:=pll; { start with the last entry in the symbol list }
While pcm<>NIL Do
  Begin
  If pcm^.pMacLbl1<>NIL Then With pcm^ Do
    Begin
    If plla=NIL Then
      pList0:=pMacLbl1 Else { no entries, set list start to macro's list }
      plla^.pNext:=pMacLbl1; { concat macro's symbol list to the last entry }
    plla:=FindSymbolLast; { find last entry }
    pMacLbl:=plla; { remember the last entry of the macro's list }
    End;
  pcm:=pcm^.pNextMac; { next macro }
  End;
End;

{ Remove all macro symbols from the symbol list }
Procedure RemoveAllMacroLabels;
Begin
pcm:=pm1; { start with the first macro }
While pcm<>NIL Do
  Begin
  If pcm^.pMacLbl1<>NIL Then
    With pcm^ Do pMacLbl^.pNext:=NIL; { disconnect the macro's list }
  pcm:=pcm^.pNextMac; { the next macro }
  End;
pList0:=pl0; { restore the old symbol list }
If pll<>NIL Then pll^.pNext:=NIL; { disconnect the last symbol entry }
End;

{ -----------------------------------------------------------
  On close of the assembler all macro space has to be cleared
  -----------------------------------------------------------}
{ clears all stored macros and the memory space used }
Procedure CloseAllMacros;
Var pm,pmn:PMacro;
  ps,psn:PMacStr;
  pl,pln:PSList;
Begin
pm:=pm1; { point to first macro }
While pm<>NIL Do { more macros to delete }
  Begin
  pl:=pm^.pMacLbl1; { point to the first symbol within that macro }
  While pl<>NIL Do
    Begin
    pln:=pl^.pNext; { remember the next symbol }
    Dispose(pl); { clear this symbol }
    pl:=pln; { point to the next symbol }
    End;
  ps:=pm^.pMacStr1; { point to the first line of that macro }
  While ps<>NIL Do
    Begin
    psn:=ps^.pNextSml; { remember the next line }
    Dispose(ps); { clear this line }
    ps:=psn; { point to the next line }
    End;
  pmn:=pm^.pNextMac; { remember the next macro }
  Dispose(pm); { clear this macro }
  pm:=pmn; { point to the next macro }
  End;
End;

{ Main unit initiation, clear all macro pointers }
Begin
pm1:=NIL;
pcm:=NIL;
fHasMacLines:=False;
End.
