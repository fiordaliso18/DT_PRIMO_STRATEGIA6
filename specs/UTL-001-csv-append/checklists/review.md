# Checklist di Review — UTL-001 Scrittura CSV in Append

## Rilevamento prima esecuzione — [UTL-001-R001]
- [ ] `FileIsExist(filename, FILE_COMMON)` usato per verificare l'esistenza
- [ ] Se file non esiste: `FileOpen(FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ';')` + intestazione + `FileClose()`
- [ ] La creazione avviene in un blocco separato che si chiude prima dell'apertura in append

## Flag obbligatori — [UTL-001-R002], [UTL-001-R003]
- [ ] `FILE_COMMON` presente su tutte le chiamate `FileOpen()` (sia creazione che append)
- [ ] Apertura append: `FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON`
- [ ] Separatore `;` passato come quarto argomento a `FileOpen()`

## Seek alla fine — [UTL-001-R004]
- [ ] `ulong size = FileSize(fh)` — tipo `ulong` (non `long`)
- [ ] `FileSeek(fh, (long)size, SEEK_SET)` — cast a `long` e flag `SEEK_SET`
- [ ] **NON** usare `FileSeek(fh, 0, SEEK_END)` — non supportato con `FILE_CSV`

## Scrittura e chiusura — [UTL-001-R005], [UTL-001-R006]
- [ ] `FileWrite()` usato dopo il seek (non `FileWriteString()`)
- [ ] `FileClose(fh)` chiamata in ogni percorso di uscita (anche in caso di errore)
- [ ] Nessun handle lasciato aperto tra chiamate successive
