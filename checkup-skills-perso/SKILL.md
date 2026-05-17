---
name: checkup-skills-perso
description: Checkup pÃ©riodique skills + CLAUDE.md + skills-store dormant â€” 2 workflows (A = Monitoring Center Vercel triage visuel, B = chat topic-by-topic avec fusion preserve-content). Auto-discover dÃ©pÃ´ts, exÃ©cution via apply_changes.py OU script batch fusion (template _archive/skills-archive/<date>/_fusion_log.py). Triggers "/skill-checkup", "audit skills", "fais le point skills", "nettoyage skills", "ranger skills", "rÃ©organiser skills", "consolider skills", "fusionner skills", "mÃ©nage skills".
---

# /skill-checkup â€” Audit + rÃ©organisation skills + CLAUDE.md multi-dÃ©pÃ´t

Skill global. Workflow reproductible et partageable pour auditer tous les skills perso **ET** tous les CLAUDE.md de Florent (ou de quelqu'un d'autre) sur tous ses dÃ©pÃ´ts d'un coup. Page Vercel **Monitoring Center** (light theme) sert de support de tri visuel + Ã©dition inline CLAUDE.md, JSON exportÃ© sert de plan d'exÃ©cution unifiÃ© appliquÃ© via `apply_changes.py`.

## Sommaire

- Â§1 Quand invoquer
- Â§2 Architecture (3 fichiers + 1 page Vercel)
- Â§3 Workflow A â€” Monitoring Center Vercel (5 phases)
- Â§3bis Workflow B â€” Chat topic-by-topic (gravÃ© 2026-05-13)
- Â§4 Format JSON dÃ©cisions (input â†’ output)
- Â§5 Ã‰tat persistant (state.json)
- Â§6 Partage Ã  un autre utilisateur
- Â§7 Anti-patterns
- Â§8 Skills-store (workflow store) â€” fusionnÃ© depuis checkup-skills-store 2026-05-13

## Â§1 Quand invoquer

- Florent dit `/skill-checkup`, "audit skills", "fais le point sur mes skills", "nettoyage skills", "rÃ©organiser skills", "ranger skills"
- Routine pÃ©riodique (mensuelle recommandÃ©e â€” pas hebdo, drift trop lent)
- AprÃ¨s crÃ©ation/rename/cleanup massif skills (>5 modifs en 1 session)
- Avant `/wrapup` si session a touchÃ© â‰¥1 skill

## Â§2 Architecture

6 fichiers + 2 pages Vercel composent le systÃ¨me (4 nouveaux fichiers ajoutÃ©s 2026-05-07 pour Ã©tendre le pÃ©rimÃ¨tre aux CLAUDE.md).

| Fichier | RÃ´le |
|---------|------|
| `master-hub/generate_skills_index.py` | Auto-discover tous dÃ©pÃ´ts `*/.claude/skills/` sous `PROJECTS/` + global `~/.claude/skills/`. Produit `skills-data.json` enrichi (incl. `full_content`). |
| `master-hub/generate_claude_md_index.py` | **NEW 2026-05-07** â€” Scanne tous CLAUDE.md (~19, 16 dÃ©pÃ´ts) global + PROJECTS/ profondeur 1-4. Filtre worktrees + backups. Produit `claude-md-data.json` (incl. `full_content` + sections H1/H2/H3). |
| `master-hub/add_recommendations.py` | PrÃ©-remplit recommandations par skill (keep/rework/archive heuristique) dans le JSON. Optionnel. |
| `master-hub/apply_changes.py` | **NEW 2026-05-07** â€” Lit JSON exportÃ© Monitoring Center â†’ backup `_archive/monitoring-changes-<ts>/` â†’ applique writes CLAUDE.md + actions skills. Demande confirmation interactive (sauf `--yes`). |
| `master-hub/skills-data.json` | Source vÃ©ritÃ© skills. Structure : `{generated_at, repos:[{slug,path,count}], skills:[{name,dir_name,description,summary,full_content,scope,repo,repo_path,path,lines,last_commit_hash}]}` |
| `master-hub/claude-md-data.json` | **NEW** â€” Source vÃ©ritÃ© CLAUDE.md. Structure : `{generated_at, repos:[{slug,path,count}], files:[{repo,scope,path,size,lines,last_modified,full_content,sections:[{level,title,line}]}]}` |
| `master-hub/skills-triage.html` | Page Vercel **dark** â€” vue dense skills uniquement. Toggle multi-target + archive/rename/rework + export JSON skills. Ã‰tat localStorage. |
| `master-hub/monitoring-center.html` | **NEW 2026-05-07** â€” Page Vercel **light theme** unifiÃ©e. Sections par dÃ©pÃ´t avec sous-blocs `ðŸ“ CLAUDE.md` + `ðŸ›  Skills`. Modal CLAUDE.md = textarea Ã©ditable. Modal skill = lecture + actions. Export JSON unifiÃ© (`skills_decisions[]` + `claude_md_edits[]`). |

**Path local Master Hub** : `C:/Users/Utilisateur/PROJECTS/Vente et Marketing - ALL Compagnies/hub/master-hub/`

**URLs prod** :
- **Hub principal** (light) : `https://antigravity-master-hub.vercel.app/monitoring-center.html` â­ POINT D'ENTRÃ‰E
- Vue dense skills (dark) : `https://antigravity-master-hub.vercel.app/skills-triage.html`

## Â§3bis Workflow B â€” Chat topic-by-topic (gravÃ© 2026-05-13)

**Quand Florent dit "fais le mÃ©nage skills" en chat direct** (sans vouloir passer par le Monitoring Center Vercel), suivre ce workflow alternatif :

1. **Phase 0** identique workflow A (regen `skills-data.json` + `claude-md-data.json` + deploy hub â€” toujours partir d'un Ã©tat propre)
2. **Grouper les skills par SUJET** (pas par dÃ©pÃ´t). Sujets typiques SpeakApp : Tests / Health-monitoring / Checkup-audit / Scan-setup / Management / Docs-orchestration / Bug-debug / Dev-workflow / Features. **Topic > dÃ©pÃ´t** : Florent raisonne par "qu'est-ce qui sert Ã  quoi", pas par "oÃ¹ est rangÃ©".
3. **Pour chaque sujet** prÃ©senter UNE proposition consolidÃ©e :
   - Liste skills du sujet avec description 1 ligne
   - Proposer FUSION (prÃ©fÃ©rÃ©e) > STORE (rÃ©cupÃ©rable) > ARCHIVE
   - Cible explicite pour chaque fusion (`X â†’ fusionner dans Y` avec raison)
   - Bilan : "passe de N Ã  M skills"
4. **Florent rÃ©pond OUI/NON/MODIF par sujet** (pas par skill individuel â€” c'est trop fastidieux)
5. **ExÃ©cuter en cascade** via script Python batch (template : `_archive/skills-archive/<date>/_fusion_log.py`) :
   - Pour chaque fusion : lire source SKILL.md (skip frontmatter) â†’ append en section `## FusionnÃ© depuis <X> (YYYY-MM-DD)` dans target â†’ archive source
   - Pour chaque store : `mv skills/<X> skills-store/<X>` + MAJ INDEX.md
   - Pour chaque archive simple : `mv skills/<X> _archive/skills-archive/<date>/<X>/`
6. **Re-Phase 0** (regen + deploy) aprÃ¨s exÃ©cution
7. **Commit + push** atomique

### Heuristique destination (gravÃ©e 2026-05-14)

**Classification skill enfant vs user-facing** â€” dÃ©terminer oÃ¹ va un skill quand on l'archive :

1. **Skill enfant â†’ `_archive/skills-archive/<date>/`** (archive permanente, pas pollution liste user). CritÃ¨res dÃ©tection :
   - CitÃ© explicitement par un **hook Python** dans `tools/*_hook.py` ou `.claude/settings.json` (mais attention : un hook qui affiche un message texte type *"Invoque `/X`"* ne dÃ©pend PAS du chargement du skill â€” il exÃ©cute son script Python directement)
   - CitÃ© par un **autre skill SKILL.md** via Skill tool / dans son workflow
   - Description du skill dit explicitement *"skill OUTIL (pas feature autonome)"* ou *"appelÃ© par"*
   - Jamais invoquÃ© directement par user dans les transcripts historiques

2. **Skill user-facing peu utilisÃ© â†’ `skills-store/`** (dormant rÃ©cupÃ©rable). CritÃ¨res :
   - Audit mensuel / cron rare / outil ponctuel
   - User l'invoque parfois mais < 1Ã—/mois
   - Description orientÃ©e action user, pas flow technique

3. **Skill mort (deprecated / fusionnÃ© dont contenu dÃ©jÃ  prÃ©servÃ© ailleurs) â†’ archive permanente**.

**VÃ©rification hooks AVANT archive enfant** : grep `<skill-name>` dans `.claude/settings.json` + `tools/*hook*.py`. Si match = texte affichÃ© type *"suggÃ¨re `/X`"* â†’ safe (hook fait son boulot via script Python, le skill archivÃ© reste fonctionnellement disponible si re-listÃ©). Si match = Skill tool call programmatique â†’ casse, ne pas archiver.

**VÃ©rification skill-to-skill calls AVANT archive enfant** : grep `<skill-name>` dans tous les `.claude/skills/*/SKILL.md` actifs. Si un skill actif appelle l'enfant via Skill tool â†’ soit garder actif, soit MAJ le skill parent mÃªme commit pour pointer vers `_archive/`.

### RÃ¨gles d'or workflow B

- âš ï¸ **PrÃ©server le contenu utile** â€” Florent verbatim 2026-05-13 : *"il y a sÃ»rement des choses utiles. (...) sÃ»rement pas les archiver comme Ã§a"*. Fusion > archive simple. Le body source est append intÃ©gral dans target (jamais perdu).
- âš ï¸ **Attention aux vieux trucs obsolÃ¨tes** â€” Florent verbatim 2026-05-13 : *"il peut y avoir des choses un peu obsolÃ¨tes et Ã§a c'est compliquÃ©"*. Si fusion dÃ©tecte contenu datÃ©/contradictoire dans le source, le marquer `[CONTENU HISTORIQUE - Ã€ NETTOYER]` au lieu de l'append brut.
- **PrÃ©fÃ©rer fusion par cible Ã©vidente** (`mechanism-tester â†’ feature-validator` car mÃªme objectif "valider mÃ©canisme sur cible"). Si pas de cible Ã©vidente â†’ demander.
- **Store > archive** pour les skills "audit mensuel" / "audit ponctuel mais utile" / "cron rare". RÃ©cupÃ©rables sans perte.
- Workflow B utilisÃ© mÃªme session que workflow A est OK (Phase 0 commun, juste skip Phase 3 UI Vercel et exÃ©cuter directement).

### Cas inaugural gravÃ© 2026-05-13

Session SpeakApp : passÃ© de 55 Ã  33 skills actifs en 1 session :
- 7 skills archivÃ©s simples (define-feature, widget-demo, brand-identity, autoresearch, create-debug-pipeline, cd-scan, switch-session)
- 13 fusions exÃ©cutÃ©es (mechanism-tester, n4-log-pipelines, test-cc-*, test-mode-b, stt-health-check, vosk-*, check-notif-pipeline, dom-scanner, checkup-doc-routing, checkup-skills-store)
- 2 mises en store (checkup-memory-archi, audit-zero-intrusion)
- Script batch `_fusion_log.py` rÃ©utilisable comme template

## Â§3 Workflow A â€” Monitoring Center Vercel (5 phases)

### Phase 0 â€” Regen hub Vercel AVANT triage (NON-NÃ‰GOCIABLE)

Toujours partir d'un hub Ã  jour. Sinon Florent voit version stale. **2 scripts Ã  lancer maintenant** (skills + CLAUDE.md).

```bash
cd "C:/Users/Utilisateur/PROJECTS/Vente et Marketing - ALL Compagnies/hub/master-hub"
python generate_skills_index.py        # â†’ skills-data.json
python generate_claude_md_index.py     # â†’ claude-md-data.json (NEW 2026-05-07)
python add_recommendations.py          # â†’ enrichit skills-data.json (heuristiques)
```

Puis :

1. Diff git pour voir changements (skills-data.json + claude-md-data.json)
2. Si changÃ© â†’ `npx vercel deploy --prod --yes` puis **OBLIGATOIRE** `npx vercel alias set <new-deploy>.vercel.app antigravity-master-hub.vercel.app` (alias se dÃ©tache Ã  chaque deploy fresh, doit Ãªtre rÃ©assignÃ©)
3. VÃ©rifier curl `https://antigravity-master-hub.vercel.app/skills-data.json` ET `claude-md-data.json` retournent les nouveaux JSON
4. Commit + push repo `Vente et Marketing - ALL Compagnies` (`hub/master-hub/skills-data.json` + `claude-md-data.json`)
5. Annoncer URL : `https://antigravity-master-hub.vercel.app/monitoring-center.html` (Ctrl+Shift+R pour bypass cache)

**Si fichier ou page absent** : invoquer skill `dashboards-hub-master` + recrÃ©er (cf. session 2026-05-07).

### Phase 1 â€” Load state + scan skills actuels

1. Read `~/.claude/skills/skill-checkup/state.json` (crÃ©er si absent : `{"validated": {}, "ignored": []}`)
2. Le scan auto-discover (Phase 0 step 1) trouve tous les dÃ©pÃ´ts, pas de scan manuel Ã  refaire
3. Pour chaque skill du JSON : rÃ©cup `dir_name`, `repo`, `lines`, `last_commit_hash`

### Phase 2 â€” Diff intelligent (filtre)

CatÃ©goriser chaque skill :
- **NEW** : pas dans `state.validated`
- **MODIFIED** : dans `state.validated` MAIS `lines` ou `commit_hash` â‰  valeurs au moment de la validation
- **STABLE** : dans `state.validated`, identique â†’ SKIP (ne pas re-prÃ©senter)
- **IGNORED** : dans `state.ignored` â†’ SKIP

Compter chaque catÃ©gorie. Si NEW + MODIFIED == 0 â†’ annoncer Ã  Florent "Aucun changement depuis dernier checkup. Hub Ã  jour : <URL>. Rien Ã  trier." â†’ STOP.

### Phase 3 â€” Florent trie + Ã©dite sur Monitoring Center

Annonce Ã  Florent (caveman OFF, langage simple) :

```
Hub Ã  jour : https://antigravity-master-hub.vercel.app/monitoring-center.html

Bilan :
- X dÃ©pÃ´ts dÃ©tectÃ©s
- Y skills total (Z nouveaux depuis dernier checkup, W modifiÃ©s)
- N CLAUDE.md scannÃ©s
- Recos prÃ©-remplies : N keep / N rework / N archive

Comment utiliser le Monitoring Center (light theme) :
1. Ouvre l'URL (Ctrl+Shift+R pour rafraÃ®chir)
2. Sections collapsibles par dÃ©pÃ´t â€” chaque dÃ©pÃ´t a 2 sous-blocs :
   ðŸ“ CLAUDE.md  â†’ click ouvre modal avec textarea Ã©ditable + bouton "ðŸ’¾ Marquer modifiÃ©"
   ðŸ›  Skills    â†’ 1 bouton par dÃ©pÃ´t (multi-select), â˜… = dÃ©pÃ´t actuel, archive/rename/rework
3. Filtres : Tous / Avec changements / CLAUDE.md seul / Skills seuls
4. Export JSON unifiÃ© quand fini â†’ reviens en session avec le fichier
```

Florent fait son tri + Ã©dition Ã  son rythme (state localStorage persistÃ©). Quand fini, il exporte un JSON `monitoring-changes-<timestamp>.json` et le partage en session.

### Phase 4 â€” ExÃ©cution dÃ©cisions via apply_changes.py

Ã€ la rÃ©ception du JSON exportÃ© (`source: "monitoring-center"`) :

```bash
python "C:/Users/Utilisateur/PROJECTS/Vente et Marketing - ALL Compagnies/hub/master-hub/apply_changes.py" <fichier>.json
```

Le script gÃ¨re **tout** automatiquement :

1. **Backup** tous les CLAUDE.md cibles dans `master-hub/_archive/monitoring-changes-<ts>/claude-md/<repo>_CLAUDE.md`
2. **Preview** : liste les `claude_md_edits[]` (avec delta bytes) + `skills_decisions[]` (avec action dÃ©duite)
3. **Confirmation interactive** : `[y/N]` (sauf flag `--yes`)
4. **ExÃ©cution** :
   - `claude_md_edits[]` â†’ write nouveau contenu en utf-8
   - `action: archive` â†’ move skill dir â†’ `<repo>/.claude/skills/_archive/skills-archive/<ts>/<dir>/`
   - `action: move` â†’ move skill dir â†’ `<target_repo>/.claude/skills/<dir>/`
   - `action: duplicate` â†’ copytree skill dir vers chaque target supplÃ©mentaire (garde courant)
   - `action: flag` (rename/rework only) â†’ log seul, pas d'action filesystem
5. **Recap final** : count Ã©crits + skippÃ©s + path backup

**Si rename** â†’ demander Ã  Florent le nouveau nom (Phase 4bis), refactor manuellement.
**Si rework** â†’ ouvrir SKILL.md + inviter Florent Ã  Ã©diter description.

AprÃ¨s `apply_changes.py` : commit atomique par dÃ©pÃ´t touchÃ©. MAJ refs grep si rename/move (CLAUDE.md, autres skills, hooks).

### Phase 5 â€” MAJ state.json + push + re-deploy hub

1. MAJ `state.json` : timestamps + commit_hash actuels par skill validÃ© (skills uniquement â€” CLAUDE.md sont versionnÃ©s par git, pas de state sÃ©parÃ©)
2. Phase 4 a modifiÃ© skills/CLAUDE.md â†’ **re-Phase 0** (regen 2 JSONs + redeploy + alias rebind) pour reflÃ©ter Ã©tat post-actions
3. Commit + push :
   - `~/.claude/skills/checkup-skills-perso/state.json`
   - `hub/master-hub/skills-data.json` + `claude-md-data.json`
   - Chaque CLAUDE.md modifiÃ© dans son dÃ©pÃ´t (commit sÃ©parÃ© par repo concernÃ©)
4. Recap final 5 lignes max : decisions appliquÃ©es + URL hub Ã  jour

## Â§4 Format JSON dÃ©cisions

### Input (Phase 0 step 2 â†’ gÃ©nÃ©rÃ© par script)

`master-hub/skills-data.json` :

```json
{
  "generated_at": "2026-05-07T...",
  "counts": { "global": 61, "projet": 120, "total": 181, "repos": {...} },
  "repos": [
    { "slug": "global", "path": "~/.claude/skills", "count": 61 },
    { "slug": "speak-app-dev", "path": "3- Wisper/speak-app-dev", "count": 48 }
  ],
  "skills": [
    {
      "name": "rule-creator",
      "dir_name": "rule-creator",
      "description": "CrÃ©e 1 rÃ¨gle...",
      "scope": "global",
      "repo": "global",
      "repo_path": "~/.claude/skills",
      "path": "C:/Users/.../skills/rule-creator/SKILL.md",
      "lines": 142,
      "last_commit_hash": "a45a6e7",
      "recommendation": { "action": "keep", "reason": "..." }
    }
  ]
}
```

### Output (Phase 3 â†’ exportÃ© par Monitoring Center, format unifiÃ© 2026-05-07)

`monitoring-changes-<timestamp>.json` :

```json
{
  "exported_at": "2026-05-07T...",
  "source": "monitoring-center",
  "total_skills": 182,
  "total_md": 19,
  "repos_known": [{ "slug": "global", "path": "~/.claude/skills" }, ...],
  "skills_decisions": [
    {
      "dir_name": "skill-builder",
      "name": "skill-builder",
      "current_repo": "global",
      "current_path": "C:/Users/.../skills/skill-builder/SKILL.md",
      "target_repos": [],
      "archive": true,
      "rename": false,
      "rework": false,
      "action": "archive"
    },
    {
      "dir_name": "doc-keeper",
      "current_repo": "global",
      "target_repos": ["global", "speak-app-dev"],
      "action": "duplicate"
    },
    {
      "dir_name": "preflight",
      "current_repo": "speak-app-dev",
      "target_repos": ["wisper"],
      "action": "move"
    }
  ],
  "claude_md_edits": [
    {
      "repo": "speak-app-dev",
      "path": "C:/Users/.../speak-app-dev/CLAUDE.md",
      "new_content": "# SpeakApp\n\n[full edited markdown]...",
      "edited_at": "2026-05-07T...",
      "previous_size": 24580,
      "new_size": 24612
    }
  ]
}
```

`action` âˆˆ `{move, duplicate, archive, flag}` (calculÃ© cÃ´tÃ© HTML, source de vÃ©ritÃ© = `target_repos` + `archive`).
`claude_md_edits[]` : liste vide si aucune Ã©dition CLAUDE.md.

## Â§5 Ã‰tat persistant `state.json`

**Fichier** : `~/.claude/skills/checkup-skills-perso/state.json`

```json
{
  "last_checkup": "2026-05-07T...",
  "validated": {
    "<dir_name>": {
      "validated_at": "2026-05-07T...",
      "decision": "keep|move-to-<repo>|duplicate-to-<repos>|archive|rename-to-<new>|rework",
      "current_repo": "global",
      "lines_at_validation": 234,
      "commit_hash_at_validation": "a45a6e7",
      "comment": "optional"
    }
  },
  "ignored": ["<dir_name-to-skip>"]
}
```

**RÃ¨gles MAJ state** :
- `keep` â†’ skill validÃ©, ne PAS reposer la question prochaine session SAUF si SKILL.md modifiÃ© depuis (`lines` ou `commit_hash` diff)
- `move|duplicate|archive|rename` â†’ action exÃ©cutÃ©e, retirer si plus actif (archive) ou re-noter avec nouvelles refs
- `rework` â†’ garder en "Ã  revoir" jusqu'Ã  modif dÃ©tectÃ©e
- `ignored` â†’ push uniquement si Florent dit explicitement "skip celui-ci toujours"

## Â§6 Partage Ã  un autre utilisateur

Skill conÃ§u pour Ãªtre dÃ©roulable par quelqu'un d'autre. PrÃ©-requis chez le destinataire :

1. **Cloner les repos** : skill suppose `~/.claude/skills/` global + `PROJECTS/<X>/.claude/skills/` par projet. Adapter `GLOBAL_SKILLS_DIR` et `PROJECTS_ROOT` dans `generate_skills_index.py` si paths diffÃ©rents.
2. **Hub Vercel** : forker repo dashboard ou crÃ©er nouveau projet Vercel. Mettre `index.html` + `monitoring-center.html` + `skills-triage.html` + `skills-data.json` + `claude-md-data.json` + `generate_skills_index.py` + `generate_claude_md_index.py` + `apply_changes.py` + `add_recommendations.py`.
3. **Workflow** : invoquer `/skill-checkup` chez Claude â†’ Phases 0â†’5 identiques. Phase 0 produit JSON adaptÃ©s Ã  l'arborescence locale.

**Customisation** :
- `EXCLUDE_PREFIXES` (script) â€” ajouter plugins externes Ã  filtrer
- `EXCLUDE_REPO_PATHS` (script) â€” exclure backups / worktrees
- Heuristiques `add_recommendations.py` `OVERRIDES` â€” adapter aux skills connus du destinataire

## Â§7 Anti-patterns

- âŒ Sauter Phase 0 (prÃ©senter triage sur hub stale = utilisateur perd confiance)
- âŒ Phase 0 â€” lancer **un seul** script (toujours les 2 : `generate_skills_index.py` ET `generate_claude_md_index.py`)
- âŒ Re-prÃ©senter skills STABLE (raison d'Ãªtre de `state.json` â€” Ã©conomie cognitive)
- âŒ Archive sans backup `_archive/skills-archive/<date>/`
- âŒ **Ã‰dition CLAUDE.md sans backup** â€” `apply_changes.py` crÃ©e backup `_archive/monitoring-changes-<ts>/claude-md/` automatiquement, ne JAMAIS Ã©craser sans passer par lui
- âŒ ExÃ©cuter dÃ©cisions Phase 4 sans confirmation utilisateur (rÃ©gÃ©nÃ©rer hub OK seul, mais move/delete/duplicate/write CLAUDE.md = besoin go explicite via `apply_changes.py [y/N]`)
- âŒ Oublier MAJ `state.json` Phase 5 (= prochain checkup re-pose tout)
- âŒ Oublier re-deploy hub aprÃ¨s actions Phase 4 (state divergent vs hub visible)
- âŒ Oublier de rÃ©assigner alias Vercel aprÃ¨s deploy (`vercel deploy` produit URL preview, alias `antigravity-master-hub.vercel.app` se dÃ©tache â†’ rÃ©assigner avec `vercel alias set`)
- âŒ Hardcoder la liste des dÃ©pÃ´ts dans le script (= ne marche que pour Florent). Auto-discover via `discover_project_repos()` obligatoire pour partage.
- âŒ Hardcoder skills/CLAUDE.md dans la page HTML. Tout vient des 2 JSON.
- âŒ Page HTML qui mÃ©lange "filtrer par dÃ©pÃ´t" et "dÃ©placer vers dÃ©pÃ´t" (bug confondu 2026-05-07). Boutons dÃ©pÃ´t = **toggle multi-target** dans skills-triage et monitoring-center, jamais filtres.
- âŒ Annoncer URL `skills-triage.html` Ã  Florent comme point d'entrÃ©e â†’ URL principale est `monitoring-center.html` (light, unifiÃ© skills + CLAUDE.md). `skills-triage.html` reste vue dense alternative.
- âŒ Commit CLAUDE.md modifiÃ©s tous dans un seul commit du master-hub repo â†’ ils vivent dans des **repos diffÃ©rents**, commit sÃ©parÃ© par repo concernÃ©.

## Â§8 Journal

- 2026-05-02 â€” Init skill global. Phase 0 NON-NÃ‰GOCIABLE regen hub avant triage. State persistant `state.json`. Coordination avec `/skill-store` + `/rule-cleaner` Workflow C.
- 2026-05-07 (matin) â€” Refonte page multi-dÃ©pÃ´t skills. Auto-discover 12 dÃ©pÃ´ts (vs 2 hardcodÃ©s avant). Boutons toggle multi-target par skill. Action `duplicate` ajoutÃ©e. Format JSON dÃ©cisions enrichi avec `target_repos[]` + `archive` + `rename` + `rework`. Skill rendu partageable (Â§6). Anti-pattern "filtre vs dÃ©place" gravÃ©.
- 2026-05-07 (soir) â€” **Extension pÃ©rimÃ¨tre = skills + CLAUDE.md**. CrÃ©ation `generate_claude_md_index.py` (scanne 19 CLAUDE.md sur 16 dÃ©pÃ´ts), `monitoring-center.html` (light theme, sections par dÃ©pÃ´t avec sous-blocs `ðŸ“ CLAUDE.md` + `ðŸ›  Skills`, modal Ã©dition textarea CLAUDE.md), `apply_changes.py` (backup + preview + confirmation + exÃ©cution unifiÃ©e). Format JSON exportÃ© unifiÃ© `monitoring-changes-<ts>.json` avec `skills_decisions[]` + `claude_md_edits[]`. URL principale changÃ©e â†’ `monitoring-center.html`. `skills-triage.html` reste vue dense alternative dark, cross-link ajoutÃ© dans header. Skill renamed `skill-checkup` â†’ `checkup-skills-perso`, paths state.json corrigÃ©s.


---

## FusionnÃ© depuis `checkup-skills-store` (2026-05-13)

Contenu prÃ©servÃ© du skill `checkup-skills-store` archivÃ©. Source originale: `.claude/skills/_archive/skills-archive/2026-05-13/checkup-skills-store/`

# Skill Store â€” Vivier de skills dormants

## Philosophie

**ProblÃ¨me** : chaque skill chargÃ© = description en tokens Ã— N sessions. Skills peu utilisÃ©s (1Ã— / mois ou ponctuels) coÃ»tent autant que skills quotidiens.

**Solution** : sortir skills dormants du chargement auto sans les supprimer. Stocker dans `skills-store/` (PAS scannÃ© par Claude). INDEX.md = pointeur consultable on-demand.

**Workflow lazy-read** :
1. Skills actifs `.claude/skills/` â†’ descriptions chargÃ©es chaque session (coÃ»t tokens)
2. Skills stockÃ©s `.claude/skills-store/` â†’ PAS chargÃ©s (zÃ©ro coÃ»t tokens default)
3. INDEX.md `.claude/skills-store/INDEX.md` â†’ 1 ligne par skill stockÃ© (description rÃ©sumÃ©e)
4. Si Claude/Florent cherche skill non trouvÃ© â†’ consulter INDEX â†’ ressortir si match

---

## Architecture skills par scope (Ã  connaÃ®tre AVANT stocker/migrer)

**4 niveaux de scope** â€” du + universel au + restreint :

| Scope | Path | Quand utiliser |
|-------|------|----------------|
| **Global** | `~/.claude/skills/` | Universel cross-projets (legal-*, dispatch, recap, plan, swarm-*, rule-cleaner, skill-store, etc.) |
| **Projet racine** | `<projet>/.claude/skills/` | SpÃ©cifique projet entier â€” chargÃ© partout dans le projet (auto-permission, widget, vosk-monitor pour SpeakApp) |
| **Sous-projet** | `<projet>/<sous-projet>/.claude/skills/` | SpÃ©cifique sous-projet â€” chargÃ© seulement quand cwd dans sous-projet (claude-design-* â†’ ALL Compagnies/Design/, youtube-* â†’ ALL Compagnies/YouTube Channel/) |
| **Exception global** | `~/.claude/skills/` malgrÃ© spÃ©cificitÃ© projet | Cas exceptionnel quand utilitÃ© cross-PC > Ã©conomie tokens (ex `speakapp-partners` global pour partage rapide associÃ©s) |

**RÃ¨gle de placement** :
- Skill utilisÃ© sur **TOUS projets** â†’ global
- Skill utilisÃ© sur **1 projet entier** â†’ projet racine
- Skill utilisÃ© sur **1 sous-dossier projet** â†’ sous-projet (scope fin = Ã©conomie tokens hors cwd)
- HÃ©sitation projet vs sous-projet â†’ projet racine (plus simple)

**Avantage scope fin** : skills sous-projet PAS chargÃ©s quand tu bosses ailleurs dans le projet â†’ Ã©conomie tokens descriptions.

## 2 niveaux de stores supportÃ©s

| Store | Path | Pour |
|-------|------|------|
| **Projet/Sous-projet** | `<scope>/.claude/skills-store/` | Skills dormants spÃ©cifiques scope |
| **Global** | `~/.claude/skills-store/` | Skills universels dormants (legal-*, infographic, etc.) |

**RÃ¨gle stock** : skill stockÃ© reste dans son scope d'origine. Skill global â†’ store global. Skill projet/sous-projet â†’ store du mÃªme scope.

---

## Workflow A â€” Stocker skill (sortir du chargement)

```bash
# 1. VÃ©rifier scope skill (projet vs global)
ls .claude/skills/<skill-name> 2>/dev/null && SCOPE="projet" || SCOPE="global"

# 2. Move vers store
if [ "$SCOPE" = "projet" ]; then
  mv .claude/skills/<skill-name> .claude/skills-store/<skill-name>
  STORE_INDEX=".claude/skills-store/INDEX.md"
else
  mv ~/.claude/skills/<skill-name> ~/.claude/skills-store/<skill-name>
  STORE_INDEX="~/.claude/skills-store/INDEX.md"
fi

# 3. Ajouter ligne INDEX (description rÃ©sumÃ©e 1 ligne)
# Format : | <skill-name> | <usage 1 phrase> | <quand rÃ©cupÃ©rer> | <date stock> |

# 4. Commit (si projet) â€” sync (si global via /migration-pc)
git add .claude/skills-store/ && git commit -m "chore(store): stocker /<skill-name> (peu utilisÃ©)"
```

## Workflow B â€” RÃ©cupÃ©rer skill (rÃ©activer)

```bash
# 1. Localiser dans store
[ -d .claude/skills-store/<skill-name> ] && SCOPE="projet" || SCOPE="global"

# 2. Move retour vers skills/
if [ "$SCOPE" = "projet" ]; then
  mv .claude/skills-store/<skill-name> .claude/skills/<skill-name>
else
  mv ~/.claude/skills-store/<skill-name> ~/.claude/skills/<skill-name>
fi

# 3. Retirer ligne INDEX

# 4. Commit / sync
git add .claude/ && git commit -m "chore(store): ressortir /<skill-name> (rÃ©activation)"
```

## Workflow C â€” Skill pas trouvÃ© (lookup INDEX)

Quand Claude/Florent cherche skill `/X` non trouvÃ© dans `/help` ou skills list :
1. Lire `.claude/skills-store/INDEX.md` projet
2. Lire `~/.claude/skills-store/INDEX.md` global
3. Match nom ou usage â†’ proposer ressortir
4. Pas de match â†’ skill n'existe vraiment pas, crÃ©er via `/skill-builder`

---

## Format INDEX.md

```markdown
# Skill Store â€” INDEX

> Skills stockÃ©s (pas chargÃ©s auto). RÃ©cupÃ©rer via `/skill-store rÃ©cupÃ©rer <name>`.

| Skill | Usage 1 phrase | Quand rÃ©cupÃ©rer | StockÃ© le |
|-------|---------------|-----------------|-----------|
| `cd-devtools-inject` | Inject JS dans DevTools console CD via clavier+clipboard | Re-investigation DevTools CD (deprecated BP-033) | 2026-05-02 |
| `python-migrate` | ProcÃ©dure migration Python 3.Xâ†’3.Y avec gates rollback | Prochaine migration Python | 2026-05-02 |
| ... |
```

---

## RÃ¨gles

1. **Stocker = pas supprimer** â€” `mv`, jamais `rm`. Skill rÃ©cupÃ©rable Ã  tout moment.
2. **INDEX 1 ligne par skill** â€” usage rÃ©sumÃ© bref. DÃ©tails restent dans SKILL.md du skill stockÃ©.
3. **Scope intact** â€” skill projet â†’ store projet. Skill global â†’ store global. Pas de cross-scope sans raison.
4. **Commit atomique** â€” `mv` + INDEX update dans mÃªme commit.
5. **Pas de stock agressif** â€” skill utilisÃ© mÃªme rarement (1Ã— / 2 mois) reste actif si gain tokens marginal vs coÃ»t rÃ©cupÃ©ration.
6. **Lookup avant crÃ©er** â€” chercher dans INDEX (les 2) AVANT de crÃ©er skill nouveau (Ã©vite doublon avec stockÃ© oubliÃ©).

---

## Anti-patterns

- âŒ `rm -rf .claude/skills/X` â€” perdu Ã  jamais. Toujours `mv` vers store.
- âŒ Stocker sans MAJ INDEX â€” skill devient invisible (perdu sans grep).
- âŒ Stocker skill quotidien â€” gain tokens nul vs friction rÃ©activation constante.
- âŒ Cross-scope mv (projet â†’ store global) sans raison â€” perd contexte projet.
- âŒ CrÃ©er skill avant lookup INDEX â€” risque doublon avec stockÃ©.

---

## Quand NE PAS utiliser

| Situation | Skill plutÃ´t |
|-----------|--------------|
| CrÃ©er skill nouveau | `/skill-builder` |
| Audit/cleanup skills actifs | `/rule-cleaner` Workflow C |
| Renommer skill (cohÃ©rence prÃ©fixe) | `/rule-cleaner` Â§3ter |
| Supprimer dÃ©finitivement skill | NE PAS â€” toujours stocker (rÃ©cupÃ©rable plus tard) |

---

## Exemples

| Action | Commande |
|--------|----------|
| Stock projet `cd-devtools-inject` | `mv .claude/skills/cd-devtools-inject .claude/skills-store/` + INDEX add |
| RÃ©cup projet `python-migrate` | `mv .claude/skills-store/python-migrate .claude/skills/` + INDEX remove |
| Stock global `infographic` | `mv ~/.claude/skills/infographic ~/.claude/skills-store/` + INDEX global add |
| Lookup "skill pour debug GIL ?" | `cat .claude/skills-store/INDEX.md` â†’ match `gil-thread-debug` â†’ propose rÃ©cup |
