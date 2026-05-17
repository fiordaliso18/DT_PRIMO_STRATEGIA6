# Checklist di Review — FEAT-004 Reporting CSV e Journal
**Architettura:** CS6Trader class in `Trader/CS6Trader.mqh`

## Esportazione CSV (WriteTradesToCSV)
- [ ] `FileIsExist(filename, FILE_COMMON)` per rilevare prima esecuzione
- [ ] Prima esecuzione: `FileOpen(FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ';')` + intestazione + `FileClose()`
- [ ] Append: `FileOpen(FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ';')`
- [ ] `FileSize(fh)` → `FileSeek(fh, (long)size, SEEK_SET)` — NON usare `SEEK_END` (non supportato in FILE_CSV)
- [ ] Separatore run `=== RUN ... ===` scritto a ogni esecuzione (non condizionato a fileSize)
- [ ] File scritto in `FILE_COMMON` → cartella `%PUBLIC%\Documents\MetaTrader 5\MQL5\Files\`
- [ ] Intestazione e righe scritte con `FileWrite(fh, col1, col2, ...)` — il separatore `;` è definito nell'apertura FILE_CSV
- [ ] `FileClose()` chiamata dopo la scrittura
- [ ] Gestione errore su `INVALID_HANDLE` con `Log("ERROR | CSV open failed")`

## Riga TOTALE e Istogramma
- [ ] Riga TOTALE scritta dopo il loop trade (lotti totali, profit totale, durata media, n. trade)
- [ ] Istogramma scritto solo se `tradeNum > 1`
- [ ] 10 bucket dinamici su range [minProfit, maxProfit]
- [ ] Barra ASCII `#` scalata su 20 caratteri rispetto al bucket più frequente

## Filtro Deal
- [ ] Filtro su `DEAL_MAGIC == _MagicNumber`
- [ ] Filtro su `DEAL_SYMBOL == _Symbol`
- [ ] Filtro su `DEAL_ENTRY == DEAL_ENTRY_OUT` (solo uscite)

## Coppia Entrata/Uscita
- [ ] Ricerca deal di entrata via `DEAL_POSITION_ID` condiviso
- [ ] Filtro su `DEAL_ENTRY == DEAL_ENTRY_IN` per il deal di entrata
- [ ] `entryDt` e `entryPx` valorizzati correttamente prima di `FileWrite()`

## Profitto Netto
- [ ] `profit = DEAL_PROFIT + DEAL_SWAP + DEAL_COMMISSION`
- [ ] Non usare solo `DEAL_PROFIT` (escluderebbe swap e commissioni)

## Motivo di Chiusura
- [ ] Check `DEAL_REASON_SL` → "SL"
- [ ] Euristica timeout: `barsHeld = iBarShift(entryDt) - iBarShift(exitDt)` → se `barsHeld >= _MaxDays` → "TIMEOUT"
- [ ] `DurationDays` nel CSV rimane in giorni solari (informativo); solo il criterio TIMEOUT usa barre D1
- [ ] Default → "RSI_EXIT"
- [ ] Nessun trade con Reason vuota o "S6 entry"

## Statistiche Aggregate (CalcStats)
- [ ] `CalcStats()` calcola winRate, PF, `_MaxDrawdown`, avgDays correttamente
- [ ] `_MaxDrawdown` aggiornato in `UpdateDrawdown()` ad ogni barra
- [ ] `_EquityHigh` usato come high water mark (aggiornato solo al rialzo)

## Logging
- [ ] `Log("FINAL REPORT | Trades: N | WR: X% | PF: Y | MaxDD: Z% | AvgDays: W")`
- [ ] `Log("CSV | S6_trades.csv | N trades written")`
- [ ] Tutti i log tramite `Log()` con prefisso `[S6]`
- [ ] Events operativi tramite `Notify()` → `_Reporter.FileReport()` su `S6_events.csv`

## Integrazione
- [ ] `GenerateFinalReport()` chiamata da `S6_EA.mq5::OnDeinit()`
- [ ] `UpdateDrawdown()` + `CalcStats()` + `Comment()` chiamati in `TradeOnBar()` ad ogni nuova barra
- [ ] `_MagicNumber` usato nel filtro — non variabile globale
