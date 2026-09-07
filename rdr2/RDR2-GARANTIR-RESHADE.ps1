<#
    RDR2 - GARANTIR O RESHADE
    =========================
    Nao sai do ar enquanto o ReShade nao estiver comprovadamente instalado
    e o preset grafico ativo.

    O que ele faz:
      1. descobre a API grafica que o SEU jogo usa (DX12 ou Vulkan)
      2. confere se o ReShade ja esta instalado - e se esta na API CERTA
      3. se nao estiver, tenta instalar sozinho pelo instalador que voce baixou
      4. se a instalacao automatica nao funcionar, abre o instalador e espera
         voce clicar, conferindo o resultado a cada tentativa
      5. instala os shaders que o preset exige e aponta o ReShade para ele
      6. no fim, faz uma verificacao final e diz APROVADO ou o que falta

    COMO USAR
        powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\RDR2-GARANTIR-RESHADE.ps1"
#>
[CmdletBinding()]
param(
    [string]$Caminho,
    [string]$PastaDownloads,
    [string]$Instalador,
    [switch]$SemInteracao
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
Write-Host '#  RDR2 - garantir o ReShade                   #' -ForegroundColor Cyan
Write-Host '################################################' -ForegroundColor Cyan

# ===========================================================================
# Localizar jogo, Downloads e API grafica
# ===========================================================================
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
if (-not $jogo) {
    Erro 'Nao encontrei o RDR2. Rode de novo com -Caminho "D:\...\Red Dead Redemption 2".'
    exit 1
}
$exeJogo = Join-Path $jogo 'RDR2.exe'
Ok "jogo: $jogo"

if (-not $PastaDownloads) {
    foreach ($c in @((Join-Path $env:USERPROFILE 'Downloads'), (Join-Path $env:USERPROFILE 'Transferencias'))) {
        if ($c -and (Test-Path -LiteralPath $c)) { $PastaDownloads = $c; break }
    }
}

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
$api = $null
if ($docs) {
    $sx = Join-Path $docs 'Rockstar Games\Red Dead Redemption 2\Settings\system.xml'
    if (Test-Path -LiteralPath $sx) {
        if ((Get-Content -LiteralPath $sx -Raw) -match 'kSettingAPI_(\w+)') { $api = $Matches[1] }
    }
}
if ($api) {
    Ok "API grafica do seu jogo: $api"
} else {
    Aviso 'nao consegui ler a API do system.xml - vou assumir DX12 (padrao do RDR2)'
    $api = 'DX12'
}
$ehVulkan = ($api -match 'Vulkan')

# ===========================================================================
# Verificacao: o ReShade esta instalado e na API certa?
# ===========================================================================
function Test-EhReShade {
    param([string]$A)
    try {
        $i = (Get-Item -LiteralPath $A).VersionInfo
        return (("$($i.FileDescription) $($i.ProductName) $($i.CompanyName)") -match 'ReShade')
    } catch { return $false }
}

function Get-EstadoReShade {
    $dlls = @()
    foreach ($n in @('dxgi.dll', 'd3d12.dll', 'd3d11.dll', 'opengl32.dll', 'ReShade64.dll')) {
        $p = Join-Path $jogo $n
        if ((Test-Path -LiteralPath $p) -and (Test-EhReShade $p)) { $dlls += $n }
    }
    $camadaVulkan = $false
    foreach ($ch in @('HKLM:\SOFTWARE\Khronos\Vulkan\ImplicitLayers', 'HKCU:\SOFTWARE\Khronos\Vulkan\ImplicitLayers')) {
        try {
            $p = Get-ItemProperty -Path $ch -ErrorAction Stop
            if (($p.PSObject.Properties.Name -join ' ') -match 'ReShade') { $camadaVulkan = $true }
        } catch { }
    }
    $ini = Test-Path -LiteralPath (Join-Path $jogo 'ReShade.ini')
    return [pscustomobject]@{
        Dlls         = $dlls
        CamadaVulkan = $camadaVulkan
        TemIni       = $ini
        # Instalado de forma COERENTE com a API que o jogo usa:
        Instalado    = if ($ehVulkan) { $camadaVulkan } else { $dlls.Count -gt 0 }
    }
}

Titulo 'Conferindo o ReShade'
$estado = Get-EstadoReShade

if ($estado.Instalado) {
    if ($ehVulkan) { Ok 'ReShade instalado no modo Vulkan (camada global)' }
    else { Ok "ReShade instalado: $($estado.Dlls -join ', ')" }
} else {
    # Caso traicoeiro: instalado, mas para a API errada. E o motivo n.1 de
    # "instalei e nao mudou nada" - o jogo nunca carrega essa DLL.
    if ($ehVulkan -and $estado.Dlls.Count -gt 0) {
        Erro "seu jogo roda em Vulkan, mas o ReShade foi instalado como $($estado.Dlls -join ', ') (modo DirectX)"
        Passo 'nesse modo o jogo NUNCA carrega o ReShade - por isso nada muda na tela'
        Passo 'solucao: reinstalar o ReShade escolhendo Vulkan, ou trocar o jogo para DX12'
    } elseif ((-not $ehVulkan) -and $estado.CamadaVulkan) {
        Erro 'o ReShade esta instalado no modo Vulkan, mas seu jogo roda em DX12'
        Passo 'solucao: reinstalar o ReShade escolhendo DirectX'
    } else {
        Aviso 'ReShade ainda nao esta instalado neste jogo'
    }
}

# ===========================================================================
# Instalar o ReShade, se preciso
# ===========================================================================
if (-not $estado.Instalado) {
    Titulo 'Instalando o ReShade'

    if (-not $Instalador) {
        $cands = @()
        if ($PastaDownloads -and (Test-Path -LiteralPath $PastaDownloads)) {
            $cands = @(Get-ChildItem -LiteralPath $PastaDownloads -Filter '*.exe' -File -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -match 'ReShade' } |
                       Sort-Object LastWriteTime -Descending)
        }
        if ($cands.Count -gt 0) { $Instalador = $cands[0].FullName }
    }

    if (-not $Instalador) {
        Erro 'nao achei o instalador do ReShade na sua pasta Downloads'
        Passo 'baixe em https://reshade.me (botao Download) e rode este script de novo'
        Passo 'ou aponte o arquivo: -Instalador "C:\Users\voce\Downloads\ReShade_Setup_6.x.x.exe"'
        exit 1
    }
    Ok "instalador: $(Split-Path $Instalador -Leaf)"

    # As instrucoes vem ANTES de abrir qualquer coisa: a tentativa automatica
    # abaixo pode acabar abrindo a janela do instalador (se esta versao nao
    # aceitar os parametros), e nesse caso voce ja sabe o que clicar.
    Write-Host ''
    Write-Host '  SE UMA JANELA DO INSTALADOR ABRIR, faca assim nela:' -ForegroundColor Yellow
    Write-Host "    1. clique em 'Browse' e selecione este arquivo:" -ForegroundColor Yellow
    Write-Host "       $exeJogo" -ForegroundColor White
    if ($ehVulkan) {
        Write-Host '    2. escolha VULKAN  <-- e a API que o SEU jogo usa' -ForegroundColor White
    } else {
        Write-Host '    2. escolha DirectX 10/11/12  <-- e a API que o SEU jogo usa' -ForegroundColor White
    }
    Write-Host '    3. quando perguntar dos shaders, marque TODOS os pacotes oferecidos' -ForegroundColor Yellow
    Write-Host '    4. termine e volte para esta janela do PowerShell' -ForegroundColor Yellow
    Write-Host ''

    # Tentativa automatica: as versoes recentes do instalador aceitam o exe do
    # jogo e a API por linha de comando. Se esta versao nao aceitar, ela abre a
    # janela normal - e as instrucoes acima ja cobrem esse caso.
    $apiArg = if ($ehVulkan) { 'vulkan' } else { 'd3d12' }
    Passo "tentando instalar sozinho (API $apiArg)..."
    try {
        Start-Process -FilePath $Instalador -ArgumentList @($exeJogo, '--api', $apiArg, '--headless') `
                      -Wait -ErrorAction Stop | Out-Null
        Start-Sleep -Seconds 2
        $estado = Get-EstadoReShade
    } catch {
        Passo "  (nao deu para automatizar: $($_.Exception.Message))"
    }

    if ($estado.Instalado) {
        Ok 'ReShade instalado'
    } elseif ($SemInteracao) {
        Erro 'nao consegui instalar sozinho e o modo sem interacao esta ligado'
        exit 1
    } else {
        # Nao desiste: reabre o instalador e confere depois de cada tentativa.
        for ($i = 1; $i -le 5; $i++) {
            Write-Host ''
            Write-Host "  Termine a instalacao e aperte ENTER aqui (tentativa $i de 5)..." -ForegroundColor Cyan
            [void](Read-Host)
            $estado = Get-EstadoReShade
            if ($estado.Instalado) { Ok 'ReShade confirmado'; break }

            if ($ehVulkan -and $estado.Dlls.Count -gt 0) {
                Erro 'foi instalado em modo DirectX, mas seu jogo usa Vulkan - refaca escolhendo Vulkan'
            } elseif ((-not $ehVulkan) -and $estado.CamadaVulkan) {
                Erro 'foi instalado em modo Vulkan, mas seu jogo usa DX12 - refaca escolhendo DirectX'
            } else {
                Erro 'ainda nao achei o ReShade na pasta do jogo - confira se selecionou o RDR2.exe certo'
            }
            if ($i -lt 5) {
                Passo 'vou abrir o instalador de novo...'
                try { Start-Process -FilePath $Instalador -ErrorAction Stop | Out-Null } catch { }
            }
        }
    }
}

if (-not $estado.Instalado) {
    Titulo 'RESULTADO'
    Erro 'nao consegui confirmar o ReShade instalado.'
    Passo "conferi a pasta: $jogo"
    Passo 'me mande a tela deste script que eu ajusto o passo que falhou.'
    exit 1
}

# ===========================================================================
# Preset + shaders
# ===========================================================================
Titulo 'Preset grafico'

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

$semSolucao = @()
if ($presets.Count -eq 0) {
    Aviso 'nenhum preset encontrado - o ReShade vai funcionar, mas sem o visual do preset'
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
    Passo "efeitos exigidos: $($exigidos.Count); faltando: $($faltando.Count)"

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

    $semSolucao = @($faltando | Where-Object { -not $achados.ContainsKey($_) })
}

# ===========================================================================
# Verificacao final
# ===========================================================================
Titulo 'VERIFICACAO FINAL'

$estado = Get-EstadoReShade
$checks = @()
$checks += @{ N = 'ReShade instalado na API do seu jogo'; Ok = $estado.Instalado }
$checks += @{ N = 'ReShade.ini presente';                 Ok = (Test-Path -LiteralPath $reshadeIni) }
$checks += @{ N = 'pasta de shaders com efeitos';         Ok = ((Test-Path -LiteralPath $pastaShaders) -and
                    @(Get-ChildItem -LiteralPath $pastaShaders -Filter '*.fx' -File -ErrorAction SilentlyContinue).Count -gt 0) }
if ($presets.Count -gt 0) {
    $confFinal = Get-Content -LiteralPath $reshadeIni -Raw
    $checks += @{ N = 'preset apontado no ReShade.ini'; Ok = ($confFinal -match '(?mi)^PresetPath=.+') }
    $checks += @{ N = 'todos os efeitos do preset presentes'; Ok = ($semSolucao.Count -eq 0) }
}

$tudoOk = $true
foreach ($c in $checks) {
    if ($c.Ok) { Ok $c.N } else { Erro $c.N; $tudoOk = $false }
}

Write-Host ''
if ($tudoOk) {
    Write-Host '  APROVADO - o ReShade esta instalado e o preset ativo.' -ForegroundColor Green
    Write-Host ''
    Write-Host '  Agora abra o RDR2 e aperte Home. O preset deve aparecer no topo do overlay.' -ForegroundColor Green
} else {
    Write-Host '  AINDA FALTA ALGO - veja as linhas [erro] acima.' -ForegroundColor Red
    if ($semSolucao.Count -gt 0) {
        Write-Host "  Efeitos sem origem: $($semSolucao -join ', ')" -ForegroundColor Red
        Write-Host '  Rode o instalador do ReShade de novo e marque TODOS os pacotes de shaders.' -ForegroundColor Yellow
    }
    Write-Host '  Me mande esta tela que eu ajusto.' -ForegroundColor Yellow
}
Write-Host ''
