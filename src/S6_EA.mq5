//+------------------------------------------------------------------+
//|                                                       S6_EA.mq5   |
//|                                              Primo Fiordaliso    |
//| S6 Swing Mean Reversion Daily — thin orchestrator               |
//| All trading logic is in Trader/CS6Trader.mqh                    |
//+------------------------------------------------------------------+
#property copyright "Primo Fiordaliso"
#property version   "2.00"
#property strict

#include "Trader/CS6Trader.mqh"

//================================================================
//  INPUT PARAMETERS
//================================================================
input group "===== S6 STRATEGY ====="
input double RiskPercent    = 1.0;        // % del capitale rischiato per trade
input int    SMA_Period     = 200;        // Periodo SMA (filtro di trend)
input int    RSI_Period     = 14;         // Periodo RSI
input int    RSI_Entry      = 35;         // Soglia RSI entrata (BUY se RSI < soglia)
input int    RSI_Exit       = 50;         // Soglia RSI uscita (CLOSE se RSI > soglia)
input double SL_Percent     = 2.0;        // Stop Loss % dal prezzo di entrata
input int    MaxDays        = 15;         // Durata massima posizione in giorni
input int    MagicNumber    = 20260509;   // Identificatore univoco EA
input bool   EnablePhase2   = false;      // Abilita funzionalita' Phase 2

input group "===== CHART ARROWS ====="
input bool   ShowArrows     = true;           // Frecce sul grafico
input int    ArrowSize      = 3;              // Dimensione frecce (1-5)
input color  ArrowBuyColor  = clrDodgerBlue;  // Colore freccia entrata
input color  ArrowExitColor = clrOrangeRed;   // Colore freccia uscita

//================================================================
//  GLOBAL
//================================================================
CS6Trader *_trader;

//================================================================
//  EVENT CALLBACKS
//================================================================
int OnInit()
{
   _trader = new CS6Trader(MagicNumber, SMA_Period, RSI_Period, RSI_Entry, RSI_Exit,
                           SL_Percent, MaxDays, RiskPercent, EnablePhase2,
                           ShowArrows, ArrowSize, ArrowBuyColor, ArrowExitColor);
   if(!_trader.Init())
   {
      delete _trader;
      _trader = NULL;
      return INIT_FAILED;
   }
   return INIT_SUCCEEDED;
}

void OnTick()
{
   _trader.Tick();
}

void OnDeinit(const int reason)
{
   if(_trader != NULL)
   {
      _trader.GenerateFinalReport();
      _trader.Deinit();
      delete _trader;
      _trader = NULL;
   }
}
//+------------------------------------------------------------------+
