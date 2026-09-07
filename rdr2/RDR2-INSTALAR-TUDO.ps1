<#
    RDR2 - INSTALAR TUDO
    ====================
    Faz a instalacao inteira de uma vez:

      1. acha a pasta do jogo sozinho
      2. faz backup dos seus saves
      3. instala os mods a partir dos .zip da sua pasta Downloads
      4. instala os shaders que o preset grafico exige
      5. aponta o ReShade para o preset
      6. mostra um relatorio do que ficou instalado

    COMO USAR
      Abra o PowerShell COMO ADMINISTRADOR e rode:

        powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\RDR2-INSTALAR-TUDO.ps1"

    Para so ver o que seria feito, sem alterar nada, acrescente -Simular no fim.

    Tudo que for sobrescrito vai para uma pasta de backup dentro do jogo.
    Nada e apagado.
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
Write-Host '################################################' -ForegroundColor Cyan
Write-Host '#  RDR2 - instalacao de mods e ReShade         #' -ForegroundColor Cyan
Write-Host '################################################' -ForegroundColor Cyan
if ($Simular) { Write-Host 'MODO SIMULACAO: nada sera alterado.' -ForegroundColor Yellow }

# ===========================================================================
# 1. Achar a pasta do jogo
# ===========================================================================
Titulo 'Procurando o jogo'

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
    foreach ($vdf in @("${env:ProgramFiles(x86)}\Steam\steamapps\libraryfolders.vdf",
                       "$env:ProgramFiles\Steam\steamapps\libraryfolders.vdf")) {
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in ([regex]'"path"\s+"(.+?)"').Matches((Get-Content -LiteralPath $vdf -Raw))) {
                $cands.Add((Join-Path ($m.Groups[1].Value -replace '\\\\', '\') 'steamapps\common\Red Dead Redemption 2'))
            }
        }
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
    return $null
}

$jogo = Get-PastaJogo -Sugerida $Caminho
if (-not $jogo) {
    Erro 'Nao encontrei o RDR2 automaticamente.'
    Write-Host ''
    Write-Host 'Rode de novo apontando a pasta que tem o RDR2.exe, assim:' -ForegroundColor Yellow
    Write-Host '  powershell -ExecutionPolicy Bypass -File "RDR2-INSTALAR-TUDO.ps1" -Caminho "D:\Games\Red Dead Redemption 2"' -ForegroundColor Yellow
    exit 1
}
Ok "jogo encontrado: $jogo"

$versaoJogo = $null
try { $versaoJogo = (Get-Item -LiteralPath (Join-Path $jogo 'RDR2.exe')).VersionInfo.FileVersion } catch { }
if ($versaoJogo) { Passo "versao do jogo: $versaoJogo" }

# Documentos (cobre OneDrive e Windows em portugues)
function Get-PastaDocumentos {
    $lista = New-Object System.Collections.Generic.List[string]
    $shell = [Environment]::GetFolderPath('MyDocuments')
    if ($shell) { $lista.Add($shell) }
    if ($env:USERPROFILE) {
        foreach ($s in @('Documents', 'Documentos', 'OneDrive\Documents', 'OneDrive\Documentos')) {
            $lista.Add((Join-Path $env:USERPROFILE $s))
        }
    }
    foreach ($p in $lista) {
        if ((Test-Path -LiteralPath $p) -and (Test-Path -LiteralPath (Join-Path $p 'Rockstar Games\Red Dead Redemption 2'))) { return $p }
    }
    foreach ($p in $lista) { if (Test-Path -LiteralPath $p) { return $p } }
    return $null
}
$docs = Get-PastaDocumentos

if (-not $PastaDownloads) {
    foreach ($c in @((Join-Path $env:USERPROFILE 'Downloads'), (Join-Path $env:USERPROFILE 'Transferencias'))) {
        if ($c -and (Test-Path -LiteralPath $c)) { $PastaDownloads = $c; break }
    }
}
if ($PastaDownloads) { Ok "downloads: $PastaDownloads" } else { Aviso 'nao achei sua pasta Downloads' }

# API grafica: decide como o ReShade deve ser instalado
$api = $null
if ($docs) {
    $sx = Join-Path $docs 'Rockstar Games\Red Dead Redemption 2\Settings\system.xml'
    if (Test-Path -LiteralPath $sx) {
        if ((Get-Content -LiteralPath $sx -Raw) -match 'kSettingAPI_(\w+)') { $api = $Matches[1] }
    }
}
if ($api) { Ok "API grafica do jogo: $api" } else { Aviso 'nao consegui ler a API grafica (abra o jogo uma vez)' }

# ===========================================================================
# 2. Backup dos saves
# ===========================================================================
Titulo 'Backup dos saves'
if ($Simular) {
    Passo 'simulacao: o backup seria feito agora'
} elseif ($docs) {
    $origemDocs = Join-Path $docs 'Rockstar Games\Red Dead Redemption 2'
    if (Test-Path -LiteralPath $origemDocs) {
        $pastaBackup = Join-Path $docs ('Backups RDR2\' + (Get-Date -Format 'yyyy-MM-dd_HHmm'))
        New-Item -ItemType Directory -Path $pastaBackup -Force | Out-Null
        foreach ($sub in @('Profiles', 'Settings')) {
            $de = Join-Path $origemDocs $sub
            if (Test-Path -LiteralPath $de) {
                Copy-Item -LiteralPath $de -Destination (Join-Path $pastaBackup $sub) -Recurse -Force
                Ok "$sub salvo"
            }
        }
        Passo "backup em: $pastaBackup"
    } else { Aviso 'nao achei a pasta de saves - abra o jogo uma vez' }
} else { Aviso 'sem pasta Documentos, backup pulado' }

# ===========================================================================
# 3. Instalar os mods dos .zip
# ===========================================================================
Titulo 'Instalando os mods'

$prioridades = @(
    @{ Padrao = 'scripthook';                   Ordem = 1; Rotulo = 'ScriptHookRDR2' },
    @{ Padrao = 'lml_rdr|lennys|mod.?loader';   Ordem = 2; Rotulo = "Lenny's Mod Loader" },
    @{ Padrao = 'online.?content|unlocker|ocu'; Ordem = 3; Rotulo = 'Online Content Unlocker' },
    @{ Padrao = 'whyem.*dlc';                   Ordem = 4; Rotulo = "WhyEm's DLC" },
    @{ Padrao = 'bloodlust';                    Ordem = 5; Rotulo = "WhyEm's BloodLust" },
    @{ Padrao = 'gun.?metal';                   Ordem = 6; Rotulo = 'Realistic Gun Metals' }
)
function Get-Prioridade { param([string]$N)
    foreach ($p in $prioridades) { if ($N -match $p.Padrao) { return $p } }
    return @{ Padrao = ''; Ordem = 50; Rotulo = 'Pacote adicional' }
}

# Cada arquivo vai para onde o CONTEUDO manda, nao o nome do zip.
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
        elseif ($nome -imatch '^(dinput8\.dll|ScriptHookRDR2\.dll|ModManager\.asi|version\.dll)$') {
            $destino = Join-Path $Jogo $nome; $tipo = 'base'
        }
        elseif ($ext -in '.fx', '.fxh') {
            $destino = Join-Path $Jogo (Join-Path 'reshade-shaders\Shaders' $nome); $tipo = 'shader'
        }
        elseif ($ext -eq '.asi') {
            $destino = Join-Path $Jogo (Join-Path 'scripts' $nome); $tipo = 'mod de script'
        }
        elseif ($norm -imatch '(^|/)lml/') {
            $depois = $norm -replace '^.*?(^|/)lml/', ''
            $destino = Join-Path $Jogo (Join-Path 'lml' ($depois -replace '/', '\')); $tipo = 'conteudo lml'
        }
        $acoes.Add([pscustomobject]@{ Entrada = $norm; Destino = $destino; Tipo = $tipo })
    }
    return $acoes
}

$pastaBackupMods = Join-Path $jogo ("_backup_antes_dos_mods_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
$totalCopiados = 0
$totalSubstituidos = 0
$instalouAlgumMod = $false

if ($PastaDownloads -and (Test-Path -LiteralPath $PastaDownloads)) {
    $conhecidos = ($prioridades | ForEach-Object { $_.Padrao }) -join '|'
    $zips = @(Get-ChildItem -LiteralPath $PastaDownloads -Filter '*.zip' -File |
              Where-Object { $_.Name -match $conhecidos } |
              Sort-Object { (Get-Prioridade $_.Name).Ordem }, Name)

    if ($zips.Count -eq 0) {
        Aviso 'nenhum pacote de mod reconhecido em Downloads'
        Passo 'se os mods ja estao instalados, tudo bem - o relatorio no fim confirma'
    }

    foreach ($z in $zips) {
        $rotulo = (Get-Prioridade $z.Name).Rotulo
        Write-Host "  $rotulo" -ForegroundColor White
        Passo "    $($z.Name)"
        $acoes = @((Get-PlanoDoPacote -Zip $z.FullName -Jogo $jogo) | Where-Object { $_.Destino })
        if ($acoes.Count -eq 0) {
            Aviso '    nada reconhecido neste pacote - abra o zip e leia o readme do autor'
            continue
        }
        if ($Simular) {
            foreach ($g in ($acoes | Group-Object Tipo)) { Passo "    $($g.Name): $($g.Count) arquivo(s)" }
            continue
        }

        $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('rdr2mod_' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($z.FullName, $temp)
            foreach ($a in $acoes) {
                $origem = Join-Path $temp ($a.Entrada -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                if (-not (Test-Path -LiteralPath $origem)) { continue }
                $pastaDestino = Split-Path -Parent $a.Destino
                if (-not (Test-Path -LiteralPath $pastaDestino)) { New-Item -ItemType Directory -Path $pastaDestino -Force | Out-Null }
                if (Test-Path -LiteralPath $a.Destino) {
                    $alvo = Join-Path $pastaBackupMods ($a.Destino.Substring($jogo.Length).TrimStart('\'))
                    New-Item -ItemType Directory -Path (Split-Path -Parent $alvo) -Force | Out-Null
                    Copy-Item -LiteralPath $a.Destino -Destination $alvo -Force
                    $totalSubstituidos++
                }
                Copy-Item -LiteralPath $origem -Destination $a.Destino -Force
                $totalCopiados++
            }
        } finally { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
        Ok "    instalado"
        $instalouAlgumMod = $true
    }
} else {
    Aviso 'pasta Downloads nao encontrada - pulando a instalacao dos mods'
}

if ($instalouAlgumMod) {
    Ok "$totalCopiados arquivo(s) copiado(s)"
    if ($totalSubstituidos -gt 0) { Passo "$totalSubstituidos originais preservados em: $pastaBackupMods" }
}

# Conflito conhecido
if ((Test-Path -LiteralPath (Join-Path $jogo 'version.dll')) -and
    (Get-ChildItem -LiteralPath (Join-Path $jogo 'lml') -Directory -ErrorAction SilentlyContinue |
     Where-Object { $_.Name -match 'online.?content|unlocker' })) {
    Aviso 'version.dll e o Online Content Unlocker nao convivem - se o jogo nao abrir, apague version.dll'
}

# ===========================================================================
# 4. ReShade: shaders do preset + PresetPath
# ===========================================================================
Titulo 'ReShade e preset grafico'

$reshadeIni   = Join-Path $jogo 'ReShade.ini'
$pastaShaders = Join-Path $jogo 'reshade-shaders\Shaders'

function Test-EhPreset {
    param([string]$A)
    try {
        $t = Get-Content -LiteralPath $A -Raw -ErrorAction Stop
        return ($t -match '(?m)^\s*Techniques\s*=' -or $t -match '(?m)^\[[^\]]+\.fx\]')
    } catch { return $false }
}

$presets = @(Get-ChildItem -LiteralPath $jogo -Filter '*.ini' -File -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -ne 'ReShade.ini' -and (Test-EhPreset $_.FullName) })
$presets += @(Get-ChildItem -LiteralPath (Join-Path $jogo 'reshade-presets') -Filter '*.ini' -File -Recurse -ErrorAction SilentlyContinue |
              Where-Object { Test-EhPreset $_.FullName })

if (-not (Test-Path -LiteralPath $reshadeIni)) {
    Aviso 'o ReShade ainda nao esta instalado neste jogo'
    Write-Host ''
    Write-Host '  FALTA VOCE FAZER (uma vez so, e o instalador e uma janela grafica):' -ForegroundColor Yellow
    Write-Host '    1. abra o instalador do ReShade que voce baixou' -ForegroundColor Yellow
    Write-Host "    2. selecione: $jogo\RDR2.exe" -ForegroundColor Yellow
    if ($api) {
        Write-Host "    3. escolha a API: $api  <-- IMPORTANTE, e a que o seu jogo usa" -ForegroundColor Yellow
    } else {
        Write-Host '    3. escolha a mesma API que o jogo usa (veja em Configuracoes > Graficos > API)' -ForegroundColor Yellow
    }
    Write-Host '    4. marque os pacotes de shaders oferecidos' -ForegroundColor Yellow
    Write-Host '    5. rode este script de novo - ele termina o resto sozinho' -ForegroundColor Yellow
} elseif ($presets.Count -eq 0) {
    Aviso 'ReShade instalado, mas nao achei nenhum preset (.ini) na pasta do jogo'
    Passo 'copie o .ini do preset para a pasta do jogo e rode este script de novo'
} else {
    $preset = ($presets | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
    Ok "preset: $(Split-Path $preset -Leaf)"

    $texto = Get-Content -LiteralPath $preset -Raw
    $exigidos = New-Object System.Collections.Generic.HashSet[string]
    foreach ($m in ([regex]'(?mi)^\s*Techniques\s*=(.*)$').Matches($texto)) {
        foreach ($parte in $m.Groups[1].Value -split ',') {
            if ($parte -match '@\s*([^,\s]+\.fx)') { [void]$exigidos.Add($Matches[1].Trim()) }
        }
    }
    foreach ($m in ([regex]'(?mi)^\[([^\]]+\.fx)\]').Matches($texto)) { [void]$exigidos.Add($m.Groups[1].Value.Trim()) }

    $instaladosFx = @()
    if (Test-Path -LiteralPath $pastaShaders) {
        $instaladosFx = @(Get-ChildItem -LiteralPath $pastaShaders -Filter '*.fx' -Recurse -File -ErrorAction SilentlyContinue |
                          Select-Object -ExpandProperty Name)
    }
    $faltando = @($exigidos | Where-Object { $instaladosFx -notcontains $_ } | Sort-Object)
    Passo "efeitos exigidos pelo preset: $($exigidos.Count); faltando: $($faltando.Count)"

    $achados = @{}
    $headers = New-Object System.Collections.Generic.List[object]
    if ($faltando.Count -gt 0 -and $PastaDownloads -and (Test-Path -LiteralPath $PastaDownloads)) {
        foreach ($zip in (Get-ChildItem -LiteralPath $PastaDownloads -Filter '*.zip' -File)) {
            try {
                $arq = [System.IO.Compression.ZipFile]::OpenRead($zip.FullName)
                try {
                    foreach ($e in $arq.Entries) {
                        $n = [System.IO.Path]::GetFileName($e.FullName)
                        if (-not $n) { continue }
                        if (($faltando -contains $n) -and -not $achados.ContainsKey($n)) {
                            $achados[$n] = @{ Zip = $zip.FullName; Entrada = $e.FullName }
                        }
                        if ([System.IO.Path]::GetExtension($n) -ieq '.fxh') {
                            $headers.Add(@{ Zip = $zip.FullName; Entrada = $e.FullName; Nome = $n })
                        }
                    }
                } finally { $arq.Dispose() }
            } catch { }
        }
    }

    if (-not $Simular) {
        if (-not (Test-Path -LiteralPath $pastaShaders)) { New-Item -ItemType Directory -Path $pastaShaders -Force | Out-Null }
        foreach ($n in $achados.Keys) {
            $info = $achados[$n]
            $arq = [System.IO.Compression.ZipFile]::OpenRead($info.Zip)
            try {
                $ent = $arq.GetEntry($info.Entrada)
                if ($ent) {
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($ent, (Join-Path $pastaShaders $n), $true)
                    Ok "shader instalado: $n"
                }
                foreach ($h in ($headers | Where-Object { $_.Zip -eq $info.Zip })) {
                    $alvo = Join-Path $pastaShaders $h.Nome
                    if (-not (Test-Path -LiteralPath $alvo)) {
                        $eh = $arq.GetEntry($h.Entrada)
                        if ($eh) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($eh, $alvo, $true) }
                    }
                }
            } finally { $arq.Dispose() }
        }

        Copy-Item -LiteralPath $reshadeIni -Destination "$reshadeIni.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
        $conf = Get-Content -LiteralPath $reshadeIni -Raw

        function Set-ChaveIni {
            param([string]$Texto, [string]$Chave, [string]$Valor)
            if ($Texto -match "(?mi)^$([regex]::Escape($Chave))=") {
                return [regex]::Replace($Texto, "(?mi)^$([regex]::Escape($Chave))=.*$", "$Chave=$Valor")
            }
            if ($Texto -match '(?mi)^\[GENERAL\]\s*$') {
                return [regex]::Replace($Texto, '(?mi)^(\[GENERAL\]\s*\r?\n)', "`$1$Chave=$Valor`r`n", 1)
            }
            return $Texto.TrimEnd() + "`r`n`r`n[GENERAL]`r`n$Chave=$Valor`r`n"
        }
        function Add-CaminhoBusca {
            param([string]$Texto, [string]$Chave, [string]$C)
            $m = [regex]::Match($Texto, "(?mi)^$([regex]::Escape($Chave))=(.*)$")
            if ($m.Success) {
                $atual = $m.Groups[1].Value
                if ($atual -split ',' | Where-Object { $_.Trim() -ieq $C }) { return $Texto }
                return Set-ChaveIni -Texto $Texto -Chave $Chave -Valor (($atual.TrimEnd(',') + ',' + $C).TrimStart(','))
            }
            return Set-ChaveIni -Texto $Texto -Chave $Chave -Valor $C
        }

        $conf = Set-ChaveIni     -Texto $conf -Chave 'PresetPath'         -Valor $preset
        $conf = Add-CaminhoBusca -Texto $conf -Chave 'EffectSearchPaths'  -C '.\reshade-shaders\Shaders'
        $conf = Add-CaminhoBusca -Texto $conf -Chave 'TextureSearchPaths' -C '.\reshade-shaders\Textures'
        Set-Content -LiteralPath $reshadeIni -Value $conf -NoNewline -Encoding ASCII
        Ok 'ReShade.ini apontado para o preset'
    }

    $semSolucao = @($faltando | Where-Object { -not $achados.ContainsKey($_) })
    if ($semSolucao.Count -gt 0) {
        Aviso "efeitos sem origem encontrada: $($semSolucao -join ', ')"
        Passo 'sem eles o preset carrega incompleto - baixe o pacote de shaders correspondente'
    }
}

# ===========================================================================
# 5. Relatorio final
# ===========================================================================
Titulo 'Como ficou'

$itens = @(
    @{ N = 'ScriptHookRDR2'; T = { (Test-Path -LiteralPath (Join-Path $jogo 'ScriptHookRDR2.dll')) -and
                                   (Test-Path -LiteralPath (Join-Path $jogo 'dinput8.dll')) } },
    @{ N = "Lenny's Mod Loader"; T = { (Test-Path -LiteralPath (Join-Path $jogo 'ModManager.asi')) -and
                                       (Test-Path -LiteralPath (Join-Path $jogo 'lml')) } },
    @{ N = 'ReShade'; T = { Test-Path -LiteralPath $reshadeIni } },
    @{ N = 'Shaders do ReShade'; T = { (Test-Path -LiteralPath $pastaShaders) -and
                                        @(Get-ChildItem -LiteralPath $pastaShaders -Filter '*.fx' -File -ErrorAction SilentlyContinue).Count -gt 0 } }
)
foreach ($i in $itens) {
    if (& $i.T) { Ok $i.N } else { Erro "$($i.N) - ainda falta" }
}

$modsLml = @(Get-ChildItem -LiteralPath (Join-Path $jogo 'lml') -Directory -ErrorAction SilentlyContinue)
if ($modsLml.Count -gt 0) { Ok "mods de conteudo em lml\: $(($modsLml | Select-Object -ExpandProperty Name) -join ', ')" }

Write-Host ''
Write-Host 'PROXIMOS PASSOS' -ForegroundColor Cyan
Write-Host '  1. abra o RDR2 e entre no MODO HISTORIA'
Write-Host '  2. dentro do jogo, aperte a tecla Home para abrir o ReShade'
Write-Host '  3. confira o preset selecionado no topo, sem linhas vermelhas na lista'
Write-Host ''
Write-Host 'SE O JOGO NAO ABRIR' -ForegroundColor Yellow
Write-Host '  quase sempre e o ScriptHookRDR2 velho demais para a versao atual do jogo.'
Write-Host "  renomeie $jogo\dinput8.dll para dinput8.dll.off e tente de novo:"
Write-Host '  se abrir, baixe a versao mais nova do ScriptHookRDR2.'
Write-Host ''
Write-Host 'ANTES DE ENTRAR NO RED DEAD ONLINE' -ForegroundColor Red
Write-Host '  tire os mods: renomeie dinput8.dll, ModManager.asi e a pasta lml.'
Write-Host '  mods no Online sao risco de banimento.'
Write-Host ''
