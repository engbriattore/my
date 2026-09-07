# RDR2 — mods + ReShade: onde paramos e como terminar

Continuação da instalação que ficou pela metade quando o limite de uso do ChatGPT
acabou. Este guia reconstrói o estado, corrige alguns pontos do plano original e
entrega scripts que fazem o trabalho pesado.

---

## 1. Seu setup

| Item | Valor |
|---|---|
| Jogo | Epic Games — `C:\Program Files\Epic Games\RedDeadRedemption2` |
| Downloads | `C:\Users\abria\Downloads` |
| Placa | RTX 3060 12 GB |
| 7-Zip | `C:\Program Files\7-Zip\7z.exe` |

---

## 2. Onde a instalação parou

O que a conversa anterior **realmente executou**:

1. `7z l` nos cinco pacotes baixados — apenas **listou** o conteúdo, não extraiu nada.
2. Copiou o preset `RDR2_Enhanced_Edition_2025.ini` para a pasta do jogo.
3. Tentou o comando final — **recusado pela revisão automática**, e em seguida o
   limite de uso encerrou a sessão.

O comando recusado faria duas coisas, e **nenhuma das duas aconteceu**:

- extrair `Technicolor2.fx`, `Curves.fx`, `DPX.fx`, `CAS.fx` do `SweetFX-master.zip`
  e `GaussianBlur.fx` do `reshade-shaders-legacy.zip` para `reshade-shaders\Shaders`;
- gravar `PresetPath=...\RDR2_Enhanced_Edition_2025.ini` no `ReShade.ini`.

**Conclusão:** apesar do "vou instalar agora", a base (LML, ScriptHook, OCU,
WhyEm's DLC, BloodLust) provavelmente **não chegou a ser instalada**. O único
resultado concreto foi o arquivo de preset copiado — que sozinho não faz nada.

> Não confie nesta reconstrução: rode `Verificar-Instalacao.ps1` (passo 4 abaixo).
> Ele lê a pasta do jogo e diz o estado real, arquivo por arquivo.

---

## 3. Pacotes baixados e o papel de cada um

| Arquivo em Downloads | O que é | Vai para |
|---|---|---|
| `ScriptHookRDR2 V2-1472-...zip` | Base para mods de script | raiz do jogo |
| `lml_rdr_beta_11.zip` | Lenny's Mod Loader — base para mods de conteúdo | raiz + `lml\` |
| `Online Content Unlocker-1688-...zip` | Libera itens do Online no modo História | `lml\` |
| `WhyEm's DLC-671-...zip` | Roupas, coldres, acessórios | `lml\` |
| `WhyEm's BloodLust-1154-...zip` | Sangue e ferimentos | `lml\` |
| `SweetFX-master.zip` | Shaders exigidos pelo preset gráfico | `reshade-shaders\Shaders\` |
| `reshade-shaders-legacy.zip` | Shader `GaussianBlur.fx` | `reshade-shaders\Shaders\` |
| `RDR2_Enhanced_Edition_2025.ini` | Preset gráfico (já na pasta do jogo) | raiz do jogo |

---

## 4. Correções ao plano original

Quatro pontos do plano anterior merecem ajuste antes de você executar.

### 4.1. "Escolha DirectX 12" no ReShade — confira antes

O ReShade precisa ser instalado para a **mesma API que o jogo está usando**. Se o
seu RDR2 estiver rodando em **Vulkan**, uma instalação em DX12 simplesmente não
carrega — e você fica com a impressão de que o preset não funcionou.

`Verificar-Instalacao.ps1` lê isso do seu `system.xml` e mostra a API atual. Se
você trocar a API dentro do jogo depois, precisa reinstalar o ReShade.

### 4.2. O ScriptHook baixado pode estar defasado

O nome do arquivo (`...-1726764708`) indica um pacote de **setembro de 2024**. O
ScriptHookRDR2 é travado por versão do jogo: **depois de qualquer atualização da
Rockstar, ele para de funcionar e o jogo trava no carregamento**.

Se o jogo não abrir após a instalação, baixe a versão mais recente do ScriptHook
no site do Alexander Blade antes de qualquer outro diagnóstico.

### 4.3. Red Dead Offline não está nos seus downloads

O plano original citava "WhyEm's DLC – Red Dead Offline Edition" + Red Dead
Offline, mas o que você baixou foi o **WhyEm's DLC principal (mod 671)** e o
Red Dead Offline **não está na lista**.

Isso não é problema: WhyEm's DLC + OCU funciona sem o Red Dead Offline. Só
**não misture as duas variantes** — se o zip trouxer uma pasta "RDO Edition" e
outra padrão, instale apenas uma.

### 4.4. Um overhaul visual por vez

Você acabou escolhendo o **RDR2 2025 Enhanced Edition** como visual principal.
Então **não instale** VESTIGIA, Renewal ou Visual Redemption — todos mexem nos
mesmos arquivos (`visualsettings.dat`) e o resultado é imprevisível.

E o alerta que já tinha sido dado, que vale repetir: **`version.dll` e o Online
Content Unlocker não convivem**. O instalador avisa se isso for acontecer.

---

## 5. Execução

Abra o **PowerShell como administrador** (o jogo está em `Arquivos de Programas`,
pasta protegida) e vá até a pasta `scripts` deste repositório.

### Passo 0 — backup (não pule)

```powershell
.\Backup-RDR2.ps1
```

Copia saves e configurações para `Documentos\Backups RDR2\<data>`. Save corrompido
por mod não volta sozinho.

### Passo 1 — ver o estado real

```powershell
.\Verificar-Instalacao.ps1
```

Mostra, item por item, o que já está instalado, o que falta e qual é o próximo
passo. É este comando que responde "onde paramos" com base no seu disco.

### Passo 2 — simular a instalação dos mods

```powershell
.\Instalar-Mods.ps1
```

Lê os zips de Downloads, descobre o tipo de cada arquivo pelo conteúdo (não pelo
nome) e mostra **exatamente para onde cada arquivo iria**. Nada é alterado.
Confira a lista antes de seguir.

### Passo 3 — instalar

```powershell
.\Instalar-Mods.ps1 -Aplicar
```

Instala na ordem correta: ScriptHook → LML → OCU → WhyEm's DLC → BloodLust.
Qualquer arquivo sobrescrito é preservado em `_backup_antes_dos_mods_<data>`
dentro da pasta do jogo.

### Passo 4 — testar o jogo ANTES do ReShade

Abra o RDR2 e entre no **modo História**. Se carregar normalmente, a base está boa.

Testar aqui é o que separa "achar o problema em 30 segundos" de "não sei o que
quebrou". Se o jogo não abrir, veja a seção 7.

### Passo 5 — instalar o ReShade

Rode o instalador oficial do ReShade que você já baixou:

1. selecione `C:\Program Files\Epic Games\RedDeadRedemption2\RDR2.exe`;
2. escolha a API que o passo 1 mostrou (DirectX 12 ou Vulkan);
3. marque os pacotes de shaders oferecidos — pelo menos o padrão.

### Passo 6 — ativar o preset gráfico

```powershell
.\Configurar-ReShade.ps1          # simula
.\Configurar-ReShade.ps1 -Aplicar # efetiva
```

Este é o passo que ficou faltando. Ele lê o `RDR2_Enhanced_Edition_2025.ini`,
descobre **quais efeitos o preset exige**, procura os `.fx` que faltam dentro dos
seus zips (SweetFX, legacy), instala e grava o `PresetPath` no `ReShade.ini` —
com backup do arquivo original.

Se algum efeito não for encontrado em nenhum zip, o script diz o nome. Sem ele o
preset carrega incompleto.

### Passo 7 — conferir no jogo

Entre no jogo e pressione **Home**. No topo do overlay deve aparecer o preset
selecionado, e a lista de efeitos **sem linhas vermelhas**. Vermelho = shader
faltando ou com erro de compilação.

---

## 6. Antes de entrar no Red Dead Online

Mods de script no Online são risco real de banimento.

```powershell
.\Modo-Online.ps1 -Desativar   # guarda os mods de lado
.\Modo-Online.ps1 -Ativar      # devolve tudo para o modo História
```

Nada é apagado — os arquivos só mudam de pasta.

---

## 7. Quando algo dá errado

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| Jogo não abre, fecha na hora | ScriptHook incompatível com a versão atual do jogo | Baixe o ScriptHook mais recente; ou remova `dinput8.dll` para confirmar que é ele |
| Carregamento infinito | Mod de conteúdo com arquivo conflitante | Renomeie `lml\` para `lml_off\` e teste; reintroduza um mod por vez |
| Roupas/itens não aparecem nas lojas | OCU ou WhyEm's DLC não carregou | Confira que cada mod em `lml\` tem seu `install.xml` (o verificador mostra) |
| Overlay do ReShade não abre com Home | ReShade instalado na API errada | Confira a API no passo 1 e reinstale o ReShade |
| Overlay abre, mas a imagem não muda | Shaders do preset faltando | `Configurar-ReShade.ps1 -Aplicar` |
| Efeitos em vermelho no overlay | `.fx` ausente ou dependência `.fxh` faltando | Veja o nome em vermelho e busque o pacote de shaders correspondente |
| Tudo quebrou depois de uma atualização | Rockstar atualizou o jogo | Espere o ScriptHook novo; até lá, `Modo-Online.ps1 -Desativar` deixa o jogo limpo |

Dois princípios que evitam a maior parte do sofrimento:

- **Instale em camadas e teste entre elas.** Base → jogo abre? → mods → jogo
  abre? → ReShade. Foi justamente pular isso que deixou a instalação anterior
  num estado indeterminado.
- **Um mod por categoria.** Um overhaul visual, um catálogo de roupas, um mod de
  sangue. Dois mods mexendo no mesmo arquivo é conflito garantido.

---

## 8. Configuração sugerida para a RTX 3060 12 GB

| Ajuste | 1080p | 1440p |
|---|---|---|
| Preset geral | Ultra | Alto/Ultra |
| Texturas | Ultra | Ultra |
| Iluminação, sombras, água | Ultra | Alto |
| Reflexos | Alto | Médio/Alto |
| MSAA | Desligado | Desligado |
| DLSS | Qualidade (ou desligado se o FPS estiver bom) | Qualidade |

MSAA é o item que mais custa FPS no RDR2 com o menor retorno visual — deixe
desligado e invista o orçamento em texturas e iluminação.

Observação: o RDR2 não tem ray tracing oficial, e não existe mod confiável que
adicione ray tracing real. O ganho visual aqui vem do overhaul + ReShade +
configurações no máximo, e sua placa dá conta disso.
