<#
.SYNOPSIS
    Diagnostico da instalacao de mods e ReShade no Red Dead Redemption 2.

.DESCRIPTION
    Localiza a pasta do jogo, inspeciona cada componente da "pilha" de mods
    (ScriptHookRDR2, ASI Loader, Lenny's Mod Loader, mods de script, ReShade)
    e informa o que ja esta instalado, o que falta e qual e o proximo passo.

    Nao instala nem altera nada. E somente leitura.

.PARAMETER Caminho
    Pasta do jogo (a que contem RDR2.exe). Se omitido, o script procura sozinho.

.PARAMETER Json
    Alem do relatorio na tela, imprime o resultado em JSON (util para colar no chat).

.EXAMPLE
    .\Verificar-Instalacao.ps1

.EXAMPLE
    .\Verificar-Instalacao.ps1 -Caminho "D:\SteamLibrary\steamapps\common\Red Dead Redemption 2" -Json
#>
[CmdletBinding()]
param(
    [string]$Caminho,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$resultados = New-Object System.Collections.Generic.List[object]

function Add-Resultado {
    param(
        [Parameter(Mandatory)][string]$Etapa,
        [Parameter(Mandatory)][ValidateSet('OK', 'FALTA', 'AVISO', 'INFO')][string]$Status,
        [string]$Detalhe = '',
        [string]$Proximo = ''
    )
    $resultados.Add([pscustomobject]@{
        Etapa   = $Etapa
        Status  = $Status
        Detalhe = $Detalhe
        Proximo = $Proximo
    })
}

function Test-Arquivo {
    param([string]$Base, [string]$Relativo)
    Test-Path -LiteralPath (Join-Path $Base $Relativo)
}

function Get-VersaoArquivo {
    param([string]$Arquivo)
    try {
        $info = (Get-Item -LiteralPath $Arquivo).VersionInfo
        if ($info.FileVersion) { return $info.FileVersion.Trim() }
        return $null
    } catch { return $null }
}

function Test-EhReShade {
    param([string]$Arquivo)
    try {
        $info = (Get-Item -LiteralPath $Arquivo).VersionInfo
        return (("$($info.FileDescription) $($info.ProductName) $($info.CompanyName)") -match 'ReShade')
    } catch { return $false }
}

# Documentos do usuario: cobre OneDrive, Windows em portugues e perfis redirecionados.
function Get-PastaDocumentos {
    $possiveis = New-Object System.Collections.Generic.List[string]
    $shell = [Environment]::GetFolderPath('MyDocuments')
    if ($shell) { $possiveis.Add($shell) }
    if ($env:USERPROFILE) {
        foreach ($sub in @('Documents', 'Documentos', 'OneDrive\Documents', 'OneDrive\Documentos')) {
            $possiveis.Add((Join-Path $env:USERPROFILE $sub))
        }
    }
    # Prioriza a pasta que realmente contem os dados do jogo.
    foreach ($p in $possiveis) {
        if ((Test-Path -LiteralPath $p) -and
            (Test-Path -LiteralPath (Join-Path $p 'Rockstar Games\Red Dead Redemption 2'))) { return $p }
    }
    foreach ($p in $possiveis) { if (Test-Path -LiteralPath $p) { return $p } }
    return $null
}

# ---------------------------------------------------------------------------
# 1. Localizar a pasta do jogo
# ---------------------------------------------------------------------------
function Get-PastaJogo {
    param([string]$Sugerida)

    if ($Sugerida) {
        if (Test-Path -LiteralPath (Join-Path $Sugerida 'RDR2.exe')) {
            return (Resolve-Path -LiteralPath $Sugerida).Path
        }
        throw "Nao encontrei RDR2.exe em '$Sugerida'. Confira o caminho."
    }

    $candidatos = New-Object System.Collections.Generic.List[string]

    # a) Registro do Rockstar Games Launcher
    foreach ($chave in @(
        'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Red Dead Redemption 2',
        'HKLM:\SOFTWARE\Rockstar Games\Red Dead Redemption 2'
    )) {
        try {
            $prop = Get-ItemProperty -Path $chave -ErrorAction Stop
            foreach ($nome in @('InstallFolder', 'InstallLocation')) {
                if ($prop.$nome) { $candidatos.Add([string]$prop.$nome) }
            }
        } catch { }
    }

    # b) Bibliotecas da Steam declaradas em libraryfolders.vdf
    foreach ($vdf in @(
        "${env:ProgramFiles(x86)}\Steam\steamapps\libraryfolders.vdf",
        "$env:ProgramFiles\Steam\steamapps\libraryfolders.vdf"
    )) {
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in ([regex]'"path"\s+"(.+?)"').Matches((Get-Content -LiteralPath $vdf -Raw))) {
                $base = $m.Groups[1].Value -replace '\\\\', '\'
                $candidatos.Add((Join-Path $base 'steamapps\common\Red Dead Redemption 2'))
            }
        }
    }

    # c) Caminhos usuais, em todos os discos fixos
    $relativos = @(
        'Program Files\Rockstar Games\Red Dead Redemption 2',
        'Program Files (x86)\Rockstar Games\Red Dead Redemption 2',
        'Rockstar Games\Red Dead Redemption 2',
        'Games\Red Dead Redemption 2',
        'SteamLibrary\steamapps\common\Red Dead Redemption 2',
        'Steam\steamapps\common\Red Dead Redemption 2',
        'Program Files (x86)\Steam\steamapps\common\Red Dead Redemption 2',
        'Program Files\Epic Games\RedDeadRedemption2',
        'Epic Games\RedDeadRedemption2'
    )
    $discos = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' |
              Select-Object -ExpandProperty DeviceID
    foreach ($disco in $discos) {
        foreach ($rel in $relativos) { $candidatos.Add("$disco\$rel") }
    }

    foreach ($c in $candidatos) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c 'RDR2.exe'))) {
            return (Resolve-Path -LiteralPath $c).Path
        }
    }
    return $null
}

Write-Host ''
Write-Host '=== Diagnostico RDR2: mods + ReShade ===' -ForegroundColor Cyan
Write-Host ''

$jogo = Get-PastaJogo -Sugerida $Caminho
if (-not $jogo) {
    Write-Host 'Nao encontrei a pasta do jogo automaticamente.' -ForegroundColor Red
    Write-Host 'Rode de novo apontando a pasta que contem RDR2.exe, por exemplo:' -ForegroundColor Yellow
    Write-Host '  .\Verificar-Instalacao.ps1 -Caminho "D:\Games\Red Dead Redemption 2"' -ForegroundColor Yellow
    exit 1
}

$versaoJogo = Get-VersaoArquivo (Join-Path $jogo 'RDR2.exe')
Write-Host "Pasta do jogo : $jogo"
Write-Host "Versao RDR2.exe: $(if ($versaoJogo) { $versaoJogo } else { 'desconhecida' })"
Write-Host ''

Add-Resultado -Etapa 'Pasta do jogo' -Status 'INFO' -Detalhe $jogo
if ($versaoJogo) {
    Add-Resultado -Etapa 'Versao do jogo' -Status 'INFO' -Detalhe $versaoJogo `
        -Proximo 'Anote esta versao: mods de script so funcionam com um ScriptHook compativel com ela.'
}

if ($env:ProgramFiles -and ($jogo -like "$env:ProgramFiles*" -or $jogo -like "${env:ProgramFiles(x86)}*")) {
    Add-Resultado -Etapa 'Permissoes de pasta' -Status 'AVISO' `
        -Detalhe 'O jogo esta dentro de Arquivos de Programas (pasta protegida pelo Windows).' `
        -Proximo 'Copie os arquivos de mod com o Explorador em modo administrador, ou instaladores (ReShade) executados como administrador.'
}

# ---------------------------------------------------------------------------
# 2. API grafica configurada (DX12 x Vulkan) - decide como instalar o ReShade
# ---------------------------------------------------------------------------
$docs = Get-PastaDocumentos
$systemXml = if ($docs) { Join-Path $docs 'Rockstar Games\Red Dead Redemption 2\Settings\system.xml' } else { $null }
$api = $null
if ($systemXml -and (Test-Path -LiteralPath $systemXml)) {
    $texto = Get-Content -LiteralPath $systemXml -Raw
    if ($texto -match 'kSettingAPI_(\w+)') { $api = $Matches[1] }
}
if ($api) {
    Add-Resultado -Etapa 'API grafica do jogo' -Status 'INFO' -Detalhe $api `
        -Proximo 'O ReShade precisa ser instalado para ESTA mesma API. Se voce trocar a API no jogo, reinstale o ReShade.'
} else {
    Add-Resultado -Etapa 'API grafica do jogo' -Status 'AVISO' `
        -Detalhe 'Nao consegui ler system.xml (abra o jogo uma vez para ele ser criado).' `
        -Proximo 'Confira em Configuracoes > Graficos > API no jogo antes de instalar o ReShade.'
}

# ---------------------------------------------------------------------------
# 3. ScriptHookRDR2 + ASI Loader
# ---------------------------------------------------------------------------
$temScriptHook = Test-Arquivo $jogo 'ScriptHookRDR2.dll'
$temDinput8    = Test-Arquivo $jogo 'dinput8.dll'

if ($temScriptHook -and $temDinput8) {
    $v = Get-VersaoArquivo (Join-Path $jogo 'ScriptHookRDR2.dll')
    Add-Resultado -Etapa 'ScriptHookRDR2' -Status 'OK' `
        -Detalhe "ScriptHookRDR2.dll + dinput8.dll presentes$(if ($v) { " (versao $v)" })" `
        -Proximo 'Se o jogo travar na tela de carregamento apos uma atualizacao da Rockstar, baixe a versao nova do ScriptHook.'
} elseif ($temScriptHook -or $temDinput8) {
    Add-Resultado -Etapa 'ScriptHookRDR2' -Status 'AVISO' `
        -Detalhe "Instalacao incompleta (ScriptHookRDR2.dll: $temScriptHook / dinput8.dll: $temDinput8)" `
        -Proximo 'Os DOIS arquivos precisam estar na raiz do jogo. Recopie o pacote do ScriptHookRDR2.'
} else {
    Add-Resultado -Etapa 'ScriptHookRDR2' -Status 'FALTA' `
        -Detalhe 'Base dos mods de script ausente.' `
        -Proximo 'FASE 1 do guia: instalar ScriptHookRDR2 (dinput8.dll + ScriptHookRDR2.dll na raiz do jogo).'
}

# ---------------------------------------------------------------------------
# 4. Lenny's Mod Loader (LML)
# ---------------------------------------------------------------------------
$temModManager = Test-Arquivo $jogo 'ModManager.asi'
$pastaLml      = Join-Path $jogo 'lml'
$temLml        = Test-Path -LiteralPath $pastaLml

if ($temModManager -and $temLml) {
    $mods = Get-ChildItem -LiteralPath $pastaLml -Directory -ErrorAction SilentlyContinue
    $comInstall = @($mods | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'install.xml') })
    Add-Resultado -Etapa "Lenny's Mod Loader" -Status 'OK' `
        -Detalhe ("$($mods.Count) mod(s) em lml\, $($comInstall.Count) com install.xml: " +
                  (($mods | Select-Object -First 12 -ExpandProperty Name) -join ', ')) `
        -Proximo 'Confira a ordem em lml\mods.xml se dois mods alterarem o mesmo arquivo.'
    if ($mods.Count -gt 0 -and $comInstall.Count -eq 0) {
        Add-Resultado -Etapa "LML: install.xml" -Status 'AVISO' `
            -Detalhe 'Nenhum mod em lml\ tem install.xml.' `
            -Proximo 'Mods de stream/asset precisam do install.xml do proprio mod - provavelmente a pasta foi copiada em nivel errado.'
    }
} elseif ($temModManager -or $temLml) {
    Add-Resultado -Etapa "Lenny's Mod Loader" -Status 'AVISO' `
        -Detalhe "Instalacao incompleta (ModManager.asi: $temModManager / pasta lml: $temLml)" `
        -Proximo 'Rode o instalador do LML novamente apontando para a pasta do jogo.'
} else {
    Add-Resultado -Etapa "Lenny's Mod Loader" -Status 'FALTA' `
        -Detalhe 'Sem ModManager.asi e sem pasta lml\.' `
        -Proximo 'FASE 2 do guia: instalar o LML (necessario para mods de textura/roupas/veiculos, ex. WhyEm s DLC).'
}

# ---------------------------------------------------------------------------
# 5. Pasta scripts/ e mods de script
# ---------------------------------------------------------------------------
$pastaScripts = Join-Path $jogo 'scripts'
if (Test-Path -LiteralPath $pastaScripts) {
    $arqs = Get-ChildItem -LiteralPath $pastaScripts -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.asi', '.dll', '.lua' }
    if ($arqs) {
        Add-Resultado -Etapa 'Mods de script' -Status 'OK' `
            -Detalhe ("$($arqs.Count) arquivo(s): " + (($arqs | Select-Object -First 12 -ExpandProperty Name) -join ', '))
    } else {
        Add-Resultado -Etapa 'Mods de script' -Status 'AVISO' `
            -Detalhe 'Pasta scripts existe mas esta vazia.' `
            -Proximo 'FASE 3 do guia: colocar os .asi/.dll dos mods dentro de scripts\.'
    }
} else {
    Add-Resultado -Etapa 'Mods de script' -Status 'FALTA' `
        -Detalhe 'Pasta scripts\ nao existe.' `
        -Proximo 'Crie a pasta scripts\ na raiz do jogo (FASE 3).'
}

# ---------------------------------------------------------------------------
# 6. ReShade
# ---------------------------------------------------------------------------
$dllsReShade = @()    # DLLs que se identificam como ReShade
$dllsSuspeitas = @()  # DLLs de hook presentes, mas sem assinatura reconhecivel
foreach ($nome in @('dxgi.dll', 'd3d12.dll', 'd3d11.dll', 'opengl32.dll', 'ReShade64.dll')) {
    $p = Join-Path $jogo $nome
    if (Test-Path -LiteralPath $p) {
        $rotulo = "$nome$(if (Get-VersaoArquivo $p) { " ($(Get-VersaoArquivo $p))" })"
        if (Test-EhReShade $p) { $dllsReShade += $rotulo } else { $dllsSuspeitas += $rotulo }
    }
}
$temArquivosReShade = (Test-Path -LiteralPath (Join-Path $jogo 'ReShade.ini')) -or
                      (Test-Path -LiteralPath (Join-Path $jogo 'reshade-shaders'))

$camadaVulkan = $false
foreach ($chave in @('HKLM:\SOFTWARE\Khronos\Vulkan\ImplicitLayers', 'HKCU:\SOFTWARE\Khronos\Vulkan\ImplicitLayers')) {
    try {
        $prop = Get-ItemProperty -Path $chave -ErrorAction Stop
        if (($prop.PSObject.Properties.Name -join ' ') -match 'ReShade') { $camadaVulkan = $true }
    } catch { }
}

if ($dllsReShade.Count -gt 0) {
    Add-Resultado -Etapa 'ReShade' -Status 'OK' -Detalhe ("DLL: " + ($dllsReShade -join ', '))
} elseif ($dllsSuspeitas.Count -gt 0 -and $temArquivosReShade) {
    Add-Resultado -Etapa 'ReShade' -Status 'OK' `
        -Detalhe ("DLL: " + ($dllsSuspeitas -join ', ') + ' (identificado pelos arquivos de configuracao do ReShade)')
} elseif ($dllsSuspeitas.Count -gt 0) {
    Add-Resultado -Etapa 'ReShade' -Status 'AVISO' `
        -Detalhe ("Existe DLL de hook na pasta do jogo que nao se identifica como ReShade: " + ($dllsSuspeitas -join ', ')) `
        -Proximo 'Pode ser outro mod (FSR/DLSS, overlay). Se voce queria ReShade, rode o instalador oficial de novo.'
} elseif ($camadaVulkan) {
    Add-Resultado -Etapa 'ReShade' -Status 'OK' `
        -Detalhe 'Instalado no modo Vulkan (camada global), sem DLL na pasta do jogo.' `
        -Proximo 'Confirme que o jogo esta rodando em Vulkan; em DX12 esse modo nao funciona.'
} else {
    Add-Resultado -Etapa 'ReShade' -Status 'FALTA' `
        -Detalhe 'Nenhuma DLL do ReShade na pasta do jogo e nenhuma camada Vulkan registrada.' `
        -Proximo 'FASE 4 do guia: instalar o ReShade apontando para RDR2.exe e escolhendo a API que o jogo usa.'
}

foreach ($item in @(
    @{ Nome = 'Shaders do ReShade'; Rel = 'reshade-shaders'; Falta = 'Instale os shaders no instalador do ReShade (marque ao menos o pacote padrao).' },
    @{ Nome = 'Presets do ReShade'; Rel = 'reshade-presets'; Falta = 'Sem presets. Voce pode criar o seu no overlay (tecla Home) ou copiar um .ini de preset para a pasta do jogo.' }
)) {
    if (Test-Path -LiteralPath (Join-Path $jogo $item.Rel)) {
        $n = @(Get-ChildItem -LiteralPath (Join-Path $jogo $item.Rel) -Recurse -File -ErrorAction SilentlyContinue).Count
        if ($n -gt 0) {
            Add-Resultado -Etapa $item.Nome -Status 'OK' -Detalhe "$n arquivo(s) em $($item.Rel)\"
        } else {
            Add-Resultado -Etapa $item.Nome -Status 'AVISO' -Detalhe "Pasta $($item.Rel)\ existe, mas esta vazia." -Proximo $item.Falta
        }
    } else {
        Add-Resultado -Etapa $item.Nome -Status 'FALTA' -Detalhe "Pasta $($item.Rel)\ ausente." -Proximo $item.Falta
    }
}

$presetsSoltos = @(Get-ChildItem -LiteralPath $jogo -Filter '*.ini' -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -notmatch '^(ReShade|d3d|dxgi)\.ini$' })
if ($presetsSoltos.Count -gt 0) {
    Add-Resultado -Etapa 'Presets soltos na raiz' -Status 'INFO' `
        -Detalhe (($presetsSoltos | Select-Object -First 10 -ExpandProperty Name) -join ', ') `
        -Proximo 'Selecione o preset no overlay do ReShade (Home) na lista do topo.'
}

if (Test-Path -LiteralPath (Join-Path $jogo 'ReShade.ini')) {
    Add-Resultado -Etapa 'ReShade.ini' -Status 'OK' -Detalhe 'Configuracao do ReShade encontrada.'
}

# ---------------------------------------------------------------------------
# 7. Backups e saves
# ---------------------------------------------------------------------------
$perfis = if ($docs) { Join-Path $docs 'Rockstar Games\Red Dead Redemption 2\Profiles' } else { $null }
if ($perfis -and (Test-Path -LiteralPath $perfis)) {
    Add-Resultado -Etapa 'Saves' -Status 'INFO' -Detalhe $perfis `
        -Proximo 'Faca backup desta pasta antes de testar mods pesados (use Backup-RDR2.ps1).'
} else {
    Add-Resultado -Etapa 'Saves' -Status 'AVISO' -Detalhe 'Pasta de perfis nao encontrada.'
}

# ---------------------------------------------------------------------------
# 8. Relatorio
# ---------------------------------------------------------------------------
$cores = @{ OK = 'Green'; FALTA = 'Red'; AVISO = 'Yellow'; INFO = 'Gray' }
foreach ($r in $resultados) {
    Write-Host ("[{0,-5}] {1}" -f $r.Status, $r.Etapa) -ForegroundColor $cores[$r.Status]
    if ($r.Detalhe) { Write-Host "         $($r.Detalhe)" }
    if ($r.Proximo) { Write-Host "         -> $($r.Proximo)" -ForegroundColor DarkCyan }
}

Write-Host ''
$faltando = @($resultados | Where-Object { $_.Status -eq 'FALTA' })
if ($faltando.Count -eq 0) {
    Write-Host 'Tudo que o script verifica esta instalado. Proximo passo: testar no jogo (FASE 5 do guia).' -ForegroundColor Green
} else {
    Write-Host "PAREI AQUI -> pendencias em ordem de execucao:" -ForegroundColor Yellow
    foreach ($f in $faltando) { Write-Host "  - $($f.Etapa): $($f.Proximo)" }
}
Write-Host ''

if ($Json) {
    Write-Host '--- JSON (copie e cole no chat) ---' -ForegroundColor Cyan
    $resultados | ConvertTo-Json -Depth 3
}
