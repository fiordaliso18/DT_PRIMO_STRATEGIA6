# BACKLOG — S6 EA
**Prodotto:** S6 — Swing Mean Reversion Daily
**Autore:** Primo Fiordaliso
**Data:** 2026-05-15
**Versione:** 1.0

---

## Principio Guida — Invarianti Assoluti

> *"Un solo trade per volta. Compra la debolezza in trend rialzista."*

| ID | Regola |
|---|---|
| INV-001 | L'EA gestisce al massimo una posizione aperta per volta sul simbolo di competenza |
| INV-002 | L'EA apre solo posizioni BUY — mai posizioni SELL o SHORT |
| INV-003 | Lo stop loss viene impostato all'apertura e non viene mai modificato |
| INV-004 | La condizione di entrata viene valutata solo sulla chiusura di una nuova barra D1 |
| INV-005 | Il volume viene sempre arrotondato per difetto al volume step del broker |

---

## Struttura dei Documenti

### Convenzione per feature

Ogni feature è descritta in due file separati:

| File | Contenuto | Lingua |
|---|---|---|
| `specs/NNN-feature-name/spec.md` | Il **COSA** — requisiti, regole, criteri di accettazione | Italiano |
| `specs/NNN-feature-name/plan.md` | Il **COME** — codice MQL5, strutture dati, metodi | Inglese + commenti IT |

Il file spec non contiene mai codice.
Il file plan non contiene mai requisiti funzionali.
Ogni sezione del plan referenzia esplicitamente la regola `[S6-RXXX]` che implementa.

---

## Utilities — Pattern Condivisi

| ID | Utility | Usata da | Stato |
|---|---|---|---|
| UTL-001 | Scrittura CSV in append (MQL5: `FILE_COMMON` + `FileSize` + `SEEK_SET`) | FEAT-004 | ✅ Implementata |

---

## Backlog — Stato delle Feature

### MVP — Implementazione Attuale

| ID | Feature | Dipende da | Stato |
|---|---|---|---|
| FEAT-001 | Logica di entrata (SMA200 + RSI) | — | ✅ Implementata |
| FEAT-002 | Logica di uscita (RSI exit + SL + timeout) | FEAT-001 | ✅ Implementata |
| FEAT-003 | Gestione rischio (calcolo lotti) | — | ✅ Implementata |
| FEAT-004 | Reporting (CSV trade-by-trade + journal) | FEAT-001, FEAT-002 | ✅ Implementata |

---

| FEAT-005 | Frecce sul grafico (entrata/uscita, colore e dimensione configurabili) + label RSI fissi | FEAT-001, FEAT-002 | ✅ Implementata |
| FEAT-006 | Rettangoli trade sul grafico con etichetta profit + RSI entrata→uscita | FEAT-001, FEAT-002 | ✅ Implementata |

---

### Phase 2 — Feature Pianificate

| ID | Feature | Dipende da | Stato |
|---|---|---|---|
| FEAT-007 | Report periodico su grafico (ogni N ore) | FEAT-004 | 📋 Da fare |
| FEAT-008 | Notifiche push mobile all'apertura/chiusura | FEAT-004 | 📋 Da fare |
| FEAT-009 | Dashboard visuale sul grafico (linee SMA, RSI panel) | FEAT-001 | 📋 Da fare |
| FEAT-010 | Ottimizzazione parametri automatica (Walk-Forward) | FEAT-001–FEAT-006 | 📋 Da fare |

---

### Release 2 — Evoluzione Strategia

| ID | Feature | Dipende da | Stato |
|---|---|---|---|
| FEAT-011 | Multi-simbolo (US100, DAX) — istanze separate | FEAT-001–FEAT-004 | 📋 Da fare |
| FEAT-012 | Phase 2 strategia (condizioni aggiuntive) | FEAT-001 | 📋 Da fare |

---

## Invarianti di Sistema

Validi per **tutte** le feature, senza eccezioni.

| ID | Regola |
|---|---|
| INV-001 | L'EA gestisce al massimo una posizione aperta per volta sul simbolo di competenza |
| INV-002 | L'EA apre solo posizioni BUY |
| INV-003 | Lo stop loss è fisso — impostato all'entrata, mai modificato |
| INV-004 | La condizione di entrata è valutata solo su nuova barra D1 |
| INV-005 | Il volume viene sempre arrotondato per difetto al volume step del broker |

---

## Legenda

| Simbolo | Stato |
|---|---|
| 📋 Da fare | Spec non ancora scritta o da implementare |
| 🔨 In corso | In fase di implementazione |
| ✅ Implementata | Implementata e testata in backtest |
| ⏸ In attesa | Bloccata da decisione aperta |
