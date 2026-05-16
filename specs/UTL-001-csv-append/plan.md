---
feature: UTL-001
title: Scrittura CSV in Append — Pattern MQL5
type: plan
status: implemented
release: MVP
layer: implementation
language: English + Italian comments
platform: MT5 / MQL5
---
# UTL-001 — Scrittura CSV in Append · IMPLEMENTAZIONE

---

## Problema

`FileSeek(handle, 0, SEEK_END)` non funziona con `FILE_CSV` in MQL5.
`FILE_WRITE` da solo tronca il file esistente.

Pattern verificato su terminale reale con `prova.mq5` (Advisors/prova.mq5).

---

## Pattern Corretto

```mql5
void AppendToCSV(string filename, string separator)
{
   // [UTL-001-R001] Prima esecuzione: crea file con intestazione
   if(!FileIsExist(filename, FILE_COMMON))
   {
      int fi = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, separator);
      if(fi == INVALID_HANDLE) { /* gestisci errore */ return; }
      FileWrite(fi, "Col1", "Col2", /* ... intestazione ... */);
      FileClose(fi);
   }

   // [UTL-001-R003] Apertura senza troncamento
   int fh = FileOpen(filename, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, separator);
   if(fh == INVALID_HANDLE) { /* gestisci errore */ return; }

   // [UTL-001-R004] Seek alla fine tramite offset assoluto — SEEK_END non funziona con FILE_CSV
   ulong size = FileSize(fh);
   FileSeek(fh, (long)size, SEEK_SET);

   // [UTL-001-R005] Scrittura normale
   FileWrite(fh, "dato1", "dato2" /* ... */);

   // [UTL-001-R006] Chiusura obbligatoria
   FileClose(fh);
}
```

---

## Perché FILE_COMMON

| Flag | Percorso | Problema |
|---|---|---|
| *(nessuno)* | `Agent-<ip>-<port>\MQL5\Files\` | Ogni Tester Agent ha la sua sandbox — file non condiviso tra run diversi |
| `FILE_COMMON` | `%PUBLIC%\Documents\MetaTrader 5\MQL5\Files\` | Condiviso tra tutti gli Agent e il terminale live ✓ |

---

## Implementazione in CS6Trader

Il pattern è applicato in `CS6Trader::WriteTradesToCSV()`:

```mql5
void CS6Trader::WriteTradesToCSV()
{
   string filename = "S6_trades.csv";

   // [UTL-001-R001] Crea file con intestazione se non esiste
   if(!FileIsExist(filename, FILE_COMMON))
   {
      int fi = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ';');
      if(fi == INVALID_HANDLE)
      { Log("ERROR | CSV create failed | Code: " + (string)GetLastError()); return; }
      FileWrite(fi, "Trade", "EntryDate", "EntryPrice", "ExitDate", "ExitPrice",
                "Lots", "Profit", "DurationDays", "Reason");
      FileClose(fi);
   }

   // [UTL-001-R003] [UTL-001-R004] Apertura in append
   int fh = FileOpen(filename, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ';');
   if(fh == INVALID_HANDLE)
   { Log("ERROR | CSV open failed | Code: " + (string)GetLastError()); return; }
   ulong size = FileSize(fh);
   FileSeek(fh, (long)size, SEEK_SET);   // ← SEEK_SET non SEEK_END

   // ... scrittura separatore run, dati trade, TOTALE, istogramma ...

   FileClose(fh);   // [UTL-001-R006]
}
```

---

## Note

- Il separatore `;` è configurato nel `FileOpen()` come quarto argomento — gestito automaticamente da `FileWrite()`.
- `FileSize()` restituisce `ulong` — il cast `(long)` è necessario per `FileSeek()`.
- Il pattern è identico per qualsiasi tipo di CSV; cambia solo il nome file e l'intestazione.
