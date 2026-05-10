---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-04-final-validation]
status: 'complete'
completedAt: '2026-05-10'
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
project_name: 'S6 Swing Mean Reversion Daily EA'
user_name: 'Primo'
date: '2026-05-10'
---

# S6 Swing Mean Reversion Daily EA - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for S6 Swing Mean Reversion Daily EA, decomposing the requirements from the PRD and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: The EA evaluates entry conditions (Price > SMA200 AND RSI14 < entry threshold AND no open position) exactly once per confirmed daily candle close
FR2: The EA detects a new daily bar and triggers signal evaluation once per bar only
FR3: The EA detects when RSI(14) crosses above the exit threshold while a position is open
FR4: The EA suppresses signal evaluation during the indicator warm-up period
FR5: The EA places a BUY market order at the open of the next daily candle following a signal bar
FR6: The EA attaches a Stop Loss to the position at the exact moment the order is executed
FR7: The EA closes a position when RSI exceeds the configured exit threshold
FR8: The EA closes a position when the maximum holding period (MaxDays) is reached
FR9: The EA records the reason for each position closure (RSI exit / SL / timeout / manual)
FR10: The EA calculates position size in lots from account balance, risk percentage, SL distance, and tick value
FR11: The EA validates calculated lot size against broker minimum, maximum, and step constraints
FR12: The EA skips and logs a trade when the calculated lot size falls below the broker minimum
FR13: The EA enforces a maximum of one open position at any time
FR14: The EA verifies trading is permitted before placing any order
FR15: The EA computes SMA with a configurable period on the Daily timeframe for the current symbol
FR16: The EA computes RSI with a configurable period on the Daily timeframe for the current symbol
FR17: The EA displays a visual Take Profit line on the chart at R/R 1:2.5 from entry *(Phase 2)*
FR18: The EA displays current Win Rate in the chart comment area
FR19: The EA displays current Max Drawdown in the chart comment area
FR20: The EA generates a periodic performance snapshot at a user-defined time interval *(Phase 2)*
FR21: The EA generates a final summary report when deactivated or manually stopped
FR22: The final report includes: total trades, win rate, profit factor, max drawdown, average trade duration
FR23: The EA logs each trade to CSV: date, entry price, SL, exit price, P&L, days open, exit reason *(Phase 2)*
FR24: The EA writes diagnostic events to the MT5 journal log (signal detected, order placed, position closed, report generated)
FR25: The user configures risk percentage per trade
FR26: The user configures SMA period
FR27: The user configures RSI period
FR28: The user configures RSI entry threshold
FR29: The user configures RSI exit threshold
FR30: The user configures Stop Loss distance as a percentage
FR31: The user configures maximum holding days
FR32: The user configures periodic report interval in hours *(Phase 2)*
FR33: The user configures a unique Magic Number for EA order identification
FR34: The EA recovers open position state after MT5 restart by scanning positions with its Magic Number
FR35: The EA suppresses duplicate trade entries when a position already exists after restart
FR36: The EA executes correctly in MT5 Strategy Tester "Open Prices Only" mode
FR37: The EA operates without external DLL dependencies or files required at runtime
FR38: The EA writes a performance summary row (timestamp, total trades, win rate, profit factor, max drawdown, average duration) to S6_report.csv on every periodic snapshot and at final report *(Phase 2)*
FR39: The EA sends a push notification to the MT5 mobile app on every position close, containing exit reason and P&L; failures are logged without stopping the EA *(Phase 2)*

### NonFunctional Requirements

NFR1: Signal evaluation completes within the same tick that triggers bar-change detection — no deferred processing
NFR2: Order placement (entry + SL) completes within a single OnTick() call on the first tick of the new daily candle
NFR3: Report generation (chart comment update) does not block order execution
NFR4: Strategy Tester completes a 5-year D1 backtest run in under 60 seconds on a standard desktop (Intel i5 / 8 GB RAM); EA OnTick() processing time does not exceed 50 ms per bar
NFR5: After MT5 restart, the EA identifies any open position within the first OnInit() call, before the next signal evaluation
NFR6: Failed trade orders are logged and retried on the next bar — no silent failures
NFR7: All error conditions (order failure, invalid lot size, insufficient bars) are logged to the MT5 journal with sufficient detail for diagnosis
NFR8: Position sizing never results in a risk amount exceeding AccountBalance × RiskPercent / 100 — MathFloor rounding enforced
NFR9: SMA and RSI values used for signal evaluation are from the closed bar (index 1), never the forming bar (index 0)
NFR10: Win Rate and Max Drawdown are recalculated from actual closed trade history on every report update — no approximations
NFR11: Backtest results are deterministic: identical inputs on identical data produce identical outputs across runs
NFR12: EA functions correctly on ECN, STP, and market-maker broker accounts without broker-specific code
NFR13: EA validates that the calculated SL distance (in points) ≥ SYMBOL_TRADE_STOPS_LEVEL before placing any order; if the constraint is not met, the order is skipped and the event is logged (FR12 pattern)
NFR14: EA uses only standard MQL5 library functions — no DLL imports, no external services, no internet calls
NFR15: CSV log output (Phase 2) uses UTF-8 encoding, comma-delimited, compatible with Excel and standard spreadsheet tools

### Additional Requirements

- **[ARCH-01 — Starter/Skeleton]** First implementation story is creating `src/S6_EA.mq5` with the 8-section skeleton and compiling in MetaEditor (F7, zero errors). No CLI scaffolding — manual creation.
- **[ARCH-02 — Single-File Structure]** All implementation lives in one file (`S6_EA.mq5`) organised by 8 comment-delimited sections: `#property + #include` → INPUT PARAMETERS → GLOBAL STATE → SIGNAL ENGINE → ORDER MANAGER → RISK CALCULATOR → REPORT ENGINE + LOGGER → EVENT CALLBACKS
- **[ARCH-03 — CTrade Mandate]** All order execution uses `CTrade trade;` global — `OrderSend()` direct calls are forbidden. `trade.SetExpertMagicNumber(MagicNumber)` called in `OnInit()`.
- **[ARCH-04 — CopyBuffer Index 1]** All indicator value reads use `CopyBuffer(..., 1, ...)` (closed bar). Index 0 (forming bar) is forbidden.
- **[ARCH-05 — MagicNumber Position Filter]** Every position check iterates `PositionsTotal()` and filters by `PositionGetInteger(POSITION_MAGIC) == MagicNumber`. Raw `PositionsTotal() > 0` check is forbidden.
- **[ARCH-06 — OnTick() Execution Order]** Fixed 5-step sequence: (1) IsNewBar gate → (2) IsWarmedUp gate → (3) equityHigh update → (4) CheckExitConditions → (5) CheckEntryConditions → UpdateReport last.
- **[ARCH-07 — Indicator Handle Lifecycle]** Handles `hSMA` and `hRSI` created in `OnInit()`, stored as global integers, reused every tick, released via `IndicatorRelease()` in `OnDeinit()`.
- **[ARCH-08 — Phase 2 Flat Gating]** `input bool EnablePhase2 = false;` guards all Phase 2 features. Each Phase 2 block is a flat `if(EnablePhase2)` — no nesting.
- **[ARCH-09 — Error Pattern]** On `OrderSend()` failure or constraint violation: log error code via `LogEvent()`, skip trade, retry on next bar naturally. No immediate retry.
- **[ARCH-10 — LogEvent Prefix]** All `Print()` calls routed through `void LogEvent(string msg) { Print("[S6] " + msg); }`. Raw `Print()` without prefix is forbidden.
- **[ARCH-11 — Equity HWM Timing]** `equityHigh` updated inside `OnTick()` immediately after `IsNewBar()` gate and before any signal evaluation.
- **[ARCH-12 — WR/DD Calculation]** Full recalculation via `HistoryDealsTotal()` iteration on every `UpdateReport()` call — no incremental approximation.
- **[ARCH-13 — Repository Structure]** `src/S6_EA.mq5` + `tests/backtest/S6_backtest_2024.ini` + `README.md`. MT5 deployment: copy `.ex5` to `%APPDATA%\MetaQuotes\Terminal\<ID>\MQL5\Experts\`.
- **[ARCH-14 — ClosePosition Reason]** `ClosePosition(string reason)` always receives one of: `"RSI_EXIT"`, `"TIMEOUT"`, `"SL_HIT"`, `"MANUAL"`. Parameterless call is forbidden.

### UX Design Requirements

*Not applicable — S6 EA is an MQL5 plugin with no custom UI layer. Interaction occurs exclusively via MT5's native parameter dialog, chart comment area, and journal log.*

### FR Coverage Map

FR1: Epic 2 — Entry 3-condition gate sulla daily close confermata
FR2: Epic 1 — Bar-change detection via iTime comparison
FR3: Epic 2 — RSI exit condition detection (posizione aperta)
FR4: Epic 1 — Warm-up guard: sopprime segnali fino a Bars ≥ SMA+RSI+1
FR5: Epic 2 — BUY market order all'apertura della candle successiva
FR6: Epic 2 — SL immediato all'apertura posizione
FR7: Epic 2 — RSI > RSI_Exit → chiude posizione
FR8: Epic 2 — MaxDays timeout → chiude posizione
FR9: Epic 2 — Motivo chiusura registrato: RSI_EXIT / TIMEOUT / SL_HIT / MANUAL
FR10: Epic 2 — Lot size = Balance × Risk% / (SL_points × TickValue)
FR11: Epic 2 — Validazione lot vs SYMBOL_VOLUME_MIN/MAX/STEP
FR12: Epic 2 — Skip + log quando lots < SYMBOL_VOLUME_MIN o SL < broker min
FR13: Epic 2 — Max 1 posizione aperta (filtro MagicNumber)
FR14: Epic 2 — IsTradeAllowed() check prima di ogni ordine
FR15: Epic 1 — Handle SMA creato in OnInit(), legge D1 bar[1]
FR16: Epic 1 — Handle RSI creato in OnInit(), legge D1 bar[1]
FR17: Epic 3 — Linea TP visuale a R/R 1:2.5 (Phase 2)
FR18: Epic 2 — Win Rate corrente nel chart comment
FR19: Epic 2 — Max Drawdown corrente nel chart comment
FR20: Epic 3 — Snapshot periodico ogni ReportInterval ore (Phase 2)
FR21: Epic 2 — Final report in OnDeinit()
FR22: Epic 2 — Final report: total trades, WR, PF, max DD, avg duration
FR23: Epic 3 — CSV log per trade: date/entry/SL/exit/P&L/days/reason (Phase 2)
FR24: Epic 2 — Tutti gli eventi diagnostici via LogEvent() al journal MT5
FR25: Epic 1 — Input RiskPercent (default 1.0)
FR26: Epic 1 — Input SMA_Period (default 200)
FR27: Epic 1 — Input RSI_Period (default 14)
FR28: Epic 1 — Input RSI_Entry (default 32)
FR29: Epic 1 — Input RSI_Exit (default 50)
FR30: Epic 1 — Input SL_Percent (default 2.0)
FR31: Epic 1 — Input MaxDays (default 15)
FR32: Epic 1+3 — Input ReportInterval dichiarato in Epic 1, usato in Epic 3
FR33: Epic 1 — Input MagicNumber (default 20260509)
FR34: Epic 2 — OnInit() scansiona posizioni aperte per MagicNumber
FR35: Epic 2 — Sopprime entrata duplicata se posizione già esiste
FR36: Epic 1 — Strategy Tester "Open Prices Only" compatibility
FR37: Epic 1 — Nessun DLL import, nessuna dipendenza esterna
FR38: Epic 3 — Performance summary (WR, PF, MaxDD, total trades) scritta su file CSV ad ogni snapshot e al final report (Phase 2)
FR39: Epic 3 — Push notification inviata all'app MT5 mobile ad ogni chiusura posizione (Phase 2)
FR40: Epic 3 — Linea entry (verde, solid) e linea SL (rossa, dashed) disegnate sul grafico quando la posizione è aperta; rimosse alla chiusura (Phase 2)

## Epic List

### Epic 1: EA Foundation & Indicator Engine

Il trader dispone di un file `S6_EA.mq5` compilabile (zero errori in MetaEditor), con tutti gli input parameters configurabili, i handle SMA/RSI creati e rilasciati correttamente, il gate di bar-change (`iTime`), e la warm-up guard. L'EA si carica in MT5 Strategy Tester senza errori.

**FRs covered:** FR2, FR4, FR15, FR16, FR25, FR26, FR27, FR28, FR29, FR30, FR31, FR32, FR33, FR36, FR37

### Epic 2: S6 Strategy Execution & Phase 1 Reporting

Il trader può eseguire un backtest completo della strategia S6: gate di entrata a 3 condizioni, ordine BUY con SL immediato, uscite (RSI / timeout / SL), position sizing con risk management corretto, report live WR+DD nel chart comment, report finale all'arresto, recupero stato dopo restart MT5. Gate di successo: PF ≥ 1.5, max DD < 2% su 1 anno.

**FRs covered:** FR1, FR3, FR5, FR6, FR7, FR8, FR9, FR10, FR11, FR12, FR13, FR14, FR18, FR19, FR21, FR22, FR24, FR34, FR35

### Epic 3: Phase 2 — Live Operations & Extended Reporting

Con `EnablePhase2 = true`, il trader ottiene: report periodico ogni N ore, log CSV di ogni trade, performance summary su file CSV, push notification mobile su ogni chiusura posizione, linea TP visuale a R/R 1:2.5, e linee Entry/SL sul grafico. Supporta operatività live non presidiata 24/7.

**FRs covered:** FR17, FR20, FR23, FR38, FR39, FR40

---

## Epic 1: EA Foundation & Indicator Engine

Il trader dispone di un file `S6_EA.mq5` compilabile (zero errori in MetaEditor), con tutti gli input parameters configurabili, i handle SMA/RSI creati e rilasciati correttamente, il gate di bar-change (`iTime`), e la warm-up guard. L'EA si carica in MT5 Strategy Tester senza errori.

### Story 1.1: S6_EA.mq5 Skeleton with 8-Section Structure & Input Parameters

As a developer,
I want a compilable `S6_EA.mq5` with the complete 8-section structure, all 10 input parameters, and the three event callback stubs,
So that I have a verified foundation I can load in MT5 Strategy Tester without errors and build upon in subsequent stories.

**Acceptance Criteria:**

**Given** MetaEditor is open on Windows with MT5 installed
**When** I create `src/S6_EA.mq5` with the canonical 8-section structure (each section delimited by `//================================================================` comments): `#property + #include` → INPUT PARAMETERS → GLOBAL STATE → SIGNAL ENGINE → ORDER MANAGER → RISK CALCULATOR → REPORT ENGINE + LOGGER → EVENT CALLBACKS
**Then** the file compiles without errors or warnings in MetaEditor (F7)

**Given** the EA file declares all 10 input parameters
**When** I inspect the INPUT PARAMETERS section
**Then** I find exactly these declarations with these defaults:
```
input double RiskPercent   = 1.0;
input int    SMA_Period     = 200;
input int    RSI_Period     = 14;
input int    RSI_Entry      = 32;
input int    RSI_Exit       = 50;
input double SL_Percent     = 2.0;
input int    MaxDays        = 15;
input int    ReportInterval = 8;
input int    MagicNumber    = 20260509;
input bool   EnablePhase2   = false;
```

**Given** the file uses CTrade
**When** I check the top of the file and the GLOBAL STATE section
**Then** `#include <Trade/Trade.mqh>` appears after `#property` directives, and `CTrade trade;` is declared as a camelCase global variable

**Given** OnInit() is called
**When** the EA initializes
**Then** `trade.SetExpertMagicNumber(MagicNumber)` is called inside `OnInit()`, and global state variables `datetime lastBarTime`, `double equityHigh`, `int totalTrades`, `int winTrades`, `int hSMA`, `int hRSI`, `bool isWarmedUp` are declared in the GLOBAL STATE section with camelCase names

**Given** the EA skeleton is compiled and the `.ex5` copied to `MQL5\Experts\`
**When** I attach it to a US500 D1 chart in Strategy Tester ("Open Prices Only" mode)
**Then** the EA loads, `OnInit()` returns `INIT_SUCCEEDED`, and no error appears in the Experts log

**FRs satisfied:** FR25–FR33, FR36, FR37
**ARCH satisfied:** ARCH-01, ARCH-02, ARCH-03

---

### Story 1.2: Bar-Change Detection & Warm-Up Guard

As a developer,
I want `IsNewBar()` and `IsWarmedUp()` implemented as the first two gates in `OnTick()`,
So that signal evaluation runs exactly once per confirmed D1 candle close and never before the minimum indicator warm-up period is complete.

**Acceptance Criteria:**

**Given** the EA is running in Strategy Tester on US500 D1
**When** a new D1 bar opens (first tick of the new bar)
**Then** `iTime(_Symbol, PERIOD_D1, 0) != lastBarTime` evaluates to true, `lastBarTime` is updated, and execution proceeds past the `IsNewBar()` gate

**Given** the EA has already processed the first tick of a new bar
**When** subsequent ticks arrive within the same D1 bar
**Then** `iTime(_Symbol, PERIOD_D1, 0) == lastBarTime` and `OnTick()` returns immediately — no signal evaluation, no order logic executes

**Given** `Bars < SMA_Period + RSI_Period + 1` (insufficient history)
**When** `IsWarmedUp()` is evaluated on a new bar
**Then** `isWarmedUp = false`, `OnTick()` returns, and `LogEvent("WARMUP | Insufficient bars: " + (string)Bars)` is written to the MT5 journal

**Given** `Bars >= SMA_Period + RSI_Period + 1` for the first time
**When** `IsWarmedUp()` detects sufficient bars
**Then** `isWarmedUp = true`, the transition is logged once via `LogEvent()`, and execution is not suppressed on subsequent bars

**Given** `OnInit()` has just completed
**When** the first `OnTick()` fires
**Then** `lastBarTime` is already initialized to prevent a spurious bar-change event on startup

**FRs satisfied:** FR2, FR4
**NFRs satisfied:** NFR1

---

### Story 1.3: SMA & RSI Indicator Handle Lifecycle

As a developer,
I want SMA and RSI indicator handles created in `OnInit()`, their closed-bar values readable via `CopyBuffer` on every new bar, and the handles released in `OnDeinit()`,
So that signal evaluation always uses verified D1 closed-candle indicator data and no resource leak occurs across backtest runs.

**Acceptance Criteria:**

**Given** `OnInit()` is called
**When** indicator handles are created
**Then** `hSMA = iMA(_Symbol, PERIOD_D1, SMA_Period, 0, MODE_SMA, PRICE_CLOSE)` and `hRSI = iRSI(_Symbol, PERIOD_D1, RSI_Period, PRICE_CLOSE)` return valid integers (≥ 0, not `INVALID_HANDLE`)
**And** if either handle returns `INVALID_HANDLE`, `OnInit()` logs the error via `LogEvent("ERROR | Indicator handle failed")` and returns `INIT_FAILED`

**Given** a new D1 bar has been confirmed (past `IsNewBar` gate)
**When** indicator values are read
**Then** `CopyBuffer(hSMA, 0, 1, 1, smaBuffer)` and `CopyBuffer(hRSI, 0, 1, 1, rsiBuffer)` use `start=1` (closed bar) — never `start=0` (forming bar)

**Given** `CopyBuffer()` returns a result < 1 (data not yet available)
**When** the read failure is detected
**Then** `LogEvent("ERROR | CopyBuffer failed")` is called and `OnTick()` returns without signal evaluation

**Given** `OnDeinit()` is called
**When** handles are released
**Then** `IndicatorRelease(hSMA)` and `IndicatorRelease(hRSI)` are called, and both globals are set to `INVALID_HANDLE`

**Given** a 5-year D1 backtest completes
**When** the tester finishes
**Then** no indicator handle errors appear in the Strategy Tester log

**FRs satisfied:** FR15, FR16
**NFRs satisfied:** NFR9, NFR4
**ARCH satisfied:** ARCH-04, ARCH-07

---

## Epic 2: S6 Strategy Execution & Phase 1 Reporting

Il trader può eseguire un backtest completo della strategia S6: gate di entrata a 3 condizioni, ordine BUY con SL immediato, uscite (RSI / timeout / SL), position sizing con risk management corretto, report live WR+DD nel chart comment, report finale all'arresto, recupero stato dopo restart MT5. Gate di successo: PF ≥ 1.5, max DD < 2% su 1 anno.

### Story 2.1: Risk Calculator — CalculateLots & LogEvent

As a developer,
I want `CalculateLots()` implemented with the correct position sizing formula, broker constraint validation, and `LogEvent()` wired as the single logging entry point for all subsystems,
So that every potential order is sized to exactly the configured risk level, broker minimums are respected, and all events produce filterable `[S6]`-prefixed journal entries.

**Acceptance Criteria:**

**Given** a trade opportunity is being evaluated
**When** `CalculateLots()` is called
**Then** it computes lots using: `MathFloor((Balance × RiskPercent/100) / (sl_points × TickValue) / VolumeStep) × VolumeStep`
**And** the result is always rounded down (`MathFloor`) — never up

**Given** the calculated lots < `SYMBOL_VOLUME_MIN`
**When** `CalculateLots()` returns
**Then** it returns `0.0` and `LogEvent("SKIP | Lots below broker minimum: " + DoubleToString(lots,2))` is called

**Given** the calculated lots > `SYMBOL_VOLUME_MAX`
**When** `CalculateLots()` evaluates
**Then** lots is capped at `SYMBOL_VOLUME_MAX` and the cap is logged via `LogEvent()`

**Given** any system event (signal, order, close, error, report)
**When** `LogEvent(string msg)` is called
**Then** `Print("[S6] " + msg)` is executed — all journal entries carry the `[S6]` prefix and are filterable in the MT5 Experts journal

**Given** a 5-year backtest with `RiskPercent = 1.0`
**When** I examine all orders in the backtest report
**Then** no single trade risk amount exceeds `AccountBalance × 1%` at order time

**FRs satisfied:** FR10, FR11, FR12, FR24
**NFRs satisfied:** NFR7, NFR8

---

### Story 2.2: Order Manager — OpenPosition & ClosePosition

As a developer,
I want `OpenPosition()` and `ClosePosition(string reason)` implemented using CTrade, with SL minimum distance validation, `IsTradeAllowed()` check, and error-log-skip pattern on failure,
So that every order is placed with an immediate stop loss, broker SL constraints are enforced, and order failures never crash the EA.

**Acceptance Criteria:**

**Given** `CheckEntryConditions()` returns true
**When** `OpenPosition()` is called
**Then** `IsTradeAllowed()` is checked first — if false, `LogEvent("SKIP | Trading not allowed")` and return false without placing any order

**Given** trading is allowed and `CalculateLots()` returns > 0
**When** `OpenPosition()` computes the SL
**Then** `sl_price = ASK × (1 − SL_Percent/100)` and `sl_points = (ASK − sl_price) / SYMBOL_POINT`
**And** if `sl_points < SYMBOL_TRADE_STOPS_LEVEL`: `LogEvent("SKIP | SL distance " + DoubleToString(sl_points,0) + " < broker min " + (string)min_stop)` and return false

**Given** SL distance is valid and lots > 0
**When** `trade.Buy()` is called
**Then** `trade.Buy(lots, _Symbol, 0, sl_price, 0, "S6 entry")` is executed using the global `CTrade trade` instance — `OrderSend()` direct call is absent from the file

**Given** `trade.Buy()` returns false
**When** the failure is detected
**Then** `LogEvent("ERROR | OrderSend failed | Code: " + (string)GetLastError())` is called and `OpenPosition()` returns false — no immediate retry, natural retry on next bar

**Given** an exit condition has been detected
**When** `ClosePosition(string reason)` is called
**Then** `reason` is one of `"RSI_EXIT"`, `"TIMEOUT"`, `"SL_HIT"`, `"MANUAL"` — parameterless overload does not exist in the file
**And** `trade.PositionClose(_Symbol)` is called, and on success `LogEvent("CLOSE | " + reason + " | ...")` records the event

**FRs satisfied:** FR5, FR6, FR9, FR12, FR14
**NFRs satisfied:** NFR2, NFR6, NFR7, NFR12, NFR13
**ARCH satisfied:** ARCH-03, ARCH-09, ARCH-14

---

### Story 2.3: Signal Engine — Entry & Exit Condition Evaluation

As a developer,
I want `CheckEntryConditions()` and `CheckExitConditions()` wired into `OnTick()` in the correct execution order, with `HasOpenPosition()` filtering by MagicNumber,
So that the 3-condition S6 entry gate fires exactly once per D1 close, exits are evaluated before entries, and no multi-EA interference is possible.

**Acceptance Criteria:**

**Given** a new D1 bar has been confirmed and warm-up is complete
**When** `OnTick()` executes the signal/order block
**Then** the sequence is strictly: equityHigh update → `CheckExitConditions()` → `CheckEntryConditions()` → `UpdateReport()` — exits before entries, report always last

**Given** any position check is needed
**When** `HasOpenPosition()` is called
**Then** it iterates `PositionsTotal()` checking `PositionGetInteger(POSITION_MAGIC) == MagicNumber` — raw `PositionsTotal() > 0` does not appear in the file

**Given** `Close[1] > smaBuffer[0]` AND `rsiBuffer[0] < RSI_Entry` AND `HasOpenPosition() == false`
**When** `CheckEntryConditions()` evaluates
**Then** it returns true and `LogEvent("SIGNAL | Entry conditions met — BUY at next open")` is written

**Given** any one of the 3 conditions is false
**When** `CheckEntryConditions()` evaluates
**Then** it returns false and no order is placed

**Given** a position is open and `rsiBuffer[0] > RSI_Exit`
**When** `CheckExitConditions()` evaluates
**Then** `ClosePosition("RSI_EXIT")` is called

**Given** a position is open and days elapsed since open ≥ `MaxDays`
**When** `CheckExitConditions()` evaluates
**Then** `ClosePosition("TIMEOUT")` is called

**Given** another EA has a position open on the same symbol with a different MagicNumber
**When** `HasOpenPosition()` is called
**Then** it returns false — only this EA's positions count

**FRs satisfied:** FR1, FR3, FR7, FR8, FR13
**NFRs satisfied:** NFR1, NFR2, NFR9
**ARCH satisfied:** ARCH-05, ARCH-06

---

### Story 2.4: Performance Reporting — Chart Comment & Final Report

As a developer,
I want `UpdateReport()` updating the chart comment on every bar and `GenerateFinalReport()` called from `OnDeinit()`, both computing WR and MaxDD via full `HistoryDeals` scan,
So that the trader always sees live metrics in the chart area and receives a complete summary when the EA stops.

**Acceptance Criteria:**

**Given** a new D1 bar has been confirmed (immediately after `IsNewBar` gate)
**When** `equityHigh` is updated
**Then** `if(AccountInfoDouble(ACCOUNT_EQUITY) > equityHigh) equityHigh = AccountInfoDouble(ACCOUNT_EQUITY)` runs before any position management in that tick

**Given** `UpdateReport()` is called (last step in `OnTick()`)
**When** it computes Win Rate and Max Drawdown
**Then** it iterates `HistoryDealsTotal()` to count all closed deals filtered by MagicNumber and symbol — no incremental counters, no cached values

**Given** WR and DD have been computed
**When** `Comment()` is updated
**Then** it uses exactly: `Comment(StringFormat("S6 EA | WR: %.1f%% (%d/%d) | MaxDD: %.2f%%", winRate, winTrades, totalTrades, maxDrawdown))` — fixed format, no variation

**Given** `UpdateReport()` is executing
**When** it runs after `CheckEntryConditions()` and `CheckExitConditions()`
**Then** `UpdateReport()` contains no `trade.Buy()`, `trade.PositionClose()`, or order-placement calls — report is read-only

**Given** `OnDeinit()` is called
**When** `GenerateFinalReport()` executes
**Then** `LogEvent()` writes: total trades, win rate, profit factor, max drawdown, average trade duration — all sourced from `HistoryDeals` full scan

**Given** `EnablePhase2 = false` (default)
**When** `UpdateReport()` runs
**Then** only `Comment()` is updated — no file writes, no periodic snapshots

**FRs satisfied:** FR18, FR19, FR21, FR22, FR24
**NFRs satisfied:** NFR3, NFR10
**ARCH satisfied:** ARCH-11, ARCH-12

---

### Story 2.5: System Resilience — MT5 Restart Recovery

As a developer,
I want `OnInit()` to scan all open positions by MagicNumber and recover state before the first signal evaluation,
So that an MT5 restart mid-trade never triggers a duplicate entry, and backtest results are fully deterministic across identical runs.

**Acceptance Criteria:**

**Given** MT5 restarts with the EA's position already open
**When** `OnInit()` executes
**Then** it iterates `PositionsTotal()`, finds the position matching `MagicNumber` and `_Symbol`, and sets state so the first `OnTick()` does not re-enter

**Given** the EA has recovered an existing position in `OnInit()`
**When** the next `OnTick()` fires and `CheckEntryConditions()` evaluates
**Then** `HasOpenPosition()` returns true and no new BUY order is placed — duplicate suppressed

**Given** MT5 restarts with no open position
**When** `OnInit()` scans
**Then** no matching position is found, state is initialized to clean defaults, and normal operation resumes from the next bar

**Given** two identical 5-year backtests are run with the same inputs and same data
**When** I compare their results
**Then** trade count, entry dates, exit dates, and final equity are identical across both runs

**FRs satisfied:** FR34, FR35, FR36
**NFRs satisfied:** NFR5, NFR11
**ARCH satisfied:** ARCH-05

---

## Epic 3: Phase 2 — Live Operations & Extended Reporting

Con `EnablePhase2 = true`, il trader ottiene: report periodico ogni N ore, log CSV di ogni trade (data/entry/SL/exit/P&L/days/reason), linea TP visuale a R/R 1:2.5. Supporta operatività live non presidiata 24/7.

### Story 3.1: Periodic Report Snapshot

As a trader,
I want a performance snapshot logged to the MT5 journal every `ReportInterval` hours when `EnablePhase2` is true,
So that I can check system status at regular intervals without opening MT5 during unattended 24/7 live operation.

**Acceptance Criteria:**

**Given** `EnablePhase2 = true` and `ReportInterval = 8`
**When** `UpdateReport()` runs on a new bar
**Then** it checks `TimeCurrent() - lastReportTime >= ReportInterval * 3600` to determine whether a snapshot is due

**Given** the interval has elapsed
**When** the periodic snapshot fires
**Then** `LogEvent()` writes current WR, total trades, MaxDD, and timestamp — same metrics as `GenerateFinalReport()` but mid-session
**And** `lastReportTime` is updated to `TimeCurrent()`

**Given** `EnablePhase2 = false` (default)
**When** `UpdateReport()` runs
**Then** no periodic report check is performed — the block is wrapped in a flat `if(EnablePhase2) { ... }` with no nesting inside

**Given** MT5 restarts mid-interval with `EnablePhase2 = true`
**When** `OnInit()` runs
**Then** `lastReportTime` is initialized to `TimeCurrent()` so the first snapshot does not fire immediately on restart

**FRs satisfied:** FR20, FR32
**ARCH satisfied:** ARCH-08

---

### Story 3.2: CSV Trade Log

As a trader,
I want each closed trade appended to a UTF-8 comma-delimited CSV file when `EnablePhase2` is true,
So that I have a complete, Excel-compatible trade history for post-session analysis independent of MT5.

**Acceptance Criteria:**

**Given** `EnablePhase2 = true` and `OnInit()` runs
**When** the CSV log is initialized (inside `if(EnablePhase2)`)
**Then** `csvLogHandle = FileOpen("S6_log.csv", FILE_WRITE|FILE_CSV|FILE_SHARE_READ|FILE_ANSI)` opens successfully in the MT5 `Files/` folder — il handle è la variabile globale `int csvLogHandle`, distinta da `int csvReportHandle` usato da Story 3.4 per `S6_report.csv`
**And** if the file is new, a header row is written: `date,entry_price,sl_price,exit_price,pnl,days_open,exit_reason`

**Given** a trade closes via `ClosePosition(reason)`
**When** the CSV row is written (inside flat `if(EnablePhase2)` in `ClosePosition`)
**Then** `FileWrite()` appends one row with fields: `YYYY.MM.DD`, entry price, SL price, exit price, P&L (pips), days open (integer), reason string — comma-delimited

**Given** the CSV file is opened in Microsoft Excel
**When** I import it
**Then** all columns parse correctly, no garbled characters, each field in its own column

**Given** `OnDeinit()` runs
**When** cleanup executes (inside `if(EnablePhase2)`)
**Then** `FileClose()` is called on the CSV handle — file is fully flushed before EA unloads

**Given** `EnablePhase2 = false` (default)
**When** any trade closes
**Then** no CSV file is opened or written — Phase 1 execution path is completely unaffected

**FRs satisfied:** FR23
**NFRs satisfied:** NFR15
**ARCH satisfied:** ARCH-08

---

### Story 3.3: Visual Take Profit Line

As a trader,
I want a horizontal TP line drawn on the chart at R/R 1:2.5 from entry when `EnablePhase2` is true,
So that I can see the target price visually while a position is open — as a reference only, not an exit trigger.

**Acceptance Criteria:**

**Given** `EnablePhase2 = true` and a BUY position has just been opened
**When** `DrawTPLine()` is called (inside flat `if(EnablePhase2)` inside `OpenPosition()`)
**Then** an `OBJ_HLINE` named `"S6_TP_Line"` is drawn at price: `entry_price + 2.5 × (entry_price − sl_price)`

**Given** the TP line is visible on the chart
**When** I inspect `CheckExitConditions()` and `OnTick()` logic
**Then** no code reads the TP line price or uses it to trigger any order — it is purely visual

**Given** a position is closed for any reason
**When** `ClosePosition(reason)` executes
**Then** `ObjectDelete(0, "S6_TP_Line")` is called — line is removed from chart immediately

**Given** two trades fire sequentially
**When** the second `OpenPosition()` calls `DrawTPLine()`
**Then** the old `"S6_TP_Line"` object is deleted before the new one is created — no duplicate objects on chart

**Given** `EnablePhase2 = false` (default)
**When** a position opens
**Then** no chart object is created — `DrawTPLine()` is never called in Phase 1 path

**FRs satisfied:** FR17
**ARCH satisfied:** ARCH-08

---

### Story 3.4: Performance Summary File

As a trader,
I want WR, PF, MaxDD and total trades written to `S6_report.csv` on every periodic snapshot and at final report when `EnablePhase2` is true,
So that I have a timestamped history of strategy performance readable in Excel without opening MT5.

**Acceptance Criteria:**

**Given** `EnablePhase2 = true` and `OnInit()` runs
**When** the report file is initialized (inside `if(EnablePhase2)`)
**Then** `csvReportHandle = FileOpen("S6_report.csv", FILE_WRITE|FILE_CSV|FILE_SHARE_READ|FILE_ANSI)` opens in the MT5 `Files/` folder — il handle è la variabile globale `int csvReportHandle`, distinta da `int csvLogHandle` usato da Story 3.2 per `S6_log.csv`
**And** se il file è nuovo, viene scritta la riga header: `timestamp,total_trades,win_rate,profit_factor,max_drawdown,avg_duration`

**Given** the periodic snapshot interval has elapsed
**When** `GeneratePeriodicReport()` executes (inside `if(EnablePhase2)`)
**Then** `FileWrite()` appends one row: `YYYY.MM.DD HH:MM`, total_trades, win_rate (%), profit_factor, max_drawdown (%), avg_duration (days) — all sourced from `HistoryDeals` full scan

**Given** `OnDeinit()` is called
**When** `GenerateFinalReport()` executes (inside `if(EnablePhase2)`)
**Then** the same row format is appended as final record, then `FileClose()` is called on the report file handle

**Given** the file is opened in Excel across multiple sessions
**When** I view the data
**Then** each snapshot appears as a separate timestamped row — a readable performance timeline

**Given** `EnablePhase2 = false` (default)
**When** any report fires
**Then** `S6_report.csv` is never opened or written — Phase 1 path unaffected

**FRs satisfied:** FR38
**NFRs satisfied:** NFR15

---

### Story 3.5: Push Notification on Trade Close

As a trader,
I want a push notification sent to my MT5 mobile app every time a position closes when `EnablePhase2` is true,
So that I am immediately informed of trade outcomes without checking MT5 manually.

**Acceptance Criteria:**

**Given** `EnablePhase2 = true` and a position closes via `ClosePosition(reason)`
**When** the notification is dispatched (inside flat `if(EnablePhase2)` in `ClosePosition`)
**Then** `SendNotification(msg)` is called with: `"S6 CLOSE | " + reason + " | P&L: " + DoubleToString(pnl,2) + "% | " + (string)daysOpen + "d"`

**Given** `SendNotification()` returns false (MetaQuotes ID not configured or no connection)
**When** the failure is detected
**Then** `LogEvent("ERROR | Push notification failed | Code: " + (string)GetLastError())` is called and execution continues — no crash, no EA stop

**Given** MT5 mobile app is configured with MetaQuotes ID (Tools → Options → Notifications)
**When** a trade closes
**Then** the notification arrives on the mobile device within seconds of `ClosePosition()` executing

**Given** `EnablePhase2 = false` (default)
**When** any trade closes
**Then** `SendNotification()` is never called — Phase 1 path unaffected

**FRs satisfied:** FR39

---

### Story 3.6: Visual Entry & SL Lines

As a trader,
I want linee orizzontali disegnate sul grafico al prezzo di entrata (verde, solid) e al prezzo dello SL (rossa, dashed) quando si apre una posizione con `EnablePhase2 = true`,
So that posso vedere visivamente i livelli chiave della posizione aperta senza aprire il pannello delle posizioni.

**Acceptance Criteria:**

**Given** `EnablePhase2 = true` e una posizione BUY viene aperta
**When** `DrawPositionLines()` è chiamata (dentro `if(EnablePhase2)` in `OpenPosition()`, insieme a `DrawTPLine()` di Story 3.3)
**Then** viene creato `OBJ_HLINE` con nome `"S6_Entry_Line"` al prezzo di entrata — colore `clrGreen`, stile `STYLE_SOLID`
**And** viene creato `OBJ_HLINE` con nome `"S6_SL_Line"` al prezzo dello stop loss — colore `clrRed`, stile `STYLE_DASH`

**Given** le tre linee sono visibili sul grafico (Entry + SL + TP da Story 3.3)
**When** ispeziono la logica di `CheckExitConditions()` e `OnTick()`
**Then** nessuna funzione legge il prezzo di `"S6_Entry_Line"` o `"S6_SL_Line"` per triggerare uscite — sono puramente visuali

**Given** la posizione viene chiusa per qualsiasi motivo (`ClosePosition(reason)`)
**When** il cleanup visuale esegue (dentro `if(EnablePhase2)`)
**Then** `ObjectDelete(0, "S6_Entry_Line")` e `ObjectDelete(0, "S6_SL_Line")` vengono chiamate insieme a `ObjectDelete(0, "S6_TP_Line")` di Story 3.3 — nessun oggetto fantasma sul grafico

**Given** `ObjectCreate()` fallisce per uno dei due oggetti
**When** l'errore viene rilevato
**Then** `LogEvent("ERROR | DrawPositionLines failed")` è chiamato e l'esecuzione continua — nessun crash

**Given** `EnablePhase2 = false` (default)
**When** una posizione apre
**Then** `DrawPositionLines()` non viene mai chiamata — nessun oggetto grafico creato

**FRs satisfied:** FR40
**ARCH satisfied:** ARCH-08
