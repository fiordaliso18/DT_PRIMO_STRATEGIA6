# ADR-003 — SMA(200) come filtro trend + RSI(14) come segnale di entrata
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

La strategia richiede due componenti: (1) un filtro per identificare il trend di lungo periodo, (2) un oscillatore per identificare il momento di ipervenduto in cui entrare. La domanda è quali indicatori usare per questi due ruoli.

---

## Decisione

- **Filtro trend:** SMA semplice di periodo 200 sulla chiusura giornaliera.
- **Segnale di entrata:** RSI di periodo 14 sulla chiusura giornaliera, con soglia di entrata configurabile (default 35).
- **Segnale di uscita:** RSI > soglia di uscita configurabile (default 50).

---

## Alternative Considerate

**Filtro trend — Alternative A: EMA(200)**
Più reattiva ai movimenti recenti rispetto alla SMA.

Scartata per ora: la SMA(200) è lo standard di riferimento più diffuso tra i trader per identificare il trend di lungo periodo su indici azionari. La differenza pratica in backtest è marginale.

**Filtro trend — Alternative B: SMA(50) incrocio SMA(200)**
Golden cross/Death cross come filtro.

Scartata: più ritardato, genera fasi di neutralità prolungate che riducono le opportunità operative.

**Segnale di entrata — Alternative A: Stocastico**
Oscillatore con zona di ipervenduto (< 20).

Scartata: più rumoroso dell'RSI su timeframe Daily. L'RSI è lo standard di riferimento per strategie di mean reversion su indici.

**Segnale di entrata — Alternative B: Bande di Bollinger**
Entrata quando il prezzo tocca la banda inferiore.

Scartata: richiede un parametro aggiuntivo (deviazione standard) e non è un oscillatore normalizzato, rendendo più difficile la confrontabilità tra periodi diversi.

**Soglia RSI_Entry — Default 35 vs 30 vs 40**
- 30: segnali rari, alta precisione ma bassa frequenza
- 35: bilanciamento frequenza/qualità — scelta attuale
- 40: segnali frequenti, più rumore

Scelta 35 come default dopo analisi backtest su US500 2010–2026.

---

## Conseguenze

- `hSMA = iMA(_Symbol, PERIOD_D1, SMA_Period, 0, MODE_SMA, PRICE_CLOSE)` in `OnInit()`.
- `hRSI = iRSI(_Symbol, PERIOD_D1, RSI_Period, PRICE_CLOSE)` in `OnInit()`.
- Warmup minimo: `SMA_Period + RSI_Period + 1` barre (default 216).
- Entrambi i valori sono letti sulla barra `[1]` (ultima barra chiusa).
- `RSI_Entry` e `RSI_Exit` sono parametri configurabili per ottimizzazione.
