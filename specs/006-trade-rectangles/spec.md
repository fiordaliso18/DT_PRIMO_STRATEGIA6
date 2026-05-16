---
feature: FEAT-006
title: Rettangoli Trade sul Grafico
type: spec
status: implemented
release: MVP
depends_on: [FEAT-001, FEAT-002]
required_by: []
layer: requirements
language: Italian
platform: agnostic
---
# FEAT-006 — Rettangoli Trade sul Grafico · REQUISITI
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Dipende da:** FEAT-001, FEAT-002

> Questo file descrive esclusivamente il **COSA**.
> Per il **COME** vedere: `plan.md`

---

## Descrizione

Al termine del backtest, l'EA disegna sul grafico un rettangolo colorato per ogni trade chiuso. Il rettangolo copre visivamente la durata del trade (asse X) e il range di prezzo percorso (asse Y). Un'etichetta testuale riporta il profitto netto e il valore RSI al momento dell'uscita.

---

## Regole

**[S6-006-R001] — Rettangolo per ogni trade**
Per ogni trade chiuso, viene disegnato un rettangolo OBJ_RECTANGLE con:
- X sinistro = datetime di apertura del trade
- X destro = datetime di chiusura del trade
- Y superiore = prezzo massimo tra entrata e uscita
- Y inferiore = prezzo minimo tra entrata e uscita

**[S6-006-R002] — Colore proporzionale al risultato**
Il rettangolo è verde se il profitto netto del trade è positivo, rosso se negativo o zero.

**[S6-006-R003] — Etichette profit e RSI**
Per ogni trade vengono disegnate due etichette testuali separate:
- **Angolo top-right** (`S6_RLBL_`): profitto netto formattato (es. "+127" o "-54"), colore verde/rosso
- **Angolo top-left** (`S6_RRSI_`): valori RSI di entrata e uscita in formato "RSI:31→53" (vedi [S6-006-R008])

**[S6-006-R004] — Rettangoli in background**
I rettangoli vengono disegnati in background (dietro alle candele) per non oscurare il grafico dei prezzi.

**[S6-006-R005] — Disabilitazione tramite ShowArrows**
I rettangoli usano lo stesso flag `ShowArrows` delle frecce. Se `ShowArrows=false`, nessun rettangolo viene disegnato.

**[S6-006-R006] — Nomi univoci**
Gli oggetti grafici usano prefissi dedicati per non interferire con altri EA o oggetti manuali:
- `S6_RECT_` — rettangoli
- `S6_RLBL_` — etichette profitto
- `S6_RRSI_` — etichette RSI

**[S6-006-R008] — Etichetta RSI: stile e contenuto**
L'etichetta RSI (`S6_RRSI_`) mostra il valore RSI al momento dell'entrata e al momento dell'uscita nel formato "RSI:NN→MM".
Il font è Arial Bold, dimensione 9pt, colore giallo (`clrYellow`) per massima visibilità su sfondo verde e rosso.

**[S6-006-R007] — Persistenza**
I rettangoli restano sul grafico dopo la fine del backtest, al pari delle frecce.

---

## Parametri

Riutilizza i parametri di FEAT-005: `ShowArrows`, `ArrowBuyColor`, `ArrowExitColor`.

---

## Criteri di Accettazione

```
[S6-006-T001] Rettangolo verde per trade vincente
  Dato:    trade chiuso con profit > 0
  Atteso:  rettangolo verde che copre la durata del trade ✓

[S6-006-T002] Rettangolo rosso per trade perdente
  Dato:    trade chiuso con profit <= 0
  Atteso:  rettangolo rosso che copre la durata del trade ✓

[S6-006-T003] Etichetta profitto top-right
  Dato:    trade chiuso con profit=+127
  Atteso:  etichetta "S6_RLBL_*" con "+127", Arial Bold 9pt, colore verde, angolo top-right ✓

[S6-006-T004] Etichetta RSI top-left
  Dato:    trade con RSI entrata=31, RSI uscita=53
  Atteso:  etichetta "S6_RRSI_*" con "RSI:31→53", Arial Bold 9pt, giallo, angolo top-left ✓

[S6-006-T005] Rettangoli in background
  Dato:    rettangoli e candele sovrapposti
  Atteso:  candele visibili sopra i rettangoli ✓

[S6-006-T006] ShowArrows=false — nessun oggetto grafico
  Dato:    ShowArrows=false
  Atteso:  nessun oggetto S6_RECT_*, S6_RLBL_*, S6_RRSI_* sul grafico ✓

[S6-006-T007] Prefissi nomi univoci
  Dato:    backtest completato
  Atteso:  tutti gli oggetti con prefisso S6_RECT_, S6_RLBL_, S6_RRSI_ — nessun conflitto ✓
```
