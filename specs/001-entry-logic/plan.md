---
feature: FEAT-001
title: Logica di Entrata
type: plan
status: implemented
release: MVP
layer: implementation
language: English + Italian comments
platform: MT5 / MQL5
architecture: DroidTrader v2
---
# FEAT-001 — Logica di Entrata · IMPLEMENTAZIONE
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Spec:** `spec.md`

> Questo file descrive esclusivamente il **COME**.
> Per il **COSA** vedere: `spec.md`

---

## Architettura

Tutta la logica risiede nella classe `CS6Trader` in `Trader/CS6Trader.mqh`.
`S6_EA.mq5` è un thin orchestrator: crea l'istanza, chiama `Init()`, `Tick()`, `GenerateFinalReport()`, `Deinit()`.

```
S6_EA.mq5
  └── CS6Trader  (extends ATraderRobot — DroidTrader)
        ├── CReporterRobot  _Reporter   (event CSV + push)
        └── CTrade          _Trade      (MQL5 Trade library)
```

---

## Struttura Dati

Membri privati di `CS6Trader`:

```mql5
// Indicator handles (CSupplierRobot non fornisce SMA/RSI — usiamo iMA/iRSI diretti)
int      _hSMA;          // handle SMA — [S6-001-R002]
int      _hRSI;          // handle RSI — [S6-001-R003]
double   _SmaVal;        // SMA valore ultima barra chiusa
double   _RsiVal;        // RSI valore ultima barra chiusa

// State
datetime _LastBarTime;    // tempo ultima barra elaborata — [S6-001-R004]
bool     _IsWarmedUp;     // flag warmup completato — [S6-001-R005]
bool     _PendingEntry;   // flag entrata pendente — [S6-001-R008]
datetime _EntryTime;      // ora apertura posizione corrente
datetime _LastRetryTime;  // timestamp ultimo tentativo pending — throttle 1/ora [S6-001-R008]
CTrade   _Trade;         // oggetto MQL5 per ordini

// Config (ricevuti dal costruttore, provengono dagli input di S6_EA.mq5)
int      _MagicNumber;
int      _SmaPeriod;
int      _RsiPeriod;
int      _RsiEntry;
```

---

## Orchestrator (S6_EA.mq5)

```mql5
CS6Trader *_trader;

int OnInit()
{
   _trader = new CS6Trader(MagicNumber, SMA_Period, RSI_Period, RSI_Entry, RSI_Exit,
                           SL_Percent, MaxDays, RiskPercent, EnablePhase2,
                           ShowArrows, ArrowSize, ArrowBuyColor, ArrowExitColor);
   return _trader.Init() ? INIT_SUCCEEDED : INIT_FAILED;
}

void OnTick()   { _trader.Tick(); }

void OnDeinit(const int reason)
{
   _trader.GenerateFinalReport();
   _trader.Deinit();
   delete _trader;
   _trader = NULL;
}
```

---

## Inizializzazione (CS6Trader::Init)

**Implementa:** [S6-001-R005], [S6-001-R009]

```mql5
bool CS6Trader::Init()
{
   _Trade.SetExpertMagicNumber(_MagicNumber);
   _LastBarTime = iTime(_Symbol, PERIOD_D1, 0);
   _IsWarmedUp  = false;
   _PendingEntry = false;

   // Crea handle SMA — [S6-001-R002]
   _hSMA = iMA(_Symbol, PERIOD_D1, _SmaPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(_hSMA == INVALID_HANDLE) { Log("ERROR | SMA handle..."); return false; }

   // Crea handle RSI — [S6-001-R003]
   _hRSI = iRSI(_Symbol, PERIOD_D1, _RsiPeriod, PRICE_CLOSE);
   if(_hRSI == INVALID_HANDLE) { Log("ERROR | RSI handle..."); return false; }
   // NB: ChartIndicatorAdd() spostato in AddIndicatorsToChart() — chiamato al primo tick
   //     (in Strategy Tester il grafico non è pronto durante OnInit)

   // Recupero riavvio — [S6-001-R009]
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == _MagicNumber)
      {
         _EntryTime = (datetime)PositionGetInteger(POSITION_TIME);
         Log("RECOVERY | Posizione esistente | Ticket: " + (string)ticket);
         break;
      }
   }
   return true;
}
```

---

## Rilevamento Nuova Barra (CS6Trader::IsNewBar)

**Implementa:** [S6-001-R004]

```mql5
bool CS6Trader::IsNewBar()
{
   datetime t = iTime(_Symbol, PERIOD_D1, 0);
   if(t == 0) { Log("ERROR | iTime returned 0"); return false; }
   if(t == _LastBarTime) return false;
   _LastBarTime = t;
   return true;
}
```

---

## Verifica Warmup (CS6Trader::CheckWarmup)

**Implementa:** [S6-001-R005]

```mql5
bool CS6Trader::CheckWarmup()
{
   int minBars = _SmaPeriod + _RsiPeriod + 1;
   if(Bars(_Symbol, PERIOD_D1) < minBars)
   {
      Log("WARMUP | Insufficient bars: " + (string)Bars(_Symbol, PERIOD_D1) +
          " / " + (string)minBars + " needed");
      return false;
   }
   if(!_IsWarmedUp) { _IsWarmedUp = true; Log("WARMUP | Warm-up complete"); }
   return true;
}
```

---

## Lettura Indicatori (CS6Trader::ReadIndicators)

**Implementa:** [S6-001-R002], [S6-001-R003]

```mql5
bool CS6Trader::ReadIndicators()
{
   double smaBuf[1], rsiBuf[1];
   if(CopyBuffer(_hSMA, 0, 1, 1, smaBuf) < 1) { Log("ERROR | CopyBuffer SMA"); return false; }
   if(CopyBuffer(_hRSI, 0, 1, 1, rsiBuf) < 1) { Log("ERROR | CopyBuffer RSI"); return false; }
   _SmaVal = smaBuf[0];
   _RsiVal = rsiBuf[0];
   return true;
}
```

---

## Verifica Condizione di Entrata (CS6Trader::CheckEntryConditions)

**Implementa:** [S6-001-R001], [S6-001-R002], [S6-001-R003], [S6-001-R006]

```mql5
bool CS6Trader::CheckEntryConditions()
{
   if(HasOpenPosition()) return false;               // [S6-001-R001]

   double closePrice = iClose(_Symbol, PERIOD_D1, 1);
   if(closePrice <= _SmaVal) return false;           // [S6-001-R002]
   if(_RsiVal >= _RsiEntry)  return false;           // [S6-001-R003]

   Log("SIGNAL | Entry conditions met | Close: " + DoubleToString(closePrice, _Digits) +
       " | SMA: " + DoubleToString(_SmaVal, _Digits) +
       " | RSI: " + DoubleToString(_RsiVal, 2));

   if(OpenPosition())                                // [S6-001-R006] BUY only
   {
      _EntryTime = TimeCurrent();
      _TotalTrades++;
      Notify("ENTRY", "S6 BUY opened",
             "Price:" + DoubleToString(closePrice, _Digits) + " RSI:" + DoubleToString(_RsiVal, 1));
   }
   return true;
}
```

---

## Apertura Posizione (CS6Trader::OpenPosition)

**Implementa:** [S6-001-R007], [S6-001-R008]

```mql5
bool CS6Trader::OpenPosition()
{
   // Verifica trading abilitato — [S6-001-R007]
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Log("SKIP | Trading not allowed");
      return false;
   }

   double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double slPrice = ask * (1.0 - _SlPercent / 100.0);
   // ... verifica distanza minima, calcolo lotti (FEAT-003) ...

   if(!_Trade.Buy(lots, _Symbol, 0, slPrice, 0, "S6 entry"))
   {
      int  err     = GetLastError();
      uint retcode = _Trade.ResultRetcode();
      // Mercato chiuso — [S6-001-R008]
      if(retcode == TRADE_RETCODE_MARKET_CLOSED || retcode == 10018 || err == 4756)
      {
         _PendingEntry = true;
         Log("INFO | Market closed — retry pending | Err: " + (string)err +
             " | RetCode: " + (string)retcode);
      }
      else { Log("ERROR | OrderSend failed | ..."); }
      return false;
   }
   Log("ORDER | BUY placed | Lots: " + DoubleToString(lots, 2) +
       " | SL: " + DoubleToString(slPrice, _Digits));
   return true;
}
```

---

## TradeOnTick / TradeOnBar — Flusso Principale

**Implementa:** [S6-001-R004], [S6-001-R008]

```mql5
// Tick() e' il punto di ingresso pubblico — chiama TradeOnTick()
bool CS6Trader::TradeOnTick()
{
   AddIndicatorsToChart();   // aggiunge SMA/RSI al grafico al primo tick (guard interno)

   // Gestione entrata pendente — [S6-001-R008]
   // Throttle: riprova max 1 volta per ora — evita spam in "every tick" mode su H1/M1
   if(_PendingEntry && !HasOpenPosition())
   {
      datetime now = TimeCurrent();
      if(now - _LastRetryTime < 3600) return true;
      _LastRetryTime = now;
      _PendingEntry  = false;
      if(OpenPosition())
      {
         _EntryTime = TimeCurrent();
         _TotalTrades++;
         Log("INFO | Pending entry executed after market open");
         Notify("ENTRY_PENDING", "Pending entry executed", "S6 BUY after market open");
      }
      return true;
   }
   return TradeOnBar();
}

bool CS6Trader::TradeOnBar()
{
   if(!IsNewBar()) return false;     // [S6-001-R004]
   _PendingEntry = false;

   if(!CheckWarmup())    return false;   // [S6-001-R005]
   if(!ReadIndicators()) return false;

   UpdateDrawdown();
   CheckExitConditions();  // FEAT-002
   CheckEntryConditions(); // FEAT-001

   // Aggiorna commento grafico — FEAT-004
   double winRate, pf, maxDD, avgDays;
   CalcStats(winRate, pf, maxDD, avgDays);
   Comment(StringFormat("S6 EA | WR: %.1f%% (%d/%d) | MaxDD: %.2f%%",
           winRate, _WinTrades, _TotalTrades, maxDD));
   return true;
}
```

---

## Logging e Notifiche

```mql5
void CS6Trader::Log(string msg)     { Print("[S6] " + msg); }

void CS6Trader::Notify(string shortDescr, string longDescr, string msg)
{
   _Reporter.FileReport(shortDescr, longDescr, msg);  // event CSV S6_events.csv
}
```
