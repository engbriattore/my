// Previa HTML com os mesmos tokens do DOCX, para conferencia visual do layout.
const fs = require("fs");
const { PARTES, RECURSOS } = require("./data.js");

const T = {
  ink: "#1B2430", soft: "#6E6656", cream: "#F5F1E8", creamD: "#EDE5D5",
  border: "#C9C1AE", accent: "#3F6B87", accentBg: "#E6EDF2", foco: "#F0EADA", ok: "#E8EFE4",
};
const css = `
*{margin:0;padding:0;box-sizing:border-box}
body{background:#8A8578;font-family:Arial,'Liberation Sans',sans-serif;color:${T.ink};padding:24px}
.page{width:794px;margin:0 auto 24px;background:#fff;padding:75px 83px;box-shadow:0 3px 14px rgba(0,0,0,.3)}
.t{font-size:17.3px;line-height:1.5}
h1{font-size:24px;text-align:center;margin-bottom:4px}
.sub{font-size:16px;color:${T.soft};text-align:center;margin-bottom:20px}
h2{font-size:18.7px;color:${T.accent};margin:0 0 8px}
h2.big{font-size:21.3px}
.box{border:1px solid ${T.border};background:${T.cream};padding:12px 14px;font-size:17.3px;line-height:1.5}
.slot{border:1px dashed ${T.border};background:#fff;padding:10px 14px}
.slot b{font-size:13.3px;color:${T.accent};display:block;margin-bottom:3px}
.slot i{font-size:12.7px;color:${T.soft}}
table{border-collapse:collapse;width:100%}
td,th{border:1px solid ${T.border};padding:7px 10px;font-size:14.7px;line-height:1.45;vertical-align:top}
th{background:${T.accent};color:#fff;font-size:13.3px;text-align:center}
.qhead{background:${T.accent};color:#fff;font-weight:bold;font-size:18.7px;padding:5px 10px}
.pista{background:${T.accentBg};border-left:6px solid ${T.accent};padding:7px 12px;font-size:17.3px;margin-top:4px}
.pista b{color:${T.accent}}
.foco{background:${T.foco};border:1px solid ${T.border};padding:10px 14px;margin-top:8px}
.foco .lab{font-size:12.7px;color:${T.soft};font-weight:bold;margin-bottom:5px}
.v{font-size:16px;line-height:1.65;text-indent:-30px;padding-left:30px}
.v .n{color:#9A917E;font-weight:bold;font-size:14.7px}
.alt{font-size:17.3px;line-height:1.5;margin-top:5px;text-indent:-60px;padding-left:60px}
.alt .p{font-weight:bold;font-size:18px}.alt .L{font-weight:bold;color:${T.accent}}
.bar{display:flex;margin-bottom:14px}
.bar .l{background:${T.accent};color:#fff;font-weight:bold;font-size:20px;padding:8px 14px}
.bar .r{flex:1;background:${T.cream};border:1px solid ${T.border};border-left:0;text-align:right;padding:8px 14px;font-size:14.7px;color:#A79E8B}
.bar .r b{color:${T.accent};font-size:17.3px}
.fim{background:${T.ok};border:1px solid ${T.border};padding:10px 14px;font-size:17.3px;margin-top:16px}
.sp{height:10px}
`;

const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");
const seg = a => a.map(s => s.b ? `<b>${esc(s.t)}</b>` : esc(s.t)).join("");
let img = 0;
const slot = (n, d) => `<div class="slot"><b>IMAGEM ${n}</b><i>${esc(d)}</i></div>`;

let h = `<!doctype html><meta charset="utf-8"><style>${css}</style><body class="t">`;

// ---- capa
h += `<div class="page"><h1>SIMULADO DE LÍNGUA PORTUGUESA</h1>
<div class="sub">Poema — 20 perguntas — versão adaptada para estudantes autistas</div>
<table><tr><td><b>Nome:</b> _______________________________________</td><td><b>Turma:</b> ____________</td></tr>
<tr><td><b>Data:</b> ______ / ______ / __________</td><td><b>Professor(a):</b> __________</td></tr></table>
<div class="sp"></div><div class="sp"></div>
<h2>COMO ESTA PROVA FUNCIONA</h2><div class="box">` +
  ["A prova tem 7 partes. Cada parte tem 1 poema e 2 ou 3 perguntas.",
   "Em cada parte você vai ler o poema e depois responder as perguntas.",
   "Cada pergunta tem 3 respostas: A, B e C. Só uma está certa.",
   "Marque um X dentro dos parênteses da resposta que você escolher.",
   "Antes de cada pergunta há uma PISTA. A pista diz em qual verso você deve olhar.",
   "Os versos do poema estão numerados: 01, 02, 03…",
   "Dentro da pergunta há uma caixa VERSO EM FOCO. Ela repete o verso da pista. Você não precisa voltar a página.",
   "Você pode olhar a CAIXA DE AJUDA a qualquer momento.",
   "No fim de cada parte você pode descansar.",
   "Se tiver dúvida, levante a mão e espere. A professora vai até você."]
  .map((t, i) => `<div class="v" style="text-indent:-28px;padding-left:28px;font-size:17.3px"><span style="color:${T.accent};font-weight:bold">${String(i + 1).padStart(2, "0")}.</span>&nbsp;&nbsp; ${esc(t)}</div>`).join("") +
`</div><div class="sp"></div>
<h2>MEU PROGRESSO</h2><div class="sub" style="text-align:left;font-size:14.7px;margin-bottom:6px">Marque um X quando terminar cada parte.</div>
<table><tr>` + ["parte 1","parte 2","parte 3","parte 4"].map(t=>`<td style="text-align:center;background:${T.cream}"><b>(&nbsp;&nbsp;&nbsp;&nbsp;)</b> ${t}</td>`).join("") + `</tr>
<tr>` + ["parte 5","parte 6","parte 7","acabei!"].map(t=>`<td style="text-align:center;background:${t==="acabei!"?T.ok:T.cream}"><b>(&nbsp;&nbsp;&nbsp;&nbsp;)</b> ${t}</td>`).join("") + `</tr></table>
<div class="sp"></div>
<h2>COMO PEDIR O QUE EU PRECISO</h2>
<table><tr>` + [["QUERO UMA PAUSA","Eu preciso parar um pouco."],["PRECISO DE AJUDA","Eu não entendi a pergunta."],["JÁ TERMINEI","Eu acabei esta parte."]]
  .map(([a,b])=>`<td style="text-align:center;background:${T.accentBg}"><b style="color:${T.accent};font-size:17px">${a}</b><br><span style="font-size:14px;color:${T.soft}">${b}</span></td>`).join("") + `</tr></table></div>`;

// ---- caixa de ajuda
h += `<div class="page"><h2 class="big">CAIXA DE AJUDA</h2>
<div class="sub" style="text-align:left;font-size:14.7px;margin-bottom:12px">Você pode consultar esta página a qualquer momento durante a prova.</div>
<table><tr><th style="width:16%">IMAGEM</th><th style="width:21%">RECURSO</th><th style="width:36%">O QUE É</th><th>EXEMPLO</th></tr>` +
RECURSOS.map(([n,q,e,des],i)=>{img++;return `<tr>
<td style="border-style:dashed;text-align:center"><b style="color:${T.accent};font-size:11.3px">IMAGEM ${img}</b><br><i style="font-size:10px;color:${T.soft}">${esc(des)}</i></td>
<td style="background:${i%2?T.creamD:T.cream}"><b>${n}</b></td>
<td style="background:${i%2?T.creamD:T.cream}">${esc(q)}</td>
<td style="background:${i%2?T.creamD:T.cream}"><i>${esc(e)}</i></td></tr>`}).join("") + `</table></div>`;

// ---- parte 1: poema
const p = PARTES[0];
const map = {}; let k = 0;
p.versos.forEach(v => { if (v !== "") map[++k] = v; });
img++;
h += `<div class="page"><div class="bar"><div class="l">PARTE 1 DE 7</div><div class="r"><b>1</b> — 2 — 3 — 4 — 5 — 6 — 7</div></div>
${slot(img, p.imagem)}<div class="sp"></div>
<div class="box" style="padding:16px 18px"><div style="font-size:20px;font-weight:bold;margin-bottom:10px">${p.titulo}</div>` +
p.versos.map(v => v === "" ? `<div style="height:9px"></div>` :
  `<div class="v"><span class="n">${String(Object.keys(map).find(kk=>map[kk]===v)).padStart(2,"0")}</span>&nbsp;&nbsp; ${esc(v)}</div>`).join("") +
`</div></div>`;

// ---- parte 1: perguntas 1 e 2
h += `<div class="page">`;
p.perguntas.slice(0, 2).forEach((q, qi) => {
  const focos = (q.pista.match(/\d+/g) || []).map(Number).filter(n => map[n]);
  img++;
  h += `${qi ? '<div style="height:20px"></div>' : ''}<div class="qhead">PERGUNTA ${q.n}</div>
<div class="pista"><b>PISTA:</b> ${esc(q.pista)}</div>
<div class="foco"><div class="lab">VERSO EM FOCO</div>` +
    focos.map(n => `<div class="v"><span class="n">${String(n).padStart(2,"0")}</span>&nbsp;&nbsp; ${esc(map[n])}</div>`).join("") +
`</div><div class="sp"></div>${slot(img, q.imagem)}<div class="sp"></div>` +
    q.enunciado.map(l => `<div style="margin-bottom:3px">${seg(l)}</div>`).join("") +
    `<div style="height:6px"></div>` +
    ["A","B","C"].map((L,i)=>`<div class="alt"><span class="p">(&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;)</span>&nbsp;&nbsp;&nbsp;<span class="L">${L})</span>&nbsp;&nbsp; ${esc(q.alt[i])}</div>`).join("");
});
h += `</div></body>`;
fs.writeFileSync("preview.html", h);
console.log("preview.html gerado");
