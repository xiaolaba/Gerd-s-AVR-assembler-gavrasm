{ Unit for processing if-else/elif-endif in gavrasm
  Last changed: 11.07.2019 }
Unit gavrif;

Interface

Var
  nIfLevel:LongInt;
  fIfAsm:Boolean;

Function IfActive:Boolean;
Procedure IfNew(f:Boolean;nl:LongInt);
Function IfElse:Boolean;
Function IfEnd:Boolean;
Function IfClear:Boolean;
Function GetLastLevelLine:LongInt;
Procedure IfDebugAll;

Implementation

Uses SysUtils,Classes;

Type
  pIfDef = ^TIfDef;
  TIfDef = Record
    fVal:Boolean;
    fElse:Boolean;
    nLine:LongInt;
    pPrevIf:pIfDef;
    pNextIf:pIfDef;
    End;

Var
  p,pIfDef0:pIfDef;

Function IfActive:Boolean;
{ Returns true if any IF conditions are active }
begin
IfActive:=pIfDef0<>NIL;
end;

Function GetLastIfDef:Boolean;
{ Steps through all active .IF conditions,
  returns true if any condition is active,
  sets the pointer p to the last condition
  and updates fIfAsm }
Var pp:pIfDef;
Begin
fIfAsm:=True;
nIfLevel:=0;
pp:=pIfDef0;
GetLastIfDef:=False;
While pp<>NIL Do With pp^ Do
  Begin
  p:=pp;
  Inc(nIfLevel);
  If fVal=fElse Then fIfAsm:=False;
  pp:=pNextIf;
  GetLastIfDef:=True;
  End;
End;

Procedure IfNew(f:Boolean;nl:LongInt);
{ Adds a new IF condition, f = current condition,
  nl is the current line, sets fIfAsm true if all
  previous conditions are true and f is true }
Var pp:pIfDef;
Begin
If GetLastIfDef Then
  Begin
  New(p^.pNextIf);
  pp:=p;
  p:=p^.pNextIf;
  Inc(nIfLevel);
  End Else
  Begin
  New(pIfDef0);
  p:=pIfDef0;
  pp:=NIL;
  nIfLevel:=1;
  End;
With p^ Do
  Begin
  fVal:=f;
  fElse:=False;
  nLine:=nl;
  pPrevIf:=pp;
  pNextIf:=NIL;
  End;
fIfAsm:=fIfAsm And f;
End;

Function IfElse:Boolean;
{ Performs an ELSE/ELIF operation, returns
  true if an IF condition is active, updates
  fIfAsm }
Begin
If GetLastIfDef Then With p^ Do
  Begin
  fElse:=Not fElse;
  IfElse:=True;
  End Else
  IfElse:=False;
GetLastIfDef;
End;

Function IfEnd:Boolean;
{ Clears the last IF condition from memory,
  returns true if succesfully removed and
  false if there are no more IF conditions,
  updates fIfAsm }
Var pp:pIfDef;
Begin
If GetLastIfDef Then
  Begin
  pp:=p^.pPrevIf;
  Dispose(p);
  Dec(nIfLevel);
  If pp=NIL Then
    pIfDef0:=NIL Else
    pp^.pNextIf:=NIL;
  IfEnd:=True;
  End Else
  IfEnd:=False;
GetLastIfDef;
End;

Function IfClear:Boolean;
{ Removes all IF conditions from memory and
  returns true if all has been removed }
Begin
If GetLastIfDef Then
  Begin
  Repeat Until Not IfEnd;
  IfClear:=False;
  nIfLevel:=0;
  End Else
  IfClear:=True;
fIfAsm:=True;
End;

Function GetLastLevelLine:LongInt;
{ Returns the line number of the last IF
  condition, returns 0 if no condition
  is active }
Begin
If GetLastIfDef Then
  GetLastLevelLine:=p^.nLine else
  GetLastLevelLine:=0;
End;

Procedure IfDebugAll;
{ For debugging purposes: writes all IF active conditions
  to a text file on my disk }
Var sl:TStringList;
  s:String;
  n:LongInt;
begin
sl:=TStringList.Create;
sl.Clear;
p:=pIfDef0;
nIfLevel:=0;
s:='';
While p<>NIL Do With p^ Do
  begin
  Inc(nIfLevel);
  For n:=1 To nIfLevel Do s:=s+'  ';
  If fVal Then s:=s+'"True"' Else s:=s+'"False"';
  If fElse Then s:=s+' Else="True"' Else s:=s+' Else="False"';
  s:=s+' Line='+IntToStr(nLine);
  sl.Add(s);
  p:=pNextIf;
  end;
sl.Add(IntToStr(nIfLevel)+' if levels');
If fIfAsm Then sl.Add('fIfAsm="True"') Else sl.Add('fIfAsm="False"');
sl.SaveToFile('C:\Users\gerd\Documents\1_dev\Lazarus\avr_sim\if.txt');
sl.Free;
end;

Begin
pIfDef0:=NIL;
p:=NIL;
fIfAsm:=True;
nIfLevel:=0;
End.

