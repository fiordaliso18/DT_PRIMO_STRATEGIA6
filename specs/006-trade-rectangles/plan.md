---
feature: FEAT-006
title: Rettangoli Trade sul Grafico
type: plan
status: implemented
release: MVP
layer: implementation
language: English + Italian comments
platform: MT5 / MQL5
architecture: DroidTrader v2
---
# FEAT-006 — Rettangoli Trade sul Grafico · IMPLEMENTAZIONE

---

## Metodo: CS6Trader::DrawTradeRects

Chiamato da `GenerateFinalReport()` dopo `WriteTradesToCSV()`.
Scansiona la history deals e disegna rettangolo + due etichette per ogni trade.

```mql5
void CS6Trader::DrawTradeRects()
{
   if(!_ShowArrows) return;                       // [S6-006-R005]

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

      // Cerca deal di entrata tramite DEAL_POSITION_ID
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

      color  clr      = (profit > 0) ? _ArrowBuyColor : _ArrowExitColor; // [S6-006-R002]
      double priceTop = MathMax(entryPx, exitPx);
      double priceBot = MathMin(entryPx, exitPx);
      if(priceTop - priceBot < entryPx * 0.001)       // altezza minima visibile
         priceTop = priceBot + entryPx * 0.001;

      string suffix    = TimeToString(exitDt, TIME_DATE | TIME_MINUTES);
      string rectName  = "S6_RECT_" + suffix;          // [S6-006-R006]
      string labelName = "S6_RLBL_" + suffix;
      string rsiName   = "S6_RRSI_" + suffix;

      // Rettangolo in background — [S6-006-R001], [S6-006-R004]
      if(ObjectFind(0, rectName) >= 0) ObjectDelete(0, rectName);
      ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, entryDt, priceTop, exitDt, priceBot);
      ObjectSetInteger(0, rectName, OBJPROP_COLOR,      clr);
      ObjectSetInteger(0, rectName, OBJPROP_FILL,       true);
      ObjectSetInteger(0, rectName, OBJPROP_BACK,       true);
      ObjectSetInteger(0, rectName, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, rectName, OBJPROP_HIDDEN,     true);

      // Etichetta profitto — angolo top-right — [S6-006-R003]
      string sign = (profit >= 0) ? "+" : "";
      if(ObjectFind(0, labelName) >= 0) ObjectDelete(0, labelName);
      ObjectCreate(0, labelName, OBJ_TEXT, 0, exitDt, priceTop);
      ObjectSetString(0,  labelName, OBJPROP_TEXT,       sign + DoubleToString(profit, 0));
      ObjectSetString(0,  labelName, OBJPROP_FONT,       "Arial Bold");
      ObjectSetInteger(0, labelName, OBJPROP_COLOR,      clr);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE,   9);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR,     ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, labelName, OBJPROP_HIDDEN,     true);

      // Etichetta RSI entrata→uscita — angolo top-left — [S6-006-R003], [S6-006-R008]
      string rsiInStr  = (rsiAtEntry > 0) ? DoubleToString(rsiAtEntry, 0) : "?";
      string rsiOutStr = (rsiAtExit  > 0) ? DoubleToString(rsiAtExit,  0) : "?";
      if(ObjectFind(0, rsiName) >= 0) ObjectDelete(0, rsiName);
      ObjectCreate(0, rsiName, OBJ_TEXT, 0, entryDt, priceTop);
      ObjectSetString(0,  rsiName, OBJPROP_TEXT,       "RSI:" + rsiInStr + "→" + rsiOutStr);
      ObjectSetString(0,  rsiName, OBJPROP_FONT,       "Arial Bold");
      ObjectSetInteger(0, rsiName, OBJPROP_COLOR,      clrYellow);
      ObjectSetInteger(0, rsiName, OBJPROP_FONTSIZE,   9);
      ObjectSetInteger(0, rsiName, OBJPROP_ANCHOR,     ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, rsiName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, rsiName, OBJPROP_HIDDEN,     true);
   }
   ChartRedraw(0);
}
```

## Integrazione in GenerateFinalReport

```mql5
void CS6Trader::GenerateFinalReport()
{
   // ... stats e CSV ...
   WriteTradesToCSV();
   DrawTradeRects();
}
```

## Aggiornamento DeleteAllArrows

Filtra tutti i prefissi S6: `S6_RECT_`, `S6_RLBL_`, `S6_RRSI_`, `S6_RSI_`, `S6_BUY_`, `S6_EXIT_`.
