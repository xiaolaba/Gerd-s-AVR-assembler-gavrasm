{ Unit for processing if-else/elif-endif in gavrasm }
Unit gavrif;

Interface

Var
  fIf:Boolean; { Inside If }
  fIfDef:Boolean; { actual result of if definition, inverted }

Procedure IfNew(f,fIna:Boolean);

Function IfElse:Boolean;

Function IfEnd:Boolean;

Function IfClear:Boolean;

Implementation

Uses Crt;

Type
  pIfDef = ^TIfDef;
  TIfDef = Record
    fVal:Boolean;
    fInact:Boolean;
    fElse:Boolean;
    pPrevIf:pIfDef;
    pNextIf:pIfDef;
    End;

Var
  pIfDef0:pIfDef;

Function GetLastIfDef(Var p:pIfDef):Boolean;
Begin
p:=pIfDef0;
If p=NIL Then GetLastIfDef:=False Else
  Begin
  While p^.pNextIf<>NIL Do
    Begin
    p:=p^.pNextIf;
    End;
  GetLastIfDef:=True;
  End;
End;

Procedure IfNew(f,fIna:Boolean);
Var p,pp:pIfDef;
Begin
If GetLastIfDef(p) Then
  Begin
  New(p^.pNextIf);
  pp:=p;
  p:=p^.pNextIf;
  End Else
  Begin
  New(pIfDef0);
  p:=pIfDef0;
  pp:=NIL;
  End;
With p^ Do
  Begin
  fVal:=f;
  fInact:=fIna;
  fElse:=False;
  pPrevIf:=pp;
  pNextIf:=NIL;
  End;
fIf:=True;
If Not fIna Then fIfDef:=f;
End;

Function IfElse:Boolean;
Var p:pIfDef;
Begin
If GetLastIfDef(p) Then
  Begin
  If p^.fElse Then
    IfElse:=False Else
    Begin
    p^.fElse:=True;
    IfElse:=pIfDef0<>NIL;
    If Not p^.fInact Then fIfDef:=Not fIfDef;
    End;
  End Else
  IfElse:=False;
End;

Function IfEnd:Boolean;
Var p,pp:pIfDef;
Begin
If GetLastIfDef(p) Then
  Begin
  pp:=p^.pPrevIf;
  Dispose(p);
  If pp=NIL Then
    Begin
    fIfDef:=False;
    fIf:=False;
    pIfDef0:=NIL;
    End Else
    Begin
    fIfDef:=pp^.fVal;
    If pp^.fElse Then fIfDef:=Not fIfDef;
    pp^.pNextIf:=NIL;
    End;
  IfEnd:=True;
  End Else
  IfEnd:=False;
End;

Function IfClear:Boolean;
Var p:pIfDef;
Begin
If GetLastIfDef(p) Then
  Begin
  Repeat Until Not IfEnd;
  IfClear:=False;
  End Else
  IfClear:=True;
End;

Begin
pIfDef0:=NIL;
fIf:=False;
fIfDef:=False;
End.
