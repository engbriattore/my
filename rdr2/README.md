# RDR2 — mods e ReShade

Scripts e guia para instalar (e manter) mods e ReShade no Red Dead Redemption 2
no PC, continuando de uma instalação que ficou pela metade.

## Por onde começar

Leia [`GUIA.md`](GUIA.md) — ele reconstrói o estado da instalação, corrige
alguns pontos do plano original e traz o passo a passo.

## Scripts

Todos em `scripts/`, feitos para rodar no **PowerShell como administrador**.
Nenhum deles altera nada sem você pedir: por padrão simulam e mostram o plano.

| Script | Para quê |
|---|---|
| `Verificar-Instalacao.ps1` | Diagnostica a pasta do jogo: o que está instalado, o que falta, qual o próximo passo. Somente leitura. |
| `Backup-RDR2.ps1` | Copia saves e configurações antes de mexer em qualquer coisa. Também restaura. |
| `Instalar-Mods.ps1` | Instala os mods a partir dos `.zip` baixados, na ordem correta, com backup do que for sobrescrito. |
| `Configurar-ReShade.ps1` | Instala os shaders que o preset exige e aponta o `ReShade.ini` para ele. |
| `Modo-Online.ps1` | Desliga/religa os mods para entrar no Red Dead Online com segurança. |

## Uso rápido

```powershell
cd scripts
.\Backup-RDR2.ps1              # 1. proteger os saves
.\Verificar-Instalacao.ps1     # 2. ver o estado real
.\Instalar-Mods.ps1            # 3. simular
.\Instalar-Mods.ps1 -Aplicar   # 4. instalar
# testar o jogo, instalar o ReShade, e então:
.\Configurar-ReShade.ps1 -Aplicar
```

## Aviso

Use os mods **somente no modo História**. Antes de entrar no Red Dead Online,
rode `Modo-Online.ps1 -Desativar`.
