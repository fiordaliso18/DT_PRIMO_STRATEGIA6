# Story 1.1: EA Scaffold with Input Parameters

Status: done

## Story

As a trader,
I want a compilable EA file with all configurable parameters declared and stub event handlers,
so that I have a working foundation I can load in MetaTrader 5 Strategy Tester without errors.

## Acceptance Criteria

1. **Given** MetaEditor is open  
   **When** I create `src/DT_SignalEA.mq5` using `File → New → Expert Advisor` and implement the canonical section order (header comment → `#property` declarations → `input` parameters → global variables → `OnInit()` → `OnDeinit()` → `OnTick()` → helper function stubs)  
   **Then** the file compiles without errors or warnings in MetaEditor (F7)

2. **Given** the EA is compiled and copied to `MQL5\Experts\DT_Signal\`  
   **When** I attach it to a chart or load it in Strategy Tester  
   **Then** the EA loads successfully and `OnInit()` returns `INIT_SUCCEEDED`

3. **Given** the EA is loaded  
   **When** I open the EA properties panel (F7)  
   **Then** I see all input parameters with correct defaults:
   - `PipThreshold` = 20.0
   - `EmailRecipient` = "primo.brandi@gmail.com"
   - `CsvFileName` = "dt_signals.csv"

4. **Given** the EA file  
   **When** I inspect the source  
   **Then** all global variables use the `g_` prefix, all input parameters use `PascalCase`, and every non-trivial line has a bilingual comment `// English / Italiano`

## Tasks / Subtasks

- [x] Task 1: Create `src/DT_SignalEA.mq5` with canonical file structure (AC: 1, 4)
  - [x] 1.1 Add header comment block (EA name, version, author, description) — bilingual
  - [x] 1.2 Add `#property` declarations (copyright, version, description)
  - [x] 1.3 Add `input` parameters block: `PipThreshold`, `EmailRecipient`, `CsvFileName` with correct defaults and labels
  - [x] 1.4 Define `PATTERN_TYPE` enum: `NONE=0`, `BULLISH=1`, `BEARISH=2`
  - [x] 1.5 Add global variables block: `g_lastBarTime`, `g_csvHandle`, `g_signalCount` with `g_` prefix
- [x] Task 2: Implement stub event handlers (AC: 1, 2)
  - [x] 2.1 `OnInit()` — initialize globals, return `INIT_SUCCEEDED`
  - [x] 2.2 `OnDeinit(const int reason)` — stub body
  - [x] 2.3 `OnTick()` — stub body
- [x] Task 3: Add helper function stubs in call order (AC: 1, 4)
  - [x] 3.1 `UpdateStatusLabel(string text, color clr)` — stub void
  - [x] 3.2 `DetectPattern()` returns `PATTERN_TYPE` — stub returns `NONE`
  - [x] 3.3 `SendAlertEmail(PATTERN_TYPE pt, double body1, double body2)` returns `bool` — stub returns `false`
  - [x] 3.4 `WriteSignalToCsv(PATTERN_TYPE pt, double body1, double body2)` returns `bool` — stub returns `false`
  - [x] 3.5 `double BodyInPips(int barIndex)` — stub returns `0.0`
- [x] Task 4: Verify compilation and load (AC: 1, 2, 3) — REQUIRES MANUAL METAEDITOR
  - [x] 4.1 Compile with MetaEditor F7 — zero errors, zero warnings
  - [x] 4.2 Copy `.ex5` to `MQL5\Experts\DT_Signal\` and load in Strategy Tester — `OnInit()` returns success
  - [x] 4.3 Open EA properties panel — verify all 3 input defaults are correct

## Dev Notes

### Platform & Language
- **Language:** MQL5 (C++-like, compiled, single-threaded event-driven)
- **IDE:** MetaEditor (MT5 built-in) — `File → New → Expert Advisor` generates the initial scaffold
- **Compiler:** F7 in MetaEditor → produces `.ex5` binary
- **Test environment:** MT5 Strategy Tester (offline historical data, no live connection required)

### Canonical File Section Order (MANDATORY — never deviate)
```
1. Header comment block (bilingual)
2. #property declarations
3. input parameters block (all inputs grouped, with labels)
4. PATTERN_TYPE enum
5. Global variables (all g_* prefixed)
6. OnInit()
7. OnDeinit()
8. OnTick()
9. Helper functions in call order:
   UpdateStatusLabel() → DetectPattern() → SendAlertEmail() → WriteSignalToCsv() → BodyInPips()
```

### Input Parameters (exact names, types, defaults — no deviation)
```mql5
// Input parameters / Parametri di input
input double PipThreshold   = 20.0;                      // Pip threshold / Soglia in pip
input string EmailRecipient = "primo.brandi@gmail.com";  // Email recipient / Destinatario email
input string CsvFileName    = "dt_signals.csv";          // CSV filename / Nome file CSV
```

### Global Variables (exact names, types — declared now, used in later stories)
```mql5
// Global state / Stato globale
datetime g_lastBarTime  = 0;    // Last processed bar time / Ora ultima barra elaborata
int      g_csvHandle    = -1;   // CSV file handle / Handle file CSV
int      g_signalCount  = 0;    // Signal counter / Contatore segnali
```

### PATTERN_TYPE Enum (used in DetectPattern return and all fan-out calls)
```mql5
// Pattern type enumeration / Enumerazione tipo pattern
enum PATTERN_TYPE { NONE=0, BULLISH=1, BEARISH=2 };
```

### OnInit() Stub Requirements
- Must return `INIT_SUCCEEDED` (value = 0)
- Initialize `g_lastBarTime = 0`, `g_csvHandle = -1`, `g_signalCount = 0`
- Do NOT call any helper functions yet (they are stubs)
- Bilingual comment on each non-trivial line

### #property Declarations Required
```mql5
#property copyright "Primo"
#property version   "1.00"
#property description "DT Signal EA — Two-candle M15 pattern detector"
#property strict
```

### Naming Conventions (MANDATORY)
| Element | Rule | Example |
|---------|------|---------|
| Input parameters | PascalCase | `PipThreshold` |
| Global variables | `g_` + camelCase | `g_lastBarTime` |
| Local variables | camelCase | `currentTime` |
| Functions | PascalCase + verb | `DetectPattern()` |
| Chart objects | `"DT_"` prefix | `"DT_StatusLabel"` |
| Enum values | UPPER_CASE | `BULLISH`, `BEARISH`, `NONE` |

### Bilingual Comment Format (MANDATORY on every non-trivial line)
```mql5
// English comment / Commento italiano
```
Single line, no multi-line blocks, no docstrings.

### File Paths
- **Source (dev):** `src/DT_SignalEA.mq5` (relative to project root)
- **Compiled output:** `MQL5\Experts\DT_Signal\DT_SignalEA.ex5` (MT5 terminal path)
- **CSV output (Story 3.1):** `MQL5\Files\dt_signals.csv` (MT5 sandbox, not this story)

### Testing Approach for MQL5
No unit test framework exists for MQL5. Verification is:
1. **Compilation test:** MetaEditor F7 → must show 0 errors, 0 warnings in the Errors tab
2. **Load test:** Attach EA to Strategy Tester chart → `OnInit()` must log success, EA appears in chart without crash
3. **Properties inspection:** F7 panel → verify PipThreshold=20.0, EmailRecipient="primo.brandi@gmail.com", CsvFileName="dt_signals.csv"
4. **Source inspection:** Grep source for `g_` prefix on all globals, `PascalCase` inputs, bilingual comments

### What NOT to implement in this story (future stories)
- `UpdateStatusLabel()`: stub only — real OBJ_LABEL logic is Story 1.2
- `g_lastBarTime` usage: declared here, iTime() guard is Story 2.1
- `g_csvHandle` usage: declared here, FileOpen() is Story 3.1
- Pattern detection logic: Story 2.2
- Email sending: Story 4.2
- CSV writing: Story 3.1

### No External Dependencies
This story has zero external dependencies. MQL5 is self-contained — no `#include` files, no external libraries needed for this scaffold.

### Project Structure Notes
- `src/` folder must be created at project root if it does not exist
- The `.mq5` file is the only deliverable of this story
- `.ex5` compiled binary is gitignored (binary artifact) — only source is committed
- Architecture reference: [architecture.md — Project Structure & Boundaries]

### References
- [epics.md — Story 1.1 Acceptance Criteria]
- [architecture.md — Implementation Patterns & Consistency Rules]
- [architecture.md — Core Architectural Decisions → Data Architecture]
- [architecture.md — Project Structure & Boundaries]
- [prd.md — FR14, FR16, FR17, FR18, FR19, FR23, FR24]
- [prd.md — NFR5]

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
None — MQL5 has no automated test framework; verification performed via MetaEditor F7 (0 errors, 0 warnings) and MT5 Strategy Tester (INIT_SUCCEEDED confirmed).

### Completion Notes List
- Scaffold created with canonical section order: header → #property → inputs → enum → globals → OnInit → OnDeinit → OnTick → helpers
- All 3 input parameters match exact specs (PipThreshold=20.0, EmailRecipient, CsvFileName)
- PATTERN_TYPE enum defined with NONE=0, BULLISH=1, BEARISH=2
- All globals use g_ prefix; all function stubs return correct zero-values
- Bilingual comments (English / Italiano) on every non-trivial line
- Task 4 verified manually: MetaEditor F7 → 0 errors, 0 warnings; Strategy Tester → EA initialized successfully

### File List
- src/DT_SignalEA.mq5 (created)
