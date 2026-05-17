---
feature: FEAT-002
title: Logica di Uscita
type: spec
status: implemented
release: MVP
depends_on: [FEAT-001]
required_by: [FEAT-004]
layer: requirements
language: Italian
platform: agnostic
---
# FEAT-002 — Logica di Uscita · REQUISITI
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Dipende da:** FEAT-001
**Richiesta da:** FEAT-004

> Questo file descrive esclusivamente il **COSA**.
> Per il **COME** vedere: `plan.md`

---

## Descrizione

L'EA monitora la posizione aperta e la chiude quando si verifica
una delle tre condizioni di uscita, in ordine di priorità:
(1) RSI supera la soglia di uscita,
(2) il prezzo tocca lo stop loss (gestito dal broker),
(3) viene superato il periodo massimo di detenzione.

---

## Regole

**[S6-002-R001] — Uscita per RSI (priorità 1)**
Se il valore RSI dell'ultima barra completata è strettamente superiore
alla soglia di uscita configurata (RSI_Exit), l'EA chiude la posizione.
Questo segnala il ritorno del prezzo in zona neutra/ipercomprata,
completando il ciclo di mean reversion.
Motivo di chiusura registrato: "RSI_EXIT".

**[S6-002-R002] — Uscita per stop loss (priorità 2)**
Lo stop loss viene impostato all'apertura della posizione al livello
`Ask × (1 − SL_Percent / 100)`. Il broker chiude automaticamente
la posizione quando il prezzo raggiunge questo livello.
L'EA non rilevare né gestisce questa uscita in tempo reale —
viene identificata nel report finale tramite `DEAL_REASON_SL`.
Motivo di chiusura registrato: "SL".

**[S6-002-R003] — Uscita per timeout (priorità 3)**
Se la posizione è aperta da un numero di **sedute di borsa** (barre D1)
uguale o superiore al periodo massimo configurato (MaxDays),
l'EA chiude la posizione forzatamente, indipendentemente dal valore RSI.
Il conteggio usa `iBarShift(_Symbol, PERIOD_D1, _EntryTime, false)`,
che conta le barre D1 effettive — weekend e festività esclusi.
Con MaxDays=15, la posizione viene chiusa dopo 15 sedute di borsa
(≈ 21 giorni di calendario).
Motivo di chiusura registrato: "TIMEOUT".

**[S6-002-R004] — Valutazione solo su nuova barra**
Le condizioni di uscita RSI e timeout vengono valutate una sola volta
per ogni nuova barra giornaliera.
L'uscita per stop loss è gestita in tempo reale dal broker.

**[S6-002-R005] — Stop loss fisso**
Lo stop loss impostato all'apertura non viene mai modificato
durante la vita della posizione.
(INV-003)

**[S6-002-R006] — Stop loss minimo broker**
Il livello di stop loss calcolato deve rispettare la distanza
minima dal prezzo corrente imposta dal broker (SYMBOL_TRADE_STOPS_LEVEL).
Se il livello calcolato è troppo vicino al prezzo, la posizione
non viene aperta.

---

## Parametri di Configurazione

| Parametro | Tipo | Default | Descrizione |
|---|---|---|---|
| RSI_Exit | intero | 50 | Soglia RSI di uscita (esci se RSI > soglia) |
| SL_Percent | decimale | 2.0 | Stop Loss % dal prezzo di entrata (Ask) |
| MaxDays | intero | 15 | Sedute di borsa massime di detenzione (barre D1, non giorni solari) |

---

## Criteri di Accettazione

```
[S6-002-T001] Uscita per RSI
  Dato:    posizione BUY aperta
           RSI(14)[1] > RSI_Exit
  Quando:  nuova barra D1 apre
  Atteso:  posizione chiusa ✓
           log "CLOSE | RSI_EXIT" nel journal ✓

[S6-002-T002] Nessuna uscita RSI se valore ≤ soglia
  Dato:    posizione BUY aperta
           RSI(14)[1] ≤ RSI_Exit
  Atteso:  posizione mantenuta aperta ✓

[S6-002-T003] Uscita per timeout
  Dato:    posizione BUY aperta da MaxDays o più sedute di borsa (barre D1)
           RSI(14)[1] ≤ RSI_Exit
  Quando:  nuova barra D1 apre
  Atteso:  posizione chiusa ✓
           log "INFO | Timeout | Bars open: N" nel journal ✓
           log "CLOSE | TIMEOUT" nel journal ✓

[S6-002-T004] Nessun timeout se sedute < MaxDays
  Dato:    posizione BUY aperta da meno di MaxDays barre D1
           RSI(14)[1] ≤ RSI_Exit
  Atteso:  posizione mantenuta aperta ✓

[S6-002-T005] RSI ha priorità su timeout
  Dato:    posizione BUY aperta da MaxDays o più giorni
           RSI(14)[1] > RSI_Exit
  Atteso:  posizione chiusa con motivo RSI_EXIT (non TIMEOUT) ✓

[S6-002-T006] SL rispetta distanza minima broker
  Dato:    SL calcolato troppo vicino al prezzo corrente
           distanza < SYMBOL_TRADE_STOPS_LEVEL
  Atteso:  posizione non aperta ✓
           log "SKIP | SL distance X pts < broker min Y" nel journal ✓

[S6-002-T007] Uscita per SL identificata nel report
  Dato:    posizione chiusa dal broker per stop loss
  Atteso:  nel CSV: colonna Reason = "SL" ✓
           riconoscimento via DEAL_REASON_SL ✓
```
