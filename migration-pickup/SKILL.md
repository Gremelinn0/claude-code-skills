---
name: migration-pickup
description: Compagnon ultra-light de /wrapup-migration. À lancer dans la session DESTINATION pour récupérer le contexte de la dernière session sur une feature donnée — git pull + lecture Plan vivant. Invoquer quand Florent dit "/migration-pickup", "récupère ma session", "rapatrie depuis migration".
---

# Migration Pickup — version 2026-04-25 (ultra-light)

**Quand l'utiliser** : tu reviens sur une session apres un switch de compte ou plusieurs jours de pause, et tu veux explicitement charger le contexte de la derniere session sur une feature donnee.

**Important** : avec le systeme "Plan vivant" (CLAUDE.md §3), 90% du temps c'est le hook UserPromptSubmit qui fait le job tout seul. Tu dis "je veux bosser sur auto-permission" → hook → `/auto-permission` → feature doc charge → Plan vivant lu. Ce skill est le **filet de securite explicite** quand tu veux forcer le chargement avant meme de parler du sujet.

**Difference avec `/wrapup-migration`** :
- `/wrapup-migration` : a lancer dans la session SOURCE avant switch — sync Plan vivant + push Notion
- `/migration-pickup` : a lancer dans la session DESTINATION apres switch — git pull + lecture Plan vivant

---

## Step 1 : Sync git

```bash
git fetch origin && git pull --rebase origin dev
```

Recuperer toute modif faite par la session source (handoff, Plan vivant a jour, commits).

**Si conflit** → stop, demander a Florent de resoudre manuellement.

---

## Step 2 : Identifier la feature cible

**Cas A — Feature donnee en argument** (`/migration-pickup auto-permission`) :
- Lire directement `memory/features/auto-permission.md`

**Cas B — Pas d'argument** :
- Lire `memory/handoffs/INDEX.md` → prendre la 1ere ligne (plus recente)
- Suivre le lien handoff → identifier la feature concernee (ligne `## Feature concernee`)
- Ouvrir le feature doc correspondant

---

## Step 3 : Lire TL;DR + Plan vivant

Du feature doc, extraire UNIQUEMENT :
- **§0 TL;DR** (~15 lignes) — etat V1, mecanismes, BPs critiques
- **## 📌 Plan vivant** (~20 lignes) — sujet courant, statut, prochain pas, bloqueurs, derniere session

**Ne pas lire le reste du feature doc** sauf si Florent demande explicitement. Plan vivant + TL;DR = ~40 lignes = contexte minimal pour reprendre.

---

## Step 4 : Annoncer en 5 lignes

```
✅ Feature : <X>
✅ Sujet courant : <copie du Plan vivant>
✅ Statut : <copie>
🎯 Prochain pas : <copie>
⛔ Bloqueurs : <copies ou "aucun">
```

Pas de blabla. Pas de recap exhaustif. Juste l'essentiel actionnable.

**Si Plan vivant absent** dans le feature doc cible → signaler a Florent : "⚠️ Pas de Plan vivant dans `<feature>.md` — le feature doc n'a pas ete migre vers le format 2026-04-25. Veux-tu que je l'initialise (stub TL;DR + Plan vivant) ou tu prefere lire le feature doc complet ?"

---

## Cas particuliers

### Aucun handoff recent (Cas B sans argument)
Si `memory/handoffs/INDEX.md` est vide ou la 1ere entree est > 7 jours → demander a Florent : "Aucune session recente. Sur quelle feature tu veux bosser ?"

### Feature inconnue (Cas A avec argument errone)
Si `memory/features/<arg>.md` n'existe pas → lister les features disponibles (`ls memory/features/*.md`) + demander correction.

### Plusieurs features touchees dans la derniere session
Si le handoff cite 2-3 features (cas rare, refacto transversal) → lire les 2-3 Plan vivant + annoncer en table 5-colonnes (1 ligne par feature).

---

## Notion (deprecate depuis 2026-04-25)

**Plus besoin de fetcher Notion** — la page Notion "migration" est devenue un simple index humain (1 ligne par session vers GitHub). Le contenu vit dans le repo git via le Plan vivant.

Si Florent demande explicitement de fetcher Notion (cas tres rare) :
- Utiliser `mcp__notion__API-get-block-children` sur la page migration
- Lister les sous-pages `Migration YYYY-MM-DD` recentes
- Pour chaque, lister les sous-sous-pages session

Mais 99% du temps, git pull + lecture Plan vivant suffit. Notion = backup visuel pour Florent humain, pas pour le pickup automatique.

---

## Error handling

- **git pull KO** (conflit) → stop, demander resolution manuelle
- **Feature doc sans Plan vivant** → proposer initialisation stub OU lecture complete
- **Argument feature inconnu** → lister features disponibles + demander correction

---

## Prerequisites

- Repo git propre ou rebase-able
- Au moins une feature doc dans `memory/features/` avec section `## 📌 Plan vivant` a jour (sinon proposer init)

---

## Rationale

Refondu 2026-04-25 sur demande Florent — la version precedente fetchait Notion + parsait des blocs + filtrait par mots-cles, ce qui bouffait les tokens et creait un systeme parallele aux feature docs.

Avec le Plan vivant integre aux feature docs (CLAUDE.md §3 "Plan vivant a jour en continu"), 90% du temps le hook UserPromptSubmit fait le job en amont. Ce skill garde sa place comme filet de securite explicite, mais devient ultra-court (2 etapes git pull + Read, ~30 lignes au lieu de 210).

Quote Florent (2026-04-25) : "Je dis je veux bosser sur tel sujet, automatiquement il sait tres bien ou regarder, tu vois."
