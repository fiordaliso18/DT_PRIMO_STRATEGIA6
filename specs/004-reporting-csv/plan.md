---
feature: FEAT-004
title: Reporting — CSV e Journal
type: plan
status: implemented
release: MVP
layer: implementation
language: English + Italian comments
platform: MT5 / MQL5
architecture: DroidTrader v2
---
# FEAT-004 — Reporting · IMPLEMENTAZIONE
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Spec:** `spec.md`

---

## Architettura

Il codice risiede nella classe `CS6Trader` in `Trader/CS6Trader.mqh`.
Vedi FEAT-001 plan.md per la struttura generale e l'orchestrator.

Il reporting usa due canali distinti:

| Canale | Classe | File | Formato | Scopo |
|---|---|---|---|---|
| Event log | `CReporterRobot` | `S6_events.csv` | `,` (DroidTrader std) | Ogni evento operativo (entry, exit, errors) |
| Trade CSV | `CS6Trader::WriteTradesToCSV` | `S6_trades.csv` | `;` (Excel italiano) | Trade-by-trade per analisi backtest |

---

## Struttura Dati

Membri privati di `CS6Trader` per il tracking:

```mql5
double _EquityHigh;   // massimo equity raggiunto — [S6-004-R009]
double _MaxDrawdown;  // max drawdown % — [S6-004-R009]
int    _TotalTrades;  // contatore trade (aggiornato da CalcStats)
int    _WinTrades;    // contatore trade vincenti (aggiornato da CalcStats)

CReporterRobot *_Reporter;  // DroidTrader: event log su S6_events.csv
```

---

## Tracking Drawdown (CS6Trader::UpdateDrawdown)

**Implementa:** [S6-004-R009]

```mql5
// Chiamato ad ogni nuova barra in TradeOnBar()
void CS6Trader::UpdateDrawdown()
{
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > _EquityHigh) _EquityHigh = eq;
   if(_EquityHigh > 0)
   {
      double dd = (_EquityHigh - eq) / _EquityHigh * 100.0;
      if(dd > _MaxDrawdown) _MaxDrawdown = dd;
   }
}
```

---

## Commento sul Grafico

**Implementa:** [S6-004-R008]

```mql5
// In CS6Trader::TradeOnBar() — aggiornato ad ogni nuova barra
double winRate, pf, maxDD, avgDays;
CalcStats(winRate, pf, maxDD, avgDays);
Comment(StringFormat("S6 EA | WR: %.1f%% (%d/%d) | MaxDD: %.2f%%",
        winRate, _WinTrades, _TotalTrades, maxDD));
```

---

## Statistiche Aggregate (CS6Trader::CalcStats)

**Implementa:** [S6-004-R001]

```mql5
void CS6Trader::CalcStats(double &winRate, double &pf, double &maxDD, double &avgDays)
{
   int    wins = 0, losses = 0, trades = 0;
   double grossProfit = 0.0, grossLoss = 0.0, totalDays = 0.0;

   HistorySelect(0, TimeCurrent());
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      // Filtro EA + simbolo — [S6-004-R007]
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC)  != _MagicNumber) continue;
      if(HistoryDealGetString(ticket,  DEAL_SYMBOL) != _Symbol)      continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY)  != DEAL_ENTRY_OUT) continue;

      // Profitto netto incluso swap e commissioni — [S6-004-R004]
      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                    + HistoryDealGetDouble(ticket, DEAL_SWAP)
                    + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      trades++;
      if(profit > 0) { wins++;   grossProfit += profit; }
      else           { losses++;  grossLoss  += MathAbs(profit); }

      // Durata — ricerca deal di entrata tramite DEAL_POSITION_ID — [S6-004-R006]
      ulong    posId    = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
      datetime exitTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      for(int j = 0; j < total; j++)
      {
         ulong inTkt = HistoryDealGetTicket(j);
         if((ulong)HistoryDealGetInteger(inTkt, DEAL_POSITION_ID) != posId) continue;
         if(HistoryDealGetInteger(inTkt, DEAL_ENTRY) != DEAL_ENTRY_IN)       continue;
         totalDays += (double)(exitTime - (datetime)HistoryDealGetInteger(inTkt, DEAL_TIME)) / 86400.0;
         break;
      }
   }

   winRate = (trades > 0) ? (double)wins / trades * 100.0 : 0.0;
   pf      = (grossLoss > 0) ? grossProfit / grossLoss : 0.0;
   maxDD   = _MaxDrawdown;
   avgDays = (trades > 0) ? totalDays / trades : 0.0;
   _TotalTrades = trades;
   _WinTrades   = wins;
}
```

---

## Report Finale (CS6Trader::GenerateFinalReport)

**Implementa:** [S6-004-R001], [S6-004-R002]
Chiamato da `S6_EA.mq5::OnDeinit()`.

```mql5
void CS6Trader::GenerateFinalReport()
{
   double winRate, pf, maxDD, avgDays;
   CalcStats(winRate, pf, maxDD, avgDays);

   Log("FINAL REPORT | Trades: " + (string)_TotalTrades +
       " | WR: "    + DoubleToString(winRate, 1) + "%" +
       " | PF: "    + DoubleToString(pf, 2) +
       " | MaxDD: " + DoubleToString(maxDD, 2) + "%" +
       " | AvgDays: " + DoubleToString(avgDays, 1));

   WriteTradesToCSV();   // [S6-004-R002]
}
```

---

## Esportazione CSV (CS6Trader::WriteTradesToCSV)

**Implementa:** [S6-004-R002]–[S6-004-R007], [S6-004-R010], [S6-004-R011], [S6-004-R012]

### Pattern append — [S6-004-R010]

Ispirato da `prova.mq5` (file di test verificato nel terminale).
Usa `FILE_COMMON` per scrivere nella cartella condivisa tra tutti i Tester Agent.
`FileSeek` con `SEEK_SET` + offset assoluto (`FileSize`) funziona con `FILE_CSV`; `SEEK_END` no.

```mql5
// Prima esecuzione: crea file con intestazione
if(!FileIsExist(filename, FILE_COMMON))
{
   int fi = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ';');
   FileWrite(fi, "Trade", "EntryDate", "EntryPrice", "ExitDate", "ExitPrice",
             "Lots", "Profit", "DurationDays", "Reason");
   FileClose(fi);
}

// Append: posiziona il puntatore alla fine tramite offset assoluto
int fh = FileOpen(filename, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ';');
ulong size = FileSize(fh);
FileSeek(fh, (long)size, SEEK_SET);

// Separatore run + righe dati via FileWrite() standard
FileWrite(fh, "=== RUN ...", "", ...);
```

### Percorso file (FILE_COMMON)

```
%PUBLIC%\Documents\MetaTrader 5\MQL5\Files\S6_trades.csv
```

Accessibile da tutti i Tester Agent e dal terminale live — nessun percorso agent-specifico.

### Trade loop — [S6-004-R003]–[S6-004-R007]

```mql5
FileWriteString(fh, Csv9("Trade", "EntryDate", "EntryPrice", "ExitDate", "ExitPrice",
                          "Lots", "Profit", "DurationDays", "Reason"));

// ... loop deals con filtro DEAL_MAGIC + DEAL_SYMBOL + DEAL_ENTRY_OUT ...

FileWriteString(fh, Csv9((string)tradeNum,
                          TimeToString(entryDt, TIME_DATE | TIME_MINUTES),
                          DoubleToString(entryPx, _Digits),
                          TimeToString(exitDt,   TIME_DATE | TIME_MINUTES),
                          DoubleToString(exitPx, _Digits),
                          DoubleToString(lots, 2),
                          DoubleToString(profit, 2),
                          DoubleToString(durDays, 1),
                          reason));
```

### Riga TOTALE — [S6-004-R011]

```mql5
FileWriteString(fh, Csv9("", "", "", "", "", "", "", "", ""));
FileWriteString(fh, Csv9("TOTALE", "", "", "", "",
                          DoubleToString(totalLots, 2),
                          DoubleToString(totalProfit, 2),
                          DoubleToString(tradeNum > 0 ? totalDays / tradeNum : 0, 1),
                          (string)tradeNum + " trades"));
```

### Istogramma profitti — [S6-004-R012]

10 bucket dinamici su range [minProfit, maxProfit]. Barra ASCII `#` scalata su 20 caratteri.

```mql5
FileWriteString(fh, Csv9("ISTOGRAMMA PROFIT", "Da", "A", "Freq", "Bar", "", "", "", ""));

for(int b = 0; b < nBuckets; b++)
{
   double lo  = minP + b * bWidth;
   double hi  = lo + bWidth;
   // barLen = counts[b] / maxCount * 20 arrotondato
   FileWriteString(fh, Csv9("",
                             DoubleToString(lo, 0),
                             DoubleToString(hi, 0),
                             (string)counts[b],
                             bar, "", "", "", ""));
}
```

---

## Percorso File CSV in Strategy Tester

```
%APPDATA%\MetaQuotes\Tester\73B7A2420D6397DFF9014A20F1201F97\
  Agent-127.0.0.1-<PORT>\MQL5\Files\S6_trades.csv
```

```
%APPDATA%\MetaQuotes\Tester\73B7A2420D6397DFF9014A20F1201F97\
  Agent-127.0.0.1-<PORT>\MQL5\Files\S6_events.csv
```
