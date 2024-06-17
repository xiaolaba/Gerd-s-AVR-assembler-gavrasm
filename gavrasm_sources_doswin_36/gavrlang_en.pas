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
    { 1} 'Unknown option on command line: ',
    { 2} 'Source file not found: ',
    { 3} 'Error ',
    { 4} 'File: ',
    { 5} 'Line: ',
    { 6} 'Source line: ',
    { 7} 'Warning ',
    { 8} 'List of symbols:',
    { 9} 'Type nDef nUsed Decimalval  Hexvalue Name',
    {10} 'No symbols defined.',
    {11} 'List of macros:',
    {12} 'nLines nUsed nParams Name',
    {13} '   No macros.',
    {14} 'Including file ',
    {15} 'Continuing file ',
    {16} ' lines done.',
    {17} 'Source file: ',
    {18} 'Hex file:    ',
    {19} 'Eeprom file: ',
    {20} 'Compiled:    ',
    {21} 'Pass:        ',
    {22} 'Compiling ',
    {23} ' words code, ',
    {24} ' words constants, total=',
    {25} 'No warnings!',
    {26} 'One warning!',
    {27} ' warnings!',
    {28} 'Compilation completed, no errors.',
    {29} 'Program             : ',
    {30} 'Constants           : ',
    {31} 'Total program memory: ',
    {32} 'Eeprom space        : ',
    {33} 'Data segment        : ',
    {34} 'Compilation endet ',
    {35} 'Compilation aborted, ',
    {36} 'one error!',
    {37} ' errors!',
    {38} ' Bye, bye ...',
    {39} 'not even', { even register instruction! }
    {40} ' \\ Instruction has no parameters!',
    {41} 'register in the range from R0 to R31',
    {42} 'bit value in the range from 0 to 7',
    {43} 'relative jump adress (label) in the range from -64 to +63',
    {44} 'absolute jump adress (label), 16/22-bit-adress',
    {45} 'none or register and Z or register and Z+',
    {46} 'relative jump adress (label) in the range +/- 2k',
    {47} 'register in the range from R16 to R31',
    {48} 'double register R24, R26, R28 or R30',
    {49} 'lower port value between 0 and 31',
    {50} 'register in the range from R16 to R23',
    {51} 'even register (R0, R2 ... R30',
    {52} 'port value in the range from 0 to 63',
    {53} 'X/Y/Z or X+/Y+/Z+ or -X/-Y/-Z',
    {54} 'Y+distance or Z+distance, range 0..63',
    {55} '16-bit SRAM adress',
    {56} 'Constant in the range 0..63',
    {57} 'Constant in the range 0..255',
    {58} 'parameter',
    {59} 'Internal compiler error! Please report to gavrasm@avr-asm-tutorial.net!',
    {60} 'See the list of directives with gavrasm -d!',
    {61} 'List of supported directives',
    {62} '.BYTE x   : reserves x bytes in the data segment (see .DSEG)',
    {63} '.CSEG     : compiles into the code segment',
    {64} '.DB x,y,z : inserts Bytes, chars or strings (.CSEG, ESEG)',
    {65} '.DEF x=y  : symbol name x is attached to register y',
    {66} '.DEVICE x : check the code for the AVR type x',
    {67} '.DSEG     : data segment, only labels and .BYTE directives',
    {68} '.DW x,y,z : insert words (.CSEG, .ESEG)',
    {69} '.ELIF x   : .ELSE with condition x',
    {70} '.ELSE     : alternative code, if .IF-condition was false',
    {71} '.ENDIF    : closes .IF resp. .ELSE or .ELIF',
    {72} '.EQU x=y  : the symbol x is set to the constant value y',
    {73} '.ERROR x  : forces an error with the message x',
    {74} '.ESEG     : compiles to the Eeprom segment',
    {75} '.EXIT [x] : closes source file, x is a logical expression',
    {76} '.IF x     : compiles the code, if x is true',
    {77} '.IFDEF x  : compiles the code if variable x is defined',
    {78} '.IFDEVICE type: compiles the code if the type is correct',
    {79} '.IFNDEF x : compiles the code if variable x is undefined',
    {80} '.INCLUDE x: inserts the file "path/name" into the source',
    {81} '.MESSAGE x: displays the message x',
    {82} '.LIST     : switches list output on',
    {83} '.LISTMAC  : switches list output for macros on',
    {84} '.MACRO x  : define macro named x',
    {85} '.ENDMACRO : closes the current macro definition (see .ENDM)',
    {86} '.ENDM     : the same as .ENDMACRO',
    {87} '.NOLIST   : switches list output off',
    {88} '.ORG x    : sets the CSEG-/ESEG-/DSEG-counter to value x',
    {89} '.SET x=y  : sets the variable symbol x to the value y',
    {90} '.SETGLOBAL x,y,z: globalize the local symbols x, y and z',
    {91} '.UNDEF x  : undefines the symbol x',
    {92} 'Constant in the range 0..15',
    {93} 'Pointer Z');

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
