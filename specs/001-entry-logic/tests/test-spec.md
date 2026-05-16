# Test Spec — FEAT-001 Logica di Entrata
**Feature:** FEAT-001
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

### T001 — Entrata eseguita con condizioni soddisfatte
**Verifica:** nel Journal cerca "SIGNAL | Entry conditions met" seguito da "ORDER | BUY placed"
**Atteso:** almeno un trade aperto nel periodo

### T002 — Filtro SMA200 attivo
**Setup:** imposta RSI_Entry=80 (sempre soddisfatto), SMA_Period=5
**Verifica:** nel periodo 2022 (mercato ribassista) il numero di trade è inferiore
rispetto a RSI_Entry=80 con SMA_Period=200
**Atteso:** il filtro SMA riduce i trade nei mercati ribassisti

### T003 — Warmup completato prima dell'entrata
**Verifica:** nel Journal, "WARMUP | Warm-up complete" appare prima di qualsiasi "ORDER | BUY placed"
**Atteso:** nessun trade nei primi SMA_Period+RSI_Period+1 giorni

### T004 — Gestione mercato chiuso (weekend)
**Verifica:** cerca nel Journal "INFO | Market closed — retry pending"
**Atteso:** se presente, deve essere seguita da "INFO | Pending entry executed after market open"

### T005 — Una sola posizione per volta
**Verifica:** controlla il CSV S6_trades.csv — le date di apertura e chiusura non si sovrappongono
**Atteso:** nessuna trade aperta mentre un'altra è ancora attiva

### T006 — Recovery al riavvio
**Setup:** avvia EA su grafico live (non backtest) con posizione già aperta
**Verifica:** nel Journal cerca "RECOVERY | Posizione esistente rilevata"
**Atteso:** nessun nuovo ordine inviato

---

## Output Attesi

Dopo il backtest:
- File `S6_trades.csv` nella cartella Files del Tester Agent
- Journal con log "[S6] FINAL REPORT | Trades: N | ..."
- Nessun log "[S6] ERROR |" per situazioni normali
