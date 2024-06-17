{ English language source code file
  Exchange gavrlang.pas with this file to
  get the english version of the compiler,
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
{1} '�R�O��W�������ﶵ:',
????{2} '����󥼧��:',
????{3} '���~',
????{4} '�ɮ�: ',
????{5} '�渹: ',
????{6} '���X��: ',
????{7} 'ĵ�i',
????{8} '�Ÿ��C��:',
????{9} '��JnDef nUsed Decimalval Hexvalue Name',
????{10} '�S���Ÿ��w�q',
????{11} '���C��:',
????{12} 'nLines nUsed nParams Name',
????{13} '�S����',
????{14} '�]�A���',
????{15} '�����ɮ�',
????{16} 'Ū������.',
????{17} '�����:',
????{18} '�Q���i�s���:',
????{19} 'EEPROM �ɮ�:',
????{20} '�sĶ����:',
????{21} '�q�L',:
????{22} '�sĶ��',
????{23} '�N�X�r�`',
????{24} '�`�Ʀr�`, �`�� =',
????{25} '�S��ĵ�i!',
????{26} '�@��ĵ�i!',
????{27} 'ĵ�i!',
????{28} '�sĶ����,�S�����~',
????{29} '�{��:',
????{30} '�`��:',
????{31} '�`�{�Ǥ��s:',
????{32} 'EEPROM �Ŷ�:',
????{33} '�ƾڬq:',
????{34} '�sġ��',
????{35} '�J�s����',
????{36} '�@�ӿ��~!',
????{37} '���~',
????{38} '�A��...',
????{39} '�D����  {���ƫ��O�H�s��! },' 
????{40} '\\���O�S���Ѽ�!',
????{41} '�H�s�� R0 - R31',
????{42} '�줸�� 0-7',
????{43} '�۹����a�}�]���ҡ^���d��q-64��+63',
????{44} '�������a�}�]���ҡ^,16/22��a�}',
????{45} '�L�αH�s��, Z �� Z+',
????{46} '�۹����a�}�]���ҡ^�b+/- 2k�d��',
????{47} '�H�s�� R16 - R31',
????{48} '���H�s�� R24,R26,R28��R30',
????{49} '�ݤf�� 0 - 31',
????{50} '�H�s�� R16 - R23',
????{51} '���ƱH�s���]R0,R2 ... R30)',
????{52} '�ݤf�� 0 - 63',
????{53} 'X / Y / Z��X + / Y + / Z +��-X / -Y / -Z',
????{54} 'Y+���� ��Z +����, �d�� 0..63',
????{55}  ',16��SRAM�a�}',
????{56} '�`�q�d�� 0..63',
????{57} '�`�q�d�� 0..255',
????{58} '�Ѽ�',
????{59} '�����sĶ���~!�г��i�� gavrasm@avr-asm-tutorial.net!',
????{60} '�ϥ� gavrasm -d, �d�ݫ��O�C�� ',
????{61} '���O�C��',
????{62} '.BYTE x:�b�ƾڬq���O�dx�Ӧr�`�]�аѾ\.DSEG�^',
????{63} '.CSEG:�sĶ���N�X�q',
????{64} '.DB x,y,z: ���J�줸��, �r��, �r��].CSEG,ESEG�^',
????{65} '.DEF x = y: �Ÿ��W��x ���[��H�s��y',
????{66} '.DEVICE x: �ˬdAVR���� x ���N�X',
????{67} '.DSEG: �ƾڬq,�u�����ҩM .BYTE ���O',
????{68} '.DW x,y,z: ���J�r�`�].CSEG,.ESEG�^',
????{69} '.ELIF x:.ELSE with condition x',
????{70} '.ELSE:���N�N�X,�p�G.IF����false',
????{71} '.ENDIF:����.IF .ELSE��.ELIF',
????{72} '.EQU x = y:�N�Ÿ�x�]�m���`�ƭ�y',
????{73} '.ERROR x:�j��ϥή���x,�o�Ϳ��~',
????{74} '.ESEG:�J�s��Eeprom����,
????{75} '.EXIT [x]:���������,x�O�޿��F��',
????{76} '.IF x:�sĶ�N�X,�p�Gx���u',
????{77} '.IFDEF x:�sĶ�N�X�p�G�ܶqx�Q�w�q',
????{78} '.IFDEVICE type:�p�G�������T,�sĶ�N�X',
????{79} '.IFNDEF x:�p�G�ܶqx���w�q,�h�sĶ�N�X',
????{80} '.INCLUDE x:�N��� path / name,���J�췽���',
????{81} '.MESSAGE x:��ܮ���x',
????{82} '.LIST: �}�ҦC��',
????{83} '.LISTMAC: �C�L����',
????{84} '.MACRO x:�w�q�W��x����',
????{85} '.ENDMACRO: ������e�����w�q�]�Ѩ�.ENDM�^',
????{86} '.ENDM:�P.ENDMACRO�ۦP
????{87} '.NOLIST: �����C��',
????{88} '.ORG x:�NCSEG- / ESEG- / DSEG-�p�ƾ��]�m����x',
????{89} '.SET x = y:�N�ܶq�Ÿ�x�]�m����y',
????{90} '.SETGLOBAL x,y,z:�N�����Ÿ�x,y�Mz������',
????{91} '.UNDEF x: ���w�q�Ÿ�x',
????{92} '�`�q 0..15',
????{93} '���wZ',
    );

  nasw=11;
  asw:Array[1..nasw] Of String[80]=(
    '001: %1 symbol(s) defined, but not used!',
    '002: More than one SET on variables(s)!',
    '003: No legal parameters found!',
    '004: Number of bytes on line is odd, added 00 to fit program memory!',
    '005: Data segment (%1 bytes) exceeds device limit (%2 bytes)!',
    '006: No device defined, no syntax checking!',
    '007: Wrap-around!',
    '008: More than one SET on global variable (%1)!',
    '009: Include defs not necessary, using internal values!',
    '010: Instruction set unclear, no documentation!',
    '011: C-style instructions in file, lines ignored!');

  nase=102;
  ase:Array[1..nase] Of String[80]=(
    '001: Illegal character (%1) in symbol name!',
    '002: Symbol name (%1) is a mnemonic, illegal!',
    '003: Symbol name (%1) not starting with a letter!',
    '004: Illegal character in binary value (%1)!',
    '005: Illegal character in hex value (%1)!',
    '006: Illegal character in decimal value (%1)!',
    '007: Undefined constant, variable, label or device (%1)!',
    '008: Unexpected = in expression, use == instead!',
    '009: Overflow of expression (%1) during shift-left(%2)!',
    '010: Overflow during multiplication (%1) by (%2)!',
    '011: Overflow during addition (%1) and (%2)!',
    '012: Underflow during subtraction (%2) from (%1)!',
    '013: Unknown function %1!',
    '014: Illegal character (%1) in expression!',
    '015: Missing opening bracket in expression!',
    '016: Missing closing bracket in expression!',
    '017: Register value (%1) out of range (%2)!',
    '018: Register value undefined!',
    '019: Register value missing!',
    '020: Port value not valid!',
    '021: Port value (%1) out of range (%2)!',
    '022: Bit value (%1) out of range (0..7)!',
    '023: Label (%1) invalid or out of range (%2)!',
    '024: Constant (%1) out of range (%2)!',
    '025: Expression of constant (%1) unreadable!',
    '026: Constant invalid!',
    '027: %1 instruction can only use -XYZ+, not %2',
    '028: Missing X/Y/Z in %1 instruction!',
    '029: %1 instruction requires Y or Z as parameter, not %2!',
    '030: Displacement (%1) out of range (%2)!',
    '031: Parameter X+d/Y+d missing!',
    '032: ''+'' expected, but ''%1'' found!',
    '033: Register and Z/Z+ expected, but %1 found!',
    '034: Register missing!',
    '035: Illegal instruction (%1) for device type (%2)!',
    '036: Include file (%1) not found!',
    '037: Name of Include file missing!',
    '038: Error in parameter %1 (%2) in directive!',
    '039: Missing "=" in directive!',
    '040: Name (%1) already in use for a %2!',
    '041: Failed resolving right side of equation in EQU/SET/DEF!',
    '042: Missing number of bytes to reserve!',
    '043: Invalid BYTE constant!',
    '044: Too many parameters, expected number of bytes only!',
    '045: Missing ORG adress, no parameters!',
    '046: Origin adress (%1) points backwards in %2!',
    '047: Undefined ORG constant!',
    '048: Too many parameters on ORG line, only adress!',
    '049: No literals allowed in DW directive! Use DB instead!',
    '050: No parameters found, expected words!',
    '051: Expected device name, no name found!',
    '052: Device already defined!',
    '053: Unknown device, run gavrasm -T for a list of supported devices!',
    '054: Too many parameters, expecting device name only!',
    '055: Symbol or register %1 already defined!',
    '056: Cannot set undefined symbol (%1)!',
    '057: Macro (%1) already defined!',
    '058: Too many parameters, expected a macro name only!',
    '059: Closing macro without one open or macro empty!',
    '060: .IF condition missing!',
    '061: Undefined constant/variable in condition, must be set before!',
    '062: Error in condition!',
    '063: Too many parameters, expected one logical condition!',
    '064: .ENDIF without .IF!',
    '065: .ELSE/ELIF without .IF!',
    '066: Illegal directive within %1-segment or macro!',
    '067: Unknown directive!',
    '068: No macro open to add lines!',
    '069: Error in macro parameters!',
    '070: Unknown instruction or macro!',
    '071: String exceeds line!',
    '072: Unexpected end of line in literal constant!',
    '073: Literal constant '''''''' expected, end of line found!',
    '074: Literal constant '''''''' expected, but char <> '' found!',
    '075: Missing second '' in literal constant!',
    '076: '':'' missing behind label or instruction starting in column 1!',
    '077: Double label in line!',
    '078: Missing closing bracket!',
    '079: Line not starting with a label, a directive or a separator!',
    '080: Illegal macro line parameter (should be @0..@9)!',
    '081: Code segment (%1 words) exceeds limit (%2 words)!',
    '082: Eeprom segment (%1 bytes) exceeds limit (%2 bytes)!',
    '083: Missing macro name!',
    '084: Undefined parameter in EXIT-directive!',
    '085: Error in logical expression of the EXIT-directive!',
    '086: Break condition is true, assembling stopped!',
    '087: Illegal literal constant (%1)!',
    '088: Illegal string constant (%1)!',
    '089: String (%1) not starting and ending with "!"',
    '090: Unexpected parameter or trash on end of line!',
    '091: Missing or unknown parameter(s)!',
    '092: Unknown device name (%1)!',
    '093: Definition of basic symbols failed!',
    '094: Definition of Int-Vector-Addresses failed!',
    '095: Definition of symbols failed!',
    '096: Definition of register names failed!',
    '097: Unrecognized include file, use .DEVICE instead!',
    '098: Device doesn''t support Auto-Inc/Dec statement!',
    '099: IF statement without ENDIF!',
    '100: Multiple DEVICE definition!',
    '101: Division by Zero',
    '102: %1 instruction requires Z as parameter, not %2!');

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
