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
double   equityHigh  = 0.0;
int      totalTrades = 0;
int      winTrades   = 0;
int      hSMA        = INVALID_HANDLE;
int      hRSI        = INVALID_HANDLE;
bool     isWarmedUp  = false;
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
   // stub — Story 2.3
   return false;
}

bool CheckEntryConditions()
{
   // stub — Story 2.3
   return false;
}

bool CheckExitConditions()
{
   // stub — Story 2.3
   return false;
}

//================================================================
//  ORDER MANAGER
//================================================================
bool OpenPosition()
{
   // stub — Story 2.2
   return false;
}

bool ClosePosition(string reason)
{
   // stub — Story 2.2
   LogEvent("CLOSE | " + reason);
   return false;
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

void UpdateReport()
{
   // stub — Story 2.4
}

void GenerateFinalReport()
{
   // stub — Story 2.4
}

//================================================================
//  EVENT CALLBACKS
//================================================================
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   equityHigh  = AccountInfoDouble(ACCOUNT_EQUITY);
   lastBarTime = iTime(_Symbol, PERIOD_D1, 0);
   isWarmedUp  = false;

   hSMA = iMA(_Symbol, PERIOD_D1, SMA_Period, 0, MODE_SMA, PRICE_CLOSE);
   if(hSMA == INVALID_HANDLE)
   {
      LogEvent("ERROR | SMA handle creation failed | Code: " + (string)GetLastError());
      return INIT_FAILED;
   }

   hRSI = iRSI(_Symbol, PERIOD_D1, RSI_Period, PRICE_CLOSE);
   if(hRSI == INVALID_HANDLE)
   {
      LogEvent("ERROR | RSI handle creation failed | Code: " + (string)GetLastError());
      return INIT_FAILED;
   }

   LogEvent("EA initialized | MagicNumber: " + (string)MagicNumber +
            " | SMA(" + (string)SMA_Period + ") RSI(" + (string)RSI_Period + ")" +
            " | EnablePhase2: " + (string)EnablePhase2);
   return INIT_SUCCEEDED;
}

void OnTick()
{
   if(!IsNewBar())       return;
   if(!IsWarmedUp())     return;
   if(!ReadIndicators()) return;

   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(currentEquity > equityHigh) equityHigh = currentEquity;

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
