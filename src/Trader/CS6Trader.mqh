//+------------------------------------------------------------------+
//|                                                  CS6Trader.mqh   |
//|                                              Primo Fiordaliso    |
//| S6 Swing Mean Reversion Daily — DroidTrader integration          |
//| Entry: Close > SMA(200) AND RSI(14) < RSI_Entry                 |
//| Exit:  RSI > RSI_Exit / SL -2% / 15-day timeout                 |
//+------------------------------------------------------------------+
#property copyright "Primo Fiordaliso"
#property version   "2.00"

#include <Trade/Trade.mqh>
#include "../../DroidTrader/Trader/ATraderRobot.mqh"
#include "../../DroidTrader/Reporter/CReporterRobot.mqh"

//+------------------------------------------------------------------+
class CS6Trader : public ATraderRobot
{
private:
   // DroidTrader components
   CReporterRobot  *_Reporter;
   CTrade           _Trade;

   // Indicator handles (CSupplierRobot non ha SMA/RSI — usiamo iMA/iRSI)
   int              _hSMA;
   int              _hRSI;
   double           _SmaVal;
   double           _RsiVal;

   // State
   datetime         _LastBarTime;
   datetime         _EntryTime;
   datetime         _LastRetryTime;
   bool             _IsWarmedUp;
   bool             _PendingEntry;
   double           _EquityHigh;
   double           _MaxDrawdown;
   int              _TotalTrades;
   int              _WinTrades;

   // Config
   int              _MagicNumber;
   int              _SmaPeriod;
   int              _RsiPeriod;
   int              _RsiEntry;
   int              _RsiExit;
   double           _SlPercent;
   int              _MaxDays;
   double           _RiskPercent;
   bool             _EnablePhase2;

   // Chart arrows config
   bool             _ShowArrows;
   int              _ArrowSize;
   color            _ArrowBuyColor;
   color            _ArrowExitColor;
   bool             _IndicatorsOnChart;

   // Private methods
   bool             IsNewBar();
   bool             CheckWarmup();
   bool             ReadIndicators();
   bool             HasOpenPosition();
   bool             CheckEntryConditions();
   bool             CheckExitConditions();
   bool             OpenPosition();
   bool             ClosePosition(string reason);
   double           CalculateLots();
   void             UpdateDrawdown();
   void             Log(string msg);
   void             Notify(string shortDescr, string longDescr, string msg);
   void             CalcStats(double &winRate, double &pf, double &maxDD, double &avgDays);
   void             WriteTradesToCSV();
   void             DrawTradeRects();
   void             DrawEntryArrow(datetime time, double price);
   void             DrawExitArrow(datetime time, double price);
   void             DrawRsiLevels();
   void             DeleteAllArrows();
   void             AddIndicatorsToChart();

protected:
   bool             TradeOnTick() override;
   bool             TradeOnBar()  override;

public:
   CS6Trader(int magic, int smaPeriod, int rsiPeriod, int rsiEntry, int rsiExit,
             double slPct, int maxDays, double riskPct, bool enablePhase2,
             bool showArrows, int arrowSize, color arrowBuyColor, color arrowExitColor);
   ~CS6Trader();

   bool             Init();
   void             Deinit();
   void             Tick();
   void             GenerateFinalReport();
};

//+------------------------------------------------------------------+
// Constructor / Destructor
//+------------------------------------------------------------------+

CS6Trader::CS6Trader(int magic, int smaPeriod, int rsiPeriod, int rsiEntry, int rsiExit,
                     double slPct, int maxDays, double riskPct, bool enablePhase2,
                     bool showArrows, int arrowSize, color arrowBuyColor, color arrowExitColor)
{
   _MagicNumber    = magic;
   _SmaPeriod      = smaPeriod;
   _RsiPeriod      = rsiPeriod;
   _RsiEntry       = rsiEntry;
   _RsiExit        = rsiExit;
   _SlPercent      = slPct;
   _MaxDays        = maxDays;
   _RiskPercent    = riskPct;
   _EnablePhase2   = enablePhase2;
   _ShowArrows     = showArrows;
   _ArrowSize      = arrowSize;
   _ArrowBuyColor      = arrowBuyColor;
   _ArrowExitColor     = arrowExitColor;
   _IndicatorsOnChart  = false;

   _hSMA        = INVALID_HANDLE;
   _hRSI        = INVALID_HANDLE;
   _SmaVal      = 0.0;
   _RsiVal      = 0.0;
   _LastBarTime  = 0;
   _EntryTime    = 0;
   _LastRetryTime = 0;
   _IsWarmedUp   = false;
   _PendingEntry = false;
   _EquityHigh  = 0.0;
   _MaxDrawdown = 0.0;
   _TotalTrades = 0;
   _WinTrades   = 0;

   _Reporter = new CReporterRobot("S6Trader", ROBOT_TRADER);
   _Reporter.SetEnableFileReport(true);
   _Reporter.SetReportFileName("S6_events.csv");
   _Reporter.SetEnableMobileTwit(false);
   _Reporter.SetEnableEmail(false);
}

CS6Trader::~CS6Trader()
{
   if(_Reporter != NULL) { delete _Reporter; _Reporter = NULL; }
}

//+------------------------------------------------------------------+
// Init / Deinit
//+------------------------------------------------------------------+

bool CS6Trader::Init()
{
   _Trade.SetExpertMagicNumber(_MagicNumber);
   _EquityHigh  = AccountInfoDouble(ACCOUNT_EQUITY);
   _LastBarTime = iTime(_Symbol, PERIOD_D1, 0);
   _IsWarmedUp  = false;
   _PendingEntry = false;

   _hSMA = iMA(_Symbol, PERIOD_D1, _SmaPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(_hSMA == INVALID_HANDLE)
   {
      Log("ERROR | SMA handle creation failed | Code: " + (string)GetLastError());
      return false;
   }

   _hRSI = iRSI(_Symbol, PERIOD_D1, _RsiPeriod, PRICE_CLOSE);
   if(_hRSI == INVALID_HANDLE)
   {
      Log("ERROR | RSI handle creation failed | Code: " + (string)GetLastError());
      return false;
   }

   // Restart recovery: rileva posizione aperta con MagicNumber
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == _MagicNumber)
      {
         _EntryTime = (datetime)PositionGetInteger(POSITION_TIME);
         Log("RECOVERY | Posizione esistente | Ticket: " + (string)ticket +
             " | Aperta: " + TimeToString(_EntryTime));
         break;
      }
   }

   Log("INIT | S6Trader v2.0 | Magic: " + (string)_MagicNumber +
       " | SMA(" + (string)_SmaPeriod + ") RSI(" + (string)_RsiPeriod + ")" +
       " | Entry<" + (string)_RsiEntry + " Exit>" + (string)_RsiExit +
       " | SL:" + DoubleToString(_SlPercent, 1) + "% MaxDays:" + (string)_MaxDays);

   DrawRsiLevels();
   return true;
}

void CS6Trader::Deinit()
{
   if(_hSMA != INVALID_HANDLE) { IndicatorRelease(_hSMA); _hSMA = INVALID_HANDLE; }
   if(_hRSI != INVALID_HANDLE) { IndicatorRelease(_hRSI); _hRSI = INVALID_HANDLE; }
   Log("DEINIT | S6Trader released");
}

//+------------------------------------------------------------------+
// Public entry point
//+------------------------------------------------------------------+

void CS6Trader::Tick()
{
   TradeOnTick();
}

//+------------------------------------------------------------------+
// TradeOnTick — gestisce pending entry e delega alla logica su barra
//+------------------------------------------------------------------+

bool CS6Trader::TradeOnTick()
{
   AddIndicatorsToChart();

   // Pending entry: mercato era chiuso al momento del segnale — riprova max 1 volta/ora
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

//+------------------------------------------------------------------+
// TradeOnBar — logica su chiusura nuova barra D1
//+------------------------------------------------------------------+

bool CS6Trader::TradeOnBar()
{
   if(!IsNewBar()) return false;
   _PendingEntry = false;

   if(!CheckWarmup())     return false;
   if(!ReadIndicators())  return false;

   UpdateDrawdown();
   CheckExitConditions();
   CheckEntryConditions();

   // Aggiorna commento sul grafico
   double winRate, pf, maxDD, avgDays;
   CalcStats(winRate, pf, maxDD, avgDays);
   Comment(StringFormat("S6 EA | WR: %.1f%% (%d/%d) | MaxDD: %.2f%%",
           winRate, _WinTrades, _TotalTrades, maxDD));

   return true;
}

//+------------------------------------------------------------------+
// Signal Engine
//+------------------------------------------------------------------+

bool CS6Trader::IsNewBar()
{
   datetime t = iTime(_Symbol, PERIOD_D1, 0);
   if(t == 0) { Log("ERROR | iTime returned 0 — data not ready"); return false; }
   if(t == _LastBarTime) return false;
   _LastBarTime = t;
   return true;
}

bool CS6Trader::CheckWarmup()
{
   int minBars = _SmaPeriod + _RsiPeriod + 1;
   if(Bars(_Symbol, PERIOD_D1) < minBars)
   {
      Log("WARMUP | Insufficient bars: " + (string)Bars(_Symbol, PERIOD_D1) +
          " / " + (string)minBars + " needed");
      return false;
   }
   if(!_IsWarmedUp)
   {
      _IsWarmedUp = true;
      Log("WARMUP | Warm-up complete — bars: " + (string)Bars(_Symbol, PERIOD_D1));
   }
   return true;
}

bool CS6Trader::ReadIndicators()
{
   double smaBuf[1], rsiBuf[1];
   if(CopyBuffer(_hSMA, 0, 1, 1, smaBuf) < 1)
   {
      Log("ERROR | CopyBuffer SMA failed | Code: " + (string)GetLastError());
      return false;
   }
   if(CopyBuffer(_hRSI, 0, 1, 1, rsiBuf) < 1)
   {
      Log("ERROR | CopyBuffer RSI failed | Code: " + (string)GetLastError());
      return false;
   }
   _SmaVal = smaBuf[0];
   _RsiVal = rsiBuf[0];
   return true;
}

bool CS6Trader::HasOpenPosition()
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC)  == _MagicNumber)
         return true;
   }
   return false;
}

bool CS6Trader::CheckEntryConditions()
{
   if(HasOpenPosition()) return false;

   double closePrice = iClose(_Symbol, PERIOD_D1, 1);
   if(closePrice <= _SmaVal) return false;   // filtro trend
   if(_RsiVal >= _RsiEntry)  return false;   // filtro ipervenduto

   Log("SIGNAL | Entry conditions met | Close: " + DoubleToString(closePrice, _Digits) +
       " | SMA: " + DoubleToString(_SmaVal, _Digits) +
       " | RSI: " + DoubleToString(_RsiVal, 2));

   if(OpenPosition())
   {
      _EntryTime = TimeCurrent();
      _TotalTrades++;
      Notify("ENTRY", "S6 BUY opened",
             "Price:" + DoubleToString(closePrice, _Digits) + " RSI:" + DoubleToString(_RsiVal, 1));
   }
   return true;
}

bool CS6Trader::CheckExitConditions()
{
   if(!HasOpenPosition()) return false;

   // Uscita RSI (priorita' 1)
   if(_RsiVal > _RsiExit)
   {
      if(ClosePosition("RSI_EXIT"))
         Notify("EXIT", "S6 RSI_EXIT", "RSI:" + DoubleToString(_RsiVal, 1));
      return true;
   }

   // Uscita timeout (priorita' 3)
   // iBarShift conta le barre D1 effettive (trading days), non i giorni di calendario.
   // Con MaxDays=15, chiude dopo 15 sedute di borsa — non 15 giorni solari (che
   // sarebbero ~21 per effetto dei weekend).
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

//+------------------------------------------------------------------+
// Order Manager
//+------------------------------------------------------------------+

bool CS6Trader::OpenPosition()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
      !MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Log("SKIP | Trading not allowed");
      return false;
   }

   double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double slPrice = ask * (1.0 - _SlPercent / 100.0);
   double slPts   = (ask - slPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   long   minStop = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

   if(slPts < (double)minStop)
   {
      Log("SKIP | SL distance " + DoubleToString(slPts, 0) +
          " pts < broker min " + (string)minStop);
      return false;
   }

   double lots = CalculateLots();
   if(lots <= 0.0) return false;

   if(!_Trade.Buy(lots, _Symbol, 0, slPrice, 0, "S6 entry"))
   {
      int  err     = GetLastError();
      uint retcode = _Trade.ResultRetcode();
      if(retcode == TRADE_RETCODE_MARKET_CLOSED || retcode == 10018 || err == 4756)
      {
         _PendingEntry = true;
         Log("INFO | Market closed — retry pending | Err: " + (string)err +
             " | RetCode: " + (string)retcode);
      }
      else
      {
         Log("ERROR | OrderSend failed | Err: " + (string)err +
             " | RetCode: " + (string)retcode);
      }
      return false;
   }

   Log("ORDER | BUY placed | Lots: " + DoubleToString(lots, 2) +
       " | SL: " + DoubleToString(slPrice, _Digits));
   DrawEntryArrow(TimeCurrent(), ask);
   return true;
}

bool CS6Trader::ClosePosition(string reason)
{
   if(!_Trade.PositionClose(_Symbol))
   {
      Log("ERROR | PositionClose failed | Code: " + (string)GetLastError());
      return false;
   }
   Log("CLOSE | " + reason);
   DrawExitArrow(TimeCurrent(), SymbolInfoDouble(_Symbol, SYMBOL_BID));
   return true;
}

//+------------------------------------------------------------------+
// Risk Calculator
//+------------------------------------------------------------------+

double CS6Trader::CalculateLots()
{
   double ask      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double slPrice  = ask * (1.0 - _SlPercent / 100.0);
   double slPoints = (ask - slPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double volStep  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double volMin   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volMax   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(slPoints <= 0 || tickVal <= 0 || tickSize <= 0 || volStep <= 0)
   {
      Log("ERROR | CalculateLots: invalid symbol data");
      return 0.0;
   }

   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * _RiskPercent / 100.0;
   double rawLots    = riskAmount / (slPoints * tickVal / tickSize);
   double lots       = MathFloor(rawLots / volStep) * volStep;

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

//+------------------------------------------------------------------+
// Reporting
//+------------------------------------------------------------------+

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

void CS6Trader::Log(string msg)
{
   Print("[S6] " + msg);
}

void CS6Trader::Notify(string shortDescr, string longDescr, string msg)
{
   // Reporter: event CSV + (opzionale) push mobile
   _Reporter.FileReport(shortDescr, longDescr, msg);
}

void CS6Trader::CalcStats(double &winRate, double &pf, double &maxDD, double &avgDays)
{
   int    wins = 0, losses = 0, trades = 0;
   double grossProfit = 0.0, grossLoss = 0.0, totalDays = 0.0;

   HistorySelect(0, TimeCurrent());
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC)  != _MagicNumber) continue;
      if(HistoryDealGetString(ticket,  DEAL_SYMBOL) != _Symbol)      continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY)  != DEAL_ENTRY_OUT) continue;

      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                    + HistoryDealGetDouble(ticket, DEAL_SWAP)
                    + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      trades++;
      if(profit > 0) { wins++;   grossProfit += profit; }
      else           { losses++;  grossLoss  += MathAbs(profit); }

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

void CS6Trader::WriteTradesToCSV()
{
   string filename = "S6_trades.csv";

   // Prima esecuzione: crea il file con l'intestazione
   if(!FileIsExist(filename, FILE_COMMON))
   {
      int fi = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ';');
      if(fi == INVALID_HANDLE)
      {
         Log("ERROR | CSV create failed | Code: " + (string)GetLastError());
         return;
      }
      FileWrite(fi, "Trade", "EntryDate", "EntryPrice", "ExitDate", "ExitPrice",
                "Lots", "Profit", "DurationDays", "Reason");
      FileClose(fi);
   }

   // Append: FILE_READ|FILE_WRITE + FileSize + SEEK_SET (pattern da prova.mq5)
   int fh = FileOpen(filename, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ';');
   if(fh == INVALID_HANDLE)
   {
      Log("ERROR | CSV open failed | Code: " + (string)GetLastError());
      return;
   }
   ulong size = FileSize(fh);
   FileSeek(fh, (long)size, SEEK_SET);

   // Separatore run
   FileWrite(fh, "", "", "", "", "", "", "", "", "");
   FileWrite(fh, "=== RUN " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES) +
             " | " + _Symbol + " ===", "", "", "", "", "", "", "", "");
   FileWrite(fh, "", "", "", "", "", "", "", "", "");

   HistorySelect(0, TimeCurrent());
   int total    = HistoryDealsTotal();

   int tradeNum = 0;

   double profits[];
   double totalProfit = 0, totalLots = 0, totalDays = 0;

   for(int i = 0; i < total; i++)
   {
      ulong exitTkt = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(exitTkt, DEAL_MAGIC)  != _MagicNumber)    continue;
      if(HistoryDealGetString(exitTkt,  DEAL_SYMBOL) != _Symbol)         continue;
      if(HistoryDealGetInteger(exitTkt, DEAL_ENTRY)  != DEAL_ENTRY_OUT)  continue;

      tradeNum++;
      double profit  = HistoryDealGetDouble(exitTkt, DEAL_PROFIT)
                     + HistoryDealGetDouble(exitTkt, DEAL_SWAP)
                     + HistoryDealGetDouble(exitTkt, DEAL_COMMISSION);
      datetime exitDt = (datetime)HistoryDealGetInteger(exitTkt, DEAL_TIME);
      double   exitPx = HistoryDealGetDouble(exitTkt, DEAL_PRICE);
      double   lots   = HistoryDealGetDouble(exitTkt, DEAL_VOLUME);

      ulong    posId   = (ulong)HistoryDealGetInteger(exitTkt, DEAL_POSITION_ID);
      datetime entryDt = 0;
      double   entryPx = 0;
      for(int j = 0; j < total; j++)
      {
         ulong inTkt = HistoryDealGetTicket(j);
         if((ulong)HistoryDealGetInteger(inTkt, DEAL_POSITION_ID) != posId) continue;
         if(HistoryDealGetInteger(inTkt, DEAL_ENTRY) != DEAL_ENTRY_IN)       continue;
         entryDt = (datetime)HistoryDealGetInteger(inTkt, DEAL_TIME);
         entryPx = HistoryDealGetDouble(inTkt, DEAL_PRICE);
         break;
      }

      double durDays = (entryDt > 0) ? (double)(exitDt - entryDt) / 86400.0 : 0;

      // Conta le barre D1 effettive (sedute di borsa) per classificare TIMEOUT.
      // iBarShift: shift più alto = barra più vecchia; barsHeld = entryShift - exitShift.
      int barsHeld = 0;
      if(entryDt > 0)
      {
         int shiftEntry = iBarShift(_Symbol, PERIOD_D1, entryDt, false);
         int shiftExit  = iBarShift(_Symbol, PERIOD_D1, exitDt,  false);
         barsHeld = shiftEntry - shiftExit;
      }

      string reason  = HistoryDealGetString(exitTkt, DEAL_COMMENT);
      if(reason == "" || reason == "S6 entry")
      {
         if((ENUM_DEAL_REASON)HistoryDealGetInteger(exitTkt, DEAL_REASON) == DEAL_REASON_SL)
            reason = "SL";
         else if(barsHeld >= _MaxDays)
            reason = "TIMEOUT";
         else
            reason = "RSI_EXIT";
      }

      FileWrite(fh, tradeNum,
                TimeToString(entryDt, TIME_DATE | TIME_MINUTES),
                DoubleToString(entryPx, _Digits),
                TimeToString(exitDt,   TIME_DATE | TIME_MINUTES),
                DoubleToString(exitPx, _Digits),
                DoubleToString(lots, 2),
                DoubleToString(profit, 2),
                DoubleToString(durDays, 1),
                reason);

      ArrayResize(profits, tradeNum);
      profits[tradeNum - 1] = profit;
      totalProfit += profit;
      totalLots   += lots;
      totalDays   += durDays;
   }

   // Riga totale
   FileWrite(fh, "", "", "", "", "", "", "", "", "");
   FileWrite(fh, "TOTALE", "", "", "", "",
             DoubleToString(totalLots, 2),
             DoubleToString(totalProfit, 2),
             DoubleToString(tradeNum > 0 ? totalDays / tradeNum : 0, 1),
             (string)tradeNum + " trades");

   // Istogramma profitti (10 classi dinamiche)
   if(tradeNum > 1)
   {
      double minP = profits[0], maxP = profits[0];
      for(int k = 1; k < tradeNum; k++)
      {
         if(profits[k] < minP) minP = profits[k];
         if(profits[k] > maxP) maxP = profits[k];
      }
      double range    = maxP - minP;
      int    nBuckets = 10;
      double bWidth   = (range > 0) ? range / nBuckets : 1;

      int counts[];
      ArrayResize(counts, nBuckets);
      ArrayInitialize(counts, 0);
      for(int k = 0; k < tradeNum; k++)
      {
         int b = (int)((profits[k] - minP) / bWidth);
         if(b >= nBuckets) b = nBuckets - 1;
         counts[b]++;
      }

      FileWrite(fh, "", "", "", "", "", "", "", "", "");
      FileWrite(fh, "ISTOGRAMMA PROFIT", "Da", "A", "Freq", "Bar", "", "", "", "");
      int maxCount = 0;
      for(int b = 0; b < nBuckets; b++)
         if(counts[b] > maxCount) maxCount = counts[b];

      for(int b = 0; b < nBuckets; b++)
      {
         double lo     = minP + b * bWidth;
         double hi     = lo + bWidth;
         int    barLen = (maxCount > 0) ? (int)MathRound((double)counts[b] / maxCount * 20) : 0;
         string bar    = "";
         for(int s = 0; s < barLen; s++) bar += "#";
         FileWrite(fh, "",
                   DoubleToString(lo, 0),
                   DoubleToString(hi, 0),
                   (string)counts[b],
                   bar, "", "", "", "");
      }
   }

   FileClose(fh);
   Log("CSV | " + filename + " | " + (string)tradeNum + " trades written | FILE_COMMON");
}

//+------------------------------------------------------------------+
// Chart Arrows
//+------------------------------------------------------------------+

void CS6Trader::DrawEntryArrow(datetime time, double price)
{
   if(!_ShowArrows) return;
   string name = "S6_BUY_" + TimeToString(time, TIME_DATE | TIME_MINUTES);
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  241);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      _ArrowBuyColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      _ArrowSize);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   ChartRedraw(0);
}

void CS6Trader::DrawExitArrow(datetime time, double price)
{
   if(!_ShowArrows) return;
   string name = "S6_EXIT_" + TimeToString(time, TIME_DATE | TIME_MINUTES);
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  242);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      _ArrowExitColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      _ArrowSize);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   ChartRedraw(0);
}

void CS6Trader::DrawRsiLevels()
{
   if(!_ShowArrows) return;

   string entryName = "S6_RSI_ENTRY";
   string exitName  = "S6_RSI_EXIT";

   if(ObjectFind(0, entryName) >= 0) ObjectDelete(0, entryName);
   ObjectCreate(0, entryName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, entryName, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0, entryName, OBJPROP_XDISTANCE,  10);
   ObjectSetInteger(0, entryName, OBJPROP_YDISTANCE,  30);
   ObjectSetString(0,  entryName, OBJPROP_TEXT,        "RSI Entry < " + (string)_RsiEntry);
   ObjectSetString(0,  entryName, OBJPROP_FONT,        "Arial Bold");
   ObjectSetInteger(0, entryName, OBJPROP_FONTSIZE,    14);
   ObjectSetInteger(0, entryName, OBJPROP_COLOR,       _ArrowBuyColor);
   ObjectSetInteger(0, entryName, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, entryName, OBJPROP_HIDDEN,      true);

   if(ObjectFind(0, exitName) >= 0) ObjectDelete(0, exitName);
   ObjectCreate(0, exitName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, exitName, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0, exitName, OBJPROP_XDISTANCE,  10);
   ObjectSetInteger(0, exitName, OBJPROP_YDISTANCE,  55);
   ObjectSetString(0,  exitName, OBJPROP_TEXT,        "RSI Exit > " + (string)_RsiExit);
   ObjectSetString(0,  exitName, OBJPROP_FONT,        "Arial Bold");
   ObjectSetInteger(0, exitName, OBJPROP_FONTSIZE,    14);
   ObjectSetInteger(0, exitName, OBJPROP_COLOR,       _ArrowExitColor);
   ObjectSetInteger(0, exitName, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, exitName, OBJPROP_HIDDEN,      true);

   ChartRedraw(0);
}

void CS6Trader::AddIndicatorsToChart()
{
   if(_IndicatorsOnChart) return;
   // Rimuove tutti i pannelli indicatore accumulati tra run consecutivi.
   // Rilegge CHART_WINDOWS_TOTAL a ogni ciclo: la rinumerazione dei subwindow
   // dopo ogni delete invalida un contatore catturato una sola volta.
   int guard = 0;
   while((int)ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL) > 1 && guard < 20)
   {
      int w = (int)ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL) - 1;
      int n = ChartIndicatorsTotal(ChartID(), w);
      for(int i = n - 1; i >= 0; i--)
         ChartIndicatorDelete(ChartID(), w, ChartIndicatorName(ChartID(), w, i));
      guard++;
   }
   ChartIndicatorAdd(ChartID(), 0, _hSMA);
   ChartIndicatorAdd(ChartID(), 1, _hRSI);
   ChartRedraw(ChartID());
   _IndicatorsOnChart = true;
   Log("INIT | Indicators added to chart " + (string)ChartID());
}

void CS6Trader::DeleteAllArrows()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, "S6_BUY_")  == 0 ||
         StringFind(name, "S6_EXIT_") == 0 ||
         StringFind(name, "S6_RECT_") == 0 ||
         StringFind(name, "S6_RLBL_") == 0 ||
         StringFind(name, "S6_RRSI_") == 0 ||
         StringFind(name, "S6_RSI_")  == 0)
         ObjectDelete(0, name);
   }
   ChartRedraw(0);
}

void CS6Trader::DrawTradeRects()
{
   if(!_ShowArrows) return;

   HistorySelect(0, TimeCurrent());
   int total = HistoryDealsTotal();

   for(int i = 0; i < total; i++)
   {
      ulong exitTkt = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(exitTkt, DEAL_MAGIC)  != _MagicNumber)    continue;
      if(HistoryDealGetString(exitTkt,  DEAL_SYMBOL) != _Symbol)         continue;
      if(HistoryDealGetInteger(exitTkt, DEAL_ENTRY)  != DEAL_ENTRY_OUT)  continue;

      double   profit  = HistoryDealGetDouble(exitTkt, DEAL_PROFIT)
                       + HistoryDealGetDouble(exitTkt, DEAL_SWAP)
                       + HistoryDealGetDouble(exitTkt, DEAL_COMMISSION);
      datetime exitDt  = (datetime)HistoryDealGetInteger(exitTkt, DEAL_TIME);
      double   exitPx  = HistoryDealGetDouble(exitTkt, DEAL_PRICE);

      ulong    posId   = (ulong)HistoryDealGetInteger(exitTkt, DEAL_POSITION_ID);
      datetime entryDt = 0;
      double   entryPx = 0;
      for(int j = 0; j < total; j++)
      {
         ulong inTkt = HistoryDealGetTicket(j);
         if((ulong)HistoryDealGetInteger(inTkt, DEAL_POSITION_ID) != posId) continue;
         if(HistoryDealGetInteger(inTkt, DEAL_ENTRY) != DEAL_ENTRY_IN)       continue;
         entryDt = (datetime)HistoryDealGetInteger(inTkt, DEAL_TIME);
         entryPx = HistoryDealGetDouble(inTkt, DEAL_PRICE);
         break;
      }
      if(entryDt == 0) continue;

      // RSI alla barra di entrata (barra[1] rispetto alla barra che ha triggerato l'entry)
      double rsiAtEntry = 0;
      int entryShift = iBarShift(_Symbol, PERIOD_D1, entryDt, false);
      if(entryShift >= 0 && _hRSI != INVALID_HANDLE)
      {
         double rsiBufIn[1];
         if(CopyBuffer(_hRSI, 0, entryShift + 1, 1, rsiBufIn) == 1)
            rsiAtEntry = rsiBufIn[0];
      }

      // RSI alla barra di uscita (barra[1] rispetto alla barra che ha triggerato l'exit)
      double rsiAtExit = 0;
      int exitShift = iBarShift(_Symbol, PERIOD_D1, exitDt, false);
      if(exitShift >= 0 && _hRSI != INVALID_HANDLE)
      {
         double rsiBufOut[1];
         if(CopyBuffer(_hRSI, 0, exitShift + 1, 1, rsiBufOut) == 1)
            rsiAtExit = rsiBufOut[0];
      }

      color  clr      = (profit > 0) ? _ArrowBuyColor : _ArrowExitColor;
      double priceTop = MathMax(entryPx, exitPx);
      double priceBot = MathMin(entryPx, exitPx);
      if(priceTop - priceBot < entryPx * 0.001)
         priceTop = priceBot + entryPx * 0.001;

      string suffix    = TimeToString(exitDt, TIME_DATE | TIME_MINUTES);
      string rectName  = "S6_RECT_" + suffix;
      string labelName = "S6_RLBL_" + suffix;

      if(ObjectFind(0, rectName) >= 0) ObjectDelete(0, rectName);
      ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, entryDt, priceTop, exitDt, priceBot);
      ObjectSetInteger(0, rectName, OBJPROP_COLOR,      clr);
      ObjectSetInteger(0, rectName, OBJPROP_FILL,       true);
      ObjectSetInteger(0, rectName, OBJPROP_BACK,       true);
      ObjectSetInteger(0, rectName, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, rectName, OBJPROP_HIDDEN,     true);

      string sign      = (profit >= 0) ? "+" : "";
      string rsiInStr  = (rsiAtEntry > 0) ? DoubleToString(rsiAtEntry, 0) : "?";
      string rsiOutStr = (rsiAtExit  > 0) ? DoubleToString(rsiAtExit,  0) : "?";

      // Etichetta profitto (angolo top-right del rettangolo)
      string profitText = sign + DoubleToString(profit, 0);
      if(ObjectFind(0, labelName) >= 0) ObjectDelete(0, labelName);
      ObjectCreate(0, labelName, OBJ_TEXT, 0, exitDt, priceTop);
      ObjectSetString(0,  labelName, OBJPROP_TEXT,       profitText);
      ObjectSetString(0,  labelName, OBJPROP_FONT,       "Arial Bold");
      ObjectSetInteger(0, labelName, OBJPROP_COLOR,      clr);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE,   9);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR,     ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, labelName, OBJPROP_HIDDEN,     true);

      // Etichetta RSI (angolo top-left, giallo bold)
      string rsiName = "S6_RRSI_" + suffix;
      string rsiText = "RSI:" + rsiInStr + "→" + rsiOutStr;
      if(ObjectFind(0, rsiName) >= 0) ObjectDelete(0, rsiName);
      ObjectCreate(0, rsiName, OBJ_TEXT, 0, entryDt, priceTop);
      ObjectSetString(0,  rsiName, OBJPROP_TEXT,       rsiText);
      ObjectSetString(0,  rsiName, OBJPROP_FONT,       "Arial Bold");
      ObjectSetInteger(0, rsiName, OBJPROP_COLOR,      clrYellow);
      ObjectSetInteger(0, rsiName, OBJPROP_FONTSIZE,   9);
      ObjectSetInteger(0, rsiName, OBJPROP_ANCHOR,     ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, rsiName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, rsiName, OBJPROP_HIDDEN,     true);
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+

void CS6Trader::GenerateFinalReport()
{
   double winRate, pf, maxDD, avgDays;
   CalcStats(winRate, pf, maxDD, avgDays);

   Log("FINAL REPORT | Trades: " + (string)_TotalTrades +
       " | WR: "    + DoubleToString(winRate, 1) + "%" +
       " | PF: "    + DoubleToString(pf, 2) +
       " | MaxDD: " + DoubleToString(maxDD, 2) + "%" +
       " | AvgDays: " + DoubleToString(avgDays, 1));

   WriteTradesToCSV();
   DrawTradeRects();
}
//+------------------------------------------------------------------+
