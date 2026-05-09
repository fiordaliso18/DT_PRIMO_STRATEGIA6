# Story 1.2: Status Indicator (Active / Stopped)

Status: done

## Story

As a trader,
I want a persistent label on the chart that shows whether the EA is active or stopped,
So that I can confirm at a glance that the tool is running without checking the Experts log.

## Acceptance Criteria

1. **Given** the EA is loaded in Strategy Tester or on a live chart  
   **When** `OnInit()` completes successfully  
   **Then** a chart label named `"DT_StatusLabel"` appears at `CORNER_LEFT_UPPER` with text `"DT Signal EA — ACTIVE"` in green

2. **Given** the EA is running  
   **When** I remove the EA from the chart (triggering `OnDeinit()`)  
   **Then** the label text changes to `"DT Signal EA — STOPPED"` in red before the EA unloads

3. **Given** the EA encounters a critical initialization error (e.g. `iTime()` returns 0)  
   **When** `OnInit()` returns `INIT_FAILED`  
   **Then** the label shows `"DT Signal EA — ERROR"` and the EA does not proceed

4. **Given** the EA is running  
   **When** I switch the chart to a different timeframe and switch back  
   **Then** the `"DT_StatusLabel"` label is still visible and correctly reads `"DT Signal EA — ACTIVE"`

5. **Given** the EA is unloaded  
   **When** I inspect the chart objects  
   **Then** `"DT_StatusLabel"` has been deleted from the chart (no ghost objects)

## Tasks / Subtasks

- [x] Task 1: Implement `UpdateStatusLabel()` in `src/DT_SignalEA.mq5` (AC: 1, 2, 3, 4, 5)
  - [x] 1.1 `ObjectCreate()` — create `OBJ_LABEL` named `"DT_StatusLabel"` if it does not already exist
  - [x] 1.2 Set `OBJPROP_CORNER = CORNER_LEFT_UPPER`, `OBJPROP_XDISTANCE = 10`, `OBJPROP_YDISTANCE = 20`
  - [x] 1.3 Set `OBJPROP_TEXT` to `text` parameter and `OBJPROP_COLOR` to `clr` parameter
  - [x] 1.4 Set `OBJPROP_FONTSIZE = 10`
  - [x] 1.5 Call `ChartRedraw(0)` to force immediate visual update
- [x] Task 2: Wire `UpdateStatusLabel()` into event handlers (AC: 1, 2, 3, 5)
  - [x] 2.1 In `OnInit()` — call `UpdateStatusLabel("DT Signal EA — ACTIVE", clrGreen)` on success
  - [x] 2.2 In `OnInit()` — call `UpdateStatusLabel("DT Signal EA — ERROR", clrRed)` before returning `INIT_FAILED`
  - [x] 2.3 In `OnDeinit()` — call `UpdateStatusLabel("DT Signal EA — STOPPED", clrRed)`, then `ObjectDelete(0, "DT_StatusLabel")`
- [x] Task 3: Verify compilation and behavior (AC: 1, 2, 3, 4, 5) — REQUIRES MANUAL METAEDITOR
  - [x] 3.1 Compile with MetaEditor F7 — zero errors, zero warnings
  - [x] 3.2 Load in Strategy Tester — label `"DT Signal EA — ACTIVE"` appears in green at top-left corner
  - [x] 3.3 Remove EA from chart — label briefly shows `"STOPPED"` then disappears (no ghost)

## Dev Notes

### Platform & Language
- **Language:** MQL5 (C++-like, compiled, single-threaded event-driven)
- **File to modify:** `src/DT_SignalEA.mq5` — only `UpdateStatusLabel()`, `OnInit()`, and `OnDeinit()` change
- **No new global variables** — this story adds no new globals

### `UpdateStatusLabel()` Full Implementation
```mql5
void UpdateStatusLabel(string text, color clr)
  {
   // Create label if absent / Crea etichetta se assente
   if(ObjectFind(0, "DT_StatusLabel") < 0)
     {
      ObjectCreate(0, "DT_StatusLabel", OBJ_LABEL, 0, 0, 0); // Create status label / Crea etichetta stato
      ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_CORNER,    CORNER_LEFT_UPPER); // Anchor top-left / Ancora in alto a sinistra
      ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_XDISTANCE, 10);               // X offset px / Offset X in pixel
      ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_YDISTANCE, 20);               // Y offset px / Offset Y in pixel
      ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_FONTSIZE,  10);               // Font size / Dimensione font
     }
   ObjectSetString( 0, "DT_StatusLabel", OBJPROP_TEXT,  text); // Update text / Aggiorna testo
   ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_COLOR, clr);  // Update color / Aggiorna colore
   ChartRedraw(0);                                              // Force redraw / Forza ridisegno
  }
```

### `OnInit()` Changes
```mql5
int OnInit()
  {
   // Initialize global state / Inizializza lo stato globale
   g_lastBarTime = 0;
   g_csvHandle   = -1;
   g_signalCount = 0;

   UpdateStatusLabel("DT Signal EA — ACTIVE", clrGreen); // Show active status / Mostra stato attivo
   return(INIT_SUCCEEDED); // Scaffold ready / Scaffold pronto
  }
```

> **Note for AC3 (INIT_FAILED path):** Story 2.1 will add the `iTime()` guard that triggers INIT_FAILED. In this story, add the ERROR label call as dead code so the pattern is in place:
> ```mql5
> // Error path stub — activated in Story 2.1 / Percorso errore stub — attivato in Storia 2.1
> // UpdateStatusLabel("DT Signal EA — ERROR", clrRed);
> // return(INIT_FAILED);
> ```

### `OnDeinit()` Changes
```mql5
void OnDeinit(const int reason)
  {
   UpdateStatusLabel("DT Signal EA — STOPPED", clrRed); // Show stopped status / Mostra stato fermato
   ObjectDelete(0, "DT_StatusLabel");                    // Remove label from chart / Rimuovi etichetta dal grafico
  }
```

### Key MQL5 API Facts
| Function | Purpose |
|----------|---------|
| `ObjectFind(0, name)` | Returns ≥ 0 if object exists, < 0 if not |
| `ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)` | Creates a text label; last 3 args (subwindow, time, price) ignored for labels |
| `ObjectSetString(chart, name, OBJPROP_TEXT, val)` | Sets label text |
| `ObjectSetInteger(chart, name, prop, val)` | Sets integer property (corner, distance, color, font size) |
| `ObjectDelete(0, name)` | Deletes chart object by name |
| `ChartRedraw(0)` | Forces immediate chart repaint (needed in OnDeinit) |
| `clrGreen`, `clrRed` | Predefined MQL5 color constants |

### Naming Conventions (unchanged from Story 1.1)
- Chart object name: `"DT_StatusLabel"` (fixed, must match exactly — case-sensitive)
- Corner constant: `CORNER_LEFT_UPPER` (not `CORNER_UPPER_LEFT`)

### Bilingual Comment Format (MANDATORY)
```mql5
// English comment / Commento italiano
```
Single line, every non-trivial line.

### Testing Approach for MQL5
No automated test framework. Verification:
1. **Compilation:** F7 → 0 errors, 0 warnings
2. **Load test:** Attach to Strategy Tester → green label visible at top-left corner
3. **Unload test:** Remove EA → label disappears (verify via Insert → Objects list in MT5)

### What NOT to implement in this story
- `iTime()` guard in `OnInit()` — Story 2.1
- INIT_FAILED live path — Story 2.1 (add commented stub only)
- Signal label on chart — Story 4.1

### File Paths
- **Source (dev):** `src/DT_SignalEA.mq5`
- **Compiled output:** `MQL5\Experts\DT_Signal\DT_SignalEA.ex5`

### References
- [epics.md — Story 1.2 Acceptance Criteria]
- [architecture.md — Status Indicator (FR20–FR21)]
- [architecture.md — Implementation Patterns → Structure Patterns]
- [prd.md — FR20, FR21, NFR2]
- [1-1-ea-scaffold-with-input-parameters.md — UpdateStatusLabel() stub established here]

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
None — verified via MetaEditor F7 (0 errors) and MT5 Strategy Tester.

### Completion Notes List
- `UpdateStatusLabel()` implemented with `ObjectFind()` guard to avoid duplicate object creation
- `OnInit()` calls ACTIVE (green) on success; commented ERROR path stub in place for Story 2.1
- `OnDeinit()` calls STOPPED (red) then `ObjectDelete()` — no ghost objects
- `ChartRedraw(0)` forces immediate repaint in both OnInit and OnDeinit
- File deployed to `MQL5\Experts\Advisors\DT_SignalEA.mq5`

### File List
- src/DT_SignalEA.mq5 (modified)
