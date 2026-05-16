# ADR-001 — L'EA opera solo in acquisto (BUY only) su US500
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

La strategia S6 è progettata per catturare rimbalzi in trend rialzista (mean reversion al rialzo). La domanda è: l'EA deve operare solo in acquisto, o deve anche aprire posizioni short quando il mercato è in trend ribassista?

---

## Decisione

L'EA opera **esclusivamente in acquisto (BUY only)** sul simbolo US500.
Non apre mai posizioni SELL.

---

## Alternative Considerate

**Alternativa A — Bidirezionale (BUY + SELL)**
L'EA apre BUY in trend rialzista e SELL in trend ribassista (RSI > soglia di ipercomprato).

Scartata perché: la strategia di mean reversion short su indici azionari ha un profilo rischio/rendimento asimmetrico sfavorevole. Gli indici azionari hanno un bias strutturale rialzista di lungo periodo. Il mean reversion short è più rischioso e richiede parametri diversi. Mantenere la strategia unidirezionale semplifica il testing e la validazione.

**Alternativa B — BUY only su qualsiasi simbolo**
L'EA opera solo BUY ma può essere applicato a qualsiasi simbolo.

Accettata parzialmente: l'EA può tecnicamente essere caricato su altri grafici, ma è ottimizzato e testato su US500. Altri simboli richiedono ottimizzazione separata dei parametri.

---

## Conseguenze

- La logica di entrata è semplificata: una sola direzione da valutare.
- Il codice non contiene mai `trade.Sell()`.
- Il comportamento in mercati ribassisti prolungati è di non operare (filtro SMA200).
- Vincolo catturato in `INV-002`.
