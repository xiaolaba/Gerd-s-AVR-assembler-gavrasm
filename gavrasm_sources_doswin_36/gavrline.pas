{ processes a line of asm code,
  introduced with gavrasm version 1.5,
  last changed: 20.12.2011
}
Unit gavrline;

Interface

Uses Crt,SysUtils,gavrinst,gavrlang;

Const
  iDirByte=1;
  iDirCseg=2;
  iDirDb=3;
  iDirDef=4;
  iDirDevice=5;
  iDirDseg=6;
  iDirDw=7;
  iDirElif=8;
  iDirElse=9;
  iDirEndIf=10;
  iDirEqu=11;
  iDirError=12;
  iDirEseg=13;
  iDirExit=14;
  iDirIf=15;
  iDirIfDef=16;
  iDirIfDevice=17;
  iDirIfNDef=18;
  iDirInclude=19;
  iDirMessage=20;
  iDirList=21;
  iDirListMac=22;
  iDirMacro=23;
  iDirEndMacro=24;
  iDirEndM=25;
  iDirNoList=26;
  iDirOrg=27;
  iDirSet=28;
  iDirSetGlobal=29;
  iDirUndef=30;

Type
  TLine=Record
    sLine:String; { the processed line }
    lc:Byte; { comment position }
    ll:Byte; { length of that line }
    pInst:Byte; { Position the command starts with }
    sLabel:String; { the label on that line, if any }
    sDirective:String; { name of the directive, if any }
    nDirective:LongInt; { number of directive, 0 if none, -1 if error }
    sMnemo:String; { the mnemonic, if any }
    sPragma:String; { #pragma line }
    sMacro:String; { a macro call, if any }
    sString:String; { a string in brackets, if any }
    sComment:String; { the comment, if any }
    asp:Array[1..50] Of String; { the parameters, if any }
    nsp:Byte; { number of parameters }
    End;

Var
  cl:TLine;
  Inst:TInstruction;

Function SplitL(Var be:Byte):Boolean;
Procedure ListDirectives;

Implementation

Type
  TDirective=Record
    sName:String;
    nParam:Integer;
    End;

Const
  cTab=Char(9);
  nDirectives=30;
  aDir:Array[1..nDirectives] Of TDirective = (
    {1} (sName:'BYTE';nParam:1),
    {2} (sName:'CSEG';nParam:0),
    {3} (sName:'DB';nParam:255),
    {4} (sName:'DEF';nParam:1),
    {5} (sName:'DEVICE';nParam:1),
    {6} (sName:'DSEG';nParam:0),
    {7} (sName:'DW';nParam:-1),
    {8} (sName:'ELIF';nParam:1),
    {9} (sName:'ELSE';nParam:0),
    {10} (sName:'ENDIF';nParam:0),
    {11} (sName:'EQU';nParam:1),
    {12} (sName:'ERROR';nParam:1),
    {13} (sName:'ESEG';nParam:0),
    {14} (sName:'EXIT';nParam:-1),
    {15} (sName:'IF';nParam:1),
    {16} (sName:'IFDEF';nParam:1),
    {17} (sName:'IFDEVICE';nParam:1),
    {18} (sName:'IFNDEF';nParam:1),
    {19} (sName:'INCLUDE';nParam:1),
    {20} (sName:'MESSAGE';nParam:1),
    {21} (sName:'LIST';nParam:0),
    {22} (sName:'LISTMAC';nParam:0),
    {23} (sName:'MACRO';nParam:1),
    {24} (sName:'ENDMACRO';nParam:0),
    {25} (sName:'ENDM';nParam:0),
    {26} (sName:'NOLIST';nParam:0),
    {27} (sName:'ORG';nParam:1),
    {28} (sName:'SET';nParam:1),
    {29} (sName:'SETGLOBAL';nParam:255),
    {30} (sName:'UNDEF';nParam:1));
    
Procedure ListDirectives;
Var k:Byte;
  c:Char;
Begin
c:=' ';
Writeln;
Writeln(GetMsgM(61));
If c=' ' Then For k:=1 To nDirectives Do
  Begin
  If (k Mod 20)=0 Then
    Begin
    Write('  Continue ... ');
    c:=UpCase(Readkey);
    Writeln;
    Writeln(GetMsgM(61));
    End;
  Writeln(GetMsgM(61+k));
  End;
End;

Function LegalLabelChar(c:Char):Boolean;
Begin
Case UpCase(c) Of
  'A'..'Z','0'..'9','_',':','.',Char(128)..Char(255):LegalLabelChar:=True;
  Else
  LegalLabelChar:=False;
  End;
End;

Function LegalInstructionChar(c:Char):Boolean;
Begin
Case UpCase(c) Of
  'A'..'Z','0'..'9','.','_':LegalInstructionChar:=True;
  Else
  LegalInstructionChar:=False;
  End;
End;

Function SeparatorChar(c:Char):Boolean;
Begin
SeparatorChar:=(c=' ') Or (c=cTab);
End;

Procedure GetOverString(Var k:Byte;Var be:Byte);
Begin
With cl Do
  Begin
  Inc(k);
  sString:='';
  Repeat
    While (k<=lc) And (sLine[k]<>'"') Do
      Begin
      sString:=sString+sLine[k];
      Inc(k);
      End;
    If ((k+1)<=lc) And (sLine[k+1]='"') Then
      Begin
      sString:=sString+'"';
      k:=k+2;
      End;
    Until (k>lc) Or (sLine[k]='"');
  Inc(k);
  If (k<=lc) And (sLine[k-1]<>'"') Then be:=1;
  End;
End;

Procedure GetOverLiteral(Var k:Byte;Var be:Byte);
Begin
With cl Do
  Begin
  If (k+2)>ll Then { Literal exceeds line end }
    be:=2 Else
    Begin
    Case sLine[k+1] Of
      '\':Begin { \ char is ASCII control char }
        If (k+3)>ll Then be:=2 Else { exceeds line end }
          Begin
          If sLine[k+3]='''' Then { check correct sceond ' }
            k:=k+4 Else
            be:=5;
          End;
        End;
      '''':Begin { ' char for a hard ' }
        If (k+3)>ll Then be:=2 Else { exceeds end of line }
          Begin
          If (sLine[k+2]='''') And (sLine[k+3]='''') Then { '''' }
            k:=k+4 Else
            be:=4;
          End;
        End;
      Else
      If sLine[k+2]='''' Then { check correct second ' }
        k:=k+3 Else
        be:=5;
      End;
    End;
  End;
End;

Procedure GetCommentPosition(Var be:Byte);
Begin
With cl Do
  Begin
  lc:=1;
  While (lc<=ll) And (sLine[lc]=' ') And (sLine[lc]=cTab) Do Inc(lc);
  If lc<=ll Then
    begin 
    lc:=1;
    Repeat
      Case sLine[lc] Of
        ';':;
        '''':GetOverLiteral(lc,be);
        '"':GetOverString(lc,be);
        Else
        Inc(lc);
        End;
      Until (lc>ll) Or (sLine[lc]=';') Or (be<>0);
    If (lc<=ll) And (sLine[lc]=';') Then sComment:=Copy(sLine,lc,255);
    end else
    begin
    sComment:=sLine;
    lc:=1;
    end;
  End;
End;

Procedure GetParameters(k:Byte;Var be:Byte);
Var j,ke:Byte;
  s:String;
Begin
With cl Do
  Begin
  While (k<lc) And SeparatorChar(sLine[k]) Do Inc(k);
  If k<lc Then
    Begin
    ke:=lc;
    Repeat Dec(ke) Until (ke=k) Or ((sLine[ke]<>' ') And (sLine[ke]<>cTab));
    Inc(ke);
    s:='';
    While (be=0) And (k<ke) Do
      Begin
      Case sLine[k] Of
        '''':Begin
          j:=k;
          GetOverLiteral(j,be);
          s:=s+Copy(sLine,k,j-k);
          k:=j;
          End;
        '"':Begin
          j:=k;
          GetOverString(j,be);
          s:=s+Copy(sLine,k,j-k);
          k:=j;
          End;
        ',':Begin
          Inc(nsp);
          asp[nsp]:=s;
          s:='';
          Inc(k);
          End;
        ' ':Inc(k);
        Else
        s:=s+UpCase(sLine[k]);
        Inc(k);
        End;
      End;
    If s<>'' Then
      Begin
      Inc(nsp);
      asp[nsp]:=s;
      End;
    End;
  End;
End;

Procedure GetInstruction(k:Byte;Var be:Byte);
Begin
With cl Do
  Begin
  inst.sM:=sMnemo;
  If Not FindInstructionFromMnemonic(inst) Then
    Begin
    sMacro:=inst.sM;
    inst.sM:='';
    sMnemo:='';
    End;
  GetParameters(k,be);
  End;
End;

Procedure GetDirective(Var k,be:Byte);
Var n:Byte;
Begin
With cl Do
  Begin
  n:=0;
  Repeat Inc(n) Until (n>nDirectives) Or (aDir[n].sName=sDirective);
  If n>nDirectives Then nDirective:=-1 Else nDirective:=n;
  GetParameters(k,be);
  If be=0 Then
    Begin
    Case aDir[nDirective].nParam Of
      -1:;
      0:If nsp<>0 Then be:=20;
      1:Begin
        If nsp=0 Then be:=21;
	If nsp>1 Then be:=20;
	End; 
      255:If nsp<1 Then be:=21;
      End;
    End;
  End;
End;

Function SplitL(Var be:Byte):Boolean;
Var k,ka:Byte;
  s:String;
Begin
be:=0;
ClearInstruction(Inst);
With cl Do
  Begin
  ll:=Length(sLine);
  lc:=ll+1;
  pInst:=1;
  sLabel:='';
  sDirective:='';
  nDirective:=0;
  sMnemo:='';
  sPragma:='';
  sMacro:='';
  sComment:='';
  For k:=1 To 50 Do asp[k]:='';
  nsp:=0;
  If ll>0 Then
    Begin
    GetCommentPosition(be);
    If be=0 Then
      Begin
      ka:=1;
      While (ka<lc) And (sLine[ka]=' ') Or (sLine[ka]=Char(cTab)) Do Inc(ka);
      k:=ka;
      If sLine[ka]='#' Then
        sPragma:=Copy(sLine,ka,255) Else
        Begin
        While (k<lc) And LegalLabelChar(sLine[k]) Do Inc(k);
        s:=UpperCase(Copy(sLine,ka,k-ka));
        If (s='') And (sLine[ka]<>';') And (Not LegalLabelChar(sLine[ka])) Then be:=9;
        If (be=0) And (s<>'') And (s[Length(s)]=':') Then
          Begin
          sLabel:=Copy(s,1,Length(s)-1);
          ka:=k;
          While (ka<lc) And ((sLine[ka]=' ') Or (sLine[ka]=Char(cTab))) Do Inc(ka);
          k:=ka;
          While (k<lc) And LegalLabelChar(sLine[k]) Do Inc(k);
          s:=UpperCase(Copy(sLine,ka,k-ka));
          If (s<>'') And (s[Length(s)]=':') Then be:=7;
          End;
        If (s<>'') And (be=0) Then
          Begin
          If s[1]='.' Then
            Begin
            sDirective:=Copy(s,2,255);
            GetDirective(k,be);
            End Else
            Begin
            pInst:=ka;
            sMnemo:=s;
            GetInstruction(k,be);
            End;
          End;
        End;
      End;
    End;
  End;
SplitL:=be=0;
End;

Begin
End.
