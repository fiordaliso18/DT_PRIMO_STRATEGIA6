---
feature: FEAT-002
title: Logica di Uscita
type: plan
status: implemented
release: MVP
layer: implementation
language: English + Italian comments
platform: MT5 / MQL5
architecture: DroidTrader v2
---
# FEAT-002 — Logica di Uscita · IMPLEMENTAZIONE
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Spec:** `spec.md`

> Questo file descrive esclusivamente il **COME**.
> Per il **COSA** vedere: `spec.md`

---

## Architettura

Il codice risiede nella classe `CS6Trader` in `Trader/CS6Trader.mqh`.
Vedi FEAT-001 plan.md per la struttura generale e l'orchestrator.

---

## Struttura Dati

Membri privati di `CS6Trader` rilevanti per l'uscita:

```mql5
datetime _EntryTime;   // ora apertura — per calcolo timeout [S6-002-R003]
double   _RsiVal;      // RSI ultima barra chiusa — per uscita RSI [S6-002-R001]
int      _RsiExit;     // soglia RSI uscita (config)
int      _MaxDays;     // durata massima in giorni (config)
CTrade   _Trade;       // oggetto MQL5 per chiusura ordini
```

---

## Verifica Condizioni di Uscita (CS6Trader::CheckExitConditions)

**Implementa:** [S6-002-R001], [S6-002-R003], [S6-002-R004]

```mql5
bool CS6Trader::CheckExitConditions()
{
   if(!HasOpenPosition()) return false;

   // Uscita per RSI — [S6-002-R001] — priorità 1
   if(_RsiVal > _RsiExit)
   {
      if(ClosePosition("RSI_EXIT"))
         Notify("EXIT", "S6 RSI_EXIT", "RSI:" + DoubleToString(_RsiVal, 1));
      return true;
   }

   // Uscita per timeout — [S6-002-R003] — priorità 3
   // iBarShift conta barre D1 effettive (trading days), non giorni solari.
   // 15 sedute di borsa != 15 giorni solari (~21 con i weekend).
   if(_EntryTime > 0)
   {
      int barsOpen = iBarShift(_Symbol, PERIOD_D1, _EntryTime, false);
      if(barsOpen >= _MaxDays)
      {
         Log("INFO | Timeout | Bars open: " + (string)barsOpen);
         if(ClosePosition("TIMEOUT"))
            Notify("EXIT", "S6 TIMEOUT", "Bars:" + (string)barsOpen);
         return true;
      }
   }

   return false;
}
```

---

## Chiusura Posizione (CS6Trader::ClosePosition)

**Implementa:** [S6-002-R001], [S6-002-R003]

```mql5
bool CS6Trader::ClosePosition(string reason)
{
   if(!_Trade.PositionClose(_Symbol))
   {
      Log("ERROR | PositionClose failed | Code: " + (string)GetLastError());
      return false;
   }
   Log("CLOSE | " + reason);
   return true;
}
```

---

## Calcolo Stop Loss

**Implementa:** [S6-002-R002], [S6-002-R005], [S6-002-R006]

```mql5
// In CS6Trader::OpenPosition() — calcolato una sola volta all'apertura [S6-002-R005]
double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
double slPrice = ask * (1.0 - _SlPercent / 100.0);       // [S6-002-R002]
double slPts   = (ask - slPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
long   minStop = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

// Verifica distanza minima broker — [S6-002-R006]
if(slPts < (double)minStop)
{
   Log("SKIP | SL distance " + DoubleToString(slPts, 0) +
       " pts < broker min " + (string)minStop);
   return false;
}

// SL passato a _Trade.Buy() — gestito dal broker in tempo reale [S6-002-R002]
_Trade.Buy(lots, _Symbol, 0, slPrice, 0, "S6 entry");
```

---

## Identificazione Motivo Uscita nel CSV

**Implementa:** [S6-002-R002] — identificazione SL nel report

```mql5
// In CS6Trader::WriteTradesToCSV() — FEAT-004
string reason = HistoryDealGetString(exitTkt, DEAL_COMMENT);
if(reason == "" || reason == "S6 entry")
{
   if((ENUM_DEAL_REASON)HistoryDealGetInteger(exitTkt, DEAL_REASON) == DEAL_REASON_SL)
      reason = "SL";          // uscita per stop loss broker — [S6-002-R002]
   else if(durDays >= _MaxDays - 0.5)
      reason = "TIMEOUT";     // uscita per timeout — [S6-002-R003]
   else
      reason = "RSI_EXIT";    // uscita per RSI — [S6-002-R001]
}
```

---

## Note Implementative

- L'uscita per SL è gestita esclusivamente dal broker tramite il livello impostato in `_Trade.Buy()`.
  L'EA non monitora il prezzo tick-by-tick per lo SL — lo rileva solo ex-post nel report.
- `CheckExitConditions()` viene chiamata **prima** di `CheckEntryConditions()` in `TradeOnBar()`
  per garantire che la posizione venga chiusa prima che l'EA valuti una nuova entrata
  sulla stessa barra.
- La priorità RSI > TIMEOUT è implementata dall'ordine degli `if` in `CheckExitConditions()`.
- `Notify()` usa `_Reporter.FileReport()` (CReporterRobot) per loggare l'evento su `S6_events.csv`.
