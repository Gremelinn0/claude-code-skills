---
name: claude-design-system-audit
description: Audite et optimise le Design System d'un projet Claude Design (claude.ai/design). Verifie la completude (fonts, tokens, brand refs, a11y), identifie les gaps, applique les fixes quand possible, et rend un rapport. A invoquer avant toute grosse campagne de generation de designs pour garantir que les outputs heriteront d'un systeme propre. S'appuie sur `design:design-system`, `design:design-critique`, `design:accessibility-review`, `marketing:brand-review`.
---

# Claude Design System Audit

## Quand utiliser ce skill

- Tu as cree ou herite un projet Claude Design et tu veux t'assurer que le Design System est propre avant de generer des masses de variantes
- Le Design System a ete initialise par Sonnet/Haiku et tu veux le challenger avec Opus/Sonnet-4-7
- Tu as accumule 5+ "Needs review" items et il faut trier
- Des fonts de marque manquent, des tokens sont incoherents, des brand refs sont en double

**Ne pas utiliser quand :** tu veux juste generer de nouvelles variantes (→ `/claude-design-orchestrate`), ou tu veux valider une seule direction (→ review manuelle dans l'UI).

## Prerequis

- Chrome MCP connecte (`mcp__Claude_in_Chrome__*`)
- Un projet Claude Design existant avec son URL (ex : `https://claude.ai/design/p/<uuid>`)
- Un fichier de reference "brand identity" local OU un projet avec tokens definis

## Inputs attendus de l'utilisateur

1. **URL du projet Claude Design** (obligatoire)
2. **Reference brand locale** (facultatif, defaut = chercher `brand-identity` skill dans le projet courant)
3. **Mode** :
   - `audit` (defaut) : rapport uniquement, aucune action dans Claude Design
   - `fix` : applique les fixes automatiques (rename refs, reorder, mark looks good/needs work selon criteres)
   - `aggressive` : comme `fix` + supprime les brand refs redondantes

## Workflow — 7 etapes (+ option routine)

### Etape 1 — Charger la brand identity locale (source de verite)

- [ ] Chercher `brand-identity/SKILL.md` dans le projet courant, sinon dans `~/.claude/skills/`
- [ ] Extraire : couleurs (`#050508`, gradient `#3B82F6→#8B5CF6`), typo (`Inter 300-800`), ton de voix (zero em-dash, "je" pas "on"), regles absolues
- [ ] Charger aussi `CLAUDE_DESIGN_PROJECT_INSTRUCTIONS.md` si present dans le projet courant (contraintes propres au projet Claude Design)

### Etape 2 — Navigation Claude Design + snapshot etat actuel

- [ ] `mcp__Claude_in_Chrome__tabs_context_mcp` puis `navigate` vers l'URL du projet
- [ ] Attendre le chargement (detecter "Review draft design system" via `get_page_text` ou `read_page`)
- [ ] **Snapshot** via `javascript_tool` :
  - Etat des toggles `Published` / `Default`
  - Warnings visibles (ex : "Missing brand fonts")
  - Liste des brand refs (section "Brand") avec leur titre
  - Count "Needs review N"
  - Tabs de conversations (Chat × N)

### Etape 3 — Invoke `design:design-system` pour l'evaluation systeme

Le skill `design:design-system` fournit l'expertise sur ce qu'un design system complet doit contenir. Utiliser ses criteres pour scorer :

- Tokens : colors (primary / secondary / semantic), spacing scale, radius scale, shadows
- Typography : display font + body font + mono (si code), scale (h1-h6, body, caption)
- Components : CTA, card, input, badge, nav, footer, modal, table, pricing, hero
- States : default / hover / active / disabled / error
- Dark / light modes

Pour chaque dimension, annoter : **PRESENT** / **IMPLICITE** / **MANQUANT** selon ce qui est visible dans les brand refs.

### Etape 4 — Cross-check avec `marketing:brand-review` et `design:accessibility-review`

- [ ] `marketing:brand-review` → cherche incoherences de ton, messaging, reassurance. Applique sur les textes visibles dans les brand refs
- [ ] `design:accessibility-review` → contraste des couleurs observables, tailles de text, hierarchie
- [ ] `design:design-critique` → 1 critique par brand ref listee (forces + faiblesses)

### Etape 5 — Generer le rapport d'audit

Format Markdown, structure :

```markdown
# Audit Design System — <nom du projet>

**URL :** <url>
**Date :** <YYYY-MM-DD>
**Score global :** X/10

## 1. Etat de surface
- Published : ON/OFF
- Default : ON/OFF
- Warnings : [liste]
- Needs review : N items

## 2. Tokens (via design:design-system)
### Colors
- Primary : PRESENT/IMPLICITE/MANQUANT — <details>
- Semantic : ...
### Typography
### Spacing / Radius
### Components

## 3. Brand refs (via design:design-critique)
### <ref 1>
- Forces : ...
- Faiblesses : ...
- Verdict : KEEP / REWORK / DROP

## 4. A11y
- Contrast : ...
- Hierarchie : ...

## 5. Gaps prioritaires (top 5)
1. <action la plus critique>
2. ...

## 6. Plan d'action
- [ ] Upload fonts : <quels .woff2>
- [ ] Approuver : <refs>
- [ ] Needs work : <refs avec feedback>
- [ ] Supprimer : <refs>
- [ ] Nouveau prompt a lancer pour combler un gap : <brief>
```

Sauvegarder dans `memory/claude_design_audit_<YYYY-MM-DD>.md` du projet courant.

### Etape 6 — Appliquer les fixes (si mode fix/aggressive)

- [ ] Si fonts manquent ET assets locaux dispo → click "Upload fonts" + drag .woff2
- [ ] Pour chaque brand ref avec verdict **KEEP** → click "Looks good"
- [ ] Pour chaque brand ref avec verdict **REWORK** → click "Needs work..." + remplir le textarea avec le feedback synthetise
- [ ] **Jamais de suppression** sans verdict explicite + confirmation utilisateur (meme en mode aggressive → demander avant de rm)

### Etape 7 — Export complet local (Axe 1 de la methodologie Jack Roberts)

**Principe** : recuperer integralement le projet Claude Design (design system + tous les HTML/JSX generes) comme ZIP local, pour pouvoir l'importer dans Claude Code Desktop, NotebookLM, ou juste archiver.

**Endpoint API decouvert** : `/v1/design/projects/<project_id>/download` retourne un ZIP complet avec tous les fichiers du projet (root + sous-dossiers `library/`, `universes/`). Cet endpoint fonctionne via les cookies de session claude.ai — pas besoin d'OAuth separee.

**Workflow d'export** :

1. **Preparer le dossier local** :
   ```bash
   mkdir -p "C:/tmp/claude-design-exports/<YYYY-MM-DD>"
   ```

2. **Lister les fichiers du projet** via Chrome MCP `javascript_tool` pour verifier ce qu'on va recuperer :
   ```javascript
   fetch('/v1/design/projects/<PROJECT_ID>/files', { credentials: 'include' })
     .then(r => r.json())
     .then(j => j.entries.map(e => `${e.type} | ${e.size} | ${e.name}`).join('\n'))
   ```

3. **Fetcher le ZIP complet** et declencher download browser :
   ```javascript
   fetch('/v1/design/projects/<PROJECT_ID>/download', { credentials: 'include' })
     .then(r => r.arrayBuffer())
     .then(buf => {
       const bytes = new Uint8Array(buf);
       window.__zipBytes = bytes;
       const blob = new Blob([bytes], { type: 'application/zip' });
       const url = URL.createObjectURL(blob);
       const a = document.createElement('a');
       a.href = url;
       a.download = 'claude-design-project-<PROJECT_ID>.zip';
       document.body.appendChild(a);
       a.click();
       document.body.removeChild(a);
       setTimeout(() => URL.revokeObjectURL(url), 1000);
       return bytes.length;
     })
   ```

4. **Deplacer le ZIP** depuis `Downloads/` vers le dossier cible et l'extraire :
   ```bash
   mv "/c/Users/Administrateur/Downloads/claude-design-project-<ID>.zip" "/c/tmp/claude-design-exports/<date>/"
   cd "/c/tmp/claude-design-exports/<date>/" && unzip -o claude-design-project-<ID>.zip
   ```

5. **Verifier l'integrite** : afficher `ls -la` et verifier que le nombre de fichiers correspond a ce que l'API /files a liste.

5bis. **OBLIGATOIRE — Redeployer sur Vercel** (URL permanente de preview visuelle) :
   ```bash
   cd "/c/tmp/claude-design-exports/<YYYY-MM-DD>/" && npx vercel deploy --prod --yes
   ```
   Puis aliaser vers l'URL permanente :
   ```bash
   npx vercel alias set <deploy-url-genere> antigravity-design-preview
   ```
   Resultat : `https://antigravity-design-preview.vercel.app` pointe toujours vers le snapshot le plus recent.

   **Ouvrir dans le navigateur de Florent pour verification visuelle :**
   ```bash
   start "" "https://antigravity-design-preview.vercel.app"
   ```

6. **Optionnel — pousser selection dans NotebookLM** (brique pour interrogation en langage naturel) :
   - Creer / reutiliser un notebook "Claude Design Reference" (URL dans `memory/reference_brain_notebook.md`)
   - Agreger les fichiers cles (tokens.css + index.html + 3 universes + library components) dans un unique markdown
   - Upload via Chrome MCP (le CLI Playwright ne marche pas quand Chrome tourne)

**Sortie attendue** : chemin local imprime + nombre de fichiers extraits + taille totale.

**Regles de garde specifiques a l'export** :
- Jamais d'ecrasement : toujours utiliser un dossier horodate `<YYYY-MM-DD>` 
- Si le dossier existe deja et a du contenu → demander confirmation avant de re-download
- Conserver le ZIP original apres extraction (utile pour re-unzip)

### Etape 8 — Routine d'export automatique hebdomadaire (Axe 4) ✅ DEPLOYEE

**But** : re-exporter le projet Claude Design chaque semaine pour garder un snapshot versionne localement.

#### Tache programmee en place (creee 2026-04-22)

| Champ | Valeur |
|-------|--------|
| **taskId** | `claude-design-export-hebdo` |
| **Fichier** | `C:\Users\Administrateur\.claude\scheduled-tasks\claude-design-export-hebdo\SKILL.md` |
| **Cron** | `0 8 * * 1` (lundi 8h local) |
| **notifyOnCompletion** | true |
| **Mode** | local (Chrome MCP requis pour cookies claude.ai) |
| **Projet cible** | Antigravity, ID `9171a33b-6bba-42ef-a95b-e803ed52965c` |

#### Ce que fait la tache a chaque run

1. Navigue sur `https://claude.ai/design/p/<id>` via Chrome MCP
2. Liste les fichiers du projet via `GET /v1/design/projects/<id>/files`
3. Telecharge le ZIP via `GET /v1/design/projects/<id>/download` (trigger browser download)
4. Deplace le ZIP depuis `Downloads/` vers `C:\tmp\claude-design-exports\<YYYY-MM-DD>\`
5. Unzip + verifie le nombre de fichiers extraits
6. Compare avec l'export precedent → logger diff ou no-change
7. Pousse une ligne dans Notion page 34901e69443c81918ff3c4608963a157 section "Exports automatises"

#### Comment la re-creer si elle disparait

Invoquer le skill `/routine` en mode local avec le prompt ci-dessus, OU appeler directement :
```
mcp__scheduled-tasks__create_scheduled_task({
  taskId: "claude-design-export-hebdo",
  cronExpression: "0 8 * * 1",
  notifyOnCompletion: true,
  description: "[CLAUDE DESIGN] Export hebdo lundi 8h — snapshot ZIP du projet Antigravity",
  prompt: <contenu integral de Etape 7 ci-dessus>
})
```

#### Monitoring

- Sidebar "Scheduled" de Claude Code desktop → statut + next run
- `mcp__scheduled-tasks__list_scheduled_tasks` pour check programmatique
- Apres premier run reussi → cliquer "Run now" manuellement pour pre-approuver les permissions Chrome MCP, sinon les runs suivants peuvent bloquer sur popup

## Selecteurs Chrome MCP (reference)

```javascript
// Trouver "Review draft design system"
document.querySelector('div.bSVzvR') // classe peut bouger, fallback sur texte
Array.from(document.querySelectorAll('*')).find(el => el.textContent.trim() === 'Review draft design system')

// Toggles Published/Default
document.querySelectorAll('[role="switch"]')

// Brand refs
Array.from(document.querySelectorAll('*')).filter(el => {
  const r = el.getBoundingClientRect();
  return r.top > 300 && el.children.length === 0 && el.textContent.length > 5 && el.textContent.length < 80;
})

// Boutons Looks good / Needs work pour chaque ref
document.querySelectorAll('button[class*="looks-good"], button:has(span:contains("Looks good"))')
```

## Outputs livres

- `memory/claude_design_audit_<YYYY-MM-DD>.md` — rapport complet
- Page Notion dans table Projets avec resume + lien vers rapport local (si config Notion dispo)
- Modifications visibles dans Claude Design (si mode fix)

## Regles de garde

- **Jamais de delete sans confirmation** — meme en mode aggressive
- **Jamais de changement de "Default" toggle** — decision produit
- **Zero em-dash** dans les feedbacks "Needs work" (regle Florent)
- **Feedback en francais**, "je" pas "on"
- Si un brand ref est controverse (forces ET faiblesses equivalentes), le laisser en pending et le flagger dans le rapport — pas de decision automatique

## Integration avec skills voisins

- **Avant :** ce skill
- **Apres :** `/claude-design-orchestrate` — qui genere de nouvelles directions en sachant que le systeme est propre
- **En parallele :** `brand-identity` local — mettre a jour les tokens locaux avec ce qui emerge de l'audit

## Etape 9 — Bascule Claude Code si rate limit Claude Design

**Pattern cle capture de la video Jack Roberts 2026-04-21** (https://www.youtube.com/watch?v=34VoezbEvLw) : Claude Design tourne sur Opus 4.7, token-hungry. On hit le rate limit vite. Solution eprouvee : exporter le Design System et basculer sur Claude Code desktop app qui n'a pas ces limites.

### Procedure complete

1. **Depuis l'UI Claude Design** : panel Design Systems (droite) → ouvrir le DS concerne → bouton **Share** → soit `Export as PDF`, soit `Download as zip`
2. **Alternative programmatique** (plus rapide, deja documentee en Etape 7) : fetch `/v1/design/projects/<id>/download` pour avoir le ZIP complet du projet
3. **Dans Claude Code desktop** : attacher le zip via le bouton fichier (`+` ou drag-drop)
4. **Prompt de codification** (a copier-coller) :
   > "Hey there, I'd like you to quickly codify this design system. I'm about to create [animated graphics / new page / landing / component]. First, parse the zip, extract the tokens, fonts, components, brand refs. Confirm when you have a full mental model of the DS. Then I'll give you my next task using this DS."
5. Claude Code reproduit la meme expertise Opus 4.7 (sur sa couche CLI) sans le rate limit de l'UI

### Quand declencher la bascule

- L'utilisateur touche le rate limit dans Claude Design (notif "You've reached your limit")
- On veut itérer rapidement sur le DS sans consommer les tokens UI
- On veut faire quelque chose que Claude Design ne peut pas (fetch web, lire fichiers locaux, modifier du code)

### Garde-fou

- Le DS exporte est une **photo** a l'instant T. Si on modifie le DS dans Claude Code, les changements ne remontent PAS dans Claude Design automatiquement.
- Pour syncer : re-upload un nouveau snapshot dans Claude Design (via "Regenerate from reference" ou manuel)

## Etape 10 — Pistes d'amelioration issues de la video Jack Roberts (2026-04-21)

Video : https://www.youtube.com/watch?v=34VoezbEvLw ("Claude just changed Content Creation Forever", 15:22 min, 10k+ vues).

Scope de la video = creation de contenu (animations, captions, audio), different de notre scope (audit de DS pour sites web). Mais 3 patterns techniques transferables :

### Piste 1 — Economie de tokens Opus 4.7 / Sonnet 4.6

Jack Roberts : "Sonnet 4.6 is way more than enough like 99% of stuff". Regle implementee dans ce skill :

- **Opus 4.7** pour l'audit initial + les fixes structurels complexes (generation de tokens, reorganisation massive de brand refs)
- **Sonnet 4.6** pour l'application des feedbacks "Needs work" et les petits fixes iteratifs (99 % des cas)

Si `--fix` mode avec < 10 brand refs a traiter → Sonnet 4.6 suffit.

### Piste 2 — Tip `/b` pour monitoring non-bloquant

Dans Claude Code desktop, le raccourci `/b` permet de poser une question **pendant** qu'une generation tourne, sans interrompre le travail. Exemple : "is it progressing?" ou "what phase are you in?".

Utile quand l'audit tourne longtemps (gros projet avec 50+ brand refs) et qu'on veut verifier que Claude n'est pas stuck dans une boucle. Le compteur de tokens en bas de l'UI aide aussi a detecter un blocage (tokens figes depuis longtemps).

### Piste 3 — Pattern "skillifier" apres un audit reussi

Apres un audit complet qui a livre un rapport + des fixes valides, proposer au user :

> "L'audit est termine. Veux-tu que je transforme ce workflow specifique en skill reutilisable pour ton projet ? Je capture : les criteres d'evaluation que j'ai utilises + les tokens valides + les regles de brand identity + les patterns 'Needs work' que tu as acceptes. Ensuite `/audit-<projet>` permet de reauditer en une commande."

Inspire de la video : transformer systematiquement un one-shot valide en skill capitalise.

### Piste ecartee — Animation de contenu

La video parle aussi de HyperFrames (edition video via code) et Auphonic (audio processing). **Pas dans le scope de ce skill** (qui concerne les sites web). Eventuel skill `content-animation-pipeline` est en backlog, pas prioritaire (cf memoire `claude_design_decisions_2026-04-22.md`).

## Resources

- `resources/audit_checklist.md` — checklist detaillee par dimension
- `resources/feedback_templates.md` — templates "Needs work" par cas de figure
- `resources/selectors.md` — liste complete des selecteurs Chrome MCP Claude Design (avec fallbacks)
