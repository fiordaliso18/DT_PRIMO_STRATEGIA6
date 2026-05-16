---
feature: FEAT-001
title: Logica di Entrata
type: spec
status: implemented
release: MVP
depends_on: []
required_by: [FEAT-002, FEAT-003, FEAT-004]
layer: requirements
language: Italian
platform: agnostic
---
# FEAT-001 — Logica di Entrata · REQUISITI
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Dipende da:** —
**Richiesta da:** FEAT-002, FEAT-003, FEAT-004

> Questo file descrive esclusivamente il **COSA**.
> Per il **COME** vedere: `plan.md`

---

## Descrizione

L'EA valuta le condizioni di entrata alla chiusura di ogni nuova barra giornaliera.
Se tutte le condizioni sono soddisfatte e non esiste già una posizione aperta,
l'EA apre un ordine BUY a mercato sul simbolo di competenza.

---

## Regole

**[S6-001-R001] — Una sola posizione per volta**
L'EA non apre un nuovo trade se esiste già una posizione aperta
sul simbolo di competenza con il suo identificatore univoco.
(INV-001)

**[S6-001-R002] — Filtro di trend (SMA200)**
La condizione di entrata richiede che il prezzo di chiusura
dell'ultima barra completata sia superiore alla media mobile semplice
di periodo configurato calcolata sulla stessa barra.
Il trend rialzista è condizione necessaria ma non sufficiente.

**[S6-001-R003] — Segnale di ipervenduto (RSI)**
La condizione di entrata richiede che il valore RSI
dell'ultima barra completata sia strettamente inferiore
alla soglia di entrata configurata (RSI_Entry).

**[S6-001-R004] — Valutazione solo su nuova barra**
Le condizioni di entrata vengono valutate una sola volta
per ogni nuova barra giornaliera, al momento in cui
la nuova barra diventa disponibile.
(INV-004)

**[S6-001-R005] — Warmup minimo**
L'EA non valuta le condizioni di entrata se il numero di barre
storiche disponibili è insufficiente per il calcolo corretto
degli indicatori (SMA_Period + RSI_Period + 1 barre minime).

**[S6-001-R006] — Solo BUY**
L'EA apre esclusivamente posizioni di acquisto.
Non apre mai posizioni di vendita.
(INV-002)

**[S6-001-R007] — Trading abilitato**
L'EA verifica che il trading sia abilitato sul terminale
e sull'EA prima di inviare qualsiasi ordine.

**[S6-001-R008] — Mercato chiuso: entrata pendente**
Se la condizione di entrata è soddisfatta ma il broker rifiuta
l'ordine perché il mercato è chiuso (RetCode 10018 o errore 4756),
l'EA attiva il flag di entrata pendente.
Al primo tick disponibile con mercato aperto, l'EA esegue
l'ordine senza rivalutare le condizioni.

**[S6-001-R009] — Recupero al riavvio**
Se l'EA viene riavviato mentre una posizione è già aperta
con il suo identificatore univoco, rileva la posizione esistente
all'inizializzazione senza aprirne una nuova.

---

## Parametri di Configurazione

| Parametro | Tipo | Default | Descrizione |
|---|---|---|---|
| SMA_Period | intero | 200 | Periodo della media mobile semplice |
| RSI_Period | intero | 14 | Periodo dell'RSI |
| RSI_Entry | intero | 35 | Soglia RSI di entrata (entra se RSI < soglia) |
| MagicNumber | intero | 20260509 | Identificatore univoco dell'EA |

---

## Criteri di Accettazione

```
[S6-001-T001] Entrata con condizioni soddisfatte
  Dato:    nessuna posizione aperta
           Close[1] > SMA(200)[1]
           RSI(14)[1] < RSI_Entry
  Quando:  nuova barra D1 apre
  Atteso:  ordine BUY inviato al broker ✓
           log "SIGNAL | Entry conditions met" nel journal ✓
           log "ORDER | BUY placed" nel journal ✓

[S6-001-T002] Nessuna entrata se posizione già aperta
  Dato:    posizione BUY già aperta con MagicNumber corretto
           Close[1] > SMA(200)[1]  e  RSI(14)[1] < RSI_Entry
  Atteso:  nessun nuovo ordine inviato ✓

[S6-001-T003] Nessuna entrata se prezzo sotto SMA200
  Dato:    nessuna posizione aperta
           Close[1] ≤ SMA(200)[1]
           RSI(14)[1] < RSI_Entry
  Atteso:  nessun ordine inviato ✓

[S6-001-T004] Nessuna entrata se RSI ≥ RSI_Entry
  Dato:    nessuna posizione aperta
           Close[1] > SMA(200)[1]
           RSI(14)[1] ≥ RSI_Entry
  Atteso:  nessun ordine inviato ✓

[S6-001-T005] Warmup insufficiente — nessuna entrata
  Dato:    numero di barre disponibili < SMA_Period + RSI_Period + 1
  Atteso:  condizioni non valutate
           log "WARMUP | Insufficient bars" nel journal ✓

[S6-001-T006] Mercato chiuso — entrata pendente
  Dato:    condizioni di entrata soddisfatte
           broker rifiuta l'ordine con RetCode 10018
  Atteso:  flag pendingEntry attivato ✓
           log "INFO | Market closed — retry pending" nel journal ✓
           al tick successivo con mercato aperto: ordine BUY inviato ✓
           log "INFO | Pending entry executed after market open" ✓

[S6-001-T007] Recupero al riavvio
  Dato:    EA riavviato con posizione già aperta (MagicNumber corretto)
  Atteso:  posizione rilevata in OnInit() ✓
           entryTime ripristinato dalla posizione esistente ✓
           nessun nuovo ordine inviato ✓
           log "RECOVERY | Posizione esistente rilevata" nel journal ✓
```
