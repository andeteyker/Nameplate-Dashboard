# Optionaler einmaliger Download der SheetJS-Bibliothek. Excel-Daten bleiben lokal.
$ErrorActionPreference = 'Stop'
$out = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'xlsx.full.min.js'
$url = 'https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js'
try {
 [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
 Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
 if ((Get-Item -LiteralPath $out).Length -lt 100000) { throw 'Unvollstaendiger Download' }
 Write-Host 'Excel-Parser lokal installiert.' -ForegroundColor Green
} catch {
 Write-Host ('Download fehlgeschlagen: ' + $_.Exception.Message) -ForegroundColor Red
 Write-Host 'Bitte bei Bedarf den Parser durch die IT freigeben lassen.'
 exit 1
}
