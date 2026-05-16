---
feature: UTL-001
title: Scrittura CSV in Append — Pattern MQL5
type: spec
status: implemented
release: MVP
depends_on: []
required_by: [FEAT-004]
layer: requirements
language: Italian
platform: MT5 / MQL5
---
# UTL-001 — Scrittura CSV in Append · REQUISITI
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Usata da:** FEAT-004

> Questo file descrive esclusivamente il **COSA**.
> Per il **COME** vedere: `plan.md`

---

## Contesto

In MQL5, la scrittura in append su file CSV non è supportata nativamente:
- `FILE_WRITE` da solo **tronca** il file esistente.
- `FileSeek(handle, 0, SEEK_END)` **non funziona** su file aperti con `FILE_CSV`.
- `FILE_READ | FILE_WRITE` senza seek posiziona il puntatore all'inizio del file.

Questa utility definisce il pattern corretto verificato su terminale reale.

---

## Regole

**[UTL-001-R001] — Rilevamento prima esecuzione**
Prima di aprire il file, verificare la sua esistenza con `FileIsExist(filename, FILE_COMMON)`.
Se il file non esiste, crearlo con intestazione e chiuderlo prima della scrittura dati.

**[UTL-001-R002] — Cartella FILE_COMMON**
Tutti i file CSV devono usare il flag `FILE_COMMON`.
Questo garantisce che il file sia scritto nella cartella condivisa tra terminale live
e tutti i Tester Agent, indipendentemente dall'agente specifico che esegue il backtest.

```
%PUBLIC%\Documents\MetaTrader 5\MQL5\Files\
```

**[UTL-001-R003] — Apertura in append**
Dopo la creazione o se il file esiste già, aprire con:
```
FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON
```
`FILE_READ | FILE_WRITE` non tronca il file esistente.

**[UTL-001-R004] — Posizionamento alla fine**
Usare `FileSize(handle)` per ottenere la dimensione corrente del file,
poi `FileSeek(handle, (long)size, SEEK_SET)` per posizionare il puntatore alla fine.
Non usare `SEEK_END`: non supportato per file `FILE_CSV` in MQL5.

**[UTL-001-R005] — Scrittura dati**
Dopo il seek, usare `FileWrite()` normalmente con il separatore configurato.
`FILE_CSV` gestisce automaticamente il separatore tra colonne e il terminatore di riga.

**[UTL-001-R006] — Chiusura**
Chiamare `FileClose(handle)` al termine di ogni operazione di scrittura.
Non lasciare handle aperti tra chiamate diverse.

---

## Criteri di Accettazione

```
[UTL-001-T001] File nuovo — creazione con intestazione
  Dato:    file non esiste
  Atteso:  file creato con intestazione come prima riga ✓
           dati scritti dalla riga 2 in poi ✓

[UTL-001-T002] File esistente — append senza perdita dati
  Dato:    file esiste con N righe
  Atteso:  file dopo la scrittura contiene N + M righe ✓
           le N righe originali non sono modificate ✓

[UTL-001-T003] Persistenza tra run del Tester
  Dato:    due backtest consecutivi sullo stesso o su diversi Agent
  Atteso:  il file accumula i dati di entrambi i run ✓

[UTL-001-T004] SEEK_SET con FileSize
  Dato:    file di dimensione S byte
  Quando:  FileSeek(handle, S, SEEK_SET)
  Atteso:  nuovi dati scritti a partire dal byte S ✓
           nessun dato precedente sovrascritto ✓
```
