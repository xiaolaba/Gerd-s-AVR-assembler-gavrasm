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
{1} '命令行上的未知選項:',
????{2} '源文件未找到:',
????{3} '錯誤',
????{4} '檔案: ',
????{5} '行號: ',
????{6} '源碼行: ',
????{7} '警告',
????{8} '符號列表:',
????{9} '鍵入nDef nUsed Decimalval Hexvalue Name',
????{10} '沒有符號定義',
????{11} '宏列表:',
????{12} 'nLines nUsed nParams Name',
????{13} '沒有宏',
????{14} '包括文件',
????{15} '持續檔案',
????{16} '讀取完成.',
????{17} '源文件:',
????{18} '十六進製文件:',
????{19} 'EEPROM 檔案:',
????{20} '編譯完畢:',
????{21} '通過',:
????{22} '編譯中',
????{23} '代碼字節',
????{24} '常數字節, 總數 =',
????{25} '沒有警告!',
????{26} '一個警告!',
????{27} '警告!',
????{28} '編譯完成,沒有錯誤',
????{29} '程序:',
????{30} '常數:',
????{31} '總程序內存:',
????{32} 'EEPROM 空間:',
????{33} '數據段:',
????{34} '編纂端',
????{35} '彙編中止',
????{36} '一個錯誤!',
????{37} '錯誤',
????{38} '再見...',
????{39} '非偶數  {偶數指令寄存器! },' 
????{40} '\\指令沒有參數!',
????{41} '寄存器 R0 - R31',
????{42} '位元值 0-7',
????{43} '相對跳轉地址（標籤）的範圍從-64到+63',
????{44} '絕對跳轉地址（標籤）,16/22位地址',
????{45} '無或寄存器, Z 或 Z+',
????{46} '相對跳轉地址（標籤）在+/- 2k範圍內',
????{47} '寄存器 R16 - R31',
????{48} '雙寄存器 R24,R26,R28或R30',
????{49} '端口值 0 - 31',
????{50} '寄存器 R16 - R23',
????{51} '偶數寄存器（R0,R2 ... R30)',
????{52} '端口值 0 - 63',
????{53} 'X / Y / Z或X + / Y + / Z +或-X / -Y / -Z',
????{54} 'Y+偏移 或Z +偏移, 範圍 0..63',
????{55}  ',16位SRAM地址',
????{56} '常量範圍 0..63',
????{57} '常量範圍 0..255',
????{58} '參數',
????{59} '內部編譯錯誤!請報告給 gavrasm@avr-asm-tutorial.net!',
????{60} '使用 gavrasm -d, 查看指令列表 ',
????{61} '指令列表',
????{62} '.BYTE x:在數據段中保留x個字節（請參閱.DSEG）',
????{63} '.CSEG:編譯成代碼段',
????{64} '.DB x,y,z: 插入位元組, 字符, 字串（.CSEG,ESEG）',
????{65} '.DEF x = y: 符號名稱x 附加到寄存器y',
????{66} '.DEVICE x: 檢查AVR類型 x 的代碼',
????{67} '.DSEG: 數據段,只有標籤和 .BYTE 指令',
????{68} '.DW x,y,z: 插入字節（.CSEG,.ESEG）',
????{69} '.ELIF x:.ELSE with condition x',
????{70} '.ELSE:替代代碼,如果.IF條件為false',
????{71} '.ENDIF:關閉.IF .ELSE或.ELIF',
????{72} '.EQU x = y:將符號x設置為常數值y',
????{73} '.ERROR x:強制使用消息x,發生錯誤',
????{74} '.ESEG:彙編到Eeprom部分,
????{75} '.EXIT [x]:關閉源文件,x是邏輯表達式',
????{76} '.IF x:編譯代碼,如果x為真',
????{77} '.IFDEF x:編譯代碼如果變量x被定義',
????{78} '.IFDEVICE type:如果類型正確,編譯代碼',
????{79} '.IFNDEF x:如果變量x未定義,則編譯代碼',
????{80} '.INCLUDE x:將文件 path / name,插入到源文件中',
????{81} '.MESSAGE x:顯示消息x',
????{82} '.LIST: 開啟列表',
????{83} '.LISTMAC: 列印巨集',
????{84} '.MACRO x:定義名為x的宏',
????{85} '.ENDMACRO: 關閉當前的宏定義（參見.ENDM）',
????{86} '.ENDM:與.ENDMACRO相同
????{87} '.NOLIST: 關閉列表',
????{88} '.ORG x:將CSEG- / ESEG- / DSEG-計數器設置為值x',
????{89} '.SET x = y:將變量符號x設置為值y',
????{90} '.SETGLOBAL x,y,z:將局部符號x,y和z全局化',
????{91} '.UNDEF x: 未定義符號x',
????{92} '常量 0..15',
????{93} '指針Z',
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
