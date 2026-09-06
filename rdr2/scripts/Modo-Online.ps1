<#
.SYNOPSIS
    Liga/desliga a pilha de mods do RDR2 sem desinstalar nada.

.DESCRIPTION
    Mods de script (ScriptHookRDR2, trainers, LML) NAO devem ser usados no
    Red Dead Online - o risco de banimento e real. Este script move os
    arquivos de mod para uma pasta lateral (_mods_desativados) e devolve
    tudo ao lugar quando voce voltar para o modo historia.

    Nada e apagado: os arquivos apenas mudam de pasta.

.PARAMETER Desativar
    Tira os mods do ar (use antes de entrar no Red Dead Online).

.PARAMETER Ativar
    Devolve os mods ao lugar (modo historia).

.PARAMETER IncluirReShade
    Tambem desativa o ReShade. Sem este parametro, o ReShade e mantido.

.PARAMETER Caminho
    Pasta do jogo. Se omitido, tenta descobrir sozinho.

.EXAMPLE
    .\Modo-Online.ps1 -Desativar

.EXAMPLE
    .\Modo-Online.ps1 -Ativar
#>
[CmdletBinding(DefaultParameterSetName = 'Status')]
param(
    [Parameter(ParameterSetName = 'Off', Mandatory)][switch]$Desativar,
    [Parameter(ParameterSetName = 'On', Mandatory)][switch]$Ativar,
    [switch]$IncluirReShade,
    [string]$Caminho
)

$ErrorActionPreference = 'Stop'

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
        'Program Files\Rockstar Games\Red Dead Redemption 2',
        'Rockstar Games\Red Dead Redemption 2',
        'Games\Red Dead Redemption 2',
        'SteamLibrary\steamapps\common\Red Dead Redemption 2',
        'Program Files (x86)\Steam\steamapps\common\Red Dead Redemption 2',
        'Program Files\Epic Games\RedDeadRedemption2'
    )
    foreach ($d in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 3').DeviceID) {
        foreach ($r in $relativos) { $cands.Add("$d\$r") }
    }
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c 'RDR2.exe'))) { return (Resolve-Path -LiteralPath $c).Path }
    }
    throw 'Nao encontrei a pasta do jogo. Use -Caminho "D:\...\Red Dead Redemption 2".'
}

$jogo = Get-PastaJogo -Sugerida $Caminho
$cofre = Join-Path $jogo '_mods_desativados'

$itensMod = @('dinput8.dll', 'ScriptHookRDR2.dll', 'ModManager.asi', 'scripts', 'lml', 'version.dll')
$itensReShade = @('dxgi.dll', 'd3d12.dll', 'd3d11.dll', 'ReShade64.dll', 'ReShade.ini', 'reshade-shaders', 'reshade-presets')

$alvos = $itensMod
if ($IncluirReShade) { $alvos += $itensReShade }

function Mover-Itens {
    param([string]$De, [string]$Para, [string[]]$Nomes)
    if (-not (Test-Path -LiteralPath $Para)) { New-Item -ItemType Directory -Path $Para | Out-Null }
    $movidos = 0
    foreach ($n in $Nomes) {
        $origem = Join-Path $De $n
        if (Test-Path -LiteralPath $origem) {
            $destino = Join-Path $Para $n
            if (Test-Path -LiteralPath $destino) { Remove-Item -LiteralPath $destino -Recurse -Force }
            Move-Item -LiteralPath $origem -Destination $destino -Force
            Write-Host "  movido: $n" -ForegroundColor DarkGray
            $movidos++
        }
    }
    return $movidos
}

Write-Host ''
Write-Host "Pasta do jogo: $jogo"

if ($Desativar) {
    Write-Host 'Desativando mods (modo seguro para Red Dead Online)...' -ForegroundColor Yellow
    $n = Mover-Itens -De $jogo -Para $cofre -Nomes $alvos
    Write-Host ''
    if ($n -eq 0) {
        Write-Host 'Nada para desativar - os mods ja estavam fora.' -ForegroundColor Green
    } else {
        Write-Host "$n item(ns) guardado(s) em: $cofre" -ForegroundColor Green
        Write-Host 'Pode entrar no Red Dead Online.' -ForegroundColor Green
    }
    if (-not $IncluirReShade) {
        Write-Host 'Obs.: o ReShade continua ativo. Use -IncluirReShade para tira-lo tambem.' -ForegroundColor DarkYellow
    }
}
elseif ($Ativar) {
    if (-not (Test-Path -LiteralPath $cofre)) {
        Write-Host 'Nao ha nada guardado - os mods ja estao ativos.' -ForegroundColor Green
        exit 0
    }
    Write-Host 'Reativando mods (modo historia)...' -ForegroundColor Yellow
    $nomes = Get-ChildItem -LiteralPath $cofre -Force | Select-Object -ExpandProperty Name
    $n = Mover-Itens -De $cofre -Para $jogo -Nomes $nomes
    if (-not (Get-ChildItem -LiteralPath $cofre -Force)) { Remove-Item -LiteralPath $cofre -Force }
    Write-Host ''
    Write-Host "$n item(ns) devolvido(s) a pasta do jogo." -ForegroundColor Green
    Write-Host 'Use apenas no modo historia.' -ForegroundColor Green
}
else {
    $ativos = @($alvos | Where-Object { Test-Path -LiteralPath (Join-Path $jogo $_) })
    $guardados = @()
    if (Test-Path -LiteralPath $cofre) { $guardados = (Get-ChildItem -LiteralPath $cofre -Force).Name }
    Write-Host ''
    Write-Host "Ativos na pasta do jogo : $(if ($ativos) { $ativos -join ', ' } else { '(nenhum)' })"
    Write-Host "Guardados (desativados) : $(if ($guardados) { $guardados -join ', ' } else { '(nenhum)' })"
    Write-Host ''
    Write-Host 'Use -Desativar antes do Red Dead Online e -Ativar para voltar ao modo historia.' -ForegroundColor Cyan
}
Write-Host ''
