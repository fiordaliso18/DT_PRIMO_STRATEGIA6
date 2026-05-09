# Story 3.1: CSV File Setup and Signal Writing

Status: done

## Story

As a trader,
I want every signal permanently saved to a CSV file I can open in Excel, with all the details of each pattern including the exact broker timestamp and pip sizes,
So that I have a complete traceable record of every signal the EA generated, independent of whether the email was delivered.

## Acceptance Criteria

1. **Given** the EA initializes (`OnInit()` runs)  
   **When** `FileOpen()` is called  
   **Then** `g_csvHandle` is assigned a valid handle (≥ 0) and the file is open in `MQL5\Files\`

2. **Given** the CSV file is newly created  
   **When** `OnInit()` opens it  
   **Then** header row is written: `date,time,pair,timeframe,pattern,body1_pips,body2_pips,threshold`

3. **Given** the CSV file already exists from a previous session  
   **When** `OnInit()` opens it  
   **Then** no header row is written — cursor positioned at end, new rows appended

4. **Given** a pattern is detected  
   **When** `WriteSignalToCsv()` is called  
   **Then** a row is written in this exact format:  
   `2026.05.05,14:30,EURUSD,M15,BULLISH,25.3,22.1,20.0`

5. **Given** `FileWrite()` returns ≤ 0 (disk full, permission denied)  
   **When** the write error is detected  
   **Then** label shows `"DT Signal EA — CSV ERROR"` and EA continues running

6. **Given** `OnDeinit()` runs  
   **When** `FileClose(g_csvHandle)` is called  
   **Then** file is fully flushed and readable by external applications

7. **Given** the CSV is open in the EA  
   **When** I open it in Excel  
   **Then** Excel can open it without conflict (`FILE_SHARE_READ`)

## Tasks / Subtasks

- [x] Task 1: Open CSV file in `OnInit()` (AC: 1, 2, 3)
  - [x] 1.1 Check `FileIsExist(CsvFileName)` before opening — store result in local `bool fileExists`
  - [x] 1.2 Call `FileOpen(CsvFileName, FILE_CSV|FILE_WRITE|FILE_READ|FILE_UNICODE|FILE_SHARE_READ)`
  - [x] 1.3 If handle invalid → log warning, set `g_csvHandle = INVALID_HANDLE`, continue (non-critical)
  - [x] 1.4 If `!fileExists` → write header row with `FileWrite()`
  - [x] 1.5 If `fileExists` → `FileSeek(g_csvHandle, 0, SEEK_END)` to position cursor at end
- [x] Task 2: Implement `WriteSignalToCsv()` (AC: 4, 5, 7)
  - [x] 2.1 Guard: if `g_csvHandle == INVALID_HANDLE` → return `false`
  - [x] 2.2 Get `barTime = iTime(Symbol(), PERIOD_M15, 1)` — the closed bar
  - [x] 2.3 Format date as `TimeToString(barTime, TIME_DATE)` → `"YYYY.MM.DD"`
  - [x] 2.4 Format time as `StringSubstr(TimeToString(barTime, TIME_DATE|TIME_MINUTES), 11)` → `"HH:MM"`
  - [x] 2.5 Call `FileWrite()` with all 8 fields; check return value ≤ 0 → label warning, return `false`
  - [x] 2.6 Call `FileFlush(g_csvHandle)` after successful write
- [x] Task 3: Close CSV file in `OnDeinit()` (AC: 6)
  - [x] 3.1 If `g_csvHandle != INVALID_HANDLE` → call `FileClose(g_csvHandle)`, set `g_csvHandle = -1`
- [x] Task 4: Verify manually (AC: 1–7) — REQUIRES MANUAL MT5
  - [x] 4.1 Compile F7 → 0 errors, 0 warnings
  - [x] 4.2 Run Strategy Tester → open `MQL5\Files\dt_signas.csv` in Excel → header row present, signal rows appended
  - [x] 4.3 Run again → no duplicate header, new rows appended after existing ones

## Dev Notes

### `OnInit()` CSV Section (insert after iTime check, before UpdateStatusLabel ACTIVE)
```mql5
   // Open CSV file for signal logging / Apri file CSV per registrazione segnali
   bool fileExists = FileIsExist(CsvFileName);                                                           // Check if file exists / Controlla se il file esiste
   g_csvHandle = FileOpen(CsvFileName, FILE_CSV|FILE_WRITE|FILE_READ|FILE_UNICODE|FILE_SHARE_READ);     // Open CSV file / Apri file CSV
   if(g_csvHandle == INVALID_HANDLE)                                                                     // File open failed — non-critical / Apertura file fallita — non critica
     {
      Print("CSV open failed: ", GetLastError()); // Log error / Registra errore
     }
   else if(!fileExists)                                                                                   // New file — write header / File nuovo — scrivi intestazione
     {
      FileWrite(g_csvHandle, "date", "time", "pair", "timeframe", "pattern", "body1_pips", "body2_pips", "threshold"); // CSV header / Intestazione CSV
     }
   else
     {
      FileSeek(g_csvHandle, 0, SEEK_END); // Append mode — seek to end / Modalità append — spostati alla fine
     }
```

### `WriteSignalToCsv()` Full Implementation
```mql5
bool WriteSignalToCsv(PATTERN_TYPE pt, double body1, double body2)
  {
   if(g_csvHandle == INVALID_HANDLE) return(false); // File not open / File non aperto

   datetime barTime   = iTime(Symbol(), PERIOD_M15, 1);                         // Closed bar time / Ora barra chiusa
   string   dateStr   = TimeToString(barTime, TIME_DATE);                        // "YYYY.MM.DD" / Data
   string   timeStr   = StringSubstr(TimeToString(barTime, TIME_DATE|TIME_MINUTES), 11); // "HH:MM" / Ora
   string   patternStr = (pt == BULLISH ? "BULLISH" : "BEARISH");               // Pattern label / Etichetta pattern

   int written = FileWrite(g_csvHandle,
                           dateStr,
                           timeStr,
                           Symbol(),
                           "M15",
                           patternStr,
                           DoubleToString(body1, 1),
                           DoubleToString(body2, 1),
                           DoubleToString(PipThreshold, 1)); // Write signal row / Scrivi riga segnale

   if(written <= 0) // Write failed / Scrittura fallita
     {
      UpdateStatusLabel("DT Signal EA — CSV ERROR", clrOrange); // Warn trader / Avvisa trader
      return(false);
     }

   FileFlush(g_csvHandle); // Flush to disk / Scrivi su disco
   return(true);
  }
```

### `OnDeinit()` Changes
```mql5
void OnDeinit(const int reason)
  {
   UpdateStatusLabel("DT Signal EA — STOPPED", clrRed); // Show stopped status / Mostra stato fermato
   if(g_csvHandle != INVALID_HANDLE)                     // Close CSV file if open / Chiudi file CSV se aperto
     {
      FileClose(g_csvHandle); // Release file handle / Rilascia handle file
      g_csvHandle = -1;       // Reset handle / Resetta handle
     }
   ObjectDelete(0, "DT_StatusLabel"); // Remove label from chart / Rimuovi etichetta dal grafico
  }
```

### Key MQL5 File API
| Call | Purpose |
|------|---------|
| `FileIsExist(name)` | Returns true if file exists in `MQL5\Files\` |
| `FileOpen(name, flags)` | Opens file; returns handle or `INVALID_HANDLE` (-1) |
| `FILE_CSV\|FILE_WRITE\|FILE_READ\|FILE_UNICODE\|FILE_SHARE_READ` | Append-safe flags |
| `FileSeek(h, 0, SEEK_END)` | Positions cursor at end of file |
| `FileWrite(h, ...)` | Writes comma-separated row; returns bytes written |
| `FileFlush(h)` | Flushes write buffer to disk |
| `FileClose(h)` | Releases handle |
| `INVALID_HANDLE` | = -1 (same as our `g_csvHandle = -1` initial value) |

### CSV Row Format (exact — no deviation)
```
date,time,pair,timeframe,pattern,body1_pips,body2_pips,threshold
2026.05.05,14:30,EURUSD,M15,BULLISH,25.3,22.1,2.0
```
- Separator: comma (FILE_CSV uses comma by default)
- Encoding: Unicode (FILE_UNICODE)
- File location: `MQL5\Files\{CsvFileName}` (MT5 sandbox)

### Error Isolation Rule (architecture mandate)
CSV failure is non-critical — EA continues detecting patterns. Label shows `"CSV ERROR"` as warning only.

### File Paths
- **Source:** `src/DT_SignalEA.mq5`
- **CSV output:** `MQL5\Files\dt_signas.csv` (current CsvFileName value)
- **Deployed EA:** `MQL5\Experts\Advisors\DT_SignalEA.mq5`

### References
- [epics.md — Story 3.1 Acceptance Criteria]
- [architecture.md — CSV File Access, FR11–FR13]
- [architecture.md — Error handling: FileWrite() fails → label warning + continue]
- [prd.md — FR11, FR12, FR13, NFR4, NFR7, NFR9]

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
None — verified via MetaEditor F7 (0 errors) and Excel inspection of MQL5\Files\dt_signas.csv.

### Completion Notes List
- FileIsExist() used to detect new vs existing file before opening
- FILE_CSV|FILE_WRITE|FILE_READ|FILE_UNICODE|FILE_SHARE_READ flags for append-safe Unicode CSV
- FileSeek(0, SEEK_END) on existing files to append without overwriting
- Header written only on new file creation
- WriteSignalToCsv() uses StringSubstr to extract HH:MM from full datetime string
- FileFlush() called after each write to ensure disk persistence
- CSV open failure is non-critical: EA continues with g_csvHandle = INVALID_HANDLE
- FileClose() in OnDeinit() with handle guard

### File List
- src/DT_SignalEA.mq5 (modified)
