# S6 EA — Swing Mean Reversion Daily
**Autore:** Primo Fiordaliso
**Platform:** MetaTrader 5 / MQL5
**Simbolo:** US500 (S&P 500 CFD)
**Timeframe:** Daily (D1)
**Direzione:** BUY only
**Architettura:** DroidTrader v2 — CS6Trader + thin orchestrator

> *"Il mercato torna sempre alla media. Compra la debolezza in trend rialzista."*

S6 è un Expert Advisor di mean reversion su timeframe Daily. Entra in acquisto quando il mercato è in trend rialzista (sopra SMA 200) e l'RSI segnala ipervenduto. Esce quando l'RSI si normalizza, il prezzo tocca lo stop loss, o si supera il periodo massimo di detenzione.

---

## Per Claude / Copilot — Leggi Prima di Tutto

Prima di implementare qualsiasi feature, leggi questi documenti nell'ordine indicato:

1. **`glossary.md`** — definizioni precise di tutti i termini di dominio (platform-agnostic).
2. **`glossary_IMPL_MT5.md`** — mappatura dei termini di dominio agli identificatori MQL5.
3. **`BACKLOG.md`** — lista feature con stato e dipendenze.
4. **La `spec.md` della feature** — il COSA (in italiano, senza codice).
5. **La `plan.md` della feature** — il COME (MQL5, con commenti IT).

Per decisioni di design, consulta i file ADR in `decisions/`.

**Regole critiche per la generazione di codice:**
- Un solo trade aperto per volta su simbolo di competenza. (INV-001)
- Ogni regola `[S6-RXXX]` nella spec deve essere referenziata nella plan corrispondente.
- Tutta la logica di trading va in `CS6Trader` — mai in `S6_EA.mq5`.
- Codice in inglese. Commenti in inglese + italiano (bilingue).
- Nomi input: seguire i nomi definiti in `glossary_IMPL_MT5.md`.

---

## Architettura

```
S6_EA.mq5  (thin orchestrator — solo OnInit/OnTick/OnDeinit)
  └── CS6Trader  extends ATraderRobot  (DroidTrader)
        ├── CReporterRobot  _Reporter   → S6_events.csv  (event log)
        └── CTrade          _Trade      (MQL5 Trade library)
```

`CS6Trader` contiene tutta la logica: segnali, ordini, rischio, reporting.
`S6_EA.mq5` crea l'istanza, chiama `Init()`, `Tick()`, `GenerateFinalReport()`, `Deinit()`.

---

## Struttura del Progetto

```
README.md                        ← parti da qui
glossary.md                      ← termini di dominio, platform-agnostic
glossary_IMPL_MT5.md             ← dominio → MQL5
BACKLOG.md                       ← feature list con stato e dipendenze
build.ps1                        ← sincronizza src/ in MT5 e compila

decisions/
  ADR-001_BuyOnly_US500.md       ← perché solo BUY su US500
  ADR-002_Daily_Timeframe.md     ← perché timeframe Daily
  ADR-003_RSI_Entry_SMA200.md    ← perché SMA200 + RSI come segnale
  ADR-004_SL_Percent_Timeout.md  ← perché SL% fisso + timeout giorni

specs/
  001-entry-logic/spec.md        ← COSA: logica di entrata
  001-entry-logic/plan.md        ← COME: CS6Trader::CheckEntryConditions etc.
  001-entry-logic/tests/
  002-exit-logic/spec.md         ← COSA: logica di uscita
  002-exit-logic/plan.md         ← COME: CS6Trader::CheckExitConditions etc.
  002-exit-logic/tests/
  003-risk-management/spec.md    ← COSA: calcolo lotti
  003-risk-management/plan.md    ← COME: CS6Trader::CalculateLots
  003-risk-management/tests/
  004-reporting-csv/spec.md      ← COSA: report CSV + journal
  004-reporting-csv/plan.md      ← COME: CS6Trader::WriteTradesToCSV etc.
  004-reporting-csv/tests/

src/
  S6_EA.mq5                      ← thin orchestrator (inputs + OnInit/OnTick/OnDeinit)
  Trader/
    CS6Trader.mqh                 ← tutta la logica di trading (estende ATraderRobot)
```

---

## Parametri di Configurazione

| Parametro | Default | Descrizione |
|---|---|---|
| RiskPercent | 1.0 | % balance rischiato per trade |
| SMA_Period | 200 | Periodo SMA per trend filter |
| RSI_Period | 14 | Periodo RSI |
| RSI_Entry | 35 | Soglia RSI entrata (compra se RSI < soglia) |
| RSI_Exit | 50 | Soglia RSI uscita (chiudi se RSI > soglia) |
| SL_Percent | 2.0 | Stop Loss % dal prezzo di entrata |
| MaxDays | 15 | Giorni massimi di detenzione |
| MagicNumber | 20260509 | Identificatore univoco EA |
| EnablePhase2 | false | Abilita feature Phase 2 (stub) |

---

## Logica Operativa

**Entrata (ogni giorno a chiusura barra):**
1. Nessuna posizione aperta
2. Close[1] > SMA(200)[1] → trend rialzista
3. RSI(14)[1] < RSI_Entry → ipervenduto
→ BUY a mercato con SL = Ask × (1 − SL% / 100)

**Uscita (in ordine di priorità):**
1. RSI[1] > RSI_Exit → RSI_EXIT
2. Prezzo tocca SL → SL (gestito dal broker)
3. Giorni aperti ≥ MaxDays → TIMEOUT

**Gestione mercato chiuso:**
Se il BUY fallisce con RetCode=10018 (mercato chiuso), il flag `_PendingEntry` in `CS6Trader`
viene attivato e il trade viene ritentato al tick successivo in `TradeOnTick()`.

---

## Decisioni Architetturali Chiave

| Decisione | File |
|---|---|
| Solo BUY su US500 | ADR-001 |
| Timeframe Daily | ADR-002 |
| SMA200 + RSI come filtro | ADR-003 |
| SL% fisso + timeout giorni | ADR-004 |
