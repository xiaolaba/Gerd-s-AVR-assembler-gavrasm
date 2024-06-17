{ Processes the instruction set of the different avr types,
  Last changed: 23.07.2011 }
Unit gavrinst;

Interface

Uses gavrdev;

Type
  TInstruction=Record
    sM:String[32];
    c1:Char;
    c2:Char;
    wx:Word;
    cC:Char;
    wT:DWord;
    nW:Byte;
    np:Integer;
    End;

{ Searches an instruction from its menmonic in Instruction.sM,
  returns true and the instruction, if found }
Function FindInstructionFromMnemonic(Var Instruction:TInstruction):Boolean;

{ Clears the instruction set }
Procedure ClearInstruction(Var Inst:TInstruction);

{ Sets the instruction word }
Procedure SetInstSet(w:DWord);

{ Checks instruction valid }
Function CheckInstValid(w:DWord):Boolean;

Implementation

Const
  nInstructions=119;
  aInstruction:Array[1..nInstructions] Of TInstruction=(
    { Menomonic  Param1  Param2  Base hex  Calc    Type      Words }
    (sM:'ADC';   c1:'R'; c2:'R'; wx:$1C00; cC:'1'; wt:0; nW:1; np:2),
    (sM:'ADD';   c1:'R'; c2:'R'; wx:$0C00; cC:'1'; wt:0; nW:1; np:2),
    (sM:'ADIW';  c1:'D'; c2:'6'; wx:$9600; cC:'7'; wT:hasAdiwSbiW; nW:1; np:2),
    (sM:'AND';   c1:'R'; c2:'R'; wx:$2000; cC:'1'; wt:0; nW:1; np:2),
    (sM:'ANDI';  c1:'H'; c2:'8'; wx:$7000; cC:'2'; wt:0; nW:1; np:2),
    (sM:'ASR';   c1:'R'; c2:' '; wx:$9405; cC:'1'; wt:0; nW:1; np:1),
    (sM:'BCLR';  c1:'B'; c2:' '; wx:$9488; cC:'2'; wt:0; nW:1; np:1),
    (sM:'BLD';   c1:'R'; c2:'B'; wx:$F800; cC:'3'; wt:0; nW:1; np:2),
    (sM:'BRBC';  c1:'B'; c2:'1'; wx:$F400; cC:'4'; wt:0; nW:1; np:2),
    (sM:'BRBS';  c1:'B'; c2:'1'; wx:$F000; cC:'4'; wt:0; nW:1; np:2),
    (sM:'BRCC';  c1:'1'; c2:' '; wx:$F400; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRCS';  c1:'1'; c2:' '; wx:$F000; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BREAK'; c1:' '; c2:' '; wx:$9598; cC:' '; wT:hasBreak; nW:1; np:0),
    (sM:'BREQ';  c1:'1'; c2:' '; wx:$F001; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRGE';  c1:'1'; c2:' '; wx:$F404; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRHC';  c1:'1'; c2:' '; wx:$F405; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRHS';  c1:'1'; c2:' '; wx:$F005; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRID';  c1:'1'; c2:' '; wx:$F407; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRIE';  c1:'1'; c2:' '; wx:$F007; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRLO';  c1:'1'; c2:' '; wx:$F000; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRLT';  c1:'1'; c2:' '; wx:$F004; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRMI';  c1:'1'; c2:' '; wx:$F002; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRNE';  c1:'1'; c2:' '; wx:$F401; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRPL';  c1:'1'; c2:' '; wx:$F402; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRSH';  c1:'1'; c2:' '; wx:$F400; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRTC';  c1:'1'; c2:' '; wx:$F406; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRTS';  c1:'1'; c2:' '; wx:$F006; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRVC';  c1:'1'; c2:' '; wx:$F403; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BRVS';  c1:'1'; c2:' '; wx:$F003; cC:'3'; wt:0; nW:1; np:1),
    (sM:'BSET';  c1:'B'; c2:' '; wx:$9408; cC:'2'; wt:0; nW:1; np:1),
    (sM:'BST';   c1:'R'; c2:'B'; wx:$FA00; cC:'3'; wt:0; nW:1; np:2),
    (sM:'CALL';  c1:'X'; c2:' '; wx:$940E; cC:'6'; wT:hasJmpCall; nW:2; np:1),
    (sM:'CBI';   c1:'Q'; c2:'B'; wx:$9800; cC:'5'; wt:0; nW:1; np:2),
    (sM:'CBR';   c1:'H'; c2:'I'; wx:$7000; cC:'2'; wt:0; nW:1; np:2),
    (sM:'CLC';   c1:' '; c2:' '; wx:$9488; cC:' '; wt:0; nW:1; np:0),
    (sM:'CLH';   c1:' '; c2:' '; wx:$94D8; cC:' '; wt:0; nW:1; np:0),
    (sM:'CLI';   c1:' '; c2:' '; wx:$94F8; cC:' '; wt:0; nW:1; np:0),
    (sM:'CLN';   c1:' '; c2:' '; wx:$94A8; cC:' '; wt:0; nW:1; np:0),
    (sM:'CLR';   c1:'R'; c2:' '; wx:$2400; cC:'4'; wt:0; nW:1; np:1),
    (sM:'CLS';   c1:' '; c2:' '; wx:$94C8; cC:' '; wt:0; nW:1; np:0),
    (sM:'CLT';   c1:' '; c2:' '; wx:$94E8; cC:' '; wt:0; nW:1; np:0),
    (sM:'CLV';   c1:' '; c2:' '; wx:$94B8; cC:' '; wt:0; nW:1; np:0),
    (sM:'CLZ';   c1:' '; c2:' '; wx:$9498; cC:' '; wt:0; nW:1; np:0),
    (sM:'COM';   c1:'R'; c2:' '; wx:$9400; cC:'1'; wt:0; nW:1; np:1),
    (sM:'CP';    c1:'R'; c2:'R'; wx:$1400; cC:'1'; wt:0; nW:1; np:2),
    (sM:'CPC';   c1:'R'; c2:'R'; wx:$0400; cC:'1'; wt:0; nW:1; np:2),
    (sM:'CPI';   c1:'H'; c2:'8'; wx:$3000; cC:'2'; wt:0; nW:1; np:2),
    (sM:'CPSE';  c1:'R'; c2:'R'; wx:$1000; cC:'1'; wt:0; nW:1; np:2),
    (sM:'DEC';   c1:'R'; c2:' '; wx:$940A; cC:'1'; wt:0; nW:1; np:1),
    (sm:'DES';   c1:'N'; c2:' '; wx:$940B; cC:'G'; wt:hasDes; nw:1; np:1),
    (sM:'EICALL';c1:' '; c2:' '; wx:$9519; cC:' '; wT:hasEiJmpCall; nW:1; np:0),
    (sM:'EIJMP'; c1:' '; c2:' '; wx:$9419; cC:' '; wT:hasEiJmpCall; nW:1; np:0),
    (sM:'ELPM';  c1:'E'; c2:' '; wx:$9000; cC:'8'; wt:0; nW:1; np:-1),
    (sM:'EOR';   c1:'R'; c2:'R'; wx:$2400; cC:'1'; wt:0; nW:1; np:2),
    (sM:'FMUL';  c1:'J'; c2:'J'; wx:$0308; cC:'F'; wT:hasMulFmul; nW:1; np:2),
    (sM:'FMULS'; c1:'J'; c2:'J'; wx:$0380; cC:'F'; wT:hasMulFMul; nW:1; np:2),
    (sM:'FMULSU';c1:'J'; c2:'J'; wx:$0388; cC:'F'; wT:hasMulFMul; nW:1; np:2),
    (sM:'ICALL'; c1:' '; c2:' '; wx:$9509; cC:' '; wT:hasIJmpICall; nW:1; np:0),
    (sM:'IJMP';  c1:' '; c2:' '; wx:$9409; cC:' '; wT:hasIJmpICall; nW:1; np:0),
    (sM:'IN';    c1:'R'; c2:'P'; wx:$B000; cC:'6'; wt:0; nW:1; np:2),
    (sM:'INC';   c1:'R'; c2:' '; wx:$9403; cC:'1'; wt:0; nW:1; np:1),
    (sM:'JMP';   c1:'X'; c2:' '; wx:$940C; cC:'6'; wT:hasJmpCall; nW:2; np:1),
    (sm:'LAC';   c1:'Z'; c2:'R'; wx:$9206; cC:'G'; wt:hasLac; nw:1; np:2),
    (sm:'LAS';   c1:'Z'; c2:'R'; wx:$9205; cC:'G'; wt:hasLas; nw:1; np:2),
    (sm:'LAT';   c1:'Z'; c2:'R'; wx:$9207; cC:'G'; wt:hasLat; nw:1; np:2),
    (sM:'LD';    c1:'R'; c2:'L'; wx:$900C; cC:'B'; wt:hasLdXY; nW:1; np:2),
    (sM:'LDD';   c1:'R'; c2:'M'; wx:$8008; cC:'8'; wT:hasLdXY; nW:1; np:2),
    (sM:'LDI';   c1:'H'; c2:'8'; wx:$E000; cC:'2'; wt:0; nW:1; np:2),
    (sM:'LDS';   c1:'R'; c2:'W'; wx:$9000; cC:'9'; wT:hasLdXY; nW:2; np:2),
    (sM:'LPM';   c1:'E'; c2:' '; wx:$9000; cC:'8'; wT:hasLpm; nW:1; np:-1),
    (sM:'LSL';   c1:'R'; c2:' '; wx:$0C00; cC:'4'; wt:0; nW:1; np:1),
    (sM:'LSR';   c1:'R'; c2:' '; wx:$9406; cC:'1'; wt:0; nW:1; np:1),
    (sM:'MOV';   c1:'R'; c2:'R'; wx:$2C00; cC:'1'; wt:0; nW:1; np:2),
    (sM:'MOVW';  c1:'K'; c2:'K'; wx:$0100; cC:'F'; wT:hasMovw; nW:1; np:2),
    (sM:'MUL';   c1:'R'; c2:'R'; wx:$9C00; cC:'1'; wT:hasMulFMul; nW:1; np:2),
    (sM:'MULS';  c1:'H'; c2:'H'; wx:$0200; cC:'F'; wT:hasMulFmul; nW:1; np:2),
    (sM:'MULSU'; c1:'J'; c2:'J'; wx:$0300; cC:'F'; wT:hasMulFmul; nW:1; np:2),
    (sM:'NEG';   c1:'R'; c2:' '; wx:$9401; cC:'1'; wt:0; nW:1; np:1),
    (sM:'NOP';   c1:' '; c2:' '; wx:$0000; cC:' '; wt:0; nW:1; np:0),
    (sM:'OR';    c1:'R'; c2:'R'; wx:$2800; cC:'1'; wt:0; nW:1; np:2),
    (sM:'ORI';   c1:'H'; c2:'8'; wx:$6000; cC:'2'; wt:0; nW:1; np:2),
    (sM:'OUT';   c1:'P'; c2:'R'; wx:$B800; cC:'E'; wt:0; nW:1; np:2),
    (sM:'POP';   c1:'R'; c2:' '; wx:$900F; cC:'1'; wT:hasPushPop; nW:1; np:1),
    (sM:'PUSH';  c1:'R'; c2:' '; wx:$920F; cC:'1'; wT:hasPushPop; nW:1; np:1),
    (sM:'RCALL'; c1:'2'; c2:' '; wx:$D000; cC:'5'; wt:0; nW:1; np:1),
    (sM:'RET';   c1:' '; c2:' '; wx:$9508; cC:' '; wt:0; nW:1; np:0),
    (sM:'RETI';  c1:' '; c2:' '; wx:$9518; cC:' '; wt:0; nW:1; np:0),
    (sM:'RJMP';  c1:'2'; c2:' '; wx:$C000; cC:'5'; wt:0; nW:1; np:1),
    (sM:'ROL';   c1:'R'; c2:' '; wx:$1C00; cC:'4'; wt:0; nW:1; np:1),
    (sM:'ROR';   c1:'R'; c2:' '; wx:$9407; cC:'1'; wt:0; nW:1; np:1),
    (sM:'SBC';   c1:'R'; c2:'R'; wx:$0800; cC:'1'; wt:0; nW:1; np:2),
    (sM:'SBCI';  c1:'H'; c2:'8'; wx:$4000; cC:'2'; wt:0; nW:1; np:2),
    (sM:'SBI';   c1:'Q'; c2:'B'; wx:$9A00; cC:'5'; wt:0; nW:1; np:2),
    (sM:'SBIC';  c1:'Q'; c2:'B'; wx:$9900; cC:'5'; wt:0; nW:1; np:2),
    (sM:'SBIS';  c1:'Q'; c2:'B'; wx:$9B00; cC:'5'; wt:0; nW:1; np:2),
    (sM:'SBIW';  c1:'D'; c2:'6'; wx:$9700; cC:'7'; wT:hasAdiwSbiw; nW:1; np:2),
    (sM:'SBR';   c1:'H'; c2:'8'; wx:$6000; cC:'2'; wt:0; nW:1; np:2),
    (sM:'SBRC';  c1:'R'; c2:'B'; wx:$FC00; cC:'3'; wt:0; nW:1; np:2),
    (sM:'SBRS';  c1:'R'; c2:'B'; wx:$FE00; cC:'3'; wt:0; nW:1; np:2),
    (sM:'SEC';   c1:' '; c2:' '; wx:$9408; cC:' '; wt:0; nW:1; np:0),
    (sM:'SEH';   c1:' '; c2:' '; wx:$9458; cC:' '; wt:0; nW:1; np:0),
    (sM:'SEI';   c1:' '; c2:' '; wx:$9478; cC:' '; wt:0; nW:1; np:0),
    (sM:'SEN';   c1:' '; c2:' '; wx:$9428; cC:' '; wt:0; nW:1; np:0),
    (sM:'SER';   c1:'H'; c2:' '; wx:$EF0F; cC:'7'; wt:0; nW:1; np:1),
    (sM:'SES';   c1:' '; c2:' '; wx:$9448; cC:' '; wt:0; nW:1; np:0),
    (sM:'SET';   c1:' '; c2:' '; wx:$9468; cC:' '; wt:0; nW:1; np:0),
    (sM:'SEV';   c1:' '; c2:' '; wx:$9438; cC:' '; wt:0; nW:1; np:0),
    (sM:'SEZ';   c1:' '; c2:' '; wx:$9418; cC:' '; wt:0; nW:1; np:0),
    (sM:'SLEEP'; c1:' '; c2:' '; wx:$9588; cC:' '; wt:0; nW:1; np:0),
    (sM:'SPM';   c1:'M'; c2:' '; wx:$95E8; cC:'5'; wT:hasSpm; nW:1; np:-1),
    (sM:'ST';    c1:'S'; c2:'R'; wx:$920C; cC:'C'; wt:0; nW:1; np:2),
    (sM:'STD';   c1:'T'; c2:'R'; wx:$8208; cC:'D'; wT:hasLdXY; nW:1; np:2),
    (sM:'STS';   c1:'W'; c2:'R'; wx:$9200; cC:'A'; wT:hasLdXY; nW:2; np:2),
    (sM:'SUB';   c1:'R'; c2:'R'; wx:$1800; cC:'1'; wt:0; nW:1; np:2),
    (sM:'SUBI';  c1:'H'; c2:'8'; wx:$5000; cC:'2'; wt:0; nW:1; np:2),
    (sM:'SWAP';  c1:'R'; c2:' '; wx:$9402; cC:'1'; wt:0; nW:1; np:1),
    (sM:'TST';   c1:'R'; c2:' '; wx:$2000; cC:'4'; wt:0; nW:1; np:1),
    (sM:'WDR';   c1:' '; c2:' '; wx:$95A8; cC:' '; wt:0; nW:1; np:0),
    (sm:'XCH';   c1:'Z'; c2:'R'; wx:$9204; cC:'G'; wt:hasXch; nw:1; np:2));

Var
  winst:DWord;
  
Function FindInstructionFromMnemonic(Var Instruction:TInstruction):Boolean;
Var k:Byte;
Begin
FindInstructionFromMnemonic:=False;
With Instruction Do
  Begin
  k:=0;
  Repeat Inc(k) Until (k>nInstructions) Or (aInstruction[k].sM>=sM);
  If (k<=nInstructions) And (aInstruction[k].sM=sM) Then
    Begin
    sM:=aInstruction[k].sM;
    c1:=aInstruction[k].c1;
    c2:=aInstruction[k].c2;
    wx:=aInstruction[k].wx;
    cC:=aInstruction[k].cC;
    wT:=aInstruction[k].wT;
    nW:=aInstruction[k].nW;
    np:=aInstruction[k].np;
    FindInstructionFromMnemonic:=True;
    End;
  End;
End;

Procedure ClearInstruction(Var Inst:TInstruction);
Begin
With Inst Do
  Begin
  sM:='';
  c1:=' ';
  c2:=' ';
  wx:=0;
  cC:=' ';
  wT:=0;
  nW:=0;
  np:=-1;
  End;
End;

{ Sets the instruction word }
Procedure SetInstSet(w:DWord);
Begin
winst:=w;
End;

{ Checks instruction valid }
Function CheckInstValid(w:DWord):Boolean;
Begin
CheckInstValid:=(w And wInst)=w;
End;

Begin
wInst:=$FFFFFF;
End.
