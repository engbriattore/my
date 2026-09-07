<#
    RDR2 - ARMAS E ITENS DO ONLINE NO MODO HISTORIA
    ===============================================
    Instala SOMENTE o necessario para liberar as armas e itens do Red Dead
    Online no modo Historia:

        1. Lenny's Mod Loader (LML) - a base
        2. Online Content Unlocker (OCU) - o que libera o conteudo

    NAO instala o ScriptHookRDR2 de proposito. O OCU nao precisa dele, e um
    ScriptHook velho demais para a versao atual do jogo trava o carregamento
    e faz o jogo redefinir as configuracoes graficas. Menos peca, menos risco.

    COMO USAR
        powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\RDR2-ARMAS-ONLINE.ps1"

    Opcoes:
        -Simular   mostra o que faria, sem alterar nada
#>
[CmdletBinding()]
param(
    [string]$Caminho,
    [string]$PastaDownloads,
    [switch]$Simular
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Titulo { param([string]$T) Write-Host ''; Write-Host "=== $T ===" -ForegroundColor Cyan }
function Ok    { param([string]$T) Write-Host "  [ok]    $T" -ForegroundColor Green }
function Aviso { param([string]$T) Write-Host "  [aviso] $T" -ForegroundColor Yellow }
function Erro  { param([string]$T) Write-Host "  [erro]  $T" -ForegroundColor Red }
function Passo { param([string]$T) Write-Host "  $T" -ForegroundColor Gray }

Write-Host ''
Write-Host '#################################################' -ForegroundColor Cyan
Write-Host '#  RDR2 - armas do Online no modo Historia      #' -ForegroundColor Cyan
Write-Host '#################################################' -ForegroundColor Cyan
if ($Simular) { Write-Host 'MODO SIMULACAO: nada sera alterado.' -ForegroundColor Yellow }

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

if (-not $PastaDownloads) {
    foreach ($c in @((Join-Path $env:USERPROFILE 'Downloads'), (Join-Path $env:USERPROFILE 'Transferencias'))) {
        if ($c -and (Test-Path -LiteralPath $c)) { $PastaDownloads = $c; break }
    }
}
if (-not $PastaDownloads -or -not (Test-Path -LiteralPath $PastaDownloads)) {
    Erro 'Nao achei sua pasta Downloads. Use -PastaDownloads "C:\caminho".'
    exit 1
}
Ok "downloads: $PastaDownloads"

# ===========================================================================
# Achar os dois pacotes
# ===========================================================================
Titulo 'Procurando os pacotes'

$zips = @(Get-ChildItem -LiteralPath $PastaDownloads -Filter '*.zip' -File -ErrorAction SilentlyContinue)

$zipLml = $zips | Where-Object { $_.Name -match 'lml_rdr|lennys|mod.?loader' } |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
$zipOcu = $zips | Where-Object { $_.Name -match 'online.?content|unlocker|(^|[^a-z])ocu([^a-z]|$)' } |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1

$temLmlInstalado = (Test-Path -LiteralPath (Join-Path $jogo 'ModManager.asi')) -and
                   (Test-Path -LiteralPath (Join-Path $jogo 'lml'))

if ($zipLml) { Ok "LML: $($zipLml.Name)" }
elseif ($temLmlInstalado) { Ok 'LML: ja instalado no jogo' }
else {
    Erro 'nao achei o Lenny s Mod Loader em Downloads e ele nao esta instalado'
    Passo 'baixe o "Lenny s Mod Loader RDR" no Nexus Mods e rode de novo'
    exit 1
}

if ($zipOcu) {
    Ok "OCU: $($zipOcu.Name)"
} else {
    Erro 'nao achei o Online Content Unlocker em Downloads'
    Passo 'se ainda esta baixando, espere terminar e rode este script de novo'
    Passo 'o arquivo tem nome parecido com: Online Content Unlocker-1688-....zip'
    exit 1
}

# ===========================================================================
# Classificacao: cada arquivo vai para onde o conteudo manda
# ===========================================================================
function Get-PlanoDoPacote {
    param([string]$Zip, [string]$Jogo)
    $entradas = @()
    $arq = [System.IO.Compression.ZipFile]::OpenRead($Zip)
    try { $entradas = @($arq.Entries | Where-Object { $_.FullName -notmatch '/$' } | Select-Object -ExpandProperty FullName) }
    finally { $arq.Dispose() }

    $raizesLml = @()
    foreach ($e in $entradas) {
        if ([System.IO.Path]::GetFileName($e) -ieq 'install.xml') {
            $raizesLml += ([System.IO.Path]::GetDirectoryName($e) -replace '\\', '/')
        }
    }
    $raizesLml = @($raizesLml | Sort-Object -Unique)

    $acoes = New-Object System.Collections.Generic.List[object]
    foreach ($e in $entradas) {
        $norm = $e -replace '\\', '/'
        $nome = [System.IO.Path]::GetFileName($norm)
        $ext  = [System.IO.Path]::GetExtension($nome).ToLowerInvariant()
        $destino = $null; $tipo = 'ignorado'

        $dono = $raizesLml | Where-Object { $_ -ne '' -and $norm.StartsWith("$_/") } |
                Sort-Object { $_.Length } -Descending | Select-Object -First 1
        if ($dono) {
            $nomeMod = ($dono -split '/')[-1]
            $rel = $norm.Substring($dono.Length + 1)
            $destino = Join-Path $Jogo (Join-Path 'lml' (Join-Path $nomeMod ($rel -replace '/', '\')))
            $tipo = 'mod LML'
        }
        elseif ($raizesLml -contains '') {
            $nomeMod = [System.IO.Path]::GetFileNameWithoutExtension($Zip) -replace '[-_ ]?\d{4,}.*$', '' -replace '[-_ ]+$', ''
            if (-not $nomeMod) { $nomeMod = 'ModSemNome' }
            $destino = Join-Path $Jogo (Join-Path 'lml' (Join-Path $nomeMod ($norm -replace '/', '\')))
            $tipo = 'mod LML'
        }
        elseif ($nome -imatch '^(dinput8\.dll|ModManager\.asi|version\.dll)$') {
            $destino = Join-Path $Jogo $nome; $tipo = 'base'
        }
        elseif ($ext -eq '.asi') {
            $destino = Join-Path $Jogo (Join-Path 'scripts' $nome); $tipo = 'mod de script (.asi)'
        }
        elseif ($norm -imatch '(^|/)lml/') {
            $depois = $norm -replace '^.*?(^|/)lml/', ''
            $destino = Join-Path $Jogo (Join-Path 'lml' ($depois -replace '/', '\')); $tipo = 'conteudo lml'
        }
        $acoes.Add([pscustomobject]@{ Entrada = $norm; Destino = $destino; Tipo = $tipo })
    }
    return $acoes
}

# ===========================================================================
# Instalar
# ===========================================================================
Titulo 'Instalando'

$pastaBackup = Join-Path $jogo ("_backup_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
$copiados = 0
$ocuVirouAsi = $false

$aInstalar = @()
if ($zipLml) { $aInstalar += [pscustomobject]@{ Zip = $zipLml; Rotulo = "Lenny's Mod Loader"; EhOcu = $false } }
$aInstalar += [pscustomobject]@{ Zip = $zipOcu; Rotulo = 'Online Content Unlocker'; EhOcu = $true }

foreach ($item in $aInstalar) {
    Write-Host "  $($item.Rotulo)" -ForegroundColor White
    $acoes = @((Get-PlanoDoPacote -Zip $item.Zip.FullName -Jogo $jogo) | Where-Object { $_.Destino })
    if ($acoes.Count -eq 0) {
        Aviso '    nada reconhecido neste pacote - abra o zip e leia o readme do autor'
        continue
    }
    foreach ($g in ($acoes | Group-Object Tipo)) { Passo "    $($g.Name): $($g.Count) arquivo(s)" }

    if ($item.EhOcu -and ($acoes | Where-Object { $_.Tipo -eq 'mod de script (.asi)' })) { $ocuVirouAsi = $true }

    if ($Simular) { continue }

    $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('rdr2ocu_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temp -Force | Out-Null
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($item.Zip.FullName, $temp)
        foreach ($a in $acoes) {
            $origem = Join-Path $temp ($a.Entrada -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            if (-not (Test-Path -LiteralPath $origem)) { continue }
            $pastaDestino = Split-Path -Parent $a.Destino
            if (-not (Test-Path -LiteralPath $pastaDestino)) { New-Item -ItemType Directory -Path $pastaDestino -Force | Out-Null }
            if (Test-Path -LiteralPath $a.Destino) {
                $alvo = Join-Path $pastaBackup ($a.Destino.Substring($jogo.Length).TrimStart('\'))
                New-Item -ItemType Directory -Path (Split-Path -Parent $alvo) -Force | Out-Null
                Copy-Item -LiteralPath $a.Destino -Destination $alvo -Force
            }
            Copy-Item -LiteralPath $origem -Destination $a.Destino -Force
            $copiados++
        }
    } finally { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
    Ok "    instalado"
}

if ($Simular) {
    Write-Host ''
    Write-Host 'SIMULACAO - nada foi alterado. Rode sem -Simular para instalar.' -ForegroundColor Yellow
    Write-Host ''
    exit 0
}
Ok "$copiados arquivo(s) copiado(s)"

# ===========================================================================
# O OCU precisa de carregador de .asi?
# ===========================================================================
Titulo 'Conferindo dependencias'

$temAsiLoader = Test-Path -LiteralPath (Join-Path $jogo 'dinput8.dll')

if ($ocuVirouAsi -and -not $temAsiLoader) {
    Aviso 'esta versao do OCU veio como .asi, e um arquivo .asi precisa de um carregador'
    Passo 'o carregador e o dinput8.dll, que vem junto com o ScriptHookRDR2.'
    Passo 'procurando o ScriptHook nos seus downloads para pegar SO o carregador...'

    $zipSh = $zips | Where-Object { $_.Name -match 'scripthook' } |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($zipSh) {
        $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('rdr2sh_' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipSh.FullName, $temp)
            $d = Get-ChildItem -LiteralPath $temp -Filter 'dinput8.dll' -Recurse -File -ErrorAction SilentlyContinue |
                 Select-Object -First 1
            if ($d) {
                Copy-Item -LiteralPath $d.FullName -Destination (Join-Path $jogo 'dinput8.dll') -Force
                Ok 'carregador dinput8.dll instalado (sem o ScriptHookRDR2.dll)'
                Passo 'se o jogo travar no carregamento, renomeie dinput8.dll para dinput8.dll.off'
                $temAsiLoader = $true
            }
        } finally { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
    }
    if (-not $temAsiLoader) {
        Aviso 'nao consegui instalar o carregador - o OCU pode nao carregar'
        Passo 'baixe o ScriptHookRDR2 e copie APENAS o dinput8.dll para a pasta do jogo'
    }
} elseif (-not $ocuVirouAsi) {
    Ok 'o OCU foi instalado como mod do LML - nao precisa de ScriptHook'
}

if (Test-Path -LiteralPath (Join-Path $jogo 'ScriptHookRDR2.dll')) {
    Aviso 'existe um ScriptHookRDR2.dll na pasta do jogo, de instalacao anterior'
    Passo 'ele nao e necessario para as armas do Online. Se o jogo nao abrir,'
    Passo 'renomeie ScriptHookRDR2.dll e dinput8.dll para .off e teste de novo.'
}

if (Test-Path -LiteralPath (Join-Path $jogo 'version.dll')) {
    Aviso 'version.dll presente - ele conflita com o Online Content Unlocker'
    Passo 'se o jogo nao abrir ou as armas nao aparecerem, apague o version.dll'
}

# ===========================================================================
# Verificacao
# ===========================================================================
Titulo 'VERIFICACAO'

$modsLml = @(Get-ChildItem -LiteralPath (Join-Path $jogo 'lml') -Directory -ErrorAction SilentlyContinue)
$ocuNoLml = @($modsLml | Where-Object { $_.Name -match 'online|unlock' })
$ocuNoScripts = @(Get-ChildItem -LiteralPath (Join-Path $jogo 'scripts') -Filter '*.asi' -File -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -match 'online|unlock' })

$checks = @(
    @{ N = "Lenny's Mod Loader (ModManager.asi)"; Ok = (Test-Path -LiteralPath (Join-Path $jogo 'ModManager.asi')) },
    @{ N = 'pasta lml\ criada';                   Ok = (Test-Path -LiteralPath (Join-Path $jogo 'lml')) },
    @{ N = 'Online Content Unlocker instalado';   Ok = (($ocuNoLml.Count + $ocuNoScripts.Count) -gt 0) }
)

$tudoOk = $true
foreach ($c in $checks) { if ($c.Ok) { Ok $c.N } else { Erro $c.N; $tudoOk = $false } }

if ($modsLml.Count -gt 0) { Passo "mods em lml\: $(($modsLml | Select-Object -ExpandProperty Name) -join ', ')" }

Write-Host ''
if ($tudoOk) {
    Write-Host '  PRONTO. Abra o RDR2 no MODO HISTORIA.' -ForegroundColor Green
    Write-Host ''
    Write-Host '  As armas e itens do Online aparecem nas LOJAS DE ARMAS do jogo' -ForegroundColor Green
    Write-Host '  (Valentine, Saint Denis, Rhodes...). Nao aparecem magicamente no' -ForegroundColor Green
    Write-Host '  inventario - voce compra normalmente, como qualquer arma.' -ForegroundColor Green
} else {
    Write-Host '  Faltou algo - veja as linhas [erro] acima e me mande esta tela.' -ForegroundColor Red
}
Write-Host ''
Write-Host '  NUNCA entre no Red Dead Online com estes mods ativos.' -ForegroundColor Red
Write-Host '  Antes de jogar Online, renomeie ModManager.asi e a pasta lml.' -ForegroundColor Red
Write-Host ''
