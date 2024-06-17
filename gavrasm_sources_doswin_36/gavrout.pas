{ outputs hex files for gavrasm }
Unit gavrout;

Interface

{ open the hex files for instructions and EEPROM content }
Procedure HexOpenFiles(sco,seo:String;ne:LongInt);
{ write the instruction word w to the address i in the hex file }
Procedure HexWriteC(i:LongInt;w:Word);
{ write the byte b to the address i in the EEPROM hex file }
Procedure HexWriteE(i:LongInt;b:Byte);
{ close all output files }
Procedure HexCloseFiles;
{ delete the instruction file sc and/or the EEPROM hex file se }
Procedure HexDeleteFiles(sc,se:String);

Implementation
Uses SysUtils;

Var
  fc,fe:Text;
  fco,feo:Boolean;
  sc,se:String;
  qc,qe:Word;
  nc,ne:LongInt;
  ic,ie:LongInt;
  wc,we:Word;
  bb:Byte;

{ open the hex files sc for instructions and se for the EEPROM
  content, if the number of EEPROM bytes in ne is more than 0 }
Procedure HexOpenFiles(sco,seo:String;ne:LongInt);
Begin
Assign(fc,sco);
Rewrite(fc);
fco:=True;
If ne>0 Then
  Begin
  Assign(fe,seo);
  ReWrite(fe);
  feo:=True;
  End Else
  If FileExists(seo) Then DeleteFile(seo);
sc:='';
se:='';
qc:=0;
qe:=0;
nc:=0;
ne:=0;
wc:=0;
we:=0;
ic:=0;
ie:=0;
bb:=$FF;
End;

Function Hex2Char(b:Byte):Char;
Begin
If b>=10 Then Hex2Char:=Char(b+55) Else Hex2Char:=Char(b+48);
End;

Function Byte2Hex(b:Byte):String;
Begin
Byte2Hex:=Hex2Char(b Div 16)+Hex2Char(b Mod 16);
End;

Function Word2Hex(w:Word):String;
Begin
Word2Hex:=Byte2Hex(w Div 256)+Byte2Hex(w Mod 256);
End;

Procedure HexCompleteLine(Var nc:LongInt;Var qc,wc:Word;Var sc:String);
Begin
qc:=256-((qc+nc+(wc Div 256)+(wc Mod 256)) Mod 256);
sc:=':'+Byte2Hex(nc)+Word2Hex(wc)+'00'+sc+Byte2Hex(qc);
nc:=0;
qc:=0;
End;

{ write the instruction word w to the address i in the hex file }
Procedure HexWriteC(i:LongInt;w:Word);
Var bl,bh:Byte;
Begin
If i<>ic Then
  Begin
  If nc>0 Then
    Begin
    HexCompleteLine(nc,qc,wc,sc);
    Writeln(fc,sc);
    sc:='';
    End;
  wc:=(2*i) MOD 65536;
  End;
If 16*(i Div $8000)<>bb Then
  Begin
  If nc>0 Then
    Begin
    HexCompleteLine(nc,qc,wc,sc);
    Writeln(fc,sc);
    sc:='';
    End;
  bb:=16*(i Div $8000);
  Writeln(fc,':02000002'+Byte2Hex(bb)+'00'+Byte2Hex(252-bb));
  End;
ic:=i+1;
bl:=w MOD 256;
bh:=w Div 256;
sc:=sc+Byte2Hex(bl)+Byte2Hex(bh);
nc:=nc+2;
qc:=qc+bl+bh;
If nc=16 Then
  Begin
  HexCompleteLine(nc,qc,wc,sc);
  Writeln(fc,sc);
  sc:='';
  wc:=wc+16;
  End;
End;

{ write the byte b to the address i in the EEPROM hex file }
Procedure HexWriteE(i:LongInt;b:Byte);
Begin
If (i<>ie) And (ne>0) Then
  Begin
  HexCompleteLine(ne,qe,we,se);
  Writeln(fe,se);
  se:='';
  we:=i MOD 65536;
  End;
ie:=i+1;
se:=se+Byte2Hex(b);
ne:=ne+1;
qe:=qe+b;
If ne=16 Then
  Begin
  HexCompleteLine(ne,qe,we,se);
  Writeln(fe,se);
  se:='';
  we:=we+16;
  End;
End;

{ close all output files }
Procedure HexCloseFiles;
Begin
If feo Then
  Begin
  If ne>0 Then
    Begin
    HexCompleteLine(ne,qe,we,se);
    Writeln(fe,se);
    se:='';
    End;
  Writeln(fe,':00000001FF');
  Close(fe);
  feo:=False;
  End;
If fco Then
  Begin
  If nc>0 Then
    Begin
    HexCompleteLine(nc,qc,wc,sc);
    Writeln(fc,sc);
    sc:='';
    End;
  Writeln(fc,':00000001FF');
  Close(fc);
  fco:=False;
  End;
End;

{ delete the instruction file sc and/or the EEPROM hex file se }
Procedure HexDeleteFiles(sc,se:String);
Begin
If fco Or feo Then HexCloseFiles;
If FileExists(sc) Then DeleteFile(sc);
If FileExists(se) Then DeleteFile(se);
End;

Begin
fco:=False;
feo:=False;
End.
