---
name: skill-checkup
description: Checkup périodique skills perso Florent (globaux + projet courant). Regen hub Vercel d'abord, triage intelligent avec mémoire decisions déjà validées (pas re-poser). Triggers "/skill-checkup", "audit skills", "fais le point skills", "nettoyage skills".
---

# /skill-checkup — Audit intelligent skills perso

Skill global. Évite à Florent de re-trier les mêmes skills à chaque session. Mémorise décisions validées, présente uniquement les NOUVEAUTÉS et changements.

## Sommaire

- §1 Quand invoquer
- §2 État persistant (state.json)
- §3 Workflow 5 phases
- §4 Hub Master Vercel
- §5 Anti-patterns

## §1 Quand invoquer

- Florent dit "/skill-checkup", "audit skills", "fais le point sur mes skills", "nettoyage skills"
- Routine périodique (mensuelle recommandée — pas hebdo, drift trop lent)
- Après création/rename/cleanup massif skills (>5 modifs en 1 session)
- Avant `/wrapup` si session a touché ≥1 skill

## §2 État persistant

**Fichier** : `~/.claude/skills/skill-checkup/state.json`

**Structure** :
```json
{
  "last_checkup": "2026-05-02T14:30:00Z",
  "validated": {
    "<skill-name>": {
      "validated_at": "2026-05-02T...",
      "decision": "keep|store|delete|fusion-with-<other>|rework|rename-to-<new>",
      "scope": "global|speakapp",
      "lines_at_validation": 234,
      "commit_hash_at_validation": "abc1234",
      "comment": "optional"
    }
  },
  "ignored": ["<skill-name-to-skip>"]
}
```

**Règles MAJ state** :
- Décision `keep` → skill validé, ne PAS reposer la question prochaine session SAUF si SKILL.md modifié depuis (lines_at_validation ou commit_hash diff)
- Décision `store|delete|fusion-*|rename-*` → action exécutée, retirer de la liste active
- Décision `rework` → garder en "à revoir" jusqu'à modif détectée
- `ignored` → Florent dit explicitement "skip celui-ci toujours" (très rare)

## §3 Workflow 5 phases

### Phase 0 — Regen hub Vercel AVANT triage (NON-NÉGOCIABLE)

Toujours partir d'un hub à jour. Sinon Florent voit version stale.

1. Run `python "C:/Users/Administrateur/PROJECTS/dashboards/generate_skills_index.py"` → regen `skills-data.json`
2. Diff git pour voir si JSON a changé
3. Si changé → `cd "C:/Users/Administrateur/PROJECTS/dashboards" && npx vercel deploy --prod --yes`
4. Commit + push repo `dashboards/`
5. Récupérer URL prod (ex `https://antigravity-master-hub.vercel.app/skills-perso.html`)

⚠️ Si script ou page n'existent pas encore → invoquer skill `dashboards-hub-master` + créer via spawn task (cf. session 2026-05-02).

### Phase 1 — Load state + scan skills actuels

1. Read `~/.claude/skills/skill-checkup/state.json` (créer si absent : `{"validated": {}, "ignored": []}`)
2. Scan `~/.claude/skills/` → liste skills globaux
3. Détecter projet courant (cwd) → si SpeakApp, scan `PROJECTS/3- Wisper/speak-app-dev/.claude/skills/`. Si autre projet → scan `<projet>/.claude/skills/`. Si pas de projet → globaux only.
4. Pour chaque skill : récup `name`, `scope`, `lines`, `last_commit_hash`

### Phase 2 — Diff intelligent (filtre)

Catégoriser chaque skill :
- **NEW** : pas dans `state.validated`
- **MODIFIED** : dans `state.validated` MAIS `lines` ou `commit_hash` ≠ valeurs au moment de la validation
- **STABLE** : dans `state.validated`, identique → SKIP (ne pas re-présenter)
- **IGNORED** : dans `state.ignored` → SKIP

Compter chaque catégorie. Si NEW + MODIFIED == 0 → annoncer à Florent "Aucun changement depuis dernier checkup (`<date>`). Hub à jour : `<URL>`. Rien à trier." → STOP.

### Phase 3 — Présentation à Florent (concise)

Format :
```
Checkup skills — depuis <last_checkup>

📊 Bilan
- Globaux : X total (Y new, Z modified, W stable)
- Projet <nom> : X total (Y new, Z modified, W stable)
- Hub : <URL prod>

🆕 Nouveaux (à trier) :
1. <name> (global) — <description courte>
2. <name> (speakapp) — <description courte>

🔄 Modifiés depuis dernière validation :
1. <name> (global, +120 lignes depuis 2026-04-15) — <description>

Pour chaque : keep / store / delete / fusion-avec-X / rework / rename-to-Y / ignore-toujours ?
```

Florent répond batch ou ligne par ligne. Si batch ambigu → demander 1 phrase courte.

### Phase 4 — Exécution actions validées

Appliquer décisions Florent :
- `keep` → noter dans state.json, rien d'autre
- `store` → invoquer skill `/skill-store` (move vers `skills-store/` + MAJ INDEX)
- `delete` → archive `_archive/skills-archive/<date>/` AVANT rm (jamais delete sec)
- `fusion-avec-X` → invoquer skill `/rule-cleaner` Workflow C Phase 4 (fusion atomique)
- `rework` → laisser en place + commentaire dans state, prochain checkup re-pose
- `rename-to-Y` → `git mv` + MAJ refs grep + alias trigger
- `ignore-toujours` → push dans `state.ignored`

Commit atomique par batch d'actions (1 commit par catégorie d'action si volumineux).

### Phase 5 — MAJ state.json + push

1. MAJ `state.json` avec nouvelles validations + timestamps + hashes commit actuels
2. Si actions Phase 4 ont modifié skills → re-Phase 0 (regen hub + redeploy)
3. `git -C ~/.claude/skills add skill-checkup/state.json && git commit -m "chore(skill-checkup): state MAJ après checkup <date>" && git push`
4. Recap final 5 lignes max : decisions appliquées + URL hub à jour

## §4 Hub Master Vercel

- Path local : `C:/Users/Administrateur/PROJECTS/dashboards/`
- Page skills : `dashboards/skills-perso.html`
- JSON source : `dashboards/skills-data.json`
- Script regen : `dashboards/generate_skills_index.py`
- URL prod : `https://antigravity-master-hub.vercel.app/skills-perso.html`

Si page ou script absents → spawn task pour build (cf. session 2026-05-02 chip "Grille skills perso accordéon + actions").

Hub permet à Florent de pré-trier visuellement (checkbox + actions per-skill exportées en JSON) AVANT le checkup conversationnel. Si Florent a déjà exporté `actions-<ts>.json` depuis le hub → consommer en input Phase 3 (skip présentation, exécuter directement Phase 4).

## §5 Anti-patterns

- ❌ Sauter Phase 0 (présenter triage sur hub stale = Florent perd confiance)
- ❌ Re-présenter skills STABLE (raison d'être du state.json — économie cognitive Florent)
- ❌ DELETE sans archive `_archive/skills-archive/<date>/`
- ❌ Exécuter actions sans confirmation Florent (juste régénérer hub OK, mais move/delete/fusion = besoin go)
- ❌ Oublier MAJ state.json Phase 5 (= prochain checkup re-pose tout)
- ❌ Oublier re-deploy hub après actions Phase 4 (state divergent vs hub visible)
- ❌ Scanner skills d'autres projets que projet courant (Florent veut focus, pas overload)

## §6 Journal

- 2026-05-02 — Init skill global. Phase 0 NON-NÉGOCIABLE regen hub avant triage. State persistant `state.json` mémoire decisions. Coordination avec `/skill-store` + `/rule-cleaner` Workflow C.
