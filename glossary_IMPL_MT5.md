# Glossary IMPL MT5 — S6 EA
**Prodotto:** S6 — Swing Mean Reversion Daily
**Piattaforma:** MetaTrader 5 / MQL5
**Stato:** Living document

> Questo documento mappa i termini di dominio (da `glossary.md`) agli identificatori MQL5.
> Non contiene requisiti funzionali — solo mapping tecnico.

---

## Mapping Termini → MQL5

| Termine (IT) | Term (EN) | Identificatore MQL5 | Note |
|---|---|---|---|
| Filtro di trend | Trend filter | `iMA(_Symbol, PERIOD_D1, SMA_Period, 0, MODE_SMA, PRICE_CLOSE)` | Handle `hSMA`; legge barra `[1]` via `CopyBuffer` |
| Segnale di ipervenduto | Oversold signal | `iRSI(_Symbol, PERIOD_D1, RSI_Period, PRICE_CLOSE)` | Handle `hRSI`; legge barra `[1]` via `CopyBuffer` |
| Condizione di entrata | Entry condition | `CheckEntryConditions()` | Verifica in `OnTick()` solo su nuova barra |
| Posizione | Position | `PositionGetTicket()`, `POSITION_MAGIC`, `POSITION_SYMBOL` | Filtro per `MagicNumber` e `_Symbol` |
| Stop loss | Stop loss | `SYMBOL_ASK * (1.0 - SL_Percent / 100.0)` | Parametro `slPrice` in `OpenPosition()` |
| Uscita per RSI | RSI exit | `g_rsiValue > RSI_Exit` → `ClosePosition("RSI_EXIT")` | Verificata in `CheckExitConditions()` |
| Uscita per timeout | Timeout exit | `(TimeCurrent() - entryTime) / 86400 >= MaxDays` → `ClosePosition("TIMEOUT")` | `entryTime` salvato all'apertura |
| Uscita per stop loss | SL exit | gestita automaticamente dal broker | Identificata in CSV via `DEAL_REASON_SL` |
| Rischio per trade | Risk per trade | `AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100.0` | `riskAmount` in `CalculateLots()` |
| Dimensione della posizione | Position size | `MathFloor(rawLots / volStep) * volStep` | Arrotondamento per difetto |
| Mercato chiuso | Market closed | `trade.ResultRetcode() == TRADE_RETCODE_MARKET_CLOSED` o `retcode == 10018` o `err == 4756` | In `OpenPosition()` |
| Entrata pendente | Pending entry | `bool pendingEntry` — flag globale | Gestito in `OnTick()` prima di `IsNewBar()` |
| Simbolo di competenza | Symbol of competence | `_Symbol` | Simbolo del grafico su cui è caricato l'EA |
| Recupero al riavvio | Restart recovery | Scansione `PositionsTotal()` in `OnInit()` per `MagicNumber` | Ripristina `entryTime` dalla posizione esistente |
| Report finale | Final report | `GenerateFinalReport()` chiamata in `OnDeinit()` | Include `WriteTradesToCSV()` |
| Valore SMA corrente | Current SMA value | `g_smaValue` | Aggiornato da `ReadIndicators()` |
| Valore RSI corrente | Current RSI value | `g_rsiValue` | Aggiornato da `ReadIndicators()` |
| Nuova barra | New bar | `IsNewBar()` — confronta `iTime(_Symbol, PERIOD_D1, 0)` con `lastBarTime` | |

---

## Input Parameters

| Parametro | Tipo MQL5 | Variabile | Default |
|---|---|---|---|
| RiskPercent | `input double` | `RiskPercent` | 1.0 |
| SMA_Period | `input int` | `SMA_Period` | 200 |
| RSI_Period | `input int` | `RSI_Period` | 14 |
| RSI_Entry | `input int` | `RSI_Entry` | 35 |
| RSI_Exit | `input int` | `RSI_Exit` | 50 |
| SL_Percent | `input double` | `SL_Percent` | 2.0 |
| MaxDays | `input int` | `MaxDays` | 15 |
| ReportInterval | `input int` | `ReportInterval` | 8 |
| MagicNumber | `input int` | `MagicNumber` | 20260509 |
| EnablePhase2 | `input bool` | `EnablePhase2` | false |

---

## Funzioni Principali

| Funzione | Ruolo |
|---|---|
| `OnInit()` | Crea handle SMA/RSI, recupero al riavvio, log inizializzazione |
| `OnTick()` | Entry point principale: gestisce pending, nuova barra, indicatori, exit/entry, report |
| `OnDeinit()` | Report finale, CSV, rilascio handle |
| `IsNewBar()` | Rileva apertura nuova barra D1 |
| `IsWarmedUp()` | Verifica disponibilità barre sufficienti per SMA+RSI |
| `ReadIndicators()` | Legge SMA[1] e RSI[1] nella barra chiusa |
| `HasOpenPosition()` | Verifica presenza posizione per MagicNumber su _Symbol |
| `CheckEntryConditions()` | Valuta condizione di entrata e chiama OpenPosition() |
| `CheckExitConditions()` | Valuta RSI exit e timeout, chiama ClosePosition() |
| `OpenPosition()` | Calcola SL, chiama CalculateLots(), invia ordine BUY |
| `ClosePosition()` | Chiude posizione via trade.PositionClose() |
| `CalculateLots()` | Calcola lotti in base a rischio%, SL%, dati broker |
| `UpdateReport()` | Aggiorna Comment() sul grafico |
| `GenerateFinalReport()` | Log statistiche finali + chiama WriteTradesToCSV() |
| `WriteTradesToCSV()` | Scansiona storico deals e scrive S6_trades.csv |
| `LogEvent()` | Stampa messaggio nel journal con prefisso [S6] |

---

## Codici di Errore Rilevanti

| Codice | Costante MQL5 | Significato |
|---|---|---|
| 4756 | — | Mercato chiuso (GetLastError) |
| 10018 | `TRADE_RETCODE_MARKET_CLOSED` | Mercato chiuso (ResultRetcode) |

---

## File Output Strategy Tester

| File | Percorso |
|---|---|
| S6_trades.csv | `%APPDATA%\MetaQuotes\Tester\<ID>\Agent-127.0.0.1-<PORT>\MQL5\Files\S6_trades.csv` |

---

## Struttura CSV Output

| Colonna | Contenuto | Formato |
|---|---|---|
| Trade | Numero progressivo | intero |
| EntryDate | Data e ora apertura | `yyyy.mm.dd hh:mm` |
| EntryPrice | Prezzo di entrata | decimale |
| ExitDate | Data e ora chiusura | `yyyy.mm.dd hh:mm` |
| ExitPrice | Prezzo di chiusura | decimale |
| Lots | Volume in lotti | 2 decimali |
| Profit | Profitto netto (P&L + swap + commission) | 2 decimali |
| DurationDays | Durata in giorni | 1 decimale |
| Reason | Motivo chiusura | `RSI_EXIT` / `SL` / `TIMEOUT` |
