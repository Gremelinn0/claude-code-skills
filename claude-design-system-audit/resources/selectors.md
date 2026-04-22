# Selecteurs Chrome MCP — Claude Design (claude.ai/design)

Selecteurs et snippets JS valides en session pour naviguer la UI de Claude Design. Les classes sc-* et hash CSS changent entre deploiements ; preferer les selecteurs par texte ou role.

## Naviguer vers un projet

```javascript
// URL pattern
// https://claude.ai/design/p/<project_uuid>

// Via Chrome MCP
mcp__Claude_in_Chrome__navigate({ url: "https://claude.ai/design/p/9171a33b-...", tabId })
```

## Detecter "Review draft design system"

```javascript
// Par texte (stable)
Array.from(document.querySelectorAll('*')).find(
  el => el.children.length === 0 && el.textContent.trim() === 'Review draft design system'
)

// Fallback via classe observee
document.querySelector('div.bSVzvR') // instable
```

## Lire les toggles Published / Default

```javascript
// Cherche les switches
const switches = document.querySelectorAll('[role="switch"]');
switches.forEach((s, i) => {
  const label = s.parentElement?.textContent.trim();
  const on = s.getAttribute('aria-checked') === 'true' || s.getAttribute('data-state') === 'checked';
  console.log(`${label}: ${on ? 'ON' : 'OFF'}`);
});
```

## Detecter warnings (Missing brand fonts etc.)

```javascript
// Les warnings ont generalement un fond rose/orange (bg-warning, red-bg)
const warnings = Array.from(document.querySelectorAll('*')).filter(el => {
  const style = window.getComputedStyle(el);
  return style.backgroundColor.includes('rgb(254') || el.textContent.toLowerCase().includes('missing');
}).map(el => el.textContent.trim()).filter((t, i, arr) => t.length > 10 && t.length < 200 && arr.indexOf(t) === i);
```

## Lister les brand refs (section "Brand")

```javascript
// Chaque ref est un div avec titre + sous-titre + pastille de status
// Strategie : scroll au bas de la page, puis collecter tous les textes dans la section "Brand"
const brandSection = Array.from(document.querySelectorAll('*')).find(
  el => el.children.length === 0 && el.textContent.trim() === 'Brand'
);
if (brandSection) {
  const container = brandSection.parentElement.parentElement; // ajuster selon profondeur
  const items = Array.from(container.querySelectorAll('div')).filter(d => {
    return d.children.length <= 2 && d.textContent.length > 5 && d.textContent.length < 100;
  });
  // Grouper par paires titre/sous-titre
}
```

## Compter les items en "Needs review"

```javascript
// "Needs review" suivi d'un nombre
const el = Array.from(document.querySelectorAll('*')).find(
  e => e.textContent.trim().startsWith('Needs review') && e.children.length < 3
);
const match = el?.textContent.match(/Needs review\s*(\d+)/);
const count = match ? parseInt(match[1]) : 0;
```

## Cliquer "Looks good" sur un ref specifique

```javascript
// "Looks good" apparait en bouton vert a droite du ref
// Chaque ref a un container unique ; trouver le container par titre puis le bouton interne
function clickLooksGood(refTitle) {
  const titleEl = Array.from(document.querySelectorAll('*')).find(
    el => el.children.length === 0 && el.textContent.trim() === refTitle
  );
  if (!titleEl) return 'title not found';
  let container = titleEl;
  for (let i = 0; i < 5 && container; i++) {
    const btn = container.querySelector?.('button');
    if (btn && btn.textContent.trim() === 'Looks good') {
      btn.click();
      return 'clicked';
    }
    container = container.parentElement;
  }
  return 'button not found';
}
```

## Cliquer "Needs work..." et remplir feedback

```javascript
function leaveNeedsWork(refTitle, feedback) {
  const titleEl = Array.from(document.querySelectorAll('*')).find(
    el => el.children.length === 0 && el.textContent.trim() === refTitle
  );
  if (!titleEl) return 'title not found';
  let container = titleEl;
  for (let i = 0; i < 5 && container; i++) {
    const btns = container.querySelectorAll?.('button');
    if (btns) {
      const needsBtn = Array.from(btns).find(b => b.textContent.trim().startsWith('Needs work'));
      if (needsBtn) {
        needsBtn.click();
        // Attendre que le textarea apparaisse
        setTimeout(() => {
          const ta = document.querySelector('textarea[placeholder*="prefer"]');
          if (ta) {
            const setter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set;
            setter.call(ta, feedback);
            ta.dispatchEvent(new Event('input', { bubbles: true }));
            // Cliquer Submit
            const submit = Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === 'Submit');
            submit?.click();
          }
        }, 400);
        return 'clicked needs work, feedback queued';
      }
    }
    container = container.parentElement;
  }
  return 'button not found';
}
```

## Lister les tabs de conversations

```javascript
// Les tabs "Chat" sont alignes en haut a gauche, au dessus de la barre de prompt
const tabs = Array.from(document.querySelectorAll('*')).filter(el => {
  const r = el.getBoundingClientRect();
  return r.top > 50 && r.top < 90 && el.children.length === 0 && el.textContent.trim() === 'Chat';
});
// Chaque tab renvoit sa position X, permet de cliquer via mcp__Claude_in_Chrome__computer left_click
const positions = tabs.map(el => Math.round(el.getBoundingClientRect().x));
```

## Creer une nouvelle conversation

```javascript
// Le bouton "+" est a droite des tabs Chat existants
// Generalement a x >= (dernier tab.x + 65)
const plusBtn = Array.from(document.querySelectorAll('button')).find(btn => {
  const r = btn.getBoundingClientRect();
  return r.top > 50 && r.top < 90 && btn.textContent.trim() === '+' || btn.getAttribute('aria-label')?.includes('new');
});
plusBtn?.click();
```

## Remplir le composer principal

```javascript
// Textarea "Describe what you want to create..."
const ta = document.querySelector('textarea[placeholder="Describe what you want to create..."]');
if (ta) {
  const setter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set;
  setter.call(ta, PROMPT_TEXT);
  ta.dispatchEvent(new Event('input', { bubbles: true }));
}
```

## Cliquer le bouton Send

```javascript
// Le bouton Send change souvent de ref_id entre conversations
// Selecteur stable : aria-label ou icone
// Utiliser mcp__Claude_in_Chrome__find avec query "Send button in main composer"

// Fallback JS
const sendBtn = Array.from(document.querySelectorAll('button')).find(b => {
  return b.getAttribute('aria-label')?.toLowerCase().includes('send') ||
         (b.closest('form')?.querySelector('textarea') && b.querySelector('svg'));
});
```

## Detecter l'etat d'une conversation (en generation ou terminee)

```javascript
// Si "Stop generating" visible -> en cours
const stopBtn = Array.from(document.querySelectorAll('button')).find(
  b => b.textContent.trim().toLowerCase().includes('stop') || b.getAttribute('aria-label')?.includes('stop')
);
const isGenerating = !!stopBtn;

// Si texte assistant final visible (fin par "Done", "Ouvre", "Voila", "Livre")
// -> terminee
```

## Ouvrir un design genere dans le canvas

```javascript
// Dans la conversation, le design apparait comme une card cliquable ou un lien "Ouvre <fichier>.html"
// Click sur la card ouvre le canvas en plein
const openLinks = Array.from(document.querySelectorAll('a, button')).filter(
  el => el.textContent.includes('.html') || el.textContent.toLowerCase().includes('ouvre')
);
openLinks[0]?.click();
```

## Recuperer le HTML du design

```javascript
// Une fois en canvas, le design est rendu dans un iframe
const iframe = document.querySelector('iframe[src*="canvas"], iframe[title*="design"], iframe');
if (iframe) {
  try {
    const html = iframe.contentDocument.documentElement.outerHTML;
    // Sauvegarder via bash Write tool
  } catch (e) {
    // CORS : utiliser screenshot a la place
  }
}
```

## Bouton "Handoff to Claude"

```javascript
// Probable emplacement : en haut a droite du canvas, ou dans un menu "..."
const handoffBtn = Array.from(document.querySelectorAll('button')).find(
  b => b.textContent.trim().toLowerCase().includes('handoff') ||
       b.getAttribute('aria-label')?.toLowerCase().includes('handoff')
);
handoffBtn?.click();
// Un dialog apparait avec la commande a copier
// Recuperer via : document.querySelector('[role="dialog"] code')?.textContent
```

## Notes de robustesse

1. **Les classes CSS sont instables** (sc-* hashes changent entre deploys). Toujours preferer : text content, role, aria-label, position.
2. **Wait states** : apres un click, attendre 400-800ms avant de lire la UI (React re-render).
3. **Shadow DOM** : Claude Design n'utilise pas de shadow DOM dans l'UI principale, c'est safe.
4. **iframe CORS** : le canvas de design peut etre iframe cross-origin. Dans ce cas, screenshot > extraction.
5. **Tabs overflow** : si plus de 6 tabs, le dernier est tronque. Scroller la barre de tabs via `element.scrollIntoView({ inline: 'end' })` ou cliquer les coordonnees (>= 437px x).
