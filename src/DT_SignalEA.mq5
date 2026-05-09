//+------------------------------------------------------------------+
//| DT Signal EA — Two-candle M15 pattern detector                  |
//| Rilevatore pattern due candele M15                               |
//|                                                                  |
//| Author / Autore: Primo                                           |
//| Version / Versione: 1.00                                         |
//| Complete implementation — Epics 1-4                              |
//+------------------------------------------------------------------+
#property copyright   "Primo"
#property version     "1.00"
#property description "DT Signal EA — Two-candle M15 pattern detector"
#property strict

//+------------------------------------------------------------------+
//| Input parameters / Parametri di input                            |
//+------------------------------------------------------------------+
input double PipThreshold   = 3.0;    // Pip threshold / Soglia in pip
input bool   EnableEmail    = false;  // Enable email alerts / Abilita alert email
input bool   EnablePush     = true;   // Enable mobile push / Abilita push mobile
input string CsvFileName    = "dt_signals.csv"; // CSV filename / Nome file CSV

//+------------------------------------------------------------------+
//| Pattern type enumeration / Enumerazione tipo pattern             |
//+------------------------------------------------------------------+
enum PATTERN_TYPE
  {
   NONE    = 0, // No pattern / Nessun pattern
   BULLISH = 1, // Bullish two-candle pattern / Pattern rialzista due candele
   BEARISH = 2  // Bearish two-candle pattern / Pattern ribassista due candele
  };

//+------------------------------------------------------------------+
//| Global state / Stato globale                                     |
//+------------------------------------------------------------------+
datetime g_lastBarTime = 0; // Last processed M15 bar time / Ora ultima barra M15 elaborata
int      g_signalCount = 0; // Total signals fired / Totale segnali emessi

//+------------------------------------------------------------------+
//| Expert initialization / Inizializzazione EA                      |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Initialize global state / Inizializza lo stato globale
   g_lastBarTime = 0;
   g_signalCount = 0;

   g_lastBarTime = iTime(Symbol(), PERIOD_M15, 0); // Initialize bar time / Inizializza ora barra
   if(g_lastBarTime == 0)                           // Chart not ready — critical error / Grafico non pronto — errore critico
     {
      UpdateStatusLabel("DT Signal EA — ERROR", clrRed); // Show error status / Mostra stato errore
      return(INIT_FAILED);                               // Abort initialization / Interrompi inizializzazione
     }

   // Write CSV header if file does not exist yet / Scrivi intestazione CSV se il file non esiste ancora
   if(!FileIsExist(CsvFileName)) // New file — write header / File nuovo — scrivi intestazione
     {
      int h = FileOpen(CsvFileName, FILE_CSV|FILE_WRITE|FILE_UNICODE|FILE_SHARE_READ); // AC 3.1-7: FILE_SHARE_READ / AC 3.1-7: FILE_SHARE_READ
      if(h != INVALID_HANDLE)
        {
         FileWrite(h, "date", "time", "pair", "timeframe", "pattern", "body1_pips", "body2_pips", "threshold"); // CSV header / Intestazione CSV
         FileClose(h); // Release immediately / Rilascia immediatamente
        }
     }

   Print("DT files folder: ", TerminalInfoString(TERMINAL_DATA_PATH), "\\MQL5\\Files\\", CsvFileName); // File path diagnostic / Diagnostica percorso file
   UpdateStatusLabel("DT Signal EA — ACTIVE", clrGreen); // Show active status / Mostra stato attivo
   return(INIT_SUCCEEDED);                               // Initialization complete / Inizializzazione completata
  }

//+------------------------------------------------------------------+
//| Expert deinitialization / Deinizializzazione EA                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   UpdateStatusLabel("DT Signal EA — STOPPED", clrRed); // Show stopped status / Mostra stato fermato
   ObjectDelete(0, "DT_StatusLabel");                    // Remove label from chart / Rimuovi etichetta dal grafico
  }

//+------------------------------------------------------------------+
//| Expert tick / Tick EA                                            |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime currentBarTime = iTime(Symbol(), PERIOD_M15, 0); // Get current M15 bar time / Ottieni ora barra M15 corrente
   if(currentBarTime != g_lastBarTime)                        // New bar detected / Nuova barra rilevata
     {
      g_lastBarTime = currentBarTime; // Update last bar time / Aggiorna ora ultima barra

      PATTERN_TYPE pt = DetectPattern(); // Evaluate two-candle pattern / Valuta pattern due candele
      if(pt != NONE)                     // Pattern found — fan-out / Pattern trovato — fan-out
        {
         double body1 = BodyInPips(1); // Body of bar [1] in pips / Corpo barra [1] in pip
         double body2 = BodyInPips(2); // Body of bar [2] in pips / Corpo barra [2] in pip
         g_signalCount++;              // Increment signal counter / Incrementa contatore segnali

         // Fan-out step 1: update status label / Passo 1 fan-out: aggiorna etichetta stato
         UpdateStatusLabel("DT Signal EA — SIGNAL", clrYellow);

         // Fan-out step 2: place arrow on chart / Passo 2 fan-out: posiziona freccia sul grafico
         datetime    barTime   = iTime(Symbol(), PERIOD_M15, 1);  // Signal bar time / Ora barra segnale
         double      arrowPrice = (pt == BULLISH)                                   // Anchor below low (bull) or above high (bear)
                                ? iLow( Symbol(), PERIOD_M15, 1)                   // Bull: below candle / Rialzista: sotto candela
                                : iHigh(Symbol(), PERIOD_M15, 1);                  // Bear: above candle / Ribassista: sopra candela
         string      dateTag   = TimeToString(barTime, TIME_DATE);
         string      timeTag   = StringSubstr(TimeToString(barTime, TIME_DATE|TIME_MINUTES), 11);
         StringReplace(dateTag, ".", "");                                            // Remove dots / Rimuovi punti
         StringReplace(timeTag, ":", "");                                            // Remove colon / Rimuovi due punti
         string      objName   = "DT_Signal_" + dateTag + "_" + timeTag;           // Unique object name / Nome oggetto univoco
         ENUM_OBJECT arrowType = (pt == BULLISH ? OBJ_ARROW_UP : OBJ_ARROW_DOWN); // Arrow type / Tipo freccia
         color       arrowClr  = (pt == BULLISH ? clrLime : clrRed);               // Arrow color: lime=bull, red=bear / Colore freccia: lime=rialzo, rosso=ribasso
         if(!ObjectCreate(0, objName, arrowType, 0, barTime, arrowPrice))          // Create arrow at low/high / Crea freccia a minimo/massimo
            Print("Arrow create failed: ", GetLastError());                         // Log error / Registra errore
         else
           {
            ObjectSetInteger(0, objName, OBJPROP_COLOR, arrowClr); // Set color / Imposta colore
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 4);        // Arrow size / Dimensione freccia
           }

         // Fan-out step 3: send email if enabled / Passo 3 fan-out: invia email se abilitata
         if(EnableEmail) SendAlertEmail(pt, body1, body2);

         // Fan-out step 4: send mobile push notification if enabled / Passo 4 fan-out: invia push mobile se abilitata
         if(EnablePush) SendMobilePush(pt, body1, body2);

         // Fan-out step 5: write to CSV (open-write-close) / Passo 5 fan-out: scrivi su CSV (apri-scrivi-chiudi)
         WriteSignalToCsv(pt, body1, body2);
        }
     }
  }

//+------------------------------------------------------------------+
//| Update chart status label / Aggiorna etichetta stato sul chart   |
//+------------------------------------------------------------------+
void UpdateStatusLabel(string text, color clr)
  {
   if(ObjectFind(0, "DT_StatusLabel") < 0) // Create label if absent / Crea etichetta se assente
     {
      ObjectCreate(0, "DT_StatusLabel", OBJ_LABEL, 0, 0, 0);                      // Create status label / Crea etichetta stato
      ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_CORNER,    CORNER_LEFT_UPPER); // Anchor top-left / Ancora in alto a sinistra
      ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_XDISTANCE, 10);               // X offset px / Offset X in pixel
      ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_YDISTANCE, 20);               // Y offset px / Offset Y in pixel
      ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_FONTSIZE,  10);               // Font size / Dimensione font
     }
   ObjectSetString( 0, "DT_StatusLabel", OBJPROP_TEXT,  text); // Update text / Aggiorna testo
   ObjectSetInteger(0, "DT_StatusLabel", OBJPROP_COLOR, clr);  // Update color / Aggiorna colore
   ChartRedraw(0);                                              // Force redraw / Forza ridisegno
  }

//+------------------------------------------------------------------+
//| Detect two-candle pattern / Rileva pattern due candele           |
//+------------------------------------------------------------------+
PATTERN_TYPE DetectPattern()
  {
   double close1 = iClose(Symbol(), PERIOD_M15, 1); // Last closed candle close / Chiusura ultima candela chiusa
   double open1  = iOpen( Symbol(), PERIOD_M15, 1); // Last closed candle open / Apertura ultima candela chiusa
   double close2 = iClose(Symbol(), PERIOD_M15, 2); // Prior closed candle close / Chiusura candela precedente
   double open2  = iOpen( Symbol(), PERIOD_M15, 2); // Prior closed candle open / Apertura candela precedente

   double body1 = BodyInPips(1); // Body of bar [1] in pips / Corpo barra [1] in pip
   double body2 = BodyInPips(2); // Body of bar [2] in pips / Corpo barra [2] in pip

   bool bull1 = (close1 > open1); // Bar [1] bullish / Barra [1] rialzista
   bool bull2 = (close2 > open2); // Bar [2] bullish / Barra [2] rialzista
   bool bear1 = (close1 < open1); // Bar [1] bearish / Barra [1] ribassista
   bool bear2 = (close2 < open2); // Bar [2] bearish / Barra [2] ribassista

   if(bull1 && bull2 && body1 >= PipThreshold && body2 >= PipThreshold) // Two bullish ≥ threshold / Due rialziste ≥ soglia
      return(BULLISH);
   if(bear1 && bear2 && body1 >= PipThreshold && body2 >= PipThreshold) // Two bearish ≥ threshold / Due ribassiste ≥ soglia
      return(BEARISH);

   return(NONE); // No qualifying pattern / Nessun pattern qualificato
  }

//+------------------------------------------------------------------+
//| Send alert email / Invia email di alert                          |
//+------------------------------------------------------------------+
bool SendAlertEmail(PATTERN_TYPE pt, double body1, double body2)
  {
   datetime barTime    = iTime(Symbol(), PERIOD_M15, 1);                          // Signal bar time / Ora barra segnale
   string   patternStr = (pt == BULLISH ? "BULLISH" : "BEARISH");                // Pattern label / Etichetta pattern
   string   subject    = "DT Signal — " + Symbol() + " M15 " + patternStr;      // Email subject / Oggetto email
   string   mailBody   = "Pair: "       + Symbol()                        + "\n" // Email body / Corpo email
                       + "Timeframe: M15\n"
                       + "Pattern: "    + patternStr                      + "\n"
                       + "Bar 1 body: " + DoubleToString(body1, 1)  + " pips\n"
                       + "Bar 2 body: " + DoubleToString(body2, 1)  + " pips\n"
                       + "Time: " + TimeToString(barTime, TIME_DATE|TIME_MINUTES) + " (broker TZ)"; // Broker timezone / Fuso orario broker

   if(!SendMail(subject, mailBody)) // SMTP failure — log to CSV / Errore SMTP — registra su CSV
     {
      int h = FileOpen(CsvFileName, FILE_CSV|FILE_WRITE|FILE_READ|FILE_UNICODE|FILE_SHARE_READ); // Open for error row / Apri per riga errore
      if(h != INVALID_HANDLE)
        {
         FileSeek(h, 0, SEEK_END);                                                                                                              // Append / Append
         string ds = TimeToString(barTime, TIME_DATE);
         string ts = StringSubstr(TimeToString(barTime, TIME_DATE|TIME_MINUTES), 11);
         FileWrite(h, ds, ts, Symbol(), "M15", "SMTP_ERROR", "0.0", "0.0", "0.0"); // SMTP error row / Riga errore SMTP
         FileClose(h);                                                               // Release immediately / Rilascia immediatamente
        }
      return(false);
     }

   return(true); // Email sent successfully / Email inviata con successo
  }

//+------------------------------------------------------------------+
//| Write signal row to CSV / Scrivi riga segnale su CSV             |
//+------------------------------------------------------------------+
bool WriteSignalToCsv(PATTERN_TYPE pt, double body1, double body2)
  {
   int h = FileOpen(CsvFileName, FILE_CSV|FILE_WRITE|FILE_READ|FILE_UNICODE|FILE_SHARE_READ); // Open file — AC 3.1-7 / Apri file — AC 3.1-7
   if(h == INVALID_HANDLE)                                                           // Open failed / Apertura fallita
     {
      UpdateStatusLabel("DT Signal EA — CSV ERROR", clrOrange); // Warn trader / Avvisa trader
      return(false);
     }

   FileSeek(h, 0, SEEK_END); // Seek to end for append — AC 3.1-3 / Posiziona alla fine — AC 3.1-3

   datetime barTime    = iTime(Symbol(), PERIOD_M15, 1);                                  // Closed bar time / Ora barra chiusa
   string   dateStr    = TimeToString(barTime, TIME_DATE);                                 // "YYYY.MM.DD" / Data
   string   timeStr    = StringSubstr(TimeToString(barTime, TIME_DATE|TIME_MINUTES), 11); // "HH:MM" / Ora
   string   patternStr = (pt == BULLISH ? "BULLISH" : "BEARISH");                         // Pattern label / Etichetta pattern

   int written = FileWrite(h,
                           dateStr, timeStr, Symbol(), "M15", patternStr,
                           DoubleToString(body1, 1),
                           DoubleToString(body2, 1),
                           DoubleToString(PipThreshold, 1)); // Write signal row / Scrivi riga segnale

   if(written > 0) FileFlush(h); // Flush to disk before close — Task 2.6 / Scrivi su disco prima di chiudere
   FileClose(h); // Release immediately / Rilascia immediatamente

   if(written <= 0) // Write failed / Scrittura fallita
     {
      UpdateStatusLabel("DT Signal EA — CSV ERROR", clrOrange); // Warn trader / Avvisa trader
      return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Send mobile push notification / Invia notifica push mobile       |
//+------------------------------------------------------------------+
bool SendMobilePush(PATTERN_TYPE pt, double body1, double body2)
  {
   datetime barTime    = iTime(Symbol(), PERIOD_M15, 1);                         // Signal bar time / Ora barra segnale
   string   patternStr = (pt == BULLISH ? "BULLISH" : "BEARISH");               // Pattern label / Etichetta pattern
   string   msg        = "DT Signal " + Symbol() + " M15 " + patternStr        // Push message / Messaggio push
                       + " | B1=" + DoubleToString(body1, 1)
                       + "p B2=" + DoubleToString(body2, 1)
                       + "p | " + TimeToString(barTime, TIME_DATE|TIME_MINUTES); // Broker time / Ora broker

   if(!SendNotification(msg)) // Push failed — log only, EA continues / Push fallito — solo log, EA continua
     {
      Print("Push notification failed: ", GetLastError()); // Log error / Registra errore
      return(false);
     }

   return(true); // Push sent successfully / Push inviata con successo
  }

//+------------------------------------------------------------------+
//| Calculate candle body in pips / Calcola corpo candela in pip     |
//+------------------------------------------------------------------+
double BodyInPips(int barIndex)
  {
   double body     = MathAbs(iClose(Symbol(), PERIOD_M15, barIndex) - iOpen(Symbol(), PERIOD_M15, barIndex)); // Raw body size / Dimensione corpo grezza
   double pipValue = (_Digits == 5 || _Digits == 3) ? _Point * 10.0 : _Point; // Pip size: 5/3-decimal vs 4/2-decimal broker / Dimensione pip
   return(NormalizeDouble(body / pipValue, 1)); // Body in pips, 1 decimal / Corpo in pip, 1 decimale
  }
//+------------------------------------------------------------------+
