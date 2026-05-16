# Test Spec — FEAT-004 Reporting CSV e Journal
**Feature:** FEAT-004
**Piattaforma di test:** MetaTrader 5 Strategy Tester
**Modalità consigliata:** Open prices only
**Parametri:** caricare `tests\backtest\S6_EA.set`

---

## Setup

1. Apri Strategy Tester in MT5
2. Simbolo: US500, Timeframe: D1
3. Modalità: Open prices only
4. Carica `tests\backtest\S6_EA.set` via Inputs → Load
5. Esegui backtest 2020-01-01 → 2024-12-31 (NON visuale)
6. Al termine, cerca il CSV nel percorso:
   `%APPDATA%\MetaQuotes\Tester\73B7A2420D6397DFF9014A20F1201F97\Agent-127.0.0.1-XXXX\MQL5\Files\S6_trades.csv`

---

## Test Cases

### T001 — File CSV creato
**Verifica:** il file `S6_trades.csv` esiste nella cartella Files del Tester Agent
**Atteso:** file presente ✓
**Journal:** cerca "CSV | S6_trades.csv | N trades written"

### T002 — Intestazione corretta
**Verifica:** apri il CSV in Blocco Note
**Atteso:** prima riga = `Trade;EntryDate;EntryPrice;ExitDate;ExitPrice;Lots;Profit;DurationDays;Reason`

### T003 — Colonne separate in Excel
**Verifica:** apri il CSV in Excel (doppio click su Windows con impostazioni italiane)
**Atteso:** ogni campo in una colonna separata (9 colonne totali)
**Fail:** tutto nella colonna A → problema delimitatore

### T004 — Numero righe = numero trade
**Verifica:** conta le righe dati nel CSV
**Atteso:** N righe = N trade visibili nel report MT5 Strategy Tester

### T005 — Colonna Reason valorizzata
**Verifica:** nessuna cella vuota nella colonna Reason
**Atteso:** ogni riga ha RSI_EXIT, SL, o TIMEOUT

### T006 — Profitto netto (swap incluso)
**Verifica:** per alcuni trade con swap significativo,
controlla che il valore CSV differisca dal profitto lordo MT5
**Atteso:** Profit CSV = DEAL_PROFIT + DEAL_SWAP + DEAL_COMMISSION

### T007 — Report finale nel Journal
**Verifica:** cerca nel Journal il messaggio "FINAL REPORT"
**Atteso:** "[S6] FINAL REPORT | Trades: N | WR: X% | PF: Y | MaxDD: Z% | AvgDays: W"

### T008 — Commento sul grafico (modalità visuale)
**Setup:** esegui backtest in modalità visuale
**Verifica:** osserva il commento in alto a sinistra del grafico durante il test
**Atteso:** aggiornamento a ogni barra con "S6 EA | WR: X% (A/B) | MaxDD: Z%"

---

## Analisi CSV post-backtest

Dopo il backtest, apri il CSV in Excel e verifica:
- Distribuzione Reason: % RSI_EXIT vs SL vs TIMEOUT
- Profit medio per categoria
- DurationDays: i TIMEOUT devono avere durata ≈ MaxDays (15 gg)
- I trade SL devono avere Profit < 0
