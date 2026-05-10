---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish, step-12-complete]
completedAt: '2026-05-09'
releaseMode: phased
inputDocuments: [strategy-S6-from-conversation]
workflowType: 'prd'
classification:
  projectType: developer_tool
  domain: fintech
  complexity: high
  projectContext: greenfield
---

# Product Requirements Document — S6 Swing Mean Reversion Daily EA

**Author:** Primo  
**Date:** 2026-05-09

---

## Executive Summary

S6 — Swing Mean Reversion Daily is a fully automated Expert Advisor (EA) for MetaTrader 5 that executes the S6 systematic trading strategy on equity indices (S&P500/US500) without manual intervention. The EA enforces strict rule-based entry and exit logic, calculates position size dynamically from account equity, supports full historical backtesting via MT5's native Strategy Tester, and operates continuously as a live trading system. A configurable reporting engine delivers periodic status updates at user-defined intervals and a final summary report at session end.

**Target user:** A single trader migrating from manual to automated execution of a validated mean reversion strategy.

**Problem solved:** Manual execution of rule-based strategies introduces latency, emotional override risk, and operational fatigue. The EA removes all three — signals fire at the daily close, orders execute at the next open, exits trigger on condition, every event is logged without human attention.

**What makes it special:** S6 EA is not a generic backtest wrapper — it is a production-grade automation with a complete operational lifecycle: **backtest validation → live deployment → automated monitoring**. The reporting subsystem makes 24/7 unattended operation viable: periodic snapshots prevent information blind spots; a final report provides end-of-session accountability. Core differentiator: **discipline enforcement at the execution layer** — the three-condition entry gate (Price > SMA200, RSI14 < 32, no open position) is evaluated mechanically at every daily close with no exceptions, no overrides, no emotional interference.

**Classification:** Developer tool (MQL5 EA plugin for MT5) · Domain: Fintech — algorithmic trading, equity indices · Complexity: High · Greenfield · Deployed on MetaTrader 5 (Windows) and MT5 Strategy Tester.

---

## Success Criteria

### User Success

- **Backtest validation gate:** Profit Factor ≥ 1.5 over a minimum 1-year historical dataset; maximum drawdown < 2% over the same period. Both conditions met → EA cleared for live deployment.
- **Live trading performance:** Win rate ≥ 60% on a rolling basis; maximum drawdown < 10% at any point. Breach of the drawdown threshold triggers a manual review decision.
- **Operational transparency:** Two key metrics always visible without opening MT5 charts — current win rate and current max drawdown.

### Business Success

Personal-use context. Success is defined as:
- Live deployment achieved within one development cycle (backtest → live)
- Live operation sustained for 3+ months with metrics within defined thresholds
- Zero unintended position openings or closings due to EA bugs

### Technical Success

- EA compiles without errors in MetaEditor (MQL5)
- Backtest results are deterministic and reproducible across identical runs
- Entry order fires at next daily open after signal bar closes, not before
- Stop Loss is set immediately on position open, not deferred
- Position sizing: `Risk = AccountBalance × 0.01 / (SL_points × TickValue)` — exact, never exceeded
- Report outputs: current win rate + current max drawdown (minimum required metrics)

### Measurable Outcomes

| Metric | Backtest Gate | Live Gate |
|--------|--------------|-----------|
| Profit Factor | ≥ 1.5 | tracked |
| Max Drawdown | < 2% | < 10% |
| Win Rate | tracked | ≥ 60% |
| Report interval | n/a | user-defined |

---

## User Journeys

### Journey 1 — Setup & Backtest (Developer/Analyst)

**Persona:** Primo, systematic trader. S6 is defined on paper; now it must be validated on historical data before risking real capital.

**Opening Scene:** Primo opens MetaEditor, pastes the `.mq5` file, clicks Compile. Zero errors. Opens MT5, drags the EA onto the US500 Daily chart. Sets parameters: `RiskPercent = 1.0`, `RSI_Period = 14`, `RSI_Entry = 32`, `RSI_Exit = 50`, `SMA_Period = 200`, `SL_Percent = 2.0`, `MaxDays = 15`.

**Rising Action:** Launches the Strategy Tester on 1 year of data (2024–2025). The tester runs candle by candle. Primo watches the equity curve grow; BUY/SELL markers appear exactly where the logic dictates.

**Climax:** Final report appears. Profit Factor: 1.73. Max Drawdown: 1.4%. Win Rate: 62%. All three gates cleared (PF ≥ 1.5, DD < 2%).

**Resolution:** Primo saves the report. The EA is validated. The risk of deploying something untested is eliminated. Ready for live deployment.

*Requirements revealed: clean MQL5 compilation, configurable input parameters, Strategy Tester compatibility, backtest report with PF/DD/WR.*

---

### Journey 2 — Live Deployment & First Trade (Operator)

**Opening Scene:** Primo opens a demo (or real) account on MT5. Drags the EA onto the US500 Daily chart in live mode. Sets `ReportInterval = 8` (every 8 hours). Enables "Allow Algo Trading". Clicks OK.

**Rising Action:** The EA starts running. End of day — candle closes. EA evaluates 3 conditions: `Close > SMA200`? Yes. `RSI14 < 32`? No. No trade. Next day, same. Third day: `RSI14 = 29.4`. Conditions met. EA places BUY order at next candle open. SL set immediately.

**Climax:** Trade is open. Primo did nothing. He wasn't even awake. The system executed the rule with surgical precision.

**Resolution:** 7 days later, `RSI > 50`. Position closed automatically. +2.8%. The system worked exactly as designed.

*Requirements revealed: order execution on next candle after signal, immediate SL, ReportInterval parameter, demo/real account compatibility.*

---

### Journey 3 — Reading Periodic Report (Passive User)

**Opening Scene:** 08:00. Primo wakes up, checks his phone. He hasn't looked at MT5 since midnight.

**Rising Action:** He checks the EA log. Sees: `Win Rate: 66.7% (4/6 trades) | Max Drawdown: 0.8% | Last trade: closed yesterday +1.9%`. 30 seconds. All good.

**Climax:** Drawdown is 0.8% — well below the 10% threshold. Win rate above 60%. No action required.

**Resolution:** Primo puts his phone down and has breakfast. The system is working for him.

*Requirements revealed: report readable without opening MT5, essential metrics in plain text (WR + DD), timestamp of last update, configurable interval.*

---

### Journey 4 — Anomaly / Debug (Troubleshooter)

**Opening Scene:** Primo checks the 16:00 report and sees `Max Drawdown: 3.2%`. Above his mental alert threshold — not yet at 10%, but unusual.

**Rising Action:** Opens MT5. Checks EA journal. Finds: trade open 12 days ago, still running, RSI never returned above 50. The EA will hold it open 3 more days (15-day timeout).

**Climax:** Primo decides not to intervene — the 15-day timeout is a defined rule. The position will close automatically in 3 days with a small loss. Not a bug, it's the strategy.

**Resolution:** Position closed on day 15. Final report updated. The 3.2% drawdown was temporary. The system handled the anomaly according to the rules.

*Requirements revealed: detailed log per trade (open date, days elapsed, current P&L), exit reason tracking, final report with full trade history.*

---

### Journey Requirements Summary

| Capability | Revealed by |
|-----------|-------------|
| Configurable input parameters via MT5 | Journey 1 |
| Strategy Tester compatibility | Journey 1 |
| Order execution on next candle after signal | Journey 2 |
| Immediate SL on position open | Journey 2 |
| Periodic report (configurable interval) | Journey 2, 3 |
| Report metrics: WR + max DD | Journey 3 |
| Detailed log per trade | Journey 4 |
| Final report with full trade history | Journey 4 |
| Exit reason tracking | Journey 4 |

---

## Domain-Specific Requirements

### Financial Calculation Accuracy

- Position sizing formula: `Lots = (AccountBalance × RiskPercent / 100) / (SL_points × TickValue)`
- Rounding: `MathFloor` enforced — never exceed intended risk amount
- Lot size validated against broker constraints: if calculated lots < `SYMBOL_VOLUME_MIN`, skip and log trade
- Lot size rounded to `SYMBOL_VOLUME_STEP` precision
- All financial comparisons use broker tick precision, not raw float equality

### MT5 Platform Constraints

- Strategy logic evaluated only on confirmed daily candle close — not on every tick
- Bar-change detection via `iTime(symbol, PERIOD_D1, 0) != lastBarTime` prevents multiple evaluations per candle
- "Open Prices Only" mode in Strategy Tester is sufficient and preferred for a daily strategy
- EA re-reads open positions on `OnInit()` to recover state after MT5 restart

### Broker Compatibility

- EA must work with ECN, STP, and market-maker brokers without broker-specific code
- Slippage on market orders at daily open is expected and acceptable
- EA checks `IsTradeAllowed()` before placing any order
- SL placed at minimum distance allowed by broker (`SYMBOL_TRADE_STOPS_LEVEL`)

### Risk Enforcement

- Maximum 1 open position at any time — enforced via `PositionsTotal()` check before every entry
- No averaging, no martingale, no pyramid — one entry per signal, one SL, one exit

### Data Integrity

- Minimum 1 full calendar year of daily OHLCV data required for backtest
- Warm-up guard: signals suppressed until `Bars ≥ SMA_Period + RSI_Period + 1`

---

## Developer Tool Requirements

### Artifact & Deployment

| Component | Detail |
|-----------|--------|
| Source file | `S6_EA.mq5` |
| Compiled artifact | `S6_EA.ex5` |
| Compilation tool | MetaEditor (bundled with MT5) |
| Host platform | MetaTrader 5 (Windows) |
| Backtest engine | MT5 Strategy Tester (native) |
| Installation | Copy `.ex5` to `MT5_DataFolder/MQL5/Experts/` |

No external dependencies, no package manager, no DLL imports. EA updates replace the `.ex5` file.

### Input Parameter Surface

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `RiskPercent` | double | 1.0 | % of account balance risked per trade |
| `SMA_Period` | int | 200 | SMA period for trend filter |
| `RSI_Period` | int | 14 | RSI period |
| `RSI_Entry` | int | 32 | RSI entry threshold |
| `RSI_Exit` | int | 50 | RSI exit threshold |
| `SL_Percent` | double | 2.0 | Stop Loss as % from entry |
| `MaxDays` | int | 15 | Maximum holding period in days |
| `ReportInterval` | int | 8 | Periodic report interval in hours |
| `MagicNumber` | int | 20260509 | Unique EA identifier for order management |

### Backtest Configuration

- Mode: Open Prices Only (sufficient for daily strategy, deterministic)
- Symbol: US500 or SP500 (broker-dependent)
- Timeframe: D1
- Minimum period: 1 year; recommended 3–5 years for statistical significance

---

## Product Scope & Phased Development

### MVP Strategy

Problem-solving MVP: an EA that runs S6 in backtest with verifiable results and an essential report. No live trading, no advanced reporting. Goal: validate the strategy before risking real capital. Single developer (Primo), autonomous on MQL5 + MT5.

### Phase 1 — MVP: Backtest Engine

**Supports:** Journey 1

**Capabilities:**
- SMA(200) + RSI(14) indicator calculation
- Entry gate: Price > SMA200 AND RSI14 < RSI_Entry AND no open position
- BUY order at open of next daily candle after signal
- Stop Loss at -SL_Percent% from entry, set immediately on open
- Exit: RSI > RSI_Exit, SL hit, or MaxDays elapsed
- Position sizing with lot validation (min/step broker constraints)
- Warm-up guard and bar-change detection
- MT5 restart recovery via MagicNumber scan
- All inputs configurable via MT5 dialog
- Basic report: Win Rate + Max Drawdown via chart comment + journal

**Success gate:** PF ≥ 1.5, max DD < 2% on 1-year dataset

### Phase 2 — Growth: Live Trading + Reporting

**Supports:** Journeys 2, 3, 4

**Capabilities:**
- Live 24/7 trading on demo or real account
- Periodic report engine (`ReportInterval` hours, user-configurable)
- Final report on EA stop: trade count, WR, PF, max DD, avg duration
- Visual TP line on chart at R/R 1:2.5 (display only — not an exit trigger)
- Trade log to CSV (`S6_log.csv`): date, entry, SL, exit, P&L, days, exit reason
- Performance summary to CSV (`S6_report.csv`): timestamped WR, PF, MaxDD, total trades on every snapshot and final report
- Push notification to MT5 mobile app on every position close (exit reason + P&L)
- Visual entry price line (green) and SL line (red dashed) drawn on chart when position is open

### Phase 3 — Vision: Expansion

- Multi-instrument support (S6 on multiple indices simultaneously)
- Framework reusability for next strategies (S7, S8...)
- Push notification on trade open (close notification moved to Phase 2 — FR39)

### Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Multiple signals per candle (timing bug) | Bar-detection pattern; verified in backtest "Open Prices Only" mode |
| Broker lot constraints | Lot validation on every order; skip + log if below minimum |
| Backtest data quality | Use broker native historical data; minimum 1 year required |
| MT5 restart mid-trade | `OnInit()` scans open positions by MagicNumber before first evaluation |
| Single-developer resource | Each phase independently shippable and testable |

---

## Functional Requirements

### Signal Detection

- **FR1:** The EA evaluates entry conditions (Price > SMA200 AND RSI14 < entry threshold AND no open position) exactly once per confirmed daily candle close
- **FR2:** The EA detects a new daily bar and triggers signal evaluation once per bar only
- **FR3:** The EA detects when RSI(14) crosses above the exit threshold while a position is open
- **FR4:** The EA suppresses signal evaluation during the indicator warm-up period

### Trade Execution

- **FR5:** The EA places a BUY market order at the open of the next daily candle following a signal bar
- **FR6:** The EA attaches a Stop Loss to the position at the exact moment the order is executed
- **FR7:** The EA closes a position when RSI exceeds the configured exit threshold
- **FR8:** The EA closes a position when the maximum holding period (MaxDays) is reached
- **FR9:** The EA records the reason for each position closure (RSI exit / SL / timeout / manual)

### Risk Management

- **FR10:** The EA calculates position size in lots from account balance, risk percentage, SL distance, and tick value
- **FR11:** The EA validates calculated lot size against broker minimum, maximum, and step constraints
- **FR12:** The EA skips and logs a trade when the calculated lot size falls below the broker minimum
- **FR13:** The EA enforces a maximum of one open position at any time
- **FR14:** The EA verifies trading is permitted before placing any order

### Indicator Calculation

- **FR15:** The EA computes SMA with a configurable period on the Daily timeframe for the current symbol
- **FR16:** The EA computes RSI with a configurable period on the Daily timeframe for the current symbol
- **FR17:** The EA displays a visual Take Profit line on the chart at R/R 1:2.5 from entry *(Phase 2)*

### Reporting

- **FR18:** The EA displays current Win Rate in the chart comment area
- **FR19:** The EA displays current Max Drawdown in the chart comment area
- **FR20:** The EA generates a periodic performance snapshot at a user-defined time interval *(Phase 2)*
- **FR21:** The EA generates a final summary report when deactivated or manually stopped
- **FR22:** The final report includes: total trades, win rate, profit factor, max drawdown, average trade duration
- **FR23:** The EA logs each trade to CSV: date, entry price, SL, exit price, P&L, days open, exit reason *(Phase 2)*
- **FR24:** The EA writes diagnostic events to the MT5 journal log (signal detected, order placed, position closed, report generated)

### Configuration

- **FR25:** The user configures risk percentage per trade
- **FR26:** The user configures SMA period
- **FR27:** The user configures RSI period
- **FR28:** The user configures RSI entry threshold
- **FR29:** The user configures RSI exit threshold
- **FR30:** The user configures Stop Loss distance as a percentage
- **FR31:** The user configures maximum holding days
- **FR32:** The user configures periodic report interval in hours *(Phase 2)*
- **FR33:** The user configures a unique Magic Number for EA order identification

### System Resilience

- **FR34:** The EA recovers open position state after MT5 restart by scanning positions with its Magic Number
- **FR35:** The EA suppresses duplicate trade entries when a position already exists after restart
- **FR36:** The EA executes correctly in MT5 Strategy Tester "Open Prices Only" mode
- **FR37:** The EA operates without external DLL dependencies or files required at runtime
- **FR38:** The EA writes a performance summary row (timestamp, total trades, win rate, profit factor, max drawdown, average duration) to `S6_report.csv` on every periodic snapshot and at final report *(Phase 2)*
- **FR39:** The EA sends a push notification to the MT5 mobile app on every position close, containing exit reason and P&L; failures are logged without stopping the EA *(Phase 2)*
- **FR40:** The EA draws horizontal lines on the chart at entry price (green, solid) and SL price (red, dashed) when a position opens; both lines are removed when the position closes *(Phase 2)*

---

## Non-Functional Requirements

### Performance

- **NFR1:** Signal evaluation completes within the same tick that triggers bar-change detection — no deferred processing
- **NFR2:** Order placement (entry + SL) completes within a single `OnTick()` call on the first tick of the new daily candle
- **NFR3:** Report generation (chart comment update) does not block order execution
- **NFR4:** Strategy Tester completes a 5-year D1 backtest run in under 60 seconds on a standard desktop (Intel i5 / 8 GB RAM); EA `OnTick()` processing time does not exceed 50 ms per bar

### Reliability

- **NFR5:** After MT5 restart, the EA identifies any open position within the first `OnInit()` call, before the next signal evaluation
- **NFR6:** Failed trade orders are logged and retried on the next bar — no silent failures
- **NFR7:** All error conditions (order failure, invalid lot size, insufficient bars) are logged to the MT5 journal with sufficient detail for diagnosis

### Correctness

- **NFR8:** Position sizing never results in a risk amount exceeding `AccountBalance × RiskPercent / 100` — `MathFloor` rounding enforced
- **NFR9:** SMA and RSI values used for signal evaluation are from the closed bar (index 1), never the forming bar (index 0)
- **NFR10:** Win Rate and Max Drawdown are recalculated from actual closed trade history on every report update — no approximations
- **NFR11:** Backtest results are deterministic: identical inputs on identical data produce identical outputs across runs

### Integration

- **NFR12:** EA functions correctly on ECN, STP, and market-maker broker accounts without broker-specific code
- **NFR13:** EA validates that the calculated SL distance (in points) ≥ `SYMBOL_TRADE_STOPS_LEVEL` before placing any order; if the constraint is not met, the order is skipped and the event is logged (FR12 pattern)
- **NFR14:** EA uses only standard MQL5 library functions — no DLL imports, no external services, no internet calls
- **NFR15:** CSV log output (Phase 2) uses UTF-8 encoding, comma-delimited, compatible with Excel and standard spreadsheet tools
