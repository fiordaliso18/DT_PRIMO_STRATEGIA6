#property copyright "Primo"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

//================================================================
//  INPUT PARAMETERS
//================================================================
input double RiskPercent    = 1.0;        // % account balance risked per trade
input int    SMA_Period     = 200;        // SMA period
input int    RSI_Period     = 14;         // RSI period
input int    RSI_Entry      = 32;         // RSI entry threshold (buy below)
input int    RSI_Exit       = 50;         // RSI exit threshold (close above)
input double SL_Percent     = 2.0;        // Stop Loss % from entry price
input int    MaxDays        = 15;         // Maximum holding period in days
input int    ReportInterval = 8;          // Periodic report interval in hours [Phase 2]
input int    MagicNumber    = 20260509;   // EA unique identifier
input bool   EnablePhase2   = false;      // Enable Phase 2 features

//================================================================
//  GLOBAL STATE
//================================================================
datetime lastBarTime = 0;
datetime entryTime   = 0;    // orario apertura posizione corrente (per MaxDays)
double   equityHigh  = 0.0;
double   maxDrawdown = 0.0;
int      totalTrades = 0;
int      winTrades   = 0;
int      hSMA        = INVALID_HANDLE;
int      hRSI        = INVALID_HANDLE;
bool     isWarmedUp  = false;
bool     pendingEntry = false;
CTrade   trade;

//================================================================
//  SIGNAL ENGINE
//================================================================
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_D1, 0);
   if(currentBarTime == 0)
   {
      LogEvent("ERROR | iTime returned 0 — data not ready");
      return false;
   }
   if(currentBarTime == lastBarTime) return false;
   lastBarTime = currentBarTime;
   return true;
}

bool IsWarmedUp()
{
   int minBars = SMA_Period + RSI_Period + 1;
   if(Bars(_Symbol, PERIOD_D1) < minBars)
   {
      LogEvent("WARMUP | Insufficient bars: " + (string)Bars(_Symbol, PERIOD_D1) +
               " / " + (string)minBars + " needed");
      return false;
   }
   if(!isWarmedUp)
   {
      isWarmedUp = true;
      LogEvent("WARMUP | Warm-up complete — bars: " + (string)Bars(_Symbol, PERIOD_D1));
   }
   return true;
}

double g_smaValue = 0.0;   // valore SMA closed bar — aggiornato da ReadIndicators()
double g_rsiValue = 0.0;   // valore RSI closed bar — aggiornato da ReadIndicators()

bool ReadIndicators()
{
   double smaBuffer[1], rsiBuffer[1];
   if(CopyBuffer(hSMA, 0, 1, 1, smaBuffer) < 1)
   {
      LogEvent("ERROR | CopyBuffer SMA failed | Code: " + (string)GetLastError());
      return false;
   }
   if(CopyBuffer(hRSI, 0, 1, 1, rsiBuffer) < 1)
   {
      LogEvent("ERROR | CopyBuffer RSI failed | Code: " + (string)GetLastError());
      return false;
   }
   g_smaValue = smaBuffer[0];
   g_rsiValue = rsiBuffer[0];
   return true;
}

bool HasOpenPosition()
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC)  == MagicNumber)
         return true;
   }
   return false;
}


bool CheckEntryConditions()
{
   if(HasOpenPosition()) return false;

   double closePrice = iClose(_Symbol, PERIOD_D1, 1);
   if(closePrice <= g_smaValue)  return false;
   if(g_rsiValue  >= RSI_Entry)  return false;

   LogEvent("SIGNAL | Entry conditions met" +
            " | Close: " + DoubleToString(closePrice, _Digits) +
            " SMA: "      + DoubleToString(g_smaValue, _Digits) +
            " RSI: "      + DoubleToString(g_rsiValue, 2));

   if(OpenPosition())
   {
      entryTime = TimeCurrent();
      totalTrades++;
   }
   else if(trade.ResultRetcode() == TRADE_RETCODE_MARKET_CLOSED)
   {
      pendingEntry = true;
      LogEvent("INFO | Market closed at bar open — entry pending for next tick");
   }
   return true;
}

bool CheckExitConditions()
{
   if(!HasOpenPosition()) return false;

   if(g_rsiValue > RSI_Exit)
   {
      ClosePosition("RSI_EXIT");
      return true;
   }

   if(entryTime > 0)
   {
      int daysOpen = (int)((TimeCurrent() - entryTime) / 86400);
      if(daysOpen >= MaxDays)
      {
         LogEvent("INFO | Timeout | Days open: " + (string)daysOpen);
         ClosePosition("TIMEOUT");
         return true;
      }
   }

   return false;
}

//================================================================
//  ORDER MANAGER
//================================================================
bool OpenPosition()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
      !MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      LogEvent("SKIP | Trading not allowed");
      return false;
   }

   double ask      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double slPrice  = ask * (1.0 - SL_Percent / 100.0);
   double slPoints = (ask - slPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   long   minStop  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

   if(slPoints < (double)minStop)
   {
      LogEvent("SKIP | SL distance " + DoubleToString(slPoints, 0) +
               " pts < broker min " + (string)minStop);
      return false;
   }

   double lots = CalculateLots();
   if(lots <= 0.0) return false;

   if(!trade.Buy(lots, _Symbol, 0, slPrice, 0, "S6 entry"))
   {
      LogEvent("ERROR | OrderSend failed | Code: " + (string)GetLastError());
      return false;
   }

   LogEvent("ORDER | BUY placed | Lots: " + DoubleToString(lots, 2) +
            " | SL: " + DoubleToString(slPrice, _Digits));
   return true;
}

bool ClosePosition(string reason)
{
   if(!trade.PositionClose(_Symbol))
   {
      LogEvent("ERROR | PositionClose failed | Code: " + (string)GetLastError());
      return false;
   }
   LogEvent("CLOSE | " + reason);
   return true;
}

//================================================================
//  RISK CALCULATOR
//================================================================
double CalculateLots()
{
   double slPrice  = SymbolInfoDouble(_Symbol, SYMBOL_ASK) * (1.0 - SL_Percent / 100.0);
   double slPoints = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - slPrice)
                     / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double volStep   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double volMin    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volMax    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(slPoints <= 0 || tickValue <= 0 || tickSize <= 0 || volStep <= 0)
   {
      LogEvent("ERROR | CalculateLots: invalid symbol data");
      return 0.0;
   }

   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100.0;
   double rawLots    = riskAmount / (slPoints * tickValue / tickSize);
   double lots       = MathFloor(rawLots / volStep) * volStep;

   if(lots < volMin)
   {
      LogEvent("SKIP | Lots " + DoubleToString(lots, 2) +
               " below broker minimum " + DoubleToString(volMin, 2));
      return 0.0;
   }
   if(lots > volMax)
   {
      lots = volMax;
      LogEvent("INFO | Lots capped at broker maximum " + DoubleToString(volMax, 2));
   }

   return lots;
}

//================================================================
//  REPORT ENGINE + LOGGER
//================================================================
void LogEvent(string msg)
{
   Print("[S6] " + msg);
}

void CalcStats(double &outWinRate, double &outPF, double &outMaxDD, double &outAvgDays)
{
   int    wins = 0, losses = 0, trades = 0;
   double grossProfit = 0.0, grossLoss = 0.0;
   double totalDays   = 0.0;

   HistorySelect(0, TimeCurrent());
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC)  != MagicNumber)  continue;
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
         ulong inTicket = HistoryDealGetTicket(j);
         if((ulong)HistoryDealGetInteger(inTicket, DEAL_POSITION_ID) != posId) continue;
         if(HistoryDealGetInteger(inTicket, DEAL_ENTRY) != DEAL_ENTRY_IN)       continue;
         totalDays += (double)(exitTime - (datetime)HistoryDealGetInteger(inTicket, DEAL_TIME)) / 86400.0;
         break;
      }
   }

   outWinRate = (trades > 0) ? (double)wins / trades * 100.0 : 0.0;
   outPF      = (grossLoss > 0) ? grossProfit / grossLoss : 0.0;
   outMaxDD   = maxDrawdown;
   outAvgDays = (trades > 0) ? totalDays / trades : 0.0;
   totalTrades = trades;
   winTrades   = wins;
}

void UpdateReport()
{
   double winRate, pf, maxDD, avgDays;
   CalcStats(winRate, pf, maxDD, avgDays);

   Comment(StringFormat("S6 EA | WR: %.1f%% (%d/%d) | MaxDD: %.2f%%",
           winRate, winTrades, totalTrades, maxDD));

   if(EnablePhase2)
   {
      // stub Phase 2 — Story 3.1
   }
}

void GenerateFinalReport()
{
   double winRate, pf, maxDD, avgDays;
   CalcStats(winRate, pf, maxDD, avgDays);

   LogEvent("FINAL REPORT | Trades: " + (string)totalTrades +
            " | WR: "    + DoubleToString(winRate, 1) + "%" +
            " | PF: "    + DoubleToString(pf, 2) +
            " | MaxDD: " + DoubleToString(maxDD, 2) + "%" +
            " | AvgDays: " + DoubleToString(avgDays, 1));
}

//================================================================
//  EVENT CALLBACKS
//================================================================
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   equityHigh  = AccountInfoDouble(ACCOUNT_EQUITY);
   maxDrawdown = 0.0;
   lastBarTime  = iTime(_Symbol, PERIOD_D1, 0);
   isWarmedUp   = false;
   pendingEntry = false;

   hSMA = iMA(_Symbol, PERIOD_D1, SMA_Period, 0, MODE_SMA, PRICE_CLOSE);
   if(hSMA == INVALID_HANDLE)
   {
      LogEvent("ERROR | SMA handle creation failed | Code: " + (string)GetLastError());
      return INIT_FAILED;
   }
   ChartIndicatorAdd(0, 0, hSMA);

   hRSI = iRSI(_Symbol, PERIOD_D1, RSI_Period, PRICE_CLOSE);
   if(hRSI == INVALID_HANDLE)
   {
      LogEvent("ERROR | RSI handle creation failed | Code: " + (string)GetLastError());
      return INIT_FAILED;
   }

   // Restart recovery: scansiona posizioni aperte per MagicNumber
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC)  == MagicNumber)
      {
         entryTime = (datetime)PositionGetInteger(POSITION_TIME);
         LogEvent("RECOVERY | Posizione esistente rilevata | Ticket: " + (string)ticket +
                  " | Aperta: " + TimeToString(entryTime));
         break;
      }
   }

   LogEvent("EA initialized | MagicNumber: " + (string)MagicNumber +
            " | SMA(" + (string)SMA_Period + ") RSI(" + (string)RSI_Period + ")" +
            " | EnablePhase2: " + (string)EnablePhase2);
   return INIT_SUCCEEDED;
}

void OnTick()
{
   if(pendingEntry && !HasOpenPosition())
   {
      if(OpenPosition())
      {
         pendingEntry = false;
         entryTime    = TimeCurrent();
         totalTrades++;
         LogEvent("INFO | Pending entry executed after market open");
      }
      return;
   }

   if(!IsNewBar()) return;
   pendingEntry = false;

   if(!IsWarmedUp())     return;
   if(!ReadIndicators()) return;

   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(currentEquity > equityHigh) equityHigh = currentEquity;
   if(equityHigh > 0)
   {
      double dd = (equityHigh - currentEquity) / equityHigh * 100.0;
      if(dd > maxDrawdown) maxDrawdown = dd;
   }

   CheckExitConditions();
   CheckEntryConditions();
   UpdateReport();
}

void OnDeinit(const int reason)
{
   GenerateFinalReport();
   IndicatorRelease(hSMA); hSMA = INVALID_HANDLE;
   IndicatorRelease(hRSI); hRSI = INVALID_HANDLE;
   LogEvent("EA deinitialized | Reason: " + (string)reason);
}
