# Checklist di Review — FEAT-003 Gestione del Rischio
**Architettura:** CS6Trader class in `Trader/CS6Trader.mqh`

## Formula
- [ ] `riskAmount = ACCOUNT_BALANCE × _RiskPercent / 100` (non equity)
- [ ] `slPoints = (ask - slPrice) / SYMBOL_POINT`
- [ ] `rawLots = riskAmount / (slPoints × tickVal / tickSize)`
- [ ] `lots = MathFloor(rawLots / volStep) × volStep` (arrotondamento per difetto)

## Validazione Dati Broker
- [ ] Controllo `slPoints <= 0`
- [ ] Controllo `tickVal <= 0`
- [ ] Controllo `tickSize <= 0`
- [ ] Controllo `volStep <= 0`
- [ ] Tutti i controlli in un unico `if` con OR (`||`)

## Limiti Broker
- [ ] `lots < volMin` → ritorna 0.0 e logga SKIP
- [ ] `lots > volMax` → riduce a volMax e logga INFO
- [ ] Nessun ordine inviato se `CalculateLots()` ritorna 0.0

## Logging
- [ ] `Log("ERROR | CalculateLots: invalid symbol data")` per dati non validi
- [ ] `Log("SKIP | Lots X below broker minimum Y")` per volume sotto minimo
- [ ] `Log("INFO | Lots capped at broker maximum X")` per volume ridotto

## Integrazione
- [ ] `CS6Trader::CalculateLots()` chiamata in `OpenPosition()` prima di `_Trade.Buy()`
- [ ] Se `lots <= 0`, `OpenPosition()` ritorna `false` immediatamente
- [ ] `_RiskPercent` e `_SlPercent` sono membri privati — non variabili globali
