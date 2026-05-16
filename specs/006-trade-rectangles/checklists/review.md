# Checklist di Review — FEAT-006 Rettangoli Trade sul Grafico
**Architettura:** CS6Trader class in `Trader/CS6Trader.mqh`

## Guard ShowArrows
- [ ] `if(!_ShowArrows) return;` all'inizio di `DrawTradeRects()`

## Scansione History
- [ ] `HistorySelect(0, TimeCurrent())` prima del loop
- [ ] Filtro su `DEAL_MAGIC == _MagicNumber`
- [ ] Filtro su `DEAL_SYMBOL == _Symbol`
- [ ] Filtro su `DEAL_ENTRY == DEAL_ENTRY_OUT` (solo uscite)
- [ ] Deal di entrata trovato via `DEAL_POSITION_ID` condiviso
- [ ] `if(entryDt == 0) continue;` — skip deal senza entrata corrispondente

## Calcolo RSI
- [ ] RSI entrata: `iBarShift(_Symbol, PERIOD_D1, entryDt, false)` + `CopyBuffer(..., entryShift + 1, ...)`
- [ ] RSI uscita: `iBarShift(_Symbol, PERIOD_D1, exitDt, false)` + `CopyBuffer(..., exitShift + 1, ...)`
- [ ] `_hRSI != INVALID_HANDLE` verificato prima di `CopyBuffer()`
- [ ] Fallback "?" se RSI non disponibile

## Rettangolo (S6_RECT_)
- [ ] `OBJ_RECTANGLE` con `entryDt, priceTop, exitDt, priceBot`
- [ ] `OBJPROP_FILL = true` — riempito
- [ ] `OBJPROP_BACK = true` — dietro alle candele
- [ ] `OBJPROP_COLOR` verde se profit > 0, rosso se profit <= 0
- [ ] Altezza minima: `if(priceTop - priceBot < entryPx * 0.001) priceTop = priceBot + entryPx * 0.001`
- [ ] `ObjectFind` + `ObjectDelete` prima di `ObjectCreate` — nessun duplicato

## Etichetta Profitto (S6_RLBL_)
- [ ] `OBJ_TEXT` a `(exitDt, priceTop)` con `ANCHOR_LEFT_LOWER`
- [ ] Testo: `"+N"` o `"-N"` (profit senza decimali)
- [ ] Font: `"Arial Bold"`, dimensione 9pt
- [ ] Colore: stesso del rettangolo (verde/rosso)

## Etichetta RSI (S6_RRSI_)
- [ ] `OBJ_TEXT` a `(entryDt, priceTop)` con `ANCHOR_LEFT_LOWER`
- [ ] Testo: `"RSI:NN→MM"` (RSI entrata → RSI uscita)
- [ ] Font: `"Arial Bold"`, dimensione 9pt
- [ ] Colore: `clrYellow`

## Nomi Oggetti
- [ ] `S6_RECT_` + suffix (suffix = `TimeToString(exitDt, TIME_DATE | TIME_MINUTES)`)
- [ ] `S6_RLBL_` + suffix — stesso suffix del rettangolo
- [ ] `S6_RRSI_` + suffix — stesso suffix del rettangolo
- [ ] `OBJPROP_SELECTABLE = false` e `OBJPROP_HIDDEN = true` su tutti gli oggetti

## Integrazione
- [ ] `DrawTradeRects()` chiamata da `GenerateFinalReport()` dopo `WriteTradesToCSV()`
- [ ] `ChartRedraw(0)` chiamata al termine del loop
- [ ] `DeleteAllArrows()` include prefissi `S6_RECT_`, `S6_RLBL_`, `S6_RRSI_`
