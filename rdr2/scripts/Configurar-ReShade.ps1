<#
.SYNOPSIS
    Ativa um preset de ReShade no RDR2: instala os shaders que ele exige e
    aponta o ReShade para o preset.

.DESCRIPTION
    Um preset de ReShade e so um arquivo .ini com uma lista de efeitos. Se os
    arquivos .fx correspondentes nao estiverem em reshade-shaders\Shaders, o
    preset carrega "vazio" e nada muda na tela - e a causa mais comum de
    "instalei o preset e nao aconteceu nada".

    Este script:
      1. encontra o preset (.ini) na pasta do jogo;
      2. le quais efeitos .fx ele exige;
      3. procura os .fx que faltam nos .zip da sua pasta de Downloads
         (SweetFX, reshade-shaders, pacotes do proprio preset) e os instala;
      4. escreve PresetPath e os caminhos de busca no ReShade.ini,
         guardando uma copia do arquivo original antes.

    Por padrao apenas mostra o plano. Use -Aplicar para efetivar.

.PARAMETER Preset
    Caminho do .ini do preset. Se omitido, procura na pasta do jogo.

.PARAMETER Caminho
    Pasta do jogo. Descoberta automaticamente se omitida.

.PARAMETER PastaDownloads
    Onde procurar os .zip com os shaders. Padrao: sua pasta Downloads.

.PARAMETER Aplicar
    Executa as mudancas. Sem isso, so mostra o que faria.

.EXAMPLE
    .\Configurar-ReShade.ps1

.EXAMPLE
    .\Configurar-ReShade.ps1 -Aplicar
#>
[CmdletBinding()]
param(
    [string]$Preset,
    [string]$Caminho,
    [string]$PastaDownloads,
    [switch]$Aplicar
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

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

$jogo = Get-PastaJogo -Sugerida $Caminho
$pastaShaders = Join-Path $jogo 'reshade-shaders\Shaders'
$reshadeIni = Join-Path $jogo 'ReShade.ini'

if (-not $PastaDownloads) {
    foreach ($c in @((Join-Path $env:USERPROFILE 'Downloads'), (Join-Path $env:USERPROFILE 'Transferencias'))) {
        if ($c -and (Test-Path -LiteralPath $c)) { $PastaDownloads = $c; break }
    }
}

Write-Host ''
Write-Host '=== Configurar ReShade (preset + shaders) ===' -ForegroundColor Cyan
Write-Host "Jogo: $jogo"

if (-not (Test-Path -LiteralPath $reshadeIni)) {
    Write-Host ''
    Write-Host 'ReShade.ini nao existe - o ReShade ainda nao foi instalado neste jogo.' -ForegroundColor Red
    Write-Host 'Rode o instalador oficial do ReShade primeiro:' -ForegroundColor Yellow
    Write-Host "  - selecione $jogo\RDR2.exe" -ForegroundColor Yellow
    Write-Host '  - escolha a MESMA API que o jogo usa (veja com Verificar-Instalacao.ps1)' -ForegroundColor Yellow
    Write-Host '  - marque os pacotes de shaders oferecidos' -ForegroundColor Yellow
    Write-Host 'Depois rode este script de novo.' -ForegroundColor Yellow
    exit 1
}

# ---------------------------------------------------------------------------
# 1. Localizar o preset
# ---------------------------------------------------------------------------
function Test-EhPreset {
    param([string]$Arquivo)
    try {
        $t = Get-Content -LiteralPath $Arquivo -Raw -ErrorAction Stop
        return ($t -match '(?m)^\s*Techniques\s*=' -or $t -match '(?m)^\[[^\]]+\.fx\]')
    } catch { return $false }
}

if (-not $Preset) {
    $candidatos = @(Get-ChildItem -LiteralPath $jogo -Filter '*.ini' -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -ne 'ReShade.ini' -and (Test-EhPreset $_.FullName) })
    $candidatos += @(Get-ChildItem -LiteralPath (Join-Path $jogo 'reshade-presets') -Filter '*.ini' -File -Recurse -ErrorAction SilentlyContinue |
                     Where-Object { Test-EhPreset $_.FullName })
    if ($candidatos.Count -eq 0) {
        Write-Host ''
        Write-Host 'Nenhum preset (.ini com lista de efeitos) encontrado na pasta do jogo.' -ForegroundColor Red
        Write-Host 'Copie o .ini do preset para a pasta do jogo, ou use -Preset "caminho\do\preset.ini".' -ForegroundColor Yellow
        exit 1
    }
    if ($candidatos.Count -gt 1) {
        Write-Host ''
        Write-Host 'Mais de um preset encontrado:' -ForegroundColor Yellow
        $candidatos | ForEach-Object { Write-Host "  - $($_.FullName)" }
        Write-Host 'Escolhendo o mais recente. Use -Preset para indicar outro.' -ForegroundColor Yellow
    }
    $Preset = ($candidatos | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
}
if (-not (Test-Path -LiteralPath $Preset)) { throw "Preset nao encontrado: $Preset" }
$Preset = (Resolve-Path -LiteralPath $Preset).Path
Write-Host "Preset: $Preset" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. Descobrir quais .fx o preset exige
# ---------------------------------------------------------------------------
$textoPreset = Get-Content -LiteralPath $Preset -Raw
$exigidos = New-Object System.Collections.Generic.HashSet[string]

# a) linha Techniques=Nome@Arquivo.fx,Outro@Outro.fx
foreach ($m in ([regex]'(?mi)^\s*Techniques\s*=(.*)$').Matches($textoPreset)) {
    foreach ($parte in $m.Groups[1].Value -split ',') {
        if ($parte -match '@\s*([^,\s]+\.fx)') { [void]$exigidos.Add($Matches[1].Trim()) }
    }
}
# b) secoes [Arquivo.fx]
foreach ($m in ([regex]'(?mi)^\[([^\]]+\.fx)\]').Matches($textoPreset)) {
    [void]$exigidos.Add($m.Groups[1].Value.Trim())
}

if ($exigidos.Count -eq 0) {
    Write-Host 'O preset nao declara efeitos - nada a instalar. Verifique se o arquivo esta completo.' -ForegroundColor Yellow
    exit 1
}

$instalados = @()
if (Test-Path -LiteralPath $pastaShaders) {
    $instalados = @(Get-ChildItem -LiteralPath $pastaShaders -Filter '*.fx' -Recurse -File -ErrorAction SilentlyContinue |
                    Select-Object -ExpandProperty Name)
}
$faltando = @($exigidos | Where-Object { $instalados -notcontains $_ } | Sort-Object)
$presentes = @($exigidos | Where-Object { $instalados -contains $_ } | Sort-Object)

Write-Host ''
Write-Host "Efeitos exigidos pelo preset: $($exigidos.Count)"
if ($presentes) { Write-Host "  ja instalados: $($presentes -join ', ')" -ForegroundColor Green }
if ($faltando)  { Write-Host "  faltando     : $($faltando -join ', ')" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# 3. Procurar os .fx que faltam nos zips baixados
# ---------------------------------------------------------------------------
$achados = @{}   # nome do .fx -> @{ Zip; Entrada }
$cabecalhos = New-Object System.Collections.Generic.List[object]

if ($faltando.Count -gt 0 -and $PastaDownloads -and (Test-Path -LiteralPath $PastaDownloads)) {
    Write-Host ''
    Write-Host "Procurando os shaders que faltam em: $PastaDownloads" -ForegroundColor Cyan
    foreach ($zip in (Get-ChildItem -LiteralPath $PastaDownloads -Filter '*.zip' -File)) {
        try {
            $arq = [System.IO.Compression.ZipFile]::OpenRead($zip.FullName)
            try {
                foreach ($e in $arq.Entries) {
                    $nome = [System.IO.Path]::GetFileName($e.FullName)
                    if (-not $nome) { continue }
                    if (($faltando -contains $nome) -and (-not $achados.ContainsKey($nome))) {
                        $achados[$nome] = @{ Zip = $zip.FullName; Entrada = $e.FullName }
                    }
                    # .fxh sao dependencias comuns dos .fx
                    if ([System.IO.Path]::GetExtension($nome) -ieq '.fxh') {
                        $cabecalhos.Add(@{ Zip = $zip.FullName; Entrada = $e.FullName; Nome = $nome })
                    }
                }
            } finally { $arq.Dispose() }
        } catch {
            Write-Host "  (nao consegui ler $($zip.Name): $($_.Exception.Message))" -ForegroundColor DarkYellow
        }
    }
    foreach ($f in $faltando) {
        if ($achados.ContainsKey($f)) {
            Write-Host "  achado : $f  <- $(Split-Path $achados[$f].Zip -Leaf)" -ForegroundColor Green
        } else {
            Write-Host "  NAO achado: $f" -ForegroundColor Red
        }
    }
}

$semSolucao = @($faltando | Where-Object { -not $achados.ContainsKey($_) })

# ---------------------------------------------------------------------------
# 4. Plano de escrita no ReShade.ini
# ---------------------------------------------------------------------------
$caminhoEfeitos = '.\reshade-shaders\Shaders'
$caminhoTexturas = '.\reshade-shaders\Textures'

Write-Host ''
Write-Host 'Mudancas em ReShade.ini:' -ForegroundColor Cyan
Write-Host "  PresetPath          = $Preset"
Write-Host "  EffectSearchPaths  += $caminhoEfeitos"
Write-Host "  TextureSearchPaths += $caminhoTexturas"

if (-not $Aplicar) {
    Write-Host ''
    Write-Host 'SIMULACAO - nada foi alterado. Para efetivar:' -ForegroundColor Yellow
    Write-Host '  .\Configurar-ReShade.ps1 -Aplicar' -ForegroundColor Yellow
    if ($semSolucao.Count -gt 0) {
        Write-Host ''
        Write-Host "Atencao: $($semSolucao.Count) efeito(s) sem origem conhecida: $($semSolucao -join ', ')" -ForegroundColor Red
        Write-Host 'Baixe o pacote de shaders correspondente (ex.: SweetFX, qUINT, Legacy) antes de aplicar.' -ForegroundColor Yellow
    }
    Write-Host ''
    exit 0
}

# ---------------------------------------------------------------------------
# 5. Aplicar
# ---------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $pastaShaders)) { New-Item -ItemType Directory -Path $pastaShaders -Force | Out-Null }

$copiados = 0
foreach ($nome in $achados.Keys) {
    $info = $achados[$nome]
    $arq = [System.IO.Compression.ZipFile]::OpenRead($info.Zip)
    try {
        $entrada = $arq.GetEntry($info.Entrada)
        if ($entrada) {
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile(
                $entrada, (Join-Path $pastaShaders $nome), $true)
            Write-Host "instalado: $nome" -ForegroundColor Green
            $copiados++
        }
        # dependencias .fxh vindas do mesmo pacote
        foreach ($h in ($cabecalhos | Where-Object { $_.Zip -eq $info.Zip })) {
            $alvo = Join-Path $pastaShaders $h.Nome
            if (-not (Test-Path -LiteralPath $alvo)) {
                $eh = $arq.GetEntry($h.Entrada)
                if ($eh) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($eh, $alvo, $true) }
            }
        }
    } finally { $arq.Dispose() }
}

# ReShade.ini: backup e escrita
$backupIni = "$reshadeIni.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item -LiteralPath $reshadeIni -Destination $backupIni -Force
Write-Host "backup do ReShade.ini em: $(Split-Path $backupIni -Leaf)" -ForegroundColor DarkGray

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
    param([string]$Texto, [string]$Chave, [string]$Caminho)
    $m = [regex]::Match($Texto, "(?mi)^$([regex]::Escape($Chave))=(.*)$")
    if ($m.Success) {
        $atual = $m.Groups[1].Value
        if ($atual -split ',' | Where-Object { $_.Trim() -ieq $Caminho }) { return $Texto }
        return Set-ChaveIni -Texto $Texto -Chave $Chave -Valor (($atual.TrimEnd(',') + ',' + $Caminho).TrimStart(','))
    }
    return Set-ChaveIni -Texto $Texto -Chave $Chave -Valor $Caminho
}

$conf = Set-ChaveIni     -Texto $conf -Chave 'PresetPath'         -Valor $Preset
$conf = Add-CaminhoBusca -Texto $conf -Chave 'EffectSearchPaths'  -Caminho $caminhoEfeitos
$conf = Add-CaminhoBusca -Texto $conf -Chave 'TextureSearchPaths' -Caminho $caminhoTexturas
Set-Content -LiteralPath $reshadeIni -Value $conf -NoNewline -Encoding ASCII

Write-Host ''
Write-Host "$copiados shader(s) instalado(s); ReShade.ini atualizado." -ForegroundColor Green
if ($semSolucao.Count -gt 0) {
    Write-Host ''
    Write-Host "AINDA FALTAM: $($semSolucao -join ', ')" -ForegroundColor Red
    Write-Host 'Sem eles o preset carrega incompleto. Baixe o pacote de shaders correspondente.' -ForegroundColor Yellow
}
Write-Host ''
Write-Host 'No jogo: pressione Home, confirme o preset selecionado no topo do overlay' -ForegroundColor Cyan
Write-Host 'e veja se a lista de efeitos aparece sem erros em vermelho.' -ForegroundColor Cyan
Write-Host ''
