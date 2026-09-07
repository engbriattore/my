<#
.SYNOPSIS
    Instala os mods do RDR2 a partir dos .zip baixados, na ordem correta.

.DESCRIPTION
    Le os pacotes .zip da pasta de Downloads, descobre o TIPO de cada um pelo
    conteudo (mod de LML, script .asi, DLL de base, shader de ReShade) e copia
    cada arquivo para o lugar certo dentro da pasta do jogo.

    Ordem de instalacao respeitada:
      1. ScriptHookRDR2 (dinput8.dll + ScriptHookRDR2.dll na raiz)
      2. Lenny's Mod Loader (ModManager.asi + pasta lml\)
      3. Mods de LML (Online Content Unlocker, WhyEm's DLC, BloodLust...)
      4. Mods de script (.asi para a pasta scripts\)

    Por padrao o script SO MOSTRA O PLANO. Nada e copiado ate voce confirmar
    (ou usar -Aplicar). Todo arquivo sobrescrito vai antes para uma pasta de
    backup dentro do jogo.

.PARAMETER Caminho
    Pasta do jogo (a que contem RDR2.exe). Descoberta automaticamente se omitida.

.PARAMETER PastaDownloads
    Onde estao os .zip. Padrao: sua pasta Downloads.

.PARAMETER Pacotes
    Nomes (ou pedacos de nome) dos zips a instalar. Se omitido, o script
    encontra sozinho os pacotes conhecidos de RDR2.

.PARAMETER Aplicar
    Executa a copia. Sem este parametro, o script apenas mostra o que faria.

.EXAMPLE
    .\Instalar-Mods.ps1

.EXAMPLE
    .\Instalar-Mods.ps1 -Aplicar
#>
[CmdletBinding()]
param(
    [string]$Caminho,
    [string]$PastaDownloads,
    [string[]]$Pacotes,
    [switch]$Aplicar
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ---------------------------------------------------------------------------
# Descoberta de pastas
# ---------------------------------------------------------------------------
function Get-PastaJogo {
    param([string]$Sugerida)
    if ($Sugerida) {
        if (Test-Path -LiteralPath (Join-Path $Sugerida 'RDR2.exe')) { return (Resolve-Path -LiteralPath $Sugerida).Path }
        throw "Nao encontrei RDR2.exe em '$Sugerida'."
    }
    $cands = New-Object System.Collections.Generic.List[string]
    foreach ($chave in @(
        'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Red Dead Redemption 2',
        'HKLM:\SOFTWARE\Rockstar Games\Red Dead Redemption 2'
    )) {
        try {
            $p = Get-ItemProperty -Path $chave -ErrorAction Stop
            foreach ($n in @('InstallFolder', 'InstallLocation')) { if ($p.$n) { $cands.Add([string]$p.$n) } }
        } catch { }
    }
    $relativos = @(
        'Program Files\Epic Games\RedDeadRedemption2',
        'Epic Games\RedDeadRedemption2',
        'Program Files\Rockstar Games\Red Dead Redemption 2',
        'Rockstar Games\Red Dead Redemption 2',
        'Games\Red Dead Redemption 2',
        'SteamLibrary\steamapps\common\Red Dead Redemption 2',
        'Program Files (x86)\Steam\steamapps\common\Red Dead Redemption 2'
    )
    foreach ($d in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 3').DeviceID) {
        foreach ($r in $relativos) { $cands.Add("$d\$r") }
    }
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c 'RDR2.exe'))) { return (Resolve-Path -LiteralPath $c).Path }
    }
    throw 'Nao encontrei a pasta do jogo. Use -Caminho "C:\Program Files\Epic Games\RedDeadRedemption2".'
}

function Get-PastaDownloads {
    param([string]$Sugerida)
    if ($Sugerida) {
        if (Test-Path -LiteralPath $Sugerida) { return (Resolve-Path -LiteralPath $Sugerida).Path }
        throw "Pasta de downloads nao encontrada: $Sugerida"
    }
    foreach ($c in @(
        (Join-Path $env:USERPROFILE 'Downloads'),
        (Join-Path $env:USERPROFILE 'Transferencias'),
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads')
    )) {
        if ($c -and (Test-Path -LiteralPath $c)) { return (Resolve-Path -LiteralPath $c).Path }
    }
    throw 'Nao encontrei sua pasta Downloads. Use -PastaDownloads.'
}

# Ordem em que os pacotes devem ser instalados. Quanto menor, mais cedo.
$prioridades = @(
    @{ Padrao = 'scripthook';                Ordem = 1; Rotulo = 'ScriptHookRDR2 (base dos mods de script)' },
    @{ Padrao = 'lml_rdr|lennys|mod.?loader'; Ordem = 2; Rotulo = "Lenny's Mod Loader (base dos mods de conteudo)" },
    @{ Padrao = 'online.?content|unlocker|ocu'; Ordem = 3; Rotulo = 'Online Content Unlocker' },
    @{ Padrao = 'whyem.*dlc';                Ordem = 4; Rotulo = "WhyEm's DLC (roupas e itens)" },
    @{ Padrao = 'bloodlust|blood';           Ordem = 5; Rotulo = 'WhyEm''s BloodLust (sangue)' },
    @{ Padrao = 'gun.?metal';                Ordem = 6; Rotulo = 'Realistic Gun Metals' }
)

function Get-Prioridade {
    param([string]$Nome)
    foreach ($p in $prioridades) {
        if ($Nome -match $p.Padrao) { return $p }
    }
    return @{ Padrao = ''; Ordem = 50; Rotulo = 'Pacote adicional' }
}

# ---------------------------------------------------------------------------
# Classificacao do conteudo de um zip
# ---------------------------------------------------------------------------
# Decide o destino de cada arquivo pelo que ele e, nao pelo nome do zip.
function Get-PlanoDoPacote {
    param([string]$Zip, [string]$Jogo)

    $entradas = @()
    $arquivo = [System.IO.Compression.ZipFile]::OpenRead($Zip)
    try {
        $entradas = @($arquivo.Entries | Where-Object { $_.FullName -notmatch '/$' } |
                      Select-Object -ExpandProperty FullName)
    } finally { $arquivo.Dispose() }

    # Pastas de mod LML: qualquer diretorio que contenha install.xml.
    $raizesLml = @()
    foreach ($e in $entradas) {
        if ([System.IO.Path]::GetFileName($e) -ieq 'install.xml') {
            $dir = [System.IO.Path]::GetDirectoryName($e) -replace '\\', '/'
            $raizesLml += $dir
        }
    }
    $raizesLml = @($raizesLml | Sort-Object -Unique)

    $acoes = New-Object System.Collections.Generic.List[object]
    foreach ($e in $entradas) {
        $normalizado = $e -replace '\\', '/'
        $nome = [System.IO.Path]::GetFileName($normalizado)
        $ext = [System.IO.Path]::GetExtension($nome).ToLowerInvariant()
        $destino = $null
        $tipo = $null

        # 1) Arquivo dentro de uma pasta de mod LML -> lml\<NomeDoMod>\...
        $lmlDono = $raizesLml | Where-Object { $_ -ne '' -and $normalizado.StartsWith("$_/") } |
                   Sort-Object { $_.Length } -Descending | Select-Object -First 1
        if ($lmlDono) {
            $nomeMod = ($lmlDono -split '/')[-1]
            $relativo = $normalizado.Substring($lmlDono.Length + 1)
            $destino = Join-Path $Jogo (Join-Path 'lml' (Join-Path $nomeMod ($relativo -replace '/', '\')))
            $tipo = 'mod LML'
        }
        # 2) install.xml na raiz do zip -> o proprio zip e um mod LML
        elseif ($raizesLml -contains '') {
            $nomeMod = [System.IO.Path]::GetFileNameWithoutExtension($Zip) -replace '[-_ ]?\d{4,}.*$', '' -replace '[-_ ]+$', ''
            if (-not $nomeMod) { $nomeMod = 'ModSemNome' }
            $destino = Join-Path $Jogo (Join-Path 'lml' (Join-Path $nomeMod ($normalizado -replace '/', '\')))
            $tipo = 'mod LML'
        }
        # 3) Arquivos de base, sempre na raiz do jogo
        elseif ($nome -imatch '^(dinput8\.dll|ScriptHookRDR2\.dll|ModManager\.asi|version\.dll)$') {
            $destino = Join-Path $Jogo $nome
            $tipo = 'base (raiz do jogo)'
        }
        # 4) Shaders do ReShade
        elseif ($ext -in '.fx', '.fxh') {
            $destino = Join-Path $Jogo (Join-Path 'reshade-shaders\Shaders' $nome)
            $tipo = 'shader ReShade'
        }
        # 5) Mods de script
        elseif ($ext -eq '.asi' -or ($ext -eq '.lua' -and $normalizado -match 'script')) {
            $destino = Join-Path $Jogo (Join-Path 'scripts' $nome)
            $tipo = 'mod de script'
        }
        # 6) Pasta lml/ ja vinda pronta dentro do zip
        elseif ($normalizado -imatch '(^|/)lml/') {
            $depois = $normalizado -replace '^.*?(^|/)lml/', ''
            $destino = Join-Path $Jogo (Join-Path 'lml' ($depois -replace '/', '\'))
            $tipo = 'conteudo lml'
        }
        else {
            $tipo = 'ignorado (readme, licenca, instalador, exemplo)'
        }

        $acoes.Add([pscustomobject]@{
            Entrada = $normalizado
            Destino = $destino
            Tipo    = $tipo
        })
    }
    return $acoes
}

# ---------------------------------------------------------------------------
# Execucao
# ---------------------------------------------------------------------------
$jogo = Get-PastaJogo -Sugerida $Caminho
$downloads = Get-PastaDownloads -Sugerida $PastaDownloads

Write-Host ''
Write-Host '=== Instalador de mods do RDR2 ===' -ForegroundColor Cyan
Write-Host "Jogo     : $jogo"
Write-Host "Downloads: $downloads"
Write-Host ''

$zips = @(Get-ChildItem -LiteralPath $downloads -Filter '*.zip' -File)
if ($Pacotes) {
    $zips = @($zips | Where-Object { $nomeZip = $_.Name; ($Pacotes | Where-Object { $nomeZip -like "*$_*" }) })
} else {
    $conhecidos = ($prioridades | ForEach-Object { $_.Padrao }) -join '|'
    $zips = @($zips | Where-Object { $_.Name -match $conhecidos })
}

if ($zips.Count -eq 0) {
    Write-Host 'Nenhum pacote de mod reconhecido em Downloads.' -ForegroundColor Red
    Write-Host 'Use -Pacotes "parte-do-nome" ou -PastaDownloads para apontar os arquivos.' -ForegroundColor Yellow
    exit 1
}

$zips = @($zips | Sort-Object { (Get-Prioridade $_.Name).Ordem }, Name)

$plano = New-Object System.Collections.Generic.List[object]
foreach ($z in $zips) {
    $info = Get-Prioridade $z.Name
    Write-Host ("[{0}] {1}" -f $info.Ordem, $info.Rotulo) -ForegroundColor Cyan
    Write-Host "     $($z.Name)" -ForegroundColor DarkGray

    $acoes = Get-PlanoDoPacote -Zip $z.FullName -Jogo $jogo
    $copiar = @($acoes | Where-Object { $_.Destino })
    $pular  = @($acoes | Where-Object { -not $_.Destino })

    foreach ($grupo in ($copiar | Group-Object Tipo)) {
        Write-Host ("     -> {0}: {1} arquivo(s)" -f $grupo.Name, $grupo.Count) -ForegroundColor Green
        foreach ($a in ($grupo.Group | Select-Object -First 4)) {
            Write-Host ("        $($a.Entrada)  =>  $($a.Destino.Substring($jogo.Length).TrimStart('\'))") -ForegroundColor DarkGray
        }
        if ($grupo.Count -gt 4) { Write-Host ("        ... e mais $($grupo.Count - 4)") -ForegroundColor DarkGray }
    }
    if ($pular.Count -gt 0) {
        Write-Host ("     -> ignorados: $($pular.Count) arquivo(s) (readme, instaladores, exemplos)") -ForegroundColor DarkYellow
    }
    if ($copiar.Count -eq 0) {
        Write-Host '     ATENCAO: nada reconhecido neste pacote. Abra o zip e leia o readme do autor.' -ForegroundColor Red
    }

    $plano.Add([pscustomobject]@{ Zip = $z.FullName; Nome = $z.Name; Acoes = $copiar })
    Write-Host ''
}

# Alertas de conflito conhecidos
$vaiInstalarVersionDll = @($plano.Acoes | Where-Object { $_.Destino -and (Split-Path $_.Destino -Leaf) -ieq 'version.dll' })
$temOcu = @($plano | Where-Object { $_.Nome -match 'online.?content|unlocker' })
if ($vaiInstalarVersionDll.Count -gt 0 -and $temOcu.Count -gt 0) {
    Write-Host 'CONFLITO: um pacote traz version.dll e voce esta instalando o Online Content Unlocker.' -ForegroundColor Red
    Write-Host 'Use apenas um dos dois. Remova version.dll depois, se o jogo nao abrir.' -ForegroundColor Red
    Write-Host ''
}

$totalArquivos = ($plano.Acoes | Measure-Object).Count
Write-Host "Total: $totalArquivos arquivo(s) a copiar de $($plano.Count) pacote(s)." -ForegroundColor Cyan

if (-not $Aplicar) {
    Write-Host ''
    Write-Host 'Isto foi apenas uma SIMULACAO - nada foi alterado.' -ForegroundColor Yellow
    Write-Host 'Confira a lista acima e, se estiver certa, rode de novo com -Aplicar:' -ForegroundColor Yellow
    Write-Host '  .\Instalar-Mods.ps1 -Aplicar' -ForegroundColor Yellow
    Write-Host ''
    exit 0
}

$backup = Join-Path $jogo ("_backup_antes_dos_mods_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
$copiados = 0
$substituidos = 0

foreach ($pacote in $plano) {
    Write-Host "Instalando: $($pacote.Nome)" -ForegroundColor Cyan
    $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("rdr2mod_" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temp -Force | Out-Null
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($pacote.Zip, $temp)
        foreach ($a in $pacote.Acoes) {
            $origem = Join-Path $temp ($a.Entrada -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            if (-not (Test-Path -LiteralPath $origem)) { continue }

            $pastaDestino = Split-Path -Parent $a.Destino
            if (-not (Test-Path -LiteralPath $pastaDestino)) {
                New-Item -ItemType Directory -Path $pastaDestino -Force | Out-Null
            }
            # Guarda o arquivo original antes de sobrescrever.
            if (Test-Path -LiteralPath $a.Destino) {
                $rel = $a.Destino.Substring($jogo.Length).TrimStart('\')
                $alvoBackup = Join-Path $backup $rel
                New-Item -ItemType Directory -Path (Split-Path -Parent $alvoBackup) -Force | Out-Null
                Copy-Item -LiteralPath $a.Destino -Destination $alvoBackup -Force
                $substituidos++
            }
            Copy-Item -LiteralPath $origem -Destination $a.Destino -Force
            $copiados++
        }
    } finally {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  concluido." -ForegroundColor Green
}

Write-Host ''
Write-Host "$copiados arquivo(s) copiado(s); $substituidos arquivo(s) originais preservados." -ForegroundColor Green
if ($substituidos -gt 0) { Write-Host "Backup em: $backup" -ForegroundColor Green }
Write-Host ''
Write-Host 'Proximos passos:' -ForegroundColor Cyan
Write-Host '  1. .\Verificar-Instalacao.ps1        (confere se tudo caiu no lugar)'
Write-Host '  2. Abra o jogo uma vez, sem ReShade, e veja se carrega o modo historia.'
Write-Host '  3. .\Configurar-ReShade.ps1 -Aplicar (shaders e preset grafico)'
Write-Host ''
