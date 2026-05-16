---
feature: FEAT-003
title: Gestione del Rischio
type: spec
status: implemented
release: MVP
depends_on: []
required_by: [FEAT-001]
layer: requirements
language: Italian
platform: agnostic
---
# FEAT-003 — Gestione del Rischio · REQUISITI
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Dipende da:** —
**Richiesta da:** FEAT-001

> Questo file descrive esclusivamente il **COSA**.
> Per il **COME** vedere: `plan.md`

---

## Descrizione

Prima di aprire ogni trade, l'EA calcola il volume in lotti in modo che
la perdita massima possibile — cioè la perdita che si verificherebbe
se il prezzo raggiungesse lo stop loss — corrisponda esattamente
alla percentuale di rischio configurata applicata al balance del conto.

---

## Regole

**[S6-003-R001] — Rischio fisso per trade**
Il volume viene calcolato affinché la perdita massima del trade
(distanza prezzo – stop loss × valore del tick per lotto)
sia uguale a `balance × RiskPercent / 100`.

**[S6-003-R002] — Arrotondamento per difetto**
Il volume calcolato viene arrotondato per difetto al multiplo
del volume step del broker. Questo garantisce che il rischio
effettivo sia sempre uguale o inferiore al rischio configurato.
(INV-005)

**[S6-003-R003] — Rispetto dei limiti broker**
Il volume finale deve essere:
- ≥ volume minimo del broker (SYMBOL_VOLUME_MIN)
- ≤ volume massimo del broker (SYMBOL_VOLUME_MAX)
Se il volume calcolato è inferiore al minimo, il trade non viene aperto.
Se il volume calcolato supera il massimo, viene ridotto al massimo.

**[S6-003-R004] — Dati broker validi**
Prima di calcolare il volume, l'EA verifica che i dati necessari
siano validi (distanza SL in punti > 0, valore del tick > 0,
dimensione del tick > 0, volume step > 0).
Se uno di questi valori non è valido, il trade non viene aperto.

**[S6-003-R005] — Balance come base del calcolo**
Il calcolo usa il balance del conto (non l'equity) al momento
della valutazione. Questo rende il rischio stabile e indipendente
da fluttuazioni di equity dovute a posizioni aperte su altri strumenti.

---

## Parametri di Configurazione

| Parametro | Tipo | Default | Descrizione |
|---|---|---|---|
| RiskPercent | decimale | 1.0 | % del balance rischiato per trade |
| SL_Percent | decimale | 2.0 | Stop Loss % dal prezzo Ask (determina la distanza SL) |

---

## Criteri di Accettazione

```
[S6-003-T001] Calcolo corretto del volume
  Dato:    balance = 10.000 USD
           RiskPercent = 1.0 → riskAmount = 100 USD
           Ask = 5000, SL = 4900 → distanza = 100 punti
           tickValue = 1 USD/tick, tickSize = 0.01
  Atteso:  rawLots = 100 / (100 × 1 / 0.01) = 0.01
           volume finale = 0.01 lotti (se volStep = 0.01) ✓

[S6-003-T002] Arrotondamento per difetto
  Dato:    rawLots = 0.037, volStep = 0.01
  Atteso:  lots = 0.03 (arrotondato per difetto) ✓
           rischio effettivo < rischio configurato ✓

[S6-003-T003] Volume sotto il minimo — trade non aperto
  Dato:    volume calcolato < SYMBOL_VOLUME_MIN
  Atteso:  trade non aperto ✓
           log "SKIP | Lots X below broker minimum Y" ✓

[S6-003-T004] Volume sopra il massimo — volume ridotto
  Dato:    volume calcolato > SYMBOL_VOLUME_MAX
  Atteso:  volume ridotto a SYMBOL_VOLUME_MAX ✓
           log "INFO | Lots capped at broker maximum X" ✓

[S6-003-T005] Dati broker non validi — trade non aperto
  Dato:    tickValue = 0 (dati broker non disponibili)
  Atteso:  trade non aperto ✓
           log "ERROR | CalculateLots: invalid symbol data" ✓
```
