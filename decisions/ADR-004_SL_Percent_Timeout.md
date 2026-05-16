# ADR-004 — Stop Loss percentuale fisso + timeout a giorni
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

Una volta aperta la posizione, l'EA ha due meccanismi di protezione aggiuntivi rispetto all'uscita RSI: uno stop loss e un limite temporale. Le domande sono: (1) come esprimere la distanza dello stop loss, (2) se usare un timeout e come esprimerlo.

---

## Decisione

1. **Stop Loss:** percentuale fissa dal prezzo di entrata (Ask), configurabile (`SL_Percent`, default 2%). Formula: `SL = Ask × (1 − SL_Percent / 100)`. Lo SL è fisso — non viene mai spostato dopo l'apertura.
2. **Timeout:** numero massimo di giorni di detenzione configurabile (`MaxDays`, default 15 giorni). Se la posizione è ancora aperta dopo 15 giorni e l'RSI non ha ancora superato la soglia di uscita, la posizione viene chiusa forzatamente.

---

## Alternative Considerate

**Stop Loss — Alternative A: pips fissi**
Stop loss a distanza fissa in pips dal prezzo di entrata.

Scartata: i pips hanno significato diverso a seconda del prezzo corrente dell'US500. Una distanza in percentuale è indipendente dal livello assoluto dell'indice (US500 a 4000 vs 6000 punti).

**Stop Loss — Alternative B: ATR (Average True Range)**
Stop loss basato sulla volatilità recente.

Scartata per MVP: aggiunge complessità e un terzo handle di indicatore. Il SL% è più semplice da comprendere e validare. ATR può essere considerato in una release successiva.

**Stop Loss — Alternative C: trailing stop**
Stop loss che segue il prezzo verso l'alto.

Scartata: la strategia S6 è di mean reversion, non di trend following. Un trailing stop è appropriato per strategie che sfruttano trend prolungati (come S2). Per mean reversion, l'uscita ottimale è il ritorno all'RSI neutro.

**Timeout — Alternative A: nessun timeout**
La posizione rimane aperta fino a RSI exit o SL.

Scartata: in mercati laterali l'RSI può non superare la soglia per settimane. Senza timeout il capitale rimane bloccato inutilmente.

**Timeout — Alternative B: timeout in barre**
Uscita dopo N barre invece di N giorni.

Scartata: sul timeframe Daily, barre = giorni, quindi la distinzione è trascurabile. L'unità "giorni" è più intuitiva per comunicare la holding period.

---

## Conseguenze

- `slPrice = ask * (1.0 - SL_Percent / 100.0)` in `OpenPosition()`.
- Il broker gestisce l'uscita per SL automaticamente — l'EA non la rileva in tempo reale.
- L'uscita per SL viene identificata nel CSV via `DEAL_REASON_SL`.
- Il timeout viene controllato in `CheckExitConditions()` ogni nuova barra.
- Vincolo catturato in `INV-003` (SL fisso, mai modificato).
