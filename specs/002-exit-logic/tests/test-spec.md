# Test Spec — FEAT-002 Logica di Uscita
**Feature:** FEAT-002
**Piattaforma di test:** MetaTrader 5 Strategy Tester
**Modalità consigliata:** Open prices only
**Parametri:** caricare `tests\backtest\S6_EA.set`

---

## Setup

1. Apri Strategy Tester in MT5
2. Simbolo: US500, Timeframe: D1
3. Modalità: Open prices only
4. Carica `tests\backtest\S6_EA.set` via Inputs → Load
5. Esegui backtest 2020-01-01 → 2024-12-31

---

## Test Cases

### T001 — Distribuzione motivi di uscita
**Verifica:** apri S6_trades.csv, colonna "Reason"
**Atteso:** presenza di almeno due delle tre categorie: RSI_EXIT, SL, TIMEOUT

### T002 — Uscita RSI_EXIT
**Verifica:** per ogni riga con Reason=RSI_EXIT nel CSV
**Atteso:** la durata (DurationDays) è ≤ MaxDays (15)

### T003 — Uscita TIMEOUT
**Verifica:** per ogni riga con Reason=TIMEOUT nel CSV
**Atteso:** DurationDays ≥ MaxDays - 1 (circa 15 giorni)

### T004 — Uscita SL
**Verifica:** per ogni riga con Reason=SL nel CSV
**Atteso:** Profit < 0 (le uscite per SL sono sempre in perdita)

### T005 — SL non modificato
**Verifica:** modalità visuale — osserva la linea SL sul grafico durante la vita di un trade
**Atteso:** la linea SL rimane fissa al livello iniziale per tutta la durata del trade

### T006 — Priorità RSI su Timeout
**Setup:** imposta MaxDays=3 (timeout molto breve)
**Verifica:** verifica che trade con durata 3 giorni in cui RSI > RSI_Exit
siano classificati come RSI_EXIT non TIMEOUT
**Atteso:** se RSI supera la soglia prima del timeout, Reason = RSI_EXIT

---

## Output Attesi

Dopo il backtest:
- Colonna "Reason" nel CSV valorizzata correttamente per ogni trade
- Nessun trade con Reason vuota o "S6 entry"
- Log "CLOSE | RSI_EXIT" / "CLOSE | TIMEOUT" nel Journal per uscite gestite dall'EA
