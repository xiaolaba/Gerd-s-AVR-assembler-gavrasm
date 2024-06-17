
# gavrasm
Originator and credits, http://www.avr-asm-tutorial.net/gavrasm/index_en.html#source, it was down, load my backup

how to compile
download Free Pascal compiler (fpc, see http://www.freepascal.org).  
install FPC, mine is C:\FPC\3.2.2   
invoke FPC in win10, nothing showing up,   
crated batch file run_fp.bat, save to C:\FPC\3.2.2\bin\i386-win32, double click & run FPC IDE explicitly,
in FPC IDE menu, Compile -> Target -> Win32 for i386

download gavrasm_sources_doswin_45.zip source code, unzip C:\FPC\gavrasm_sources_doswin_45 (or version 4.5)
copy your desired language file gavrlang_xx.pas, rename it to gavrlang.pas  
compile or build or make gavrlang.pas, no error
compile or build or make gavrasm.pas, error as following

![圖片](https://github.com/xiaolaba/Gerd-s-AVR-assembler-gavrasm/assets/2533993/b4f8c6d3-8da5-4f20-a0e4-4f5b63687e1b)


failed, gavrasm.pas, V3.6 ok, Ver4.5 & Ver4.6
line 437 Longint2Hex, error 
```
        Writeln('  ',cType,nDefined:6,nUsed:6,iValue:11,Longint2Hex(iValue),' ',sName);
```

```
  C:\FPC\gavrasm_sources_doswin_46\gavrasm.pas （2 個結果）
	行號  437:         Writeln('  ',cType,nDefined:6,nUsed:6,iValue:11,Longint2Hex(iValue),' ',sName);
	行號  512:       Writeln(fl,'        ',Longint2HexN(6,ListGetAddressLongInt+1),'   ',LongInt2HexN(4,w2));
```

refer to gavrasm.pas, there is function LongInt2HexN  
change line 437, add 1 line,
```
        Writeln('  ',cType,nDefined:6,nUsed:6,iValue:11, LongInt2HexN(nUsed,iValue),' ',sName);
```

change line 512, add 1 line to,  
```
    {Writeln(fl,ListGetLineAndAddress,'  ',Longint2HexN(4,w1),'  ',Copy(cl.sLine,cl.pInst,255));}
    Writeln(fl,ListGetLineAndAddress,'  ', LongInt2HexN(4,w1),'  ',Copy(cl.sLine,cl.pInst,255));
```    

compile or build or make gavrasm.pas again,  
gavrasm.exe will be produced  

V4.5 ok, V4.6 still another bug ??  
