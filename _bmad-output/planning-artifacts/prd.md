---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish, step-12-complete]
completedAt: '2026-05-05'
releaseMode: phased
classification:
  projectType: signal_tool
  domain: fintech
  complexity: high
  projectContext: greenfield
  currencyPairs: [EUR/USD]
  alertTypes: [visual, email, csv]
  modes: [realtime, test]
  timeframe: M15
inputDocuments: []
workflowType: 'prd'
---

# Product Requirements Document — Forex Signal Tool

**Author:** Primo
**Date:** 2026-05-05

---

## Executive Summary

A forex signal tool that monitors M15 candles on EUR/USD and alerts the trader when two consecutive closed candles of the same direction (both bullish or both bearish) have a body exceeding a configurable pip threshold. Alerts are delivered visually on the chart and via email; every signal is logged to CSV. The MVP operates in test mode (historical data replay); live market feed is Phase 2.

### What Makes This Special

Single-pattern, single-pair, zero-noise detection. No subscriptions, no dashboard overload — just the exact two-candle condition the trader wants to act on, signalled at candle close on M15.

---

## Project Classification

| Field | Value |
|-------|-------|
| **Project Type** | Forex Signal Tool |
| **Domain** | Fintech — Forex Trading |
| **Currency Pair** | EUR/USD (Phase 1 hardcoded) |
| **Timeframe** | M15 |
| **Complexity** | High |
| **Project Context** | Greenfield |
| **Operating Modes** | Test (MVP) · Live (Phase 2) |
| **Alert Channels** | Visual chart · Email · CSV log |

---

## Success Criteria

### User Success
- Trader does not miss a pattern entry — signal fires at M15 candle close without active monitoring.
- Visual signal on chart is immediate and unambiguous.

### Business Success
- Tool validates correctly in test mode before live use.
- Every pattern occurrence with body ≥ configured threshold is signalled (zero miss).

### Technical Success
- Pattern detected at close of current M15 candle — no delay to next tick.
- Stable operation across both modes (test and live).

### Measurable Outcomes
- 100% of qualifying patterns detected within the current candle close.
- Email sent within 5 seconds of candle close.
- CSV row written within 5 seconds of candle close.

---

## Product Scope

### Phase 1 — MVP
- EUR/USD M15 pattern detection (hardcoded pair).
- Visual alert on chart at candle close.
- Email notification (configurable recipient, default: primo.brandi@gmail.com).
- CSV signal log (configurable path, UTF-8, includes broker timezone).
- Pip threshold configurable at runtime without restart (default: 20 pips).
- System status indicator on chart (active / stopped).
- Test mode: historical M15 data, offline replay.

### Phase 2 — Growth
- Live mode: real-time broker feed EUR/USD.
- Multi-pair architecture: additional currency pairs.
- Audio alert at pattern close.

### Phase 3 — Vision
- Multiple configurable patterns.
- Signal history dashboard.
- Session time and volume filters.

---

## User Journeys

### Journey 1 — Test Mode Validation (MVP · Success Path)

Marco wants to validate his strategy before going live. He loads historical M15 EUR/USD data, sets the threshold to 20 pips, and starts the tool in test mode. Signals appear on the chart at the correct candle positions. He verifies the logic matches his expectations, then moves to live.

### Journey 2 — Live Trading (Phase 2)

During a live session Marco is not watching the chart. When the pattern forms on M15, the signal appears at the close of the second candle and an email arrives. He evaluates market context and decides whether to enter — without having missed the moment. *(Phase 2)*

### Journey 3 — Threshold Reconfiguration (MVP · Edge Case)

Marco sets a 5-pip threshold and receives excessive signals. He edits the threshold in the tool configuration. The new value takes effect on the next candle — no restart required.

### Journey Requirements Summary

| Journey | Required Capabilities |
|---------|----------------------|
| Test mode validation | Historical data load · M15 replay · Visual signal · CSV log |
| Live trading *(Phase 2)* | Real-time feed · Candle-close detection · Visual signal · Email · CSV |
| Threshold reconfiguration | Runtime parameter change · Applied next candle · No restart |

---

## Domain-Specific Requirements

### Compliance
- No regulatory requirements — personal-use tool, no third-party data or money handling.

### Technical Constraints
- EUR/USD market data: no licensing restrictions.
- Historical data: downloaded from the internet and stored locally; test mode requires no active connection during replay.
- Live mode: active broker connection required.

### Integration
- Live feed: broker platform data channel.
- Email: SMTP server (configured credentials).
- Log: local file system (CSV).

### Risk Mitigations
- False negatives: mitigated by detection-on-closed-candle requirement.
- Threshold misconfiguration: mitigated by runtime reconfiguration without restart.
- Email failure: CSV log provides independent signal traceability; tool continues operating.

---

## Signal Tool Platform Requirements

### Platform
- Operating system: Windows.
- Updates: manual (trader replaces tool file and recompiles).

### System Integration

| System | Function |
|--------|----------|
| Trading platform | M15 data feed · Chart rendering · Visual signal |
| Email (SMTP) | Alert notification at pattern close |
| File system | CSV signal log |

### Offline Capability
- Test mode operates fully offline using pre-downloaded historical data.
- Live mode requires active broker connection.

### Multi-Pair Architecture
- Phase 1: EUR/USD hardcoded.
- Phase 2: architecture extended to support additional pairs without structural changes.

---

## Project Scoping

### MVP Strategy
**Approach:** Problem-solving MVP — minimum viable scope that validates the detection logic in test mode and proves the tool works before live deployment.

### Phase 1 — Must-Have Capabilities
- 2 consecutive same-color M15 closed candles · EUR/USD · hardcoded.
- Body ≥ configurable threshold (default 20 pips).
- Detection on closed candle only — not on forming candle.
- Visual chart signal · status indicator (active/stopped).
- Email alert (default: primo.brandi@gmail.com) · SMTP failure handled gracefully.
- CSV log with full fields including broker timezone.
- Test mode with offline historical data.
- Threshold modifiable at runtime without restart.

### Risk Mitigation
- **Technical:** Closed-candle detection is a hard requirement, testable in test mode before live.
- **Operational:** CSV log is independent of email — no signal is lost if SMTP fails.
- **Scope:** EUR/USD hardcoded in Phase 1 — no multi-pair complexity until Phase 2.

---

## Functional Requirements

### Pattern Detection

- **FR1:** The system detects two consecutive same-color M15 candles (both bullish or both bearish) on EUR/USD.
- **FR2:** The system evaluates each candle body in pips (close minus open absolute value).
- **FR3:** The system generates a signal only when both candle bodies exceed the configured threshold.
- **FR4:** The system performs detection exclusively on closed M15 candles.
- **FR5:** The system does not generate signals on candles still in formation.

### Alert & Notification

- **FR6:** The trader receives a visual signal on the chart at pattern close.
- **FR7:** The trader receives an email notification at pattern close.
- **FR8:** The email contains: pair, timeframe, pattern type (bullish/bearish), body size in pips, timestamp with broker timezone.
- **FR9:** Email is sent within 5 seconds of candle close.
- **FR10:** On SMTP failure, the system continues operating and records the error in the CSV log.

### Signal Logging

- **FR11:** The system writes every signal to a CSV file.
- **FR12:** CSV fields: date, time (broker timezone), pair, timeframe, pattern type, candle 1 body (pips), candle 2 body (pips), configured threshold.
- **FR13:** The CSV file is readable by external applications (e.g. Excel). Encoding: UTF-8.

### Configuration

- **FR14:** The trader configures the pip threshold before startup.
- **FR15:** The trader modifies the pip threshold at runtime without restart; the new value applies from the next candle.
- **FR16:** The trader configures the email recipient address.
- **FR17:** The trader configures the CSV file path.
- **FR18:** Default threshold: 20 pips.
- **FR19:** Default email recipient: primo.brandi@gmail.com.

### System Status

- **FR20:** The system displays its operational state (active / stopped) on the chart.
- **FR21:** The system updates the status indicator when it stops unexpectedly.
- **FR22:** The system remains operational after a runtime threshold change.

### Data Mode

- **FR23:** The trader starts the system in **test mode** using pre-downloaded offline M15 historical data.
- **FR24:** Test mode requires no internet connection during replay.
- **FR25:** The trader starts the system in **live mode** with real-time broker feed. *(Phase 2)*
- **FR26:** Live mode requires an active broker connection. *(Phase 2)*

---

## Non-Functional Requirements

### Performance

- **NFR1:** Pattern detected within the close of the current M15 candle — no delay to next tick.
- **NFR2:** Visual alert appears on chart within 1 second of candle close.
- **NFR3:** Email sent within 5 seconds of candle close.
- **NFR4:** CSV row written within 5 seconds of candle close.
- **NFR5:** Tool introduces no perceptible lag to the trading platform UI.

### Security

- **NFR6:** SMTP credentials stored securely — not in plaintext in source code.
- **NFR7:** CSV signal file accessible only to the local Windows user.

### Integration Resilience

- **NFR8:** Tool connects to the configured SMTP server and handles connection timeouts without crashing.
- **NFR9:** On CSV write error (full disk, permission denied), the tool continues operating and displays a visual warning.
- **NFR10:** Tool operates with any broker providing M15 EUR/USD data via the configured trading platform.
