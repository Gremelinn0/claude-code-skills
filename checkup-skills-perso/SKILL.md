---
name: checkup-skills-perso
description: Checkup périodique skills + CLAUDE.md + skills-store dormant — 2 workflows (A = Monitoring Center Vercel triage visuel, B = chat topic-by-topic avec fusion preserve-content). Auto-discover dépôts, exécution via apply_changes.py OU script batch fusion (template _archive/skills-archive/<date>/_fusion_log.py). Triggers "/skill-checkup", "audit skills", "fais le point skills", "nettoyage skills", "ranger skills", "réorganiser skills", "consolider skills", "fusionner skills", "ménage skills".
---

# /skill-checkup — Audit + réorganisation skills + CLAUDE.md multi-dépôt

Skill global. Workflow reproductible et partageable pour auditer tous les skills perso **ET** tous les CLAUDE.md de Florent (ou de quelqu'un d'autre) sur tous ses dépôts d'un coup. Page Vercel **Monitoring Center** (light theme) sert de support de tri visuel + édition inline CLAUDE.md, JSON exporté sert de plan d'exécution unifié appliqué via `apply_changes.py`.

## Sommaire

- §1 Quand invoquer
- §2 Architecture (8 fichiers + 3 pages Vercel)
- §3 Workflow A — Monitoring Center Vercel (5 phases)
- §3bis Workflow B — Chat topic-by-topic (gravé 2026-05-13)
- §3ter Workflow C — Audit worktree vs dépôt principal (gravé 2026-05-20)
- §4 Format JSON décisions (input → output)
- §5 État persistant (state.json)
- §6 Partage à un autre utilisateur
- §7 Anti-patterns
- §8 Skills-store (workflow store) — fusionné depuis checkup-skills-store 2026-05-13

## §1 Quand invoquer

- Florent dit `/skill-checkup`, "audit skills", "fais le point sur mes skills", "nettoyage skills", "réorganiser skills", "ranger skills"
- Routine périodique (mensuelle recommandée — pas hebdo, drift trop lent)
- Après création/rename/cleanup massif skills (>5 modifs en 1 session)
- Avant `/wrapup` si session a touché ≥1 skill

## §2 Architecture

8 fichiers + 3 pages Vercel composent le système (2 nouveaux fichiers ajoutés 2026-05-15 : `skills-marketplace.html` page skills épurée + `skills-usage-map.json` mapping usage).

| Fichier | Rôle |
|---------|------|
| `master-hub/generate_skills_index.py` | Auto-discover tous dépôts `*/.claude/skills/` sous `PROJECTS/` + global `~/.claude/skills/`. Produit `skills-data.json` enrichi (incl. `full_content`). |
| `master-hub/generate_claude_md_index.py` | **NEW 2026-05-07** — Scanne tous CLAUDE.md (~19, 16 dépôts) global + PROJECTS/ profondeur 1-4. Filtre worktrees + backups. Produit `claude-md-data.json` (incl. `full_content` + sections H1/H2/H3). |
| `master-hub/add_recommendations.py` | Pré-remplit recommandations par skill (keep/rework/archive heuristique) dans le JSON. Optionnel. |
| `master-hub/apply_changes.py` | **NEW 2026-05-07** — Lit JSON exporté Monitoring Center → backup `_archive/monitoring-changes-<ts>/` → applique writes CLAUDE.md + actions skills. Demande confirmation interactive (sauf `--yes`). |
| `master-hub/skills-data.json` | Source vérité skills. Structure : `{generated_at, repos:[{slug,path,count}], skills:[{name,dir_name,description,summary,full_content,scope,repo,repo_path,path,lines,last_commit_hash}]}` |
| `master-hub/claude-md-data.json` | **NEW** — Source vérité CLAUDE.md. Structure : `{generated_at, repos:[{slug,path,count}], files:[{repo,scope,path,size,lines,last_modified,full_content,sections:[{level,title,line}]}]}` |
| `master-hub/skills-triage.html` | Page Vercel **dark** — vue dense skills uniquement. Toggle multi-target + archive/rename/rework + export JSON skills. État localStorage. |
| `master-hub/monitoring-center.html` | **NEW 2026-05-07** — Page Vercel **light theme** unifiée. Sections par dépôt avec sous-blocs `📁 CLAUDE.md` + `🛠 Skills`. Modal CLAUDE.md = textarea éditable. Modal skill = lecture + actions. Export JSON unifié (`skills_decisions[]` + `claude_md_edits[]`). |
| `master-hub/skills-marketplace.html` | **NEW 2026-05-15 ; refonte v2 2026-05-15** ⭐ — Page Vercel **light éditoriale chaude** (palette crème/terracotta/ocre/sage, serif Georgia titres), modèle **master-détail** (liste à gauche + panneau détail à droite, pas de modal), pleine page togglable. 2 modes commutables : **Skills** (par dépôt OU par usage-métier) + **CLAUDE.md** (consulter + éditer inline les 19 CLAUDE.md). 5 actions par skill : **Garder · Mettre en réserve · Archiver · Déplacer vers `<dépôt>` · Dupliquer vers `<dépôts>`** (multi-sélection). Doublons cross-dépôt marqués. Recommandations pré-remplies. Filtres multi-sélection avec compteurs. Tiroir de décisions repliable. Contenu complet des SKILL.md déplié par défaut (lazy au clic). Export JSON unifié skills + CLAUDE.md compatible `apply_changes.py`. C'est LA page skills principale. |
| `master-hub/skills-usage-map.json` | **NEW 2026-05-15** — Mapping `<repo>::<dir_name> → catégorie usage/métier` + `categories_order`. Alimente la vue "Par usage" de `skills-marketplace.html`. Éditable à la main, skills absents → "Non classé". |

**Path local Master Hub** : `C:/Users/Administrateur/PROJECTS/Vente et Marketing - ALL Compagnies/hub/master-hub/`

**URLs prod** :
- **Marketplace de skills** (light, épurée) : `https://antigravity-master-hub.vercel.app/skills-marketplace.html` ⭐ POINT D'ENTRÉE SKILLS
- Hub unifié skills + CLAUDE.md (light) : `https://antigravity-master-hub.vercel.app/monitoring-center.html` — pour le travail CLAUDE.md
- Vue dense skills (dark) : `https://antigravity-master-hub.vercel.app/skills-triage.html`

### Export de `skills-marketplace.html` — format unifié compatible `apply_changes.py`

`skills-marketplace.html` v2 exporte `skill-hub-decisions-<ts>.json` au format unifié skills + CLAUDE.md (même structure que `monitoring-changes-<ts>.json` du Monitoring Center) :
```json
{ "source": "skills-marketplace", "exported_at": "...", "repos_known": [...],
  "_note": "...",
  "skills_decisions": [
    { "dir_name": "...", "name": "...", "current_repo": "...", "current_path": "...",
      "target_repos": [...], "archive": bool, "rename": bool, "rework": bool,
      "action": "archive" | "move" | "duplicate" | "store" | "flag" }
  ],
  "claude_md_edits": [
    { "repo": "...", "path": "...", "new_content": "...", "edited_at": "...",
      "previous_size": N, "new_size": N }
  ]
}
```
Consommation : `python apply_changes.py <fichier>.json` gère nativement `archive`, `move`, `duplicate`, `flag` (rename/rework) + applique les `claude_md_edits[]` (write avec backup auto). L'`action: store` n'est pas native — consommée par **Workflow B** (§3bis) qui fait `mv <repo>/.claude/skills/<dir>/ → <repo>/.claude/skills-store/<dir>/` + MAJ `INDEX.md`. Avant chaque session de tri : régénérer fresh via Phase 0 (les 2 generate scripts) sinon décisions sur données stales.

## §3bis Workflow B — Chat topic-by-topic (gravé 2026-05-13)

**Quand Florent dit "fais le ménage skills" en chat direct** (sans vouloir passer par le Monitoring Center Vercel), suivre ce workflow alternatif :

1. **Phase 0** identique workflow A (regen `skills-data.json` + `claude-md-data.json` + deploy hub — toujours partir d'un état propre)
2. **Grouper les skills par SUJET** (pas par dépôt). Sujets typiques SpeakApp : Tests / Health-monitoring / Checkup-audit / Scan-setup / Management / Docs-orchestration / Bug-debug / Dev-workflow / Features. **Topic > dépôt** : Florent raisonne par "qu'est-ce qui sert à quoi", pas par "où est rangé".
3. **Pour chaque sujet** présenter UNE proposition consolidée :
   - Liste skills du sujet avec description 1 ligne
   - Proposer FUSION (préférée) > STORE (récupérable) > ARCHIVE
   - Cible explicite pour chaque fusion (`X → fusionner dans Y` avec raison)
   - Bilan : "passe de N à M skills"
4. **Florent répond OUI/NON/MODIF par sujet** (pas par skill individuel — c'est trop fastidieux)
5. **Exécuter en cascade** via script Python batch (template : `_archive/skills-archive/<date>/_fusion_log.py`) :
   - Pour chaque fusion : lire source SKILL.md (skip frontmatter) → append en section `## Fusionné depuis <X> (YYYY-MM-DD)` dans target → archive source
   - Pour chaque store : `mv skills/<X> skills-store/<X>` + MAJ INDEX.md
   - Pour chaque archive simple : `mv skills/<X> _archive/skills-archive/<date>/<X>/`
6. **Re-Phase 0** (regen + deploy) après exécution
7. **Commit + push** atomique

### Heuristique destination (gravée 2026-05-14)

**Classification skill enfant vs user-facing** — déterminer où va un skill quand on l'archive :

1. **Skill enfant → `_archive/skills-archive/<date>/`** (archive permanente, pas pollution liste user). Critères détection :
   - Cité explicitement par un **hook Python** dans `tools/*_hook.py` ou `.claude/settings.json` (mais attention : un hook qui affiche un message texte type *"Invoque `/X`"* ne dépend PAS du chargement du skill — il exécute son script Python directement)
   - Cité par un **autre skill SKILL.md** via Skill tool / dans son workflow
   - Description du skill dit explicitement *"skill OUTIL (pas feature autonome)"* ou *"appelé par"*
   - Jamais invoqué directement par user dans les transcripts historiques

2. **Skill user-facing peu utilisé → `skills-store/`** (dormant récupérable). Critères :
   - Audit mensuel / cron rare / outil ponctuel
   - User l'invoque parfois mais < 1×/mois
   - Description orientée action user, pas flow technique

3. **Skill mort (deprecated / fusionné dont contenu déjà préservé ailleurs) → archive permanente**.

**Vérification hooks AVANT archive enfant** : grep `<skill-name>` dans `.claude/settings.json` + `tools/*hook*.py`. Si match = texte affiché type *"suggère `/X`"* → safe (hook fait son boulot via script Python, le skill archivé reste fonctionnellement disponible si re-listé). Si match = Skill tool call programmatique → casse, ne pas archiver.

**Vérification skill-to-skill calls AVANT archive enfant** : grep `<skill-name>` dans tous les `.claude/skills/*/SKILL.md` actifs. Si un skill actif appelle l'enfant via Skill tool → soit garder actif, soit MAJ le skill parent même commit pour pointer vers `_archive/`.

### Règles d'or workflow B

- ⚠️ **Préserver le contenu utile** — Florent verbatim 2026-05-13 : *"il y a sûrement des choses utiles. (...) sûrement pas les archiver comme ça"*. Fusion > archive simple. Le body source est append intégral dans target (jamais perdu).
- ⚠️ **Attention aux vieux trucs obsolètes** — Florent verbatim 2026-05-13 : *"il peut y avoir des choses un peu obsolètes et ça c'est compliqué"*. Si fusion détecte contenu daté/contradictoire dans le source, le marquer `[CONTENU HISTORIQUE - À NETTOYER]` au lieu de l'append brut.
- **Préférer fusion par cible évidente** (`mechanism-tester → feature-validator` car même objectif "valider mécanisme sur cible"). Si pas de cible évidente → demander.
- **Store > archive** pour les skills "audit mensuel" / "audit ponctuel mais utile" / "cron rare". Récupérables sans perte.
- Workflow B utilisé même session que workflow A est OK (Phase 0 commun, juste skip Phase 3 UI Vercel et exécuter directement).

### Cas inaugural gravé 2026-05-13

Session SpeakApp : passé de 55 à 33 skills actifs en 1 session :
- 7 skills archivés simples (define-feature, widget-demo, brand-identity, autoresearch, create-debug-pipeline, cd-scan, switch-session)
- 13 fusions exécutées (mechanism-tester, n4-log-pipelines, test-cc-*, test-mode-b, stt-health-check, vosk-*, check-notif-pipeline, dom-scanner, checkup-doc-routing, checkup-skills-store)
- 2 mises en store (checkup-memory-archi, audit-zero-intrusion)
- Script batch `_fusion_log.py` réutilisable comme template

## §3 Workflow A — Monitoring Center Vercel (5 phases)

### Phase 0 — Regen hub Vercel AVANT triage (NON-NÉGOCIABLE)

Toujours partir d'un hub à jour. Sinon Florent voit version stale. **2 scripts à lancer maintenant** (skills + CLAUDE.md).

```bash
cd "C:/Users/Administrateur/PROJECTS/Vente et Marketing - ALL Compagnies/hub/master-hub"
python generate_skills_index.py        # → skills-data.json
python generate_claude_md_index.py     # → claude-md-data.json (NEW 2026-05-07)
python add_recommendations.py          # → enrichit skills-data.json (heuristiques)
```

Puis :

1. Diff git pour voir changements (skills-data.json + claude-md-data.json)
2. Si changé → `npx vercel deploy --prod --yes` puis **OBLIGATOIRE** `npx vercel alias set <new-deploy>.vercel.app antigravity-master-hub.vercel.app` (alias se détache à chaque deploy fresh, doit être réassigné)
3. Vérifier curl `https://antigravity-master-hub.vercel.app/skills-data.json` ET `claude-md-data.json` retournent les nouveaux JSON
4. Commit + push repo `Vente et Marketing - ALL Compagnies` (`hub/master-hub/skills-data.json` + `claude-md-data.json`)
5. Annoncer URL : `https://antigravity-master-hub.vercel.app/monitoring-center.html` (Ctrl+Shift+R pour bypass cache)

**Si fichier ou page absent** : invoquer skill `dashboards-hub-master` + recréer (cf. session 2026-05-07).

### Phase 1 — Load state + scan skills actuels

1. Read `~/.claude/skills/skill-checkup/state.json` (créer si absent : `{"validated": {}, "ignored": []}`)
2. Le scan auto-discover (Phase 0 step 1) trouve tous les dépôts, pas de scan manuel à refaire
3. Pour chaque skill du JSON : récup `dir_name`, `repo`, `lines`, `last_commit_hash`

### Phase 2 — Diff intelligent (filtre)

Catégoriser chaque skill :
- **NEW** : pas dans `state.validated`
- **MODIFIED** : dans `state.validated` MAIS `lines` ou `commit_hash` ≠ valeurs au moment de la validation
- **STABLE** : dans `state.validated`, identique → SKIP (ne pas re-présenter)
- **IGNORED** : dans `state.ignored` → SKIP

Compter chaque catégorie. Si NEW + MODIFIED == 0 → annoncer à Florent "Aucun changement depuis dernier checkup. Hub à jour : <URL>. Rien à trier." → STOP.

### Phase 3 — Florent trie + édite sur Monitoring Center

Annonce à Florent (caveman OFF, langage simple) :

```
Hub à jour : https://antigravity-master-hub.vercel.app/monitoring-center.html

Bilan :
- X dépôts détectés
- Y skills total (Z nouveaux depuis dernier checkup, W modifiés)
- N CLAUDE.md scannés
- Recos pré-remplies : N keep / N rework / N archive

Comment utiliser le Monitoring Center (light theme) :
1. Ouvre l'URL (Ctrl+Shift+R pour rafraîchir)
2. Sections collapsibles par dépôt — chaque dépôt a 2 sous-blocs :
   📁 CLAUDE.md  → click ouvre modal avec textarea éditable + bouton "💾 Marquer modifié"
   🛠 Skills    → 1 bouton par dépôt (multi-select), ★ = dépôt actuel, archive/rename/rework
3. Filtres : Tous / Avec changements / CLAUDE.md seul / Skills seuls
4. Export JSON unifié quand fini → reviens en session avec le fichier
```

Florent fait son tri + édition à son rythme (state localStorage persisté). Quand fini, il exporte un JSON `monitoring-changes-<timestamp>.json` et le partage en session.

### Phase 4 — Exécution décisions via apply_changes.py

À la réception du JSON exporté (`source: "monitoring-center"`) :

```bash
python "C:/Users/Administrateur/PROJECTS/Vente et Marketing - ALL Compagnies/hub/master-hub/apply_changes.py" <fichier>.json
```

Le script gère **tout** automatiquement :

1. **Backup** tous les CLAUDE.md cibles dans `master-hub/_archive/monitoring-changes-<ts>/claude-md/<repo>_CLAUDE.md`
2. **Preview** : liste les `claude_md_edits[]` (avec delta bytes) + `skills_decisions[]` (avec action déduite)
3. **Confirmation interactive** : `[y/N]` (sauf flag `--yes`)
4. **Exécution** :
   - `claude_md_edits[]` → write nouveau contenu en utf-8
   - `action: archive` → move skill dir → `<repo>/.claude/skills/_archive/skills-archive/<ts>/<dir>/`
   - `action: move` → move skill dir → `<target_repo>/.claude/skills/<dir>/`
   - `action: duplicate` → copytree skill dir vers chaque target supplémentaire (garde courant)
   - `action: flag` (rename/rework only) → log seul, pas d'action filesystem
5. **Recap final** : count écrits + skippés + path backup

**Si rename** → demander à Florent le nouveau nom (Phase 4bis), refactor manuellement.
**Si rework** → ouvrir SKILL.md + inviter Florent à éditer description.

Après `apply_changes.py` : commit atomique par dépôt touché. MAJ refs grep si rename/move (CLAUDE.md, autres skills, hooks).

### Phase 5 — MAJ state.json + push + re-deploy hub

1. MAJ `state.json` : timestamps + commit_hash actuels par skill validé (skills uniquement — CLAUDE.md sont versionnés par git, pas de state séparé)
2. Phase 4 a modifié skills/CLAUDE.md → **re-Phase 0** (regen 2 JSONs + redeploy + alias rebind) pour refléter état post-actions
3. Commit + push :
   - `~/.claude/skills/checkup-skills-perso/state.json`
   - `hub/master-hub/skills-data.json` + `claude-md-data.json`
   - Chaque CLAUDE.md modifié dans son dépôt (commit séparé par repo concerné)
4. Recap final 5 lignes max : decisions appliquées + URL hub à jour

## §3ter Workflow C — Audit worktree vs dépôt principal (gravé 2026-05-20)

**Quand Florent dit** "audit worktree skills", "check divergence skills worktree", "skills à jour partout ?", `/skill-checkup workflow C` — ou en routine périodique (mensuelle, OU après session avec ≥1 skill édité dans un worktree).

### Pourquoi ce workflow existe (cas inaugural 2026-05-20)

Quand on édite un skill `/X` SKILL.md dans un worktree d'un projet (ex SpeakApp `worktrees/heuristic-liskov-826772/.claude/skills/drive/`), on commit + push origin/dev OK, mais **le dépôt principal `speak-app-dev/` ne voit pas la nouvelle version tant qu'il n'a pas `git pull`**. Risque :
- Une autre session Claude Code dans `speak-app-dev/` charge l'ancien skill
- Consommation tokens 2× si Claude charge les 2 versions divergentes
- Drift silencieux entre worktrees du même repo
- Comportement skill imprévisible selon où la session est lancée

Florent verbatim 2026-05-20 : *"il faut toujours que le skill soit mis à jour dans la version officielle [dépôt principal ou global], jamais que ça reste dans un worktree non pushé ou non pull"*.

### Phase 0 — Scan multi-repo des worktrees

Pour chaque dépôt Git détecté (auto-discover via Phase 0 Workflow A `generate_skills_index.py` OU listing manuel) :

```bash
# Exemple SpeakApp
cd "C:/Users/Utilisateur/PROJECTS/3- Wisper/speak-app-dev"
git worktree list
# Output exemple : speak-app-dev (principal dev) + 9 worktrees claude/* + 2 worktrees V2
```

Étendre à tous les projets de premier niveau Florent (~4 sur ce PC : `0- Marketplace`, `3- Wisper` = SpeakApp, `Vente et Marketing - ALL Compagnies`, `navigateur`).

### Phase 1 — Diff skills entre principal et chaque worktree

Pour chaque skill du dépôt principal (`.claude/skills/<X>/SKILL.md`) :
1. Calculer hash contenu : `git hash-object <path>`
2. Pour chaque worktree, calculer hash du même skill
3. Comparer et classer :
   - **TOUS IDENTIQUES** → ✅ skill aligné, SKIP
   - **Worktree à jour, principal en retard** (hash worktree = HEAD d'origin/dev plus récent que hash principal) → 🟡 principal doit pull (recommandation auto-pull si Florent autorise)
   - **Worktree avec modif locale non-commité** (status worktree dirty sur ce fichier) → 🟠 flag Florent (commit + push attendu côté worktree)
   - **Worktrees divergents entre eux** (≥2 hashes différents non-principal) → 🔴 critique, multiple sources, gestion 1 par 1 (cas rare, escalade Florent)

### Phase 2 — Rapport synthétique

Tableau par dépôt × skill :

```
| Dépôt | Skill | Principal hash | Worktrees status | Action recommandée |
|-------|-------|----------------|------------------|--------------------|
| speak-app-dev | drive | abc123 (commit ancien) | 1 worktree heuristic-liskov à jour def456 | 🟡 git pull principal |
| speak-app-dev | recap | xyz789 | 11/11 identique | ✅ aligné |
| speak-app-dev | wrapup | qrs456 | 1 worktree v2-phase1 avec modif locale non-commitée | 🟠 commit attendu worktree |
```

### Phase 3 — Auto-fix (si autorisé par Florent)

**Cas 🟡 "principal en retard"** :
1. Vérifier que principal est sur la bonne branche (`git -C <repo-principal> branch --show-current` doit retourner `dev` pour SpeakApp, sinon flag Florent — pas auto-switch branche)
2. Vérifier que principal n'a pas de WIP uncommitted (`git -C <repo-principal> status --porcelain` doit être vide ; sinon `/git-safe-push` style auto-stash recommandé)
3. `cd <repo-principal> && git pull origin <branch>`
4. Signaler à Florent : "Pull principal `<repo>` effectué, skills synchronisés (commits N1→N2)"

**Cas 🟠 "modif worktree non-commitée"** :
- Flag à Florent, **NE PAS auto-commit** (pourrait écraser WIP intentionnel)
- Suggérer commande : `cd <worktree> && git status` puis si Florent veut propager → `/git-safe-push`

**Cas 🔴 "worktrees divergents entre eux"** :
- Lister les versions divergentes par hash + mtime + auteur du dernier commit
- Demander Florent quelle version garder (cas escalade Phase 3 `/drive` 5 — décision produit)
- Backup obligatoire des versions perdantes dans `~/.claude/skills-store/_dedup-worktree-<YYYY-MM-DD>/`

### Phase 4 — Trace + commit

1. **Drive-log local** `<repo>/.autopilot/drive-log.md` : 1 ligne par audit workflow C
2. **Roadmap entry** `<repo>/memory/roadmap/roadmap.md` section `[DRIVE]` si actions auto-pull effectuées
3. **Pas de commit Git** dans `/checkup-skills-perso` lui-même (skill global, external repos) — les commits sont dans les repos audités si auto-pull a tiré des nouveaux commits

### Phase 5 — Santé sync cross-PC `claude-home` (gravée 2026-05-20)

**Quand exécuter** : à la fin de chaque audit Workflow C complet, ou en standalone via `/skill-checkup health-sync` quand Florent dit "santé sync skills cross-PC", "tu vois bien que les 2 PCs sont alignés ?".

**Contexte** : `~/.claude/` est un repo Git `Gremelinn0/claude-home` (vérifier : `git -C ~/.claude remote -v`) avec auto-sync continu via 2 hooks bash (`~/.claude/hooks/auto_sync_repos.sh` push + `~/.claude/hooks/auto_pull_repos.sh` pull, déclenchés par events Claude Code via `~/.claude/settings.json`). Les PCs de Florent (`Portableflo` + `DESKTOP-UH5HSM9`) se synchronisent en continu. Vérifier la santé = s'assurer que les 2 PCs sont bien alignés et que rien n'a divergé silencieusement.

**5 checks à faire** :

1. **Unpushed commits** sur ce PC : `git -C ~/.claude log --oneline origin/main..HEAD`
   - Doit être vide. Sinon → l'auto-sync push n'a pas encore tourné, attendre 2-5 min OU forcer `git -C ~/.claude push origin main`
2. **Unpulled commits** depuis l'autre PC : `git -C ~/.claude log --oneline HEAD..origin/main`
   - Doit être vide. Sinon → l'auto-sync pull n'a pas encore tourné, forcer `git -C ~/.claude pull origin main --rebase`
3. **Untracked critiques** : `git -C ~/.claude status --porcelain | grep -E "^\?\?" | grep -vE "^\?\? (tasks|projects|sessions)/"`
   - Doit être vide. Les `tasks/<uuid>/` et `projects/**` (gitignored) sont OK. Tout autre fichier untracked dans `skills/`, `hooks/`, `memory/`, `CLAUDE.md` racine = **drift potentiel**, à investiguer.
4. **Activité auto-sync par PC** (analyse des derniers commits) :
   ```bash
   git -C ~/.claude log --oneline -50 | grep -E "auto-sync (Portableflo|DESKTOP-UH5HSM9)" | head -10
   ```
   - Identifier dernier timestamp par PC. Si un PC n'a pas push depuis >24h → PC potentiellement offline / hors-réseau, **flag à Florent** (pas auto-fix : problème côté PC distant, pas dans le repo).
5. **Conflits résolus auto récents** : `ls -t ~/.claude/conflict-backups/ | head -10`
   - 1-10 conflits/jour résolus auto = normal (deux PCs syncs simultanés, strategy "concat" sur les logs).
   - >20 conflits/jour = race conditions excessives, signaler à Florent. Possible cause : un hook qui modifie un fichier sur les 2 PCs en boucle, ou un fichier non-déterministe inclus dans le repo.

**Rapport synthétique** (format obligatoire pour Florent caveman OFF) :

```
| Check | Status | Détail |
|-------|--------|--------|
| Unpushed | ✅/🟡 | <N> commit non-pushé sur ce PC |
| Unpulled | ✅/🟡 | <N> commit en retard sur origin/main |
| Untracked critiques | ✅/🟠 | <N> (X tasks/ untracked = OK) |
| Portableflo activité | ✅/🟡 | dernier sync <timestamp> (il y a <X> heures) |
| DESKTOP-UH5HSM9 activité | ✅/🟡 | dernier sync <timestamp> (il y a <X> heures) |
| Conflits auto (24h) | ✅/🟠 | <N> résolus auto, tous backups OK dans `conflict-backups/` |
```

**Auto-fix si autorisé par Florent** :
- Cas "Unpushed" → `git -C ~/.claude push origin main` (zéro risque, juste pusher ce qui est déjà commité local)
- Cas "Unpulled" → `git -C ~/.claude pull origin main --rebase` (auto-sync style, rebase rapide sans merge commit)
- Cas "PC offline >24h" → **flag Florent, pas auto-fix** (problème pas dans le repo, problème PC distant)
- Cas "Conflits excessifs" → flag Florent, suggérer audit des patterns auto-resolution

**Anti-patterns Phase 5** :
- ❌ Auto-pull sans checker `git -C ~/.claude branch --show-current` = `main` (pourrait casser une branche feature en cours)
- ❌ Force push pour "réparer" divergence (perte de modifs côté autre PC)
- ❌ Supprimer manuellement les `conflict-backups/` sans valider — ils servent de safety net pour rollback

### Trigger workflow C

- **Manuel** : Florent dit `/skill-checkup workflow C`, "audit worktree", "check divergence skills", "skills à jour partout ?"
- **Routine mensuelle** : ajouter au cron checkup mensuel (en plus des workflows A + B)
- **Auto post-push** (V2 backlog, pas encore implémenté) : hook PostToolUse `git push` depuis worktree contenant edit `.claude/skills/*/SKILL.md` → trigger workflow C ciblé sur ce skill uniquement

### Anti-patterns interdits

- ❌ **Auto-pull dépôt principal sans vérifier la branche courante** (peut casser autre session active sur branche différente)
- ❌ **Auto-commit worktree avec modif non-commitée** (peut écraser WIP utilisateur intentionnel)
- ❌ **Auto-merge worktrees divergents sans demander Florent** (perte de modifs)
- ❌ **Skip backup avant suppression d'une version divergente** (procédure §1 anti-doublon CLAUDE.md global = backup obligatoire `~/.claude/skills-store/_dedup-<date>/`)

### Vision auto (V2 idéale, pas encore implémentée)

Si la divergence est détectée DANS LA MÊME SESSION (Claude vient d'éditer un skill dans worktree, vient de push origin/dev) → **auto-pull principal en background** + signaler 1 ligne à Florent ("Skill `/X` propagé : worktree → push → pull principal OK"). Hook PostToolUse `git push` + check si fichier `.claude/skills/*/SKILL.md` dans les commits du push → auto-trigger workflow C ciblé. V2 backlog.

---

## §4 Format JSON décisions

### Input (Phase 0 step 2 → généré par script)

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
      "description": "Crée 1 règle...",
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

### Output (Phase 3 → exporté par Monitoring Center, format unifié 2026-05-07)

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

`action` ∈ `{move, duplicate, archive, flag}` (calculé côté HTML, source de vérité = `target_repos` + `archive`).
`claude_md_edits[]` : liste vide si aucune édition CLAUDE.md.

## §5 État persistant `state.json`

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

**Règles MAJ state** :
- `keep` → skill validé, ne PAS reposer la question prochaine session SAUF si SKILL.md modifié depuis (`lines` ou `commit_hash` diff)
- `move|duplicate|archive|rename` → action exécutée, retirer si plus actif (archive) ou re-noter avec nouvelles refs
- `rework` → garder en "à revoir" jusqu'à modif détectée
- `ignored` → push uniquement si Florent dit explicitement "skip celui-ci toujours"

## §6 Partage à un autre utilisateur

Skill conçu pour être déroulable par quelqu'un d'autre. Pré-requis chez le destinataire :

1. **Cloner les repos** : skill suppose `~/.claude/skills/` global + `PROJECTS/<X>/.claude/skills/` par projet. Adapter `GLOBAL_SKILLS_DIR` et `PROJECTS_ROOT` dans `generate_skills_index.py` si paths différents.
2. **Hub Vercel** : forker repo dashboard ou créer nouveau projet Vercel. Mettre `index.html` + `monitoring-center.html` + `skills-triage.html` + `skills-data.json` + `claude-md-data.json` + `generate_skills_index.py` + `generate_claude_md_index.py` + `apply_changes.py` + `add_recommendations.py`.
3. **Workflow** : invoquer `/skill-checkup` chez Claude → Phases 0→5 identiques. Phase 0 produit JSON adaptés à l'arborescence locale.

**Customisation** :
- `EXCLUDE_PREFIXES` (script) — ajouter plugins externes à filtrer
- `EXCLUDE_REPO_PATHS` (script) — exclure backups / worktrees
- Heuristiques `add_recommendations.py` `OVERRIDES` — adapter aux skills connus du destinataire

## §7 Anti-patterns

- ❌ Sauter Phase 0 (présenter triage sur hub stale = utilisateur perd confiance)
- ❌ Phase 0 — lancer **un seul** script (toujours les 2 : `generate_skills_index.py` ET `generate_claude_md_index.py`)
- ❌ Re-présenter skills STABLE (raison d'être de `state.json` — économie cognitive)
- ❌ Archive sans backup `_archive/skills-archive/<date>/`
- ❌ **Édition CLAUDE.md sans backup** — `apply_changes.py` crée backup `_archive/monitoring-changes-<ts>/claude-md/` automatiquement, ne JAMAIS écraser sans passer par lui
- ❌ Exécuter décisions Phase 4 sans confirmation utilisateur (régénérer hub OK seul, mais move/delete/duplicate/write CLAUDE.md = besoin go explicite via `apply_changes.py [y/N]`)
- ❌ Oublier MAJ `state.json` Phase 5 (= prochain checkup re-pose tout)
- ❌ Oublier re-deploy hub après actions Phase 4 (state divergent vs hub visible)
- ❌ Oublier de réassigner alias Vercel après deploy (`vercel deploy` produit URL preview, alias `antigravity-master-hub.vercel.app` se détache → réassigner avec `vercel alias set`)
- ❌ Hardcoder la liste des dépôts dans le script (= ne marche que pour Florent). Auto-discover via `discover_project_repos()` obligatoire pour partage.
- ❌ Hardcoder skills/CLAUDE.md dans la page HTML. Tout vient des 2 JSON.
- ❌ Page HTML qui mélange "filtrer par dépôt" et "déplacer vers dépôt" (bug confondu 2026-05-07). Boutons dépôt = **toggle multi-target** dans skills-triage et monitoring-center, jamais filtres.
- ❌ Annoncer URL `skills-triage.html` à Florent comme point d'entrée → URL principale est `monitoring-center.html` (light, unifié skills + CLAUDE.md). `skills-triage.html` reste vue dense alternative.
- ❌ Commit CLAUDE.md modifiés tous dans un seul commit du master-hub repo → ils vivent dans des **repos différents**, commit séparé par repo concerné.

## §8 Journal

- 2026-05-02 — Init skill global. Phase 0 NON-NÉGOCIABLE regen hub avant triage. State persistant `state.json`. Coordination avec `/skill-store` + `/rule-cleaner` Workflow C.
- 2026-05-07 (matin) — Refonte page multi-dépôt skills. Auto-discover 12 dépôts (vs 2 hardcodés avant). Boutons toggle multi-target par skill. Action `duplicate` ajoutée. Format JSON décisions enrichi avec `target_repos[]` + `archive` + `rename` + `rework`. Skill rendu partageable (§6). Anti-pattern "filtre vs déplace" gravé.
- 2026-05-07 (soir) — **Extension périmètre = skills + CLAUDE.md**. Création `generate_claude_md_index.py` (scanne 19 CLAUDE.md sur 16 dépôts), `monitoring-center.html` (light theme, sections par dépôt avec sous-blocs `📁 CLAUDE.md` + `🛠 Skills`, modal édition textarea CLAUDE.md), `apply_changes.py` (backup + preview + confirmation + exécution unifiée). Format JSON exporté unifié `monitoring-changes-<ts>.json` avec `skills_decisions[]` + `claude_md_edits[]`. URL principale changée → `monitoring-center.html`. `skills-triage.html` reste vue dense alternative dark, cross-link ajouté dans header. Skill renamed `skill-checkup` → `checkup-skills-perso`, paths state.json corrigés.


---

## Fusionné depuis `checkup-skills-store` (2026-05-13)

Contenu préservé du skill `checkup-skills-store` archivé. Source originale: `.claude/skills/_archive/skills-archive/2026-05-13/checkup-skills-store/`

# Skill Store — Vivier de skills dormants

## Philosophie

**Problème** : chaque skill chargé = description en tokens × N sessions. Skills peu utilisés (1× / mois ou ponctuels) coûtent autant que skills quotidiens.

**Solution** : sortir skills dormants du chargement auto sans les supprimer. Stocker dans `skills-store/` (PAS scanné par Claude). INDEX.md = pointeur consultable on-demand.

**Workflow lazy-read** :
1. Skills actifs `.claude/skills/` → descriptions chargées chaque session (coût tokens)
2. Skills stockés `.claude/skills-store/` → PAS chargés (zéro coût tokens default)
3. INDEX.md `.claude/skills-store/INDEX.md` → 1 ligne par skill stocké (description résumée)
4. Si Claude/Florent cherche skill non trouvé → consulter INDEX → ressortir si match

---

## Architecture skills par scope (à connaître AVANT stocker/migrer)

**4 niveaux de scope** — du + universel au + restreint :

| Scope | Path | Quand utiliser |
|-------|------|----------------|
| **Global** | `~/.claude/skills/` | Universel cross-projets (legal-*, dispatch, recap, plan, swarm-*, rule-cleaner, skill-store, etc.) |
| **Projet racine** | `<projet>/.claude/skills/` | Spécifique projet entier — chargé partout dans le projet (auto-permission, widget, vosk-monitor pour SpeakApp) |
| **Sous-projet** | `<projet>/<sous-projet>/.claude/skills/` | Spécifique sous-projet — chargé seulement quand cwd dans sous-projet (claude-design-* → ALL Compagnies/Design/, youtube-* → ALL Compagnies/YouTube Channel/) |
| **Exception global** | `~/.claude/skills/` malgré spécificité projet | Cas exceptionnel quand utilité cross-PC > économie tokens (ex `speakapp-partners` global pour partage rapide associés) |

**Règle de placement** :
- Skill utilisé sur **TOUS projets** → global
- Skill utilisé sur **1 projet entier** → projet racine
- Skill utilisé sur **1 sous-dossier projet** → sous-projet (scope fin = économie tokens hors cwd)
- Hésitation projet vs sous-projet → projet racine (plus simple)

**Avantage scope fin** : skills sous-projet PAS chargés quand tu bosses ailleurs dans le projet → économie tokens descriptions.

## 2 niveaux de stores supportés

| Store | Path | Pour |
|-------|------|------|
| **Projet/Sous-projet** | `<scope>/.claude/skills-store/` | Skills dormants spécifiques scope |
| **Global** | `~/.claude/skills-store/` | Skills universels dormants (legal-*, infographic, etc.) |

**Règle stock** : skill stocké reste dans son scope d'origine. Skill global → store global. Skill projet/sous-projet → store du même scope.

---

## Workflow A — Stocker skill (sortir du chargement)

```bash
# 1. Vérifier scope skill (projet vs global)
ls .claude/skills/<skill-name> 2>/dev/null && SCOPE="projet" || SCOPE="global"

# 2. Move vers store
if [ "$SCOPE" = "projet" ]; then
  mv .claude/skills/<skill-name> .claude/skills-store/<skill-name>
  STORE_INDEX=".claude/skills-store/INDEX.md"
else
  mv ~/.claude/skills/<skill-name> ~/.claude/skills-store/<skill-name>
  STORE_INDEX="~/.claude/skills-store/INDEX.md"
fi

# 3. Ajouter ligne INDEX (description résumée 1 ligne)
# Format : | <skill-name> | <usage 1 phrase> | <quand récupérer> | <date stock> |

# 4. Commit (si projet) — sync (si global via /migration-pc)
git add .claude/skills-store/ && git commit -m "chore(store): stocker /<skill-name> (peu utilisé)"
```

## Workflow B — Récupérer skill (réactiver)

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
git add .claude/ && git commit -m "chore(store): ressortir /<skill-name> (réactivation)"
```

## Workflow C — Skill pas trouvé (lookup INDEX)

Quand Claude/Florent cherche skill `/X` non trouvé dans `/help` ou skills list :
1. Lire `.claude/skills-store/INDEX.md` projet
2. Lire `~/.claude/skills-store/INDEX.md` global
3. Match nom ou usage → proposer ressortir
4. Pas de match → skill n'existe vraiment pas, créer via `/skill-builder`

---

## Format INDEX.md

```markdown
# Skill Store — INDEX

> Skills stockés (pas chargés auto). Récupérer via `/skill-store récupérer <name>`.

| Skill | Usage 1 phrase | Quand récupérer | Stocké le |
|-------|---------------|-----------------|-----------|
| `cd-devtools-inject` | Inject JS dans DevTools console CD via clavier+clipboard | Re-investigation DevTools CD (deprecated BP-033) | 2026-05-02 |
| `python-migrate` | Procédure migration Python 3.X→3.Y avec gates rollback | Prochaine migration Python | 2026-05-02 |
| ... |
```

---

## Règles

1. **Stocker = pas supprimer** — `mv`, jamais `rm`. Skill récupérable à tout moment.
2. **INDEX 1 ligne par skill** — usage résumé bref. Détails restent dans SKILL.md du skill stocké.
3. **Scope intact** — skill projet → store projet. Skill global → store global. Pas de cross-scope sans raison.
4. **Commit atomique** — `mv` + INDEX update dans même commit.
5. **Pas de stock agressif** — skill utilisé même rarement (1× / 2 mois) reste actif si gain tokens marginal vs coût récupération.
6. **Lookup avant créer** — chercher dans INDEX (les 2) AVANT de créer skill nouveau (évite doublon avec stocké oublié).

---

## Anti-patterns

- ❌ `rm -rf .claude/skills/X` — perdu à jamais. Toujours `mv` vers store.
- ❌ Stocker sans MAJ INDEX — skill devient invisible (perdu sans grep).
- ❌ Stocker skill quotidien — gain tokens nul vs friction réactivation constante.
- ❌ Cross-scope mv (projet → store global) sans raison — perd contexte projet.
- ❌ Créer skill avant lookup INDEX — risque doublon avec stocké.

---

## Quand NE PAS utiliser

| Situation | Skill plutôt |
|-----------|--------------|
| Créer skill nouveau | `/skill-builder` |
| Audit/cleanup skills actifs | `/rule-cleaner` Workflow C |
| Renommer skill (cohérence préfixe) | `/rule-cleaner` §3ter |
| Supprimer définitivement skill | NE PAS — toujours stocker (récupérable plus tard) |

---

## Exemples

| Action | Commande |
|--------|----------|
| Stock projet `cd-devtools-inject` | `mv .claude/skills/cd-devtools-inject .claude/skills-store/` + INDEX add |
| Récup projet `python-migrate` | `mv .claude/skills-store/python-migrate .claude/skills/` + INDEX remove |
| Stock global `infographic` | `mv ~/.claude/skills/infographic ~/.claude/skills-store/` + INDEX global add |
| Lookup "skill pour debug GIL ?" | `cat .claude/skills-store/INDEX.md` → match `gil-thread-debug` → propose récup |
