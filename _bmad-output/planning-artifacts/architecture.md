---
stepsCompleted: [step-01-init, step-02-context, step-03-starter, step-04-decisions, step-05-patterns, step-06-structure, step-07-validation, step-08-complete]
lastStep: 8
status: 'complete'
completedAt: '2026-05-10'
inputDocuments: [_bmad-output/planning-artifacts/prd.md]
workflowType: 'architecture'
project_name: 'DT_PRIMO_STRATEGIA6'
user_name: 'Primo'
date: '2026-05-09'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements — Architectural Implications:**

| Category | FRs | Architectural Implication |
|----------|-----|--------------------------|
| Signal Detection | FR1–FR4 | Bar-change gate in OnTick(); evaluation runs once per D1 close |
| Trade Execution | FR5–FR9 | Order Manager executes BUY + SL in same OnTick() call; exit on condition |
| Risk Management | FR10–FR14 | Risk Calculator runs before every order; skip+log pattern on constraint fail |
| Indicator Calculation | FR15–FR17 | SMA/RSI computed from closed bar (index 1); Phase 2 adds visual TP object |
| Reporting | FR18–FR24 | Report Engine updates chart comment on every bar; final report on OnDeinit() |
| Configuration | FR25–FR33 | 9 input parameters — all read-only after OnInit(); no hot-reload needed |
| System Resilience | FR34–FR37 | OnInit() scans open positions by MagicNumber; Strategy Tester compatible |

**Non-Functional Requirements — Architectural Constraints:**

| NFR | Constraint |
|-----|-----------|
| NFR1/NFR2 | All signal + order logic completes within one OnTick() — no deferred queues |
| NFR3 | Report Engine must not block Order Manager path |
| NFR4 | OnTick() processing ≤ 50 ms; full 5-year backtest ≤ 60s |
| NFR5 | State recovery in OnInit() before first signal evaluation |
| NFR8 | MathFloor rounding enforced in Risk Calculator — never overshoot |
| NFR9 | Indicator values always from bar index 1 (closed bar) |
| NFR11 | No stateful side-effects between runs — deterministic |
| NFR14 | No DLL imports, no network calls — pure MQL5 stdlib |

**Scale & Complexity:**

- Primary domain: MQL5 embedded plugin (single-file, event-driven, single-threaded)
- Complexity level: Medium — no distributed components, no external APIs
- Physical components: 1 source file (S6_EA.mq5) → 1 compiled artifact (S6_EA.ex5)
- Logical subsystems: 6 (Signal Engine, Order Manager, Risk Calculator, Report Engine, Logger, Config)

### Technical Constraints & Dependencies

- Platform: MetaTrader 5 (Windows) — MQL5 runtime, MT5 Strategy Tester
- Language: MQL5 (C++-like, compiled to .ex5)
- No external dependencies: no DLL, no external files at runtime (Phase 1)
- Phase 2 only: CSV file write (S6_log.csv) — local filesystem, UTF-8 comma-delimited
- Broker compatibility: ECN, STP, market-maker — no broker-specific code
- Deployment: copy .ex5 to MT5_DataFolder/MQL5/Experts/

### Cross-Cutting Concerns Identified

- **Error handling**: every OrderSend, every indicator call, every file operation — log + graceful skip
- **Logging**: all subsystems write to MT5 journal; Phase 2 adds CSV log
- **State management**: lastBarTime (bar-change), trade counters, equity high-watermark (for DD)
- **Phase-gating**: Phase 2 features (CSV, periodic report, TP line) are additive; Phase 1 path unaffected
- **Determinism**: no global mutable state that persists across backtest runs

## Starter Template Evaluation

### Primary Technology Domain

MQL5 embedded plugin (MetaTrader 5 Expert Advisor) — no external package manager, no web CLI scaffolding. Starter = structured .mq5 skeleton file.

### Starter Options Considered

| Option | Verdict |
|--------|---------|
| MetaEditor EA Wizard | Too minimal — no subsystem structure |
| Community templates (mql5.com) | Variable quality, no standard |
| **Manual structured skeleton** | **Selected** — reflects 6-subsystem decomposition |

### Selected Starter: Manual Structured Skeleton (S6_EA.mq5)

**Rationale:** The EA architecture is already fully defined (6 logical subsystems, 9 input params, 3 event callbacks). A hand-crafted skeleton that mirrors this decomposition is the most direct path to implementation.

**Initialization:** Create `S6_EA.mq5` in MetaEditor — no CLI command needed. Compile with F7. Deploy: copy `S6_EA.ex5` to `MT5_DataFolder/MQL5/Experts/`.

**Architectural Decisions Provided by Skeleton:**

**Language & Runtime:** MQL5 (C++-like, compiled to .ex5 via MetaEditor)

**Code Organization:** Single-file architecture — 6 logical sections delimited by comments: Input Params → Global State → Signal Engine → Order Manager → Risk Calculator → Report Engine + Logger → Event Callbacks

**Event Model:** Three mandatory entry points:
- `OnInit()` — initialization + MagicNumber state recovery
- `OnTick()` — bar-change gate → signal evaluation → order execution → reporting
- `OnDeinit()` — final report generation

**State Management:** Global variables (MQL5 has no class requirement): `lastBarTime`, `equityHigh`, `totalTrades`, `winTrades`, `isWarmedUp`

**Build Tooling:** MetaEditor compiler (F7) — deterministic, no build scripts needed

**Testing Infrastructure:** MT5 Strategy Tester (native) — Open Prices Only mode

**Note:** Creating `S6_EA.mq5` with the skeleton structure is the first implementation story (Epic 1, Story 1).

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- OnTick() execution order — defines the entire runtime behavior contract
- Indicator handle lifecycle — determines resource management pattern
- Error handling pattern — determines system safety behavior

**Important Decisions (Shape Architecture):**
- Phase 2 gating strategy — determines how features are activated
- WR/DD calculation method — determines report accuracy guarantee

**Deferred Decisions (Post-MVP):**
- Multi-instrument support (Phase 3) — no architectural impact on Phase 1/2

### Decision 1 — Indicator Handle Lifecycle

**Decision:** Create SMA and RSI handles in `OnInit()`, store as global integers, reuse on every `OnTick()`, release in `OnDeinit()`.

**Rationale:** Single handle creation per session; `iClose()`/`CopyBuffer()` calls per tick are minimal. Creating handles on every tick is a deprecated anti-pattern in MQL5.

**Implementation:** `int hSMA = INVALID_HANDLE; int hRSI = INVALID_HANDLE;` as globals; assigned in `OnInit()`; `IndicatorRelease()` in `OnDeinit()`.

### Decision 2 — OnTick() Execution Order

**Decision:** Fixed execution sequence inside `OnTick()`:

```
1. IsNewBar()            → gate: return if same candle (lastBarTime check)
2. IsWarmedUp()          → gate: return if Bars < SMA_Period + RSI_Period + 1
3. CheckExitConditions() → RSI exit + MaxDays check (only if position open)
4. CheckEntryConditions()→ 3-condition entry gate (only if no position open)
5. UpdateReport()        → chart comment update (always last — NFR3)
```

**Rationale:** Exit-before-Entry ensures open positions are managed before new entries are evaluated. Report always last prevents blocking order execution path (NFR3). Gates at top minimize unnecessary computation on same-bar ticks.

### Decision 3 — Error Handling Pattern

**Decision:** On `OrderSend()` failure: log the error code + description to MT5 journal, skip the trade, retry on next bar naturally.

**Rationale:** Aligns with NFR6 ("Failed trade orders are logged and retried on the next bar — no silent failures"). Immediate retry risks duplicate orders on same tick if MT5 internal state is inconsistent.

**Pattern:** `if(!trade.Buy(...)) { LogEvent("OrderSend failed: " + (string)GetLastError()); return; }`

### Decision 4 — Phase 2 Gating Strategy

**Decision:** Input parameter `input bool EnablePhase2 = false;` guards all Phase 2 features at runtime.

**Rationale:** No recompilation needed to activate Phase 2 features. Default `false` ensures clean Phase 1 backtest behavior. Phase 2 features (CSV log, periodic report, visual TP) are compiled in but dormant — additive, not disruptive.

**Cascading:** Adds 1 parameter to the Input dialog. Phase 2 code blocks wrapped in `if(EnablePhase2) { ... }`.

### Decision 5 — Win Rate / Max Drawdown Calculation

**Decision:** Full recalculation from closed trade history on every report update — no incremental approximation.

**Rationale:** NFR10 mandates "recalculated from actual closed trade history on every report update — no approximations." Trade dataset is small (D1 strategy, dozens of trades per year) — full scan cost is negligible.

**Implementation:** Iterate `HistoryDealsTotal()` on every `UpdateReport()` call; compute WR and DD from scratch.

### Decision Impact Analysis

**Implementation Sequence:**
1. Global state + handle lifecycle (OnInit/OnDeinit) — foundation for all subsystems
2. IsNewBar() + IsWarmedUp() — gates that control all downstream execution
3. Risk Calculator (CalculateLots) — needed before any order
4. Order Manager (OpenPosition/ClosePosition) — core execution
5. Signal Engine (CheckEntry/CheckExit) — wires conditions to Order Manager
6. Report Engine (UpdateReport/GenerateFinalReport) — last, non-blocking
7. Phase 2 blocks behind EnablePhase2 flag

**Cross-Component Dependencies:**
- Signal Engine reads indicator handles owned by global state
- Order Manager calls Risk Calculator before every OpenPosition
- Report Engine reads trade history — no dependency on other subsystems
- Logger is called by all subsystems — no dependencies itself

## Architecture Validation Results

### Coherence Validation ✅

All decisions compatible: MQL5 + CTrade + MetaEditor — native stack, no conflicts. Patterns reinforce decisions: CTrade mandate, CopyBuffer index 1, LogEvent prefix all enforced by explicit anti-pattern rules. OnTick() order satisfies NFR1/2/3. Phase 2 flat gating isolates Phase 1 path completely.

### Requirements Coverage ✅

All 37 FRs architecturally supported (see FR→Structure mapping in Project Structure section). All 15 NFRs addressed: NFR1–4 via OnTick() order + performance decisions; NFR5 via OnInit() scan; NFR6–7 via error handling pattern; NFR8–11 via Risk Calculator decisions; NFR12–15 via CTrade + pure MQL5 stdlib constraints.

### Implementation Readiness ✅

5 architectural decisions with explicit rationale and implementation notes. 8 conflict points resolved with concrete code examples and anti-patterns. Complete file structure defined: repo + MT5 deployment + internal section map.

### Gap Analysis

**Important (1 — fixed):** NFR13 SL minimum distance check not shown in OpenPosition() pattern → fixed: added SYMBOL_TRADE_STOPS_LEVEL validation to OpenPosition():

```mql5
bool OpenPosition() {
    double sl_price  = SymbolInfoDouble(_Symbol, SYMBOL_ASK) * (1.0 - SL_Percent/100.0);
    double sl_points = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - sl_price)
                       / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    long   min_stop  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if(sl_points < min_stop) {
        LogEvent("SKIP | SL distance " + DoubleToString(sl_points,0) +
                 " < broker min " + (string)min_stop);
        return false;
    }
    double lots = CalculateLots();
    if(lots <= 0) return false;
    return trade.Buy(lots, _Symbol, 0, sl_price, 0, "S6 entry");
}
```

**Nice-to-have (2 — deferred):** HistoryDealsTotal() iteration detail; backtest .ini content → deferred to Epic/Story phase.

### Architecture Completeness Checklist

**Requirements Analysis**
- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed (Medium — single-file, no distributed components)
- [x] Technical constraints identified (MQL5, single-threaded, no DLL, CTrade)
- [x] Cross-cutting concerns mapped (error handling, logging, state, phase-gating)

**Architectural Decisions**
- [x] Critical decisions documented with rationale (5 decisions)
- [x] Technology stack fully specified (MQL5, CTrade, MetaEditor F7)
- [x] Integration patterns defined (CTrade, CopyBuffer, HistoryDeals, Comment)
- [x] Performance considerations addressed (OnTick() ≤ 50 ms, index 1 rule)

**Implementation Patterns**
- [x] Naming conventions established (PascalCase functions, camelCase globals)
- [x] Structure patterns defined (8 section delimiters, include directives)
- [x] Communication patterns specified (LogEvent, Comment, FileWrite Phase 2)
- [x] Process patterns documented (error skip+log, phase gating, equity HWM)

**Project Structure**
- [x] Complete directory structure defined (repo + MT5 deployment)
- [x] Component boundaries established (6 subsystem sections in single file)
- [x] Integration points mapped (data flow: OnTick → subsystems → MT5)
- [x] Requirements to structure mapping complete (FR→section table)

### Architecture Readiness Assessment

**Overall Status: READY FOR IMPLEMENTATION**
All 16/16 checklist items ✅ — 0 critical gaps.

**Confidence Level:** High

**Key Strengths:**
- Single-file architecture eliminates inter-module dependency issues
- CTrade mandate prevents raw OrderSend usage across agents
- Explicit anti-patterns prevent the 3 most common MQL5 bugs (index 0, no MagicNumber filter, raw OrderSend)
- Phase 2 flat gating allows incremental delivery without rework

**Areas for Future Enhancement (Phase 3):**
- Multi-instrument: refactor Global State into per-symbol structs
- Push notifications: MQL5 `SendNotification()` — additive, no core changes needed

### Implementation Handoff

**AI Agent Guidelines:**
- Follow all 5 architectural decisions exactly as documented
- Use PascalCase/camelCase naming — no exceptions
- CTrade only — never raw OrderSend
- CopyBuffer index 1 always — never index 0
- Every Print() must go through LogEvent() with [S6] prefix

**First Implementation Priority:**
Create `src/S6_EA.mq5` with the 8-section skeleton, compile in MetaEditor (F7, zero errors), run minimal backtest to verify OnInit/OnTick/OnDeinit lifecycle. This is Epic 1, Story 1.

## Project Structure & Boundaries

### Complete Project Directory Structure

**Repository (`DT_PRIMO_STRATEGIA6/`):**

```
DT_PRIMO_STRATEGIA6/
├── src/
│   └── S6_EA.mq5                    ← single MQL5 source file
├── _bmad-output/
│   └── planning-artifacts/
│       ├── prd.md
│       ├── architecture.md
│       └── prd-validation-report.md
├── tests/
│   └── backtest/
│       └── S6_backtest_2024.ini     ← Strategy Tester configuration
└── README.md
```

**MT5 Deployment (outside repo):**

```
%APPDATA%\MetaQuotes\Terminal\<ID>\MQL5\
├── Experts/
│   └── S6_EA.ex5                   ← compiled EA (copy after F7 in MetaEditor)
├── Include/
│   └── Trade/
│       └── Trade.mqh               ← CTrade built-in (do not modify)
└── Files/
    └── S6_log.csv                  ← Phase 2: CSV trade log (generated by EA)
```

### Internal File Structure (`S6_EA.mq5`)

```
S6_EA.mq5
├── #property directives + #include <Trade/Trade.mqh>
├── ── INPUT PARAMETERS ──   10 inputs (RiskPercent…MagicNumber + EnablePhase2)
├── ── GLOBAL STATE ──        lastBarTime, equityHigh, totalTrades, winTrades,
│                             hSMA, hRSI, isWarmedUp, CTrade trade
├── ── SIGNAL ENGINE ──       IsNewBar(), IsWarmedUp(),
│                             CheckEntryConditions(), CheckExitConditions()
├── ── ORDER MANAGER ──       OpenPosition(), ClosePosition(string reason)
├── ── RISK CALCULATOR ──     CalculateLots()
├── ── REPORT ENGINE+LOGGER ─ UpdateReport(), GenerateFinalReport(), LogEvent()
└── ── EVENT CALLBACKS ──     OnInit(), OnTick(), OnDeinit()
```

### Requirements to Structure Mapping

| FR Category | File Section | Functions |
|-------------|-------------|-----------|
| Signal Detection FR1–4 | SIGNAL ENGINE | IsNewBar, IsWarmedUp, CheckEntryConditions, CheckExitConditions |
| Trade Execution FR5–9 | ORDER MANAGER | OpenPosition, ClosePosition |
| Risk Management FR10–14 | RISK CALCULATOR | CalculateLots |
| Indicator Calc FR15–17 | GLOBAL STATE + SIGNAL ENGINE | hSMA, hRSI handles; Phase 2: DrawTPLine |
| Reporting FR18–24 | REPORT ENGINE + LOGGER | UpdateReport, GenerateFinalReport, LogEvent |
| Configuration FR25–33 | INPUT PARAMETERS | 10 input vars |
| Resilience FR34–37 | OnInit + GLOBAL STATE | MagicNumber scan, lastBarTime |

### Integration Points & Data Flow

```
MT5 Market Feed
    ↓
OnTick()
    ├─ IsNewBar()              [gate — same bar: return]
    ├─ IsWarmedUp()            [gate — cold bars: return]
    ├─ equityHigh update
    ├─ CheckExitConditions() → ClosePosition(reason) → LogEvent()
    ├─ CheckEntryConditions() → CalculateLots() → OpenPosition() → LogEvent()
    └─ UpdateReport() → Comment() | [Phase2: FileWrite(S6_log.csv)]

OnInit()   → IndicatorCreate(hSMA, hRSI) + MagicNumber position scan
OnDeinit() → GenerateFinalReport() + IndicatorRelease(hSMA, hRSI)
```

**Integration Boundaries:**

| Boundary | Mechanism |
|----------|-----------|
| MT5 ↔ Signal Engine | `CopyBuffer(hSMA/hRSI, 0, 1, 1, buf)` — read-only |
| MT5 ↔ Order Manager | `CTrade.Buy()` / `trade.PositionClose()` |
| MT5 ↔ Report Engine | `Comment()`, `Print()`, `FileWrite()` (Phase 2) |
| MT5 ↔ Risk Calculator | `AccountInfoDouble()`, `SymbolInfoDouble()` |
| All subsystems ↔ Logger | `LogEvent(msg)` — write-only, no return |

## Implementation Patterns & Consistency Rules

### Critical Conflict Points Identified: 8

### Naming Patterns

**Function naming — PascalCase, descriptive prefix:**

```mql5
// ✅ REQUIRED
bool   IsNewBar()
bool   IsWarmedUp()
bool   CheckEntryConditions()
bool   CheckExitConditions()
bool   OpenPosition()
bool   ClosePosition(string reason)
double CalculateLots()
void   UpdateReport()
void   GenerateFinalReport()
void   LogEvent(string msg)

// ❌ ANTI-PATTERN: snake_case, ambiguous names, lowercase first char
```

**Global variable naming — camelCase, explicit names:**

```mql5
// ✅ REQUIRED
datetime lastBarTime;
double   equityHigh;
int      totalTrades;
int      winTrades;
int      hSMA;
int      hRSI;
bool     isWarmedUp;
CTrade   trade;   // global CTrade instance

// ❌ ANTI-PATTERN: lb, cnt, h1, h2 (opaque abbreviations)
```

### Structure Patterns

**Required #include directives (top of file, before inputs):**

```mql5
#property copyright "Primo"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>
```

**File section delimiters — standard format:**

```mql5
//================================================================
//  INPUT PARAMETERS
//================================================================
//================================================================
//  GLOBAL STATE
//================================================================
//================================================================
//  SIGNAL ENGINE
//================================================================
//================================================================
//  ORDER MANAGER
//================================================================
//================================================================
//  RISK CALCULATOR
//================================================================
//================================================================
//  REPORT ENGINE + LOGGER
//================================================================
//================================================================
//  EVENT CALLBACKS
//================================================================
```

### Format Patterns

**Chart comment — fixed StringFormat (no variation):**

```mql5
// ✅ REQUIRED
Comment(StringFormat("S6 EA | WR: %.1f%% (%d/%d) | MaxDD: %.2f%%",
        winRate, winTrades, totalTrades, maxDrawdown));
```

**Journal log — `[S6]` prefix mandatory (filterable in MT5 journal):**

```mql5
// ✅ REQUIRED
void LogEvent(string msg) { Print("[S6] " + msg); }

// Call examples:
LogEvent("SIGNAL | Entry conditions met — BUY at next open");
LogEvent("ORDER | BUY placed | Lots: " + DoubleToString(lots,2));
LogEvent("CLOSE | " + reason + " | P&L: " + DoubleToString(pnl,2));
LogEvent("ERROR | OrderSend failed | Code: " + (string)GetLastError());

// ❌ ANTI-PATTERN: Print("signal detected") — no prefix, not filterable
```

**ClosePosition — always pass reason string (FR9):**

```mql5
// ✅ REQUIRED — reason values: "RSI_EXIT", "TIMEOUT", "SL_HIT", "MANUAL"
ClosePosition("RSI_EXIT");
ClosePosition("TIMEOUT");

// ❌ ANTI-PATTERN: ClosePosition() with no reason parameter
```

### Process Patterns

**Order execution — CTrade always, never raw OrderSend:**

```mql5
// ✅ REQUIRED
CTrade trade;   // global
// In OnInit(): trade.SetExpertMagicNumber(MagicNumber);
trade.Buy(lots, _Symbol, 0, sl_price, 0, "S6 entry");

// ❌ ANTI-PATTERN: OrderSend() direct call
```

**Position check — always with MagicNumber filter:**

```mql5
// ✅ REQUIRED
bool HasOpenPosition() {
    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 &&
           PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            return true;
    }
    return false;
}

// ❌ ANTI-PATTERN: if(PositionsTotal() > 0) — ignores MagicNumber, breaks multi-EA
```

**Indicator values — CopyBuffer with index 1 (closed bar, NFR9):**

```mql5
// ✅ REQUIRED
double smaBuffer[1], rsiBuffer[1];
CopyBuffer(hSMA, 0, 1, 1, smaBuffer);  // index 1 = closed bar
CopyBuffer(hRSI, 0, 1, 1, rsiBuffer);

// ❌ ANTI-PATTERN: iMA(..., 0) or CopyBuffer(..., 0, ...) — forming bar
```

**Equity high-watermark — update only on new bar, before signal evaluation:**

```mql5
// ✅ REQUIRED (inside OnTick, immediately after IsNewBar gate)
double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
if(currentEquity > equityHigh) equityHigh = currentEquity;
```

**Phase 2 gating — flat condition, no nesting:**

```mql5
// ✅ REQUIRED
if(EnablePhase2) GeneratePeriodicReport();
if(EnablePhase2) DrawTPLine();

// ❌ ANTI-PATTERN: nested if(EnablePhase2) { if(...) { ... } }
```

### Enforcement Guidelines

**All AI Agents MUST:**
- Use `CTrade trade;` global — never raw `OrderSend()`
- Use `CopyBuffer(..., 1, ...)` — always closed bar (index 1)
- Prefix every `Print()` with `[S6]` via `LogEvent()`
- Pass reason string to `ClosePosition()`
- Filter positions by `MagicNumber` in every position check
- Open handles in `OnInit()`, release in `OnDeinit()`
- Keep Phase 2 code behind flat `if(EnablePhase2)` — no nesting

**Anti-patterns that will cause bugs:**
- `PositionsTotal() > 0` without MagicNumber — double-trades with other EAs
- `CopyBuffer(..., 0, ...)` — signal on forming bar, repaints
- Raw `OrderSend()` — bypasses CTrade filling mode handling
- `ClosePosition()` without reason — breaks FR9 exit tracking
