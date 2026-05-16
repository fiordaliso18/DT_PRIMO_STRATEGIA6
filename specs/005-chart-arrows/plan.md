---
feature: FEAT-005
title: Frecce sul Grafico
type: plan
status: implemented
release: MVP
layer: implementation
language: English + Italian comments
platform: MT5 / MQL5
architecture: DroidTrader v2
---
# FEAT-005 — Frecce sul Grafico · IMPLEMENTAZIONE
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

## Nuovi Input (S6_EA.mq5)

```mql5
input group "===== CHART ARROWS ====="
input bool   ShowArrows     = true;              // Frecce sul grafico
input int    ArrowSize      = 3;                 // Dimensione frecce (1-5)
input color  ArrowBuyColor  = clrDodgerBlue;     // Colore freccia entrata
input color  ArrowExitColor = clrOrangeRed;      // Colore freccia uscita
```

Passati al costruttore di `CS6Trader`:
```mql5
_trader = new CS6Trader(..., ShowArrows, ArrowSize, ArrowBuyColor, ArrowExitColor);
```

---

## Nuovi Membri Privati (CS6Trader)

```mql5
bool   _ShowArrows;
int    _ArrowSize;
color  _ArrowBuyColor;
color  _ArrowExitColor;
bool   _IndicatorsOnChart;   // guard: ChartIndicatorAdd eseguito una sola volta al primo tick
```

---

## Metodi Privati

### DrawEntryArrow — [S6-005-R001], [S6-005-R003], [S6-005-R004], [S6-005-R007]

```mql5
void CS6Trader::DrawEntryArrow(datetime time, double price)
{
   if(!_ShowArrows) return;                              // [S6-005-R005]
   string name = "S6_BUY_" + TimeToString(time, TIME_DATE | TIME_MINUTES);
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 241);   // freccia su
   ObjectSetInteger(0, name, OBJPROP_COLOR,     _ArrowBuyColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,     _ArrowSize);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,    true);
   ChartRedraw(0);
}
```

### DrawExitArrow — [S6-005-R002], [S6-005-R003], [S6-005-R004], [S6-005-R007]

```mql5
void CS6Trader::DrawExitArrow(datetime time, double price)
{
   if(!_ShowArrows) return;                              // [S6-005-R005]
   string name = "S6_EXIT_" + TimeToString(time, TIME_DATE | TIME_MINUTES);
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 242);   // freccia giu
   ObjectSetInteger(0, name, OBJPROP_COLOR,     _ArrowExitColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,     _ArrowSize);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,    true);
   ChartRedraw(0);
}
```

### AddIndicatorsToChart

Aggiunge SMA(200) e RSI(14) al grafico Strategy Tester tramite `ChartIndicatorAdd()`.
Chiamata al **primo tick** da `TradeOnTick()` — il grafico non è ancora pronto durante `OnInit()` in Strategy Tester.
Il guard interno `_IndicatorsOnChart` garantisce esecuzione unica.

```mql5
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
   ChartIndicatorAdd(ChartID(), 0, _hSMA);   // subwindow 0 — grafico prezzi
   ChartIndicatorAdd(ChartID(), 1, _hRSI);   // subwindow 1 — pannello RSI
   ChartRedraw(ChartID());
   _IndicatorsOnChart = true;
   Log("INIT | Indicators added to chart " + (string)ChartID());
}
```

---

### DrawRsiLevels — [S6-005-R001], [S6-005-R003], [S6-005-R005]

Disegna due `OBJ_LABEL` fissi nell'angolo in alto a sinistra del grafico con i parametri di entrata e uscita RSI.
Chiamato da `Init()` — persiste per tutta la sessione.

```mql5
void CS6Trader::DrawRsiLevels()
{
   if(!_ShowArrows) return;

   string entryName = "S6_RSI_ENTRY";
   string exitName  = "S6_RSI_EXIT";

   if(ObjectFind(0, entryName) >= 0) ObjectDelete(0, entryName);
   ObjectCreate(0, entryName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, entryName, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, entryName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, entryName, OBJPROP_YDISTANCE, 30);
   ObjectSetString(0,  entryName, OBJPROP_TEXT,       "RSI Entry < " + (string)_RsiEntry);
   ObjectSetString(0,  entryName, OBJPROP_FONT,       "Arial Bold");
   ObjectSetInteger(0, entryName, OBJPROP_FONTSIZE,   14);
   ObjectSetInteger(0, entryName, OBJPROP_COLOR,      _ArrowBuyColor);
   ObjectSetInteger(0, entryName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, entryName, OBJPROP_HIDDEN,     true);

   if(ObjectFind(0, exitName) >= 0) ObjectDelete(0, exitName);
   ObjectCreate(0, exitName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, exitName, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, exitName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, exitName, OBJPROP_YDISTANCE, 55);
   ObjectSetString(0,  exitName, OBJPROP_TEXT,       "RSI Exit > " + (string)_RsiExit);
   ObjectSetString(0,  exitName, OBJPROP_FONT,       "Arial Bold");
   ObjectSetInteger(0, exitName, OBJPROP_FONTSIZE,   14);
   ObjectSetInteger(0, exitName, OBJPROP_COLOR,      _ArrowExitColor);
   ObjectSetInteger(0, exitName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, exitName, OBJPROP_HIDDEN,     true);

   ChartRedraw(0);
}
```

### DeleteAllArrows — [S6-005-R006]

Rimuove tutti gli oggetti grafici S6 (frecce, rettangoli, label RSI).

```mql5
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
```

---

## Punti di Chiamata

| Metodo | Chiamato in | Condizione |
|---|---|---|
| `AddIndicatorsToChart` | `TradeOnTick()` — primo tick | `_IndicatorsOnChart == false` |
| `DrawEntryArrow` | `OpenPosition()` dopo `_Trade.Buy()` OK | `_ShowArrows == true` |
| `DrawExitArrow` | `ClosePosition()` dopo `_Trade.PositionClose()` OK | `_ShowArrows == true` |
| `DrawRsiLevels` | `Init()` — una sola volta all'avvio | `_ShowArrows == true` |
| `DeleteAllArrows` | — non chiamato automaticamente — | rimozione manuale da MT5 |

---

## Codici Freccia MQL5

| Codice | Simbolo |
|---|---|
| 241 | Freccia su (▲) — entrata BUY |
| 242 | Freccia giù (▼) — uscita |

`OBJPROP_WIDTH` = 1–5 controlla la dimensione dell'oggetto freccia.

---

## Note Implementative

- In Strategy Tester non visuale, `ObjectCreate()` viene ignorato silenziosamente — nessun errore.
- `ShowArrows=false` azzerare il lavoro grafico per le sessioni di ottimizzazione Walk-Forward.
- `OBJPROP_HIDDEN=true` nasconde le frecce dal pannello oggetti per non intasare la lista.
- `OBJPROP_SELECTABLE=false` impedisce all'utente di selezionare/spostare accidentalmente le frecce.
