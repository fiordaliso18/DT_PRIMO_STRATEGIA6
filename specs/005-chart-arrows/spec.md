---
feature: FEAT-005
title: Frecce sul Grafico
type: spec
status: implemented
release: MVP
depends_on: [FEAT-001, FEAT-002]
required_by: []
layer: requirements
language: Italian
platform: agnostic
---
# FEAT-005 — Frecce sul Grafico · REQUISITI
**Prodotto:** S6 — Swing Mean Reversion Daily
**Release:** MVP
**Stato:** ✅ Implementata
**Dipende da:** FEAT-001, FEAT-002
**Richiesta da:** —

> Questo file descrive esclusivamente il **COSA**.
> Per il **COME** vedere: `plan.md`

---

## Descrizione

L'EA disegna sul grafico oggetti visivi per l'analisi delle operazioni:
- **Frecce** in corrispondenza di ogni apertura (▲) e chiusura (▼) di posizione
- **Label RSI fissi** nell'angolo in alto a sinistra con i parametri di entrata e uscita

Grandezza e colore delle frecce sono configurabili tramite parametri di input.
Tutti gli oggetti grafici sono soggetti al flag `ShowArrows`.

---

## Regole

**[S6-005-R001] — Freccia di entrata**
All'apertura di ogni posizione BUY, l'EA disegna sul grafico una freccia rivolta verso l'alto in corrispondenza del prezzo e del tempo di esecuzione dell'ordine.

**[S6-005-R002] — Freccia di uscita**
Alla chiusura di ogni posizione (per qualsiasi motivo: RSI_EXIT, SL, TIMEOUT), l'EA disegna sul grafico una freccia rivolta verso il basso in corrispondenza del prezzo e del tempo di chiusura.

**[S6-005-R003] — Colore configurabile**
Il colore della freccia di entrata e il colore della freccia di uscita sono indipendentemente configurabili tramite parametri di input.

**[S6-005-R004] — Dimensione configurabile**
La dimensione delle frecce è configurabile tramite un parametro intero (scala 1–5).

**[S6-005-R005] — Disabilitazione**
Le frecce possono essere disabilitate completamente tramite un parametro booleano. Quando disabilitate, nessun oggetto grafico viene creato. Utile in fase di ottimizzazione per ridurre il carico computazionale.

**[S6-005-R006] — Persistenza al termine del backtest**
Le frecce restano visibili sul grafico al termine del backtest o alla rimozione dell'EA,
per consentire l'analisi visuale dei trade. La rimozione manuale avviene tramite
MT5 (tasto destro sul grafico → Oggetti → Elimina tutto).

**[S6-005-R007] — Non interferenza con altri oggetti**
Tutti gli oggetti grafici S6 usano nomi univoci con prefisso dedicato:
- `S6_BUY_` — frecce di entrata
- `S6_EXIT_` — frecce di uscita
- `S6_RSI_ENTRY`, `S6_RSI_EXIT` — label RSI fissi

**[S6-005-R008] — Label RSI fissi sul grafico**
All'avvio dell'EA (`Init()`), vengono disegnati nell'angolo in alto a sinistra del grafico
due oggetti testo fissi (OBJ_LABEL, posizione in pixel non dipendente dal prezzo) con:
- `"RSI Entry < N"` — N = valore del parametro RSI_Entry; colore = ArrowBuyColor
- `"RSI Exit > N"` — N = valore del parametro RSI_Exit; colore = ArrowExitColor

Font: Arial Bold, dimensione 14pt. Soggetti al flag ShowArrows ([S6-005-R005]).

---

## Parametri di Configurazione

| Parametro | Tipo | Default | Descrizione |
|---|---|---|---|
| ShowArrows | bool | true | Abilita frecce sul grafico |
| ArrowSize | intero | 3 | Dimensione frecce (1 = minima, 5 = massima) |
| ArrowBuyColor | color | clrDodgerBlue | Colore freccia di entrata |
| ArrowExitColor | color | clrOrangeRed | Colore freccia di uscita |

---

## Criteri di Accettazione

```
[S6-005-T001] Freccia BUY disegnata all'entrata
  Dato:    condizioni di entrata soddisfatte, ShowArrows=true
  Quando:  ordine BUY eseguito con successo
  Atteso:  freccia verso l'alto visibile sul grafico al prezzo di entrata ✓
           nome oggetto inizia con "S6_BUY_" ✓

[S6-005-T002] Freccia EXIT disegnata alla chiusura
  Dato:    posizione aperta, ShowArrows=true
  Quando:  posizione chiusa (qualsiasi motivo)
  Atteso:  freccia verso il basso visibile sul grafico al prezzo di chiusura ✓
           nome oggetto inizia con "S6_EXIT_" ✓

[S6-005-T003] Dimensione frecce rispetta ArrowSize
  Dato:    ArrowSize=1 vs ArrowSize=5
  Atteso:  freccia con ArrowSize=5 visibilmente più grande di ArrowSize=1 ✓

[S6-005-T004] Colori rispettano i parametri
  Dato:    ArrowBuyColor=clrGreen, ArrowExitColor=clrRed
  Atteso:  freccia BUY verde, freccia EXIT rossa ✓

[S6-005-T005] ShowArrows=false — nessun oggetto grafico S6
  Dato:    ShowArrows=false
  Atteso:  nessun oggetto "S6_BUY_*", "S6_EXIT_*", "S6_RSI_*" sul grafico ✓

[S6-005-T007] Label RSI visibili all'avvio
  Dato:    ShowArrows=true, RSI_Entry=35, RSI_Exit=50
  Atteso:  label "RSI Entry < 35" in alto a sinistra, Arial Bold 14pt, colore blu ✓
           label "RSI Exit > 50" sotto, stessa posizione, colore arancione ✓

[S6-005-T006] Pulizia alla deinizializzazione
  Dato:    frecce presenti sul grafico
  Quando:  Strategy Tester termina
  Atteso:  tutte le frecce S6_BUY_* e S6_EXIT_* restano visibili sul grafico ✓
           rimozione manuale possibile da MT5 Oggetti -> Elimina tutto ✓
```
