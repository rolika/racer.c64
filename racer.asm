*=      $c000           ;sys49152

;képernyőmemőria fontos helyei
frstpg= $0400           ;képernyő-memória kezdete (első lapja)
lastpg= $0700           ;képernyő memőria utolsó lapja
row=    $0720           ;20. sor eleje (1824)
;zero page címek
trckps= $f7             ;út bal oldalának pozíciója
actp=   $f9             ;aktuális lap
actp40= $fb             ;aktuális lap + egy sor
;karakterkódok
crlft=  $9d             ;kurzor balra (ascii)
crrgt=  $1d             ;kurzor jobbra
car=    $01             ;nagy a betű (screen-kód)
fence=  $09             ;nagy i mint út széle
;véletlenszámhoz
frehi3= $d40f           ;véletlen-
vcreg3= $d412           ;számhoz
sigvol= $d418           ;kellenek
random= $d41b           ;itt lesz a véletlenszám
;egyebek
tod=    $dc08           ;time-of-day óra tizedmásodpercei
kbblen= $c6             ;bill-puffer hossza (nullázáshoz)
getin=  $ffe4           ;egy karakter akkuba (ascii, a,x használja)

;beállítások
        jsr rdinit      ;véletlenszám-generátor inicializálása
        lda #$0f        ;első pályaelem (low byte)
        sta trckps
        lda #>frstpg
        sta trckps+1    ;pályaelem high byte-ja
        lda #$14        ;újraindítás esetén
        sta carpos      ;a kocsi kezdőpozícióját
        lda #$00        ;bill-puffer üres
        sta kbblen
        ldx #$00        ;pályaelem-számláló indexe

;rajtegyenes
        ldy #$18        ;képernyő magassága
        lda #fence      ;útszéle-jel
loop1   sta frstpg+$0f  ;bal oldalon 15.,
        sta frstpg+$19  ;jobb oldalon 25. helyen
        jsr scrdwn      ;képernyő le
        dey             ;egyenes út
        bne loop1       ;lefelé egy képernyőn keresztül
        jsr drwcar

;játékciklus
gamlop  jsr getin       ;bekér egy billentyűt
        beq drwtrck     ;ha nincs, gördül a pálya
        cmp #crlft      ;bal kurzor?
        beq toleft      ;balra
        cmp #crrgt      ;jobb kurzor?
        beq torght      ;jobbra
        jmp gamlop      ;ha egyik sem, vissza

;kirajzolja az út egy elemét
drwtrck inx             ;pályaelemszámlálót növel
        cpx #$19        ;ha eléri a 25-öt (egy képernyő után)
        bne cont
        dec wid         ;eggyel csökkenti az útszélességet,
        ldx #$00        ;és kinullázza a számlálót
cont    jsr rnddir
        ldy #$00
        lda #fence      ;akku=útszéle
        sta (trckps),y  ;kirajzol
        ldy wid
        sta (trckps),y  ;másik oldal is kirajzol
        jsr delay       ;késleltet
        jsr scrdwn      ;gördít
        jmp gamlop

;balra megy a kocsi
toleft  ldy carpos
        cpy #$00        ;képernyő bal széle?
        beq gamlop      ;ha igen, vár új gombra
        lda #$20        ;a=szóköz
        sta row,y       ;kitörli az autót
        dec carpos      ;eggyel balra
        jsr drwcar
        jmp gamlop      ;vár tovább

;jobbra megy a kocsi
torght  ldy carpos
        cpy #$27        ;képernyő jobb széle?
        beq gamlop      ;ha igen, vár új gombra
        lda #$20        ;a=szóköz
        sta row,y       ;kitörli az autót
        inc carpos      ;itt jobbra megy
        jsr drwcar
        jmp gamlop
back    rts             ;vége a játéknak

;véletlen útirány
rnddir  lda random      ;véletlenszám betölt
        cmp #$6d        ;ha 109-nél
        bcc left        ;kisebb, balra
        cmp #$a6        ;ha 166-nál
        bcs rght        ;nagyobb, jobbra megy az út
        jmp enddir      ;egyébként egyenesen
left    lda trckps      ;pályapoz
        beq rnddir      ;ha bal szélen van, újat kér
        adc #$ff        ;egyébként csökkenti eggyel,
        sta trckps      ;és visszatölt
        jmp enddir
rght    lda trckps      ;pályapoz betölt
        adc wid         ;szélesség hozzáad
        cmp #$28        ;jobb oldalon van?
        beq rnddir      ;ha igen, újat kér
        lda trckps      ;egyébként megint betölt,
        adc #$01        ;hozzáad 1-et
        sta trckps      ;visszarak
enddir  rts             ;visszatér

;autó kirajzolása
drwcar  pha
        tya
        pha
        ldy carpos      ;autó pozíciója
        lda row,y       ;helyén
        cmp #fence      ;kerítés van?
        bne goon
        brk             ;ha igen, vége
goon    lda #car        ;amúgy autót kirajzol
        ldy carpos      ;az aktuális
        sta row,y       ;pozícióba
        pla
        tay
        pla
        rts

;egy sorral lejjebb tolja a képernyőt
scrdwn  pha             ;használt
        tya             ;regiszterek
        pha             ;verembe
        lda #<lastpg    ;zp-k feltöltése
        sta actp
        lda #>lastpg
        sta actp+1
        sta actp40+1
        lda #$28        ;egy sor (40 karakter)
        sta actp40
        ldy #$e8        ;utolsó sor első oszlopa,
loop0   dey             ;mert innen számol vissza
        lda (actp),y    ;kezdő screen-poz a-ba (hátulról),
        cmp #car        ;(autót nem másolja)
        beq itscar
        sta (actp40),y  ;és másol egy sorral lejjebb
        jsr drwcar
itscar  cpy #$00        ;laphatár?
        bne loop0       ;ha nem, folytatja
        lda actp+1      ;aktuális lapcím a-ba
        cmp #>frstpg    ;az utolsó? (valójában az első)
        beq delfrs      ;ha igen, még törli az 1. sort
        dec actp+1      ;ha nem, csökkenti
        dec actp40+1    ;a két lapcímet,
        jmp loop0       ;és folytatja
;szóközök az 1. sorba
delfrs  lda #$20        ;a=szóköz, y= mindig 0, mire ideér
fillsp  sta frstpg,y    ;mire ideér, $0400 lesz
        iny             ;növel
        cpy #$28        ;sor vége?
        bne fillsp      ;ha nem, folytatja
        pla             ;használt
        tay             ;regiszterek
        pla             ;vissza
        rts             ;vége a szubrutinnak

;késleltetés
delay   pha
        lda #$00        ;kinullázza
        sta tod         ;a tizedmásodperceket
wait    lda tod         ;majd be is olvassa
        cmp speed       ;eltelt az idő?
        bne wait        ;ha nem, vár
        pla
        rts

;véletlenszám előkészítése
rdinit  lda #$ff        ;inicializáló, csak egyszer kell hívni
        sta frehi3      ;a sid chip 3. hangjából
        lda #%10000000  ;készít véletlen számot
        sta vcreg3      ;elindítja a 3. hang hullámgenerátorát
        sta sigvol      ;3. hang lehalkít
        rts

;változ(tathat)ó értékek
wid     byte    $0a     ;út szélessége
speed   byte    $01     ;késleltetés tizedmásodpercben
carpos  byte    $14     ;sor közepe (20)
