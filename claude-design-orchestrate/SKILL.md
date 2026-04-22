---
name: claude-design-orchestrate
description: Orchestre de bout en bout la generation de directions de design sur Claude Design (claude.ai/design). Lance N conversations en parallele avec des prompts structures, monitor la generation, repond aux questions de clarification, extrait les outputs (HTML, screenshots, transcripts), applique `design:design-critique` sur chaque direction et produit une synthese de fusion. A utiliser pour refaire une page (ex `/agence`, `/pricing`, `/vote`) avec plusieurs directions en une seule commande. Complement de `claude-design-system-audit`.
---

# Claude Design Orchestrate

## Quand utiliser ce skill

- Tu veux generer 3 a 6 directions de design differentes pour une page ou un composant
- Tu ne veux PAS piloter a la main chaque conversation dans claude.ai/design
- Tu veux recuperer les outputs automatiquement (HTML, screenshots) pour implementation locale
- Tu veux une synthese des directions avec forces/faiblesses et recommandation

**Ne pas utiliser quand :** il s'agit d'une iteration fine sur UNE direction deja validee (pilote a la main dans l'UI), ou pour auditer/nettoyer le systeme (utiliser `claude-design-system-audit`).

## Prerequis

- Chrome MCP connecte (`mcp__Claude_in_Chrome__*`)
- Un projet Claude Design existant avec son URL
- Idealement le Design System dans ce projet est propre (sinon invoque d'abord `claude-design-system-audit`)
- Brand identity locale connue (`brand-identity` skill dans le projet ou `CLAUDE_DESIGN_PROJECT_INSTRUCTIONS.md`)

## Inputs attendus

1. **URL du projet Claude Design** (obligatoire)
2. **Page cible** : ex `/agence`, `/pricing`, `/vote` (obligatoire)
3. **Nombre de directions** : defaut 3, max 6
4. **Styles souhaites** (optionnel) : liste des templates a piocher dans `direction_templates.md`. Defaut = selection intelligente selon la page
5. **Skip audit** : si `--skip-audit`, ne pas invoquer `claude-design-system-audit` en pre-check
6. **Output dir** : defaut `design_outputs/<YYYY-MM-DD>/<page_name>/`

## Workflow — 7 etapes

### Etape 1 — Charger le contexte

- [ ] Lire `CLAUDE_DESIGN_PROJECT_INSTRUCTIONS.md` (docs du projet courant si present)
- [ ] Lire `CLAUDE_DESIGN_EXECUTION_PLAYBOOK.md` (docs du projet, pour pattern Setup A-F)
- [ ] Charger `brand-identity` skill (tokens, ton, regles absolues)
- [ ] Identifier les **regles absolues** (ex : zero em-dash, "je" pas "on", gradient bleu-violet)

### Etape 2 — Audit pre-check (sauf si --skip-audit)

- [ ] Invoker `claude-design-system-audit` en mode `audit` sur le projet
- [ ] Si score < 6/10 → afficher warning a l'utilisateur :
  > "Design System score < 6/10. Tu veux fix avant de generer (recommande) ou continuer quand meme ?"
- [ ] Attendre confirmation avant de continuer

### Etape 3 — Selectionner les N templates de direction

- [ ] Lire `resources/direction_templates.md`
- [ ] Si utilisateur a specifie des styles → prendre ceux-la
- [ ] Sinon selectionner N templates complementaires (pas 2 minimalistes, equilibrer : 1 sobre + 1 energique + 1 editorial par defaut)
- [ ] Pour chaque template, **substituer les placeholders** (`{page}`, `{tokens}`, `{business_context}`, `{regles_absolues}`)
- [ ] Optionnellement : passer chaque prompt final dans `design:ux-copy` pour polir le phrasing

### Etape 4 — Lancer les conversations en parallele

Pour chaque direction :
- [ ] `mcp__Claude_in_Chrome__tabs_context_mcp` pour verifier le tab du projet
- [ ] Si pas sur la page projet → `navigate` vers l'URL
- [ ] Click sur le bouton "+" pour creer une nouvelle conversation (voir `resources/selectors.md`)
- [ ] Remplir le textarea avec le prompt via pattern `nativeInputValueSetter`
- [ ] Click Send (utiliser `mcp__Claude_in_Chrome__find` avec query "Send button in main composer")
- [ ] Noter le tab_position / ref_id de la conversation dans un registre local

```javascript
// Pattern valide pour fill
const ta = document.querySelector('textarea[placeholder="Describe what you want to create..."]');
const setter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set;
setter.call(ta, PROMPT);
ta.dispatchEvent(new Event('input', { bubbles: true }));
```

### Etape 5 — Monitor + repondre aux questions de clarification

Pour chaque conversation active :
- [ ] Polling toutes les 60s : `javascript_tool` qui verifie :
  - Est-ce en generation ? (presence de "Stop generating")
  - Est-ce termine ? (dernier message assistant conclu)
  - Une question de clarification a ete posee ? (detecter un bloc de questions numerotees ou un choix)
- [ ] Si question de clarification → consulter `resources/question_responses.md` pour trouver la reponse adequate. Envoyer via textarea + Send
- [ ] Si generation > 15 min sans progresser → flagger comme stuck

### Etape 6 — Extraction des outputs (3 voies complementaires)

**Voie A — Export ZIP complet via API** (recommande, fiable) :

Le projet Claude Design expose `/v1/design/projects/<ID>/download` qui retourne un ZIP de tous les fichiers. Meme endpoint que `claude-design-system-audit` etape 7. A privilegier pour recuperer HTML + JSX reellement generes sur disque :

```javascript
fetch('/v1/design/projects/<PROJECT_ID>/download', { credentials: 'include' })
  .then(r => r.arrayBuffer())
  .then(buf => {
    const bytes = new Uint8Array(buf);
    const blob = new Blob([bytes], { type: 'application/zip' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url;
    a.download = 'claude-design-project-<ID>.zip';
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
    return bytes.length;
  })
```

Puis `mv` depuis `Downloads/` vers `design_outputs/<date>/<page>/` et `unzip`. Renommer les fichiers par direction si besoin.

**Voie B — Lister + fetcher fichier par fichier** (si on ne veut qu'une selection) :

```javascript
fetch('/v1/design/projects/<PROJECT_ID>/files', { credentials: 'include' }).then(r => r.json())
```

Filtrer par pattern (ex : tous les `.jsx` de la direction courante), puis pour chaque fichier utilise le ZIP complet pour en extraire uniquement ceux qui matchent.

**Voie C — Scraping classique du transcript + screenshots** (fallback, voir `resources/extraction_patterns.md`) :
- [ ] **Screenshot** : desktop (1440x900) + mobile (375x812) du canvas → `<direction>_desktop.png`, `<direction>_mobile.png`
- [ ] **Transcript assistant** : dernier message (copier le texte via `document.body.innerText`) → `<direction>_transcript.md`
- [ ] **Fichiers mentionnes** : chaque `.html` / `.jsx` / `.tsx` mentionne dans le transcript → fallback uniquement si voies A/B indisponibles

### Etape 7 — Synthese et livrables

- [ ] Pour chaque direction, appliquer `design:design-critique` :
  - Forces (3 points)
  - Faiblesses (3 points)
  - Verdict : RETENIR / REWORK / DROP
- [ ] Produire un **brief de fusion** : Markdown qui extrait les meilleurs elements de chaque direction (ex : "Hero de direction 2 + Pricing de direction 3 + Footer de direction 1")
- [ ] Generer un **index HTML** local qui affiche les N directions cote a cote avec leurs screenshots et verdicts
- [ ] Optionnel (si demande) : lancer une 7eme conversation "Fusion" dans Claude Design avec le brief de merge pour produire la direction finale unifiee
- [ ] Livrer a l'utilisateur :
  - Path vers le dossier `design_outputs/<date>/<page>/`
  - Resume court : "3 directions generees, recommandation = Direction 2 (score 8.5/10)"
  - Lien vers l'index HTML pour review rapide
  - Brief de merge pret pour l'implementation React

## Regles de garde

- **Jamais** de generation sur un projet Claude Design autre que celui specifie par l'utilisateur
- **Jamais** de suppression de conversations (ni par le skill, ni en clean-up) sans confirmation explicite
- **Zero em-dash** dans les prompts generes
- **Respecter le ton** defini (si `brand-identity` dit "je" → les prompts demandent "je" dans le copy)
- **Rate limit friendly** : ne pas lancer plus de 3 conversations a la fois pour eviter d'epuiser les quotas de claude.ai. Si N>3, batch par 3
- **Ne jamais commit les outputs** dans git automatiquement (certains peuvent contenir du contenu sensible)

## Integration avec skills voisins

- **Avant** : `claude-design-system-audit` (recommande)
- **Apres** : `design:design-handoff` pour formaliser le handoff vers Claude Code, puis implementation en React/Tailwind/shadcn via `frontend-design` plugin ou `ui-ux-pro-max`
- **Brique** : `design:design-critique` pour chaque direction, `design:ux-copy` pour polir les prompts, `marketing:brand-review` pour verifier la coherence de marque

## Exemples d'invocation

### Cas 1 — Page /agence, 3 directions par defaut

```
/claude-design-orchestrate
  url: https://claude.ai/design/p/9171a33b-6bba-42ef-a95b-e803ed52965c
  page: /agence
```

### Cas 2 — Page /pricing, 5 directions avec styles imposes

```
/claude-design-orchestrate
  url: ...
  page: /pricing
  count: 5
  styles: [stripe-minimal, linear-energetic, editorial-warm, brutalist, cro-focused]
```

### Cas 3 — Iteration rapide, skip audit

```
/claude-design-orchestrate
  url: ...
  page: /vote
  count: 3
  --skip-audit
```

## Etape 8 — Routine d'orchestration programmee ✅ DEPLOYEE

**But** : relancer 3 directions /agence chaque mois pour test-and-learn sur l'evolution du site Antigravity.

#### Tache programmee en place (creee 2026-04-22)

| Champ | Valeur |
|-------|--------|
| **taskId** | `claude-design-orchestrate-mensuel` |
| **Fichier** | `C:\Users\Administrateur\.claude\scheduled-tasks\claude-design-orchestrate-mensuel\SKILL.md` |
| **Cron** | `0 9 1 * *` (1er du mois, 9h local) |
| **notifyOnCompletion** | true |
| **Mode** | local (Chrome MCP requis) |
| **Prochaine execution** | 1er du mois suivant |

#### Ce que fait la tache a chaque run

1. Invoke `/claude-design-orchestrate` avec URL projet + page `/agence` + count 3 + `--skip-audit`
2. Skill selectionne 3 templates complementaires + lance 3 conversations dans claude.ai/design
3. Monitoring + reponses clarifications automatiques
4. Extraction Voie A (ZIP API) des outputs
5. Critique via `design:design-critique` sur chaque direction
6. Brief de fusion + index HTML side-by-side
7. Push dans Notion page 34901e69443c81918ff3c4608963a157 section "Cycles mensuels test-and-learn"

#### Comment la re-creer si elle disparait

```
mcp__scheduled-tasks__create_scheduled_task({
  taskId: "claude-design-orchestrate-mensuel",
  cronExpression: "0 9 1 * *",
  notifyOnCompletion: true,
  description: "[CLAUDE DESIGN] Orchestrate mensuel — 3 directions /agence test-and-learn",
  prompt: <contenu de Etape 6 + cycle test-and-learn>
})
```

#### Prerequis avant chaque run

- Export hebdo (task `claude-design-export-hebdo`) a reussi au moins une fois dans la semaine
- Quota claude.ai disponible (max 3 conversations paralleles)
- Si quota atteint → task se reporte au cycle suivant automatiquement

## Etape 9 — Decisions produit Antigravity (ancrage 2026-04-22)

Lors des cycles de generation `/agence`, ces decisions produit sont **figees** et doivent guider le skill pour eviter de regenerer un truc que Florent a deja rejete.

### Directions gardees comme reference

| Direction | Style | Decision | Archivage |
|-----------|-------|----------|-----------|
| **V1 Technical clarity** | epure, eclaire, pro, typo display, espace blanc, gradient mesh subtil | GARDEE | `Vente et Marketing - ALL Compagnies/hub/references-design/V1-technical-clarity-KEEP.html` |
| **V4 Warm and human** | serif Fraunces, creme/terracotta, illustrations douces, cards arrondies, style no-code academy | GARDEE | `Vente et Marketing - ALL Compagnies/hub/references-design/V4-warm-human-KEEP.html` |

### Directions rejetees

| Direction | Style | Raison du rejet |
|-----------|-------|-----------------|
| **V2 Ambitious energy** | fond quasi-noir, gradients satures violet/rose/ambre, cards sombres | "Design pas ouf", Florent prefere le design original |
| **V3 Confident minimalism** | noir et blanc pur, system stack, regles 1px | "Headline naze", "V3 elle est bien nulle" |

### Regle absolue issue de ces cycles

**PARTIR DU SITE ORIGINAL, JAMAIS FROM SCRATCH.**

Les directions generees par Claude Design sont des **sources d'inspiration** (patterns visuels precis a piquer de V1 et V4), pas des remplacements du site existant. Toute iteration design doit :

- Partir de `0- Marketplace/1- Marketplace FrontEnd/Marketplace - Antigravity - BLAST/agence-ia/SANDBOX-v4-hero-copy.html` (site live sur antigravity-agence.vercel.app)
- Conserver copy, CTAs Cal.com, branding existants
- Ajouter des patterns precis piqués de V1 (espace blanc, typo display, gradient subtil) ou V4 (serif, terracotta, cards arrondies)
- NE JAMAIS creer un nouveau fichier HTML qui ignore le copy existant

Citation Florent 2026-04-22 : "je prefere le design original tant qu'a faire. C'est des completes nouvelles iterations, ca n'a aucun sens par rapport a ce que j'ai fait. Ce n'est pas mon site web."

### Fichier memoire de reference

Source de verite complete des decisions + workflow 2 phases (copywriting puis design iteration) :

`C:\Users\Administrateur\.claude\projects\C--Users-Administrateur-PROJECTS-Vente-et-Marketing---ALL-Compagnies\memory\claude_design_decisions_2026-04-22.md`

## Etape 10 — Pistes d'amelioration issues de la video Jack Roberts (2026-04-21)

Video source : https://www.youtube.com/watch?v=34VoezbEvLw ("Claude just changed Content Creation Forever"). Scope different (content creation, pas website design), mais 4 patterns applicables a ce skill :

### Piste 1 — Skillifier une direction validee

Apres qu'une direction soit retenue en Etape 7 synthese, proposer au user :

> "Direction X est validee. Veux-tu que je la transforme en skill reutilisable ? Je capture : le template de prompt utilise + les reponses aux clarifications + les patterns visuels specifiques. Ensuite `/agence-direction-X-generator` permet de reprompter une direction equivalente en une commande."

Inspire du pattern Jack Roberts : transformer systematiquement un one-shot valide en skill pour replicabilite.

### Piste 2 — Economie de tokens Opus 4.7 / Sonnet 4.6

Garde-fou : Opus 4.7 pour la **structure initiale** des directions (generation premiere passe). Sonnet 4.6 suffit pour les **iterations ulterieures** sur une direction deja structuree (99 % des edits selon Jack Roberts).

Si `--skip-audit` + iteration sur un DS deja valide → encourager Sonnet 4.6.

### Piste 3 — Tip `/b` pour monitoring non-bloquant

Quand une conversation Claude Design est longue a generer (Etape 5 monitor), on peut utiliser le raccourci `/b` dans le chat Claude desktop pour poser une question ("is it progressing?", "where are we?") sans interrompre le travail. Utile pour detecter un blocage silencieux sans interferer.

### Piste 4 — Export DS → Claude Code (documente dans skill voisin)

Quand Claude Design rate limit hit, la procedure de bascule vers Claude Code est documentee dans `claude-design-system-audit` (Etape 9). Ce skill-ci ne duplique pas mais pointe vers le skill audit.

## Resources

- `resources/direction_templates.md` — 6 prompts pre-ecrits (a substituer)
- `resources/question_responses.md` — reponses calibrees aux questions de clarification
- `resources/selectors.md` — selecteurs Chrome MCP Claude Design
- `resources/extraction_patterns.md` — JS snippets pour extraire HTML / screenshots / transcripts + endpoint ZIP `/v1/design/projects/<id>/download`
