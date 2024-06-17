{ Processes macros for gavrasm 
  Version 1.1, created 06.01.2005 
  Version 1.2, modified 13.01.2019 }
Unit gavrmacr;

Interface

Uses gavrsymb,gavrline;

Type
  TParamArray=Array[1..maxAsp] Of String;

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
    nMacUse:LongInt; { Use counter for this macro }
    nMacUsed:LongInt; { times the macro is used in the program }
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

{ Clear all macro use counters }
Function ClearAllMacroUseCounters:Boolean;

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

{ Clear the macro list in memory }
Procedure CloseAllMacros;

Implementation

Uses SysUtils;

Var pm1:PMacro; { pointer to the first macro entry, NIL if none }

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
  pm^.sMacName:=sName;
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
  nMacUse:=0; { clear use counter }
  nMacUsed:=0; { not used so far }
  pMacStr1:=NIL; { no lines stored, clear pointer }
  pMacLine:=NIL; { current input line pointer clear }
  pNextMac:=NIL; { pointer to the next macro list entry clear }
  pPrevMac:=pp; { pointer the last defined macro }
  For k:=0 To 9 Do { clear parameter list of the macro }
    Begin
    fParamUsed[k]:=False;
    sParam[k]:='';
    End;
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
  End;
End;

{ closes the macro for input, returns false if no macro open
  or number of lines is 0 }
Function WriteCloseMacro:Boolean;
Var pp:pMacro;
Begin
WriteCloseMacro:=(pcm<>NIL); { close only if opened }
If WriteCloseMacro And (pcm^.nMacLines=0) Then
  Begin { delete the empty macro from the list }
  pp:=pcm^.pPrevMac; { point to previous macro }
  If pp<>NIL Then pp^.pNextMac:=NIL; { clear the next pointer }
  Dispose(pcm); { clear mem space of the macro }
  WriteCloseMacro:=False; { return error }
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

{ ---------------------------------------
  Clear all macro use counters:
  Returns False if no macros are defined
  ---------------------------------------}
Function ClearAllMacroUseCounters:Boolean;
Var pm:PMacro;
begin
ClearAllMacroUseCounters:=False;
pm:=pm1; { start with the first macro }
While pm<>NIL Do
  begin
  ClearAllMacroUseCounters:=True;
  pm^.nMacUse:=0;
  pm:=pm^.pNextMac;
  end;
end;

{ Finds the macro with the name s and the parameters in sp,
  returns false if not found }
Function OpenReadMacro(s:String;ipc:LongInt):Boolean;
Var pm:PMacro;
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
  fHasMacLines:=True; { macro has lines to be read }
  Inc(pcm^.nMacUse); { increase the use counter }
  Inc(pcm^.nMacUsed); { count the times that the macro was used }
  End;
End;

{ get the next line of a macro during output, returns false if not open for output }
Function ReadGetMacroLine(Var s:String):Boolean;
Var pm:PMacro;
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
        '@': { found an @ character }
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
    pm:=pcm^.pPrevMac; { get the pointer to the previous macro }
    pcm^.pPrevMac:=NIL; { clear previous macro in the current macro }
    pcm^.pMacLine:=pcm^.pMacStr1; { line pointer to first entry }
    pcm:=pm; { point to previous macro }
    ReadGetMacroLine:=ReadGetMacroLine And ReadGetMacroLine(s);
      { get the next line from the previous macro }
    If pcm=NIL Then fHasMacLines:=False; { no more macros to process }
    End;
  End;
End;

{ sets the macro pointer to the first macro in the list, returns
  false if no macros are stored }
Function ResetMacroPointer:Boolean;
Begin
pcm:=pm1; { point to first macro }
ResetMacroPointer:=(pm1<>NIL); { a macro defined }
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

{ -----------------------------------------------------------
  On close of the assembler all macro space has to be cleared
  -----------------------------------------------------------}
{ clears all stored macros and the memory space used }
Procedure CloseAllMacros;
Var pm,pmn:PMacro;
  ps,psn:PMacStr;
Begin
pm:=pm1; { point to first macro }
While pm<>NIL Do { more macros to delete }
  Begin
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
