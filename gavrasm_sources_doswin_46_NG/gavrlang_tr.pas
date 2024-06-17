{ Turkish language source code file
  Exchange gavrlang.pas with this file to
  get the turkish version of the compiler,
  gavrasm version 3.2, last changed 04.10.2017
}
Unit gavrlang;

Interface

Var nMaxErr:Byte;

Function GetMsgM(nem:Byte):WideString;
Function GetMsgW(nem:Byte;s1,s2:WideString):WideString;
Function GetMsgE(nem:Byte;s1,s2:WideString):WideString;

Implementation

Uses gavrline;

Const
  nas=93;
  aas:Array[1..nas] Of WideString=(
    { 1} 'Komut satırında bilinmeyen seçenek: ',
    { 2} 'Kaynak dosyası bulunamadı: ',
    { 3} 'Hata ',
    { 4} 'Dosya: ',
    { 5} 'Satır: ',
    { 6} 'Kaynak satırı: ',
    { 7} 'Uyarı ',
    { 8} 'Sembol listesi:',
    { 9} 'Type nDef nUsed             Decimalval         Hexvalue İsim',
    {10} 'Sembol tanımlanmadı.',
    {11} 'Makro listesi:',
    {12} 'nLines nUsed nParams İsim',
    {13} '   Makro yok.',
    {14} 'Dosyayı içeriyor ',
    {15} 'Dosyaya devam ediyor ',
    {16} ' satırları yapıldı.',
    {17} 'Kaynak dosyası: ',
    {18} '16lık dosya:    ',
    {19} 'Eeprom dosyası: ',
    {20} 'Derlendi:    ',
    {21} 'Geçiş:        ',
    {22} 'Derliyor ',
    {23} ' Kelime kodu, ',
    {24} ' Kelime sabitleri, toplam=',
    {25} 'Uyarı yok!',
    {26} 'Bir uyarı!',
    {27} ' Uyarılar!',
    {28} 'Derleme tamamlandı, hata yok.',
    {29} 'Program             : ',
    {30} 'Sabitler           : ',
    {31} 'Toplam program hafızası: ',
    {32} 'Eeprom alanı        : ',
    {33} 'Veri segmenti        : ',
    {34} 'Derleme bitti ',
    {35} 'Derleme bitiriliyor, ',
    {36} 'bir hata!',
    {37} ' hatalar!',
    {38} ' Güle güle ...',
    {39} 'Çift değil', { çift kayıt komutu! }
    {40} ' \\ Komutun paramteresi yok!',
    {41} 'R0 dan R31 e kadarki aralıkta kayıt',
    {42} '0 dan 7 ye kadarki aralıkta bit değeri',
    {43} '-64 den +63 e kadarki aralıkta relatif atlama (jump) adresi',
    {44} 'mutlak atlama (jump) adresi (etiketi), 16/22-bit-adres',
    {45} 'hiçbiri veya kayıt ve Z veya kayıt ve Z+',
    {46} '+/- 2k aralığında relatif atlama (jump) adresi (etiketi)',
    {47} 'R16 dan R31 e kadarki aralıkta kayıt',
    {48} 'R24, R26, R28 veya R30 tekrarlı kayıt',
    {49} '0 ile 31 aralığında aşağı port değeri',
    {50} 'R16 dan R23 e kadarki aralıkta kayıt',
    {51} 'çift kayıt (R0, R2 ... R30)',
    {52} '0 dan 63 e kadarki aralıkta port değeri',
    {53} 'X/Y/Z veya X+/Y+/Z+ veya -X/-Y/-Z',
    {54} 'Y+mesafe veya Z+mesafe, 0..63 aralığı',
    {55} '16-bit SRAM adresi',
    {56} '0..63 aralığında sabit',
    {57} '0..255 aralığında sabit',
    {58} 'parametre',
    {59} 'Dahili derleyici hatası! Lütfen gavrasm@avr-asm-tutorial.net e raporlayın!',
    {60} 'Direktifler listesini gavrasm -d ile görün!',
    {61} 'Desteklenen direktifler listesi',
    {62} '.BYTE x   : data segmentinde x bayt rezerve eder (bakınız .DSEG)',
    {63} '.CSEG     : kod segmentinde derler',
    {64} '.DB x,y,z : Bayt, karakter veya string sokar (.CSEG, ESEG)',
    {65} '.DEF x=y  : x sembol adı y kaydına iliştirildi',
    {66} '.DEVICE x : AVR x tipi için kodu kontrol et',
    {67} '.DSEG     : veri segmenti, sadece etiketler ve .BYTE direktifleri',
    {68} '.DW x,y,z : kelime sok (.CSEG, .ESEG)',
    {69} '.ELIF x   : x şartıyla .ELSE',
    {70} '.ELSE     : .IF-şartı yanlışsa alternatif kod',
    {71} '.ENDIF    :  .IF resp. .ELSE veya .ELIF i kapatır',
    {72} '.EQU x=y  : x sembolü y sabit değerine set edilir',
    {73} '.ERROR x  : x mesajıyla hataya zorlar',
    {74} '.ESEG     : Eeprom segmentine derler',
    {75} '.EXIT [x] : Kaynak dosyayı kapatır, x burada bir mantık ifadesidir',
    {76} '.IF x     : x doğru ise kodu derler',
    {77} '.IFDEF x  : x değişkeni tanımlı ise kodu derler',
    {78} '.IFDEVICE type: Tip doğruysa kodu derler',
    {79} '.IFNDEF x : x değişkeni tanımlı değilse kodu derler',
    {80} '.INCLUDE x: Kaynağa dosya "yol/isim"ini sokar',
    {81} '.MESSAGE x: x mesajını görüntüler',
    {82} '.LIST     : Liste çıktısını açar',
    {83} '.LISTMAC  : Makrolar için liste çıktısını açar',
    {84} '.MACRO x  : x isimli makroyu tanımla',
    {85} '.ENDMACRO : Mevcut makro tanımlamasını kapatır (.ENDM ye bakınız)',
    {86} '.ENDM     : .ENDMACRO ile aynı',
    {87} '.NOLIST   : Liste çıktısını kapatır',
    {88} '.ORG x    : CSEG-/ESEG-/DSEG-sayaçlarını x değerine atar',
    {89} '.SET x=y  : x değişken sembolünü y değerine atar',
    {90} '.SETGLOBAL x,y,z: Yerel x, y ve z sembollerini globalleştirir',
    {91} '.UNDEF x  : x sembolünü tanım dışına çıkartır',
    {92} '0..15 aralığında sabit',
    {93} 'Z pointerı');

  nasw=11;
  asw:Array[1..nasw] Of WideString=(
    '001: %1 sembol(ler) tanımlandı, fakat kullanılmadı!',
    '002: Değişken(ler) üzerinde birden fazla SET!',
    '003: Uygun bir parametre bulunamadı!',
    '004: Satırdaki bayt sayısı tek, program hafızasına uydurabilmek için 00 eklendi!',
    '005: (%1 bayt) veri segmenti cihaz sınırını (%2 bayt) aşıyor!',
    '006: Herhangi bir cihaz tanımlanmadı, sentaks kontrolü yok!',
    '007: Sarmalanıyor!',
    '008: (%1) global değişkeninde birden fazla SET!',
    '009: Include def ler gerekli değil, dahili değerler kullanılıyor!',
    '010: Komut belirli değil, belge yok!',
    '011: Dosyada C-tarzı komutlar, satırlar dikkate alınmıyor!');

  nase=103;
  ase:Array[1..nase] Of WideString=(
    '001: Sembol adında (%1) uygunsuz karakteri!',
    '002: (%1) sembol ismi mnemonik, uygunsuz!',
    '003: (%1) sembol ismi harf ile başlamıyor!',
    '004: (%1) ondalık değerinde uygunsuz 2lik değer!',
    '005: (%1) ondalık değerinde uygunsuz 16lık değer!',
    '006: (%1) ondalık değerinde uygunsuz karakter!',
    '007: Tanımlanmamış sabit, değişken, etiket veya cihaz (%1)!',
    '008: İfadede beklenmeyen = , onun yerine == kullanın!',
    '009: (%2) yi shift-leftlerken (%1) ifadesinde overflow!',
    '010: (%1) ile (%2) yi çarparken overflow!',
    '011: (%1) ile (%2) yi toplama sırasında overflow!',
    '012: (%2) from (%1) den (%2) yi çıkartma sırasında underflow!',
    '013: Bilinmeyen %1 fonksiyonu!',
    '014: İfadede (%1) uygunsuz karakteri!',
    '015: İfadede kaçırılan açma parantezi!',
    '016: İfadede kaçırılan kapatma parantezi!',
    '017: (%1) kayıt değeri (%2) aralığının dışında!',
    '018: Kayıt değeri tanımlanmamış!',
    '019: Kayıt değeri yok!',
    '020: Port değeri geçerli değil!',
    '021: (%1) port değeri (%2) aralığının dışında!',
    '022: (%1) bit değeri (0..7) aralığının dışında!',
    '023: (%1) etiketi geçersiz veya (%2) aralığının dışında!',
    '024: (%1) sabiti (%2) aralığının dışında!',
    '025: (%1) sabiti ifadesi okunamıyor!',
    '026: Geçersiz sabit!',
    '027: %1 komutu sadece -XYZ+ yi kullanabiliyor, %2 yi değil',
    '028: %1 komutunda kaçırılan X/Y/Z!',
    '029: %1 komutu paramtere olarak Y veya Z yi alıyor, %2 yi değil!',
    '030: (%1) yer değiştirmesi (%2) aralığının dışında!',
    '031: X+d/Y+d parametresi yok!',
    '032: ''+'' bekleniyor, fakat ''%1'' bulundu!',
    '033: Kayıt ve Z/Z+ bekleniyor, fakat %1 bulundu!',
    '034: Kaçırılan kayıt!',
    '035: (%2) cihaz tipi için uymayan komut (%1)!',
    '036: (%1) include dosyası bulunamadı!',
    '037: Include dosyasının ismi yok!',
    '038: Direktifte (%2) verilen %1 paramteresinde hata!',
    '039: Direktifte kaçırılan "="!',
    '040: (%1) ismi %2 için kullanılıyor!',
    '041: EQU/SET/DEF de eşitliğin sağ tarafını çözmede başarısız oldu!',
    '042: Rezerve etmek için kaçırılan bayt sayısı!',
    '043: Geçersiz BYTE sabiti!',
    '044: Çok fazla parametre, sadece bayt sayısı bekleniyor!',
    '045: Kaçırılan ORG adresi, parametre yok!',
    '046: (%1) kaynak adresi %2 de geriye doğru işaretliyor!',
    '047: Tanımlanmayan ORG sabiti!',
    '048: ORG satırında çok fazla parametre, sadece adres!',
    '049: DW emrinde literallere izin verilmiyor! Onun yerine DB kullanın!',
    '050: Parametre bulunamadı, kelime bekleniyor!',
    '051: Cihaz ismi bekleniyor, hernagi bir isim bulunamadı!',
    '052: Cihaz önceden tanımlanmıştı!',
    '053: Bilinmeyen cihaz, desteklenen cihazlar listesi için gavrasm -T komutunu çalıştırın!',
    '054: Çok fazla paramtere, sadece cihaz adı bekleniyor!',
    '055: %1 sembol veya kaydı önceden tanımlanmıştı!',
    '056: Tanımlanamayan (%1) sembolünü set edemedi!',
    '057: (%1) makrosu daha önceden tanımlanmıştı!',
    '058: Çok fazla paramtere, sadece bir makro ismi bekleniyor!',
    '059: Bir tane açık olmadan kapanan makro veya makro boş!',
    '060: .IF şartı yok!',
    '061: Tanımlanmamış şartta sabit/değişken, önceden set edilmeli!',
    '062: Şartta hata!',
    '063: Çok fazla parametre, bir mantık şartı olması lazım!',
    '064: .IF! olmadan .ENDIF',
    '065: .IF! olmadan .ELSE/ELIF',
    '066: %1-segment or makroda uymayan direktif!',
    '067: Bilinmeyen direktif!',
    '068: Satır eklemek için açılan makro yok!',
    '069: Macro parametrelerinde hata!',
    '070: Bilinmeyen komut veya makro!',
    '071: String satırı aşıyor!',
    '072: Literal sabitte beklenmeyen satır sonu!',
    '073: Literal sabit '''''''' olması lazım, satır sonu bulundu!',
    '074: Literal sabit '''''''' olması lazım, fakat char <> '' bulundu!',
    '075: Literal sabitte kaçırılan ikinci ''!',
    '076: '':'' 1. sütunda başlayan komut veya etiketin arkasında kaçırılan!',
    '077: Satırda çift etiket!',
    '078: Kaçırılan parantez kapatması!',
    '079: Satır, direktif veya ayraç etiketle başlamıyor!',
    '080: Uymayan makro satır parametresi (@0..@9 olmalı)!',
    '081: Kod segmenti (%1 kelime) sınırı aşıyor (%2 kelime)!',
    '082: Eeprom segmenti (%1 bayt) sınırı aşıyor (%2 bayt)!',
    '083: Kaçırılan makro adı!',
    '084: EXIT-direktifinde tanımlanmamış parametre!',
    '085: EXIT-direktifinin ifadesinde mantıki hata!',
    '086: Break şartı doğru, assembıllama durduruldu!',
    '087: Uymayan literal sabit (%1)!',
    '088: Uymayan string sabiti (%1)!',
    '089: (%1) stringi "!" ile başlamıyor veya bitmiyor',
    '090: Beklenmeyen parametre veya satır sonunda işe yaramaz şeyler var!',
    '091: Gözden kaçırılan veya bilinmeyen parametre(ler)!',
    '092: Bilinmeyen cihaz adı (%1)!',
    '093: Temel semboller tanımlaması başarısız oldu!',
    '094: Int-Vector-Addresses tanımlaması başarısız oldu!',
    '095: Sembol tanımlaması başarısız oldu!',
    '096: Kayıt isimleri tanımlaması başarısız oldu!',
    '097: Tanınmayan include dosyası, onun yerine .DEVICE kullanın!',
    '098: Cihaz Auto-Inc/Dec ifadesini desteklemiyor!',
    '099: ENDIF olmadan IF ifadesi!',
    '100: Birden fazla CİHAZ tanımı!',
    '101: Sıfıra bölüm',
    '102: %1 komutu Z ye paramtere olarak ihtiyaç duyuyor, %2 ye değil!',
    '103: Open macro definition, use .endm to close!');

Procedure ExchPars(sp,se:WideString;Var s:WideString);
Var p:Byte;
Begin
p:=Pos(sp,s);
If p>0 Then
  Begin
  Delete(s,p,Length(sp));
  Insert(se,s,p);
  End;
End;

Function GetMsg(c:WideChar;nem:Byte;s1,s2:WideString):WideString;
Begin
Case c Of
  'M':GetMsg:=aas[nem];
  'W':GetMsg:=asw[nem];
  'E':GetMsg:=ase[nem];
  End;
ExchPars('%1',s1,GetMsg);
ExchPars('%2',s2,GetMsg);
End;

Function GetMsgW(nem:Byte;s1,s2:WideString):WideString;
Begin
GetMsgW:=GetMsg('W',nem,s1,s2);
End;

Function GetMsgE(nem:Byte;s1,s2:WideString):WideString;
Begin
If nem=0 Then
  GetMsgE:='Forced error: '+WideString(cl.sString) Else
  GetMsgE:=GetMsg('E',nem,s1,s2);
End;

Function GetMsgM(nem:Byte):WideString;
Begin
GetMsgM:=aas[nem];
End;

Begin
nMaxErr:=nase;
End.
