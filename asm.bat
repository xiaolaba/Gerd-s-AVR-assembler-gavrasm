prompt xiao$G 

set ac=C:\WinAVR-20100110
set inc=C:\WinAVR-20100110\avr\include\avr
path %ac%\bin;%ac%\utils\bin;%inc%;%path%
cls


set CHANNEL=4ch
::set CHANNEL=1ch


set MCU=atmega328p
::set COMPORT=COM8
::set BAUD=115200

::set MCU=atmega168p
::set COMPORT=COM7
::set BAUD=250000

set main=twoMHz_square_wave_asm

set HEX=%main%_%MCU%_%CHANNEL%.hex
set LST=%main%_%MCU%_%CHANNEL%.lst
set ASM=%main%_%MCU%_%CHANNEL%.asm
set PCB=arduino



::gavrasm_cht.exe %main%.asm
gavrasm_en_4.5.exe %main%.asm

pause



del %main%.out


:end

REM burn firmware to Nano, Nano has bootloader burned
::avrdude -v -p %MCU% -c %PCB% -P %COMPORT% -b %BAUD% -D -Uflash:w:%HEX%:a


REM burn firmware by usbtiny, Nano chip is empty
:::: burn hex
::avrdude -c usbtiny -p %MCU% -U flash:w:%HEX%:a -U lfuse:w:%lfuse%:m  -U hfuse:w:%hfuse%:m -U lock:w:%lock%:m

avrdude -c usbtiny -p %MCU% -U flash:w:%main%.hex:a



pause

