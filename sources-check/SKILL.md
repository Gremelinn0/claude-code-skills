---
name: sources-check
description: Inventaire sources existantes (Notion/NotebookLM/dashboards/posts/mémoire) AVANT production contenu (post LinkedIn, carousel, lead magnet, newsletter, hub, dashboard). Triggers "fais le point sur", "rassemble sources", "pré-brief", "état des lieux", "ne pas partir de zéro".
---

# /sources-check — Inventaire automatique des sources AVANT rédaction

## Overview

**Principe : zero production de contenu sans inventaire sources préalable.**

Florent a beaucoup de matière déjà existante (Notion, NotebookLM, dossiers locaux, dashboards, posts antérieurs, mémoire agent). Écrire un post sans les consulter = repartir de zéro + contredire soi-même + perdre le travail accumulé.

Ce skill fait le scan, agrège, restitue un inventaire structuré, et **demande validation avant de rédiger**.

---

## Quand invoquer (red flags)

| Signal utilisateur | Skill s'active |
|---|---|
| "nouveau post sur X" | ✅ Immédiat |
| "fais-moi un carousel / lead magnet / newsletter sur X" | ✅ Immédiat |
| "fais le point sur X" / "état des lieux X" | ✅ Immédiat |
| "rassemble les sources X" / "page Notion centralisée" | ✅ Immédiat |
| "on a déjà travaillé sur X" | ✅ Immédiat |
| Brief dashboard synthèse topic | ✅ Immédiat |
| Affirmation "je connais le sujet" sans source citée | ✅ Immédiat (anti-hallucination) |

**Si tu hésites à invoquer → invoque. Coût d'un scan raté < coût d'un post hors-sujet ou qui ignore 15 pages Notion existantes.**

---

## Phase 1 — Extraction du topic

À l'invocation, reformuler le topic en 3-7 mots-clés scannables :
- Topic principal (ex: "Skills Claude Code")
- Synonymes / variantes (ex: "skills", "compétences Claude", "SKILL.md", "Anthropic skills", "superpowers")
- Angle si connu (ex: "lead magnet", "pédagogique", "check-up")

**Écrire les mots-clés à l'utilisateur en 1 ligne avant de scanner** :
```
Topic détecté : [topic]. Mots-clés scan : [liste]. Go.
```

Si topic ambigu → 1 question courte, sinon continuer.

---

## Phase 2 — Scan parallèle 5 axes (OBLIGATOIRE, pas de raccourci)

Lancer les 5 axes en parallèle dans un seul message (tool calls concurrents) :

### Axe 1 — Notion (source prioritaire de Florent)
- `notion-search` avec le topic principal (page_size: 15)
- `notion-search` avec les synonymes si < 5 résultats (1 query supplémentaire)
- Si un résultat est un "Hub de contenus" existant → `notion-fetch` dessus en priorité

### Axe 2 — NotebookLM (si applicable)
- Lire `~/.claude/projects/<project>/memory/notebooklm_urls.md` si existe
- Si un notebook est pertinent au topic → noter l'URL (pas de ask auto, coûteux — proposer à Florent)
- Règle CLAUDE.md : "NotebookLM-first pour gros corpus"

### Axe 3 — Dossier local du projet
- `Glob` sur `**/*.md`, `**/*.html`, `**/*<topic-keyword>*`
- `Grep` sur le topic dans le projet courant (content mode, head_limit 10)
- Cibler dossiers connus : `LinkedIn Content Agent/Sessions/`, `dashboards/`, `PLANS_CONSOLIDES/`, `hub/`

### Axe 4 — Dashboards et hubs déployés
- Lire `hub/index.html` (Master Hub projet)
- Si une page dashboard mentionne le topic → `WebFetch` sur l'URL Vercel
- Si Master Hub global (`antigravity-master-hub.vercel.app`) → le vérifier

### Axe 5 — Mémoire agent + backlog
- Relire `memory/MEMORY.md` — chercher des feedback/references/projects pertinents
- Lire `BACKLOG_ROADMAP.md` ou `roadmap.md` — chercher tâches/brouillons liés au topic
- **INDISPENSABLE** : un brouillon déjà écrit change tout (on enrichit, on ne recommence pas)

---

## Phase 3 — Restitution structurée (format obligatoire)

**Ne jamais passer à la rédaction sans cette restitution écrite dans le chat.**

Format exact :

```markdown
## 📚 Inventaire sources — [topic]

### ✅ Déjà existant chez toi (à exploiter)

**Notion — N pages trouvées :**
- [Titre page] — [URL courte ou ID] — *[1 ligne : ce qu'elle contient]*
- ...

**Dossier local — N fichiers :**
- [chemin/fichier] — *[1 ligne]*

**Dashboards :**
- [URL Vercel] — *[section / position]*

**NotebookLM :**
- [Nom notebook] — *[pertinent si...]* — URL : ...

**Mémoire + backlog :**
- [feedback/project name] — *[règle/contrainte à respecter]*
- [BACKLOG entry] — *[brouillon existant : OUI/NON, statut]*

### 🔄 Doublons / overlaps détectés
- [Page A] et [Page B] couvrent le même sous-angle → fusionner ?
- ...

### 📉 Trous identifiés
- Pas de source sur [angle X]
- Si besoin → skill `youtube-scraper` / `skool-scraper` / `notebooklm` à lancer

### 🎯 Recommandation
Il y a déjà **assez de matière pour : [post / carousel / lead magnet / pilier de page]**.
Hypothèse d'angle : [formulation 1 phrase].

**On valide cet inventaire avant que je rédige ?** (oui / ajuste / scan plus large)
```

**Règles de restitution :**
- **Langage simple** (règle CLAUDE.md) — pas de jargon sans traduction
- **Pas de conclusion prématurée** — on liste, on propose, Florent tranche
- **Limite : 40 lignes max** dans la restitution initiale — détails on-demand
- **Chiffres concrets** (N pages, N fichiers) — pas "plusieurs sources"

---

## Phase 4 — Sauvegarde systématique de l'inventaire

Dès que Florent valide l'inventaire, **créer immédiatement une page Notion "Sources — [topic]"** sous la database Mon contenu (collection `a8d9fa9e-3614-4f19-be94-7e3c4ad163c1`) OU sous le parent logique (Hub Claude, etc.).

Règle CLAUDE.md applicable : "Sortie d'information = Notion". Ne pas livrer juste dans le chat.

Cette page sert de hub durable pour le topic. Elle contient :
- La liste des sources (avec URLs cliquables)
- Les doublons / recommandations de ménage
- Les angles de contenu possibles
- Les liens vers les brouillons existants

---

## Interdits formels

- ❌ **Écrire un post avant d'avoir scanné les 5 axes** — c'est le bug qu'évite ce skill
- ❌ **Restituer en vrac sans structure** — l'inventaire doit être scannable
- ❌ **"Je connais le sujet, pas besoin de scanner"** — Florent a toujours plus de matière que ce dont tu te souviens
- ❌ **Ignorer un brouillon existant** — si BACKLOG mentionne un brouillon, on l'enrichit, on ne recrée pas à côté
- ❌ **Ne pas pousser l'inventaire dans Notion** — règle "sortie = Notion" s'applique
- ❌ **Scanner seulement Notion** — les 5 axes sont obligatoires, même si certains renvoient vide

---

## Fast-path (topic déjà scanné dans la session)

Si la même session a déjà scanné ce topic il y a < 30 min :
- Relire la restitution Phase 3 précédente
- Vérifier seulement les axes où du nouveau a été ajouté entre-temps
- Pas besoin de re-scanner tout

---

## Auto-amelioration

**Ce skill s'ameliore a chaque usage.** C'est une responsabilite, pas un bonus.

Apres chaque execution, avant de conclure :
1. **Friction detectee ?** (axe oublié, restitution pas claire, Florent a dû re-demander des sources) → corriger ce skill immediatement
2. **Source-type découvert** non couvert par les 5 axes (ex: Google Drive, Linear, canaux Slack) → ajouter un axe
3. **Approche validee ?** → l'ancrer comme pattern reference dans ce skill
4. **Gain applicable a d'autres skills ?** → propager vers `linkedin-post-creator` / `content-intel` (ils doivent appeler ce skill en prérequis)

**Ne jamais reporter une amelioration a "plus tard". L'appliquer maintenant ou la perdre.**

---

## Red Flags — STOP si tu te surprends à penser

| Pensée | Réalité |
|---|---|
| "Le topic est simple, scan inutile" | 5 axes en parallèle = 30s. Pas d'excuse. |
| "Florent a dit d'aller vite" | Vite ≠ repartir de zéro. L'inventaire fait gagner du temps. |
| "Je me souviens de 2-3 pages Notion" | Mémoire trompeuse. Scan officiel obligatoire. |
| "On scannera si besoin" | Le besoin est là dès la demande de contenu. |
| "J'ai déjà des idées d'angle" | Angle après inventaire, pas avant. |

**Si une de ces pensées apparaît → arrêter la rédaction et faire le scan.**
