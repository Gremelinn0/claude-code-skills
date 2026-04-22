# Extraction patterns — recuperer les outputs depuis Claude Design

Snippets JS et commandes Chrome MCP pour recuperer ce que Claude Design a genere : HTML, JSX/TSX, screenshots, transcripts, fichiers attaches.

**Objectif** : apres qu'une conversation Claude Design ait produit un design, le skill doit :
1. Extraire le HTML rendu (si accessible)
2. Screenshot le canvas en desktop + mobile
3. Sauvegarder le transcript complet assistant
4. Lister les fichiers mentionnes (`*.html`, `*.jsx`, `*.tsx`) et les recuperer si possible

Tout ca est sauvegarde dans `design_outputs/<YYYY-MM-DD>/<page_name>/<direction>_<asset>.{html,png,md}`.

---

## 1. Screenshot desktop du canvas

```
mcp__Claude_in_Chrome__resize_window({ width: 1440, height: 900 })
// Attendre 500ms
mcp__Claude_in_Chrome__javascript_tool({
  code: `
    // Forcer viewport desktop dans le canvas si toggle disponible
    const desktopBtn = Array.from(document.querySelectorAll('button')).find(b => b.getAttribute('aria-label')?.match(/desktop/i));
    desktopBtn?.click();
    'switched to desktop';
  `
})
// Attendre 800ms
mcp__Claude_in_Chrome__computer({ action: 'screenshot' })
// Sauvegarder le resultat : design_outputs/<date>/<page>/<direction>_desktop.png
```

## 2. Screenshot mobile (375x812)

```
mcp__Claude_in_Chrome__resize_window({ width: 900, height: 900 }) // garde window large
mcp__Claude_in_Chrome__javascript_tool({
  code: `
    // Basculer le canvas en mode mobile
    const mobileBtn = Array.from(document.querySelectorAll('button')).find(b => b.getAttribute('aria-label')?.match(/mobile|phone/i));
    mobileBtn?.click();
    'switched to mobile';
  `
})
// Attendre 800ms pour re-render
mcp__Claude_in_Chrome__computer({ action: 'screenshot' })
// Sauvegarder : <direction>_mobile.png
```

**Note** : certains designs generes n'ont pas de toggle mobile. Dans ce cas, le skill tente un `resize_window({ width: 500, height: 900 })` pour forcer un reflow CSS responsive.

## 3. Extraction HTML du rendu (iframe accessible)

Le canvas rend le design dans une iframe. Si elle est sur le meme domaine (pas de CORS), on peut lire le DOM complet.

```javascript
function extractCanvasHTML() {
  // Trouver l'iframe principale (il y en a parfois plusieurs : preview + tools)
  const iframes = Array.from(document.querySelectorAll('iframe'));
  const canvasIframe = iframes.find(f => {
    const src = f.src || '';
    const title = f.title || '';
    return src.includes('claude.ai') || title.toLowerCase().includes('design') || title.toLowerCase().includes('canvas') || (!src && f.offsetWidth > 300);
  });
  
  if (!canvasIframe) return { ok: false, reason: 'no iframe found' };
  
  try {
    const doc = canvasIframe.contentDocument || canvasIframe.contentWindow.document;
    return {
      ok: true,
      html: doc.documentElement.outerHTML,
      chars: doc.documentElement.outerHTML.length,
      title: doc.title,
    };
  } catch (e) {
    return { ok: false, reason: 'CORS blocked: ' + e.message };
  }
}

JSON.stringify(extractCanvasHTML());
```

Si CORS bloque : fallback vers screenshot + scraping du transcript pour recuperer les chunks de HTML inclus.

## 4. Extraction du transcript assistant

Le skill doit sauvegarder le dernier message assistant (texte complet) en Markdown.

```javascript
function extractLastAssistantMessage() {
  // Selecteurs possibles selon deploys
  const messageSelectors = [
    '[data-testid*="message-assistant"]',
    '[class*="assistant-message"]',
    '[data-author="assistant"]',
    'article[class*="message"]'
  ];
  
  let messages = [];
  for (const sel of messageSelectors) {
    const found = document.querySelectorAll(sel);
    if (found.length > 0) { messages = Array.from(found); break; }
  }
  
  // Fallback : chercher par structure (message = div contenant beaucoup de texte, non-user)
  if (messages.length === 0) {
    messages = Array.from(document.querySelectorAll('div')).filter(d => {
      const t = d.textContent.trim();
      return t.length > 200 && t.length < 50000 && d.children.length > 2 && !d.querySelector('textarea');
    });
  }
  
  const lastAssistant = messages[messages.length - 1];
  if (!lastAssistant) return { ok: false, reason: 'no assistant message found' };
  
  return {
    ok: true,
    text: lastAssistant.textContent.trim(),
    html: lastAssistant.innerHTML,
    chars: lastAssistant.textContent.length,
  };
}

JSON.stringify(extractLastAssistantMessage());
```

## 5. Extraction de TOUS les messages de la conversation (full transcript)

```javascript
function extractFullTranscript() {
  const messages = [];
  const containers = document.querySelectorAll('[class*="message"], [data-testid*="message"]');
  
  containers.forEach(el => {
    const isUser = el.getAttribute('data-author') === 'user' ||
                   el.className.includes('user') ||
                   el.querySelector('[class*="user"]');
    const isAssistant = el.getAttribute('data-author') === 'assistant' ||
                        el.className.includes('assistant') ||
                        el.querySelector('[class*="assistant"]');
    
    if (!isUser && !isAssistant) return;
    
    messages.push({
      role: isUser ? 'user' : 'assistant',
      text: el.textContent.trim(),
      ts: el.querySelector('time')?.getAttribute('datetime') || null,
    });
  });
  
  return { ok: true, count: messages.length, messages };
}

JSON.stringify(extractFullTranscript());
```

Le skill formate ensuite en Markdown :
```markdown
# Transcript — <direction_id>
Date : 2026-04-21
Conversation URL : https://claude.ai/design/p/<proj>/c/<conv_id>

---

## User
<texte message 1>

## Assistant
<texte message 2>

## User
<texte message 3>

...
```

## 6. Lister les fichiers generes mentionnes

Claude Design nomme souvent ses livrables dans le transcript : "J'ai genere `agence-v1.html` et `components.jsx`". Extraire les references :

```javascript
function listMentionedFiles(transcriptText) {
  // Regex pour .html, .jsx, .tsx, .css, .json
  const matches = transcriptText.match(/[\w\-]+\.(html?|jsx?|tsx?|css|json|scss)/g) || [];
  // Dedupe
  return [...new Set(matches)];
}
```

## 7. Ouvrir le fichier dans le canvas et extraire son source

Certains fichiers sont visibles directement dans le canvas (via l'onglet "Files"). Cliquer sur le fichier puis scraper le contenu.

```javascript
function openFileInCanvas(filename) {
  const filesTab = Array.from(document.querySelectorAll('*')).find(el =>
    el.children.length === 0 && /^files?$/i.test(el.textContent.trim())
  );
  filesTab?.click();
  
  // Attendre que la liste apparaisse, puis cliquer le fichier
  setTimeout(() => {
    const fileLink = Array.from(document.querySelectorAll('a, button, [role="button"]')).find(el =>
      el.textContent.trim() === filename || el.textContent.includes(filename)
    );
    fileLink?.click();
  }, 500);
}

function extractFileContent() {
  // Apres ouverture, le contenu est dans un code editor
  const codeEl = document.querySelector('[class*="code"] pre, [role="code"], .monaco-editor');
  if (!codeEl) return null;
  
  // Monaco editor : iterer sur les lignes visibles
  const lines = Array.from(codeEl.querySelectorAll('.view-line'));
  if (lines.length > 0) {
    return lines.map(l => l.textContent).join('\n');
  }
  
  // Fallback pre/code simple
  return codeEl.textContent;
}
```

Si l'editeur est Monaco, les lignes sont virtualisees (seules les visibles sont dans le DOM). Dans ce cas, il faut scroller et concatener. Solution plus robuste : copier-coller via selection + execCommand :

```javascript
function copyMonacoFileContent() {
  const monaco = document.querySelector('.monaco-editor');
  if (!monaco) return null;
  
  monaco.focus();
  document.execCommand('selectAll');
  document.execCommand('copy');
  
  // Le contenu est dans le clipboard, le skill doit lire via mcp__computer-use__read_clipboard
  return 'copied to clipboard';
}
```

## 8. Alternative : bouton "Handoff to Claude"

Claude Design a un bouton "Handoff to Claude" qui genere une commande clipboard pour demarrer un projet Claude Code avec le design. Recuperer cette commande est une alternative a l'extraction HTML.

```javascript
function triggerHandoff() {
  const handoffBtn = Array.from(document.querySelectorAll('button')).find(b => {
    const txt = b.textContent.trim().toLowerCase();
    return txt.includes('handoff') || b.getAttribute('aria-label')?.toLowerCase().includes('handoff');
  });
  if (!handoffBtn) return { ok: false, reason: 'button not found' };
  handoffBtn.click();
  
  return { ok: true, status: 'dialog opened, wait 500ms then extract command' };
}

function extractHandoffCommand() {
  const dialog = document.querySelector('[role="dialog"]');
  if (!dialog) return null;
  
  const codeEl = dialog.querySelector('code, pre');
  return codeEl?.textContent.trim();
}
```

Le skill peut ensuite sauvegarder cette commande dans `<direction>_handoff.md`.

## 9. Download via bouton "Export" (si disponible)

Claude Design a parfois un bouton Export qui telecharge les fichiers en .zip.

```javascript
function triggerExport() {
  const exportBtn = Array.from(document.querySelectorAll('button')).find(b => {
    const txt = b.textContent.trim().toLowerCase();
    return txt.includes('export') || txt.includes('download');
  });
  exportBtn?.click();
}
```

Le telechargement arrive dans `~/Downloads/`. Le skill peut detecter via un check Bash sur le dossier, puis deplacer vers `design_outputs/<date>/<page>/<direction>.zip`.

---

## 10. Pipeline complet — recette

Pour chaque direction terminee :

```
# 1. Naviguer vers la conversation de la direction
mcp__Claude_in_Chrome__computer({ action: 'left_click', x: <tab_position>, y: 60 })
# wait 600ms

# 2. Ouvrir le canvas (click sur la card preview ou le lien .html)
mcp__Claude_in_Chrome__javascript_tool({ code: 'const b = Array.from(...).find(...); b.click();' })
# wait 800ms

# 3. Screenshot desktop
mcp__Claude_in_Chrome__resize_window({ width: 1440, height: 900 })
# wait 400ms
mcp__Claude_in_Chrome__computer({ action: 'screenshot' })
# save to <direction>_desktop.png

# 4. Switch to mobile + screenshot
# (JS pour cliquer le toggle mobile)
# wait 600ms
mcp__Claude_in_Chrome__computer({ action: 'screenshot' })
# save to <direction>_mobile.png

# 5. Extraire HTML (si accessible)
mcp__Claude_in_Chrome__javascript_tool({ code: 'JSON.stringify(extractCanvasHTML());' })
# save to <direction>.html

# 6. Extraire transcript
mcp__Claude_in_Chrome__javascript_tool({ code: 'JSON.stringify(extractFullTranscript());' })
# save to <direction>_transcript.md

# 7. Lister fichiers mentionnes, puis scraper chacun
# Pour chaque fichier : openFileInCanvas + extractFileContent
# save to <direction>_<filename>

# 8. Optionnellement : trigger Handoff + extractHandoffCommand
# save to <direction>_handoff.md
```

---

## 11. Gestion des cas non-ideaux

### Case A : canvas iframe CORS bloque
- Fallback 1 : screenshot seul (perte du code source)
- Fallback 2 : scraper le code blocks dans le transcript (Claude Design inclut souvent le HTML dans la reponse text)

### Case B : Monaco editor partiellement rendu
- Scroller le canvas file viewer avec `element.scrollTop = element.scrollHeight` par chunks
- Capturer chunk par chunk et concatener

### Case C : Pas de toggle mobile dans le canvas
- Utiliser `resize_window({ width: 500, height: 900 })` pour forcer reflow CSS
- Si le design est fluide, le viewport changera. Sinon, screenshot tel quel et annoter comme "desktop-only design"

### Case D : Conversation stuck (en generation > 15 min)
- Cliquer "Stop generating" (si disponible)
- Screenshot l'etat actuel
- Flagger comme `status: stuck` dans le registre
- Passer a la direction suivante

### Case E : Question de clarification non prevue
- Extraire le texte de la question
- Consulter `resources/question_responses.md`
- Si pattern match → repondre auto
- Si pas de match → flagger `status: needs_user`, laisser pour review manuelle

---

## 12. Structure de sortie finale

```
design_outputs/
  2026-04-21/
    agence/
      stripe-minimal_desktop.png
      stripe-minimal_mobile.png
      stripe-minimal.html
      stripe-minimal_transcript.md
      stripe-minimal_handoff.md
      linear-energetic_desktop.png
      linear-energetic_mobile.png
      linear-energetic.html
      linear-energetic_transcript.md
      hormozi-vsl_desktop.png
      hormozi-vsl_mobile.png
      hormozi-vsl.html
      hormozi-vsl_transcript.md
      _synthesis.md
      _merge_brief.md
      index.html  # Page locale qui affiche les 3 directions cote a cote
```

Le fichier `index.html` est generé par le skill avec :
- Titre de la page
- 3 cards (une par direction) avec :
  - Nom de la direction
  - Thumbnail desktop
  - Thumbnail mobile
  - Verdict (RETENIR / REWORK / DROP)
  - Lien "Voir transcript"
  - Lien "Voir HTML source"
- Section "Merge brief" en bas

Permet une review rapide visuelle.
