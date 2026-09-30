# Fester localhost-Origin ist erforderlich, damit Edge/Chrome die gespeicherten Ordner wiederfinden.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$url = 'http://localhost:8765/'
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try {
 $listener.Start()
} catch {
 try {
  $existing = Invoke-WebRequest -Uri ($url + '__nameplate/status') -UseBasicParsing -TimeoutSec 2
  if ($existing.Content.Trim() -ceq 'nameplate-dashboard-v2') {
   Write-Host 'Bereits gestartetes Dashboard wieder oeffnen.' -ForegroundColor Green
   Start-Process $url
   exit 0
  }
 } catch { }
 Write-Host 'Port 8765 ist durch eine andere Anwendung blockiert.' -ForegroundColor Red
 Write-Host 'Diese Anwendung schliessen und erneut starten. Keinen anderen Port verwenden.'
 exit 1
}
Write-Host ('Dashboard: ' + $url) -ForegroundColor Green
Write-Host 'Browser schliessen beendet nicht dieses Serverfenster. STRG+C beendet den Server.'
Start-Process $url
$files = @{'/'='index.html';'/index.html'='index.html';'/app.js'='app.js';'/xlsx.full.min.js'='xlsx.full.min.js'}
try {
 while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
   $path = $ctx.Request.Url.AbsolutePath
   $ctx.Response.Headers.Add('Cache-Control','no-store')
   $ctx.Response.Headers.Add('X-Content-Type-Options','nosniff')
   if ($path -ceq '/__nameplate/status') {
    $bytes = [Text.Encoding]::UTF8.GetBytes('nameplate-dashboard-v2')
    $ctx.Response.ContentType = 'text/plain; charset=utf-8'
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
   } elseif (-not $files.ContainsKey($path)) {
    $ctx.Response.StatusCode = 404
   } else {
    $name = $files[$path]
    $file = Join-Path $root $name
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
     $ctx.Response.StatusCode = 404
    } else {
     $ctx.Response.ContentType = if ($name.EndsWith('.js')) {'text/javascript; charset=utf-8'} else {'text/html; charset=utf-8'}
     $bytes = [IO.File]::ReadAllBytes($file)
     $ctx.Response.ContentLength64 = $bytes.Length
     $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    }
   }
  } catch { Write-Host ('HTTP-Fehler: '+$_.Exception.Message) -ForegroundColor Yellow
  } finally { $ctx.Response.Close() }
 }
} finally {
 $listener.Stop()
 $listener.Close()
}
