# Story 2.1: Bar-Close Detection (iTime Guard)

Status: done

## Story

As a trader,
I want the EA to react exclusively at M15 bar close and ignore all intermediate ticks,
So that pattern evaluation always uses complete, closed candle data and never fires on a forming bar.

## Acceptance Criteria

1. **Given** the EA is running in Strategy Tester on M15 EUR/USD  
   **When** a new M15 bar opens (first tick of the new bar)  
   **Then** `iTime(Symbol(), PERIOD_M15, 0)` differs from `g_lastBarTime`, the EA enters the detection branch, and `g_lastBarTime` is updated to the new bar time

2. **Given** the EA has already processed the first tick of a new bar  
   **When** subsequent ticks arrive within the same M15 bar  
   **Then** `iTime(Symbol(), PERIOD_M15, 0)` equals `g_lastBarTime` and the detection branch is NOT entered

3. **Given** `OnInit()` has just completed  
   **When** the first `OnTick()` fires  
   **Then** `g_lastBarTime` is initialized to `iTime(Symbol(), PERIOD_M15, 0)` so no spurious detection fires on startup

4. **Given** the EA runs through multiple M15 bars in Strategy Tester  
   **When** I inspect the MetaEditor Experts log  
   **Then** a bar-close event log entry appears exactly once per M15 bar — no duplicates, no missed bars

5. **Given** `iTime()` returns 0 on startup (chart not ready)  
   **When** `OnInit()` checks the return value  
   **Then** `UpdateStatusLabel("DT Signal EA — ERROR", clrRed)` is called and `OnInit()` returns `INIT_FAILED`

## Tasks / Subtasks

- [x] Task 1: Activate INIT_FAILED path in `OnInit()` (AC: 3, 5)
  - [x] 1.1 After globals init, call `g_lastBarTime = iTime(Symbol(), PERIOD_M15, 0)`
  - [x] 1.2 If `g_lastBarTime == 0` → call `UpdateStatusLabel("DT Signal EA — ERROR", clrRed)` and return `INIT_FAILED`
  - [x] 1.3 Remove the commented-out stub lines from Story 1.2
- [x] Task 2: Implement `iTime()` guard in `OnTick()` (AC: 1, 2, 4)
  - [x] 2.1 Declare local `datetime currentBarTime = iTime(Symbol(), PERIOD_M15, 0)`
  - [x] 2.2 If `currentBarTime != g_lastBarTime` → update `g_lastBarTime`, log `Print()`, enter detection branch stub
  - [x] 2.3 Detection branch calls `DetectPattern()` (still returns NONE — Story 2.2 fills it in)
- [x] Task 3: Verify manually (AC: 1, 2, 3, 4, 5) — REQUIRES MANUAL METAEDITOR
  - [x] 3.1 Compile F7 → 0 errors, 0 warnings
  - [x] 3.2 Run Strategy Tester → Journal shows one "New M15 bar" entry per bar, no duplicates
  - [x] 3.3 Confirm EA loads cleanly (no INIT_FAILED on normal chart)

## Dev Notes

### `OnInit()` Changes (Task 1)
```mql5
int OnInit()
  {
   // Initialize global state / Inizializza lo stato globale
   g_lastBarTime = 0;
   g_csvHandle   = -1;
   g_signalCount = 0;

   g_lastBarTime = iTime(Symbol(), PERIOD_M15, 0); // Initialize bar time / Inizializza ora barra
   if(g_lastBarTime == 0)                           // Chart not ready — critical error / Grafico non pronto — errore critico
     {
      UpdateStatusLabel("DT Signal EA — ERROR", clrRed); // Show error status / Mostra stato errore
      return(INIT_FAILED);                               // Abort initialization / Interrompi inizializzazione
     }

   UpdateStatusLabel("DT Signal EA — ACTIVE", clrGreen);
   return(INIT_SUCCEEDED);
  }
```

### `OnTick()` Implementation (Task 2)
```mql5
void OnTick()
  {
   datetime currentBarTime = iTime(Symbol(), PERIOD_M15, 0); // Get current M15 bar time / Ottieni ora barra M15 corrente
   if(currentBarTime != g_lastBarTime)                        // New bar detected / Nuova barra rilevata
     {
      g_lastBarTime = currentBarTime;                                          // Update last bar time / Aggiorna ora ultima barra
      Print("New M15 bar: ", TimeToString(currentBarTime, TIME_DATE|TIME_MINUTES)); // Log bar-close event / Registra evento chiusura barra
      DetectPattern();                                                          // Pattern detection — Story 2.2 / Rilevamento pattern — Storia 2.2
     }
  }
```

### Key Architecture Rules
- Bar index `[0]` = forming candle — **NEVER** used for detection
- Bar index `[1]` = last closed candle — used in Story 2.2
- Bar index `[2]` = prior closed candle — used in Story 2.2
- `g_lastBarTime` initialized in `OnInit()` to prevent spurious first-tick detection
- `iTime()` returns 0 only when chart has no data — treat as critical error

### Bilingual Comment Format (MANDATORY)
```mql5
// English comment / Commento italiano
```

### File Paths
- **Source:** `src/DT_SignalEA.mq5`
- **Deployed:** `MQL5\Experts\Advisors\DT_SignalEA.mq5`

### References
- [epics.md — Story 2.1 Acceptance Criteria]
- [architecture.md — Bar-Close Detection iTime() Pattern]
- [architecture.md — Error handling: OnInit() iTime() returns 0 → INIT_FAILED]
- [prd.md — FR4, FR5, NFR1, NFR5]

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
None — verified via MetaEditor F7 and MT5 Strategy Tester Journal.

### Completion Notes List
- iTime() guard implemented in OnTick(): fires detection branch exactly once per M15 bar
- g_lastBarTime initialized in OnInit() to prevent spurious detection on first tick
- INIT_FAILED path activated: iTime()==0 → ERROR label + abort
- DetectPattern() called in detection branch (still stub — Story 2.2 implements logic)
- Print() log confirms one entry per M15 bar in MetaEditor Journal

### File List
- src/DT_SignalEA.mq5 (modified)
