---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-04-final-validation]
status: 'complete'
completedAt: '2026-05-05'
inputDocuments: [_bmad-output/planning-artifacts/prd.md, _bmad-output/planning-artifacts/architecture.md]
project_name: 'DT_PRIMO_PROVA'
user_name: 'Primo'
date: '2026-05-05'
---

# DT_PRIMO_PROVA - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for DT_PRIMO_PROVA, decomposing the requirements from the PRD and Architecture into implementable stories for the MQL5 Expert Advisor.

## Requirements Inventory

### Functional Requirements

FR1: The system detects two consecutive same-color M15 candles (both bullish or both bearish) on EUR/USD.
FR2: The system evaluates each candle body in pips (absolute value of close minus open).
FR3: The system generates a signal only when both candle bodies exceed the configured threshold.
FR4: The system performs detection exclusively on closed M15 candles.
FR5: The system does not generate signals on candles still in formation.
FR6: The trader receives a visual signal on the chart at pattern close.
FR7: The trader receives an email notification at pattern close.
FR8: The email contains: pair, timeframe, pattern type (bullish/bearish), body size in pips, timestamp with broker timezone.
FR9: Email is sent within 5 seconds of candle close.
FR10: On SMTP failure, the system continues operating and records the error in the CSV log.
FR11: The system writes every signal to a CSV file.
FR12: CSV fields: date, time (broker timezone), pair, timeframe, pattern type, candle 1 body (pips), candle 2 body (pips), configured threshold.
FR13: The CSV file is readable by external applications (e.g. Excel). Encoding: UTF-8.
FR14: The trader configures the pip threshold before startup.
FR15: The trader modifies the pip threshold at runtime without restart; the new value applies from the next candle.
FR16: The trader configures the email recipient address.
FR17: The trader configures the CSV file path (filename).
FR18: Default threshold: 20 pips.
FR19: Default email recipient: primo.brandi@gmail.com.
FR20: The system displays its operational state (active / stopped) on the chart.
FR21: The system updates the status indicator when it stops unexpectedly.
FR22: The system remains operational after a runtime threshold change.
FR23: The trader starts the system in test mode using pre-downloaded offline M15 historical data.
FR24: Test mode requires no internet connection during replay.
FR25: The trader starts the system in live mode with real-time broker feed. (Phase 2)
FR26: Live mode requires an active broker connection. (Phase 2)

### NonFunctional Requirements

NFR1: Pattern detected within the close of the current M15 candle — no delay to next tick.
NFR2: Visual alert appears on chart within 1 second of candle close.
NFR3: Email sent within 5 seconds of candle close.
NFR4: CSV row written within 5 seconds of candle close.
NFR5: Tool introduces no perceptible lag to the trading platform UI.
NFR6: SMTP credentials stored securely — not in plaintext in source code.
NFR7: CSV signal file accessible only to the local Windows user.
NFR8: Tool connects to the configured SMTP server and handles connection timeouts without crashing.
NFR9: On CSV write error (full disk, permission denied), the tool continues operating and displays a visual warning.
NFR10: Tool operates with any broker providing M15 EUR/USD data via the configured trading platform.

### Additional Requirements

- **Starter template (Architecture):** MetaEditor EA Scaffold — `File → New → Expert Advisor` in MetaEditor (MT5 built-in IDE). This is Epic 1 Story 1.
- **Single .mq5 file structure:** Canonical section order: header comment → `#property` declarations → `input` parameters → global variables (`g_*`) → `OnInit()` → `OnDeinit()` → `OnTick()` → helper functions (in call order).
- **Bar-close detection pattern:** `iTime()` comparison in `OnTick()` — evaluate bars `[1]` (last closed) and `[2]` (prior closed); never bar `[0]` (forming).
- **BodyInPips() helper:** `MathAbs(iClose - iOpen) / _Point / 10.0` for 5-decimal pairs (EUR/USD).
- **Error isolation:** Continue-and-log for SMTP and CSV failures; `INIT_FAILED` only for critical `OnInit()` errors (e.g. iTime returns 0).
- **Fan-out order (fixed):** 1) `UpdateStatusLabel()` → 2) `ObjectCreate()` arrow → 3) `SendAlertEmail()` → 4) `WriteSignalToCsv()`.
- **CSV encoding:** `FileOpen()` with `FILE_CSV | FILE_UNICODE` flags; CSV file handle opened in `OnInit()`, closed in `OnDeinit()`.
- **Chart objects:** `OBJ_ARROW_UP`/`OBJ_ARROW_DOWN` for signals; `OBJ_LABEL` (CORNER_LEFT_UPPER) for status indicator. All object names prefixed `"DT_"`.
- **Naming conventions:** `g_` prefix for global variables; `PascalCase` for functions and input parameters.
- **Bilingual comments:** Every non-trivial line: `// English comment / Commento italiano`.
- **CSV format:** Date `YYYY.MM.DD`, time `HH:MM` (broker TZ), pattern `BULLISH`/`BEARISH`, pip values to 1 decimal place.

### UX Design Requirements

N/A — This is an MQL5 Expert Advisor. The "UI" is the MetaTrader 5 chart. Visual elements are defined in the Architecture document (OBJ_ARROW, OBJ_LABEL) and fully specified in the Additional Requirements above. No separate UX design document exists or is needed.

### FR Coverage Map

FR1:  Epic 2 — Detect two consecutive same-color M15 candles
FR2:  Epic 2 — Evaluate candle body in pips
FR3:  Epic 2 — Signal only when both bodies exceed threshold
FR4:  Epic 2 — Detection on closed candles only (bar [1] and [2])
FR5:  Epic 2 — No signal on forming candle (bar [0])
FR6:  Epic 4 — Visual arrow signal on chart
FR7:  Epic 4 — Email notification at pattern close
FR8:  Epic 4 — Email content (pair, TF, pattern type, pips, timestamp)
FR9:  Epic 4 — Email sent within 5 seconds of bar close
FR10: Epic 4 — SMTP failure → CSV error log, EA continues
FR11: Epic 3 — Write every signal to CSV
FR12: Epic 3 — CSV fields: date, time, pair, TF, type, body1, body2, threshold
FR13: Epic 3 — CSV UTF-8, readable by Excel
FR14: Epic 1 — Configure pip threshold before startup
FR15: Epic 1 — Modify threshold at runtime without restart
FR16: Epic 1 — Configure email recipient address
FR17: Epic 1 — Configure CSV filename
FR18: Epic 1 — Default threshold 20 pips
FR19: Epic 1 — Default email recipient primo.brandi@gmail.com
FR20: Epic 1 — Status indicator on chart (active/stopped)
FR21: Epic 1 — Update status indicator on unexpected stop
FR22: Epic 1 — EA operational after runtime threshold change
FR23: Epic 1 — Test mode with offline historical data
FR24: Epic 1 — Test mode requires no internet connection
FR25: Phase 2 — Deferred (live mode)
FR26: Phase 2 — Deferred (live mode broker connection)

## Epic List

### Epic 1: EA Foundation, Configuration & Status
The trader can deploy a configured EA in MT5 Strategy Tester, see an operational status indicator on the chart, adjust the pip threshold at runtime without restarting, and verify the EA runs correctly on offline historical data.
**FRs covered:** FR14, FR15, FR16, FR17, FR18, FR19, FR20, FR21, FR22, FR23, FR24

### Epic 2: Pattern Detection Engine
The EA correctly detects two consecutive same-color M15 candles whose bodies both exceed the configured threshold, triggering only at bar close — never on the forming candle.
**FRs covered:** FR1, FR2, FR3, FR4, FR5

### Epic 3: Signal Log (CSV)
Every detected pattern is permanently recorded in a UTF-8 CSV file the trader can open in Excel, with full broker-timezone timestamp and pip body details.
**FRs covered:** FR11, FR12, FR13

### Epic 4: Visual & Email Alerts
The trader receives an arrow signal on the chart and an email notification within 5 seconds of every pattern close; SMTP failures are logged to CSV without stopping the EA.
**FRs covered:** FR6, FR7, FR8, FR9, FR10

---

## Epic 1: EA Foundation, Configuration & Status

The trader can deploy a configured EA in MT5 Strategy Tester, see an operational status indicator on the chart, adjust the pip threshold at runtime without restarting, and verify the EA runs correctly on offline historical data.

### Story 1.1: EA Scaffold with Input Parameters

As a trader,
I want a compilable EA file with all configurable parameters declared and stub event handlers,
So that I have a working foundation I can load in MetaTrader 5 Strategy Tester without errors.

**Acceptance Criteria:**

**Given** MetaEditor is open
**When** I create `src/DT_SignalEA.mq5` using `File → New → Expert Advisor` and implement the canonical section order (header comment → `#property` declarations → `input` parameters → global variables → `OnInit()` → `OnDeinit()` → `OnTick()` → helper function stubs)
**Then** the file compiles without errors or warnings in MetaEditor (F7)

**Given** the EA is compiled and copied to `MQL5\Experts\DT_Signal\`
**When** I attach it to a chart or load it in Strategy Tester
**Then** the EA loads successfully and `OnInit()` returns `INIT_SUCCEEDED`

**Given** the EA is loaded
**When** I open the EA properties panel (F7)
**Then** I see all input parameters with correct defaults:
- `PipThreshold` = 20.0
- `EmailRecipient` = "primo.brandi@gmail.com"
- `CsvFileName` = "dt_signals.csv"

**Given** the EA file
**When** I inspect the source
**Then** all global variables use the `g_` prefix, all input parameters use `PascalCase`, and every non-trivial line has a bilingual comment `// English / Italiano`

**FRs satisfied:** FR14, FR16, FR17, FR18, FR19, FR23, FR24
**NFRs satisfied:** NFR5 (no lag — stub handlers return immediately)

---

### Story 1.2: Status Indicator (Active / Stopped)

As a trader,
I want a persistent label on the chart that shows whether the EA is active or stopped,
So that I can confirm at a glance that the tool is running without checking the Experts log.

**Acceptance Criteria:**

**Given** the EA is loaded in Strategy Tester or on a live chart
**When** `OnInit()` completes successfully
**Then** a chart label named `"DT_StatusLabel"` appears at `CORNER_LEFT_UPPER` with text `"DT Signal EA — ACTIVE"` in green

**Given** the EA is running
**When** I remove the EA from the chart (triggering `OnDeinit()`)
**Then** the label text changes to `"DT Signal EA — STOPPED"` in red before the EA unloads

**Given** the EA encounters a critical initialization error (e.g. `iTime()` returns 0)
**When** `OnInit()` returns `INIT_FAILED`
**Then** the label shows `"DT Signal EA — ERROR"` and the EA does not proceed

**Given** the EA is running
**When** I switch the chart to a different timeframe and switch back
**Then** the `"DT_StatusLabel"` label is still visible and correctly reads `"DT Signal EA — ACTIVE"`

**Given** the EA is unloaded
**When** I inspect the chart objects
**Then** `"DT_StatusLabel"` has been deleted from the chart (no ghost objects)

**FRs satisfied:** FR20, FR21
**NFRs satisfied:** NFR2 (label update is synchronous, < 1s)

---

### Story 1.3: Hot-Reload Configuration Verification

As a trader,
I want to change the pip threshold in the EA properties panel while the EA is running and have the new value take effect on the next candle without restarting,
So that I can tune the sensitivity of the signal without interrupting the session.

**Acceptance Criteria:**

**Given** the EA is running in Strategy Tester with `PipThreshold = 20.0`
**When** I open the EA properties (F7), change `PipThreshold` to `10.0`, and click OK
**Then** the EA continues running without restarting (status label remains "ACTIVE")
**And** on the next `OnTick()` call, the EA reads `PipThreshold = 10.0` (verifiable via `Print()` in MetaEditor log)

**Given** the EA is running
**When** I change `EmailRecipient` in the properties panel and click OK
**Then** the EA continues running and the new recipient value is used from the next event

**Given** the EA is running
**When** I change `CsvFileName` in the properties panel and click OK
**Then** the EA continues running without crash or file handle error

**Given** the EA processes a new bar after a threshold change
**When** the bar-close event fires
**Then** the new `PipThreshold` value is used in all comparisons — not the previous value

**FRs satisfied:** FR15, FR22
**NFRs satisfied:** NFR5 (no restart = no lag)

---

## Epic 2: Pattern Detection Engine

The EA correctly detects two consecutive same-color M15 candles whose bodies both exceed the configured threshold, triggering only at bar close — never on the forming candle.

### Story 2.1: Bar-Close Detection (iTime Guard)

As a trader,
I want the EA to react exclusively at M15 bar close and ignore all intermediate ticks,
So that pattern evaluation always uses complete, closed candle data and never fires on a forming bar.

**Acceptance Criteria:**

**Given** the EA is running in Strategy Tester on M15 EUR/USD
**When** a new M15 bar opens (first tick of the new bar)
**Then** `iTime(Symbol(), PERIOD_M15, 0)` differs from `g_lastBarTime`, the EA enters the detection branch, and `g_lastBarTime` is updated to the new bar time

**Given** the EA has already processed the first tick of a new bar
**When** subsequent ticks arrive within the same M15 bar
**Then** `iTime(Symbol(), PERIOD_M15, 0)` equals `g_lastBarTime` and the detection branch is NOT entered

**Given** `OnInit()` has just completed
**When** the first `OnTick()` fires
**Then** `g_lastBarTime` is initialized to `iTime(Symbol(), PERIOD_M15, 0)` so no spurious detection fires on startup

**Given** the EA runs through multiple M15 bars in Strategy Tester
**When** I inspect the MetaEditor Experts log
**Then** a bar-close event log entry appears exactly once per M15 bar — no duplicates, no missed bars

**FRs satisfied:** FR4, FR5
**NFRs satisfied:** NFR1 (detection on closed candle, first tick of new bar), NFR5

---

### Story 2.2: BodyInPips Helper & DetectPattern Function

As a trader,
I want the EA to identify when the last two closed M15 candles are the same color and both have a body exceeding my configured pip threshold,
So that I receive a signal only on the exact two-candle pattern I care about — no false positives, no misses.

**Acceptance Criteria:**

**Given** a closed M15 candle at bar index `n`
**When** `BodyInPips(n)` is called
**Then** it returns `MathAbs(iClose(Symbol(), PERIOD_M15, n) - iOpen(Symbol(), PERIOD_M15, n)) / _Point / 10.0` rounded to 1 decimal place
**And** the result is always ≥ 0 (never negative)

**Given** bars `[1]` and `[2]` are both bullish (close > open) and both bodies ≥ `PipThreshold`
**When** `DetectPattern()` is called after the bar-close event
**Then** it returns `BULLISH`

**Given** bars `[1]` and `[2]` are both bearish (close < open) and both bodies ≥ `PipThreshold`
**When** `DetectPattern()` is called
**Then** it returns `BEARISH`

**Given** bars `[1]` and `[2]` are opposite colors (one bullish, one bearish)
**When** `DetectPattern()` is called
**Then** it returns `NONE`

**Given** bars `[1]` and `[2]` are same color but at least one body < `PipThreshold`
**When** `DetectPattern()` is called
**Then** it returns `NONE`

**Given** the forming bar (index `[0]`) has not closed yet
**When** `DetectPattern()` is called
**Then** bar `[0]` is never read — only `[1]` and `[2]` are accessed

**Given** `PipThreshold` is changed via the EA panel between two bar-close events
**When** the next bar closes and `DetectPattern()` runs
**Then** it uses the new `PipThreshold` value

**FRs satisfied:** FR1, FR2, FR3, FR4, FR5
**NFRs satisfied:** NFR1, NFR5, NFR10 (uses `Symbol()` — broker-agnostic)

---

## Epic 3: Signal Log (CSV)

Every detected pattern is permanently recorded in a UTF-8 CSV file the trader can open in Excel, with full broker-timezone timestamp and pip body details.

### Story 3.1: CSV File Setup and Signal Writing

As a trader,
I want every signal permanently saved to a CSV file I can open in Excel, with all the details of each pattern including the exact broker timestamp and pip sizes,
So that I have a complete traceable record of every signal the EA generated, independent of whether the email was delivered.

**Acceptance Criteria:**

**Given** the EA initializes (`OnInit()` runs)
**When** `FileOpen(CsvFileName, FILE_CSV|FILE_WRITE|FILE_UNICODE|FILE_SHARE_READ)` is called
**Then** the file handle `g_csvHandle` is assigned a valid value (≥ 0) and the file is open in append mode in `MQL5\Files\`

**Given** the CSV file is newly created (did not exist before)
**When** `OnInit()` opens the file
**Then** a header row is written: `date,time,pair,timeframe,pattern,body1_pips,body2_pips,threshold`

**Given** the CSV file already exists from a previous session
**When** `OnInit()` opens the file
**Then** no header row is written — new signal rows are appended after existing content

**Given** a pattern is detected and the fan-out sequence reaches `WriteSignalToCsv()`
**When** `FileWrite()` is called
**Then** a row is written with all FR12 fields in this exact format:
`2026.05.05,14:30,EURUSD,M15,BULLISH,25.3,22.1,20.0`
- Date: `YYYY.MM.DD` (broker timezone)
- Time: `HH:MM` (broker timezone)
- Pair: `EURUSD`
- Timeframe: `M15`
- Pattern: `BULLISH` or `BEARISH` (uppercase)
- body1_pips: body of bar `[1]` to 1 decimal place
- body2_pips: body of bar `[2]` to 1 decimal place
- threshold: current `PipThreshold` to 1 decimal place

**Given** a CSV row is written
**When** I open the file in Microsoft Excel
**Then** each field appears in a separate column with correct UTF-8 encoding and no garbled characters

**Given** `FileWrite()` returns `false` (disk full, permission denied)
**When** the write error is detected
**Then** the chart status label updates to show a warning (e.g. `"DT Signal EA — CSV ERROR"`)
**And** the EA continues running — no crash, no stop
**And** subsequent bar-close events still attempt to write (error is not permanent)

**Given** the EA is removed from the chart or Strategy Tester ends (`OnDeinit()` runs)
**When** `FileClose(g_csvHandle)` is called
**Then** the file handle is released and the CSV file is fully flushed and readable by external applications

**Given** the CSV file is open in the EA
**When** I open the same file in Excel (read-only mode)
**Then** Excel can open it without conflict (FILE_SHARE_READ flag allows concurrent reading)

**Given** `CsvFileName` is changed via the EA panel between sessions
**When** the EA reinitializes
**Then** it opens the new filename — the old file is not affected

**FRs satisfied:** FR11, FR12, FR13
**NFRs satisfied:** NFR4 (< 5s — synchronous FileWrite), NFR7 (MQL5\Files\ sandbox = local user only), NFR9 (write error → warning + continue), NFR10 (broker-agnostic via Symbol())

---

## Epic 4: Visual & Email Alerts

The trader receives an arrow signal on the chart and an email notification within 5 seconds of every pattern close; SMTP failures are logged to the already-open CSV file without stopping the EA.

### Story 4.1: Visual Arrow Signal on Chart

As a trader,
I want a colored arrow to appear on the chart at the exact candle where a pattern was detected,
So that I can immediately see where and when each signal fired during a Strategy Tester session.

**Acceptance Criteria:**

**Given** `DetectPattern()` returns `BULLISH` at bar close
**When** the fan-out sequence runs
**Then** `ObjectCreate()` places an `OBJ_ARROW_UP` object on the chart at the price of `iClose(Symbol(), PERIOD_M15, 1)` and time of `iTime(Symbol(), PERIOD_M15, 1)`, colored green (clrGreen)

**Given** `DetectPattern()` returns `BEARISH` at bar close
**When** the fan-out sequence runs
**Then** `ObjectCreate()` places an `OBJ_ARROW_DOWN` object on the chart at the price of `iClose(Symbol(), PERIOD_M15, 1)` and time of `iTime(Symbol(), PERIOD_M15, 1)`, colored red (clrRed)

**Given** a signal arrow is placed on the chart
**When** I inspect the chart object name
**Then** the name follows the format `"DT_Signal_"` + timestamp string (e.g. `"DT_Signal_20260505_1430"`) — unique per signal, no name collisions across multiple signals

**Given** multiple pattern signals have fired in a Strategy Tester session
**When** I scroll through the chart
**Then** all signal arrows persist on the chart and are visible at their correct bar positions

**Given** `ObjectCreate()` fails (e.g. object name already exists)
**When** the error occurs
**Then** the failure is printed to the MetaEditor Experts log and execution continues — no crash, no EA stop

**Given** the visual signal is the first step in the fan-out sequence
**When** the bar-close event fires and a pattern is detected
**Then** the arrow appears within 1 second of bar close (synchronous call — no async delay)

**FRs satisfied:** FR6
**NFRs satisfied:** NFR2 (< 1s), NFR5

---

### Story 4.2: Email Notification & SMTP Failure Handling

As a trader,
I want an email sent to my configured address within 5 seconds of every pattern close, with full signal details, and I want the EA to keep running and log the failure to CSV even if the email fails,
So that I am notified of signals I missed while away from the screen, without risking loss of any other output.

**Acceptance Criteria:**

**Given** a pattern is detected (BULLISH or BEARISH)
**When** `SendAlertEmail()` is called
**Then** `SendMail()` is invoked with:
- Subject: e.g. `"DT Signal — EURUSD M15 BULLISH"`
- Body containing: pair (`EURUSD`), timeframe (`M15`), pattern type (`BULLISH`/`BEARISH`), body1 pips, body2 pips, timestamp with broker timezone

**Given** `SendMail()` is called
**When** the call completes successfully (returns `true`)
**Then** no error is logged and the fan-out sequence continues to `WriteSignalToCsv()` for the normal signal row

**Given** `SendMail()` returns `false` (SMTP failure, timeout, misconfiguration)
**When** the failure is detected
**Then** `WriteSignalToCsv()` is called with an error marker (e.g. `date,time,EURUSD,M15,SMTP_ERROR,0.0,0.0,0.0`) using the already-open `g_csvHandle` from Epic 3
**And** the EA continues running — status label remains "ACTIVE"
**And** the fan-out sequence then proceeds to write the normal signal row to CSV

**Given** the SMTP server is unreachable (connection timeout)
**When** `SendMail()` is called
**Then** MT5 handles the timeout internally — the EA does not freeze or crash (NFR8)

**Given** the EA source file `DT_SignalEA.mq5`
**When** I search for SMTP credentials (server, username, password)
**Then** no credentials appear anywhere in the source — they reside exclusively in MT5 Tools → Options → Email

**Given** a pattern fires
**When** `SendAlertEmail()` is called on the first tick of the new bar
**Then** the email dispatch is initiated within 5 seconds of bar close (MT5 handles SMTP async delivery)

**FRs satisfied:** FR7, FR8, FR9, FR10
**NFRs satisfied:** NFR3 (< 5s), NFR6 (no credentials in source), NFR8 (timeout handled by MT5)
