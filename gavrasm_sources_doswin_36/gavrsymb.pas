{ Processes symbols for gavrasm }
{ Version 1.1, Last changed: 25.05.2012 }
Unit gavrsymb;

Interface

Const
  sAllTypes='CVLMGRT';

Type
  PSList=^TSList; { Concatenated list for labels, constants, etc. }
  TSList=Record
    cType:Char;
    sName:String;
    iValue:LongInt;
    nDefined:LongInt;
    fValid:Boolean;
    fDefInc:Boolean;
    fHasGlobal:Boolean;
    nUsed:LongInt;
    pNext:PSList;
    End;

Var
  pList0:pSList; { the first list element }
  fWithinDefInclude:Boolean; { within definition include file: ignore unused }

{ add a new symbol s of type c with value i, returns false if symbol is
  already defined and is not a variable }
Function AddSymbol(c:Char;s:String;fVal:Boolean;i:LongInt):Boolean;

{ sets the value of the symbol s with the type c to the value i,
  returns false, if undefined }
Function SetSymbol(sc:String;s:String;fValid:Boolean;i:LongInt):Boolean;

{ converts a local macro symbol named s to a global one }
Function ConvertLocalToGlobal(s:String;pl:pSList):Boolean;

{ returns the value i of the symbol s out of the types listed
  in sTypes, fValid is true if the symbol is defined valid, returns
  false if the symbol is not found }
Function GetSymbolValue(sTypes:String;s:String;Var fValid:Boolean;Var iValue:LongInt):Boolean;

{ undefines the symbol s by setting fValid false, returns false if not defined yet }
Function UndefSymbol(s:String):Boolean;

{ clears all nUsed of all symbols }
Procedure ClearAllnUsed;

{ returns true if there are symbols defined }
Function FindAnySymbol:Boolean;

{ find the first symbol of the type ct, returns NIL if not found }
Function FindSymbolFirst(ct:Char):pSList;

{ find the next symbol of the same type, returns NIL if no more symbols }
Function FindSymbolNext:pSList;

{ find the last element in the list }
Function FindSymbolLast:pSList;

{ check all unused and redefined symbols, returns TRUE if none }
Function CheckAllSymbols(Var nUnused,nVarReDef:LongInt):Boolean;

{ clears all symbols in memory }
Procedure ClearSymbols;

Implementation

Uses SysUtils;

Var
  p:PSList; { First symbol defined }

{ -------------------------- }
{ Store and retrieve symbols }
{ -------------------------- }
{ add a new symbol s of type c with value i, returns false if symbol is
  already defined and is not a variable }
Function AddSymbol(c:Char;s:String;fVal:Boolean;i:LongInt):Boolean;
Var pList,pPrev:PSList;
Begin
AddSymbol:=True;
pList:=pList0;
pPrev:=NIL;
While (pList<>NIL) And (pList^.sName<>Uppercase(s)) Do
  Begin
  pPrev:=pList;
  pList:=pList^.pNext;
  End;
If pList=NIL Then
  Begin
  If pPrev=NIL Then
    Begin
    New(pList0);
    pList:=pList0;
    End Else
    Begin
    New(pPrev^.pNext);
    pList:=pPrev^.pNext;
    End;
  With pList^ Do
    Begin
    cType:=c;
    sName:=UpperCase(s);
    iValue:=i;
    fValid:=fVal;
    nDefined:=1;
    If cType='T' Then nUsed:=1 Else nUsed:=0;
    fDefInc:=fWithinDefInclude;
    fHasGlobal:=False;
    pNext:=NIL;
    End;
  pList^.fValid:=fVal;
  End Else
  Begin
  With pList^ Do
    Begin
    AddSymbol:=Pos(c,'CLMPRT')<1;
    Inc(nDefined);
    iValue:=i;
    fValid:=fVal;
    End;
  End;
End;

{ sets the value of the symbol s with the type c to the value i,
  returns false, if undefined }
Function SetSymbol(sc:String;s:String;fValid:Boolean;i:LongInt):Boolean;
Var pList:PSList;
Begin
pList:=pList0;
While (pList<>NIL) And ((Pos(pList^.cType,sc)<1) Or (pList^.sName<>Uppercase(s))) Do pList:=pList^.pNext;
If pList=NIL Then
  SetSymbol:=False Else
  Begin
  pList^.iValue:=i;
  pList^.fValid:=fValid;
  SetSymbol:=True;
  End;
End;

{ converts a local macro symbol named s at the position pl to a global one }
Function ConvertLocalToGlobal(s:String;pl:pSList):Boolean;
Var pList:pSList;
Begin
pList:=pList0;
While (pList<>NIL) And (pList<>pl) And (pList^.sName<>Uppercase(s)) Do
  pList:=pList^.pNext;
ConvertLocalToGlobal:=(pList<>NIL) And (pList=pl);
If ConvertLocalToGlobal Then
  Begin
  pl^.fHasGlobal:=True;
  New(pList);
  pList^.cType:='G';
  pList^.sName:=pl^.sName;
  pList^.iValue:=pl^.iValue;
  pList^.nDefined:=pl^.nDefined;
  pList^.fDefInc:=pl^.fDefInc;
  pList^.nUsed:=0;
  pList^.pNext:=pList0;
  pList0:=pList;
  End;
End;

{ returns the value i of the symbol s out of the types listed
  in sTypes, fValid is true if the symbol is defined valid, returns
  false if the symbol is not found }
Function GetSymbolValue(sTypes:String;s:String;Var fValid:Boolean;Var iValue:LongInt):Boolean;
Var pList:PSList;
Begin
pList:=pList0;
While (pList<>NIL) And ((Pos(pList^.cType,sTypes)<1) Or (pList^.sName<>s)) Do pList:=pList^.pNext;
GetSymbolValue:=pList<>NIL;
If GetSymbolValue Then
  Begin
  If fValid Then Inc(pList^.nUsed);
  fValid:=pList^.fValid;
  iValue:=pList^.iValue;
  End;
End;

{ undefines the symbol s by setting fValid false, returns false if not defined yet }
Function UndefSymbol(s:String):Boolean;
Var pList:PSList;
Begin
pList:=pList0;
While (pList<>NIL) And (pList^.sName<>s) Do pList:=pList^.pNext;
UndefSymbol:=pList<>NIL;
If UndefSymbol Then pList^.fValid:=False;
End;

{ clears all nUsed of all symbols }
Procedure ClearAllnUsed;
Var pList:pSList;
Begin
pList:=pList0;
While pList<>NIL Do With pList^ Do
  Begin
  If cType<>'T' Then nUsed:=0;
  pList:=pNext;
  End;
End;

{ returns true if there are symbols defined }
Function FindAnySymbol:Boolean;
Begin
FindAnySymbol:=pList0<>NIL;
End;

{ find the first symbol of the type ct, returns NIL if not found }
Function FindSymbolFirst(ct:Char):pSList;
Begin
FindSymbolFirst:=NIL;
p:=pList0;
While (p<>NIL) And (ct<>p^.cType) Do p:=p^.pNext;
FindSymbolFirst:=p;
End;

{ find the next symbol of the same type, returns NIL if no more symbols }
Function FindSymbolNext:pSList;
Var ct:Char;
Begin
FindSymbolNext:=NIL;
ct:=p^.cType;
p:=p^.pNext;
While (p<>NIL) And (ct<>p^.cType) Do p:=p^.pNext;
FindSymbolNext:=p;
End;

{ find the last symbol on the list }
Function FindSymbolLast:pSList;
Begin
FindSymbolLast:=pList0;
If FindSymbolLast<>NIL Then
  While FindSymbolLast^.pNext<>NIL Do
    FindSymbolLast:=FindSymbolLast^.pNext;
End;

{ check all unused and redefined symbols, returns TRUE if none }
Function CheckAllSymbols(Var nUnused,nVarReDef:LongInt):Boolean;
Var p:pSList;
Begin
nUnused:=0;
nVarReDef:=0;
p:=pList0;
While p<>NIL Do With p^ Do
  Begin
  If (cType<>'T') And ((Not fDefInc) And (nUsed=0)) Then Inc(nUnused);
  If ((cType='V') Or (cType='G')) And (nDefined>1) Then Inc(nVarReDef);
  p:=pNext;
  End;
CheckAllSymbols:=(nUnused=0) And (nVarReDef=0);
End;

{ clears all symbols in memory }
Procedure ClearSymbols;
Var pList,pNxt:PSList;
Begin
pList:=pList0;
While pList<>NIL Do
  Begin
  pNxt:=pList^.pNext;
  Dispose(pList);
  pList:=pNxt;
  End;
End;

Begin
pList0:=NIL;
p:=NIL;
End.
