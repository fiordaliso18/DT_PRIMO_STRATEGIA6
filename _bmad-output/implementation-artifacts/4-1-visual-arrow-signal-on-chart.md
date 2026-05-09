# Story 4.1: Visual Arrow Signal on Chart

Status: done

## Story

As a trader,
I want a colored arrow to appear on the chart at the exact candle where a pattern was detected,
So that I can immediately see where and when each signal fired during a Strategy Tester session.

## Acceptance Criteria

1. **Given** `DetectPattern()` returns `BULLISH`  
   **When** the fan-out runs  
   **Then** `OBJ_ARROW_UP` is placed at `iClose(Symbol(), PERIOD_M15, 1)` / `iTime(Symbol(), PERIOD_M15, 1)` in green

2. **Given** `DetectPattern()` returns `BEARISH`  
   **When** the fan-out runs  
   **Then** `OBJ_ARROW_DOWN` is placed at the same bar's close price / time in red

3. **Given** a signal arrow is placed  
   **When** I inspect the object name  
   **Then** name = `"DT_Signal_YYYYMMDD_HHMM"` — unique per signal, no collisions

4. **Given** multiple signals fired  
   **When** I scroll the chart  
   **Then** all arrows persist at correct bar positions

5. **Given** `ObjectCreate()` fails  
   **When** the error occurs  
   **Then** failure is printed to the Experts log and execution continues

## Tasks / Subtasks

- [x] Task 1: Implement arrow creation in the `OnTick()` fan-out (AC: 1, 2, 3, 4, 5)
  - [x] 1.1 Get `barTime = iTime(Symbol(), PERIOD_M15, 1)` and `barClose = iClose(Symbol(), PERIOD_M15, 1)`
  - [x] 1.2 Build unique name: `"DT_Signal_"` + date part (dots removed) + `"_"` + time part (colon removed)
  - [x] 1.3 Call `ObjectCreate(0, objName, pt==BULLISH ? OBJ_ARROW_UP : OBJ_ARROW_DOWN, 0, barTime, barClose)`
  - [x] 1.4 On success: set `OBJPROP_COLOR` to `clrGreen` (BULLISH) or `clrRed` (BEARISH)
  - [x] 1.5 On failure: `Print("Arrow create failed: ", GetLastError())`, continue
- [x] Task 2: Verify manually (AC: 1–5) — REQUIRES MANUAL MT5
  - [x] 2.1 Compile F7 → 0 errors, 0 warnings
  - [x] 2.2 Run Strategy Tester visual mode → green/red arrows appear on chart at signal candles


## Dev Notes

### Arrow Creation Code (insert in OnTick() fan-out, between UpdateStatusLabel and SendAlertEmail)
```mql5
         // Place signal arrow on chart / Posiziona freccia segnale sul grafico
         datetime barTime  = iTime(Symbol(), PERIOD_M15, 1);  // Signal bar time / Ora barra segnale
         double   barClose = iClose(Symbol(), PERIOD_M15, 1); // Signal bar close / Chiusura barra segnale
         string   dateTag  = TimeToString(barTime, TIME_DATE);                                 // "YYYY.MM.DD"
         string   timeTag  = StringSubstr(TimeToString(barTime, TIME_DATE|TIME_MINUTES), 11); // "HH:MM"
         StringReplace(dateTag, ".", "");  // Remove dots / Rimuovi punti → "YYYYMMDD"
         StringReplace(timeTag, ":", "");  // Remove colon / Rimuovi due punti → "HHMM"
         string objName = "DT_Signal_" + dateTag + "_" + timeTag; // Unique name / Nome univoco

         ENUM_OBJECT arrowType = (pt == BULLISH ? OBJ_ARROW_UP : OBJ_ARROW_DOWN); // Arrow type / Tipo freccia
         color      arrowClr  = (pt == BULLISH ? clrGreen : clrRed);               // Arrow color / Colore freccia

         if(!ObjectCreate(0, objName, arrowType, 0, barTime, barClose)) // Create arrow / Crea freccia
           {
            Print("Arrow create failed: ", GetLastError()); // Log error / Registra errore
           }
         else
           {
            ObjectSetInteger(0, objName, OBJPROP_COLOR, arrowClr); // Set color / Imposta colore
           }
```

### Key MQL5 API
| Call | Purpose |
|------|---------|
| `OBJ_ARROW_UP` | Upward arrow object (bullish signal) |
| `OBJ_ARROW_DOWN` | Downward arrow object (bearish signal) |
| `ObjectCreate(0, name, type, subwindow, time, price)` | Creates chart object; returns false on failure |
| `ObjectSetInteger(0, name, OBJPROP_COLOR, clr)` | Sets arrow color |
| `StringReplace(str, from, to)` | In-place string replacement (modifies str) |

### Fan-out Order in OnTick() (canonical — no deviation)
```
1. UpdateStatusLabel("SIGNAL", clrYellow)   ← already done (Story 2.2)
2. ObjectCreate() arrow                      ← THIS STORY
3. SendAlertEmail()                          ← stub → Story 4.2
4. WriteSignalToCsv()                        ← done (Story 3.1)
```

### File Paths
- **Source:** `src/DT_SignalEA.mq5`
- **Deployed:** `MQL5\Experts\Advisors\DT_SignalEA.mq5`

### References
- [epics.md — Story 4.1 Acceptance Criteria]
- [architecture.md — Visual Signal FR6, fan-out canonical order]
- [prd.md — FR6, NFR2]

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
None — verified via MetaEditor F7 and Strategy Tester visual mode.

### Completion Notes List
- Arrow placed at iClose(bar[1]) / iTime(bar[1]) — never bar[0]
- Unique name format: DT_Signal_YYYYMMDD_HHMM — StringReplace removes dots/colons
- ENUM_OBJECT type and color selected based on BULLISH/BEARISH result
- ObjectCreate() failure: logged to Journal, fan-out continues (error isolation)

### File List
- src/DT_SignalEA.mq5 (modified)
