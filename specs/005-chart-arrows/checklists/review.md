# Checklist di Review — FEAT-005 Frecce sul Grafico
**Architettura:** CS6Trader class in `Trader/CS6Trader.mqh`

## AddIndicatorsToChart — primo tick
- [ ] `_IndicatorsOnChart` inizializzato a `false` nel costruttore
- [ ] `AddIndicatorsToChart()` dichiarato tra i metodi privati di CS6Trader
- [ ] Chiamata ad `AddIndicatorsToChart()` come **prima istruzione** di `TradeOnTick()`
- [ ] While loop con rilettura `CHART_WINDOWS_TOTAL` a ogni iterazione (non catturato una sola volta)
- [ ] Condizione di uscita: `CHART_WINDOWS_TOTAL == 1` oppure `guard >= 20` (anti-loop infinito)
- [ ] Inner loop su `ChartIndicatorsTotal` dall'ultimo indice verso 0 per ogni subwindow
- [ ] `ChartIndicatorDelete(ChartID(), w, ChartIndicatorName(ChartID(), w, i))` per ogni indicatore
- [ ] `ChartIndicatorAdd(ChartID(), 0, _hSMA)` — subwindow 0 (grafico prezzi)
- [ ] `ChartIndicatorAdd(ChartID(), 1, _hRSI)` — subwindow 1 (pannello RSI)
- [ ] `ChartRedraw(ChartID())` dopo le due chiamate
- [ ] `_IndicatorsOnChart = true` dopo la prima esecuzione (guard)
- [ ] Log `"INIT | Indicators added to chart N"` emesso una sola volta

## Disegno Frecce
- [ ] `DrawEntryArrow()` usa `OBJPROP_ARROWCODE = 241` (freccia su)
- [ ] `DrawExitArrow()` usa `OBJPROP_ARROWCODE = 242` (freccia giù)
- [ ] `OBJPROP_WIDTH` impostato a `_ArrowSize` (1–5)
- [ ] `OBJPROP_COLOR` impostato a `_ArrowBuyColor` / `_ArrowExitColor`
- [ ] `OBJPROP_SELECTABLE = false` — frecce non selezionabili
- [ ] `OBJPROP_HIDDEN = true` — nascoste dal pannello oggetti
- [ ] `ChartRedraw(0)` chiamata dopo ogni creazione/eliminazione

## Nomi Oggetti
- [ ] Frecce BUY: nome inizia con `"S6_BUY_"`
- [ ] Frecce EXIT: nome inizia con `"S6_EXIT_"`
- [ ] Nessun conflitto con oggetti esistenti (verifica `ObjectFind` prima di `ObjectCreate`)

## Guard ShowArrows
- [ ] `if(!_ShowArrows) return;` all'inizio di `DrawEntryArrow()` e `DrawExitArrow()`
- [ ] Se `ShowArrows=false`, nessun `ObjectCreate()` chiamato

## Label RSI fissi (DrawRsiLevels)
- [ ] `DrawRsiLevels()` chiamata in `Init()` una sola volta
- [ ] `if(!_ShowArrows) return;` all'inizio di `DrawRsiLevels()`
- [ ] Due `OBJ_LABEL` creati: `S6_RSI_ENTRY` e `S6_RSI_EXIT`
- [ ] Posizione: `CORNER_LEFT_UPPER`, `XDISTANCE=10`, `YDISTANCE=30` / `YDISTANCE=55`
- [ ] Font: `"Arial Bold"`, dimensione 14pt
- [ ] Colori: `_ArrowBuyColor` per entry, `_ArrowExitColor` per exit
- [ ] Testo: `"RSI Entry < N"` e `"RSI Exit > N"` con i valori reali dei parametri

## Nomi Oggetti
- [ ] Frecce BUY: nome inizia con `"S6_BUY_"`
- [ ] Frecce EXIT: nome inizia con `"S6_EXIT_"`
- [ ] Label RSI: `"S6_RSI_ENTRY"` e `"S6_RSI_EXIT"`
- [ ] Nessun conflitto con oggetti esistenti (verifica `ObjectFind` prima di `ObjectCreate`)

## DeleteAllArrows — prefissi completi
- [ ] Filtra `"S6_BUY_"`, `"S6_EXIT_"`, `"S6_RECT_"`, `"S6_RLBL_"`, `"S6_RRSI_"`, `"S6_RSI_"`
- [ ] Loop dall'ultimo oggetto all'indice 0 (rimozione sicura durante iterazione)

## Punti di Chiamata
- [ ] `DrawEntryArrow()` chiamata in `OpenPosition()` DOPO `_Trade.Buy()` OK
- [ ] `DrawExitArrow()` chiamata in `ClosePosition()` DOPO `_Trade.PositionClose()` OK
- [ ] `DrawRsiLevels()` chiamata in `Init()` al termine dell'inizializzazione
- [ ] `DeleteAllArrows()` NON chiamata automaticamente — disponibile per pulizia manuale

## Persistenza
- [ ] `DeleteAllArrows()` NON chiamata in `Deinit()` — tutti gli oggetti S6 restano dopo il backtest

## Input / Costruttore
- [ ] 4 nuovi input in `S6_EA.mq5`: `ShowArrows`, `ArrowSize`, `ArrowBuyColor`, `ArrowExitColor`
- [ ] Passati al costruttore `CS6Trader(...)` come ultimi 4 argomenti
- [ ] Inizializzati come membri privati nel costruttore
