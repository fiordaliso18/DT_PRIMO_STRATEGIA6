---
stepsCompleted: [step-01-init, step-02-context, step-03-starter, step-04-decisions, step-05-patterns, step-06-structure, step-07-validation, step-08-complete]
status: 'complete'
completedAt: '2026-05-05'
inputDocuments: [_bmad-output/planning-artifacts/prd.md]
workflowType: 'architecture'
project_name: 'DT_PRIMO_PROVA'
user_name: 'Primo'
date: '2026-05-05'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements — Architectural Implications:**

| Category | FRs | Implication |
|----------|-----|-------------|
| Pattern Detection | FR1–FR5 | Event-driven detection engine triggered by M15 bar close event |
| Alert & Notification | FR6–FR10 | Fan-out to 3 channels (visual, SMTP, CSV) from single event, with independent failure handling |
| Signal Logging | FR11–FR13 | Async CSV writer, fixed schema, UTF-8 encoding |
| Configuration | FR14–FR19 | Hot-reloadable parameters at runtime without restart — shared state with detector |
| System Status | FR20–FR22 | Independent UI component reflecting system state |
| Data Mode | FR23–FR26 | Two operating modes (test/live) with interchangeable data source |

**Non-Functional Requirements — Architectural Constraints:**
- **NFR1–NFR5 (Performance):** Detection within current candle close → synchronous event-driven architecture, no polling
- **NFR6–NFR7 (Security):** SMTP credentials not in plaintext → config file separate from source code
- **NFR8–NFR10 (Integration):** SMTP and CSV failures must be isolated — no error blocks the detector

**Scale & Complexity:**
- Single user, single pair (EUR/USD), single pattern
- Complexity: **Medium** (real-time event, multi-output fanout, hot-reload config, error isolation)
- Technical domain: Forex signal processing / event-driven desktop tool
- Estimated architectural components: **4** (Detector · Notifier · Logger · Config Manager)

### Technical Constraints & Dependencies

- **Platform:** Windows, trading environment with M15 EUR/USD data feed
- **Language:** MQL5 (native Expert Advisor in MT5 platform)
- **Python 3.9:** Virtual environment `.venv39/` for speakit (currency name display)
- **Phase 1:** EUR/USD hardcoded, test mode only

### Cross-Cutting Concerns

1. **Event timing:** Everything depends on `OnBarClose` M15 event — it is the system clock
2. **Error isolation:** SMTP failure must not block CSV logging or visual signal
3. **Hot-reload config:** Pip threshold modifiable at runtime → thread-safe shared state
4. **Multi-output fanout:** One event → 3 outputs (visual, email, CSV) all within 5 seconds

## Starter Template Evaluation

### Primary Technology Domain

MQL5 Expert Advisor — MetaTrader 5 platform, Windows.

### Selected Starter: MetaEditor EA Scaffold (MT5 native)

**Rationale:** Single-file, single-developer project. No external framework needed. The native MT5 template is the de facto standard for all Expert Advisors.

**Initialization:** `File → New → Expert Advisor` in MetaEditor (MT5 built-in IDE)

**Architectural Decisions Provided by Scaffold:**

- **Language & Runtime:** MQL5 (C++-like, compiled, event-driven)
- **Core Event Handlers:** `OnInit()` · `OnDeinit()` · `OnTick()`
- **Code Organization:** Single `.mq5` file — input parameters → global variables → event handlers → helper functions
- **Development Experience:** MetaEditor compiler · Strategy Tester (test mode) · integrated debugger

**Note:** First implementation story — create EA file in MetaEditor with 4 base event handlers.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Bar-close detection pattern (`iTime()` comparison in `OnTick()`)
- SMTP credential storage (input parameters — not in source)
- Error isolation strategy (SMTP/CSV failure must not block detection)

**Important Decisions (Shape Architecture):**
- Config hot-reload via MT5 input parameter panel (F7 → modify → OK)
- CSV output via `FileWrite()` to MT5 sandbox (`MQL5\Files\`)
- Visual signal via `OBJ_ARROW_UP` / `OBJ_ARROW_DOWN` chart objects
- Status indicator via persistent `OBJ_LABEL` (chart corner)

**Deferred Decisions (Post-MVP):**
- Live mode broker connection handling (Phase 2)
- Multi-pair architecture extension (Phase 2)
- Audio alert integration (Phase 2)

### Data Architecture

**Configuration — Input Parameters (hot-reload):**
- All user-configurable parameters declared with `input` keyword in MQL5
- Hot-reload: user modifies values in EA panel (F7) → new values active on next `OnTick()` — no restart required (FR15, FR22)
- Parameters saved/loaded via MT5 `.set` files (trader-managed)
- Default values hardcoded at declaration: `PipThreshold = 20`, `EmailRecipient = "primo.brandi@gmail.com"`

**CSV Signal Log — FileWrite():**
- Function: `FileOpen()` in append mode + `FileWrite()` per signal row
- Path: `MQL5\Files\` sandbox (MT5 security constraint) — filename configurable via input parameter (FR17)
- Schema (FR12): `date, time (broker TZ), pair, timeframe, pattern type, candle1_body_pips, candle2_body_pips, threshold`
- Encoding: UTF-8 via `FILE_CSV | FILE_UNICODE` flags (FR13)
- On write error: visual warning on chart, EA continues operating (NFR9)

### Authentication & Security

**SMTP Credentials (NFR6):**
- Approach: MT5 built-in email configuration (`Tools → Options → Email` in MT5 terminal)
- SMTP server, port, username, password: stored in MT5 settings — never in `.mq5` source file
- `SendMail(subject, body)` reads credentials from MT5 settings at runtime
- Satisfies NFR6: zero plaintext credentials in source code or compiled file

**CSV File Access (NFR7):**
- MT5 sandbox (`MQL5\Files\`) is accessible only to the local Windows user running MT5
- No additional permission configuration needed

### API & Communication Patterns

**Bar-Close Detection — iTime() Pattern:**
```mql5
// Standard new-bar detection / Rilevamento nuova barra standard
datetime lastBarTime = 0;
// In OnTick():
datetime currentBarTime = iTime(Symbol(), PERIOD_M15, 0);
if(currentBarTime != lastBarTime) {
    lastBarTime = currentBarTime;
    // → trigger pattern detection on closed bar [0] and [1]
}
```
- Detects M15 bar close on the first tick of the new bar (NFR1)
- Evaluates candles at index `[1]` (just closed) and `[2]` (prior closed)

**Email Notification — SendMail():**
- Function: `SendMail(string subject, string body)`
- Called synchronously in the bar-close detection branch
- Return value checked: `false` → log error to CSV, continue (FR10)
- Target: within 5 seconds of bar close (NFR3) — MT5 handles SMTP async internally

**Error Isolation Pattern:**
```
OnTick() → new bar? → detect pattern → [fan-out]
                                         ├─ ObjectCreate() visual signal   (never fails silently)
                                         ├─ SendMail()     → false? → CSV error row
                                         └─ FileWrite()    → false? → chart warning label
```
Each output is independent — failure of one does not affect others (NFR8–NFR10).

### Frontend Architecture (Chart UI)

**Visual Signal (FR6):**
- Object type: `OBJ_ARROW_UP` (bullish) / `OBJ_ARROW_DOWN` (bearish)
- Position: price of the second closed candle (`iClose(Symbol(), PERIOD_M15, 1)`)
- Time: timestamp of second closed candle (`iTime(Symbol(), PERIOD_M15, 1)`)
- Color: green (bullish) / red (bearish)
- Created once per signal, persists on chart

**Status Indicator (FR20–FR21):**
- Object type: `OBJ_LABEL`, anchored to chart corner (CORNER_LEFT_UPPER)
- Text: `"DT Signal EA — ACTIVE"` / `"DT Signal EA — STOPPED"`
- Updated in `OnInit()` (ACTIVE), `OnDeinit()` (STOPPED), and on unexpected errors
- Persists across timeframe changes; removed on EA unload (`OnDeinit()`)

### Infrastructure & Deployment

| Aspect | Decision | Note |
|--------|----------|------|
| Build | MetaEditor → F7 | Produces `.ex5` compiled file |
| Deploy | Copy `.ex5` to `MQL5\Experts\` | Manual, as per PRD (Platform requirement) |
| Test mode | MT5 Strategy Tester | Offline replay of historical M15 data (FR23–FR24) |
| Live mode | Attach EA to live chart | Phase 2 only |
| Monitoring | OBJ_LABEL status + CSV log | No external monitoring infrastructure |
| Updates | Trader replaces `.ex5` and reloads EA | Manual (PRD: Platform requirement) |

### Decision Impact Analysis

**Implementation Sequence:**
1. `OnInit()` — create status label (ACTIVE), initialize `lastBarTime`
2. `OnTick()` — `iTime()` check → new bar branch → detect → fan-out
3. Pattern detection — evaluate `iClose/iOpen` on bars `[1]` and `[2]`
4. Fan-out — visual arrow → `SendMail()` → `FileWrite()`
5. `OnDeinit()` — update status label (STOPPED), close file handle

**Cross-Component Dependencies:**
- All components share `input` parameters (read-only after `OnInit()` per tick)
- CSV file handle opened once in `OnInit()`, closed in `OnDeinit()`
- SMTP failure path writes to same CSV — file handle must be open before `SendMail()` call
- Status label object name must be unique and consistent across `OnInit()` / `OnDeinit()`

## Implementation Patterns & Consistency Rules

### Critical Conflict Points Identified

5 areas where AI agents could make different, incompatible choices without explicit rules.

### Naming Patterns

**MQL5 Identifier Conventions:**

| Element | Convention | Example |
|---------|------------|---------|
| Input parameters | `PascalCase` | `PipThreshold`, `EmailRecipient`, `CsvFileName` |
| Global variables | prefix `g_` + camelCase | `g_lastBarTime`, `g_csvHandle`, `g_signalCount` |
| Local variables | camelCase | `candleBody`, `currentBarTime`, `patternType` |
| Helper functions | `PascalCase` + verb | `DetectPattern()`, `WriteSignalToCsv()`, `SendAlertEmail()`, `UpdateStatusLabel()` |
| Chart objects — status | `"DT_StatusLabel"` | Fixed name, one instance per EA |
| Chart objects — signals | `"DT_Signal_"` + timestamp string | Unique per signal, e.g. `"DT_Signal_20260505_1430"` |
| CSV header row | snake_case English | `date,time,pair,timeframe,pattern,body1_pips,body2_pips,threshold` |

### Structure Patterns

**Canonical file section order (single `.mq5` file):**

```
1. Header comment block (EA name, version, author, description)
2. #property declarations (copyright, version, description)
3. input parameters block (all inputs in one block, grouped by category)
4. Global variables block (all g_* variables)
5. OnInit()
6. OnDeinit()
7. OnTick()
8. Helper functions in call order:
   DetectPattern() → SendAlertEmail() → WriteSignalToCsv() → UpdateStatusLabel()
```

No function may appear before the handler that calls it (MQL5 does not require forward declarations but forward order is clearer for agents).

### Format Patterns

**Pip body calculation (5-decimal broker, EUR/USD):**
```mql5
// Body size in pips / Dimensione del corpo in pips
double BodyInPips(int barIndex) {
    return MathAbs(iClose(Symbol(), PERIOD_M15, barIndex)
                 - iOpen(Symbol(),  PERIOD_M15, barIndex)) / _Point / 10.0;
}
```
- `_Point` = 0.00001 for 5-decimal pairs → dividing by 10 gives pips
- Always use `MathAbs()` — body is always positive

**Bar index convention (mandatory — never deviate):**

| Index | Meaning |
|-------|---------|
| `[0]` | Bar currently forming — NEVER used for pattern |
| `[1]` | Last closed bar (most recent) |
| `[2]` | Prior closed bar |

**CSV row format:**
```
2026.05.05,14:30,EURUSD,M15,BULLISH,25.3,22.1,20.0
```
- Date: `YYYY.MM.DD` (MT5 broker format)
- Time: `HH:MM` (broker timezone)
- Pattern: `BULLISH` or `BEARISH` (uppercase)
- Pips: one decimal place, e.g. `25.3`

### Communication Patterns

**Event flow — canonical fan-out sequence:**

```
OnTick()
 └─ iTime() check → new M15 bar?
     └─ DetectPattern(bars [1],[2])
         └─ pattern found?
             ├─ 1. UpdateStatusLabel("SIGNAL")     ← visual first, always succeeds
             ├─ 2. ObjectCreate() arrow on chart    ← visual signal
             ├─ 3. SendAlertEmail()                 ← SMTP, may fail → log error
             └─ 4. WriteSignalToCsv()               ← file, may fail → chart warning
```

Fan-out is always in this exact order. Visual outputs precede external I/O outputs.

### Process Patterns

**Error handling — continue-and-log for secondary outputs:**

| Context | On failure | EA continues? |
|---------|------------|---------------|
| `OnInit()` — `iTime()` returns 0 | `return INIT_FAILED` | No (critical) |
| `OnInit()` — file open fails | Log + visual warning, continue | Yes |
| `SendMail()` returns false | Write error row to CSV | Yes |
| `FileWrite()` returns false | Update chart warning label | Yes |
| `ObjectCreate()` fails | Print to MetaEditor log | Yes |

**Comment format (bilingual — mandatory for all comments):**
```mql5
// English comment / Commento italiano
```
One line per comment. No multi-line comment blocks. No docstrings.

### Enforcement Guidelines

**All AI agents MUST:**
- Follow the canonical file section order (header → properties → inputs → globals → handlers → helpers)
- Use `g_` prefix for every global variable
- Use `"DT_"` prefix for every chart object name
- Use bar index `[1]` for last closed, `[2]` for prior closed — never `[0]`
- Write bilingual comments on every non-trivial line
- Check return value of `SendMail()` and `FileWrite()` — never fire-and-forget
- Use `BodyInPips()` helper for all pip calculations — no inline formulas

## Project Structure & Boundaries

### Complete Project Directory Structure

```
DT_PRIMO_PROVA/                          ← project root / root progetto
│
├── _bmad/                               ← BMAD framework (do not modify / non modificare)
├── _bmad-output/
│   └── planning-artifacts/
│       ├── prd.md                       ← completed PRD / PRD completato
│       └── architecture.md             ← this document / questo documento
│
├── src/
│   └── DT_SignalEA.mq5                  ← main EA source file (single file) / sorgente EA (file unico)
│
├── sets/
│   └── DT_SignalEA_default.set          ← default parameter preset / preset parametri default
│
├── docs/
│   └── user-guide.md                    ← trader deploy + usage instructions / istruzioni deploy e uso
│
├── .venv39/                             ← Python 3.9 venv (speakit utility)
├── demo_currency.py                     ← currency display utility / utility display valute
└── .gitignore
```

### MT5 Deployment Path

```
%APPDATA%\MetaQuotes\Terminal\[InstanceID]\
└── MQL5\
    ├── Experts\
    │   └── DT_Signal\
    │       └── DT_SignalEA.ex5          ← compiled output (MetaEditor F7) / compilato da MetaEditor
    └── Files\
        └── dt_signals.csv              ← CSV signal log (auto-created on first signal / creato al primo segnale)
```

### Requirements to Structure Mapping

| FR Category | File / Location |
|-------------|-----------------|
| FR1–FR5 Pattern Detection | `DetectPattern()` in `src/DT_SignalEA.mq5` |
| FR6 Visual signal | `ObjectCreate()` calls in `src/DT_SignalEA.mq5` |
| FR7–FR10 Email + SMTP failure | `SendAlertEmail()` in `src/DT_SignalEA.mq5` |
| FR11–FR13 CSV log | `WriteSignalToCsv()` in `src/DT_SignalEA.mq5` |
| FR14–FR19 Configuration | `input` block in `src/DT_SignalEA.mq5` + `sets/*.set` |
| FR20–FR22 Status indicator | `UpdateStatusLabel()` in `src/DT_SignalEA.mq5` |
| FR23–FR24 Test mode | MT5 Strategy Tester (no additional code) |

### Integration Points

| External System | Integration Method | Boundary |
|----------------|-------------------|----------|
| MT5 price feed | `iTime()`, `iClose()`, `iOpen()` — native MQL5 | `OnTick()` handler |
| SMTP email | `SendMail()` — MT5 built-in (reads MT5 Options settings) | `SendAlertEmail()` |
| File system CSV | `FileOpen()` / `FileWrite()` — MT5 `MQL5\Files\` sandbox | `WriteSignalToCsv()` |
| Chart UI | `ObjectCreate()` / `ObjectSetString()` — MT5 chart API | Fan-out sequence |

### Data Flow

```
MT5 price tick
    └─ OnTick()
        └─ iTime() → new M15 bar?
            └─ iClose()/iOpen() bars [1],[2] → DetectPattern()
                └─ pattern found?
                    ├─ UpdateStatusLabel()          → MT5 Chart Object
                    ├─ ObjectCreate() arrow          → MT5 Chart Object
                    ├─ SendAlertEmail()              → MT5 SMTP → Email
                    └─ WriteSignalToCsv()            → MQL5\Files\*.csv
```

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:** MQL5 è single-threaded event-driven — tutte le chiamate (iTime, FileWrite, SendMail, ObjectCreate) sono sincrone native, nessun conflitto. Nessuna dipendenza esterna per Phase 1.

**Pattern Consistency:** Naming conventions (`g_`, `DT_`, PascalCase) coerenti con standard MQL5. Canonical file order compatibile con MetaEditor.

**Structure Alignment:** Singolo file `.mq5` supporta tutte le decisioni. Sandbox `MQL5\Files\` è l'unico path FileWrite disponibile — nessun conflitto.

### Requirements Coverage Validation ✅

**Functional Requirements — Phase 1 (FR1–FR24):**

| Group | FRs | Coverage |
|-------|-----|----------|
| Pattern Detection | FR1–FR5 | `DetectPattern()` su bars [1],[2] con `iTime()` guard ✅ |
| Alert & Notification | FR6–FR10 | Fan-out: OBJ_ARROW + SendMail() + continue-on-fail ✅ |
| Signal Logging | FR11–FR13 | `FileWrite()` append, schema fisso, FILE_UNICODE ✅ |
| Configuration | FR14–FR19 | `input` parameters con defaults espliciti ✅ |
| System Status | FR20–FR22 | `OBJ_LABEL` in OnInit()/OnDeinit() ✅ |
| Data Mode | FR23–FR24 | MT5 Strategy Tester (nessun codice aggiuntivo) ✅ |
| Phase 2 | FR25–FR26 | Deferred by design ✅ |

**Non-Functional Requirements (NFR1–NFR10):** copertura 100%

| NFR | Coverage |
|-----|----------|
| NFR1 | iTime() su primo tick nuova barra ✅ |
| NFR2 | ObjectCreate() primo nel fan-out (< 1s) ✅ |
| NFR3–NFR4 | SendMail() + FileWrite() stessa barra (< 5s) ✅ |
| NFR5 | Singolo file, computazione minima ✅ |
| NFR6 | Credenziali in MT5 Options — mai nel .mq5 ✅ |
| NFR7 | Sandbox MQL5\Files\ — solo utente locale ✅ |
| NFR8–NFR10 | Continue-and-log per tutti gli output secondari ✅ |

### Gap Analysis Results

**Critical Gaps:** nessuno.

**Important (non-blocking):**
- `sets/DT_SignalEA_default.set` va creato manualmente dal trader dopo il primo avvio — documentare in `user-guide.md`.

**Nice-to-have (deferred):** Rotazione CSV per file di grandi dimensioni — non richiesta dal PRD.

### Architecture Completeness Checklist

**Requirements Analysis**
- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**Architectural Decisions**
- [x] Critical decisions documented with versions
- [x] Technology stack fully specified (MQL5, MT5 native)
- [x] Integration patterns defined
- [x] Performance considerations addressed

**Implementation Patterns**
- [x] Naming conventions established
- [x] Structure patterns defined (canonical file order)
- [x] Communication patterns specified (fan-out sequence)
- [x] Process patterns documented (continue-and-log)

**Project Structure**
- [x] Complete directory structure defined
- [x] Component boundaries established (4 helper functions)
- [x] Integration points mapped (chart, SMTP, CSV)
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status: READY FOR IMPLEMENTATION** — tutti i 16 item verificati, nessun Critical Gap aperto.

**Confidence Level:** High

**Key Strengths:**
- Pattern di rilevamento barra chiusa robusto e universale (iTime comparison)
- Isolamento errori completo: SMTP/CSV failure non bloccano mai il detector
- Zero dipendenze esterne per Phase 1 — tutto MQL5 nativo
- Hot-reload config nativo MT5 senza codice aggiuntivo
- NFR6 soddisfatto senza alcun file di configurazione custom

**Areas for Future Enhancement (Phase 2):**
- Live mode broker connection handling
- Multi-pair architecture extension
- Audio alert integration
- CSV rotation strategy

### Implementation Handoff

**AI Agent Guidelines:**
- Seguire il canonical file order per il file `.mq5`
- Usare sempre `g_` per variabili globali, `DT_` per oggetti chart
- Bar index: [1] = ultima chiusa, [2] = precedente — mai [0]
- Commenti bilingual su ogni riga non banale: `// English / Italiano`
- Verificare sempre il return value di SendMail() e FileWrite()
- Usare BodyInPips() helper — nessuna formula pip inline

**First Implementation Priority:**
Creare `src/DT_SignalEA.mq5` in MetaEditor: `File → New → Expert Advisor` → scaffold con 4 handler base (OnInit, OnDeinit, OnTick, OnDeinit) → aggiungere input parameters block → aggiungere g_* globals.
