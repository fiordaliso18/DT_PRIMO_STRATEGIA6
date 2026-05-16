# Checklist di Review — FEAT-001 Logica di Entrata
**Architettura:** CS6Trader class in `Trader/CS6Trader.mqh`

## Correttezza Funzionale
- [ ] `CS6Trader::IsNewBar()` usa `PERIOD_D1` e confronta con `_LastBarTime`
- [ ] `CS6Trader::CheckWarmup()` calcola minBars = `_SmaPeriod` + `_RsiPeriod` + 1
- [ ] `CS6Trader::ReadIndicators()` legge dalla barra `[1]` (ultima chiusa), non `[0]`
- [ ] `CS6Trader::CheckEntryConditions()` verifica `HasOpenPosition()` per primo
- [ ] Filtro trend: `closePrice > _SmaVal` (strettamente superiore)
- [ ] Filtro RSI: `_RsiVal < _RsiEntry` (strettamente inferiore)
- [ ] `OpenPosition()` usa solo `_Trade.Buy()` — mai `_Trade.Sell()`

## Gestione Mercato Chiuso
- [ ] Controllo `retcode == TRADE_RETCODE_MARKET_CLOSED || retcode == 10018 || err == 4756`
- [ ] `_PendingEntry = true` impostato correttamente
- [ ] In `TradeOnTick()`: gestione `_PendingEntry` PRIMA di chiamare `TradeOnBar()`
- [ ] `_PendingEntry = false` resettato all'inizio di ogni nuova barra in `TradeOnBar()`
- [ ] Throttle retry: `if(now - _LastRetryTime < 3600) return true` — max 1 tentativo/ora
- [ ] `_LastRetryTime` aggiornato prima di ogni tentativo (`_LastRetryTime = now`)

## Recovery al Riavvio
- [ ] `CS6Trader::Init()` scansiona `PositionsTotal()` per `_MagicNumber`
- [ ] `_EntryTime` ripristinato da `POSITION_TIME` della posizione esistente
- [ ] Nessun log duplicato di entrata al riavvio

## Logging e Notifiche
- [ ] `Log()` stampa `[S6] <msg>` tramite `Print()`
- [ ] `Notify()` chiama `_Reporter.FileReport()` per loggare su `S6_events.csv`
- [ ] Log "SIGNAL | Entry conditions met" con valori Close, SMA, RSI
- [ ] Log "ORDER | BUY placed" con Lots e SL
- [ ] Log "RECOVERY | Posizione esistente" in caso di recupero

## MQL5 / Architettura
- [ ] Handle `_hSMA` e `_hRSI` creati in `Init()` e rilasciati in `Deinit()`
- [ ] `ChartIndicatorAdd()` NON chiamato in `Init()` — spostato in `AddIndicatorsToChart()` (primo tick)
- [ ] `_Trade.SetExpertMagicNumber(_MagicNumber)` chiamato in `Init()`
- [ ] `CS6Trader` estende `ATraderRobot` — `TradeOnTick()` e `TradeOnBar()` sono override
- [ ] `S6_EA.mq5` è thin orchestrator: chiama solo `Init()`, `Tick()`, `GenerateFinalReport()`, `Deinit()`
