# Checklist di Review — FEAT-002 Logica di Uscita
**Architettura:** CS6Trader class in `Trader/CS6Trader.mqh`

## Correttezza Funzionale
- [ ] `CS6Trader::CheckExitConditions()` chiamata PRIMA di `CheckEntryConditions()` in `TradeOnBar()`
- [ ] Priorità corretta: RSI_EXIT > TIMEOUT (l'if `_RsiVal` è prima dell'if `_EntryTime`)
- [ ] Uscita RSI: `_RsiVal > _RsiExit` (strettamente superiore)
- [ ] Timeout: `daysOpen >= _MaxDays` (uguale o superiore)
- [ ] `_EntryTime` usato per calcolare `daysOpen` — non `TimeCurrent()` standalone

## Stop Loss
- [ ] `slPrice = ask * (1.0 - _SlPercent / 100.0)` — formula corretta
- [ ] Verifica `slPts < (double)minStop` prima di inviare l'ordine
- [ ] SL passato come quarto argomento a `_Trade.Buy(lots, _Symbol, 0, slPrice, 0, "S6 entry")`
- [ ] SL non mai modificato dopo l'apertura

## Identificazione Motivo nel CSV
- [ ] `DEAL_REASON_SL` usato per identificare uscite per stop loss
- [ ] Euristica timeout: `durDays >= _MaxDays - 0.5`
- [ ] Default: `RSI_EXIT` se nessuna delle condizioni precedenti è soddisfatta
- [ ] Colonna "Reason" mai vuota nel CSV

## Logging e Notifiche
- [ ] `Log("CLOSE | RSI_EXIT")` per uscita RSI
- [ ] `Log("INFO | Timeout | Days open: N")` + `Log("CLOSE | TIMEOUT")` per timeout
- [ ] `Log("ERROR | PositionClose failed")` in caso di errore chiusura
- [ ] `Log("SKIP | SL distance X pts < broker min Y")` se SL troppo vicino
- [ ] `Notify("EXIT", ...)` chiama `_Reporter.FileReport()` su `S6_events.csv`

## MQL5 / Architettura
- [ ] `_Trade.PositionClose(_Symbol)` usato — non `OrderClose()` legacy
- [ ] `HistoryDealGetInteger(exitTkt, DEAL_REASON)` castato a `ENUM_DEAL_REASON`
- [ ] `_MaxDays` e `_RsiExit` sono membri privati di `CS6Trader`, non variabili globali
