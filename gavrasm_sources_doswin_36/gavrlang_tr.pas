{ Turkish language source code file
  Exchange gavrlang.pas with this file to
  get the turkish version of the compiler,
  gavrasm version 3.2, last changed 13.04.2014
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
  as:Array[1..nas] Of String=(
    { 1} 'Komut satirinda bilinmeyen secenek: ',
    { 2} 'Kaynak dosyasi bulunamadi: ',
    { 3} 'Hata ',
    { 4} 'Dosya: ',
    { 5} 'Satir: ',
    { 6} 'Kaynak satiri: ',
    { 7} 'Uyari ',
    { 8} 'Sembol listesi:',
    { 9} 'Type nDef nUsed Decimalval  Hexvalue Isim',
    {10} 'Sembol tanimlanmadi.',
    {11} 'Makro listesi:',
    {12} 'nLines nUsed nParams Isim',
    {13} '   Makro yok.',
    {14} 'Dosyayi iceriyor ',
    {15} 'Dosyaya devam ediyor ',
    {16} ' satirlari yapildi.',
    {17} 'Kaynak dosyasi: ',
    {18} '16lik dosya:    ',
    {19} 'Eeprom dosyasi: ',
    {20} 'Derlendi:    ',
    {21} 'Gecis:        ',
    {22} 'Derliyor ',
    {23} ' Kelime kodu, ',
    {24} ' Kelime sabitleri, toplam=',
    {25} 'Uyari yok!',
    {26} 'Bir uyari!',
    {27} ' Uyarilar!',
    {28} 'Derleme tamamlandi, hata yok.',
    {29} 'Program             : ',
    {30} 'Sabitler           : ',
    {31} 'Toplam program hafizasi: ',
    {32} 'Eeprom alani        : ',
    {33} 'Veri segmenti        : ',
    {34} 'Derleme bitti ',
    {35} 'Derleme bitiriliyor, ',
    {36} 'bir hata!',
    {37} ' hatalar!',
    {38} ' Guele guele ...',
    {39} 'Cift degil', { cift kayit komutu! }
    {40} ' \\ Komutun paramteresi yok!',
    {41} 'R0 dan R31 e kadarki aralikta kayit',
    {42} '0 dan 7 ye kadarki aralikta bit degeri',
    {43} '-64 den +63 e kadarki aralikta relatif atlama (jump) adresi',
    {44} 'mutlak atlama (jump) adresi (etiketi), 16/22-bit-adres',
    {45} 'hicbiri veya kayit ve Z veya kayit ve Z+',
    {46} '+/- 2k araliginda relatif atlama (jump) adresi (etiketi)',
    {47} 'R16 dan R31 e kadarki aralikta kayit',
    {48} 'R24, R26, R28 veya R30 tekrarli kayit',
    {49} '0 ile 31 araliginda asagi port degeri',
    {50} 'R16 dan R23 e kadarki aralikta kayit',
    {51} 'Cift kayit (R0, R2 ... R30)',
    {52} '0 dan 63 e kadarki aralikta port degeri',
    {53} 'X/Y/Z veya X+/Y+/Z+ veya -X/-Y/-Z',
    {54} 'Y+mesafe veya Z+mesafe, 0..63 araligi',
    {55} '16-bit SRAM adresi',
    {56} '0..63 araliginda sabit',
    {57} '0..255 araliginda sabit',
    {58} 'parametre',
    {59} 'Dahili derleyici hatasi! Luetfen gavrasm@avr-asm-tutorial.net e raporlayin!',
    {60} 'Direktifler listesini gavrasm -d ile goeruen!',
    {61} 'Desteklenen direktifler listesi',
    {62} '.BYTE x   : data segmentinde x bayt rezerve eder (bakiniz .DSEG)',
    {63} '.CSEG     : kod segmentinde derler',
    {64} '.DB x,y,z : Bayt, karakter veya string sokar (.CSEG, ESEG)',
    {65} '.DEF x=y  : x sembol adi y kaydina ilistirildi',
    {66} '.DEVICE x : AVR x tipi icin kodu kontrol et',
    {67} '.DSEG     : veri segmenti, sadece etiketler ve .BYTE direktifleri',
    {68} '.DW x,y,z : kelime sok (.CSEG, .ESEG)',
    {69} '.ELIF x   : x sartiyla .ELSE',
    {70} '.ELSE     : .IF-sarti yanlissa alternatif kod',
    {71} '.ENDIF    :  .IF resp. .ELSE veya .ELIF i kapatir',
    {72} '.EQU x=y  : x sembolue y sabit degerine set edilir',
    {73} '.ERROR x  : x mesajiyla hataya zorlar',
    {74} '.ESEG     : Eeprom segmentine derler',
    {75} '.EXIT [x] : Kaynak dosyayi kapatir, x burada bir mantik ifadesidir',
    {76} '.IF x     : x dogru ise kodu derler',
    {77} '.IFDEF x  : x degiskeni tanimli ise kodu derler',
    {78} '.IFDEVICE type: Tip dogruysa kodu derler',
    {79} '.IFNDEF x : x degiskeni tanimli degilse kodu derler',
    {80} '.INCLUDE x: Kaynaga dosya "yol/isim"ini sokar',
    {81} '.MESSAGE x: x mesajini goeruentueler',
    {82} '.LIST     : Liste ciktisini acar',
    {83} '.LISTMAC  : Makrolar icin liste ciktisini acar',
    {84} '.MACRO x  : x isimli makroyu tanimla',
    {85} '.ENDMACRO : Mevcut makro tanimlamasini kapatir (.ENDM ye bakiniz)',
    {86} '.ENDM     : .ENDMACRO ile ayni',
    {87} '.NOLIST   : Liste ciktisini kapatir',
    {88} '.ORG x    : CSEG-/ESEG-/DSEG-sayaclarini x degerine atar',
    {89} '.SET x=y  : x degisken semboluenue y degerine atar',
    {90} '.SETGLOBAL x,y,z: Yerel x, y ve z sembollerini globallestirir',
    {91} '.UNDEF x  : x semboluenue tanim disina cikartir',
    {92} '0..15 araliginda sabit',
    {93} 'Z pointeri');

  nasw=11;
  asw:Array[1..nasw] Of String=(
    '001: %1 sembol(ler) tanimlandi, fakat kullanilmadi!',
    '002: Degisken(ler) uezerinde birden fazla SET!',
    '003: Uygun bir parametre bulunamadi!',
    '004: Satirdaki bayt sayisi tek, program hafizasina uydurabilmek icin 00 eklendi!',
    '005: (%1 bayt) veri segmenti cihaz sinirini (%2 bayt) asiyor!',
    '006: Herhangi bir cihaz tanimlanmadi, sentaks kontrolue yok!',
    '007: Sarmalaniyor!',
    '008: (%1) global degiskeninde birden fazla SET!',
    '009: Include def ler gerekli degil, dahili degerler kullaniliyor!',
    '010: Komut belirli degil, belge yok!',
    '011: Dosyada C-tarzi komutlar, satirlar dikkate alinmiyor!');

  nase=102;
  ase:Array[1..nase] Of String=(
    '001: Sembol adinda (%1) uygunsuz karakteri!',
    '002: (%1) sembol ismi mnemonik, uygunsuz!',
    '003: (%1) sembol ismi harf ile baslamiyor!',
    '004: (%1) ondalik degerinde uygunsuz 2lik deger!',
    '005: (%1) ondalik degerinde uygunsuz 16lik deger!',
    '006: (%1) ondalik degerinde uygunsuz karakter!',
    '007: Tanimlanmamis sabit, degisken, etiket veya cihaz (%1)!',
    '008: Ifadede beklenmeyen = , onun yerine == kullanin!',
    '009: (%2) yi shift-leftlerken (%1) ifadesinde overflow!',
    '010: (%1) ile (%2) yi carparken overflow!',
    '011: (%1) ile (%2) yi toplama sirasinda overflow!',
    '012: (%2) from (%1) den (%2) yi cikartma sirasinda underflow!',
    '013: Bilinmeyen %1 fonksiyonu!',
    '014: Ifadede (%1) uygunsuz karakteri!',
    '015: Ifadede kacirilan acma parantezi!',
    '016: Ifadede kacirilan kapatma parantezi!',
    '017: (%1) kayit degeri (%2) araliginin disinda!',
    '018: Kayit degeri tanimlanmamis!',
    '019: Kayit degeri yok!',
    '020: Port degeri gecerli degil!',
    '021: (%1) port degeri (%2) araliginin disinda!',
    '022: (%1) bit degeri (0..7) araliginin disinda!',
    '023: (%1) etiketi gecersiz veya (%2) araliginin disinda!',
    '024: (%1) sabiti (%2) araliginin disinda!',
    '025: (%1) sabiti ifadesi okunamiyor!',
    '026: Gecersiz sabit!',
    '027: %1 komutu sadece -XYZ+ yi kullanabiliyor, %2 yi degil',
    '028: %1 komutunda kacirilan X/Y/Z!',
    '029: %1 komutu paramtere olarak Y veya Z yi aliyor, %2 yi degil!',
    '030: (%1) yer degistirmesi (%2) araliginin disinda!',
    '031: X+d/Y+d parametresi yok!',
    '032: ''+'' bekleniyor, fakat ''%1'' bulundu!',
    '033: Kayit ve Z/Z+ bekleniyor, fakat %1 bulundu!',
    '034: Kacirilan kayit!',
    '035: (%2) cihaz tipi icin uymayan komut (%1)!',
    '036: (%1) include dosyasi bulunamadi!',
    '037: Include dosyasinin ismi yok!',
    '038: Direktifte (%2) verilen %1 paramteresinde hata!',
    '039: Direktifte kacirilan "="!',
    '040: (%1) ismi %2 icin kullaniliyor!',
    '041: EQU/SET/DEF de esitligin sag tarafini coezmede basarisiz oldu!',
    '042: Rezerve etmek icin kacirilan bayt sayisi!',
    '043: Gecersiz BYTE sabiti!',
    '044: cok fazla parametre, sadece bayt sayisi bekleniyor!',
    '045: Kacirilan ORG adresi, parametre yok!',
    '046: (%1) kaynak adresi %2 de geriye dogru isaretliyor!',
    '047: Tanimlanmayan ORG sabiti!',
    '048: ORG satirinda cok fazla parametre, sadece adres!',
    '049: DW emrinde literallere izin verilmiyor! Onun yerine DB kullanin!',
    '050: Parametre bulunamadi, kelime bekleniyor!',
    '051: Cihaz ismi bekleniyor, hernagi bir isim bulunamadi!',
    '052: Cihaz oenceden tanimlanmisti!',
    '053: Bilinmeyen cihaz, desteklenen cihazlar listesi icin gavrasm -T komutunu calistirin!',
    '054: cok fazla paramtere, sadece cihaz adi bekleniyor!',
    '055: %1 sembol veya kaydi oenceden tanimlanmisti!',
    '056: Tanimlanamayan (%1) semboluenue set edemedi!',
    '057: (%1) makrosu daha oenceden tanimlanmisti!',
    '058: cok fazla paramtere, sadece bir makro ismi bekleniyor!',
    '059: Bir tane acik olmadan kapanan makro veya makro bos!',
    '060: .IF sarti yok!',
    '061: Tanimlanmamis sartta sabit/degisken, oenceden set edilmeli!',
    '062: sartta hata!',
    '063: cok fazla parametre, bir mantik sarti olmasi lazim!',
    '064: .IF! olmadan .ENDIF',
    '065: .IF! olmadan .ELSE/ELIF',
    '066: %1-segment or makroda uymayan direktif!',
    '067: Bilinmeyen direktif!',
    '068: Satir eklemek icin acilan makro yok!',
    '069: Macro parametrelerinde hata!',
    '070: Bilinmeyen komut veya makro!',
    '071: String satiri asiyor!',
    '072: Literal sabitte beklenmeyen satir sonu!',
    '073: Literal sabit '''''''' olmasi lazim, satir sonu bulundu!',
    '074: Literal sabit '''''''' olmasi lazim, fakat char <> '' bulundu!',
    '075: Literal sabitte kacirilan ikinci ''!',
    '076: '':'' 1. suetunda baslayan komut veya etiketin arkasinda kacirilan!',
    '077: Satirda cift etiket!',
    '078: Kacirilan parantez kapatmasi!',
    '079: Satir, direktif veya ayrac etiketle baslamiyor!',
    '080: Uymayan makro satir parametresi (@0..@9 olmali)!',
    '081: Kod segmenti (%1 kelime) siniri asiyor (%2 kelime)!',
    '082: Eeprom segmenti (%1 bayt) siniri asiyor (%2 bayt)!',
    '083: Kacirilan makro adi!',
    '084: EXIT-direktifinde tanimlanmamis parametre!',
    '085: EXIT-direktifinin ifadesinde mantiki hata!',
    '086: Break sarti dogru, assembillama durduruldu!',
    '087: Uymayan literal sabit (%1)!',
    '088: Uymayan string sabiti (%1)!',
    '089: (%1) stringi "!" ile baslamiyor veya bitmiyor',
    '090: Beklenmeyen parametre veya satir sonunda ise yaramaz seyler var!',
    '091: Goezden kacirilan veya bilinmeyen parametre(ler)!',
    '092: Bilinmeyen cihaz adi (%1)!',
    '093: Temel semboller tanimlamasi basarisiz oldu!',
    '094: Int-Vector-Addresses tanimlamasi basarisiz oldu!',
    '095: Sembol tanimlamasi basarisiz oldu!',
    '096: Kayit isimleri tanimlamasi basarisiz oldu!',
    '097: Taninmayan include dosyasi, onun yerine .DEVICE kullanin!',
    '098: Cihaz Auto-Inc/Dec ifadesini desteklemiyor!',
    '099: ENDIF olmadan IF ifadesi!',
    '100: Birden fazla CIHAZ tanimi!',
    '101: Sifira boeluem',
    '102: %1 komutu Z ye paramtere olarak ihtiyac duyuyor, %2 ye degil!');

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
