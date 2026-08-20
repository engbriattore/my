# Simulado de poema — versão adaptada para estudantes autistas

Adaptação do simulado de Língua Portuguesa (poema, 20 perguntas) para estudantes
autistas, com base em pesquisa sobre apoios visuais, ensino estruturado e
aprendizagem multimídia.

## Arquivo principal

`Simulado_Poema_ADAPTADO_TEA_v3.docx` — A4, Arial 13 pt, entrelinha 1,5, fundo
creme, alinhamento à esquerda.

Conteúdo: capa com rotina e cartões de comunicação, caixa de ajuda ilustrada,
7 partes (1 poema + 2 ou 3 perguntas cada), gabarito com descritores,
justificativa das adaptações, sugestões de aplicação e roteiro das imagens.

## Imagens

O documento traz **36 molduras tracejadas numeradas** (`IMAGEM 1` … `IMAGEM 36`),
cada uma com a descrição do que desenhar. A seção **ROTEIRO DAS IMAGENS**, ao
final, lista as 36 em tabela.

Regras de arte adotadas no roteiro:

- desenho ilustrado com volume e cena de fundo — nada de boneco de palito;
- paleta neutra e de baixa saturação, sem contraste agressivo;
- uma ideia por imagem, sem enfeite (princípio da coerência);
- texto dentro da imagem só cita o verso do poema, nunca a resposta.

`ilustracoes/` contém as 5 primeiras ilustrações já produzidas (SVG + PNG) e o
sistema visual usado para gerá-las.

## Base de pesquisa das adaptações

| Adaptação | Base |
|---|---|
| Imagem em cada pergunta e poema | Apoios visuais como prática baseada em evidências no TEA (NCAEP/AFIRM) |
| Ilustração instrucional, nunca decorativa | Princípio da coerência e efeito dos "detalhes sedutores" (Mayer) |
| Caixa VERSO EM FOCO dentro da pergunta | Princípio da contiguidade espacial (Mayer) |
| Rotina fixa, trilha de progresso, fim de parte sinalizado | Ensino estruturado (TEACCH) |
| Apoio explícito ao sentido figurado | Literatura sobre linguagem figurada no TEA |
| Tipografia ampliada, tons neutros, baixa poluição visual | Design sensorialmente amigável |

## Correção de conteúdo

As pistas das perguntas 1, 2, 5 e 6 apontavam versos que não continham a
expressão cobrada (por exemplo, a pergunta 1 remetia ao verso 12, mas
"senta no chão" está no verso 10). Foram corrigidas e o gerador valida, a cada
build, se a expressão de cada pergunta aparece no verso indicado pela PISTA.

## Como regerar o documento

```bash
cd gerador
npm install
node build.js && python3 fix_pbdr.py Simulado_Poema_TEA_v3.docx
```

`data.js` concentra poemas, perguntas, gabarito e descrições das imagens.
`fix_pbdr.py` reordena os filhos de `<w:pBdr>` — a biblioteca `docx` os emite
como top/bottom/left/right, e o schema exige top/left/bottom/right.

`node preview.js` gera uma prévia HTML do layout.
