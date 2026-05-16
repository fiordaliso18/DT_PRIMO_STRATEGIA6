# Test Spec — FEAT-005 Frecce sul Grafico
**Feature:** FEAT-005
**Piattaforma di test:** MetaTrader 5 Strategy Tester — modalità visuale
**Parametri:** caricare `tests\backtest\S6_EA.set`

---

## Setup

1. Apri Strategy Tester in MT5
2. Simbolo: US500, Timeframe: D1
3. Modalità: **Visual mode** (obbligatorio per vedere le frecce)
4. Periodo: 2020-01-01 → 2024-12-31
5. Carica `tests\backtest\S6_EA.set`
6. Verifica che `ShowArrows=true`, `ArrowSize=3`

---

## Test Cases

### T001 — Freccia BUY visibile all'entrata
**Verifica:** al momento dell'apertura di un trade, osserva il grafico
**Atteso:** freccia blu verso l'alto appare sul grafico al prezzo di entrata

### T002 — Freccia EXIT visibile alla chiusura
**Verifica:** al momento della chiusura di un trade, osserva il grafico
**Atteso:** freccia arancione verso il basso appare al prezzo di chiusura

### T003 — Dimensione frecce
**Setup:** esegui due backtest con `ArrowSize=1` e `ArrowSize=5`
**Atteso:** frecce con size=5 visibilmente più grandi

### T004 — Colori personalizzati
**Setup:** imposta `ArrowBuyColor=clrGreen`, `ArrowExitColor=clrRed`
**Atteso:** freccia BUY verde, freccia EXIT rossa

### T005 — ShowArrows=false
**Setup:** imposta `ShowArrows=false`, esegui backtest visuale
**Atteso:** nessuna freccia sul grafico
**Journal:** nessun log relativo alle frecce

### T006 — Pulizia al termine
**Verifica:** al termine del backtest (o rimozione EA dal grafico live)
**Atteso:** tutte le frecce S6_BUY_* e S6_EXIT_* spariscono dal grafico
