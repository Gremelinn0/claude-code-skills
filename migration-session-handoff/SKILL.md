---
name: migration-session-handoff
description: Handoff session pour switch de compte Claude — push Plan vivant features touchées. Triggers "/migration-session-handoff", "switch de compte", "change de compte", "migration de compte". Alias rétro-compat "/wrapup-migration".
---

# Session Wrap-Up — Migration / Switch de compte (version 2026-05-01 v2 — sans Notion)

Skill à lancer juste avant de changer de compte Claude. Version 2026-05-01 v2 : **plus de fichier handoff séparé NI de push Notion**. Tout vit dans le Plan vivant feature, et `git push` suffit pour qu'un autre compte reprenne.

**Différence avec `/wrapup`** :
- `/wrapup` : wrap-up normal, summary NotebookLM
- `/wrapup-migration` : `/wrapup` + `git push` OBLIGATOIRE

**Pourquoi unifié sans Notion** :
- Florent verbatim 2026-05-01 *"ca sert a rien de créer des handoff si on a deja dans plans vivants"* — handoff fichier séparé virés.
- Florent verbatim 2026-05-01 *"stop pas de notion oula"* — push Notion viré (le repo + Plan vivant suffisent multi-comptes).

Le Plan vivant feature contient déjà statut + prochain pas + bloqueurs + commits + last_account. Le hook `tools/plan_vivant_update_hook.py` met à jour `last_session` / `last_account` / `commits[]` automatiquement à chaque commit.

---

## Step 1 — Plan vivant à jour (cf. `/wrapup` Step 2.5)

Pour chaque feature touchée dans la session, vérifier que les blocs `<!-- ticket: <slug> ... -->` reflètent l'état réel :

- `status` correct (`in-progress` → `closed` si fini)
- `priority` réévaluée si scope a changé
- Corps Markdown : prochain pas concret + bloqueurs

Le hook `plan_vivant_update_hook.py` aura déjà mis à jour `last_session` / `last_account` / `commits[]` au dernier commit.

Si nouveau ticket dans la session → ajouter le bloc complet dans `### 🔧 En cours`. Format dans `/wrapup` Step 2.5.

---

## Step 2 — Commit + push (OBLIGATOIRE)

```bash
git add memory/features/ memory/PLANS-INDEX.md memory/roadmap/roadmap.md
git commit -m "chore(wrapup-migration): switch compte YYYY-MM-DD HHhMM <slug-court>"
git push origin HEAD:dev
```

Si push KO (non-fast-forward) → `git fetch origin && git rebase origin/dev` puis retry.

---

## Step 3 — Confirm (4 lignes max)

```
✅ Plan vivant ticket [<slug>] à jour dans memory/features/<feature>.md (last_account: <account>, commits: [<hashes>])
✅ Push Git : <commit hash> sur origin/dev
✅ PLANS-INDEX régénéré
🎯 Reprise compte 2 : `/migration-pickup <feature> <slug>` ou "continue <feature>"
```

Pas de blabla, pas de récap session. **PAS DE PUSH NOTION** (Florent verbatim 2026-05-01 *"stop pas de notion oula"*).

---

## Comment relancer la session depuis le nouveau compte

1. Ouvrir Claude Code dans le bon repo
2. `git pull --rebase origin dev`
3. `/migration-pickup <feature> <slug>` → annonce 6 lignes du prochain pas
4. OU dire "je veux continuer <feature> [<slug>]"
5. Exécuter le prochain pas du ticket

**Source unique** = repo git + Plan vivant feature. Pas de Notion, pas de handoff fichier séparé.

---

## Error handling

- **Plan vivant absent dans le feature doc touché** → l'ajouter MAINTENANT (stub minimal TL;DR + Plan vivant) avant de continuer.
- **Git push KO** (non-fast-forward) → rebase + retry
- **Conflit de merge** pendant rebase → stop le skill, demander à Florent

---

## Prerequisites

- Repo git propre ou rebase-able
- Le feature doc concerné contient `## 📌 Plan vivant` avec bloc ticket actif (ou créer en Step 1)

---

## Rationale

**v2 2026-05-01** — Notion viré (Florent verbatim *"stop pas de notion oula"* 2026-05-01 22h). Push Notion = bruit, le repo + Plan vivant suffisent multi-comptes.

**v1 unifiée 2026-05-01** — Handoff fichier séparé viré (Florent verbatim *"ca sert a rien de créer des handoff si on a deja dans plans vivants tu piges ? handoof c'est uniqument en gros c'est la meme chose"*). Avec `<!-- ticket: ... -->` enrichi (`status` / `last_session` / `last_account` / `commits[]`) + hook auto-MAJ + index agrégé `memory/PLANS-INDEX.md`, le Plan vivant suffit comme source unique session + multi-compte.

42 handoffs existants archivés dans `memory/_archive/handoffs-pre-2026-05-01/`. Tickets actifs migrés vers les Plan vivants des features correspondantes.

---

## Post-session check (skill auto-amélioration)

| Date | Skill change | À vérifier prochaine invocation |
|------|--------------|--------------------------------|
| 2026-05-01 22h25 | Step 3 Notion supprimé (verbatim Florent) | Confirm n'affiche plus `Notion index`, aucun `mcp__notion__*` call dans run skill |
