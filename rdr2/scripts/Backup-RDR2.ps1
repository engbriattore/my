<#
.SYNOPSIS
    Backup e restauracao dos saves e configuracoes do RDR2 (e da lista de mods).

.DESCRIPTION
    Copia a pasta Documentos\Rockstar Games\Red Dead Redemption 2
    (saves em Profiles\ e configuracoes em Settings\system.xml) para uma
    pasta datada, e registra quais mods estavam instalados no momento.

    Faca isso ANTES de instalar mods novos. Save corrompido por mod nao volta.

.PARAMETER Destino
    Onde guardar os backups. Padrao: Documentos\Backups RDR2.

.PARAMETER Restaurar
    Caminho de um backup criado por este script, para devolver ao lugar.

.EXAMPLE
    .\Backup-RDR2.ps1

.EXAMPLE
    .\Backup-RDR2.ps1 -Restaurar "C:\Users\voce\Documents\Backups RDR2\2026-09-06_1930"
#>
[CmdletBinding()]
param(
    [string]$Destino,
    [string]$Restaurar,
    [string]$Caminho
)

$ErrorActionPreference = 'Stop'

function Get-PastaDocumentos {
    $possiveis = New-Object System.Collections.Generic.List[string]
    $shell = [Environment]::GetFolderPath('MyDocuments')
    if ($shell) { $possiveis.Add($shell) }
    if ($env:USERPROFILE) {
        foreach ($sub in @('Documents', 'Documentos', 'OneDrive\Documents', 'OneDrive\Documentos')) {
            $possiveis.Add((Join-Path $env:USERPROFILE $sub))
        }
    }
    foreach ($p in $possiveis) {
        if ((Test-Path -LiteralPath $p) -and
            (Test-Path -LiteralPath (Join-Path $p 'Rockstar Games\Red Dead Redemption 2'))) { return $p }
    }
    foreach ($p in $possiveis) { if (Test-Path -LiteralPath $p) { return $p } }
    return $null
}

$docs = Get-PastaDocumentos
if (-not $docs) { throw 'Nao localizei sua pasta Documentos.' }
$pastaJogoDocs = Join-Path $docs 'Rockstar Games\Red Dead Redemption 2'
if (-not $Destino) { $Destino = Join-Path $docs 'Backups RDR2' }

if ($Restaurar) {
    if (-not (Test-Path -LiteralPath $Restaurar)) { throw "Backup nao encontrado: $Restaurar" }
    $origemPerfis = Join-Path $Restaurar 'Profiles'
    $origemConfig = Join-Path $Restaurar 'Settings'

    Write-Host "Restaurando de: $Restaurar" -ForegroundColor Yellow
    foreach ($par in @(
        @{ De = $origemPerfis; Para = (Join-Path $pastaJogoDocs 'Profiles'); Nome = 'Saves' },
        @{ De = $origemConfig; Para = (Join-Path $pastaJogoDocs 'Settings'); Nome = 'Configuracoes' }
    )) {
        if (Test-Path -LiteralPath $par.De) {
            if (Test-Path -LiteralPath $par.Para) {
                $lado = "$($par.Para)_antes_da_restauracao_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Move-Item -LiteralPath $par.Para -Destination $lado
                Write-Host "  $($par.Nome): pasta atual preservada em $lado" -ForegroundColor DarkGray
            }
            Copy-Item -LiteralPath $par.De -Destination $par.Para -Recurse -Force
            Write-Host "  $($par.Nome): restaurado." -ForegroundColor Green
        }
    }
    Write-Host 'Pronto.' -ForegroundColor Green
    exit 0
}

if (-not (Test-Path -LiteralPath $pastaJogoDocs)) {
    throw "Nao encontrei '$pastaJogoDocs'. Abra o jogo ao menos uma vez."
}

$carimbo = Get-Date -Format 'yyyy-MM-dd_HHmm'
$pastaBackup = Join-Path $Destino $carimbo
New-Item -ItemType Directory -Path $pastaBackup -Force | Out-Null

foreach ($sub in @('Profiles', 'Settings')) {
    $de = Join-Path $pastaJogoDocs $sub
    if (Test-Path -LiteralPath $de) {
        Copy-Item -LiteralPath $de -Destination (Join-Path $pastaBackup $sub) -Recurse -Force
        $n = @(Get-ChildItem -LiteralPath $de -Recurse -File).Count
        Write-Host "$sub copiado ($n arquivo(s))." -ForegroundColor Green
    } else {
        Write-Host "$sub nao existe - ignorado." -ForegroundColor DarkYellow
    }
}

# Registra o estado dos mods, para saber o que estava instalado neste backup
try {
    $verificador = Join-Path $PSScriptRoot 'Verificar-Instalacao.ps1'
    if (Test-Path -LiteralPath $verificador) {
        $parametros = @{}
        if ($Caminho) { $parametros['Caminho'] = $Caminho }
        & $verificador @parametros *>&1 |
            Out-File -LiteralPath (Join-Path $pastaBackup 'estado-dos-mods.txt') -Encoding utf8
        Write-Host 'Estado dos mods registrado em estado-dos-mods.txt.' -ForegroundColor Green
    }
} catch {
    Write-Host "Nao consegui registrar o estado dos mods: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

Write-Host ''
Write-Host "Backup completo em: $pastaBackup" -ForegroundColor Cyan
Write-Host "Para voltar atras:  .\Backup-RDR2.ps1 -Restaurar `"$pastaBackup`"" -ForegroundColor Cyan
Write-Host ''
