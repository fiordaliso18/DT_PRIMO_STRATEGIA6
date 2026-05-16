# ADR-002 — Timeframe Daily (D1) come timeframe operativo
**Prodotto:** S6 — Swing Mean Reversion Daily
**Data:** 2026-05-15
**Stato:** Accettato

---

## Metadata

| Campo | Valore |
|---|---|
| **Status** | Accepted |
| **Deciders** | Primo Fiordaliso |
| **Date** | 2026-05-15 |
| **Supersedes** | — |
| **Superseded by** | — |

---

## Contesto

La strategia opera su swing di medio termine. La domanda è quale timeframe usare per il calcolo degli indicatori (SMA, RSI) e per la valutazione delle condizioni di entrata/uscita.

---

## Decisione

L'EA usa esclusivamente il **timeframe Daily (PERIOD_D1)** per tutti i calcoli.
La condizione di entrata viene valutata solo alla **chiusura di una nuova barra giornaliera**.

---

## Alternative Considerate

**Alternativa A — H4 (4 ore)**
Più segnali disponibili, reazione più rapida ai movimenti di mercato.

Scartata perché: genera più rumore, richiede maggiore attenzione al market timing infragiornaliero, aumenta i costi di transazione. Lo swing mean reversion su indici funziona meglio su timeframe più alti dove il segnale RSI è più pulito.

**Alternativa B — Weekly**
Meno segnali, movimenti più ampi, meno rumore.

Scartata perché: il Weekly produce troppo pochi trade per una valutazione statistica significativa in backtest. Il MaxDays di 15 giorni è incompatibile con un timeframe settimanale.

**Alternativa C — Multi-timeframe (D1 + H4)**
Conferma del segnale su H4 prima dell'entrata D1.

Scartata per MVP: aumenta complessità senza evidenza che migliori i risultati nel caso specifico di mean reversion su US500.

---

## Conseguenze

- La logica di `IsNewBar()` confronta `iTime(_Symbol, PERIOD_D1, 0)`.
- Tutti i `CopyBuffer()` usano `PERIOD_D1`.
- Il timeout `MaxDays` è espresso in giorni solari, coerente con il timeframe.
- Richiede modalità "Open prices only" nel Strategy Tester per performance ottimale.
- Vincolo catturato in `INV-004`.
