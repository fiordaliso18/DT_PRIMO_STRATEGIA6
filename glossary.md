# Glossary — S6 EA
**Prodotto:** S6 — Swing Mean Reversion Daily
**Autore:** Primo Fiordaliso
**Stato:** Living document — estendi quando emergono nuovi termini

> Questo documento definisce solo termini di dominio.
> Non contiene termini platform-specifici, nomi di API, né codice.
> Per la mappatura dei termini di dominio agli identificatori MQL5,
> vedi `glossary_IMPL_MT5.md`.
>
> Ogni termine appare in italiano (usato nei file spec.md)
> e in inglese (usato nei file plan.md e nel codice).
> Il significato è identico — cambia solo la lingua.

---

## Come Leggere Questo Glossario

Ogni voce ha:
- **Termine / Term** — nome italiano e inglese
- **Definizione / Definition** — significato preciso nel contesto di questo prodotto
- **Non è / Is NOT** — interpretazioni errate comuni da evitare

---

## Termini di Dominio

---

### Filtro di Trend / Trend Filter

| | |
|---|---|
| **Termine (IT)** | Filtro di trend |
| **Term (EN)** | Trend filter |
| **Definizione** | La condizione che verifica se il mercato è in trend rialzista. Soddisfatta quando il prezzo di chiusura dell'ultima barra completata è superiore alla media mobile semplice di periodo configurato calcolata sulla stessa barra. |
| **Definition** | The condition verifying whether the market is in an uptrend. Satisfied when the closing price of the last completed bar is above the simple moving average of configured period computed on the same bar. |
| **Non è / Is NOT** | Un indicatore separato. È una condizione booleana derivata dalla combinazione di prezzo e SMA. |

---

### Segnale di Ipervenduto / Oversold Signal

| | |
|---|---|
| **Termine (IT)** | Segnale di ipervenduto |
| **Term (EN)** | Oversold signal |
| **Definizione** | La condizione che identifica un ritracciamento del prezzo in zona di ipervenduto. Soddisfatta quando il valore RSI dell'ultima barra completata è inferiore alla soglia di entrata configurata. |
| **Definition** | The condition identifying a price retracement into oversold territory. Satisfied when the RSI value of the last completed bar is below the configured entry threshold. |
| **Non è / Is NOT** | Una divergenza RSI né un pattern di candele. È esclusivamente il confronto numerico RSI < soglia. |

---

### Condizione di Entrata / Entry Condition

| | |
|---|---|
| **Termine (IT)** | Condizione di entrata |
| **Term (EN)** | Entry condition |
| **Definizione** | L'insieme completo delle condizioni che devono essere tutte vere contemporaneamente per aprire un trade: (1) nessuna posizione aperta, (2) filtro di trend soddisfatto, (3) segnale di ipervenduto soddisfatto. |
| **Definition** | The complete set of conditions that must all be true simultaneously to open a trade: (1) no open position, (2) trend filter satisfied, (3) oversold signal satisfied. |
| **Non è / Is NOT** | Un segnale di acquisto immediato. La condizione viene verificata solo alla chiusura di ogni nuova barra giornaliera. |

---

### Posizione / Position

| | |
|---|---|
| **Termine (IT)** | Posizione |
| **Term (EN)** | Position |
| **Definizione** | Un'operazione di acquisto aperta sul conto del trader sul simbolo di competenza, gestita dall'EA tramite il suo identificatore univoco (MagicNumber). |
| **Definition** | An open buy trade on the trader's account on the symbol of competence, managed by the EA via its unique identifier (MagicNumber). |
| **Non è / Is NOT** | Un ordine pendente. L'EA gestisce solo posizioni eseguite a mercato. |

---

### Stop Loss

| | |
|---|---|
| **Termine (IT)** | Stop loss |
| **Term (EN)** | Stop loss |
| **Definizione** | Il livello di prezzo a cui il broker chiude automaticamente la posizione in perdita. Calcolato all'apertura come prezzo Ask moltiplicato per (1 − SL% / 100). Non viene mai modificato dopo l'apertura. |
| **Definition** | The price level at which the broker automatically closes the position at a loss. Computed at opening as Ask price multiplied by (1 − SL% / 100). Never modified after opening. |
| **Non è / Is NOT** | Uno stop loss mobile (trailing). L'EA S6 usa uno stop loss fisso calcolato all'entrata. |

---

### Uscita per RSI / RSI Exit

| | |
|---|---|
| **Termine (IT)** | Uscita per RSI |
| **Term (EN)** | RSI exit |
| **Definizione** | La condizione di uscita dal trade verificata quando il valore RSI dell'ultima barra completata supera la soglia di uscita configurata. Indica il ritorno del prezzo in zona neutra/ipercomprata, completando il ciclo di mean reversion. |
| **Definition** | The exit condition triggered when the RSI value of the last completed bar exceeds the configured exit threshold. Indicates price return to neutral/overbought territory, completing the mean reversion cycle. |
| **Non è / Is NOT** | Un segnale di vendita. L'EA chiude la posizione aperta — non apre una posizione short. |

---

### Uscita per Timeout / Timeout Exit

| | |
|---|---|
| **Termine (IT)** | Uscita per timeout |
| **Term (EN)** | Timeout exit |
| **Definizione** | La condizione di uscita dal trade attivata quando il numero di giorni trascorsi dall'apertura è uguale o superiore al periodo massimo configurato. Evita che la posizione rimanga aperta indefinitamente senza che la condizione RSI si verifichi. |
| **Definition** | The exit condition triggered when the number of days elapsed since opening is equal to or greater than the configured maximum period. Prevents the position from remaining open indefinitely without the RSI condition materializing. |
| **Non è / Is NOT** | Un'uscita per perdita. Il timeout chiude la posizione indipendentemente dal P&L. |

---

### Rischio per Trade / Risk per Trade

| | |
|---|---|
| **Termine (IT)** | Rischio per trade |
| **Term (EN)** | Risk per trade |
| **Definizione** | L'importo massimo che il trader è disposto a perdere su un singolo trade, espresso come percentuale del balance del conto al momento dell'apertura. Determina la dimensione della posizione (lotti). |
| **Definition** | The maximum amount the trader is willing to lose on a single trade, expressed as a percentage of the account balance at opening time. Determines the position size (lots). |

---

### Dimensione della Posizione / Position Size

| | |
|---|---|
| **Termine (IT)** | Dimensione della posizione |
| **Term (EN)** | Position size |
| **Definizione** | Il volume in lotti del trade, calcolato in modo che la perdita massima (prezzo di entrata − stop loss) corrisponda esattamente al rischio per trade. Arrotondato per difetto al volume step del broker. |
| **Definition** | The trade volume in lots, computed so that the maximum loss (entry price − stop loss) exactly matches the risk per trade. Rounded down to the broker's volume step. |

---

### Mercato Chiuso / Market Closed

| | |
|---|---|
| **Termine (IT)** | Mercato chiuso |
| **Term (EN)** | Market closed |
| **Definizione** | La condizione in cui il broker non accetta ordini a mercato perché la sessione di trading è chiusa. Si verifica tipicamente nel fine settimana. Quando l'apertura di un trade viene rifiutata per questo motivo, l'EA attiva il flag di entrata pendente. |
| **Definition** | The condition in which the broker does not accept market orders because the trading session is closed. Typically occurs on weekends. When a trade opening is rejected for this reason, the EA activates the pending entry flag. |

---

### Entrata Pendente / Pending Entry

| | |
|---|---|
| **Termine (IT)** | Entrata pendente |
| **Term (EN)** | Pending entry |
| **Definizione** | Lo stato interno dell'EA in cui una condizione di entrata è stata rilevata ma il trade non è stato ancora eseguito perché il mercato era chiuso al momento del segnale. L'EA riproverà ad aprire il trade al primo tick disponibile. |
| **Definition** | The EA's internal state in which an entry condition was detected but the trade has not yet been executed because the market was closed at signal time. The EA will retry opening the trade on the first available tick. |

---

### Simbolo di Competenza / Symbol of Competence

| | |
|---|---|
| **Termine (IT)** | Simbolo di competenza |
| **Term (EN)** | Symbol of competence |
| **Definizione** | Il simbolo sul quale l'EA opera. Corrisponde al simbolo del grafico sul quale il robot è caricato (US500). L'EA ignora tutti gli eventi su simboli diversi. |
| **Definition** | The symbol on which the EA operates. Corresponds to the symbol of the chart on which the robot is loaded (US500). The EA ignores all events on different symbols. |

---

### Recupero al Riavvio / Restart Recovery

| | |
|---|---|
| **Termine (IT)** | Recupero al riavvio |
| **Term (EN)** | Restart recovery |
| **Definizione** | La procedura eseguita all'inizializzazione dell'EA per rilevare posizioni già aperte con il suo MagicNumber. Se una posizione viene trovata, l'EA riprende la gestione senza riaprire e senza duplicare la notifica di entrata. |
| **Definition** | The procedure executed at EA initialization to detect positions already open with its MagicNumber. If a position is found, the EA resumes management without reopening and without duplicating the entry notification. |

---

### Report Finale / Final Report

| | |
|---|---|
| **Termine (IT)** | Report finale |
| **Term (EN)** | Final report |
| **Definizione** | Il riepilogo statistico prodotto dall'EA alla chiusura (deinizializzazione). Include: numero di trade, win rate, profit factor, max drawdown, durata media. Il report finale include anche l'esportazione CSV trade-by-trade. |
| **Definition** | The statistical summary produced by the EA at shutdown (deinitialization). Includes: trade count, win rate, profit factor, max drawdown, average duration. The final report also includes the trade-by-trade CSV export. |
