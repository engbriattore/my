<#
    RDR2 - RESHADE 100% POR CODIGO
    ==============================
    Instala o ReShade sem voce clicar em nada.

    O instalador grafico do ReShade, no fundo, so faz tres coisas:
      - copia a ReShade64.dll para a pasta do jogo com o nome que a API usa
        (em DirectX 12 o jogo carrega "dxgi.dll")
      - cria o ReShade.ini
      - coloca os shaders em reshade-shaders\Shaders

    Este script faz as tres, tentando nesta ordem:
      1. rodar o instalador em modo silencioso (varias formas de parametro,
         cada uma com limite de tempo para nao travar)
      2. extrair a ReShade64.dll de dentro do instalador com o 7-Zip
      3. extrair a DLL lendo o proprio arquivo do instalador (sem 7-Zip)
    Depois resolve os shaders e o preset, e confere o resultado.

    COMO USAR
        powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\RDR2-RESHADE-AUTOMATICO.ps1"
#>
[CmdletBinding()]
param(
    [string]$Caminho,
    [string]$PastaDownloads,
    [string]$Instalador,
    [int]$SegundosPorTentativa = 25
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Titulo { param([string]$T) Write-Host ''; Write-Host "=== $T ===" -ForegroundColor Cyan }
function Ok    { param([string]$T) Write-Host "  [ok]    $T" -ForegroundColor Green }
function Aviso { param([string]$T) Write-Host "  [aviso] $T" -ForegroundColor Yellow }
function Erro  { param([string]$T) Write-Host "  [erro]  $T" -ForegroundColor Red }
function Passo { param([string]$T) Write-Host "  $T" -ForegroundColor Gray }

Write-Host ''
Write-Host '#############################################' -ForegroundColor Cyan
Write-Host '#  RDR2 - ReShade automatico (sem cliques)  #' -ForegroundColor Cyan
Write-Host '#############################################' -ForegroundColor Cyan

# ===========================================================================
# Localizacao
# ===========================================================================
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
$exeJogo = Join-Path $jogo 'RDR2.exe'
Ok "jogo: $jogo"

if (-not $PastaDownloads) {
    foreach ($c in @((Join-Path $env:USERPROFILE 'Downloads'), (Join-Path $env:USERPROFILE 'Transferencias'))) {
        if ($c -and (Test-Path -LiteralPath $c)) { $PastaDownloads = $c; break }
    }
}

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

$api = $null
if ($docs) {
    $sx = Join-Path $docs 'Rockstar Games\Red Dead Redemption 2\Settings\system.xml'
    if (Test-Path -LiteralPath $sx) { if ((Get-Content -LiteralPath $sx -Raw) -match 'kSettingAPI_(\w+)') { $api = $Matches[1] } }
}
if (-not $api) { $api = 'DX12'; Aviso 'nao li a API no system.xml - assumindo DX12 (padrao do RDR2)' } else { Ok "API do jogo: $api" }
$ehVulkan = ($api -match 'Vulkan')

if ($ehVulkan) {
    Write-Host ''
    Aviso 'seu jogo esta em VULKAN.'
    Passo 'a instalacao por codigo aqui cobre DirectX 12, que e o modo padrao do RDR2.'
    Passo 'no jogo, va em Configuracoes > Graficos > API e mude para DirectX 12,'
    Passo 'depois rode este script de novo. (DX12 e o recomendado para a sua RTX 3060.)'
    Write-Host ''
}

# DLL que o jogo carrega em DirectX: dxgi.dll
$dllAlvo = Join-Path $jogo 'dxgi.dll'
$reshadeIni = Join-Path $jogo 'ReShade.ini'
$pastaShaders = Join-Path $jogo 'reshade-shaders\Shaders'
$pastaTexturas = Join-Path $jogo 'reshade-shaders\Textures'

function Test-EhReShade {
    param([string]$A)
    try {
        $i = (Get-Item -LiteralPath $A).VersionInfo
        return (("$($i.FileDescription) $($i.ProductName) $($i.CompanyName)") -match 'ReShade')
    } catch { return $false }
}
function Test-ReShadeInstalado {
    foreach ($n in @('dxgi.dll', 'd3d12.dll', 'd3d11.dll', 'ReShade64.dll')) {
        $p = Join-Path $jogo $n
        if ((Test-Path -LiteralPath $p) -and (Test-EhReShade $p)) { return $true }
    }
    return $false
}

Titulo 'Estado atual'
if (Test-ReShadeInstalado) {
    Ok 'o ReShade ja esta instalado na pasta do jogo'
} else {
    Aviso 'ReShade ainda nao esta na pasta do jogo'

    # =======================================================================
    # Achar o instalador
    # =======================================================================
    if (-not $Instalador -and $PastaDownloads -and (Test-Path -LiteralPath $PastaDownloads)) {
        $c = @(Get-ChildItem -LiteralPath $PastaDownloads -Filter '*.exe' -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match 'ReShade' } | Sort-Object LastWriteTime -Descending)
        if ($c.Count -gt 0) { $Instalador = $c[0].FullName }
    }
    if (-not $Instalador) {
        Erro 'nao achei o instalador do ReShade em Downloads'
        Passo 'baixe em https://reshade.me e rode de novo, ou use -Instalador "caminho\do\setup.exe"'
        exit 1
    }
    Ok "instalador: $(Split-Path $Instalador -Leaf)"

    # =======================================================================
    # PLANO 1 - modo silencioso, varias formas de parametro
    # =======================================================================
    Titulo 'Plano 1: instalar em modo silencioso'

    # O ReShade agrupa DX10/11/12 sob o nome "dxgi" - por isso "dxgi" vem
    # primeiro; "d3d12" fica como alternativa para versoes que aceitem.
    $formas = @(
        @($exeJogo, '--api', 'dxgi', '--headless'),
        @($exeJogo, '--api', 'dxgi'),
        @($exeJogo, '--api', 'd3d12', '--headless'),
        @($exeJogo, '--api', 'd3d12')
    )
    foreach ($f in $formas) {
        if (Test-ReShadeInstalado) { break }
        Passo "tentando: $(($f | Select-Object -Skip 1) -join ' ')"
        try {
            $p = Start-Process -FilePath $Instalador -ArgumentList $f -PassThru -ErrorAction Stop
            # Limite de tempo: se abriu janela e ficou esperando clique, encerra
            # e passa para a proxima forma, em vez de travar o script.
            if (-not $p.WaitForExit($SegundosPorTentativa * 1000)) {
                Passo '  (abriu janela em vez de instalar - encerrando e tentando outra forma)'
                try { $p.Kill() } catch { }
            }
            Start-Sleep -Seconds 2
        } catch {
            Passo "  (falhou: $($_.Exception.Message))"
        }
    }
    if (Test-ReShadeInstalado) { Ok 'instalado pelo modo silencioso' }

    # =======================================================================
    # PLANO 2 - extrair a ReShade64.dll com o 7-Zip
    # =======================================================================
    if (-not (Test-ReShadeInstalado)) {
        Titulo 'Plano 2: extrair a DLL com o 7-Zip'
        $sete = @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") |
                Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if (-not $sete) {
            Passo '7-Zip nao encontrado - pulando este plano'
        } else {
            Ok "7-Zip: $sete"
            $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('reshade_' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $temp -Force | Out-Null
            try {
                & $sete e $Instalador "-o$temp" -r 'ReShade64.dll' -y 2>&1 | Out-Null
                $achada = Get-ChildItem -LiteralPath $temp -Filter 'ReShade64.dll' -Recurse -File -ErrorAction SilentlyContinue |
                          Select-Object -First 1
                if ($achada -and (Test-EhReShade $achada.FullName)) {
                    Copy-Item -LiteralPath $achada.FullName -Destination $dllAlvo -Force
                    Ok "DLL instalada como dxgi.dll"
                } elseif ($achada) {
                    Passo '  extraiu um arquivo, mas ele nao se identifica como ReShade - descartado'
                } else {
                    Passo '  o 7-Zip nao achou ReShade64.dll dentro do instalador'
                }
            } catch {
                Passo "  (falhou: $($_.Exception.Message))"
            } finally { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    # =======================================================================
    # PLANO 3 - achar a DLL lendo o proprio instalador
    # =======================================================================
    if (-not (Test-ReShadeInstalado)) {
        Titulo 'Plano 3: procurar a DLL dentro do instalador'
        $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('reshade_' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
        try {
            $bytes = [System.IO.File]::ReadAllBytes($Instalador)
            $achou = $false
            # Procurar "MZ" byte a byte em PowerShell levaria minutos num arquivo
            # de varios MB. Mapeando os bytes para texto 1-para-1 (ISO-8859-1),
            # o IndexOf do .NET faz a busca em tempo desprezivel.
            $comoTexto = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
            $posicoes = New-Object System.Collections.Generic.List[int]
            $busca = $comoTexto.IndexOf('MZ', 0x400)
            while ($busca -ge 0 -and $posicoes.Count -lt 200) {
                $posicoes.Add($busca)
                $busca = $comoTexto.IndexOf('MZ', $busca + 1)
            }
            Passo "  $($posicoes.Count) candidato(s) a arquivo embutido"

            foreach ($i in $posicoes) {
                if ($achou) { break }
                if ($i + 0x200 -ge $bytes.Length) { continue }
                $eLfanew = [BitConverter]::ToInt32($bytes, $i + 0x3C)
                if ($eLfanew -le 0 -or $eLfanew -gt 0x1000) { continue }
                $pe = $i + $eLfanew
                if ($pe + 0x100 -ge $bytes.Length) { continue }
                if ($bytes[$pe] -ne 0x50 -or $bytes[$pe + 1] -ne 0x45) { continue }   # "PE"
                $maquina = [BitConverter]::ToUInt16($bytes, $pe + 4)
                if ($maquina -ne 0x8664) { continue }                                  # x64
                $carac = [BitConverter]::ToUInt16($bytes, $pe + 22)
                if (($carac -band 0x2000) -eq 0) { continue }                          # e DLL
                $nSecoes = [BitConverter]::ToUInt16($bytes, $pe + 6)
                $tamOpc  = [BitConverter]::ToUInt16($bytes, $pe + 20)
                $secoes  = $pe + 24 + $tamOpc
                # Tamanho em disco = maior (offset + tamanho) entre as secoes.
                $fim = 0
                for ($s = 0; $s -lt $nSecoes; $s++) {
                    $h = $secoes + ($s * 40)
                    if ($h + 40 -gt $bytes.Length) { break }
                    $tam = [BitConverter]::ToInt32($bytes, $h + 16)
                    $off = [BitConverter]::ToInt32($bytes, $h + 20)
                    if ($off -gt 0 -and ($off + $tam) -gt $fim) { $fim = $off + $tam }
                }
                if ($fim -le 0 -or ($i + $fim) -gt $bytes.Length) { continue }

                $saida = Join-Path $temp 'candidata.dll'
                $recorte = New-Object byte[] $fim
                [Array]::Copy($bytes, $i, $recorte, 0, $fim)
                [System.IO.File]::WriteAllBytes($saida, $recorte)
                if (Test-EhReShade $saida) {
                    Copy-Item -LiteralPath $saida -Destination $dllAlvo -Force
                    Ok 'DLL encontrada dentro do instalador e instalada como dxgi.dll'
                    $achou = $true
                }
                Remove-Item -LiteralPath $saida -Force -ErrorAction SilentlyContinue
            }
            if (-not $achou) { Passo '  nao encontrei a DLL solta dentro do instalador (deve estar compactada)' }
        } catch {
            Passo "  (falhou: $($_.Exception.Message))"
        } finally { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if (-not (Test-ReShadeInstalado)) {
    Titulo 'RESULTADO'
    Erro 'nao consegui instalar o ReShade por codigo.'
    Passo 'os tres planos falharam - esta versao do instalador guarda a DLL compactada'
    Passo 'e nao aceita instalacao silenciosa. Nesse caso so o instalador grafico resolve:'
    Passo "  abra-o, clique em Browse, escolha $exeJogo e a API DirectX 10/11/12."
    Passo 'me mande esta tela que eu vejo outro caminho.'
    exit 1
}

# ===========================================================================
# Shaders
# ===========================================================================
Titulo 'Shaders'

if (-not (Test-Path -LiteralPath $pastaShaders))  { New-Item -ItemType Directory -Path $pastaShaders -Force | Out-Null }
if (-not (Test-Path -LiteralPath $pastaTexturas)) { New-Item -ItemType Directory -Path $pastaTexturas -Force | Out-Null }

function Get-QuantidadeFx {
    return @(Get-ChildItem -LiteralPath $pastaShaders -Filter '*.fx' -File -ErrorAction SilentlyContinue).Count
}

# Fonte 1: pacote oficial de shaders, baixado do repositorio publico.
if ((Get-QuantidadeFx) -lt 5) {
    foreach ($ramo in @('slim', 'master')) {
        if ((Get-QuantidadeFx) -ge 5) { break }
        $url = "https://github.com/crosire/reshade-shaders/archive/refs/heads/$ramo.zip"
        $zipTmp = Join-Path ([System.IO.Path]::GetTempPath()) "reshade-shaders-$ramo.zip"
        try {
            Passo "baixando pacote de shaders ($ramo)..."
            Invoke-WebRequest -Uri $url -OutFile $zipTmp -UseBasicParsing -TimeoutSec 120
            $destTmp = Join-Path ([System.IO.Path]::GetTempPath()) ('shaders_' + [guid]::NewGuid().ToString('N'))
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipTmp, $destTmp)
            foreach ($par in @(@{ F = 'Shaders'; D = $pastaShaders }, @{ F = 'Textures'; D = $pastaTexturas })) {
                $origem = Get-ChildItem -LiteralPath $destTmp -Directory -Recurse -ErrorAction SilentlyContinue |
                          Where-Object { $_.Name -eq $par.F } | Select-Object -First 1
                if ($origem) {
                    Copy-Item -Path (Join-Path $origem.FullName '*') -Destination $par.D -Recurse -Force
                }
            }
            Remove-Item -LiteralPath $destTmp -Recurse -Force -ErrorAction SilentlyContinue
            Ok "pacote de shaders instalado ($(Get-QuantidadeFx) efeitos)"
        } catch {
            Passo "  (nao deu para baixar de $ramo : $($_.Exception.Message))"
        } finally { Remove-Item -LiteralPath $zipTmp -Force -ErrorAction SilentlyContinue }
    }
} else {
    Ok "$(Get-QuantidadeFx) efeitos ja presentes"
}

# ===========================================================================
# Preset
# ===========================================================================
Titulo 'Preset grafico'

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

$semSolucao = @()
$preset = $null
if ($presets.Count -eq 0) {
    Aviso 'nenhum preset encontrado na pasta do jogo'
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

    $temFx = @(Get-ChildItem -LiteralPath $pastaShaders -Filter '*.fx' -Recurse -File -ErrorAction SilentlyContinue |
               Select-Object -ExpandProperty Name)
    $faltando = @($exigidos | Where-Object { $temFx -notcontains $_ } | Sort-Object)
    Passo "efeitos do preset: $($exigidos.Count); faltando: $($faltando.Count)"

    # Fonte 2: os .zip da sua pasta Downloads (SweetFX, legacy, etc.)
    if ($faltando.Count -gt 0 -and $PastaDownloads -and (Test-Path -LiteralPath $PastaDownloads)) {
        $achados = @{}
        $headers = New-Object System.Collections.Generic.List[object]
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
        $temFx = @(Get-ChildItem -LiteralPath $pastaShaders -Filter '*.fx' -Recurse -File -ErrorAction SilentlyContinue |
                   Select-Object -ExpandProperty Name)
        $semSolucao = @($exigidos | Where-Object { $temFx -notcontains $_ } | Sort-Object)
    }
}

# ===========================================================================
# ReShade.ini
# ===========================================================================
Titulo 'Configuracao'

if (Test-Path -LiteralPath $reshadeIni) {
    Copy-Item -LiteralPath $reshadeIni -Destination "$reshadeIni.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
    $conf = Get-Content -LiteralPath $reshadeIni -Raw
} else {
    $conf = "[GENERAL]`r`n"
}

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

$conf = Set-ChaveIni -Texto $conf -Chave 'EffectSearchPaths'  -Valor '.\reshade-shaders\Shaders'
$conf = Set-ChaveIni -Texto $conf -Chave 'TextureSearchPaths' -Valor '.\reshade-shaders\Textures'
if ($preset) { $conf = Set-ChaveIni -Texto $conf -Chave 'PresetPath' -Valor $preset }
Set-Content -LiteralPath $reshadeIni -Value $conf -NoNewline -Encoding ASCII
Ok 'ReShade.ini escrito'

# ===========================================================================
# Verificacao final
# ===========================================================================
Titulo 'VERIFICACAO FINAL'

$checks = @(
    @{ N = 'ReShade instalado (dxgi.dll na pasta do jogo)'; Ok = (Test-ReShadeInstalado) },
    @{ N = 'ReShade.ini criado';                            Ok = (Test-Path -LiteralPath $reshadeIni) },
    @{ N = 'shaders disponiveis';                           Ok = ((Get-QuantidadeFx) -gt 0) }
)
if ($preset) {
    $checks += @{ N = 'preset apontado'; Ok = ((Get-Content -LiteralPath $reshadeIni -Raw) -match '(?mi)^PresetPath=.+') }
    $checks += @{ N = 'efeitos do preset completos'; Ok = ($semSolucao.Count -eq 0) }
}

$tudoOk = $true
foreach ($c in $checks) { if ($c.Ok) { Ok $c.N } else { Erro $c.N; $tudoOk = $false } }

Write-Host ''
if ($tudoOk) {
    Write-Host '  APROVADO - abra o RDR2 e aperte Home.' -ForegroundColor Green
    if ($ehVulkan) {
        Write-Host '  LEMBRE: mude a API do jogo para DirectX 12, senao o ReShade nao carrega.' -ForegroundColor Yellow
    }
} else {
    Write-Host '  Faltou algo - veja as linhas [erro] acima.' -ForegroundColor Red
    if ($semSolucao.Count -gt 0) { Write-Host "  Efeitos sem origem: $($semSolucao -join ', ')" -ForegroundColor Red }
}
Write-Host ''
