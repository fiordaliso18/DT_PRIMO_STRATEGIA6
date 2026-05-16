# build.ps1 - sincronizza S6_EA.mq5 + Trader/ nella cartella MT5 e compila
# Usage: powershell.exe -ExecutionPolicy Bypass -File build.ps1

$src        = "$PSScriptRoot\src\S6_EA.mq5"
$dst        = "C:\Users\primo\AppData\Roaming\MetaQuotes\Terminal\73B7A2420D6397DFF9014A20F1201F97\MQL5\Experts\Advisors\S6_EA.mq5"
$srcTrader  = "$PSScriptRoot\src\Trader"
$dstTrader  = "C:\Users\primo\AppData\Roaming\MetaQuotes\Terminal\73B7A2420D6397DFF9014A20F1201F97\MQL5\Experts\Advisors\Trader"
$metaeditor = "C:\Program Files\Pepperstone MetaTrader 5\MetaEditor64.exe"
$logFile    = "$PSScriptRoot\build.log"

# Verifica sorgente
if (-not (Test-Path $src)) {
    Write-Host "[BUILD] ERRORE: sorgente non trovata: $src" -ForegroundColor Red
    exit 1
}

# Copia S6_EA.mq5 verso MT5
$dstDir = Split-Path $dst
if (-not (Test-Path $dstDir)) {
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
}
Copy-Item $src $dst -Force
(Get-Item $dst).LastWriteTime = Get-Date
Write-Host "[BUILD] Copiato: $src -> $dst" -ForegroundColor Cyan

# Copia cartella Trader/ verso MT5
if (Test-Path $srcTrader) {
    if (-not (Test-Path $dstTrader)) {
        New-Item -ItemType Directory -Force -Path $dstTrader | Out-Null
    }
    Copy-Item "$srcTrader\*" $dstTrader -Force -Recurse
    Write-Host "[BUILD] Copiato: $srcTrader -> $dstTrader" -ForegroundColor Cyan
}

# Compila
if (-not (Test-Path $metaeditor)) {
    Write-Host "[BUILD] MetaEditor non trovato: $metaeditor" -ForegroundColor Yellow
    Write-Host "[BUILD] Compilazione manuale richiesta (F7 in MetaEditor)" -ForegroundColor Yellow
    exit 0
}

Write-Host "[BUILD] Compilazione S6_EA.mq5..." -ForegroundColor Cyan
Start-Process -FilePath $metaeditor `
    -ArgumentList "/compile:`"$dst`"", "/log:`"$logFile`"" `
    -Wait | Out-Null

# Mostra risultato
if (Test-Path $logFile) {
    $lines    = Get-Content $logFile
    $result   = $lines | Select-String "Result:"
    $errors   = $lines | Select-String " error "
    $warnings = $lines | Select-String " warning "

    if ($result)   { Write-Host "[BUILD] $($result.Line)" -ForegroundColor Green }
    if ($errors)   {
        Write-Host "[BUILD] --- ERRORI ---" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
    }
    if ($warnings) {
        Write-Host "[BUILD] --- WARNINGS ---" -ForegroundColor Yellow
        $warnings | ForEach-Object { Write-Host $_.Line -ForegroundColor Yellow }
    }
    if (-not $errors) {
        Write-Host "[BUILD] Compilazione OK - S6_EA.ex5 pronto" -ForegroundColor Green
    }
} else {
    Write-Host "[BUILD] Log di compilazione non trovato" -ForegroundColor Yellow
}
