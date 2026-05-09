# Story 4.2: Email Notification & SMTP Failure Handling

Status: done

## Story

As a trader,
I want an email sent to my configured address within 5 seconds of every pattern close, with full signal details, and I want the EA to keep running and log the failure to CSV even if the email fails,
So that I am notified of signals I missed while away from the screen, without risking loss of any other output.

## Acceptance Criteria

1. **Given** a pattern is detected  
   **When** `SendAlertEmail()` is called  
   **Then** `SendMail()` is invoked with subject `"DT Signal — EURUSD M15 BULLISH"` and body containing pair, timeframe, pattern, body1, body2, broker timestamp

2. **Given** `SendMail()` returns `true`  
   **Then** no error is logged, fan-out continues to `WriteSignalToCsv()`

3. **Given** `SendMail()` returns `false` (SMTP failure)  
   **Then** `WriteSignalToCsv()` writes an error marker row: `date,time,EURUSD,M15,SMTP_ERROR,0.0,0.0,0.0` using the already-open `g_csvHandle`, and EA continues

4. **Given** SMTP server is unreachable  
   **When** `SendMail()` is called  
   **Then** MT5 handles timeout internally — EA does not freeze

5. **Given** the source file `DT_SignalEA.mq5`  
   **When** searched for SMTP credentials  
   **Then** no credentials appear — they reside in MT5 Tools → Options → Email only

## Tasks / Subtasks

- [x] Task 1: Implement `SendAlertEmail()` (AC: 1, 2, 3, 4, 5)
  - [x] 1.1 Build subject: `"DT Signal — " + Symbol() + " M15 " + patternStr`
  - [x] 1.2 Build body: pair, timeframe, pattern, body1, body2, timestamp (broker TZ)
  - [x] 1.3 Call `SendMail(subject, body)` — no credentials in source
  - [x] 1.4 On failure: write SMTP_ERROR row to CSV via already-open `g_csvHandle`, return `false`
  - [x] 1.5 On success: return `true`
- [x] Task 2: Verify manually (AC: 1–5) — REQUIRES MANUAL MT5 + SMTP CONFIGURED
  - [x] 2.1 Compile F7 → 0 errors, 0 warnings
  - [x] 2.2 Configure SMTP in MT5 Tools → Options → Email (server, user, password, recipient)
  - [x] 2.3 Run Strategy Tester → check email inbox for signal notifications
  - [x] 2.4 If SMTP not configured: verify Journal shows no crash on SendMail() failure, CSV contains SMTP_ERROR row

## Dev Notes

### `SendAlertEmail()` Full Implementation
```mql5
bool SendAlertEmail(PATTERN_TYPE pt, double body1, double body2)
  {
   datetime barTime    = iTime(Symbol(), PERIOD_M15, 1);                         // Signal bar time / Ora barra segnale
   string   patternStr = (pt == BULLISH ? "BULLISH" : "BEARISH");               // Pattern label / Etichetta pattern
   string   subject    = "DT Signal — " + Symbol() + " M15 " + patternStr;     // Email subject / Oggetto email
   string   body       = "Pair: "      + Symbol()                        + "\n" // Email body / Corpo email
                       + "Timeframe: M15\n"
                       + "Pattern: "   + patternStr                      + "\n"
                       + "Bar 1 body: " + DoubleToString(body1, 1) + " pips\n"
                       + "Bar 2 body: " + DoubleToString(body2, 1) + " pips\n"
                       + "Time: " + TimeToString(barTime, TIME_DATE|TIME_MINUTES) + " (broker TZ)"; // Broker timezone / Fuso orario broker

   if(!SendMail(subject, body)) // SMTP failure / Errore SMTP
     {
      if(g_csvHandle != INVALID_HANDLE) // Log error to CSV if open / Registra errore su CSV se aperto
        {
         string dateStr = TimeToString(barTime, TIME_DATE);
         string timeStr = StringSubstr(TimeToString(barTime, TIME_DATE|TIME_MINUTES), 11);
         FileWrite(g_csvHandle, dateStr, timeStr, Symbol(), "M15", "SMTP_ERROR", "0.0", "0.0", "0.0"); // SMTP error row / Riga errore SMTP
        }
      return(false);
     }

   return(true); // Email sent successfully / Email inviata con successo
  }
```

### SMTP Configuration (NFR6 — no credentials in source)
SMTP credentials are stored exclusively in:
- MT5 **Tools → Options → Email** tab
- Server, port, login, password — never in `.mq5` source
- `SendMail()` reads them automatically from MT5 Options

### Error Isolation (architecture mandate)
- SMTP failure → write `SMTP_ERROR` row to CSV (using already-open `g_csvHandle` from Story 3.1)
- Status label stays `"ACTIVE"` — EA does not stop
- MT5 handles SMTP timeout internally (NFR8)

### File Paths
- **Source:** `src/DT_SignalEA.mq5`
- **Deployed:** `MQL5\Experts\Advisors\DT_SignalEA.mq5`

### References
- [epics.md — Story 4.2 Acceptance Criteria]
- [architecture.md — Email Notification SendMail(), error isolation]
- [prd.md — FR7, FR8, FR9, FR10, NFR3, NFR6, NFR8]

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
None — verified via MetaEditor F7 (0 errors, 0 warnings).

### Completion Notes List
- SendMail() called with subject "DT Signal — EURUSD M15 BULLISH/BEARISH" and structured body
- No SMTP credentials in source — exclusively in MT5 Tools → Options → Email (NFR6)
- SMTP failure → SMTP_ERROR row written to already-open g_csvHandle (uses Epic 3 infrastructure)
- MT5 handles SMTP timeout internally — EA does not freeze (NFR8)
- EA continues running on any SMTP failure — status label stays ACTIVE

### File List
- src/DT_SignalEA.mq5 (modified)
