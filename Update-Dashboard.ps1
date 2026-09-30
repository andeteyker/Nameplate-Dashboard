# Nameplate Dashboard: Updates von genau diesem GitHub-Repository.
# Windows PowerShell 5.1; keine Administratorrechte und kein Git erforderlich (ZIP-Installation).
[CmdletBinding()]
param(
    [string] $InstallDir = $PSScriptRoot,
    [switch] $CheckOnly,
    [switch] $Yes
)
$ErrorActionPreference = 'Stop'
$repo = 'andeteyker/Nameplate-Dashboard'
$branch = 'main'
$root = [IO.Path]::GetFullPath($InstallDir)
$versionFile = Join-Path $root '.nameplate-version'
$backupRoot = Join-Path $root 'update-backups'
# Ausschließlich Anwendungscode aktualisieren: XLS, CSV, Parser und persönliche Dateien bleiben unberührt.
$managed = @(
    'index.html', 'app.js', 'README.md',
    'Start-Dashboard.bat', 'Start-Dashboard.ps1',
    'Excel-Parser-installieren.bat', 'Excel-Parser-installieren.ps1',
    'Update-Dashboard.ps1', '.gitignore'
)
$workDir = $null
$pendingFiles = @()

function Print-Step([string] $message) { Write-Host $message -ForegroundColor Cyan }
function Fail([string] $message) { throw $message }
function Get-RemoteSha {
    $api = "https://api.github.com/repos/$repo/commits/$branch"
    $result = Invoke-RestMethod -Uri $api -TimeoutSec 20 -Headers @{
        'User-Agent' = 'Nameplate-Dashboard-Updater'
        'Accept' = 'application/vnd.github+json'
    }
    $sha = [string] $result.sha
    if ($sha -cnotmatch '^[0-9a-f]{40}$') { Fail 'GitHub hat keinen gueltigen Commit-Hash geliefert.' }
    return $sha
}
function GitOutput([string[]] $Arguments) {
    # Git schreibt Fortschritt auch bei Erfolg auf STDERR; das darf unter PS 5.1 kein Fehler sein.
    $oldPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & git @Arguments 2>&1
        $gitExit = $LASTEXITCODE
    } finally { $ErrorActionPreference = $oldPreference }
    if ($gitExit -ne 0) { Fail ('Git-Fehler: ' + ($output -join [Environment]::NewLine)) }
    return ($output -join "`n").Trim()
}

try {
    if (-not (Test-Path -LiteralPath (Join-Path $root 'index.html') -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $root 'app.js') -PathType Leaf)) {
        Fail "Kein Dashboard-Verzeichnis: $root`nBitte Update-Dashboard.bat direkt im Programmordner starten."
    }
    Print-Step 'Nameplate Dashboard: Update-Pruefung'
    $remoteSha = Get-RemoteSha
    $isGit = Test-Path -LiteralPath (Join-Path $root '.git')
    if ($isGit) {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Fail 'Git-Arbeitskopie erkannt, aber Git fehlt. Bitte Git installieren oder das GitHub-ZIP in einen separaten Ordner entpacken.'
        }
        $current = GitOutput @('-C', $root, 'rev-parse', 'HEAD')
    } else {
        $current = if (Test-Path -LiteralPath $versionFile -PathType Leaf) {
            (Get-Content -LiteralPath $versionFile -Raw).Trim()
        } else { '' }
    }
    Write-Host ('Installiert: ' + $(if ($current) { $current.Substring(0, [Math]::Min(12, $current.Length)) } else { 'Version unbekannt (Erstpruefung)' }))
    Write-Host ('Auf GitHub: ' + $remoteSha.Substring(0, 12))
    if ($current -ceq $remoteSha) {
        Write-Host 'Bereits auf dem neuesten Stand.' -ForegroundColor Green
        exit 0
    }
    if ($CheckOnly) {
        Write-Host 'Ein neuer Stand ist verfuegbar. Update-Dashboard.bat zum Aktualisieren starten.' -ForegroundColor Yellow
        exit 0
    }
    if (-not $Yes) {
        $answer = Read-Host 'Update jetzt installieren? [J/N]'
        if ($answer -notmatch '^(j|ja|y|yes)$') { Write-Host 'Kein Update installiert.'; exit 0 }
    }
    if ($isGit) {
        # Bei einem geklonten Repository ausschließlich Fast-Forward und niemals lokale Aenderungen verwerfen.
        $origin = GitOutput @('-C', $root, 'remote', 'get-url', 'origin')
        if ($origin -notmatch '^(https://github\.com/andeteyker/Nameplate-Dashboard(\.git)?/?|git@github\.com:andeteyker/Nameplate-Dashboard(\.git)?)$') {
            Fail "Unbekanntes Git-Origin: $origin. Aus Sicherheitsgruenden kein automatisches Update."
        }
        $active = GitOutput @('-C', $root, 'branch', '--show-current')
        if ($active -cne $branch) { Fail "Git-Branch '$active' ist nicht '$branch'. Bitte manuell aktualisieren." }
        $dirty = GitOutput @('-C', $root, 'status', '--porcelain', '--untracked-files=no')
        if ($dirty) { Fail "Lokale Aenderungen festgestellt. Zuerst committen oder stashen:`n$dirty" }
        Print-Step 'Git: main abrufen und Fast-Forward durchfuehren ...'
        GitOutput @('-C', $root, 'fetch', '--no-tags', 'origin', $branch) | Out-Null
        $fetched = GitOutput @('-C', $root, 'rev-parse', 'FETCH_HEAD')
        if ($fetched -cne $remoteSha) {
            Fail 'Der abgerufene Git-Stand passt nicht zum geprueften GitHub-Commit. Abbruch.'
        }
        GitOutput @('-C', $root, 'merge', '--ff-only', 'FETCH_HEAD') | Out-Null
        Write-Host ('Update installiert: ' + $remoteSha.Substring(0, 12)) -ForegroundColor Green
        Write-Host 'Dashboard-Browserseite mit Strg+F5 neu laden.'
        exit 0
    }

    # ZIP-Installation: exakt den zuvor von GitHub bestaetigten Commit herunterladen.
    $workDir = Join-Path ([IO.Path]::GetTempPath()) ('nameplate-update-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $workDir | Out-Null
    $archive = Join-Path $workDir 'update.zip'
    $unpack = Join-Path $workDir 'extracted'
    Print-Step 'Geprueften Programmstand herunterladen ...'
    Invoke-WebRequest -Uri "https://codeload.github.com/$repo/zip/$remoteSha" -UseBasicParsing -TimeoutSec 90 -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $unpack -Force
    $folders = @(Get-ChildItem -LiteralPath $unpack -Directory)
    if ($folders.Count -ne 1) { Fail 'Unerwartete Archivstruktur. Keine Dateien geaendert.' }
    $srcRoot = $folders[0].FullName
    foreach ($relative in $managed) {
        if (-not (Test-Path -LiteralPath (Join-Path $srcRoot $relative) -PathType Leaf)) {
            Fail "Unvollstaendiges Update: $relative fehlt. Keine Dateien geaendert."
        }
    }

    $backup = Join-Path $backupRoot ((Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $remoteSha.Substring(0, 8))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    $previousVersion = if (Test-Path -LiteralPath $versionFile -PathType Leaf) { [IO.File]::ReadAllText($versionFile) } else { $null }
    $existed = @{}
    Print-Step ('Sicherung erstellen: ' + $backup)
    foreach ($relative in $managed) {
        $dest = Join-Path $root $relative
        $existed[$relative] = Test-Path -LiteralPath $dest -PathType Leaf
        if ($existed[$relative]) {
            Copy-Item -LiteralPath $dest -Destination (Join-Path $backup $relative) -Force
        }
    }
    # Alle Update-Dateien vor dem Austauschen auf demselben Datentraeger bereitstellen.
    foreach ($relative in $managed) {
        $pending = Join-Path $root ('.nameplate-pending-' + [guid]::NewGuid().ToString('N'))
        Copy-Item -LiteralPath (Join-Path $srcRoot $relative) -Destination $pending
        $pendingFiles += @{Name = $relative; Path = $pending}
    }
    $changed = @()
    try {
        Print-Step 'Programmdateien ersetzen ...'
        foreach ($item in $pendingFiles) {
            $dest = Join-Path $root $item.Name
            $changed += $item.Name
            Move-Item -LiteralPath $item.Path -Destination $dest -Force
        }
        $stamp = Join-Path $root ('.nameplate-pending-' + [guid]::NewGuid().ToString('N'))
        $pendingFiles += @{Name = '.nameplate-version'; Path = $stamp}
        [IO.File]::WriteAllText($stamp, $remoteSha + "`n", (New-Object Text.UTF8Encoding $false))
        Move-Item -LiteralPath $stamp -Destination $versionFile -Force
    } catch {
        Write-Warning 'Fehler beim Aktualisieren. Vorherige Dateien werden aus der Sicherung wiederhergestellt.'
        foreach ($relative in $changed) {
            $dest = Join-Path $root $relative
            if ($existed[$relative]) {
                Copy-Item -LiteralPath (Join-Path $backup $relative) -Destination $dest -Force
            } elseif (Test-Path -LiteralPath $dest -PathType Leaf) {
                Remove-Item -LiteralPath $dest -Force
            }
        }
        if ($null -eq $previousVersion) {
            if (Test-Path -LiteralPath $versionFile) { Remove-Item -LiteralPath $versionFile -Force }
        } else {
            [IO.File]::WriteAllText($versionFile, $previousVersion, (New-Object Text.UTF8Encoding $false))
        }
        throw
    }
    Write-Host ('Erfolgreich aktualisiert: ' + $remoteSha.Substring(0, 12)) -ForegroundColor Green
    Write-Host ('Sicherung: ' + $backup)
    Write-Host 'Excel-Dateien, lokale Parser-Bibliothek und Browserdaten wurden nicht angetastet.'
    Write-Host 'Dashboard bei Bedarf neu starten und mit Strg+F5 aktualisieren.'
} catch {
    Write-Host ('Update fehlgeschlagen: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    foreach ($item in $pendingFiles) {
        if (Test-Path -LiteralPath $item.Path -PathType Leaf) {
            Remove-Item -LiteralPath $item.Path -Force -ErrorAction SilentlyContinue
        }
    }
    if ($workDir -and (Test-Path -LiteralPath $workDir)) {
        Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
