# Selecteurs Chrome MCP — Orchestration Claude Design

Selecteurs et snippets JS utilises par le skill `claude-design-orchestrate` pour piloter les conversations. Complete ceux de `claude-design-system-audit/resources/selectors.md` (qui couvre plus le panel Design System).

**Regle de base** : les classes CSS sont instables (hash sc-*). Preferer : text content, role, aria-label, position (bounding rect).

---

## 1. Verifier que l'onglet projet est actif

```javascript
// Via Chrome MCP : mcp__Claude_in_Chrome__tabs_context_mcp
// Verifier que l'URL active commence par https://claude.ai/design/p/<uuid>
// Sinon : mcp__Claude_in_Chrome__navigate({ url: expected_project_url })
```

## 2. Lister les tabs de conversation ouverts

Les tabs conversation sont alignes en haut de la zone de chat. Chaque tab affiche "Chat" (ou un titre custom si renomme).

```javascript
// Recuperer les positions X des tabs (pour click via coordonnees)
const chatTabs = Array.from(document.querySelectorAll('*')).filter(el => {
  const r = el.getBoundingClientRect();
  return r.top > 40 && r.top < 95
    && el.children.length === 0
    && /^(chat|conversation)/i.test(el.textContent.trim());
});
const positions = chatTabs.map(el => Math.round(el.getBoundingClientRect().x + el.getBoundingClientRect().width / 2));
// positions = [30, 100, 170, ...] pour cliquer via mcp__Claude_in_Chrome__computer left_click
```

## 3. Creer une nouvelle conversation (bouton +)

```javascript
// Le "+" est a droite du dernier tab de conversation
const plusBtn = Array.from(document.querySelectorAll('button')).find(btn => {
  const r = btn.getBoundingClientRect();
  const txt = btn.textContent.trim();
  return r.top > 40 && r.top < 95
    && (txt === '+' || btn.getAttribute('aria-label')?.match(/new|create|ajouter/i));
});
if (plusBtn) plusBtn.click();
```

**Fallback robuste via Chrome MCP** :
```
mcp__Claude_in_Chrome__find({ query: "Button to create a new chat conversation, showing a plus icon at the top of the chat area" })
```

## 4. Remplir le composer principal (prompt utilisateur)

Le textarea utilise React controlled input, donc le .value simple ne suffit pas. Il FAUT passer par le native setter pour que React voie le changement.

```javascript
function fillComposer(prompt) {
  const ta = document.querySelector('textarea[placeholder="Describe what you want to create..."]')
    || document.querySelector('textarea[placeholder*="what you want" i]')
    || document.querySelector('form textarea');
  if (!ta) return { ok: false, reason: 'textarea not found' };
  
  ta.focus();
  const setter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set;
  setter.call(ta, prompt);
  ta.dispatchEvent(new Event('input', { bubbles: true }));
  
  return { ok: true, chars: prompt.length };
}
```

## 5. Envoyer le prompt (bouton Send)

Le bouton Send est a droite du composer, il contient generalement une icone fleche ou avion. Son ref_id change entre deploys.

```javascript
// Approche text/aria
const sendBtn = Array.from(document.querySelectorAll('button')).find(b => {
  const aria = b.getAttribute('aria-label')?.toLowerCase() || '';
  const insideForm = b.closest('form')?.querySelector('textarea');
  return (aria.includes('send') || aria.includes('submit'))
    && insideForm
    && !b.disabled;
});
sendBtn?.click();
```

**Preferer via Chrome MCP** :
```
mcp__Claude_in_Chrome__find({ query: "Send button in the main prompt composer (arrow or plane icon, right of textarea)" })
```

## 6. Detecter l'etat d'une conversation (en cours / attente / terminee)

### 6a. En generation

```javascript
// Signal : bouton "Stop generating" visible
const stopBtn = Array.from(document.querySelectorAll('button')).find(b => {
  const txt = b.textContent.trim().toLowerCase();
  const aria = b.getAttribute('aria-label')?.toLowerCase() || '';
  return txt.includes('stop') || aria.includes('stop');
});
const isGenerating = !!stopBtn;
```

### 6b. Question de clarification en attente

```javascript
// Signal : dernier message assistant contient une question (numerotee ou choix A/B/C)
const messages = document.querySelectorAll('[data-testid*="message"], [class*="message"]');
const lastAssistantMsg = Array.from(messages).reverse().find(m =>
  m.getAttribute('data-author') === 'assistant' ||
  m.querySelector('[class*="assistant"]')
);
const text = lastAssistantMsg?.textContent || '';
const hasQuestion = /option\s*[abc]|laquelle|choisis|prefere-tu|\?\s*$/i.test(text.slice(-500));
```

### 6c. Conversation terminee

```javascript
// Signal : pas de "Stop generating" + dernier message assistant long + pas de question
const isDone = !isGenerating && text.length > 300 && !hasQuestion;
```

## 7. Ouvrir un design dans le canvas

Apres une generation reussie, Claude Design affiche une card avec preview + "Open in canvas" ou un lien direct vers le fichier genere (ex : `agence-v1.html`).

```javascript
// Card canvas cliquable
const openBtn = Array.from(document.querySelectorAll('a, button, [role="button"]')).find(el => {
  const txt = el.textContent.trim().toLowerCase();
  return txt.includes('open in canvas') || txt.includes('ouvrir') || /\.html\b/.test(txt);
});
openBtn?.click();
```

**Preferer Chrome MCP** :
```
mcp__Claude_in_Chrome__find({ query: "Canvas preview card that opens the generated design in full view" })
```

## 8. Quitter le canvas (revenir au chat)

```javascript
// Bouton "X" ou "Close" en haut a droite du canvas
const closeBtn = Array.from(document.querySelectorAll('button')).find(b => {
  const aria = b.getAttribute('aria-label')?.toLowerCase() || '';
  return aria.includes('close') || aria.includes('exit') || b.textContent.trim() === '×';
});
closeBtn?.click();
```

## 9. Bouton "Handoff to Claude"

Generalement dans le canvas, en haut a droite ou dans le menu "..." (trois points). Ouvre un dialog avec la commande a copier-coller dans Claude Code.

```javascript
const handoffBtn = Array.from(document.querySelectorAll('button')).find(b => {
  const txt = b.textContent.trim().toLowerCase();
  const aria = b.getAttribute('aria-label')?.toLowerCase() || '';
  return txt.includes('handoff') || aria.includes('handoff');
});
handoffBtn?.click();

// Apres click, le dialog apparait
setTimeout(() => {
  const cmd = document.querySelector('[role="dialog"] code, [role="dialog"] pre')?.textContent;
  console.log('Handoff command:', cmd);
}, 400);
```

## 10. Viewport responsive (desktop / tablet / mobile)

Le canvas a des toggles pour changer la taille d'affichage. Utile pour screenshots responsive.

```javascript
// Recherche par aria-label ou icone
const viewports = {
  desktop: Array.from(document.querySelectorAll('button')).find(b => b.getAttribute('aria-label')?.match(/desktop/i)),
  tablet: Array.from(document.querySelectorAll('button')).find(b => b.getAttribute('aria-label')?.match(/tablet/i)),
  mobile: Array.from(document.querySelectorAll('button')).find(b => b.getAttribute('aria-label')?.match(/mobile|phone/i)),
};
viewports.mobile?.click();
```

## 11. Preuve qu'une conversation est associee a une direction (mapping interne)

Le skill orchestre tient un registre local :
```json
{
  "direction_id": "stripe-minimal",
  "tab_position_x": 30,
  "prompt_sent_at": "2026-04-21T14:30:00Z",
  "status": "generating | waiting_clarification | done | stuck",
  "transcript_preview": "...derniers 200 chars..."
}
```

Au polling, reconstruire ce mapping en :
1. Clic sur chaque tab (left_click via coordonnees X)
2. Attendre 400-800ms (re-render React)
3. Capturer le DOM actuel avec le snippet 6a/6b/6c
4. Mettre a jour le registre

## 12. Attention : rate limiting

Claude.ai a un rate limit soft (~3 conversations actives a la fois sur un projet). Si une 4eme tentative echoue avec "You're sending too many messages" :
- Attendre 30-60s
- Batch par 3

```javascript
// Detection rate limit message
const rateLimitEl = Array.from(document.querySelectorAll('*')).find(el =>
  /too many messages|rate limit|slow down/i.test(el.textContent) && el.children.length < 3
);
const isRateLimited = !!rateLimitEl;
```

## 13. Notes de robustesse

1. **React re-render** : apres un click / fill, attendre 400-800ms avant de re-lire la UI
2. **Tabs overflow** : si > 6 tabs, les plus anciens sont tronques a gauche. Scroller la tab bar avec `element.scrollIntoView({ inline: 'start' })` ou cliquer un tab absolut (position X negative vs viewport)
3. **iframe CORS dans canvas** : si le design utilise une iframe cross-origin, extraction DOM impossible. Fallback : screenshot via Chrome MCP
4. **Refresh de tab** : ne JAMAIS refresh pendant une generation (perd la conversation). Si besoin, naviguer vers projet puis cliquer le tab conversation
5. **Multi-device Claude Design** : si la UI detecte un layout mobile (viewport narrow), les tabs passent en dropdown. Toujours forcer `resize_window({ width: 1440, height: 900 })` avant de lancer
