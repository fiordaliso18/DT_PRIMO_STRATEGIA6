---
feature: FEAT-003
title: Gestione del Rischio
type: plan
status: implemented
release: MVP
layer: implementation
language: English + Italian comments
platform: MT5 / MQL5
architecture: DroidTrader v2
---
# FEAT-003 — Gestione del Rischio · IMPLEMENTAZIONE
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Spec:** `spec.md`

---

## Architettura

Il codice risiede nella classe `CS6Trader` in `Trader/CS6Trader.mqh`.
Vedi FEAT-001 plan.md per la struttura generale e l'orchestrator.

---

## Funzione CalculateLots (CS6Trader::CalculateLots)

**Implementa:** [S6-003-R001], [S6-003-R002], [S6-003-R003], [S6-003-R004], [S6-003-R005]

```mql5
double CS6Trader::CalculateLots()
{
   // Dati broker necessari per il calcolo — [S6-003-R004]
   double ask      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double slPrice  = ask * (1.0 - _SlPercent / 100.0);
   double slPoints = (ask - slPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double volStep  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double volMin   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volMax   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   // Verifica validità dati broker — [S6-003-R004]
   if(slPoints <= 0 || tickVal <= 0 || tickSize <= 0 || volStep <= 0)
   {
      Log("ERROR | CalculateLots: invalid symbol data");
      return 0.0;
   }

   // Rischio in valuta conto — [S6-003-R001], [S6-003-R005]
   // Usa ACCOUNT_BALANCE (non equity) per stabilità del calcolo
   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * _RiskPercent / 100.0;

   // Volume grezzo: risk / (distanzaSL_in_punti × valore_tick_per_lotto)
   double rawLots = riskAmount / (slPoints * tickVal / tickSize);

   // Arrotondamento per difetto al volume step — [S6-003-R002]
   double lots = MathFloor(rawLots / volStep) * volStep;

   // Rispetto limiti broker — [S6-003-R003]
   if(lots < volMin)
   {
      Log("SKIP | Lots " + DoubleToString(lots, 2) +
          " below broker minimum " + DoubleToString(volMin, 2));
      return 0.0;
   }
   if(lots > volMax)
   {
      lots = volMax;
      Log("INFO | Lots capped at broker maximum " + DoubleToString(volMax, 2));
   }

   return lots;
}
```

---

## Formula di Calcolo

```
riskAmount = balance × _RiskPercent / 100
slPoints   = (Ask - SL) / point
lotValue   = slPoints × tickValue / tickSize   [perdita per 1 lotto se SL colpito]
rawLots    = riskAmount / lotValue
lots       = floor(rawLots / volStep) × volStep
```

---

## Note Implementative

- `SYMBOL_TRADE_TICK_VALUE` restituisce il valore in valuta conto di 1 tick per 1 lotto.
- `SYMBOL_TRADE_TICK_SIZE` è la dimensione del tick in unità di prezzo.
- Il rapporto `tickVal / tickSize` converte il valore del tick per punto intero.
- Il calcolo viene eseguito ogni volta che si apre una posizione (non viene cachato).
- Se `CalculateLots()` restituisce 0, `OpenPosition()` ritorna `false` senza inviare ordini.
- `_RiskPercent` e `_SlPercent` sono membri privati di `CS6Trader`, ricevuti dal costruttore
  dagli input `RiskPercent` e `SL_Percent` di `S6_EA.mq5`.
