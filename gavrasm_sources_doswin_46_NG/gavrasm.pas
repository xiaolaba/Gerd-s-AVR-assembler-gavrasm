{$R+,S+,I+,Q+}
{ $DEFINE debug}
{
  ********************************************************
  * Gerd's AVR-Assembler Version 4.6 as of December 2019 *
  * Free Pascal, source code, (C)2019 by DG4FAC          *
  * New in Version 4.6: See ReadMe.Txt for version info  *
  ********************************************************
}
Program gavrasm;

Uses Crt,SysUtils,variants,gavrinst,gavrout,
  gavrmacr,gavrsymb,gavrline,gavrlang,gavrif,gavrdev;

Const
  nHeader=3;
  asHeader:Array[1..nHeader] Of String=(
    '+------------------------------------------------------------+',
    '| gavrasm gerd''s AVR assembler Version 4.6 (C)2019 by DG4FAC |',
    '+------------------------------------------------------------+');
  lHeader:String='gavrasm Gerd''s AVR assembler version 4.6 (C)2019 by DG4FAC';
  cTab=Char(9);
  iMaxInt:Int64=$7FFFFFFFFFFFFFFF; { 9,223,372,036,854,775,807 }

Var
    sListFile,sEepFile,sCodeFile,sXErrorFile:String; { Result files }
    fListFileOpen,fFatal:Boolean; { List File is open }
    fQuiet,fSymbols,fList,fListOff,fAnsiOff,fErrLong,fWrapOn,
    fTypesList,fOptionList,fListMac,fBeginner,fListDirectives,
    fInternalOff,fEepromErr,fDate:Boolean; { Command line options }
    fl,fx:Text; { list-file, error-file }
    spFile:String; { Name of currently processed file }
    fExit:Boolean; { Skips further processing of the source file }
    fExitFile:Boolean; { Skips further processing of the file }
    fMacroDef:Boolean; { Inside macro definition }
    npLine:LongInt; { Currently processed line number }
    nerr,nw:LongInt; { Number of errors and s per pass }
    pc,pe,pd:LongInt; { Current PC/EEPROM/SRAM count }
    ncode,nconstants,ne,nd:LongInt; { Number of code/EEPROM/SRAM created }
    cSegm:Char; { Segment target, C/E/D }
    fCSeg,fDSeg,fESeg:Boolean ; { Flag for DSEG already set }
    pass:Byte; { Current pass number }
    k:Byte; { For header output }
    w1,w2:Word; { Command words }
    sListLine2:String; { Second list line }
    nDev:LongInt; { The current device }
    fAvr8L:Boolean; { Device with AVR8L core }
    fCStyle:Boolean; { C-Style instructions, ignored }

Function ProcessFile(sf:String):Boolean; Forward;
Procedure ListAllAvrTypes; Forward;

{ ------------------------- }
{ Read command line options }
{ ------------------------- }
Function GetOptions:Boolean;
Var j,k:LongInt;
  s:String;
Begin
GetOptions:=True;
fList:=False;
fQuiet:=False;
fSymbols:=False;
fTypesList:=False;
fListMac:=False;
fListDirectives:=False;
fErrLong:=False;
fBeginner:=False;
fInternalOff:=False;
fEepromErr:=False;
fDate:=False;
sfn:='test.asm';
For j:=1 To ParamCount Do
  Begin
  s:=ParamStr(j);
  If s[1]='-' Then
    Begin
    For k:=2 To Length(s) Do
      Begin
      Case UpCase(s[k]) Of
        '?','H':fOptionList:=True;
        'A':fAnsiOff:=Not fAnsiOff;
        'B':fBeginner:=True;
        'D':fListDirectives:=True;
        'E':fErrLong:=True;
        'L':fList:=True;
        'M':fListMac:=True;
        'P':fEepromErr:=True;
        'Q':fQuiet:=True;
        'S':fSymbols:=True;
        'T':fTypesList:=True;
        'W':fWrapOn:=True;
        'X':fInternalOff:=True;
        'Z':fDate:=True;
        Else
        Writeln(GetMsgM(1),s[k],'!');
        GetOptions:=False;
        End;
      End;
    End Else
    Begin
    sfn:=s;
    End;
  End;
If fTypesList Or fOptionList Or fListDirectives Then
  Begin
  GetOptions:=False;
  If fTypesList Then ListAllAvrTypes;
  If fListDirectives Then ListDirectives;
  If fOptionList Then
    Begin
    Writeln;
    Writeln('Calls: gavrasm [-ABEJLMQSWXZ] source[.asm]');
    Writeln('       gavrasm [-?DHT]');
    Writeln;
    Writeln('List of options:');
    Writeln('  -L Listfile off            -M Expand macro code');
    Writeln('  -Q Quiet, no screen output -S Symbol list in listfile');
    Writeln('  -B Beginners error comment -A Toggle ANSI output on command line');
    Writeln('  -E Longer error comments   -D List all supported directives');
    Writeln('  -W Enable wrapping         -T List all supported AVR types');
    Writeln('  -X Internal def.inc off    -Z Define current date constants');
    Writeln('  -H -? List options (shows this)');
    Writeln;
    End;
  End Else
  Begin
  If ExtractFileExt(sfn)='' Then sfn:=sfn+'.asm';
  If FileExists(sfn) Then
    Begin
    sListFile:=ChangeFileExt(sfn,'.lst');
    sEepFile:=ChangeFileExt(sfn,'.eep');
    sCodeFile:=ChangeFileExt(sfn,'.hex');
    sXErrorFile:=ChangeFileExt(sfn,'.err');
    End Else
    Begin
    GetOptions:=False;
    Writeln(GetMsgM(2),sfn,'!');
    End;
  End;
fListOff:=fList;
End;

{ ----------------------------- }
{ Get date and time for listing }
{ ----------------------------- }

Function GetDateAndTime:String;
Begin
GetDateAndTime:=FormatDateTime('dd.mm.yyyy", "hh:nn:ss',Now);
End;

{ --------------------------- }
{ Process errors and warnings }
{ --------------------------- }

Procedure Dbg(s:String); { Internal compiler errors }
Begin
fFatal:=True;
Inc(nerr);
Writeln;
Writeln(GetMsgM(59));
Writeln(GetMsgM(6),cl.sLine);
Writeln(' ==> ',s);
Writeln;
If Not fListOff Then
  Begin
  Writeln(fl);
  Writeln(fl,GetMsgM(59));
  Writeln(fl,GetMsgM(6),cl.sLine);
  Writeln(fl,' ==> ',s);
  End;
End;

Procedure BeginnersError; { list syntax for the instructions }
Begin
If Not fListOff Then
  Begin
  Write(fl,'      Syntax: ');
  If cl.nDirective<>0 Then
    Begin
    If cl.nDirective>0 Then Writeln(fl,GetMsgM(Byte(61+cl.nDirective))) Else
      Writeln(fl,GetMsgM(60));
    End Else
    If Inst.sM<>'' Then
    Begin
    If Inst.c1=' ' Then
      Writeln(fl,Inst.sM,GetMsgM(40)) Else
      Begin
      If Inst.c2=' ' Then
        Begin
        Writeln(fl,Inst.sM,' ',GetMsgM(58));
        Write(fl,'      ',GetMsgM(58),': ');
        Case Inst.c1 Of
          'R':Writeln(fl,GetMsgM(41));
          'B':Writeln(fl,GetMsgM(42));
          '1':Writeln(fl,GetMsgM(43));
          'X':Writeln(fl,GetMsgM(44));
          'E':Writeln(fl,GetMsgM(45));
          '2':Writeln(fl,GetMsgM(46));
          'H':Writeln(fl,GetMsgM(47));
          'N':Writeln(fl,GetMsgM(92));
          Else
          Dbg('Illegal c1 ('+Inst.c1+') in single parameter instruction!');
          End;
        End Else
        Begin
        Writeln(fl,Inst.sM,' ',GetMsgM(58),'1,',GetMsgM(58),'2');
        Write(fl,'      ',GetMsgM(58),' 1: ');
        Case Inst.c1 Of
          'R':Writeln(fl,GetMsgM(41));
          'D':Writeln(fl,GetMsgM(48));
          'H':Writeln(fl,GetMsgM(47));
          'B':Writeln(fl,GetMsgM(42));
          'Q':Writeln(fl,GetMsgM(49));
          'J':Writeln(fl,GetMsgM(50));
          'K':Writeln(fl,GetMsgM(51));
          'P':Writeln(fl,GetMsgM(52));
          'S':Writeln(fl,GetMsgM(53));
          'T':Writeln(fl,GetMsgM(54));
          'W':Writeln(fl,GetMsgM(55));
          'Z':Writeln(fl,GetMsgM(93));
          Else
          Dbg('Illegal c1 ('+Inst.c1+') in double parameter instruction!');
          End;
        Write(fl,'      ',GetMsgM(58),' 2: ');
        Case Inst.c2 Of
          'R':Writeln(fl,GetMsgM(41));
          '6':Writeln(fl,GetMsgM(56));
          '8':Writeln(fl,GetMsgM(57));
          'B':Writeln(fl,GetMsgM(42));
          '1':Writeln(fl,GetMsgM(43));
          'I':Writeln(fl,GetMsgM(57));
          'J':Writeln(fl,GetMsgM(50));
          'P':Writeln(fl,GetMsgM(52));
          'L':Writeln(fl,GetMsgM(53));
          'M':Writeln(fl,GetMsgM(54));
          'N':Writeln(fl,GetMsgM(92));
          'W':Writeln(fl,GetMsgM(55));
          'H':Writeln(fl,GetMsgM(47));
          'K':Writeln(fl,GetMsgM(51));
          Else
          Dbg('Illegal c2 ('+Inst.c2+') in double parameter instruction!');
          End;
        End;
      End;
    End;
  End;
End;

Procedure Error(ne:Byte;s1,s2:WideString); { Process error messages }
Begin
If ne>nMaxErr Then Dbg('Illegal error message ('+IntToStr(ne)+')!');
Inc(nerr);
If Not fQuiet Then
  Begin
  If fErrLong Then
    Begin
    Writeln(GetMsgM(3),GetMsgE(ne,s1,s2));
    Writeln('  ',GetMsgM(4),spFile,', ',GetMsgM(5),npLine);
    Writeln('  ',GetMsgM(6),cl.sLine);
    If Not fAnsiOff Then Writeln;
    End Else
    Begin
    Writeln(GetMsgM(3),'==> ',cl.sLine);
    Writeln('[',spFile,',',npLine,'] ',GetMsgE(ne,s1,s2));
    If Not fAnsiOff Then Writeln;
    End;
  End;
If Not fListOff Then
  Begin
  If fErrLong Then
    Begin
    Writeln(fl,' ===> ',GetMsgM(3),GetMsgE(ne,s1,s2));
    Writeln(fl,'      ',GetMsgM(5),cl.sLine);
    Writeln(fl,'      ',GetMsgM(4),spFile,', ',GetMsgM(5),npLine);
    If fBeginner Then BeginnersError;
    End Else
    Begin
    Writeln(fl,GetMsgM(3),'==> ',cl.sLine);
    Writeln(fl,'[',spFile,',',npLine,'] ',GetMsgE(ne,s1,s2));
    End;
  End;
If fErrLong Then
  Begin
  Writeln(fx,' ===> ',GetMsgM(3),GetMsgE(ne,s1,s2));
  Writeln(fx,'      ',GetMsgM(5),cl.sLine);
  Writeln(fx,'      ',GetMsgM(4),spFile,', ',GetMsgM(5),npLine);
  End Else
  Begin
  Writeln(fx,GetMsgM(3),'==> ',cl.sLine);
  Writeln(fx,'[',spFile,',',npLine,'] ',GetMsgE(ne,s1,s2));
  End;
End;

Procedure Warning(f:Boolean;nws:Byte;s1,s2:WideString); { List warnings }
Begin
Inc(nw);
If Not fQuiet Then
  Begin
  Writeln(GetMsgM(7),GetMsgW(nws,s1,s2));
  If f Then
    Begin
    Writeln('  ',GetMsgM(4),spFile,', ',GetMsgM(5),npLine);
    Writeln('  ',GetMsgM(6),cl.sLine);
    End;
  Writeln;
  End;
If Not fListOff Then
  Begin
  Writeln(fl,' -> ',GetMsgM(7),GetMsgW(nws,s1,s2));
  If f Then
    Begin
    Writeln(fl,'   ',GetMsgM(4),spFile,', ',GetMsgM(5),npLine);
    Writeln(fl,'   ',GetMsgM(6),cl.sLine);
    End;
  End;
End;

Procedure Message(s:WideString); { Display a message }
Begin
Writeln('  ==> Message: ',s);
If Not fListOff Then
  Begin
  Writeln(fl,' -> Message: ',s);
  Writeln(fl,'   ',GetMsgM(4),spFile,', ',GetMsgM(5),npLine);
  End;
End;

{ ---------------- }
{ Listing routines }
{ ---------------- }

Function LongInt2HexN(nb:Byte;i:LongInt):String;
Var j,n:LongInt;
  b:Byte;
Begin
LongInt2HexN:='';
j:=1;
For n:=1 To nb-1 Do j:=16*j;
While j>0 Do
  begin
  b:=i Div j;
  If b>9 Then
    LongInt2HexN:=LongInt2HexN+Char(b+55) else
    LongInt2HexN:=LongInt2HexN+Char(b+48);
  i:=i-b*j;
  j:=j Div 16;
  end;
End;

Function Byte2Hex(b:Byte):String;
Var bn:Byte;
Begin
Byte2Hex:='';
bn:=b Div 16;
If bn>9 Then Byte2Hex:=Char(bn+55) Else Byte2Hex:=Char(bn+48);
bn:=b And $0F;
If bn>9 Then Byte2Hex:=Byte2Hex+Char(bn+55) Else Byte2Hex:=Byte2Hex+Char(bn+48);
End;

Function Int64ToHex(i:Int64):String;
Var j:Int64;
  b:Byte;
  f:Boolean;
Begin
j:=$100000000000000;
If i=0 Then Int64ToHex:='               00' else
  begin
  If i<0 Then
    i:=$1000000000000000+i;
  Int64ToHex:=' ';
  f:=True;
  While j>0 Do
    begin
    b:=i Div j;
    If b>0 Then
      begin
      Int64ToHex:=Int64ToHex+Byte2Hex(b);
      f:=False;
      end else
      begin
      If f Then
        Int64ToHex:=Int64ToHex+'  ' else
        Int64ToHex:=Int64ToHex+'00';
      end;
    i:=i-b*j;
    j:=j Div $100;
    end;
  end;
If Copy(Int64ToHex,1,3)=' 7F' Then
  Int64ToHex:=' FF'+Copy(Int64ToHex,4,1000);
End;

Procedure ListSymbols;
Const sListTypes='TLEDRCV';
Var k:LongInt;
  p:pSList;
Begin
Writeln(fl);
If FindAnySymbol Then
  Begin
  Writeln(fl,GetMsgM(8));
  Writeln(fl,GetMsgM(9));
  For k:=1 To Length(sListTypes) Do
    Begin
    p:=FindSymbolFirst(sListTypes[k]);
    While p<>NIL Do With p^ Do
      begin
      If Not fDefInc Then
        Writeln(fl,'  ',cType,nDefined:6,nUsed:6,iValue:23,Int64ToHex(iValue),' ',sName);
      p:=FindSymbolNext;
      end;
    End;
  End Else
  Writeln(fl,GetMsgM(10));
End;

{$IFDEF debug}

Procedure DisplaySymbols;
Const sListTypes='TLEDRCV';
Var k:Byte;
  p:pSList;
Begin
Writeln;
If FindAnySymbol Then
  Begin
  Writeln(GetMsgM(8));
  Writeln(GetMsgM(9));
  For k:=1 To Length(sListTypes) Do
    Begin
    p:=FindSymbolFirst(sListTypes[k]);
    While p<>NIL Do With p^ Do
      Begin
      If Not fDefInc Then
        Writeln('  ',cType,nDefined:6,nUsed:6,iValue:11,LongInt2HexN(nUsed, iValue),' ',sName);
      p:=FindSymbolNext;
      End
    End;
  End Else
  Writeln(GetMsgM(10));
Writeln;
End;

{$ENDIF}

Function IntToWideStr(i:LongInt):WideString;
Var s:String;
begin
s:=IntToStr(i);
IntToWideStr:=WideString(s);
end;

Procedure CheckSymbols;
Var nUnused,nVarReDef:LongInt;
Begin
If Not CheckAllSymbols(nUnused,nVarReDef) Then
  Begin
  If nUnUsed>0 Then
    Warning(False,1,IntToWideStr(nUnused),'');
  If nVarReDef>0 Then
    Warning(False,2,'','');
  End;
End;

Function ListGetLine:String;
Var s:String;
Begin
Str(npLine:6,s);
ListGetLine:=s+': ';
End;

Procedure ListOutLine;
Begin
If Not fListOff Then
  Writeln(fl,ListGetLine,cl.sLine);
End;

Function ListGetAddressLongInt:LongInt;
Begin
Case cSegm Of
  'C':ListGetAddressLongInt:=pc;
  'E':ListGetAddressLongInt:=pe;
  'D':ListGetAddressLongInt:=pd;
  End;
End;

Function ListGetLineAndAddress:String;
Var i:LongInt;
Begin
i:=ListGetAddressLongInt;
ListGetLineAndAddress:=ListGetLine+LongInt2HexN(6,i)+' ';
End;

Function ListGetAddressAlone:String;
Var i:LongInt;
Begin
i:=ListGetAddressLongInt;
ListGetAddressAlone:='        '+LongInt2HexN(6,i)+' ';
End;

Procedure ListOutCommand;
Begin
If Not fListOff Then
  Begin
  If fMacroDef Or (Not fIfAsm) Then
    Writeln(fl,ListGetLine+Copy(cl.sLine,cl.pInst,255)) Else
    Begin
    Writeln(fl,ListGetLineAndAddress,'  ',LongInt2HexN(4,w1),'  ',Copy(cl.sLine,cl.pInst,255));
    If Inst.nW=2 Then
      Writeln(fl,'        ',Longint2HexN(6,ListGetAddressLongInt+1),'   ',LongInt2HexN(4,w2));
    End;
  End;
End;

Procedure ListMacros;
Var se:String;
Begin
If ResetMacroPointer Then
  Begin
  Writeln(fl);
  Writeln(fl,GetMsgM(11));
  Writeln(fl,GetMsgM(12));
  While EnumMacroList(se) Do Writeln(fl,se);
  End Else
  Writeln(fl,GetMsgM(13));
End;

Function ToBinary(iSet:DWord):String;
Var i:DWord;
  k:LongInt;
begin
ToBinary:='';
i:=1<<23;
k:=1;
Repeat
  If (k>1) And ((k Mod 4)=1) Then ToBinary:=ToBinary+'.';
  If iSet>=i Then
    begin
    ToBinary:=ToBinary+'1';
    iSet:=iSet-i;
    end Else
    ToBinary:=ToBinary+'0';
  i:=i Div 2;
  Inc(k);
  Until k=25;
end;


Procedure ListAllAvrTypes;
Var k,l:LongInt;
  c:Char;
Begin
c:=' ';
If c=' ' Then For k:=1 To nDevices Do With aDevices[k] Do
  Begin
  If (k Mod 21)=1 Then
    Begin
    If k>1 Then
      Begin
      Write('  any key to continue ... ');
      Repeat Until Keypressed;
      c:=ReadKey;
      End;
    Writeln;
    Writeln('List of supported AVR types and their properties, page ',(k Div 21)+1);
    Writeln('  # Type             Flash   SRAM Start EEPROM Instructions');
    Writeln('                     Bytes  Bytes Adrs.  Bytes (Instruction set flags)');
    End;
  Write(k:3,' ',sn);
  For l:=Length(sn)+1 To 15 Do Write(' ');
  Writeln(nf:7,ns:7,nss:6,ne:7,' ',ToBinary(iSet));
  End;
End;

{ -------------------- }
{ Evaluate expressions }
{ -------------------- }
Function CheckSymbolLegal(s:String):Boolean;
Var k:Byte;
  Inst:TInstruction;
Begin
CheckSymbolLegal:=True;
With Inst Do If ((s[1]>='A') And (s[1]<='Z')) Or (s[1]='_') Then
  Begin
  For k:=2 To Length(s) Do
    Case s[k] Of
      'A'..'Z':;
      '0'..'9':;
      '_':;
      Else
      Error(1,WideString(s[k]),'');
      CheckSymbolLegal:=False;
      End;
  sM:=s;
  If FindInstructionFromMnemonic(Inst) And (Inst.sM<>'OR') And (Inst.sM<>'BRTS') Then
    Begin
    Error(2,WideString(s),'');
    CheckSymbolLegal:=False;
    End;
  End Else
  Begin
  Error(3,WideString(s),'');
  CheckSymbolLegal:=False;
  End;
End;

Function SnipOff(Var s:String):Boolean;
Begin
While (s<>'') And ((s[1]=' ') Or (s[1]=cTab)) Do Delete(s,1,1);
While (s<>'') And ((s[Length(s)]=' ') Or (s[Length(s)]=cTab)) Do Delete(s,Length(s),1);
SnipOff:=s<>'';
End;

Procedure ExchangeDouble(Var s:String;sr:String;ce:Char);
Var p:LongInt;
Begin
p:=Pos(sr,s);
Delete(s,p,2);
Insert(ce,s,p);
End;

Procedure RemoveDoubleAddSub(Var s:String);
Begin
While Pos('--',s)>0 Do ExchangeDouble(s,'--','+');
While Pos('++',s)>0 Do ExchangeDouble(s,'++','+');
While Pos('-+',s)>0 Do ExchangeDouble(s,'-+','-');
While Pos('+-',s)>0 Do ExchangeDouble(s,'+-','-');
End;

Function GetInnerBracket(s:String;Var pka,pke:Int64):Boolean;
Var k,nke,mke:Byte;
  f,fl:Boolean;
Begin
f:=True;
fl:=True;
pka:=0;
pke:=0;
nke:=0;
mke:=0;
For k:=1 To Length(s) Do
  Begin
  If s[k]='''' Then fl:=Not fl;
  If fl And f And (s[k]='(') Then
    Begin
    Inc(nke);
    If nke>=mke Then
      Begin
      mke:=nke;
      pka:=k;
      End;
    End;
  If fl And f And (s[k]=')') Then
    Begin
    If nke=mke Then pke:=k;
    If nke=0 Then
      begin
      Error(15,'','');
      mke:=0;
      f:=False;
      end else
      begin
      Dec(nke);
      If nke=0 Then f:=False;
      end;
    End;
  End;
If (pka>0) And (pke=0) Then
  begin
  Error(16,'','');
  GetInnerbracket:=False;
  end else
  GetInnerBracket:=mke>0;
End;

Function CheckChar(c:Char):Boolean;
Begin
Case c Of
  '!','~','*','/','+','-','<','>','=','&','^','|','(',')':CheckChar:=False;
  Else
  CheckChar:=True;
  End;
End;

Function GetBinaryValue(s:String;Var i:Int64):Boolean;
Var k:Byte;
Begin
GetBinaryValue:=True;
i:=0;
k:=0;
While GetBinaryValue And (k<Length(s)) Do
  Begin
  Inc(k);
  Case s[k] Of
    '0':i:=i+i;
    '1':i:=i+i+1;
    '.','_':;
    Else
    GetBinaryValue:=False;
    End;
  End;
If Not GetBinaryValue Then
  Error(4,WideString(s[k]),'');
End;

Function GetHexValue(s:String;Var i:Int64):Boolean;
Var k:Byte;
Begin
GetHexValue:=True;
i:=0;
k:=0;
While GetHexValue And (k<Length(s)) Do
  Begin
  Inc(k);
  Case s[k] Of
    '0'..'9':i:=i*16+Byte(s[k])-48;
    'A'..'F':i:=i*16+Byte(s[k])-55;
    '.':;
    Else
    GetHexValue:=False;
    End;
  End;
If Not GetHexValue Then
  Error(5,WideString(s[k]),'');
End;

Function GetDecimalValue(s:String;Var i:Int64):Boolean;
Var p:Byte;
Begin
GetDecimalValue:=True;
i:=0;
For p:=1 To Length(s) Do
  Case s[p] Of
    '0'..'9':i:=i*10+(Byte(s[p])-48);
    Else
    GetDecimalValue:=False;
    End;
If Not GetDecimalValue Then
  Error(6,WideString(s),'');
End;

Function GetLiteralValue(s:String;Var i:Int64):Boolean;
Begin
GetLiteralValue:=(Length(s)=3) And (s[3]=s[1]);
If GetLiteralValue Then i:=Byte(s[2]);
End;

Function GetPCvalue(s:String;Var i:Int64):Boolean;
Begin
If UpperCase(s)='PC' Then
  Begin
  i:=pc+Inst.nw-1;
  GetPCvalue:=True;
  End Else
  GetPCvalue:=False;
End;

Function GetSingleValue(s:String;Var fValid:Boolean;Var i:Int64):Boolean;
Var p:Byte;
  fs:Boolean;
  sLbl:String;
Begin
If s='' Then
  begin
  fValid:=False;
  GetSingleValue:=False;
  Error(7,'','');
  end else
  begin
  If s='-0' Then s:='0';
  p:=1;
  If s[p]='-' Then
    Begin
    fs:=True;
    Inc(p);
    End Else
    fs:=False;
  GetSingleValue:=False;
  Case s[p] Of
    'A'..'Z','_':
      Begin
      GetSingleValue:=GetPCvalue(Copy(s,p,255),i);
      If Not GetSingleValue Then
        Begin
        GetSingleValue:=GetSymbolValue('CVLRP',Copy(s,p,255),fValid,i);
        If pass=1 Then GetSingleValue:=True Else
          begin
          If Not GetSingleValue Then
            begin
            If pcm<>NIL Then
              Begin
              sLbl:=Copy(s,p,255)+'@'+pcm^.sMacName+'@'+IntToStr(pcm^.nMacUse);
              fValid:=True;
              GetSingleValue:=GetSymbolValue('L',sLbl,fValid,i);
              If Not GetSingleValue Then
                Error(7,WideString(s),'');
              end else
              begin
              fValid:=False;
              Error(7,WideString(s),'');
              end;
            End;
          end;
        End;
      End;
    '0': If Length(s)>2 Then
      Begin
      Case s[p+1] Of
        'B':GetSingleValue:=GetBinaryValue(Copy(s,p+2,255),i);
        'X':GetSingleValue:=GetHexValue(Copy(s,p+2,255),i);
        Else
        GetSingleValue:=GetDecimalValue(Copy(s,p,255),i);
        End;
      End Else
      Begin
      If s='0' Then
        Begin
        i:=0;
        GetSingleValue:=True;
        End Else
        begin
        Error(25,WideString(s),'');
        i:=0;
        GetSingleValue:=False;
        end;
      End;
    '1'..'9':GetSingleValue:=GetDecimalValue(Copy(s,p,255),i);
    '$':GetSingleValue:=GetHexValue(Copy(s,p+1,255),i);
    '"','''':GetSingleValue:=GetLiteralValue(s,i);
    End;
  If Not GetSingleValue Then
    fValid:=False Else
    Begin
    If fs Then i:=-i;
    End;
  end;
End;

Function GetExpressionRight(s:String;Var p:LongInt;Var fValid:Boolean;Var i:Int64):Boolean;
Var sh:String;
Begin
GetExpressionRight:=False;
i:=0;
sh:='';
Inc(p);
If (p<Length(s)) And (s[p]='-') Then
  Begin
  sh:='-';
  Inc(p);
  End;
While (p<=Length(s)) And CheckChar(s[p]) Do
  Begin
  sh:=sh+s[p];
  Inc(p);
  End;
If sh<>'' Then
  GetExpressionRight:=GetSingleValue(sh,fValid,i);
End;

Function GetExpressionLeft(s:String;Var p:LongInt; Var fValid:Boolean;Var i:Int64;fChkSigned:Boolean):Boolean;
Var sh:String;
Begin
GetExpressionLeft:=False;
i:=0;
sh:='';
Dec(p);
While (p>0) And CheckChar(s[p]) Do
  Begin
  sh:=s[p]+sh;
  Dec(p);
  End;
If sh='' Then
  GetExpressionLeft:=True Else
  GetExpressionLeft:=GetSingleValue(sh,fValid,i);
If (p>0) And fChkSigned And (s[p]='-') Then
  Begin
  Dec(p);
  i:=-i;
  End;
End;

Function GetLogicOp(s:String;Var p,bType:LongInt):Boolean;
Const
  sas:Array[1..9] Of String = ('&&','||','!=','==','>=','<=','<>','>','<');
Begin
bType:=0;
Repeat Inc(bType) Until (bType>9) Or ((Pos(sas[bType],s)>0) And ((bType<8) Or
  (s[Pos(sas[bType],s)+1]<>sas[bType])));
GetLogicOp:=bType<=9;
If GetLogicOp Then p:=Pos(sas[bType],s);
End;

Function GetBitOp(s:String;Var p,bType:LongInt):Boolean;
Const
  sas:Array[1..5] Of String = ('<<','>>','&','^','|');
Begin
bType:=0;
Repeat Inc(bType) Until (bType>5) Or (Pos(sas[bType],s)>0);
GetBitOp:=bType<=5;
If GetBitOp Then p:=Pos(sas[bType],s);
End;

Function GetCalcOp(s:String;Var p,bType:LongInt):Boolean;
Var p1,p2,p3:LongInt;
Begin
GetCalcOp:=False;
p1:=Pos('*',s);
p2:=Pos('/',s);
p3:=Pos('%',s);
If (p1<>0) Or (p2<>0) Or (p3<>0) Then { * or / or % }
  Begin
  p:=p2;
  bType:=1;
  If (p2=0) Or ((p1>0) And (p1<p2)) Then
    Begin
    bType:=2;
    p:=p1;
    If p3>0 Then
      begin
      bType:=5;
      p:=p3;
      end;
    End;
  GetCalcOp:=True;
  End Else
  Begin { + or - }
  p1:=Pos('+',s);
  p2:=Pos('-',s);
  If p2=1 Then
    Begin
    p2:=Pos('-',Copy(s,2,255));
    If p2>0 Then p2:=p2+1;
    End;
  If (p1>0) Or (p2>0) Then
    Begin
    p:=p2;
    bType:=3;
    If (p2=0) Or ((p1>0) And (p1<p2)) Then
      Begin
      bType:=4;
      p:=p1;
      End;
    GetCalcOp:=True;
    End;
  End;
End;

Function GetValue(s:String;Var fValid:Boolean;Var i:Int64):Boolean;
Var bType,pa,p,pe:LongInt;
  i1,i2,ix:Int64;
  b:Byte;
Begin
GetValue:=True;
p:=Pos('!',s);
If (p>=Length(s)) Or ((p>1) And (s[p-1]='''') And (s[p+1]='''')) Then p:=0;
While GetValue And (p>0) And (Length(s)>1) And (s[p+1]<>'=') Do
  Begin
  pe:=p;
  GetValue:=GetExpressionRight(Copy(s,p,255),pe,fValid,i);
  If GetValue Then
    Begin
    If i=0 Then i:=1 Else i:=0;
    Delete(s,p,pe-p);
    Insert(IntToStr(i),s,p);
    p:=Pos('!',s);
    End;
  End;
While GetValue And (Pos('''',s)>0) Do
  Begin
  p:=Pos('''',s);
  pe:=p;
  Repeat Inc(pe) Until (pe>Length(s)) Or (s[pe]='''');
  GetValue:= pe <= Length(s);
  If GetValue Then
    Begin
    Case (pe-p) Of
      1: If ((pe+2)<=Length(s)) And (s[pe+1]='''') And (s[pe+2]='''') Then
          Begin
          b:=Byte('''');
          pe:=pe+2;
          End Else
          GetValue:=False;
      2: b:=Byte(s[p+1]);
      3: If s[p+1]='\' Then b:=Byte(s[p+2]) Mod $20 Else GetValue:=False;
      Else
      GetValue:=False;
      End;
    If GetValue Then
      Begin
      Delete(s,p,pe-p+1);
      Insert(IntToStr(b),s,p);
      End;
    End;
  End;
While GetValue And GetLogicOp(s,p,bType) Do
  Begin
  pa:=p;
  If bType<8 Then pe:=p+1 Else pe:=p;
  GetValue:=GetExpressionLeft(s,pa,fValid,i1,False) And GetExpressionRight(s,pe,fValid,i2);
  If GetValue Then
    Begin
    i:=0;
    Case bType Of
      1:If (i1<>0) And (i2<>0) Then i:=1; {&&}
      2:If (i1<>0) Or (i2<>0) Then i:=1; {||}
      3:If ((i1<>0) And (i2=0)) Or ((i1=0) And (i2<>0)) Then i:=1; {!=}
      4:If i1=i2 Then i:=1; {==}
      5:If i1>=i2 Then i:=1; {>=}
      6:If i1<=i2 Then i:=1; {<=}
      7:If i1<>i2 Then i:=1; {<>}
      8:If i1>i2 Then i:=1; {>}
      9:If i1<i2 Then i:=1; {<}
      End;
    Delete(s,pa+1,pe-pa-1);
    Insert(IntToStr(i),s,pa+1);
    End;
  End;
If GetValue And (Pos('=',s)>0) Then
  Begin
  GetValue:=False;
  Error(8,'','');
  End;
p:=Pos('~',s);
While GetValue And (p>0) And (Length(s)>1) Do
  Begin
  pe:=p;
  GetValue:=GetExpressionRight(Copy(s,p,255),pe,fValid,i);
  If GetValue Then
    Begin
    i:=Not i;
    Delete(s,p,pe-p);
    Insert(IntToStr(i),s,p);
    p:=Pos('~',s);
    End;
  End;
While GetValue And GetBitOp(s,p,bType) Do
  Begin
  pa:=p;
  pe:=p;
  If bType<3 Then pe:=p+1;
  GetValue:=GetExpressionLeft(s,pa,fValid,i1,False) And GetExpressionRight(s,pe,fValid,i2);
  If GetValue Then
    Begin
    i:=0;
    Case bType Of
      1:begin  {<<}
        i:=i1;
        ix:=0;
        While ix<i2 Do
          begin
          If i>=(iMaxInt Div 2) Then
            begin
            Error(9,WideString(s),WideString(IntToStr(i2)));
            ix:=i2;
            end else
            begin
            i:=i+i;
            Inc(ix);
            end;
          end;
        end;
      2:begin  {>>}
        i:=i1;
        For ix:=1 To i2 Do i:=i Div 2;
        end;
      3:i:=i1 AND i2; {&}
      4:i:=i1 XOR i2; {^}
      5:i:=i1 OR i2; {|}
      End;
    Delete(s,pa+1,pe-pa-1);
    Insert(IntToStr(i),s,pa+1);
    End;
  End;
While GetValue And GetCalcOp(s,p,bType) Do
  Begin
  pa:=p;
  pe:=p;
  GetValue:=GetExpressionLeft(s,pa,fValid,i1,(bType>2) And (bType<5)) And
    GetExpressionRight(s,pe,fValid,i2);
  If Getvalue Then
    Begin
    i:=0;
    Case bType Of
      1:If i2=0 Then
          Begin
          If pass=2 Then Error(101,'','') Else i:=0;
          End Else
          i:=i1 Div i2; {/}
      2:If (Extended(i1)*Extended(i2))<Extended(iMaxInt) Then {*}
          i:=i1*i2 Else
          Error(10,IntToWideStr(i1),IntToWideStr(i2));
      3:If (Extended(i1)-Extended(i2))>-Extended(iMaxInt) Then {-}
          i:=i1-i2 Else
          Error(12,IntToWideStr(i1),IntToWideStr(i2));
      4:If Extended(i1)+Extended(i2)<Extended(iMaxInt) Then {+}
          i:=i1+i2 Else
          Error(11,IntToWideStr(i1),IntToWideStr(i2));
      5:If (i2<=0) And (pass=2) Then Error(101,'','') else
          i:=i1 Mod i2;
      Else
      Dbg('Illegal bType '+IntToStr(bType)+' in GetValue!');
      End;
    Delete(s,pa+1,pe-pa-1);
    Insert(IntToStr(i),s,pa+1);
    RemoveDoubleAddSub(s);
    End;
  End;
If GetValue Then GetValue:=GetSingleValue(s,fValid,i);
End;

Function GetFunction(s:String;Var pka,i:Int64):Boolean;
Const
  nas=15;
  sas:Array[1..nas] Of String = ('LOW','HIGH','BYTE1','BYTE2','BYTE3','BYTE4',
    'BYTE5','BYTE6','BYTE7','BYTE8','LWRD','HWRD','PAGE','EXP2','LOG2');
Var k,p:Byte;
  sh:String;
Begin
GetFunction:=True;
If pka>3 Then
  Begin
  p:=Byte(pka-1);
  sh:='';
  While (p>0) And (CheckChar(s[p])) Do
    Begin
    sh:=s[p]+sh;
    Dec(p)
    End;
  If sh<>'' Then
    Begin
    k:=0;
    Repeat Inc(k) Until (k>nas) Or (sh=sas[k]);
    If k<=nas Then
      Begin
      If i<0 Then i:=$7FFFFFFFFFFFFFFF+i+1;
      Case k Of
        1,3:i:=i MOD $100;  { LOW, BYTE1 }
        2,4:i:=(i DIV $100) MOD $100; { HIGH, BYTE2 }
        5:i:=(i DIV $10000) MOD $100; { BYTE3 }
        6:i:=(i DIV $1000000) MOD $100; { BYTE4 }
        7:i:=(i DIV $100000000) MOD $100; { BYTE5 }
        8:i:=(i DIV $10000000000) MOD $100; { BYTE6 }
        9:i:=(i DIV $1000000000000) MOD $100; { BYTE7 }
        10:i:=(i DIV $100000000000000) MOD $100; { BYTE8 }
        11:i:=i MOD $10000; { LWRD }
        12:i:=(i DIV $10000) MOD $10000; { HWRD }
        13:i:=(i DIV $10000) MOD 64; { PAGE }
        14:i:=2 SHL (i-1); { EXP2 }
        15:i:=LongInt(TRUNC(LN(i)/LN(2.0))); { LOG2 }
        End;
      pka:=p+1;
      End Else
      Begin
      GetFunction:=False;
      Error(13,WideString(Copy(s,p+1,pka-p)),'');
      End;
    End;
  End;
End;

Function RemoveBlankTab(Var s:String):Boolean;
Var p:Byte;
Begin
While Pos(''' ''',s)>0 Do
  Begin
  p:=Byte(Pos(''' ''',s));
  Delete(s,p,3);
  Insert('32',s,p);
  End;
While Pos(' ',s)>0 Do Delete(s,Pos(' ',s),1);
While Pos(cTab,s)>0 Do Delete(s,Pos(cTab,s),1);
RemoveBlankTab:=s<>'';
End;

Function GetExpression(s:String;Var fValid:Boolean;Var i:Int64):Boolean;
Var pka,pke:Int64;
Begin
fValid:=True;
GetExpression:=True;
RemoveBlankTab(s);
RemoveDoubleAddSub(s);
While GetExpression And GetInnerBracket(s,pka,pke) Do
  Begin
  GetExpression:=GetValue(Copy(s,pka+1,pke-pka-1),fValid,i);
  If GetExpression Then
    Begin
    GetExpression:=GetFunction(s,pka,i);
    If GetExpression Then
      Begin
      Delete(s,pka,pke-pka+1);
      Insert(IntToStr(i),s,pka);
      RemoveDoubleAddSub(s);
      End;
    End;
  End;
GetExpression:=GetExpression And GetValue(s,fValid,i);
End;

Function CheckExpression(s:String):Boolean;
Var k:Byte;
  nk:LongInt;
Begin
CheckExpression:=True;
nk:=0;
If s[1]='''' Then
  Begin
  Case Length(s) Of
    3:If s[3]<>'''' Then
      Begin
      Error(14,Widestring(s[3]),'');
      CheckExpression:=False;
      End;
    4:If (s[2]='\') Or (s[2]='''') Then
        Begin
        If s[4]<>'''' Then
          Begin
          Error(14,Widestring(s[4]),'');
          CheckExpression:=False;
          End;
        End Else
        Begin
        Error(14,WideString(s[2]),'');
	      CheckExpression:=False;
        End;
    Else
    Error(14,WideString(s),'');
    End;
  End Else
  Begin
  For k:=1 To Length(s) Do
    Case s[k] Of
      '(':If nk>=0 Then Inc(nk);
      ')':Dec(nk);
      'A'..'Z':;
      '0'..'9':;
      ' ',cTab:;
      '!','~','*','/','+','-','<','>','=','&','^','|':;
      '$','"','_','''':;
      Else
      Error(14,WideString(s[k]),'');
      CheckExpression:=False;
      End;
  End;
If nk<>0 Then
  Begin
  CheckExpression:=False;
  If nk<0 Then
    Error(15,'','') Else
    Error(16,'','');
  End;
End;

Function GetConstantLongInt(s:String;Var fValid:Boolean;Var i:Int64):Boolean;
Begin
GetConstantLongInt:=GetExpression(s,fValid,i);
End;

{ ------------------------------------- }
{ Processing parameters of instructions }
{ ------------------------------------- }

Function GetRegisterValue(s:String):LongInt;
Var e:LongInt;
begin
If (Length(s)>1) And (s[1]='R') Then
  Begin
  Val(Copy(s,2,255),GetRegisterValue,e);
  If (e>0) Or (GetRegisterValue<0) Or (GetRegisterValue>31) Then
    begin
    Error(17,WideString(s),'0..31');
    GetRegisterValue:=-1;
    end;
  end else
  Error(19,'','');
end;

Function GetRegister(s:String;Var wr:Word):Boolean;
Var fValid:Boolean;
  i:Int64;
Begin
wr:=0;
i:=0;
GetRegister:=True;
If SnipOff(s) Then
  Begin
  If (Length(s)>3) Or ((Length(s)>1) And (Not (s[2] in ['0'..'9']))) Or
    ((Length(s)>2) And (Not (s[3] in ['0'..'9']))) Then
    begin
    fValid:=True;
    If Not GetSymbolValue('R',s,fValid,i) Then
      begin
      If (pass=1) Then
        begin
        fValid:=True;
        i:=16;
        end else
        begin
        Error(18,'','');
        GetRegister:=False;
        end;
      end;
    s:='R'+IntToStr(i);
    end;
  i:=GetRegisterValue(s);
  If i>=0 Then
    begin
    wr:=i;
    If fAvr8L And (wr<16) Then
      begin
      Error(17,IntToWideStr(i),'16..31');
      GetRegister:=False;
      end;
    end;
  end else
  begin
  Error(19,'','');
  GetRegister:=False;
  end;
End;

Function GetHighRegister(s:String;Var wr:Word):Boolean;
Begin
wr:=0;
GetHighRegister:=GetRegister(s,wr);
If GetHighRegister Then
  Begin
  If wr>=16 Then
    wr:=Word(wr-16) Else
    Begin
    If pass=2 Then
      Begin
      GetHighRegister:=False;
      Error(17,IntToWideStr(wr),'R16..R31');
      End;
    End;
  End;
End;

Function GetDoubleRegister(s:String;Var wr:Word):Boolean;
Var s1,s2:String;
    w1,w2:Word;
Begin
wr:=0;
GetDoubleRegister:=True;
Case s Of
  'X':wr:=26;
  'Y':wr:=28;
  'Z':wr:=30;
  else
  If Pos(':',s)>0 Then
    begin
    s1:=Copy(s,1,Pos(':',s)-1);
    s2:=Copy(s,Pos(':',s)+1,255);
    GetDoubleRegister:=GetRegister(s1,w1) And GetRegister(s2,w2);
    If GetDoubleRegister And (w1=(w2+1)) Then wr:=w2 Else wr:=w1;
    End Else
    GetDoubleRegister:=GetRegister(s,wr);
  end;
If GetDoubleRegister Then
  Begin
  Case wr Of
    24,26,28,30:wr:=Word((wr-24) Div 2);
    Else
    GetDoubleRegister:=False;
    Error(17,IntToWideStr(wr),'R24/26/28/30!');
    End;
  End;
End;

Function GetMovwReg(s:String;Var wr:Word):Boolean;
Var s1,s2:String;
  w1,w2:Word;
Begin
wr:=0;
GetMovwReg:=True;
Case s Of
  'X':wr:=26;
  'Y':wr:=28;
  'Z':wr:=30;
  else
  If Pos(':',s)>0 Then
    begin
    s1:=LeftStr(s,Pos(':',s)-1);
    s2:=Copy(s,Pos(':',s)+1,1000);
    GetMovwReg:=GetRegister(s1,w1) And GetRegister(s2,w2);
    If GetMovwReg And (w1=(w2+1)) Then wr:=w2 Else wr:=w1;
    end else
    GetMovwReg:=GetRegister(s,wr);
  end;
If GetMovwReg Then
  Begin
  If (wr>30) Or Odd(wr) Then
    Begin
    GetMovwReg:=False;
    Error(17,IntToWideStr(wr),GetMsgM(39));
    End Else
    wr:=Word(wr Div 2);
  End;
End;

Function GetMulReg(s:String;Var wr:Word):Boolean;
Begin
wr:=0;
GetMulReg:=GetRegister(s,wr);
If GetMulReg Then
  Begin
  If (wr>=16) And (wr<24) Then wr:=Word(wr-16) Else
    Error(17,IntToWideStr(wr),'R16..R23');
  End;
End;

Function GetPort(s:String;Var wr:Word):Boolean;
Var i:Int64;
  fValid:Boolean;
Begin
wr:=0;
i:=0;
fValid:=True;
GetPort:=GetExpression(s,fValid,i);
If GetPort Then
  Begin
  If (i>=0) And (i<64) Then
    Begin
    wr:=Word(i MOD 64);
    If (pass=2) And (Not fValid) Then
      Begin
      GetPort:=False;
      Error(20,'','');
      End;
    End Else
    Begin
    GetPort:=False;
    Error(21,IntToWideStr(i),'0..63');
    End;
  End;
End;

Function GetLowPort(s:String;Var wr:Word):Boolean;
Begin
wr:=0;
GetLowPort:=GetPort(s,wr);
If GetLowPort And (wr>=32) Then
  Begin
  GetLowPort:=False;
  Error(21,IntToWideStr(wr),'0..31');
  End;
End;

Function GetBit(s:String;Var wr:Word):Boolean;
Var fValid:Boolean;
  i:Int64;
Begin
wr:=0;
i:=0;
fValid:=True;
GetBit:=GetExpression(s,fValid,i) And fValid;
If (Not fValid) And (pass=1) Then
  Begin
  GetBit:=True;
  wr:=0;
  End;
If (pass=2) And GetBit Then
  Begin
  If (i>=0) And (i<8) Then
    wr:=Word(i MOD 8) Else
    Begin
    GetBit:=False;
    Error(22,IntToWideStr(i),'');
    End;
  End;
End;

Function GetConstant(s:String;Var i:Int64;imin,imax:Int64):Boolean;
Var fValid:Boolean;
Begin
fValid:=True;
GetConstant:=GetExpression(s,fValid,i);
If (Not fValid) And (pass=1) Then i:=0;
If GetConstant Then
  Begin
  If (Pass=2) And ((i<imin) Or (i>imax)) Then
    Begin
    GetConstant:=False;
    Error(24,IntToWideStr(i),IntToWideStr(imin)+'...'+IntToWideStr(imax));
    End;
  End Else
  Error(25,WideString(s),'');
End;

Function GetConstantSmall(s:String;Var wr:Word):Boolean;
Var i:Int64;
Begin
wr:=0;
GetConstantSmall:=GetConstant(s,i,0,63);
If GetConstantSmall Then wr:=Word(i);
End;

Function GetConstantNibble(s:String; Var wr:Word):Boolean;
Var i:Int64;
begin
wr:=0;
GetConstantNibble:=GetConstant(s,i,0,15);
If GetConstantNibble Then wr:=Word(i);
End;

Function GetConstantByte(s:String;Var wr:Word):Boolean;
Var i:Int64;
Begin
wr:=0;
GetConstantByte:=GetConstant(s,i,-255,255);
If GetConstantByte Then
  Begin
  If i<0 Then i:=256+i;
  wr:=Word(i);
  End;
End;

Function GetConstantByteInverted(s:String; Var wr:Word):Boolean;
Begin
GetConstantByteInverted:=GetConstantByte(s,wr);
wr:=Word(255-wr);
End;

Function GetConstantWord(s:String;Var wr:Word):Boolean;
Var i:Int64;
Begin
wr:=0;
GetConstantWord:=GetConstant(s,i,-65535,65535);
If GetConstantWord Then
  Begin
  If i<0 Then i:=65536+i;
  wr:=Word(i);
  End;
End;

Function GetConstantLongWord(s:String;Var wr:LongWord):Boolean;
Var fValid:Boolean;
  i:Int64;
Begin
wr:=0;
fValid:=True;
GetConstantLongWord:=GetExpression(s,fValid,i);
If (Not fValid) And (pass=1) Then i:=0;
If GetConstantLongWord Then
  Begin
  If pass=2 then
    Begin
    If Not fValid Then
      Begin
      GetConstantLongWord:=False;
      Error(26,'','');
      End Else
      Begin
      If (i>=0) And (i<=4194303) Then
        wr:=i Else
        Begin
        GetConstantLongWord:=False;
        Error(24,IntToWideStr(i),'0..4194303');
        End;
      End;
    End else
    wr:=0;
  End Else
  wr:=0;
End;

Function GetOffset(s:String;Var wr:Word;imax:LongInt):Boolean;
Var fValid,fError:Boolean;
  i:Int64;
Begin
wr:=0;
i:=0;
GetOffset:=True;
If pass=1 Then wr:=0 Else
  Begin
  fValid:=True;
  GetOffset:=GetExpression(s,fValid,i);
  If (s[1]='+') Or (s[1]='-') Then
    Begin
    GetOffset:=GetExpression(Copy(s,2,255),fValid,i);
    If s[1]='-' Then i:=-i-1 else i:=i-1;
    End Else
    Begin
    GetOffset:=GetExpression(s,fValid,i);
    i:=i-pc-1;
    End;
  If GetOffset And fValid Then
    Begin
    fError:=False;
    If (i<(-imax+1)) Or (i>imax) Then
      Begin
      fError:=True;
      i:=i+pc+1;
      If fWrapOn Then
        Begin
        If i>(pc+1) Then
          i:=i-(pc+1+(aDevices[nDev].nf Div 2)) else
          i:=(aDevices[nDev].nf Div 2)-(pc+1)+i;
        fError:=(i<-imax) Or (i>(imax-1));
        If Not fError Then Warning(True,7,'','');
        End;
      If fError Then
        Begin
        GetOffset:=False;
        Error(23,IntToWideStr(i),'-'+IntToWideStr(imax-1)+'..+'+IntToWideStr(imax));
        End Else
      End;
    End;
  If GetOffset And fValid Then
    Begin
    If i>=0 Then wr:=Word(i MOD imax) Else wr:=Word(2*imax+i);
    End;
  End;
End;

Function GetLdSt(s:String;Var wr:Word;cST:Boolean):Boolean;
Var se:String;
Begin
If cST Then se:='ST' Else se:='LD';
wr:=0;
GetLdSt:=True;
If SnipOff(s) Then
  Begin
  if (s<>'Z') And (nDev=1) Then
    Error(35,'LD/ST','AT90S1200') else
    begin
    Case Length(s) Of
      1:Begin
        Case s[1] Of
          'X':wr:=$900C;
          'Y':wr:=$8008;
          'Z':wr:=$8000;
          Else
          GetLdSt:=False;
          Error(27,WideString(se),WideString(s));
          End;
        End;
      2:If s[1]='-' Then
        Begin
        If CheckInstValid(hasLdXY) Then
          Begin
          Case s[2] Of
            'X':wr:=$900E;
            'Y':wr:=$900A;
            'Z':wr:=$9002;
            Else
            GetLdSt:=False;
            Error(27,WideString(se),WideString(s));
            End;
          End Else
          Begin
          Error(98,'','');
          GetLdSt:=False;
          End;
        End Else
        Begin
        If s[2]='+' Then
          Begin
          If CheckInstValid(hasLdXY) Then
            Begin
            Case s[1] Of
              'X':wr:=$900D;
              'Y':wr:=$9009;
              'Z':wr:=$9001;
              Else
              GetLdSt:=False;
              Error(27,WideString(se),WideString(s));
              End;
            End Else
            Begin
            Error(98,'','');
            GetLdSt:=False;
            End;
          End Else
          Begin
          GetLdSt:=False;
          Error(27,WideString(se),WideString(s));
          End;
        End;
      Else
      GetLdSt:=False;
      Error(27,WideString(se),WideString(s));
      End;
    If GetLdSt And cST Then wr:=Word(wr+$0200);
    End;
  End Else
  Begin
  GetLdSt:=False;
  Error(28,WideString(se),'');
  End;
End;

Function GetLddStd(s:String;Var wr:Word;fStd:Boolean):Boolean;
Var se:String;
  wh:LongInt;
  fValid:Boolean;
  i:Int64;
Begin
If fStd Then se:='STD' Else se:='LDD';
wr:=0;
GetLddStd:=True;
If RemoveBlankTab(s) Then
  Begin
  Case s[1] Of
    'Y':wr:=$8008;
    'Z':wr:=$8000;
    Else
    GetLddStd:=False;
    Error(29,WideString(se),WideString(s[1]));
    End;
  If GetLddStd Then
    Begin
    i:=0;
    If (Length(s)>1) And (s[2]='+') Then
      Begin
      GetLddStd:=GetExpression(Copy(s,3,255),fValid,i);
      If (Not fValid) And (pass=1) Then i:=0;
      End;
    If GetLddStd Then
      Begin
      If (i>=0) And (i<64) Then
        Begin
        wh:=i MOD 64;
        wr:=Word(wr+(wh AND $07)+128*(wh AND $18)+256*(wh AND $20));
        If fStd Then wr:=Word(wr+$0200);
        End Else
        Begin
        GetLddStd:=False;
        Error(30,WideString(se),IntToWideStr(i));
        End;
      End;
    End;
  End Else
  Begin
  GetLddStd:=False;
  Error(31,'','');
  End;
End;

Function GetELpm(s1,s2:String;Var w1,w2:Word):Boolean;
Begin
GetELpm:=False;
w1:=0;
w2:=0;
If RemoveBlankTab(s1) Or RemoveBlankTab(s2) Then
  Begin
  GetELpm:=GetRegister(s1,w2);
  If GetELpm Then
    Begin
    If s2<>'' Then
      Begin
      If s2[1]='Z' Then
        Begin
        GetELpm:=True;
        Case Length(s2) Of
          1:If Inst.sM='ELPM' Then
              Begin
              w1:=$0006;
              If Not CheckInstValid(hasElpmZ) Then
                Error(35,'ELPM r,Z',WideString(aDevices[nDev].sn));
              End Else
              Begin
              w1:=$0004;
              If Not CheckInstValid(hasLpmZ) Then
                Error(35,'LPM r,Z',WideString(aDevices[nDev].sn));
              End;
          2:If s2[2]='+' Then
            Begin
            If Inst.sM='ELPM' Then
              Begin
              w1:=$0007;
              If Not CheckInstValid(hasElpmZ) Then
                Error(35,'ELPM r,Z+',WideString(aDevices[nDev].sn));
              End Else
              Begin
              w1:=$0005;
              If Not CheckInstValid(hasLpmZ) Then
                Error(35,'LPM r,Z+',WideString(aDevices[nDev].sn));
              End;
            End Else
            Begin
            Error(32,WideString(s2[2]),'');
            GetELpm:=False;
            End;
          Else
          Error(33,WideString(s2),'');
          GetELpm:=False;
          End;
        End Else
        Error(33,WideString(s2),'');
      End Else
      Error(33,'-','');
    End Else
    Error(34,'','');
  End Else
  Begin
  GetELpm:=True;
  If Inst.sM='ELPM' Then
    Begin
    w1:=$05D8;
    If Not CheckInstValid(hasElpm) Then
      Error(35,'ELPM',WideString(aDevices[nDev].sn));
    End Else
    Begin
    w1:=$05C8;
    If Not CheckInstValid(hasLpm) Then
      Error(35,'LPM',WideString(aDevices[nDev].sn));
    End;
  End;
End;

Function GetSpm(s:String;Var w1:Word):Boolean;
Begin
GetSpm:=False;
If s='Z+' Then
  Begin
  w1:=$10;
  If CheckInstValid(hasSpmZ) Then GetSpm:=True Else
    Error(35,'SPM Z+',WideString(aDevices[nDev].sn));
  End Else
  Begin
  If s='' Then
    Begin
    w1:=$00;
    If CheckInstValid(hasSpm) Then GetSpm:=True Else
      Error(35,'SPM',WideString(aDevices[nDev].sn));
    End Else
    Error(90,'','');
  End;
End;

Function GetZ(s:String):Boolean;
begin
GetZ:=UpperCase(s)='Z';
If Not GetZ Then Error(102,WideString(Inst.sM),WideString(s));
end;

{
Function ToHex(i:DWord):String;
Var k:DWord;
  b:Byte;
Begin
k:=$100000;
ToHex:='$';
Repeat
  b:=i Div k;
  If b>9 Then ToHex:=ToHex+Char(55+b) Else ToHex:=ToHex+Char(48+b);
  i:=i-b*k;
  k:=k Div 16;
  If (k=$1000) Or (k=$10) Then ToHex:=ToHex+'.';
  Until k=0;
End;
    }

{ -------------------- }
{ Analyse instructions }
{ -------------------- }
Function AnalyseCommand:Boolean;
Var wp1,wp2:Word;
  lw1:LongWord;
  fLdSt1200:Boolean;
Begin
AnalyseCommand:=False;
With Inst Do With cl Do
  Begin
  fLdSt1200:=((sM='LD') Or (sM='ST')) And (nDev=1);
  If Not (CheckInstValid(wt) Or fLdSt1200) Then
    Begin
    Error(35,WideString(sM),WideString(aDevices[nDev].sn));
    End Else
    Begin
    If (np<0) Or (np=nsp) Then
      Begin
      w1:=wx;
      Case c1 Of
        ' ':Begin
          AnalyseCommand:=(nsp=0);
          If nsp>0 Then Error(90,'','');
          End;
        'R':AnalyseCommand:=GetRegister(asp[1],wp1);
        'H':AnalyseCommand:=GetHighRegister(asp[1],wp1);
        'D':AnalyseCommand:=GetDoubleRegister(asp[1],wp1);
        'P':AnalyseCommand:=GetPort(asp[1],wp1);
        'Q':AnalyseCommand:=GetLowPort(asp[1],wp1);
        'B':AnalyseCommand:=GetBit(asp[1],wp1);
        '1':AnalyseCommand:=GetOffset(asp[1],wp1,64);
        '2':AnalyseCommand:=GetOffset(asp[1],wp1,2048);
        'S':AnalyseCommand:=GetLdSt(asp[1],wp1,True);
        'T':AnalyseCommand:=GetLddStd(asp[1],wp1,True);
        'N':AnalyseCommand:=GetConstantNibble(asp[1],wp1);
        'W':AnalyseCommand:=GetConstantWord(asp[1],wp1);
        'X':AnalyseCommand:=GetConstantLongWord(asp[1],LongWord(lw1));
        'E':AnalyseCommand:=GetELpm(asp[1],asp[2],wp1,wp2); { LPM,ELPM }
        'J':AnalyseCommand:=GetMulReg(asp[1],wp1);
        'K':AnalyseCommand:=GetMovwReg(asp[1],wp1);
        'M':AnalyseCommand:=GetSpm(asp[1],wp1);
        'Z':AnalyseCommand:=GetZ(asp[1]);
        Else
        Dbg('Illegal parameter type c1 ('+c1+')!');
        End;
      Case c2 Of
        ' ':Begin
          AnalyseCommand:=(nsp<=1) Or (sM='LPM') Or (sM='ELPM');
          If Not AnalyseCommand Then
            Error(90,'','');
          End;
        'R':AnalyseCommand:=GetRegister(asp[2],wp2);
        'H':AnalyseCommand:=GetHighRegister(asp[2],wp2);
        'I':AnalyseCommand:=GetConstantByteInverted(asp[2],wp2);
        'P':AnalyseCommand:=GetPort(asp[2],wp2);
        'B':AnalyseCommand:=GetBit(asp[2],wp2);
        '1':AnalyseCommand:=GetOffset(asp[2],wp2,64);
        '6':AnalyseCommand:=GetConstantSmall(asp[2],wp2);
        '8':AnalyseCommand:=GetConstantByte(asp[2],wp2);
        'L':AnalyseCommand:=GetLdSt(asp[2],wp2,False);
        'M':AnalyseCommand:=GetLddStd(asp[2],wp2,False);
        'W':AnalyseCommand:=GetConstantWord(asp[2],wp2);
        'J':AnalyseCommand:=GetMulReg(asp[2],wp2);
        'K':AnalyseCommand:=GetMovwReg(asp[2],wp2);
        Else
        Dbg('Illegal parameter type c2 ('+c2+')!');
        End;
      End Else
      Begin
      If nsp>np Then Error(90,'','') Else Error(91,'','');
      AnalyseCommand:=False;
      End;
    If AnalyseCommand Then
      Begin
      If (c1<>' ') And (c2<>' ') Then
        Case cC Of
          '1':w1:=Word(w1+16*wp1+(wp2 MOD 16)+32*(wp2 AND $10)); { ADC,ADD,CP,CPC,CPSE,EOR,MOV,OR,SBC,SUB }
          '2':w1:=Word(w1+16*wp1+(wp2 MOD 16)+16*(wp2 AND $F0)); { ANDI,CBR,CPI,LDI,ORI,SBCI,SBR,SUBI }
          '3':w1:=Word(w1+16*wp1+wp2); { BLD,BST,SBRC,SBRS }
          '4':w1:=Word(w1+wp1+Word(8*wp2)); { BRBC,BRBS }
          '5':w1:=Word(w1+8*wp1+wp2); { CBI,SBI,SBIC,SBIS }
          '6':w1:=Word(w1+16*wp1+(wp2 MOD 16)+32*(wp2 AND $30)); { IN }
          '7':w1:=Word(w1+16*wp1+(wp2 MOD 16)+4*(wp2 AND $30)); { SBIW,ADIW }
          '8':w1:=Word(wp2+16*wp1); { LDD }
          '9': {LDS}
            Begin
            If fAvr8L Then
              begin
              Inst.nW:=1;
              If (wp2<$40) Or (wp2>$BF) Then
                Error(24,IntToWideStr(Round(wp2) And $FFFF),'64..191') Else
	            Begin
                If wp2>=$80 Then
                  w1:=$A000+16*(wp1-16)+((wp2-$80) And $0F)+512*((wp2-$80) Div 16) Else
                  w1:=$A100+16*(wp1-16)+((wp2-$40) And $0F)+512*((wp2-$40) Div 16);
                End;
              end else
              begin
              w1:=Word(w1+16*wp1);
              w2:=Word(wp2);
              end;
            End;
          'A': {STS}
            Begin
            If fAvr8L Then
              begin
              Inst.nW:=1;
              If (wp1<$40) Or (wp1>$BF) Then
                Error(24,IntToWideStr(Round(wp1) And $FFFF),'64..191') Else
	            Begin
                If wp1>=$80 Then
                  w1:=$A800+16*(wp2-16)+((wp1-$80) And $0F)+512*((wp1-$80) Div 16) Else
                  w1:=$A900+16*(wp2-16)+((wp1-$40) And $0F)+512*((wp1-$40) Div 16);
                End;
              End Else
              begin
              w1:=Word(w1+16*wp2);
              w2:=Word(wp1);
              end;
            End;
          'B':w1:=Word(wp2+16*wp1); { LD }
          'C':w1:=Word(wp1+16*wp2); { ST }
          'D':w1:=Word(wp1+16*wp2); { STD }
          'E':w1:=Word(w1+16*wp2+(wp1 MOD 16)+32*(wp1 AND $30)); { OUT }
          'F':w1:=Word(w1+16*wp1+wp2); { FMUL,FMULS,FMULSU,MOVW,MULS,MULSU }
          'G':w1:=Word(w1+16*wp2); { XCH, LAS, LAC, LAT }
          Else
          Dbg('Illegal 2-parameter method '+cC+'!');
          End;
      If (c1<>' ') And (c2=' ') Then
        Case cC Of
          '1':w1:=Word(w1+16*(wp1 MOD 32)); { ASR,COM,DEC,INC,LSR,NEG,POP,PUSH,ROR,SWAP }
          '2':w1:=Word(w1+16*(wp1 MOD 8)); { BCLR,BSET }
          '3':w1:=Word(w1+8*(wp1 MOD 128)); { BRxx }
          '4':w1:=Word(w1+16*wp1+(wp1 MOD 16)+32*(wp1 AND $10)); { CLR,LSL,ROL,TST }
          '5':w1:=Word(w1+wp1); { RCALL,RJMP, SPM }
          '6': Begin { CALL,JMP }
            w2:=Word(lw1 AND $FFFF);
            wp1:=Word(lw1 DIV $010000);
            w1:=Word(w1+(wp1 AND $0001)+Word(8*(wp1 AND $003E)));
            End;
          '7':w1:=Word(w1+16*wp1); { SER }
          '8':w1:=Word(w1+wp1+Word(16*wp2)); { LPM,ELPM }
          'G':w1:=Word(w1+16*wp1); { DES }
          Else
          Dbg('Illegal 1-parameter method '+cC+'!');
          End;
      End Else
      Begin
      w1:=0;
      w2:=0;
      End;
    End;
  End;
End;

{ ---------------------------- }
{ Process assembler directives }
{ ---------------------------- }

Function CheckInternalDefine(s:String):Boolean;
Var k:LongInt;
Begin
k:=0;
s:=UpperCase(s);
k:=Pos('DEF.INC',s);
If k>0 Then
  Begin
  Repeat Dec(k) Until (k=0) Or (s[k]='\') Or (s[k]='/');
  If k>0 Then s:=Copy(s,k+1,255);
  nDev:=GetDeviceFromInc(s);
  If nDev<0 Then nDev:=0;
  CheckInternalDefine:=nDev>0;
  End Else
  CheckInternalDefine:=False;
End;

Function ExpandHex(sExp:AnsiString):AnsiString;
Var k:LongInt;
begin
k:=1; { Expand standard symbol string }
ExpandHex:='';
While k<=Length(sExp) Do
  begin
  Case sExp[k] Of
    '0':ExpandHex:=ExpandHex+'0000';
    '1':ExpandHex:=ExpandHex+'0001';
    '2':ExpandHex:=ExpandHex+'0010';
    '3':ExpandHex:=ExpandHex+'0011';
    '4':ExpandHex:=ExpandHex+'0100';
    '5':ExpandHex:=ExpandHex+'0101';
    '6':ExpandHex:=ExpandHex+'0110';
    '7':ExpandHex:=ExpandHex+'0111';
    '8':ExpandHex:=ExpandHex+'1000';
    '9':ExpandHex:=ExpandHex+'1001';
    'A':ExpandHex:=ExpandHex+'1010';
    'B':ExpandHex:=ExpandHex+'1011';
    'C':ExpandHex:=ExpandHex+'1100';
    'D':ExpandHex:=ExpandHex+'1101';
    'E':ExpandHex:=ExpandHex+'1110';
    'F':ExpandHex:=ExpandHex+'1111';
    else
    Writeln('Internal compiler error! Illegal character in hex constant!');
    Halt(9);
    end;
  Inc(k);
  end;
end;

Procedure DefineSymbolList(s:AnsiString);
Var err,i,j,p:LongInt;
begin
s:=s+';';
While s<>'' Do
  begin
  p:=AnsiPos(':',s);
  Val(Copy(s,1,p-1),i,err);
  If err>0 Then
    begin
    Writeln('Internal compiler error! Illegal char in number "',Copy(s,1,p-1),'"');
    Halt(9);
    end else
    begin
    Delete(s,1,p);
    p:=AnsiPos(';',s);
    Val(Copy(s,1,p-1),j,err);
    If err>0 Then
      begin
      Writeln('Internal compiler error! Illegal char in number "',Copy(s,1,p-1),'"');
      Halt(9);
      end else
      begin
      AddSymbol('C',aSymbolNames[i],True,j);
      Delete(s,1,p);
      end;
    end;
  end;
end;

Procedure DefineDeviceSymbols;
Const s='CZNVSHTI';
Var sExp:AnsiString;
  k,l:LongInt;
begin
With aDevices[nDev] Do
  begin
  If fSreg Then { define SREG definitions }
    For k:=0 To 7 Do
      AddSymbol('C','SREG_'+s[k+1],TRUE,k);
  If sBits<>'' Then { define bit symbols }
    begin
    sExp:=ExpandHex(sBits);
    For k:=1 To Length(sExp) Do If sExp[k]='1' Then For l:=0 To 7 Do
      AddSymbol('C',sBitNames[k]+IntToStr(l),True,l);
    end;
  If soSym<>'' Then { define symbol patterns }
    begin
    sExp:=ExpandHex(soSym);
    For k:=1 To Length(sExp) Do If sExp[k]='1' Then
      DefineSymbolList(aOSym[k]);
    end;
  If sStd<>'' Then { define standard symbols }
    begin
    sExp:=ExpandHex(sStd);
    For k:=1 To Length(sExp) Do If sExp[k]='1' Then
      AddSymbol('C',aSymbolNames[aStdSym[k,1]],True,aStdSym[k,2]);
    end;
  If sSym<>'' Then DefineSymbolList(sSym); { define rest of the remaining symbols }
  If CheckInstValid(hasLdXY) Then
    begin
    AddSymbol('R','XH',TRUE,27);
    AddSymbol('R','XL',TRUE,26);
    AddSymbol('R','YH',TRUE,29);
    AddSymbol('R','YL',TRUE,28);
    AddSymbol('R','ZH',TRUE,31);
    AddSymbol('R','ZL',TRUE,30);
    end;
  end;
end;

Procedure DefineDevice;
Begin
If FindSymbolFirst('T')= NIL Then
  Begin
  If AddSymbol('T',aDevices[nDev].sn,TRUE,nDev) Then
    Begin
    fWithInDefInclude:=True;
    pd:=aDevices[nDev].nss;
    fAvr8L:=aDevices[nDev].nr=16;
    SetInstSet(aDevices[nDev].iSet);
    DefineDeviceSymbols;
    End Else
    Error(93,'','');
  End Else
  Error(100,'','');
fWithInDefInclude:=False;
End;

Procedure ProcessDevice;
Var s:String;
Begin
s:=UpperCase(cl.asp[1]);
If (s[1]='"') And (s[Length(s)]='"') Then
  Begin
  Delete(s,Length(s),1);
  Delete(s,1,1);
  End;
nDev:=GetDeviceFromName(s);
If nDev>0 Then
  Begin
  If (pass=1) And (Not fInternalOff) Then DefineDevice;
  End Else
  begin
  Error(53,'','');
  nDev:=0;
  end;
End;

Procedure IncludeFile;
Var s,spFileOld:String;
  npLineOld:LongInt;
Begin
s:=cl.asp[1];
If SnipOff(s) Then
  Begin
  If s[1]='"' Then Delete(s,1,1);
  If s[Length(s)]='"' Then Delete(s,Length(s),1);
  If (Not fInternalOff) And CheckInternalDefine(s) Then
    Begin
    If pass=1 Then
      Begin
      DefineDevice;
      end else
      Warning(True,9,'','');
    End Else
    Begin
    If FileExists(s) Then
      Begin
      spFileOld:=spFile;
      npLineOld:=npLine;
      Writeln(GetMsgM(14),s);
      If Not fListOff Then Writeln(fl,'  ',GetMsgM(14),s);
      ProcessFile(s);
      Writeln('ok.');
      spFile:=spFileOld;
      npLine:=npLineOld;
      If Not fListOff Then Writeln(fl,'  ',GetMsgM(15),spFile);
      If fInternalOff And CheckInternalDefine(s) Then
        Begin
        pd:=aDevices[nDev].nss;
        SetInstSet(aDevices[nDev].iSet);
        End;
      End Else
      Begin
      Error(36,WideString(s),'');
      End;
    End;
  End Else
  Error(37,'','');
End;

Function SplitPseudoEquation(Var s1,s2:String):Boolean;
Var p:Byte;
Begin
SplitPseudoEquation:=False;
p:=Byte(Pos('=',cl.asp[1]));
If p>0 Then
  Begin
  s1:=Copy(cl.asp[1],1,p-1);
  s2:=Copy(cl.asp[1],p+1,255);
  If SnipOff(s1) Then
    Begin
    If SnipOff(s2) Then
      Begin
      If CheckSymbolLegal(s1) Then
        Begin
        If CheckExpression(s2) Then
          SplitPseudoEquation:=True Else
          Error(38,'2',WideString(s2));
        End Else
        Error(38,'1',WideString(s1));
      End Else
      Error(38,'2',WideString(s2));
    End Else
    Error(38,'1',WideString(s1));
  End Else
  Error(39,'','');
End;

Procedure EquSetDef(cType:Char);
Var s1,s2:String;
  i:Int64;
  fv,fValid:Boolean;
Begin
If SplitPseudoEquation(s1,s2) Then
  Begin
  Case cType Of
    'R':
      Begin
      fvalid:=True;
      If GetSymbolValue('CVG',s1,fValid,i) Then
        Begin
        fv:=False;
        Error(40,WideString(s1),'constant or variable');
        End Else
        begin
        i:=GetRegisterValue(s2);
        fv:=i>=0;
        end;
       End;
    'C','V':
      Begin
      fValid:=True;
      If GetSymbolValue('R',s1,fValid,i) Then
        Begin
        fv:=False;
        Error(40,WideString(s1),'register');
        End Else
	      Begin
      	fv:=GetConstantLongInt(s2,fValid,i);
	      End;
      End;
    Else
    Dbg('EquSetDef: cType not R, C, G or V!');
    End;
  If fv Then
    Begin
    fv:=True;
    Case pass Of
      1:If Not AddSymbol(cType,s1,fv,i) Then Error(55,WideString(s1),'');
      2:If Not SetSymbol(cType,s1,fv,i) Then Error(56,WideString(s1),'');
      End;
    End Else
    Error(41,'','');
{$IFDEF debug}
    DisplaySymbols;
{$ENDIF}
  End;
End;

Procedure Undef;
Var i:Int64;
  fValid:Boolean;
  s1:String;
Begin
s1:=UpperCase(cl.asp[1]);
fValid:=True;
If GetSymbolValue('CVLGMR',s1,fValid,i) Then
  UndefSymbol(s1) Else
  Error(7,WideString(s1),' ');
End;

Procedure ProcessByte;
Var i:Int64;
  fValid:Boolean;
Begin
If GetExpression(cl.asp[1],fValid,i) And fValid Then
  Begin
  pd:=pd+i;
  nd:=nd+i;
  End Else
  Begin
  If pass=2 Then Error(43,'','');
  End;
End;

Procedure ProcessOrg;
Var i:Int64;
  fValid:Boolean;
Begin
If GetExpression(cl.asp[1],fValid,i) And fValid Then
  Begin
  Case cSegm Of
    'C':If i>=pc Then pc:=i Else
      Error(46,IntToWideStr(i),'code segment');
    'D':If i>=pd Then pd:=i Else
      Error(46,IntToWideStr(i),'data segment');
    'E':If (i>=pe) Or fEepromErr Then pe:=i Else
      Error(46,IntToWideStr(i),'eeprom segment!');
    End;
  End Else
  Begin
  If pass=2 Then Error(47,'','');
  End;
End;

Function GetString(s:String):String;
Var k:Byte;
  sh:String;
Begin
sh:=s;
GetString:='';
If (s[1]='"') And (s[Length(s)]='"') Then
  Begin
  Delete(s,1,1);
  Delete(s,Length(s),1);
  k:=Length(s);
  While k>0 Do
    Begin
    Case s[k] Of
      '"':If (k>1) And (s[k-1]='"') Then
        Begin
        Delete(s,k,1);
        Dec(k);
        End;
      '\':If (k>1) And (s[k-1]='\') Then
        Begin
        Delete(s,k,1);
        Dec(k);
        End Else
        Begin
        Delete(s,k,1);
        If k<=Length(s) Then
          s[k]:=Char(Byte(s[k]) MOD $20) Else
          Error(88,WideString(sh),'');
        End;
      End;
    Dec(k);
    End;
  GetString:=s;
  End Else
  Error(89,WideString(s),'');
End;

Function GetLiteral(s:String):Char;
Begin
GetLiteral:=Char(0);
If (s[1]='''') And (s[Length(s)]='''') Then
  Begin
  Case Length(s) Of
    3:GetLiteral:=s[2];
    4:Begin
      Case s[2] Of
        '''':If s[3]='''' Then
          GetLiteral:='''' Else
          Error(87,WideString(s),'');
        '\':If s[3]='\' Then
          GetLiteral:='\' Else
          GetLiteral:=Char(Byte(s[3]) Mod $20);
        Else
        Error(87,WideString(s),'');
        End;
      End;
    Else
    Error(87,WideString(s),'');
    End;
  End Else
  Dbg('Literal ('+s+') does not start and end with a ''!');
End;

Procedure ProcessDb;
Var j,k,nab:LongInt;
  ab:Array[1..255] Of Byte;
  w:Word;
  s:String;
Begin
nab:=0;
w:=0;
For k:=1 To cl.nsp Do With cl Do
  If (asp[k]<>'') And (asp[k,1]='"') Then
    Begin
    s:=GetString(asp[k]);
    If s<>'' Then For j:=1 To Length(s) Do
        Begin
        Inc(nab);
        ab[nab]:=Byte(s[j]);
        End;
    End Else
    Begin
    GetConstantByte(cl.asp[k],w);
    Inc(nab);
    ab[nab]:=Byte(w);
    End;
If nab=0 Then
  Warning(True,3,'','') Else
  Begin
  If (cSegm='C') And ((nab MOD 2)=1) Then
    Begin
    If pass=2 Then
      Warning(True,4,'','');
    Inc(nab);
    ab[nab]:=0;
    End;
  s:=ListGetAddressAlone;
  Case cSegm Of
    'C':For k:=1 To nab Div 2 Do
      Begin
      w:=Word(256*ab[2*k]+ab[2*k-1]);
      Inc(nconstants);
      If pass=2 Then HexWriteC(pc,w);
      If Not fListOff Then
        Begin
        If (k Mod 4)<>1 Then s:=s+' ';
        s:=s+LongInt2HexN(4,w);
        If ((k MOD 4)=0) Or (k=(nab Div 2)) Then
          Begin
          Writeln(fl,s);
          Inc(pc);
          s:=ListGetAddressAlone;
          Dec(pc);
          End;
        End;
      Inc(pc);
      End;
    'E':For k:=1 To nab Do
      Begin
      If pass=2 Then HexWriteE(pe,ab[k]);
      Inc(ne);
      If Not fListOff Then
        Begin
        If (k Mod 8)<>1 Then s:=s+' ';
        s:=s+LongInt2HexN(2,ab[k]);
        If ((k Mod 8)=0) Or (k=nab) Then
          Begin
          Writeln(fl,s);
          Inc(pe);
          s:=ListGetAddressAlone;
          Dec(pe);
          End;
        End;
      Inc(pe);
      End;
    End;
  End;
End;

Procedure ProcessDw;
Var w:Word;
  s:String;
  k,naw:Byte;
  aw:Array[1..255] Of Word;
Begin
naw:=0;
w:=0;
For k:=1 To cl.nsp Do
  Begin
  If (Pos('''',cl.asp[k])>0) Or (Pos('"',cl.asp[k])>0) Then
    Error(49,'','') Else
    Begin
    GetConstantWord(cl.asp[k],w);
    Inc(naw);
    aw[naw]:=w;
    End;
  End;
If naw>0 Then
  Begin
  s:=ListGetAddressAlone;
  Case cSegm Of
    'C':For k:=1 To naw Do
      Begin
      If pass=2 Then HexWriteC(pc,aw[k]);
      Inc(pc);
      Inc(nconstants);
      If Not fListOff Then
        Begin
        If (k MOD 8)<>1 Then s:=s+' ';
        s:=s+LongInt2HexN(4,aw[k]);
        If ((k MOD 8)=0) Or (k=naw) Then
          Begin
          If Not fListOff Then Writeln(fl,s);
          s:=ListGetAddressAlone;
          End;
        End;
      End;
    'E':For k:=1 To naw Do
      Begin
      If pass=2 Then HexWriteE(pe,Byte(aw[k] MOD 256));
      Inc(pe);
      Inc(ne);
      If pass=2 Then HexWriteE(pe,Byte(aw[k] DIV 256));
      Inc(pe);
      Inc(ne);
      If Not fListOff Then
        Begin
        If (k MOD 4)<>1 Then s:=s+' ';
        s:=s+LongInt2HexN(2,aw[k] MOD 256)+' '+LongInt2HexN(2,aw[k] Div 256);
        If ((k MOD 4)=0) Or (k=naw) Then
          Begin
          If Not fListOff Then Writeln(fl,s);
          s:=ListGetAddressAlone;
          End;
        End;
      End;
    End;
  End Else
  Error(50,'','');
End;

Procedure ProcessMacro;
Begin
If (pass=1) And (Not WriteNewMacro(cl.asp[1])) Then
  Error(57,WideString(cl.asp[1]),'');
fMacroDef:=True;
End;

Procedure ProcessEndMacro;
Begin
If (pass=1) And (Not WriteCloseMacro) Then
  Error(59,'','');
fMacroDef:=False;
End;

Procedure ProcessIf; { Call of routine in gavrif }
Var f,fValid:Boolean;
  i:Int64;
Begin
fValid:=True;
If fIfAsm And (Not GetExpression(cl.asp[1],fValid,i))  Then
  Error(62,'','') else
  begin
  If (Not fValid) And fIfAsm Then
    Error(61,'','') else
    Begin
    f:=fIfAsm And (i=1);
    IfNew(f,npLine);
    End;
  end;
End;

Procedure ProcessIfDevice; { Call of routine in gavrif }
Var p:PSList;
  f:Boolean;
Begin
If (cl.asp[1,1]='"') And (cl.asp[1,Length(cl.asp[1])]='"') Then
  Begin
  Delete(cl.asp[1],Length(cl.asp[1]),1);
  Delete(cl.asp[1],1,1);
  End;
If GetDeviceFromName(cl.asp[1])>0 Then
  Begin
  p:=FindSymbolFirst('T');
  If p=NIL Then
    Error(7,WideString(cl.asp[1]),'') Else
    Begin
    f:=fIfAsm And (UpperCase(cl.asp[1])=p^.sName);
    IfNew(f,npLine);
    end;
  End Else
  Error(92,WideString(cl.asp[1]),'');
End;

Procedure ProcessEndIf; { call of routine in gavrif }
Begin
If IfActive Then
  IfEnd Else { .ENDIF }
  Error(64,'','');
End;

Procedure ProcessElse; { call of routine in gavrif }
Begin
If IfActive Then
  IfElse Else
  Error(65,'','');
End;

Procedure ProcessElif; { call of routine in gavrif }
Var fValid:Boolean;
  i:Int64;
Begin
If IfActive Then
  begin
  If Not fIfAsm Then
    begin
    If GetExpression(cl.asp[1],fValid,i) Then
      Begin
      If fValid Then
        Begin
        If i=1 Then IfElse;
        End Else
        Error(61,'','');
      End Else
      Error(62,'','');
    End;
  End Else
  Error(65,'','');
End;

Procedure ProcessIfDef; { call of routine IFNEW in gavrif }
Var f,fValid:Boolean;
  i:Int64;
Begin
fValid:=True;
f:=fIfAsm And (GetSymbolValue(sAllTypes,cl.asp[1],fValid,i) And fValid);
IfNew(f,npLine);
End;

Procedure ProcessIfNDef; { call of IFNEW routine in gavrif }
Var f,fValid:Boolean;
  i:Int64;
Begin
fValid:=True;
f:=fIfAsm And (Not GetSymbolValue(sAllTypes,cl.asp[1],fValid,i));
IfNew(f,npLine);
End;

Procedure ProcessMessage;
Begin
Message(WideString(cl.sString));
Writeln;
End;

Procedure ProcessError;
Begin
Error(0,'','');
End;

Procedure ProcessExit;
Var fValid:Boolean;
  i:Int64;
Begin
If cl.nsp=1 Then
  Begin
  fValid:=True;
  If GetExpression(cl.asp[1],fValid,i) Then
    Begin
    If fValid Then
      Begin
      fExit:=i=1;
      If fExit Then Error(86,'','');
      End Else
      Error(84,'','');
    End Else
    Error(85,'','');
  End Else
  fExitFile:=True;
End;

Procedure ProcessSegm(c:Char);
Begin
cSegm:=c;
Case c Of
  'C': If Not fCSeg Then fCSeg:=True;
  'D': If Not fDSeg Then
         Begin
         pd:=aDevices[nDev].nss;
         fDSeg:=True;
         End;
  'E': If Not fESeg Then
         Begin
         pe:=0;
         fESeg:=True;
         End;
  End;
End;

Procedure ProcessPseudo;
Var fe:Boolean;
Begin
If cl.nDirective>0 Then
  Begin
  sListLine2:='';
  If Not fListOff Then Writeln(fl,ListGetLine+cl.sLine);
  fe:=False;
  Case cSegm Of
    'C':Case cl.nDirective Of
          iDirByte:fe:=True;
          iDirEndMacro,iDirEndM:fe:=Not fMacroDef;
          End;
    'D':Case cl.nDirective Of
          iDirDb,iDirDw:fe:=True;
          End;
    'E':Case cl.nDirective Of
	  iDirByte:fe:=True;
          End;
    End;
  If fe Then
    Error(66,WideString(cSegm),'') Else
    Begin
    Case cl.nDirective Of
      iDirByte:ProcessByte; { .BYTE }
      iDirCseg:ProcessSegm('C') ; { .CSEG }
      iDirDb:ProcessDb; { .DB }
      iDirDef:EquSetDef('R'); { .DEF }
      iDirDevice:ProcessDevice; { .DEVICE }
      iDirDseg:ProcessSegm('D') ; { .DSEG }
      iDirDw:ProcessDw; { .DW }
      iDirElif:ProcessElif; { .ELIF}
      iDirElse:ProcessElse; { .ELSE }
      iDirEndIf:ProcessEndIf; { ENDIF }
      iDirEqu:EquSetDef('C'); { .EQU }
      iDirError:ProcessError; { .ERROR}
      iDirEseg:ProcessSegm('E') ; { .ESEG }
      iDirExit:ProcessExit; { .EXIT }
      iDirIf:ProcessIf; { .IF }
      iDirIfDef:ProcessIfDef; { .IFDEF }
      iDirIfDevice:ProcessIfDevice; {.IFDEVICE }
      iDirIfNDef:ProcessIfNDef; { .IFNDEF }
      iDirInclude:IncludeFile; { .INCLUDE }
      iDirMessage:ProcessMessage; { .MESSAGE }
      iDirList:fListOff:=Not fListFileOpen; { .LIST }
      iDirListMac:fListMac:=True; { .LISTMAC }
      iDirMacro:ProcessMacro; { .MACRO }
      iDirEndMacro:ProcessEndMacro; { .ENDMACRO }
      iDirEndM:ProcessEndMacro; { .ENDM }
      iDirNoList:fListOff:=True; { .NOLIST }
      iDirOrg:ProcessOrg; { .ORG }
      iDirSet:EquSetDef('V'); { .SET }
      iDirUndef:Undef; { .UNDEF }
      Else
      Dbg('Unknown directive= '+IntToStr(cl.nDirective));
      End;
    End;
  If (Not fListOff) And (sListLine2<>'') Then Writeln(fl,sListLine2);
  End Else
  Error(67,'','');
End;

{ ------------- }
{ Process lines }
{ ------------- }

Procedure ProcessMacroLine;
Var s:String;
Begin
If (cl.sDirective='ENDMACRO') Or (cl.sDirective='ENDM') Then
  ProcessEndMacro Else
  If pass=1 Then With cl Do
  Begin
  If sDirective='SET' Then
    Begin
    If Pos('=',asp[1])>0 Then
      Begin
      s:=Copy(asp[1],1,Pos('=',asp[1])-1);
      If snipoff(s) Then AddSymbol('V',s,False,0) Else
        Error(65,'','');
      End Else
      Error(65,'','');
    End;
  If Not WriteAddMacroLine(sLine) Then Error(68,'','');
  End;
End;

{$IFDEF debug}

Procedure DisplayMacros;
Var se:String;
Begin
If ResetMacroPointer Then
  Begin
  Writeln;
  Writeln(GetMsgM(11));
  Writeln(GetMsgM(12));
  While EnumMacroList(se) Do Writeln(se);
  End Else
  Writeln(GetMsgM(13));
End;

{$ENDIF}

Procedure ProcessInstructionLine; { normal instruction line }
Var i:Int64;
  fValid:Boolean;
  sLbl:String;
Begin
With cl Do
  Begin
  If (sLabel<>'') Then { define/set label }
    Begin
    Case pass Of
      1:Begin
        fValid:=True;
        If Not AddSymbol('L',sLabel,fValid,ListGetAddressLongInt) Then
          Error(55,WideString(sLabel),'');
        End;
      2:Begin
        fValid:=False;
        sLbl:=sLabel;
        If pcm<>NIL Then
          sLbl:=sLabel+'@'+pcm^.sMacName+'@'+IntToStr(pcm^.nMacUse);
        If GetSymbolValue('L',sLbl,fValid,i) Then
          Begin
          If i<>ListGetAddressLongInt Then
            Dbg('Label value ($'+
              LongInt2HexN(6,ListGetAddressLongInt)+') <> pass1 ($'+
              LongInt2HexN(6,i)+')!');
          End Else
          Begin
          Dbg('Unexpected undefined label ('+sLabel+') in instruction line!');
          End;
        End;
      End;
    End;
  If sDirective<>'' Then ProcessPseudo Else
    Begin
    If sMnemo<>'' Then
      Begin { Process an instruction }
      AnalyseCommand;
      ListOutCommand;
      If(pass=2) Then
        Begin
        HexWriteC(pc,w1);
        If Inst.nW=2 Then HexWriteC(pc+1,w2);
        End;
      ncode:=ncode+Inst.nW;
      pc:=pc+Inst.nW;
      End Else
      Begin
      If sMacro<>'' Then
        Begin { Process a macro call }
        If OpenReadMacro(sMacro,pc) Then
          Begin { Set macro parameter }
          If SetMacroParams(nsp,asp) Then
            ListOutLine Else
            Error(68,'','');
          End Else
          Error(70,'','');
        End Else
        ListOutLine; { No instruction, no macro }
      End;
    End;
  End;
End;

Procedure ProcessLine;
Begin
If fMacroDef Or (Not fIfAsm) Then { Inside macro def or if }
  Begin
  If Not fListOff Then
    Writeln(fl,ListGetLine,cl.sLine);
  If fMacroDef Then { line inside macro definition }
    Begin
    ProcessMacroLine;
    End Else With cl Do
    Begin { line inside if }
    Case nDirective Of
      iDirIf:ProcessIf;
      iDirIfDevice:ProcessIfDevice;
      iDirIfDef:ProcessIfDef;
      iDirIfNDef:ProcessIfNDef;
      iDirEndIf:ProcessEndIf;
      iDirElse:ProcessElse;
      iDirElif:ProcessElif;
      End;
    End;
  End Else
  ProcessInstructionLine;
End;

{ -------------- }
{ Process a file }
{ -------------- }
Function ProcessFile(sf:String):Boolean;
Var nl:LongInt;
  fs:Text;
  fh:Boolean;
  be:Byte;
  sLbl:String;
Begin
If FileExists(sf) Then
  Begin
  fWithinDefInclude:=Pos('def.inc',sf)>0;
  spFile:=sf;
  nl:=0;
  nw:=0;
  Assign(fs,sf);
  Reset(fs);
  If Not fQuiet Then Writeln;
  While Not (Eof(fs) Or fExit Or fExitFile) Do { Process lines in file }
    Begin
    Inc(nl);
    If Not (fQuiet Or fAnsiOff) Then Writeln(Char(27),'[1A',GetMsgM(5),nl);
    npLine:=nl;
    Readln(fs,cl.sLine);
    If SplitL(be) Then
      Begin
      ProcessLine;
      fCStyle:=fCStyle Or (cl.sPragma<>'');
      fh:=fListOff;
      fListOff:=fListOff Or (Not fListMac);
      While fHasMacLines Do { Process macro lines, if any }
        Begin
        If ReadGetMacroLine(cl.sLine) Then
          Begin
          If cl.sLine<>'' Then
            Begin
            If SplitL(be) Then
              Begin
              If (pass=1) And (cl.sLabel<>'') Then
                begin
                sLbl:=cl.sLabel+'@'+pcm^.sMacName+'@'+IntToStr(pcm^.nMacUse);
                If Not AddSymbol('L',sLbl,True,ListGetAddressLongInt) Then
                  Error(55,WideString(sLbl),'');
                end;
              cl.sLabel:='';
              ProcessLine;
              End Else
              Error(Byte(70+be),'','');
            End;
          End Else
          If fHasMacLines Then Error(80,'','');
        End;
      fListOff:=fh;
      End Else
      Error(Byte(70+be),'','');
    End;
  If Not fQuiet Then
    Begin
    If Not fAnsiOff Then Write(Char(27),'[1A');
    Writeln(nl,GetMsgM(16));
    Writeln;
    End;
  Close(fs);
  fWithinDefInclude:=False;
  fExitFile:=False;
  ProcessFile:=nerr=0;
  End Else
  Error(36,WideString(sf),'');
End;

{ ------------------------------------- }
{ Set all variables for starting a pass }
{ ------------------------------------- }
Procedure ClearForRestart;
Begin
pc:=0;
pe:=0;
pd:=aDevices[nDev].nss;
ncode:=0;
nconstants:=0;
ne:=0;
nd:=0;
cSegm:='C';
fExitFile:=False;
fMacroDef:=False;
fHasMacLines:=False;
ClearAllnUsed;
End;

Procedure OpenListFile; { Start list file }
Begin
fListOff:=fList;
If fListFileOpen Then Close(fl);
If Not fList Then
  Begin
  Assign(fl,sListFile);
  ReWrite(fl);
  Writeln(fl,lHeader);
  For k:=1 To Length(lHeader) Do Write(fl,'-');
  Writeln(fl);
  Writeln(fl,GetMsgM(17),sfn);
  Writeln(fl,GetMsgM(18),sCodeFile);
  Writeln(fl,GetMsgM(19),sEepFile);
  Writeln(fl,GetMsgM(20),GetDateAndTime);
  Writeln(fl,GetMsgM(21),pass);
  fListFileOpen:=True;
  End Else
  If FileExists(sListFile) Then DeleteFile(sListFile);
Assign(fx,sXErrorFile);
ReWrite(fx);
Writeln(fx,lHeader);
For k:=1 To Length(lHeader) Do Write(fx,'-');
Writeln(fx);
Writeln(fx,GetMsgM(17),sfn);
Writeln(fx,GetMsgM(18),sCodeFile);
Writeln(fx,GetMsgM(19),sEepFile);
Writeln(fx,GetMsgM(20),GetDateAndTime);
Writeln(fx,GetMsgM(21),pass);
End;

{ ----------- }
{ Do one pass }
{ ----------- }
Function DoPass:Boolean;
Var f:Boolean;
Begin
If Not fQuiet Then
  Begin
  Writeln('-------');
  Writeln(GetMsgM(21),pass);
  End;
OpenListFile;
If pass=2 Then
  HexOpenFiles(sCodeFile,sEepFile,ne);
ClearForRestart;
f:=ProcessFile(sfn);
With aDevices[nDev] Do
  Begin
  If pc>((nf Div 2)+1) Then Error(81,IntToWideStr(pc),IntToWideStr(nf Div 2));
  If (pe>ne) And (Not fEepromErr) Then Error(82,IntToWideStr(pe),IntToWideStr(ne));
  If (pd-nss)>ns Then Warning(False,5,IntToWideStr(pd-nss),IntToWideStr(ns));
  End;
If Not IfClear Then
  Error(99,'','');
If fMacroDef Then
  Error(103,'','');
If nErr>0 Then
  Writeln(fx,GetMsgM(35),nerr,GetMsgM(37));
Close(fx);
If nErr=0 Then DeleteFile(sXErrorFile);
DoPass:=f And (nErr=0);
End;

Function GetDate(s:String):Int64;
begin
GetDate:=10*(Byte(s[1])-48)+(Byte(s[2])-48);
end;

Function GetDateInt(c:Char):Int64;
begin
Case c Of
  'Y':GetDateInt:=GetDate(FormatDateTime('YY',Now()));
  'M':GetDateInt:=GetDate(FormatDateTime('MM',Now()));
  'D':GetDateInt:=GetDate(FormatDateTime('DD',Now()));
  'I':GetDateInt:=Trunc(Now());
  end;
end;

{ ------------ }
{ Main program }
{ ------------ }
Begin
For k:=1 To nHeader Do Writeln(asHeader[k]);
fList:=False;
fListOff:=False; { Set default values }
fListMac:=False;
fBeginner:=False;
fCSeg:=False;
fDSeg:=False;
fESeg:=False;
fFatal:=False;
{$IFDEF LINUX}
fAnsiOff:=False;
{$ELSE}
fAnsiOff:=True;
{$ENDIF}
fExit:=False;
nw:=0;
nDev:=0;
fCStyle:=False;
If GetOptions Then { Get command line options }
  Begin
  Writeln(GetMsgM(22),GetMsgM(17),sfn);
  nerr:=0;
  pass:=1;
  If DoPass Then { Do pass one }
    Begin
    Writeln('Pass 1 ok.');
    nw:=0;
    fCSeg:=False;
    fDSeg:=False;
    fESeg:=False;
    If fDate Then
      begin
      AddSymbol('C','NOW_Y',True,GetDateInt('Y'));
      AddSymbol('C','NOW_M',True,GetDateInt('M'));
      AddSymbol('C','NOW_D',True,GetDateInt('D'));
      AddSymbol('C','NOW_I',True,GetDateInt('I'));
      end;
    pass:=2;
    ClearAllMacroUseCounters;
    If DoPass Then { Do pass two }
      Begin
      If nDev<1 Then
        Warning(False,6,'','');
      If (aDevices[nDev].iSet And hasDoc)<>hasDoc Then
        Warning(False,10,'','');
      If fCStyle Then
        Warning(False,11,'','');
      CheckSymbols;
      If Not fquiet Then { list results on screen }
        Begin
        Writeln;
        If nDev>0 Then
          begin
          Writeln(ncode,GetMsgM(23),nconstants,GetMsgM(24),ncode+nconstants,' =',200.0*(ncode+nconstants)/aDevices[nDev].nf:5:1,'%');
          If (aDevices[nDev].ne>0) And (ne>0) Then
            Writeln(ne,' bytes EEPROM =',100.0*ne/aDevices[nDev].ne:5:1,'%');
          If (aDevices[nDev].ns>0) And (nd>0) Then
            Writeln(nd,' bytes SRAM =',100.0*nd/aDevices[nDev].ns:5:1,'%.');
          end else
          begin
          Writeln(ncode,GetMsgM(23),nconstants,GetMsgM(24),ncode+nconstants);
          If (aDevices[nDev].ne>0) And (ne>0) Then
            Writeln(ne,' bytes EEPROM');
          If (aDevices[nDev].ns>0) And (nd>0) Then
            Writeln(nd,' bytes SRAM');
          end;
        Writeln;
        End;
      Case nw Of
        0:Writeln(GetMsgM(25));
        1:Writeln(GetMsgM(26));
        Else
        Writeln(nw,GetMsgM(27));
        End;
      Writeln(GetMsgM(28),GetMsgM(38));
      If fSymbols Then { Write list of symbols and macros }
        Begin
        ListSymbols;
        ListMacros;
        End;
      If Not fListOff Then { write results to list file }
        Begin
        Writeln(fl);
        Writeln(fl,GetMsgM(29),ncode:8,' words.');
        Writeln(fl,GetMsgM(30),nconstants:8,' words.');
        Writeln(fl,GetMsgM(31),ncode+nconstants:8,' words.');
        Writeln(fl,GetMsgM(32),ne:8,' bytes.');
        Writeln(fl,GetMsgM(33),nd:8,' bytes.');
        Writeln(fl,GetMsgM(28));
        Writeln(fl,GetMsgM(34),GetDateAndTime);
        End;
      HexCloseFiles;
      End;
    End;
  If nerr>0 Then
    Begin { List error messages }
    If nerr=1 Then
      Writeln(GetMsgM(35),GetMsgM(36)) Else
      Writeln(GetMsgM(35),nerr,GetMsgM(37));
    If Not fListOff Then
      Begin
      If fSymbols Then ListSymbols;
      If nerr=1 Then
        Writeln(fl,GetMsgM(35),GetMsgM(36)) Else
        Writeln(fl,GetMsgM(35),nerr,GetMsgM(37));
      End;
    HexDeleteFiles(sCodeFile,sEepFile);
    End;
  If fListFileOpen Then Close(fl); { Close list file }
  ClearSymbols; { Clear lists of symbols and macros }
  CloseAllMacros;
  End;
If fFatal Then
  Halt(2) Else
  Begin
  If nerr>0 Then
    Halt(1) else
    Halt(0);
  end;
End.
