const fs = require("fs");
const d = require("docx");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType,
  BorderStyle, ShadingType, AlignmentType, HeightRule, PageBreak, Footer,
  PageNumber, VerticalAlign, convertMillimetersToTwip,
} = d;
const { PARTES, RECURSOS } = require("./data.js");

// ------------------------------------------------------------------ tokens
const INK = "1B2430";
const SOFT = "6E6656";
const CREAM = "F5F1E8";
const CREAM_D = "EDE5D5";
const BORDER = "C9C1AE";
const ACCENT = "3F6B87";        // azul calmo, baixo contraste com o creme
const ACCENT_BG = "E6EDF2";
const FOCO_BG = "F0EADA";
const OK_BG = "E8EFE4";

const FONT = "Arial";
const BODY = 26;                 // 13 pt — corpo ampliado
const LINE = 360;                // entrelinha 1,5
const CONTENT = 9412;            // largura util em DXA

const noBorder = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
const NO_BORDERS = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };
const line = (color, size = 6, style = BorderStyle.SINGLE) => ({ style, size, color });
const boxBorders = (color = BORDER, size = 6, style = BorderStyle.SINGLE) => ({
  top: line(color, size, style), left: line(color, size, style),
  bottom: line(color, size, style), right: line(color, size, style),
});

// ------------------------------------------------------------------ helpers
function run(text, o = {}) {
  return new TextRun({
    text, font: FONT, size: o.size || BODY, bold: !!o.bold, italics: !!o.italics,
    color: o.color || INK, allCaps: !!o.caps, characterSpacing: o.spacing,
  });
}

function P(text, o = {}) {
  return new Paragraph({
    children: Array.isArray(text) ? text : [run(text, o)],
    alignment: o.align || AlignmentType.LEFT,
    spacing: { before: o.before || 0, after: o.after === undefined ? 120 : o.after, line: o.line || LINE },
    indent: o.indent,
    keepNext: !!o.keepNext,
    keepLines: o.keepLines === undefined ? true : o.keepLines,
    border: o.border,
    shading: o.fill ? { type: ShadingType.CLEAR, color: "auto", fill: o.fill } : undefined,
  });
}

function cell(children, o = {}) {
  return new TableCell({
    children,
    width: { size: o.width || CONTENT, type: WidthType.DXA },
    shading: { type: ShadingType.CLEAR, color: "auto", fill: o.fill || CREAM },
    borders: o.borders || boxBorders(),
    margins: { top: o.pt === undefined ? 140 : o.pt, bottom: o.pb === undefined ? 140 : o.pb, left: 180, right: 180 },
    verticalAlign: o.valign || VerticalAlign.TOP,
    columnSpan: o.span,
  });
}

function box(children, o = {}) {
  return new Table({
    columnWidths: [o.width || CONTENT],
    width: { size: o.width || CONTENT, type: WidthType.DXA },
    rows: [new TableRow({
      children: [cell(children, o)],
      cantSplit: true,
      height: o.height ? { value: o.height, rule: HeightRule.ATLEAST } : undefined,
    })],
  });
}

const spacer = (h = 120) => new Paragraph({ children: [], spacing: { before: 0, after: h, line: 200 } });

// Espaco reservado para a ilustracao — o desenho entra depois, no lugar da moldura.
function imgSlot(numero, descricao, alturaTwips) {
  return box([
    P([run(`IMAGEM ${numero}`, { bold: true, size: 20, color: ACCENT })], { after: 60, line: 240 }),
    P([run(descricao, { size: 19, color: SOFT, italics: true })], { after: 0, line: 240 }),
  ], {
    fill: "FFFFFF",
    borders: boxBorders(BORDER, 6, BorderStyle.DASHED),
    height: alturaTwips,
    pt: 120, pb: 120,
  });
}

// --------------------------------------------------------------- documento
const kids = [];
let img = 0;

// ============================================================ CAPA
kids.push(P([run("SIMULADO DE LÍNGUA PORTUGUESA", { bold: true, size: 36 })],
  { after: 40, align: AlignmentType.CENTER }));
kids.push(P([run("Poema — 20 perguntas — versão adaptada para estudantes autistas", { size: 24, color: SOFT })],
  { after: 260, align: AlignmentType.CENTER }));

kids.push(new Table({
  columnWidths: [5600, 3812],
  width: { size: CONTENT, type: WidthType.DXA },
  rows: [new TableRow({
    children: [
      cell([P([run("Nome: ", { bold: true }), run("_______________________________________")], { after: 0 })], { width: 5600 }),
      cell([P([run("Turma: ", { bold: true }), run("____________")], { after: 0 })], { width: 3812 }),
    ],
  }), new TableRow({
    children: [
      cell([P([run("Data: ", { bold: true }), run("______ / ______ / __________")], { after: 0 })], { width: 5600 }),
      cell([P([run("Professor(a): ", { bold: true }), run("__________")], { after: 0 })], { width: 3812 }),
    ],
  })],
}));
kids.push(spacer(240));

// ---- como esta prova funciona
kids.push(P([run("COMO ESTA PROVA FUNCIONA", { bold: true, size: 28, color: ACCENT })], { after: 120, keepNext: true }));
const regras = [
  "A prova tem 7 partes. Cada parte tem 1 poema e 2 ou 3 perguntas.",
  "Em cada parte você vai ler o poema e depois responder as perguntas.",
  "Cada pergunta tem 3 respostas: A, B e C. Só uma está certa.",
  "Marque um X dentro dos parênteses da resposta que você escolher.",
  "Antes de cada pergunta há uma PISTA. A pista diz em qual verso você deve olhar.",
  "Os versos do poema estão numerados: 01, 02, 03…",
  "Dentro da pergunta há uma caixa VERSO EM FOCO. Ela repete o verso da pista. Você não precisa voltar a página.",
  "Você pode olhar a CAIXA DE AJUDA a qualquer momento.",
  "No fim de cada parte você pode descansar.",
  "Se tiver dúvida, levante a mão e espere. A professora vai até você.",
];
kids.push(box(regras.map((t, i) => P([
  run(String(i + 1).padStart(2, "0") + ".   ", { bold: true, color: ACCENT }), run(t),
], { after: i === regras.length - 1 ? 0 : 90, indent: { left: 420, hanging: 420 } }))));
kids.push(spacer(240));

// ---- meu progresso
kids.push(P([run("MEU PROGRESSO", { bold: true, size: 28, color: ACCENT })], { after: 60, keepNext: true }));
kids.push(P([run("Marque um X quando terminar cada parte.", { size: 22, color: SOFT })], { after: 120, keepNext: true }));
const prog = ["parte 1", "parte 2", "parte 3", "parte 4", "parte 5", "parte 6", "parte 7", "acabei!"];
const cw = Math.floor(CONTENT / 4);
kids.push(new Table({
  columnWidths: [cw, cw, cw, CONTENT - cw * 3],
  width: { size: CONTENT, type: WidthType.DXA },
  rows: [0, 1].map(r => new TableRow({
    children: prog.slice(r * 4, r * 4 + 4).map((t, i) => cell(
      [P([run("(        )   ", { bold: true }), run(t)], { after: 0, align: AlignmentType.CENTER })],
      { width: i === 3 ? CONTENT - cw * 3 : cw, fill: t === "acabei!" ? OK_BG : CREAM }
    )),
  })),
}));
kids.push(spacer(240));

// ---- cartoes de comunicacao
kids.push(P([run("COMO PEDIR O QUE EU PRECISO", { bold: true, size: 28, color: ACCENT })], { after: 60, keepNext: true }));
kids.push(P([run("Aponte para o cartão ou levante a mão. Não precisa falar.", { size: 22, color: SOFT })], { after: 120, keepNext: true }));
const cartoes = [
  ["QUERO UMA PAUSA", "Eu preciso parar um pouco."],
  ["PRECISO DE AJUDA", "Eu não entendi a pergunta."],
  ["JÁ TERMINEI", "Eu acabei esta parte."],
];
const c3 = Math.floor(CONTENT / 3);
kids.push(new Table({
  columnWidths: [c3, c3, CONTENT - c3 * 2],
  width: { size: CONTENT, type: WidthType.DXA },
  rows: [new TableRow({
    children: cartoes.map(([t, s], i) => cell([
      P([run(t, { bold: true, size: 24, color: ACCENT })], { after: 60, align: AlignmentType.CENTER }),
      P([run(s, { size: 21, color: SOFT })], { after: 0, align: AlignmentType.CENTER }),
    ], { width: i === 2 ? CONTENT - c3 * 2 : c3, fill: ACCENT_BG })),
  })],
}));

// ============================================================ CAIXA DE AJUDA
kids.push(new Paragraph({ children: [new PageBreak()] }));
kids.push(P([run("CAIXA DE AJUDA", { bold: true, size: 32, color: ACCENT })], { after: 60, keepNext: true }));
kids.push(P([run("Você pode consultar esta página a qualquer momento durante a prova.", { size: 22, color: SOFT })],
  { after: 160, keepNext: true }));

const colIcone = 1500, colRec = 2000, colQue = 3400, colEx = CONTENT - colIcone - colRec - colQue;
const headRow = new TableRow({
  children: [["IMAGEM", colIcone], ["RECURSO", colRec], ["O QUE É", colQue], ["EXEMPLO", colEx]].map(([t, w]) =>
    cell([P([run(t, { bold: true, size: 21, color: "FFFFFF" })], { after: 0, align: AlignmentType.CENTER })],
      { width: w, fill: ACCENT, pt: 90, pb: 90 })),
  tableHeader: true,
});
const recRows = RECURSOS.map(([nome, oque, ex, desenho], i) => {
  img += 1;
  return new TableRow({
    cantSplit: true,
    height: { value: 900, rule: HeightRule.ATLEAST },
    children: [
      cell([P([run(`IMAGEM ${img}`, { bold: true, size: 17, color: ACCENT })], { after: 30, line: 220, align: AlignmentType.CENTER }),
      P([run(desenho, { size: 15, color: SOFT, italics: true })], { after: 0, line: 200, align: AlignmentType.CENTER })],
        { width: colIcone, fill: "FFFFFF", borders: boxBorders(BORDER, 6, BorderStyle.DASHED), pt: 90, pb: 90 }),
      cell([P([run(nome, { bold: true, size: 22 })], { after: 0, line: 260 })], { width: colRec, fill: i % 2 ? CREAM_D : CREAM, pt: 90, pb: 90 }),
      cell([P([run(oque, { size: 22 })], { after: 0, line: 260 })], { width: colQue, fill: i % 2 ? CREAM_D : CREAM, pt: 90, pb: 90 }),
      cell([P([run(ex, { size: 22, italics: true })], { after: 0, line: 260 })], { width: colEx, fill: i % 2 ? CREAM_D : CREAM, pt: 90, pb: 90 }),
    ],
  });
});
kids.push(new Table({
  columnWidths: [colIcone, colRec, colQue, colEx],
  width: { size: CONTENT, type: WidthType.DXA },
  rows: [headRow, ...recRows],
}));

// ============================================================ PARTES
PARTES.forEach((parte) => {
  // mapa numero -> verso (as linhas vazias separam estrofes e nao contam)
  const numerados = [];
  let k = 0;
  parte.versos.forEach(v => { if (v === "") { numerados.push(null); } else { k += 1; numerados.push([k, v]); } });
  const porNumero = {};
  numerados.forEach(x => { if (x) porNumero[x[0]] = x[1]; });

  kids.push(new Paragraph({ children: [new PageBreak()] }));

  // cabecalho da parte + trilha visual de progresso
  kids.push(new Table({
    columnWidths: [3400, CONTENT - 3400],
    width: { size: CONTENT, type: WidthType.DXA },
    rows: [new TableRow({
      children: [
        cell([P([run(`PARTE ${parte.n} DE 7`, { bold: true, size: 30, color: "FFFFFF" })], { after: 0 })],
          { width: 3400, fill: ACCENT, pt: 120, pb: 120 }),
        cell([P([1, 2, 3, 4, 5, 6, 7].flatMap(i => {
          const r = [run(` ${i} `, {
            bold: i === parte.n, size: i === parte.n ? 26 : 22,
            color: i === parte.n ? ACCENT : "A79E8B",
          })];
          if (i < 7) r.push(run("—", { size: 20, color: "C9C1AE" }));
          return r;
        }), { after: 0, align: AlignmentType.RIGHT })],
          { width: CONTENT - 3400, fill: CREAM, pt: 120, pb: 120, valign: VerticalAlign.CENTER }),
      ],
    })],
  }));
  kids.push(spacer(200));

  // ilustracao do poema
  img += 1;
  kids.push(imgSlot(img, parte.imagem, 3000));
  kids.push(spacer(200));

  // poema
  const poema = [P([run(parte.titulo, { bold: true, size: 30 })], { after: 160, keepNext: true })];
  numerados.forEach((x, i) => {
    if (x === null) { poema.push(spacer(60)); return; }
    poema.push(P([
      run(String(x[0]).padStart(2, "0") + "   ", { bold: true, color: "9A917E", size: 22 }),
      run(x[1], { size: 25 }),
    ], { after: 40, line: 320, indent: { left: 460, hanging: 460 } }));
  });
  kids.push(box(poema, { pt: 200, pb: 200 }));

  // perguntas
  kids.push(new Paragraph({ children: [new PageBreak()] }));

  parte.perguntas.forEach((q, qi) => {
    const focos = (q.pista.match(/\d+/g) || []).map(Number).filter(n => porNumero[n]);

    kids.push(P([run(`PERGUNTA ${q.n}`, { bold: true, size: 28, color: "FFFFFF" })], {
      after: 0, before: qi === 0 ? 0 : 260, fill: ACCENT, keepNext: true,
      border: { top: line(ACCENT, 12), left: line(ACCENT, 12), bottom: line(ACCENT, 12), right: line(ACCENT, 12) },
    }));

    kids.push(P([run("PISTA: ", { bold: true, color: ACCENT }), run(q.pista)], {
      after: 0, before: 60, fill: ACCENT_BG, keepNext: true,
      border: { top: line(ACCENT_BG, 6), left: line(ACCENT, 18), bottom: line(ACCENT_BG, 6), right: line(ACCENT_BG, 6) },
      indent: { left: 160, right: 160 },
    }));
    kids.push(spacer(120));

    // verso em foco — evita ter de voltar a pagina do poema
    if (focos.length) {
      kids.push(box([
        P([run("VERSO EM FOCO", { bold: true, size: 19, color: SOFT })], { after: 80, line: 240, keepNext: true }),
        ...focos.map((n, i) => P([
          run(String(n).padStart(2, "0") + "   ", { bold: true, color: "9A917E", size: 21 }),
          run(porNumero[n], { size: 24 }),
        ], { after: i === focos.length - 1 ? 0 : 40, line: 300, indent: { left: 440, hanging: 440 }, keepNext: true })),
      ], { fill: FOCO_BG, borders: boxBorders(BORDER), pt: 110, pb: 110 }));
      kids.push(spacer(120));
    }

    // ilustracao da pergunta
    img += 1;
    kids.push(imgSlot(img, q.imagem, 1900));
    kids.push(spacer(140));

    // enunciado
    q.enunciado.forEach((linha, i) => {
      kids.push(P(linha.map(seg => run(seg.t, { bold: !!seg.b })), {
        after: i === q.enunciado.length - 1 ? 140 : 60, keepNext: true,
      }));
    });

    // alternativas
    ["A", "B", "C"].forEach((L, i) => {
      kids.push(P([
        run("(        )      ", { bold: true, size: 27 }),
        run(`${L})   `, { bold: true, color: ACCENT }),
        run(q.alt[i]),
      ], { after: i === 2 ? 0 : 70, indent: { left: 900, hanging: 900 }, keepNext: i < 2 }));
    });
  });

  // fim da parte
  kids.push(spacer(240));
  kids.push(box([
    P([
      run(`Fim da parte ${parte.n}.      `, { bold: true }),
      run("(        ) Terminei.      ", { bold: true }),
      run(parte.n === 7 ? "Fim da prova. Parabéns!" : "Se quiser, descanse antes de virar a página.",
        { color: SOFT }),
    ], { after: 0 }),
  ], { fill: OK_BG, borders: boxBorders(BORDER) }));
});

// ============================================================ GABARITO
kids.push(new Paragraph({ children: [new PageBreak()] }));
kids.push(P([run("GABARITO E ORIENTAÇÕES", { bold: true, size: 32, color: ACCENT })], { after: 40, keepNext: true }));
kids.push(P([run("Uso exclusivo do professor.", { size: 22, color: SOFT, italics: true })], { after: 160, keepNext: true }));

const gc = [1100, 1300, 1700, CONTENT - 4100];
const gabRows = [new TableRow({
  tableHeader: true,
  children: [["PERGUNTA", gc[0]], ["RESPOSTA", gc[1]], ["DESCRITOR", gc[2]], ["HABILIDADE AVALIADA", gc[3]]].map(([t, w]) =>
    cell([P([run(t, { bold: true, size: 20, color: "FFFFFF" })], { after: 0, align: AlignmentType.CENTER })],
      { width: w, fill: ACCENT, pt: 90, pb: 90 })),
})];
let gi = 0;
PARTES.forEach(p => p.perguntas.forEach(q => {
  const f = gi++ % 2 ? CREAM_D : CREAM;
  gabRows.push(new TableRow({
    cantSplit: true,
    children: [
      cell([P([run(String(q.n).padStart(2, "0"), { size: 22 })], { after: 0, align: AlignmentType.CENTER })], { width: gc[0], fill: f, pt: 70, pb: 70 }),
      cell([P([run(q.certa, { bold: true, size: 22, color: ACCENT })], { after: 0, align: AlignmentType.CENTER })], { width: gc[1], fill: f, pt: 70, pb: 70 }),
      cell([P([run(q.desc, { size: 21 })], { after: 0, align: AlignmentType.CENTER })], { width: gc[2], fill: f, pt: 70, pb: 70 }),
      cell([P([run(q.hab, { size: 20 })], { after: 0, line: 260 })], { width: gc[3], fill: f, pt: 70, pb: 70 }),
    ],
  }));
}));
kids.push(new Table({ columnWidths: gc, width: { size: CONTENT, type: WidthType.DXA }, rows: gabRows }));

// ============================================================ O QUE FOI ADAPTADO
kids.push(new Paragraph({ children: [new PageBreak()] }));
kids.push(P([run("O QUE FOI ADAPTADO E POR QUÊ", { bold: true, size: 32, color: ACCENT })], { after: 40, keepNext: true }));
kids.push(P([run("Cada ajuste abaixo responde a um achado de pesquisa sobre aprendizagem e avaliação de estudantes autistas.",
  { size: 22, color: SOFT })], { after: 180, keepNext: true }));

const adapt = [
  ["Uma imagem em cada pergunta e em cada poema",
    "Apoios visuais são prática baseada em evidências para o TEA (mais de cem estudos de caso único revisados pelo NCAEP/AFIRM) e sustentam desde compreensão até engajamento na tarefa. Cada ilustração representa exatamente o que a pergunta cobra."],
  ["Ilustração instrucional, nunca decorativa",
    "Pelo princípio da coerência (Mayer), imagens bonitas mas irrelevantes — os “detalhes sedutores” — pioram a retenção e a transferência. Por isso nenhuma imagem traz enfeite: ela mostra o recurso ou o sentido que está sendo avaliado."],
  ["Etiquetas que só citam o verso, nunca a resposta",
    "As imagens sinalizam onde olhar (princípio da sinalização), mas o texto dentro delas repete apenas palavras do próprio poema. Nenhuma etiqueta antecipa a alternativa correta, então o item continua medindo o que se propõe."],
  ["Caixa VERSO EM FOCO dentro de cada pergunta",
    "Pelo princípio da contiguidade espacial, informação relacionada deve ficar junta. Repetir ali o verso indicado pela PISTA elimina a ida e volta entre páginas e reduz a carga de memória de trabalho."],
  ["Rotina fixa e previsível em todas as partes",
    "Ensino estruturado (TEACCH): sequência previsível, estrutura visual e sistema de trabalho que deixa claro o que fazer, quanto fazer e quando acaba. Toda parte segue a mesma ordem: cabeçalho, imagem, poema, perguntas, fim da parte."],
  ["Trilha de progresso e quadro MEU PROGRESSO",
    "Funciona como agenda visual: mostra onde o aluno está e quanto falta. Previsibilidade reduz ansiedade e favorece autonomia."],
  ["Três alternativas em vez de quatro",
    "Menos opções simultâneas diminuem a carga de comparação sem alterar o conceito avaliado. O gabarito conceitual foi mantido."],
  ["Frases curtas, uma informação por frase",
    "Sem duplo comando, sem forma negativa e sem oração encaixada. Enunciados diretos reduzem ambiguidade — coerente com o estilo de processamento que favorece informação clara e literal."],
  ["Apoio explícito ao sentido figurado",
    "A literatura mostra que linguagem figurada tende a ser interpretada literalmente no TEA e que o ganho vem de ensino explícito, apoio visual e múltiplos exemplos. Daí a caixa de ajuda ilustrada e uma imagem que torna concreto o sentido figurado."],
  ["Versos numerados e palavra-alvo em negrito",
    "Permite localizar a informação por referência direta, sem depender de varredura visual do texto inteiro."],
  ["Resposta marcada na própria pergunta",
    "Não há transferência para cartão-resposta, etapa que costuma gerar erro por transcrição e não por compreensão."],
  ["Cartões de pausa, ajuda e “já terminei”",
    "Dá uma forma de pedir o que precisa sem depender da fala no momento de tensão. A pausa é prevista e sinalizada no fim de cada parte."],
  ["Fonte sem serifa maior, entrelinha ampliada, fundo creme",
    "Design sensorialmente amigável: tipografia sem serifa (Arial), corpo e entrelinha ampliados, texto alinhado à esquerda, tons neutros e contraste suave, sem poluição visual."],
  ["Correção das pistas das perguntas 1, 2, 5 e 6",
    "Na versão anterior essas pistas apontavam versos que não continham a expressão cobrada (por exemplo, a pergunta 1 remetia ao verso 12, mas “senta no chão” está no verso 10). Uma pista errada quebra justamente o apoio que ela deveria dar."],
];
adapt.forEach(([t, p], i) => {
  kids.push(box([
    P([run(t, { bold: true, size: 24, color: ACCENT })], { after: 70, line: 300, keepNext: true }),
    P([run(p, { size: 22 })], { after: 0, line: 300 }),
  ], { fill: i % 2 ? CREAM_D : CREAM, pt: 120, pb: 120 }));
  kids.push(spacer(110));
});

// ============================================================ SUGESTOES
kids.push(new Paragraph({ children: [new PageBreak()] }));
kids.push(P([run("SUGESTÕES DE APLICAÇÃO", { bold: true, size: 32, color: ACCENT })], { after: 160, keepNext: true }));
const sug = [
  "Combine antes o tempo e mostre a prova impressa. Previsibilidade reduz ansiedade mais do que qualquer ajuste no papel.",
  "Permita tempo estendido e a aplicação em duas sessões, se a atenção se dispersar.",
  "Aceite leitura em voz alta pelo aplicador e resposta oral, registrando a escolha do aluno.",
  "Sala com pouco ruído e luz suave. Combine antes um sinal ou cartão para pedir pausa.",
  "Deixe a CAIXA DE AJUDA solta sobre a mesa, e não presa no meio do caderno.",
  "As perguntas 8, 14, 18 e 20 exigem sentido figurado — área de maior esforço para muitos alunos autistas. Se o aluno travar, releia o verso junto com ele antes de oferecer ajuda.",
  "Registre o que funcionou: leitura em voz alta, tempo extra, pausas. Isso alimenta o PEI do aluno.",
  "Autismo é espectro: ajuste esta versão ao aluno real. Se ele lê com autonomia, talvez precise só da versão comum com tempo maior; se usa comunicação alternativa, adapte também a forma de resposta.",
];
kids.push(box(sug.map((t, i) => P([run("•   ", { bold: true, color: ACCENT }), run(t)], {
  after: i === sug.length - 1 ? 0 : 130, indent: { left: 340, hanging: 340 },
}))));

// ============================================================ ROTEIRO DAS IMAGENS
kids.push(new Paragraph({ children: [new PageBreak()] }));
kids.push(P([run("ROTEIRO DAS IMAGENS", { bold: true, size: 32, color: ACCENT })], { after: 40, keepNext: true }));
kids.push(P([run(`Lista das ${img} ilustrações a produzir. Cada moldura tracejada do documento traz o mesmo número.`,
  { size: 22, color: SOFT })], { after: 160, keepNext: true }));

kids.push(box([
  P([run("Como devem ser as ilustrações", { bold: true, size: 24, color: ACCENT })], { after: 90, line: 300 }),
  ...[
    "Desenho ilustrado de verdade: figuras cheias, com volume e cena ao fundo. Nada de bonequinho de palito.",
    "Cores neutras e de baixa saturação, sem contraste agressivo e sem fundo poluído.",
    "Uma ideia por imagem. Nada de enfeite: tudo que aparece deve servir à pergunta.",
    "Texto dentro da imagem só pode citar o verso do poema. Nunca escreva a resposta nem o nome do recurso.",
    "Estilo igual nas 36 imagens: mesma paleta, mesma espessura de traço, mesma moldura.",
  ].map((t, i, a) => P([run("•   ", { bold: true, color: ACCENT }), run(t, { size: 22 })],
    { after: i === a.length - 1 ? 0 : 80, line: 300, indent: { left: 340, hanging: 340 } })),
], { fill: ACCENT_BG, pt: 140, pb: 140 }));
kids.push(spacer(200));

const rc = [1000, 2000, CONTENT - 3000];
const rotRows = [new TableRow({
  tableHeader: true,
  children: [["IMAGEM", rc[0]], ["ONDE ENTRA", rc[1]], ["O QUE DESENHAR", rc[2]]].map(([t, w]) =>
    cell([P([run(t, { bold: true, size: 20, color: "FFFFFF" })], { after: 0, align: AlignmentType.CENTER })],
      { width: w, fill: ACCENT, pt: 90, pb: 90 })),
})];
let ri = 0;
const addRot = (n, onde, oque) => {
  const f = ri++ % 2 ? CREAM_D : CREAM;
  rotRows.push(new TableRow({
    cantSplit: true,
    children: [
      cell([P([run(String(n), { bold: true, size: 22, color: ACCENT })], { after: 0, align: AlignmentType.CENTER })], { width: rc[0], fill: f, pt: 80, pb: 80 }),
      cell([P([run(onde, { size: 20 })], { after: 0, line: 260 })], { width: rc[1], fill: f, pt: 80, pb: 80 }),
      cell([P([run(oque, { size: 20 })], { after: 0, line: 260 })], { width: rc[2], fill: f, pt: 80, pb: 80 }),
    ],
  }));
};
let rn = 0;
RECURSOS.forEach(([nome, , , desenho]) => { rn += 1; addRot(rn, `Caixa de ajuda — ${nome}`, desenho); });
PARTES.forEach(parte => {
  rn += 1; addRot(rn, `Parte ${parte.n} — poema “${parte.titulo}”`, parte.imagem);
  parte.perguntas.forEach(q => { rn += 1; addRot(rn, `Pergunta ${q.n}`, q.imagem); });
});
kids.push(new Table({ columnWidths: rc, width: { size: CONTENT, type: WidthType.DXA }, rows: rotRows }));

// ------------------------------------------------------------------ montagem
const doc = new Document({
  creator: "Simulado adaptado",
  title: "Simulado de Língua Portuguesa — Poema — versão adaptada",
  styles: {
    default: {
      document: { run: { font: FONT, size: BODY, color: INK }, paragraph: { spacing: { line: LINE } } },
    },
  },
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 },
        margin: { top: 1134, bottom: 1020, left: 1247, right: 1247, footer: 560 },
      },
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          alignment: AlignmentType.RIGHT,
          spacing: { before: 0, after: 0, line: 240 },
          children: [
            new TextRun({ text: "Simulado adaptado — Poema        ", font: FONT, size: 17, color: "9A917E" }),
            new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 17, color: "9A917E", bold: true }),
          ],
        })],
      }),
    },
    children: kids,
  }],
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync("Simulado_Poema_TEA_v3.docx", buf);
  console.log("gerado: Simulado_Poema_TEA_v3.docx  (" + (buf.length / 1024).toFixed(1) + " KB)");
  console.log("molduras de imagem numeradas: " + img);
});
