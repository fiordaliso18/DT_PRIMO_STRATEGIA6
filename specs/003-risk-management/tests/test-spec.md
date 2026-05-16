# Test Spec — FEAT-003 Gestione del Rischio
**Feature:** FEAT-003
**Piattaforma di test:** MetaTrader 5 Strategy Tester
**Modalità consigliata:** Open prices only

---

## Test Cases

### T001 — Volume coerente con rischio configurato
**Setup:** RiskPercent=1.0, SL_Percent=2.0, balance iniziale 10.000 USD
**Verifica:** nel CSV, colonna "Lots"
**Atteso:** per ogni trade, la perdita massima teorica (Lots × SL_Percent% del prezzo)
deve essere circa 1% del balance al momento dell'apertura.
Tolleranza: ±1 volStep per effetto arrotondamento.

### T002 — Volume mai superiore al massimo broker
**Verifica:** nel CSV, colonna "Lots"
**Atteso:** nessun valore superiore a SYMBOL_VOLUME_MAX per US500

### T003 — Volume mai inferiore al minimo broker
**Verifica:** nel CSV, colonna "Lots"
**Atteso:** nessun valore inferiore a SYMBOL_VOLUME_MIN per US500

### T004 — Arrotondamento per difetto
**Verifica:** ogni valore nella colonna "Lots" è un multiplo esatto di SYMBOL_VOLUME_STEP
**Atteso:** nessun valore con decimali "spuri" (es. 0.013 se volStep=0.01)

### T005 — Rischio basato su balance (non equity)
**Verifica concettuale:** se il balance cambia tra un trade e l'altro,
il volume deve variare proporzionalmente.
**Atteso:** trade aperti con balance maggiore hanno volume maggiore (a parità di parametri)

---

## Calcolo Manuale di Verifica

Per verificare manualmente il volume di un trade:
```
SL_distance = EntryPrice × SL_Percent / 100
risk_amount  = balance × RiskPercent / 100
expected_lots ≈ risk_amount / (SL_distance / point × tickValue / tickSize)
```
Confronta `expected_lots` (arrotondato al volStep) con il valore "Lots" nel CSV.
