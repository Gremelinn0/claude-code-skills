---
name: migration-pickup
description: Migration session destination (récupère contexte session précédente après switch compte — git pull + lecture Plan vivant). Compagnon ultra-light de /migration-session-handoff. Invoquer quand Florent dit "/migration-pickup", "récupère ma session", "rapatrie depuis migration".
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

## Step 2 : Identifier feature + session cible

**3 cas selon les arguments :**

**Cas A — Feature + slug session** (`/migration-pickup auto-permission bp034-redispatch`) :
- Lire directement `memory/features/auto-permission.md`
- Cibler l'entree `[bp034-redispatch]` dans le Plan vivant

**Cas B — Feature seule** (`/migration-pickup auto-permission`) :
- Lire `memory/features/auto-permission.md`
- Lister TOUTES les entrees `[slug]` de la section "🔧 En cours"
- Demander a Florent : "Tu veux reprendre laquelle ? `[bp034-redispatch]` `[uia-name-migration]` ?"
- Si une seule entree En cours → la prendre directement sans demander

**Cas C — Pas d'argument** :
- Lire `memory/PLANS-INDEX.md` → prendre les tickets `🔧 in-progress` triés par `last_session` desc + filtrés `last_account != current_account`
- Si 1 seul → cible direct
- Si plusieurs → demander à Florent lequel reprendre
- Si vide → demander sur quelle feature il veut bosser

---

## Step 3 : Lire TL;DR + entree Plan vivant ciblee

Du feature doc, extraire UNIQUEMENT :
- **§0 TL;DR** (~15 lignes) — etat V1, mecanismes, BPs critiques
- **## 📌 Plan vivant entree `[<slug>]`** (~10 lignes) — statut, prochain pas, bloqueurs, derniere session

**Ne pas lire le reste du feature doc** sauf si Florent demande explicitement. TL;DR + entree Plan vivant = ~30 lignes = contexte minimal pour reprendre.

**Si Florent veut voir TOUTES les sessions actives sur la feature** → lire toute la section `## 📌 Plan vivant` (En cours + En pause + Recemment livre).

---

## Step 4 : Annoncer en 6 lignes

```
✅ Feature : <X>
✅ Session : `[<slug>]`
✅ Sujet : <resume entree Plan vivant>
✅ Statut : <copie>
🎯 Prochain pas : <copie>
⛔ Bloqueurs : <copies ou "aucun">
```

Pas de blabla. Pas de recap exhaustif. Juste l'essentiel actionnable.

**Si entree Plan vivant absente** (slug fourni mais pas dans le Plan vivant) → signaler : "⚠️ Slug `<slug>` introuvable dans `[<feature>].md`. Sessions actives disponibles : `<liste>`. Tu voulais l'une d'elles, ou je cherche dans 'En pause' / 'Recemment livre' ?"

**Si Plan vivant entierement absent** → "⚠️ Pas de Plan vivant dans `<feature>.md` — feature doc pas encore migre. Je l'initialise (stub TL;DR + Plan vivant) ?"

---

## Cas particuliers

### Aucun ticket recent (Cas C sans argument)
Si `memory/PLANS-INDEX.md` n'a aucun ticket `in-progress` ou tous sont > 7 jours → demander a Florent : "Aucune session recente. Sur quelle feature tu veux bosser ?"

### Feature inconnue (Cas A/B avec feature errone)
Si `memory/features/<arg>.md` n'existe pas → lister les features disponibles (`ls memory/features/*.md`) + demander correction.

### Plusieurs features touchees dans le dernier handoff
Si le handoff cite 2-3 features (cas rare, refacto transversal) → lire les 2-3 Plan vivant + annoncer en table 6-colonnes (1 ligne par couple feature × slug).

### Vue d'ensemble multi-features (commande implicite)
Si Florent demande "liste-moi mes sessions actives" / "qu'est-ce que j'ai en cours" / "vue d'ensemble" → grep tous les feature docs `memory/features/*.md` pour extraire les sections "🔧 En cours" → annoncer en table :
```
Feature        | Slug                | Prochain pas              | Derniere session
---------------+---------------------+---------------------------+-----------------
auto-perm      | bp034-redispatch    | Monitorer prod 2j        | 2026-04-25 abc
auto-perm      | uia-name-migration  | Implementer 3 modes      | 2026-04-24 def
chat-reader    | cd-uia-extraction   | Tester sur session live  | 2026-04-23 ghi
```
Pas de skill dedie — c'est juste un grep + extraction.

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

Avec le Plan vivant integre aux feature docs (CLAUDE.md §3 "Plan vivant a jour en continu"), 90% du temps le hook UserPromptSubmit fait le job en amont. Ce skill garde sa place comme filet de securite explicite.

**Affinement multi-session 2026-04-25 (2eme passe)** : Florent a souleve qu'on peut avoir N sessions actives par feature (ex: auto-perm avec `bp034-redispatch` + `uia-name-migration`). Solution : `/migration-pickup` accepte 2 arguments (`feature` + `slug`). Si slug fourni → cible direct. Si feature seule → liste les sessions En cours et demande. Cela rend le skill **vraiment utile** (vs ancienne version 90% redondante avec hook).

Quote Florent (2026-04-25) : "Une session c'est pas meme niveau qu'une fonctionnalite. On peut en avoir plusieurs par fonctionnalite. On les nomme bien, on leur donne des noms explicites pour bien les retrouver."
