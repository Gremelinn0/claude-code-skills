---
name: wrapup-migration
description: Wrap-up de session POUR SWITCH DE COMPTE — sync Plan vivant des features touchees + handoff fichier + push Notion (1 ligne index par session). Trigger sur "/wrapup-migration", "switch de compte", "je change de compte", "migration de compte".
---

# Session Wrap-Up — Migration / Switch de compte (version 2026-04-25 simplifiee)

Skill a lancer dans **chaque session Claude Code ouverte** juste avant de changer de compte. Version courte depuis 2026-04-25 : repose sur le systeme "Plan vivant" (CLAUDE.md §3).

**Difference avec `/wrapup`** :
- `/wrapup` : wrap-up normal, handoff optionnel, push NotebookLM
- `/wrapup-migration` : sync Plan vivant + handoff **FORCE** + push Notion **OBLIGATOIRE** (1 ligne index, pas un dump)

**Pourquoi simplifie** : avec le Plan vivant a jour dans chaque feature doc, plus besoin de dumper le contexte session dans Notion. Le handoff fichier garde le detail. Notion devient un index simple (1 ligne par session vers GitHub). Tokens divises par ~10 vs ancienne version.

---

## Page Notion cible (FIXE — ne jamais changer)

- **URL** : `https://www.notion.so/prospectpartner/migration-34b01e69443c805bb045d1332cce75ea`
- **Page ID** : `34b01e69-443c-805b-b045-d1332cce75ea`

---

## Step 1 : Plan vivant — ajouter/maj l'entree de la session courante (OBLIGATOIRE — contrat principal du switch)

**Pour chaque feature touchee dans la session**, ajouter ou mettre a jour l'entree `[slug]` correspondante dans `## 📌 Plan vivant` du feature doc.

C'est le **contrat principal** du switch de compte. Sans entree Plan vivant a jour, le pickup de l'autre compte n'a rien de fiable a lire.

**Format multi-session (CLAUDE.md §3 "Plan vivant a jour en continu") :**

```markdown
## 📌 Plan vivant

### 🔧 En cours
**[slug-explicite]** — <resume 1 ligne>
- Statut : ...
- Prochain pas : ...
- Bloqueurs : ...
- Derniere session : YYYY-MM-DD HH:MM — commit `<hash>` — [handoff](...)

### ⏸️ En pause
(meme format + raison de la pause)

### ✅ Recemment livre
(meme format + date de livraison)
```

**Procedure :**

1. **Identifier le slug** de la session courante (kebab-case explicite, descriptif, stable). Exemples : `bp034-redispatch`, `uia-name-migration`, `ag-multi-window-fix`. PAS `session-25`, PAS `wip-1`, PAS la date.
   - Si la session a ete demarree avec un slug deja existant dans le Plan vivant → reutiliser (MAJ l'entree)
   - Si nouveau chantier → nouveau slug
   - Si tu ne sais pas → demander explicitement a Florent : "Quel slug pour cette session ? (suggestion : `<X>`)"

2. **Determiner la section cible** selon l'etat :
   - **🔧 En cours** : prochain pas dans les 7 jours, encore actif
   - **⏸️ En pause** : mis de cote (manque info, attend feedback, deprio temporaire). Ajouter "Raison : ..."
   - **✅ Recemment livre** : termine, plus de prochain pas. Ajouter "Livre : YYYY-MM-DD"

3. **Ajouter ou mettre a jour l'entree** `[slug]` dans la bonne section :
   - Si entree absente → ajouter
   - Si entree existante → mettre a jour (statut, prochain pas, bloqueurs, derniere session)
   - Si transition de section (ex: En cours → Recemment livre) → deplacer l'entree

4. **Si feature doc n'a pas de Plan vivant** → l'ajouter (stub minimal TL;DR + Plan vivant avec juste l'entree de cette session).

**Si tu skip cette etape** : le `/migration-pickup` cote destination ne saura pas quelle session reprendre → echec du switch.

---

## Step 2 : Reutiliser le slug + feature de Step 1

3 infos deja determinees en Step 1 :

- **Slug session** = identite stable de cette session (ex: `bp034-redispatch`)
- **Feature concernee** = feature doc principal touche (ex: `auto-permission`)
- **Prochaine action** = copiee de l'entree Plan vivant § "Prochain pas"

---

## Step 3 : Creer le handoff fichier (OBLIGATOIRE — format court)

**Chemin** : `memory/handoffs/YYYY-MM-DD-HHhMM-<slug>.md`

**Contenu** (court, pointe vers le Plan vivant pour le detail) :

```markdown
# Session Handoff — YYYY-MM-DD HH:MM — <slug>

## Feature concernee
[memory/features/<feature>.md](../features/<feature>.md) → voir § 📌 Plan vivant entree `[<slug>]`

## Ce qui a ete fait dans cette session
<3-5 bullets max, actions concretes, commits cites>

## PROCHAINE ACTION IMMEDIATE
<1 ligne — copiee de l'entree Plan vivant `[<slug>]` § "Prochain pas">

## WIP (travail en cours interrompu)
<Si arret au milieu : fichier modifie, ou on en est, ce qui restait>
<Si rien en cours : "RAS — session proprement terminee, voir Plan vivant entree [<slug>]">

## Bloqueurs actifs
<Copies de l'entree Plan vivant `[<slug>]` § "Bloqueurs", ou "aucun">

## Comment reprendre (autre compte / nouvelle session)
1. `git fetch && git pull --rebase origin dev`
2. Lire `memory/features/<feature>.md` § 📌 Plan vivant (entree `[<slug>]` ~10 lignes)
3. Executer "PROCHAINE ACTION IMMEDIATE"
```

**Puis MAJ 2 pointeurs** :
1. `memory/session-handoff.md` — copie + header "Dernier handoff"
2. `memory/handoffs/INDEX.md` — ligne EN HAUT (anti-chrono) : `- [YYYY-MM-DD HH:MM — slug](YYYY-MM-DD-HHhMM-slug.md) — 1 ligne resume`

---

## Step 4 : MAJ index local migrations (1 fichier par jour)

**Fichier** : `memory/migrations/YYYY-MM-DD.md` (cree si absent avec header).

**Inserer EN HAUT** (juste apres `---` du header, ordre anti-chrono) :

```markdown
## HHhMM — <slug>

- **Feature** : [memory/features/<feature>.md](../features/<feature>.md) → § 📌 Plan vivant entree `[<slug>]`
- **Handoff** : [memory/handoffs/YYYY-MM-DD-HHhMM-<slug>.md](../handoffs/YYYY-MM-DD-HHhMM-<slug>.md)
- **Prochaine action** : <1 ligne, copiee de l'entree Plan vivant>
- **🔍 Mots-cles** : <5-10 termes courts separes par virgules>
```

**Note** : pas de description longue (le Plan vivant la contient deja). Pas de redondance avec le handoff.

---

## Step 5 : Commit + push (handoff + index local)

```bash
git add memory/handoffs/ memory/session-handoff.md memory/migrations/ memory/features/ memory/roadmap/roadmap.md
git commit -m "chore(wrapup-migration): handoff session YYYY-MM-DD HHhMM <slug>"
git push origin HEAD:dev
```

Si push KO (non-fast-forward) → `git fetch origin && git rebase origin/dev` puis retry.

**Recuperer le commit hash** apres push pour Step 6.

---

## Step 6 : Push Notion (1 ligne index, pas un dump)

**Architecture Notion en 3 niveaux** (inchangee depuis 2026-04-25) :
1. Page parent "migration" (FIXE)
2. Sous-page par jour `Migration YYYY-MM-DD`
3. Sous-sous-page par session `HHhMM — <slug>`

**Procedure** :

1. **Chercher la sous-page du jour** : `mcp__notion__API-get-block-children` sur la page parent → filtrer `child_page` titre `Migration YYYY-MM-DD`.

2. **Si absente** → la creer (`mcp__notion__API-post-page`, parent = page migration, title = `Migration YYYY-MM-DD`, intro paragraph minimal).

3. **Anti-doublon** : verifier qu'aucune sous-sous-page `HHhMM — <slug>` n'existe deja dans la sous-page du jour.

4. **Creer la sous-sous-page** (`mcp__notion__API-post-page`) avec UNIQUEMENT 4 paragraphs (plus de dump !) :
   - `📌 Feature : <feature>` (slug session : `<slug>`) → lien vers le feature doc + Plan vivant (`https://github.com/.../memory/features/<feature>.md#-plan-vivant`)
   - `🔗 Handoff : https://github.com/.../memory/handoffs/YYYY-MM-DD-HHhMM-<slug>.md` (lien GitHub raw)
   - `🎯 Prochaine action : <1 ligne, copiee de l'entree Plan vivant [<slug>]>`
   - `🔍 Mots-cles : <liste virgules>`

5. **Repositionner en haut** (ordre anti-chrono) — meme procedure qu'avant (`API-move-page` ou TOC fallback).

**Si Notion KO** → continuer le skill, fichiers locaux + git suffisent. Signaler "⚠️ Notion KO, retry manuel".

---

## Step 7 : Confirm (6 lignes max)

Dire a Florent :

```
✅ Entree Plan vivant `[<slug>]` ajoutee/maj dans memory/features/<feature>.md (section <En cours/En pause/Livre>)
✅ Handoff cree : memory/handoffs/YYYY-MM-DD-HHhMM-<slug>.md
✅ Push Git : <commit hash> sur origin/dev
✅ Notion index : <url sous-sous-page>
🎯 Prochaine action : <1 ligne>
🔁 Reprise compte 2 : "continue <feature> [<slug>]" OU `/migration-pickup <feature> <slug>`
```

Pas de blabla, pas de recap session.

---

## Comment relancer la session depuis le nouveau compte

1. Ouvrir Claude Code dans le bon repo
2. Soit dire "je veux continuer <feature> `[<slug>]`" → hook UserPromptSubmit charge feature + Plan vivant + cible la bonne entree
3. Soit dire "je veux continuer <feature>" → hook charge → si plusieurs sessions En cours → Claude liste les slugs et demande
4. Soit `/migration-pickup <feature> <slug>` → version explicite avec git pull
5. Executer "Prochaine action" de l'entree Plan vivant `[<slug>]`

**Plus besoin** d'ouvrir Notion pour reprendre — Notion ne sert qu'a Florent pour visualiser ce qui est en cours, le contenu vit dans le repo git + Plan vivant.

---

## Error handling

- **Plan vivant absent dans le feature doc touche** → l'ajouter MAINTENANT (stub minimal TL;DR + Plan vivant) avant de continuer. Sinon le pickup ne pourra pas reprendre.
- **Notion MCP KO** → skill continue, push Notion skip, confirm affiche "⚠️ Notion KO" + URL pour retry manuel
- **Git push KO** (non-fast-forward) → rebase + retry, puis continuer
- **Conflit de merge** pendant rebase → stop le skill, demander a Florent de resoudre manuellement avant de relancer

---

## Prerequisites

- `mcp__notion__API-post-page` + `API-get-block-children` disponibles (Notion MCP connecte)
- Repo git propre ou rebase-able
- Le feature doc concerne contient deja `## 📌 Plan vivant` (ou stub a creer en Step 1)

---

## Rationale

Refondu 2026-04-25 sur demande Florent — la version precedente dumpait le contexte session entier dans Notion, ce qui bouffait les tokens au pickup et creait un systeme parallele aux feature docs. Avec le Plan vivant integre aux feature docs (CLAUDE.md §3), Notion devient un simple index navigable et le contenu vit dans le repo git.

**Affinement multi-session 2026-04-25 (2eme passe)** : Florent a souleve qu'une session != une fonctionnalite — on peut avoir N sessions paralleles sur la meme feature (ex: auto-perm avec `bp034-redispatch` + `uia-name-migration` + `ag-edge-case`). Solution : Plan vivant gere N entrees `[slug]` par feature, sections En cours / En pause / Recemment livre. `/wrapup-migration` ajoute ou maj une entree `[slug]` (au lieu de remplacer le Plan vivant entier).

Quote Florent (2026-04-25) : "Une session c'est pas meme niveau qu'une fonctionnalite. Chaque session, chaque plan pour moi, ils appartiennent a une fonctionnalite. On peut en avoir plusieurs par fonctionnalite, sans que ca pose probleme. On les nomme bien, on leur donne des noms explicites pour bien les retrouver."
