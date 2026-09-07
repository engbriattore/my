<#
    RDR2 - REMOVER TUDO
    ===================
    Tira do jogo todos os mods e o ReShade, deixando a instalacao limpa,
    como veio da loja.

    Por padrao NADA e apagado: tudo e movido para
        Documentos\RDR2 mods removidos\<data>
    Se voce mudar de ideia, os arquivos estao la.

    COMO USAR
        powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\RDR2-REMOVER-TUDO.ps1"

    Opcoes:
        -Simular          mostra o que seria removido, sem mexer em nada
        -Apagar           apaga de vez, em vez de mover para a pasta de guarda
        -RestaurarConfig  devolve tambem o system.xml (ajustes graficos) do
                          backup mais recente feito pelos scripts
#>
[CmdletBinding()]
param(
    [string]$Caminho,
    [switch]$Simular,
    [switch]$Apagar,
    [switch]$RestaurarConfig
)

$ErrorActionPreference = 'Stop'

function Titulo { param([string]$T) Write-Host ''; Write-Host "=== $T ===" -ForegroundColor Cyan }
function Ok    { param([string]$T) Write-Host "  [ok]    $T" -ForegroundColor Green }
function Aviso { param([string]$T) Write-Host "  [aviso] $T" -ForegroundColor Yellow }
function Erro  { param([string]$T) Write-Host "  [erro]  $T" -ForegroundColor Red }
function Passo { param([string]$T) Write-Host "  $T" -ForegroundColor Gray }

Write-Host ''
Write-Host '###########################################' -ForegroundColor Cyan
Write-Host '#  RDR2 - remover mods e ReShade          #' -ForegroundColor Cyan
Write-Host '###########################################' -ForegroundColor Cyan
if ($Simular) { Write-Host 'MODO SIMULACAO: nada sera removido.' -ForegroundColor Yellow }

function Get-PastaJogo {
    param([string]$Sugerida)
    if ($Sugerida) {
        if (Test-Path -LiteralPath (Join-Path $Sugerida 'RDR2.exe')) { return (Resolve-Path -LiteralPath $Sugerida).Path }
        throw "Nao encontrei RDR2.exe em '$Sugerida'."
    }
    $cands = New-Object System.Collections.Generic.List[string]
    foreach ($ch in @('HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Red Dead Redemption 2',
                      'HKLM:\SOFTWARE\Rockstar Games\Red Dead Redemption 2')) {
        try {
            $p = Get-ItemProperty -Path $ch -ErrorAction Stop
            foreach ($n in @('InstallFolder', 'InstallLocation')) { if ($p.$n) { $cands.Add([string]$p.$n) } }
        } catch { }
    }
    foreach ($r in @(
        'Program Files\Epic Games\RedDeadRedemption2',
        'Epic Games\RedDeadRedemption2',
        'Program Files\Rockstar Games\Red Dead Redemption 2',
        'Rockstar Games\Red Dead Redemption 2',
        'Games\Red Dead Redemption 2',
        'SteamLibrary\steamapps\common\Red Dead Redemption 2',
        'Program Files (x86)\Steam\steamapps\common\Red Dead Redemption 2'
    )) {
        foreach ($d in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 3').DeviceID) { $cands.Add("$d\$r") }
    }
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c 'RDR2.exe'))) { return (Resolve-Path -LiteralPath $c).Path }
    }
    return $null
}

$jogo = Get-PastaJogo -Sugerida $Caminho
if (-not $jogo) { Erro 'Nao encontrei o RDR2. Use -Caminho "D:\...\Red Dead Redemption 2".'; exit 1 }
Ok "jogo: $jogo"

function Get-PastaDocumentos {
    $l = New-Object System.Collections.Generic.List[string]
    $s = [Environment]::GetFolderPath('MyDocuments')
    if ($s) { $l.Add($s) }
    if ($env:USERPROFILE) {
        foreach ($x in @('Documents', 'Documentos', 'OneDrive\Documents', 'OneDrive\Documentos')) { $l.Add((Join-Path $env:USERPROFILE $x)) }
    }
    foreach ($p in $l) {
        if ((Test-Path -LiteralPath $p) -and (Test-Path -LiteralPath (Join-Path $p 'Rockstar Games\Red Dead Redemption 2'))) { return $p }
    }
    foreach ($p in $l) { if (Test-Path -LiteralPath $p) { return $p } }
    return $null
}
$docs = Get-PastaDocumentos

# ===========================================================================
# O que sai do jogo
# ===========================================================================
Titulo 'Procurando o que remover'

$alvos = New-Object System.Collections.Generic.List[object]

function Marcar {
    param([string]$Nome, [string]$Motivo)
    $p = Join-Path $jogo $Nome
    if (Test-Path -LiteralPath $p) {
        $alvos.Add([pscustomobject]@{ Nome = $Nome; Caminho = $p; Motivo = $Motivo })
    }
}

# ReShade
foreach ($n in @('dxgi.dll', 'd3d12.dll', 'd3d11.dll', 'opengl32.dll', 'ReShade64.dll', 'ReShade32.dll')) {
    Marcar $n 'ReShade (DLL)'
}
foreach ($n in @('ReShade.ini', 'ReShadePreset.ini', 'reshade-shaders', 'reshade-presets')) {
    Marcar $n 'ReShade'
}
# Mods
foreach ($n in @('dinput8.dll', 'ScriptHookRDR2.dll', 'ModManager.asi', 'version.dll')) {
    Marcar $n 'mod (base)'
}
foreach ($n in @('scripts', 'lml')) { Marcar $n 'mods' }

# Logs e sobras
foreach ($item in (Get-ChildItem -LiteralPath $jogo -File -ErrorAction SilentlyContinue)) {
    if ($item.Name -match '^(ReShade.*\.log|ScriptHookRDR2\.log|ModManager\.log|asiloader\.log)$') {
        $alvos.Add([pscustomobject]@{ Nome = $item.Name; Caminho = $item.FullName; Motivo = 'log' })
    }
    if ($item.Extension -ieq '.ini' -and $item.Name -ne 'ReShade.ini') {
        try {
            $t = Get-Content -LiteralPath $item.FullName -Raw -ErrorAction Stop
            if ($t -match '(?m)^\s*Techniques\s*=' -or $t -match '(?m)^\[[^\]]+\.fx\]') {
                $alvos.Add([pscustomobject]@{ Nome = $item.Name; Caminho = $item.FullName; Motivo = 'preset do ReShade' })
            }
        } catch { }
    }
    if ($item.Name -match '^ReShade\.ini\.backup_') {
        $alvos.Add([pscustomobject]@{ Nome = $item.Name; Caminho = $item.FullName; Motivo = 'backup do ReShade' })
    }
}
# Pastas de backup criadas pelos scripts
foreach ($d in (Get-ChildItem -LiteralPath $jogo -Directory -ErrorAction SilentlyContinue)) {
    if ($d.Name -match '^(_backup_antes_dos_mods_|_mods_desativados$)') {
        $alvos.Add([pscustomobject]@{ Nome = $d.Name; Caminho = $d.FullName; Motivo = 'backup dos scripts' })
    }
}

if ($alvos.Count -eq 0) {
    Ok 'nada de mod ou ReShade encontrado - seu jogo ja esta limpo'
    Write-Host ''
    exit 0
}

foreach ($g in ($alvos | Group-Object Motivo)) {
    Write-Host "  $($g.Name):" -ForegroundColor White
    foreach ($a in $g.Group) { Passo "    $($a.Nome)" }
}
Write-Host ''
Passo "total: $($alvos.Count) item(ns)"

if ($Simular) {
    Write-Host ''
    Write-Host 'SIMULACAO - nada foi removido. Rode sem -Simular para remover.' -ForegroundColor Yellow
    Write-Host ''
    exit 0
}

# ===========================================================================
# Remover
# ===========================================================================
Titulo 'Removendo'

$guarda = $null
if (-not $Apagar) {
    # Cadeia de reserva: se nenhuma pasta pessoal resolver, guarda ao lado do
    # jogo - o importante e nunca falhar no meio da remocao.
    $base = $docs
    if (-not $base) { $base = $env:USERPROFILE }
    if (-not $base) { $base = [Environment]::GetFolderPath('UserProfile') }
    if (-not $base) { $base = Split-Path -Parent $jogo }
    $guarda = Join-Path $base ('RDR2 mods removidos\' + (Get-Date -Format 'yyyy-MM-dd_HHmm'))
    New-Item -ItemType Directory -Path $guarda -Force | Out-Null
    Passo "guardando em: $guarda"
}

$removidos = 0
$falhas = New-Object System.Collections.Generic.List[string]
foreach ($a in $alvos) {
    try {
        if ($Apagar) {
            Remove-Item -LiteralPath $a.Caminho -Recurse -Force
        } else {
            $destino = Join-Path $guarda $a.Nome
            if (Test-Path -LiteralPath $destino) { Remove-Item -LiteralPath $destino -Recurse -Force }
            Move-Item -LiteralPath $a.Caminho -Destination $destino -Force
        }
        Ok "removido: $($a.Nome)"
        $removidos++
    } catch {
        Erro "nao consegui remover $($a.Nome): $($_.Exception.Message)"
        $falhas.Add($a.Nome)
    }
}

# ===========================================================================
# Ajustes graficos (opcional)
# ===========================================================================
if ($RestaurarConfig) {
    Titulo 'Restaurando os ajustes graficos'
    if (-not $docs) {
        Aviso 'nao localizei sua pasta Documentos'
    } else {
        $pastaBackups = Join-Path $docs 'Backups RDR2'
        $maisRecente = Get-ChildItem -LiteralPath $pastaBackups -Directory -ErrorAction SilentlyContinue |
                       Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'Settings') } |
                       Sort-Object Name -Descending | Select-Object -First 1
        if (-not $maisRecente) {
            Aviso 'nao achei backup de configuracoes feito pelos scripts'
        } else {
            $destinoCfg = Join-Path $docs 'Rockstar Games\Red Dead Redemption 2\Settings'
            if (Test-Path -LiteralPath $destinoCfg) {
                $lado = "${destinoCfg}_antes_da_restauracao_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Move-Item -LiteralPath $destinoCfg -Destination $lado
                Passo "configuracoes atuais preservadas em: $(Split-Path $lado -Leaf)"
            }
            Copy-Item -LiteralPath (Join-Path $maisRecente.FullName 'Settings') -Destination $destinoCfg -Recurse -Force
            Ok "ajustes graficos restaurados de $($maisRecente.Name)"
        }
    }
}

# ===========================================================================
# Conferencia
# ===========================================================================
Titulo 'CONFERINDO'

$sobrou = New-Object System.Collections.Generic.List[string]
foreach ($n in @('dxgi.dll', 'd3d12.dll', 'd3d11.dll', 'ReShade64.dll', 'ReShade.ini',
                 'reshade-shaders', 'reshade-presets', 'dinput8.dll', 'ScriptHookRDR2.dll',
                 'ModManager.asi', 'version.dll', 'scripts', 'lml')) {
    if (Test-Path -LiteralPath (Join-Path $jogo $n)) { $sobrou.Add($n) }
}

if ($sobrou.Count -eq 0) {
    Ok 'pasta do jogo limpa - nenhum mod ou ReShade restante'
    Write-Host ''
    Write-Host "  $removidos item(ns) removido(s)." -ForegroundColor Green
    if (-not $Apagar) {
        Write-Host "  Tudo guardado em: $guarda" -ForegroundColor Green
        Write-Host '  (se quiser de volta um dia, e so copiar para a pasta do jogo)' -ForegroundColor Gray
    }
    Write-Host ''
    Write-Host '  Abra o jogo: ele deve estar exatamente como antes dos mods.' -ForegroundColor Green
} else {
    Erro "ainda sobrou: $($sobrou -join ', ')"
    Passo 'geralmente e arquivo em uso: FECHE O JOGO e o launcher (Epic/Rockstar) e rode de novo.'
    Passo 'se persistir, rode o PowerShell como administrador.'
}
Write-Host ''
