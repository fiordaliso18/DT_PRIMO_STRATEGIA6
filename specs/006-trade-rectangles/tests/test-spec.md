---
feature: FEAT-006
title: Rettangoli Trade sul Grafico — Test di Specifica
type: test-spec
status: implemented
release: MVP
---
# FEAT-006 — Rettangoli Trade sul Grafico · TEST

> Verifica manuale visuale in Strategy Tester (modalità Visual) o su grafico live.

---

## [S6-006-T001] Rettangolo verde per trade vincente

**Precondizioni:** ShowArrows=true, backtest completato con almeno un trade in profitto
**Procedura:** Aprire il grafico dopo il backtest
**Atteso:**
- Rettangolo con sfondo verde che copre la durata del trade (asse X) e il range di prezzo (asse Y)
- Oggetto con prefisso `S6_RECT_`, riempito, posizionato in background (dietro alle candele)

---

## [S6-006-T002] Rettangolo rosso per trade perdente

**Precondizioni:** ShowArrows=true, backtest completato con almeno un trade in perdita
**Procedura:** Aprire il grafico dopo il backtest
**Atteso:**
- Rettangolo con sfondo rosso che copre la durata del trade

---

## [S6-006-T003] Etichetta profitto top-right

**Precondizioni:** trade chiuso con profit=+127
**Procedura:** Zoom sul rettangolo del trade
**Atteso:**
- Etichetta `S6_RLBL_*` posizionata all'angolo in alto a destra del rettangolo
- Testo: "+127", font Arial Bold 9pt, colore verde
- Per trade in perdita: "-54", colore rosso

---

## [S6-006-T004] Etichetta RSI top-left

**Precondizioni:** trade con RSI entrata ≈ 31, RSI uscita ≈ 53
**Procedura:** Zoom sul rettangolo del trade
**Atteso:**
- Etichetta `S6_RRSI_*` posizionata all'angolo in alto a sinistra del rettangolo
- Testo: "RSI:31→53", font Arial Bold 9pt, colore giallo (`clrYellow`)
- Se RSI non disponibile: "RSI:?→?"

---

## [S6-006-T005] Rettangoli in background

**Precondizioni:** backtest completato con almeno un trade
**Procedura:** Zoom sul rettangolo e verifica sovrapposizione con candele
**Atteso:**
- Le candele sono visibili sopra i rettangoli
- `OBJPROP_BACK = true` verificabile aprendo le proprietà dell'oggetto in MT5

---

## [S6-006-T006] ShowArrows=false — nessun oggetto grafico

**Precondizioni:** ShowArrows=false nel parametro EA
**Procedura:** Eseguire backtest, aprire grafico
**Atteso:**
- Nessun oggetto con prefisso `S6_RECT_*`, `S6_RLBL_*`, `S6_RRSI_*` presente sul grafico
- Verificabile tramite MT5: tasto destro → Oggetti → lista vuota per prefissi S6_

---

## [S6-006-T007] Prefissi nomi univoci

**Precondizioni:** backtest completato
**Procedura:** MT5 → Inserisci → Oggetti → verifica nomi
**Atteso:**
- Tutti gli oggetti S6 hanno prefisso `S6_RECT_`, `S6_RLBL_`, `S6_RRSI_`
- Nessun conflitto con oggetti di altri EA o manuali
