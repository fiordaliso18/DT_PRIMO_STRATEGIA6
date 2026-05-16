---
feature: FEAT-004
title: Reporting — CSV e Journal
type: spec
status: implemented
release: MVP
depends_on: [FEAT-001, FEAT-002]
required_by: []
layer: requirements
language: Italian
platform: agnostic
---
# FEAT-004 — Reporting · REQUISITI
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Dipende da:** FEAT-001, FEAT-002
**Richiesta da:** —

> Questo file descrive esclusivamente il **COSA**.
> Per il **COME** vedere: `plan.md`

---

## Descrizione

Al termine del backtest (deinizializzazione dell'EA), il sistema produce:
1. Un log finale nel journal con le statistiche aggregate della sessione.
2. Un file CSV con i dati trade-by-trade per analisi esterna.

Durante il backtest, il sistema aggiorna periodicamente il commento
sul grafico con le statistiche correnti.

---

## Regole

**[S6-004-R001] — Report finale al termine**
Alla deinizializzazione dell'EA, viene prodotto un report finale
con le seguenti statistiche aggregate:
- Numero totale di trade chiusi
- Win rate (% di trade in profitto)
- Profit factor (profitto lordo / perdita lorda)
- Massimo drawdown (% rispetto all'equity più alta raggiunta)
- Durata media dei trade (in giorni)

**[S6-004-R002] — Esportazione CSV trade-by-trade in append**
Alla deinizializzazione, il sistema aggiunge i trade della sessione corrente
al file CSV esistente (modalità append). Se il file non esiste viene creato.
Ogni run successivo viene accodato, preservando i run precedenti.
Il file risiede nella cartella Files del Tester Agent.
Il delimitatore di campo è il punto e virgola (`;`) per compatibilità
con Excel in configurazione italiana (separatore decimale: virgola).

**[S6-004-R003] — Colonne del CSV**
Il file CSV contiene le seguenti colonne nell'ordine indicato:
Trade, EntryDate, EntryPrice, ExitDate, ExitPrice, Lots, Profit, DurationDays, Reason

**[S6-004-R004] — Profitto netto nel CSV**
La colonna "Profit" rappresenta il profitto netto del trade,
inclusi swap e commissioni del broker.
Formula: Profit = DEAL_PROFIT + DEAL_SWAP + DEAL_COMMISSION

**[S6-004-R005] — Motivo di chiusura nel CSV**
La colonna "Reason" contiene uno dei tre valori possibili:
- "RSI_EXIT" — chiusura per RSI sopra soglia
- "SL" — chiusura per stop loss (gestita dal broker)
- "TIMEOUT" — chiusura per superamento MaxDays

**[S6-004-R006] — Identificazione coppia entrata/uscita**
Per ogni deal di uscita (DEAL_ENTRY_OUT), il sistema identifica
il corrispondente deal di entrata (DEAL_ENTRY_IN) tramite
il DEAL_POSITION_ID condiviso, per recuperare data e prezzo di entrata.

**[S6-004-R007] — Solo trade dell'EA corrente**
Il CSV include solo i deal con il MagicNumber dell'EA
e sul simbolo di competenza. Trade di altri EA o manuali
vengono ignorati.

**[S6-004-R008] — Commento periodico sul grafico**
Durante l'esecuzione, il commento sul grafico viene aggiornato
a ogni nuova barra con le statistiche correnti:
win rate, conteggio trade (vinti/totali), massimo drawdown.

**[S6-004-R009] — Tracking del drawdown**
L'EA traccia il massimo drawdown calcolato come percentuale
di riduzione dell'equity rispetto al massimo storico raggiunto
durante la sessione (high water mark dell'equity).

**[S6-004-R010] — Separatore tra run**
Se il file CSV contiene già dati di run precedenti, viene inserito un separatore
prima dei nuovi dati, nel formato: `=== RUN YYYY.MM.DD HH:MM | SYMBOL ===`.
Il separatore è preceduto e seguito da una riga vuota per leggibilità.

**[S6-004-R011] — Riga TOTALE**
Al termine dei dati trade-by-trade, viene aggiunta una riga riepilogativa "TOTALE"
con: lotti totali, profitto netto totale, durata media dei trade, numero di trade.

**[S6-004-R012] — Istogramma profitti**
Se il numero di trade è maggiore di 1, viene aggiunto un istogramma testuale
della distribuzione dei profitti, con 10 bucket di ampiezza uguale su range dinamico
[minProfit, maxProfit]. Ogni bucket mostra: intervallo, frequenza, barra ASCII (`#`)
scalata a 20 caratteri rispetto al bucket più frequente.

---

## Parametri di Configurazione

| Parametro | Tipo | Default | Descrizione |
|---|---|---|---|
| MagicNumber | intero | 20260509 | Usato per filtrare i deal nel CSV |
| ReportInterval | intero | 8 | Intervallo report periodico in ore [Phase 2] |

---

## Criteri di Accettazione

```
[S6-004-T001] File CSV creato alla fine del backtest
  Dato:    backtest completato con almeno 1 trade
  Atteso:  file "S6_trades.csv" presente nella cartella Files del Tester ✓
           log "CSV | S6_trades.csv | N trades written" nel Journal ✓

[S6-004-T002] Intestazione CSV corretta
  Dato:    file S6_trades.csv aperto in Excel (separatore `;`)
  Atteso:  prima riga = "Trade;EntryDate;EntryPrice;ExitDate;ExitPrice;Lots;Profit;DurationDays;Reason" ✓

[S6-004-T003] Una riga per ogni trade chiuso
  Dato:    backtest con N trade
  Atteso:  N righe dati nel CSV (esclusa intestazione) ✓

[S6-004-T004] Colonna Reason valorizzata
  Dato:    trade chiusi per RSI, SL, e timeout
  Atteso:  colonna Reason = "RSI_EXIT" / "SL" / "TIMEOUT" — mai vuota ✓

[S6-004-T005] Profitto netto corretto
  Dato:    trade con profit=50, swap=-2, commission=-1
  Atteso:  colonna Profit = 47.00 ✓

[S6-004-T006] Solo trade dell'EA
  Dato:    history con trade manuali (MagicNumber=0) + trade EA (MagicNumber=20260509)
  Atteso:  CSV contiene solo i trade con MagicNumber=20260509 ✓

[S6-004-T007] Report finale nel Journal
  Dato:    fine backtest
  Atteso:  log "FINAL REPORT | Trades: N | WR: X% | PF: Y | MaxDD: Z% | AvgDays: W" ✓

[S6-004-T008] Delimitatore corretto per Excel italiano
  Dato:    file S6_trades.csv aperto in Excel con impostazioni italiane
  Atteso:  colonne separate correttamente (separatore `;`) ✓
           nessun dato "tutto nella prima colonna" ✓

[S6-004-T009] Append tra run consecutivi
  Dato:    due backtest eseguiti in sequenza sullo stesso Agent
  Atteso:  file CSV contiene entrambi i run separati da "=== RUN ... ===" ✓
           dati del run precedente non sovrascritti ✓

[S6-004-T010] Riga TOTALE presente
  Dato:    backtest con N trade
  Atteso:  ultima riga dati = "TOTALE" con profit totale, lotti totali, durata media ✓

[S6-004-T011] Istogramma profitti presente
  Dato:    backtest con più di 1 trade
  Atteso:  sezione "ISTOGRAMMA PROFIT" con 10 righe bucket ✓
           barra ASCII proporzionale alla frequenza ✓
```
