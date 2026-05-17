---
name: checkup-routines-migrate
description: Migration routines `~/.claude/scheduled-tasks/` â†’ docs portables **dans le dÃ©pÃ´t actif** (cwd). DÃ©tection auto repo via git root, filtrage des routines par tag `repo:` (frontmatter SKILL.md) ou pattern slug. Phase 6 rehydrate, Phase 7 cloud optionnelle. Alias rÃ©tro-compat "/migrate-routines-to-docs".
type: skill
---

# Skill â€” migration-routines (locales â†’ docs portables â†’ autre compte local)

## âš ï¸ Convention dÃ©pÃ´t â€” TOUJOURS scope par dÃ©pÃ´t actif

**RÃ¨gle non-nÃ©gociable** : Florent travaille TOUJOURS sur un seul dÃ©pÃ´t Ã  la fois. La migration filtre par dÃ©faut au dÃ©pÃ´t actif. Cross-repo = `--all-repos` explicite.

### DÃ©tection du dÃ©pÃ´t actif

```bash
DEPOT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DEPOT_NAME=$(basename "$DEPOT_ROOT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
```

Annoncer : `Migration scopÃ©e au dÃ©pÃ´t **<DEPOT_NAME>** ($DEPOT_ROOT).`

### Filtrage routines â†’ dÃ©pÃ´t actif

Pour chaque `~/.claude/scheduled-tasks/<slug>/SKILL.md` :
- Lire frontmatter `repo:` â†’ si == `$DEPOT_NAME` â†’ garder
- Si `repo:` absent â†’ fallback pattern slug (table dans skill `/checkup-routines-run`) â†’ si match `$DEPOT_NAME` â†’ garder
- Sinon â†’ skip (routine d'un autre dÃ©pÃ´t)

### Storage par dÃ©pÃ´t (override path)

Output docs migration **dans le dÃ©pÃ´t actif** :
- `$DEPOT_ROOT/docs/routines/<slug>/00-contexte/<slug>-config.md`
- `$DEPOT_ROOT/docs/routines/README.md` (index par dÃ©pÃ´t)
- `$DEPOT_ROOT/memory/routines-inventory.md` (inventory par dÃ©pÃ´t)

**Plus de chemin global** `~/.claude/routines-docs/` (legacy 2026-05-08 â€” sera retirÃ© quand tous les dÃ©pÃ´ts auront leur version locale).

### Modes invocation

```
/migrate-routines-to-docs               # full pipeline (Phase 1-5) sur dÃ©pÃ´t actif uniquement
/migrate-routines-to-docs check         # inventaire + classification scope dÃ©pÃ´t actif
/migrate-routines-to-docs <slug>        # une seule routine (skip filtre dÃ©pÃ´t)
/migrate-routines-to-docs rehydrate     # Phase 6 â€” recrÃ©e routines en local depuis docs DU DÃ‰PÃ”T actif
/migrate-routines-to-docs cloud         # Phase 7 OPTIONNELLE â€” push cloud RemoteTrigger
/migrate-routines-to-docs --all-repos   # cross-repo (rare, explicite)
/migrate-routines-to-docs --repo <slug> # scope un autre dÃ©pÃ´t explicite
```

## Usage

```
/migrate-routines-to-docs           # Migration complÃ¨te (Phase 1-5)
/migrate-routines-to-docs check     # Phase 1+2 seulement â€” inventaire + classification
/migrate-routines-to-docs <slug>    # Migre une seule routine
/migrate-routines-to-docs rehydrate # Phase 6 â€” recrÃ©e routines en LOCAL sur compte courant depuis docs
/migrate-routines-to-docs cloud     # Phase 7 OPTIONNELLE â€” pousse en cloud Anthropic Remote Trigger
```

## âš ï¸ Ne PAS confondre les deux systÃ¨mes

| SystÃ¨me | C'est quoi | Outil | Stockage |
|---------|-----------|-------|----------|
| **MCP scheduled-tasks LOCAL** | TÃ¢ches qui tournent dans Claude Code/Desktop sur la machine | `mcp__scheduled-tasks__create_scheduled_task` | `~/.claude/scheduled-tasks/<slug>/SKILL.md` |
| **Anthropic Remote Trigger CLOUD** | Routines qui tournent dans l'infra Anthropic via API | Skill `/schedule` + tool `RemoteTrigger` | API claude.ai (visible https://claude.ai/code/routines) |

**Le scope par dÃ©faut de ce skill = LOCAL.** L'objectif est de migrer les routines locales d'un compte Claude Code Ã  un autre via un repo GitHub intermÃ©diaire (export configs â†’ pull sur compte cible â†’ recrÃ©ation MCP locale).

Le cloud (Phase 7) est une option secondaire â€” Ã  ne lancer que si Florent demande explicitement.

## Guide de rÃ©fÃ©rence

Lire `docs/guide-routines-claude.md` AVANT d'exÃ©cuter la phase 3.
Structure cible par routine : `~/.claude/routines-docs/<domaine>/<slug>/00-contexte/<slug>-config.md`

---

## Phase 1 â€” Inventaire

```bash
ls /c/Users/Administrateur/.claude/scheduled-tasks/ | sort | wc -l
```

Pour chaque dossier dans `~/.claude/scheduled-tasks/*/SKILL.md` :
- Extraire `name` et `description` (frontmatter YAML)
- Extraire le schedule/cron (chercher : `cron:`, `tous les jours`, `daily`, `weekly`, `hourly`, `hebdo`, `mensuel`, pattern `0 [0-9]`)
- DÃ©tecter si la routine est morte/annulÃ©e (desc contient : `ANNULÃ‰`, `REMPLACÃ‰`, `FAIT`, `dÃ©sactivÃ©`, `ANNULÃ‰E`)

Afficher tableau Markdown :

```
| # | Slug | Statut | Domaine | Schedule | Description courte |
|---|------|--------|---------|----------|-------------------|
```

Statuts : `ACTIVE` / `MORTE` / `ONE-SHOT` (investigation ponctuelle, jamais rÃ©currente)

---

## Phase 2 â€” Classification

Grouper les 64 routines par domaine :

| Domaine | Pattern de dÃ©tection |
|---------|---------------------|
| `speakapp` | slug prÃ©fixÃ© `speakapp-` |
| `orchestration` | `orchestrateur-*`, `auto-[1-9]-*`, `cc-pipeline-*` |
| `business` | attestation, malt, gladia, cfe, inpi, intel, is-*, credit-* |
| `design` | `claude-design-*`, `linkedin-*` |
| `maintenance` | delete-tab-groups, email-digest, daily-email, marketplace, youtube, vosk-weekly, comfort-mirror, overnight-*, check-antigravity |
| `other` | tout le reste |

Routines mortes/one-shot connues (NE PAS migrer vers cloud Routines) :
- `attestation-regularite-fiscale` â€” ANNULÃ‰
- `inpi-cessation-activite` â€” REMPLACÃ‰
- `intel-warranty-followup` â€” dÃ©sactivÃ©
- `is-deadline-last-chance` â€” ANNULÃ‰
- `is-declaration-zero-rappel` â€” FAIT
- `speakapp-bisect-crash-ucrtbase-fastfail` â€” investigation one-shot
- `speakapp-bp098-v11-spawned-log-missing` â€” investigation one-shot
- `speakapp-overnight-run-01-tts-metric` â€” run one-shot terminÃ©
- `check-antigravity-forum-reply` â€” check one-shot
- `linkedin-post-claude-design` â€” rappel one-shot
- `gladia-nego-round2` â€” nÃ©gociation one-shot
- `wisper-deploy-live` â€” dÃ©ploiement one-shot

**Si mode `check` â†’ STOP ici.** Afficher tableau complet + comptes par domaine.

---

## Phase 3 â€” Conversion SKILL.md â†’ fichier contexte

Pour chaque routine ACTIVE (non morte, non one-shot), crÃ©er :

```
~/.claude/routines-docs/<domaine>/<slug>/00-contexte/<slug>-config.md
```

### Template fichier contexte (8 sections)

```markdown
# <Nom lisible de la routine> â€” Configuration

> **Slug MCP local** : `<slug>`
> **Domaine** : `<domaine>`
> **Statut** : ACTIVE

## âš ï¸ PrÃ©-requis critiques

- **Schedule** : <cron ou description humaine du dÃ©clencheur>
- **ModÃ¨le recommandÃ©** : <Opus 4.7 si tÃ¢che cognitive complexe, sinon Sonnet 4.6>
- **Connecteurs MCP** : <liste des connecteurs nÃ©cessaires dÃ©tectÃ©s dans le SKILL.md>
- **DÃ©pendances locales** : <fichiers/paths locaux rÃ©fÃ©rencÃ©s, le cas Ã©chÃ©ant>

## 1. Contexte business

<1-2 phrases : projet concernÃ© (SpeakApp / Marketplace / Personnel), qui est Florent, pourquoi cette routine existe dans le systÃ¨me global>

## 2. Objectif

<Description directe de l'objectif â€” reprendre `description` du frontmatter SKILL.md + reformulation si trop courte>

## 3. Architecture (flux haut niveau)

<3-6 Ã©tapes numÃ©rotÃ©es extraites du contenu SKILL.md â€” vision macro>

## 4. Sources et cibles

<D'oÃ¹ viennent les donnÃ©es (fichiers logs, JSONL, API, GitHub, Notionâ€¦) et oÃ¹ vont les rÃ©sultats (rapport MD, Notion, email, roadmapâ€¦)>

## 5. ProcÃ©dure dÃ©taillÃ©e

<Contenu complet du SKILL.md original â€” coller tel quel, c'est le cerveau de la routine>

## 6. RÃ¨gles strictes

<Extraire les contraintes, rÃ¨gles, garde-fous mentionnÃ©s dans le SKILL.md. Si aucune rÃ¨gle explicite, Ã©crire :>
- Lire les fichiers sources AVANT toute action
- Ne pas modifier le code de production
- Signaler UNIQUEMENT si anomalie dÃ©tectÃ©e (pas de rapport "tout va bien" verbeux)
- Ne jamais supprimer de donnÃ©es sans confirmation explicite

## 7. Format du livrable

<DÃ©crire ce que la routine doit produire : rapport MD, sous-page Notion, email, commit, pushâ€¦
Si le SKILL.md mentionne un format de sortie â†’ le reprendre exactement>

## 8. Gestion des erreurs

<Que faire si une source est indisponible / un fichier manque / un API Ã©choue.
Si non explicitÃ© dans le SKILL.md, Ã©crire :>
- Source indisponible â†’ logger l'erreur, ne pas planter, continuer avec les sources disponibles
- Aucune donnÃ©e dans la pÃ©riode â†’ produire quand mÃªme un rapport vide datÃ©
- Erreur sur un item â†’ skipper et continuer (pas d'arrÃªt brutal)

---

## Prompt claude.ai/code (court)

> Coller ce bloc dans le champ "Instructions" lors de la crÃ©ation de la routine sur claude.ai/code.

```
Tu exÃ©cutes la routine "<Nom lisible>" pour le projet <projet>.

Ã‰TAPE 1 â€” CHARGEMENT DU CONTEXTE
Lis intÃ©gralement le fichier `<slug>/00-contexte/<slug>-config.md`
du dÃ©pÃ´t clonÃ©. Ce fichier contient la procÃ©dure complÃ¨te.

Ã‰TAPE 2 â€” EXÃ‰CUTION
ExÃ©cute la routine selon les instructions du fichier de contexte.
Respecte toutes les rÃ¨gles de la Â§6.

Ã‰TAPE 3 â€” LIVRABLE
<1 phrase : type de livrable attendu>

Ã‰TAPE 4 â€” CONFIRMATION
En fin d'exÃ©cution, afficher :
- Statut : SUCCÃˆS / PARTIEL / Ã‰CHEC
- RÃ©sumÃ© en 2-3 lignes
- Lien(s) vers le(s) livrable(s) crÃ©Ã©(s) si applicable
```
```

### RÃ¨gles de conversion

1. **ModÃ¨le** : tÃ¢ches cognitives complexes (synthÃ¨se, analyse logs, rÃ©daction) â†’ Opus 4.7. TÃ¢ches dÃ©terministes (grep, count, health check basique) â†’ Sonnet 4.6.
2. **Connecteurs** : dÃ©tecter dans le SKILL.md les mentions de Notion, Gmail, GitHub, Slack, Chrome, Supabase â†’ les lister en Â§1.
3. **DÃ©pendances locales** : si le SKILL.md rÃ©fÃ©rence des paths locaux (`logs/`, `memory/`, `tools/`) â†’ noter en Â§1 que la routine nÃ©cessite accÃ¨s dÃ©pÃ´t GitHub + contexte local (donc candidat MCP local plutÃ´t que cloud pur).
4. **Ne pas inventer** : si une section n'a pas de contenu dans le SKILL.md source â†’ le dire explicitement ("Non spÃ©cifiÃ© dans la version locale â€” Ã  complÃ©ter").

---

## Phase 4 â€” Dispatch parallÃ¨le

Traiter les routines par batch de 8 via `/dispatch` pour aller vite. Exemple :

```
Batch A : speakapp-agent-vocal-daily, speakapp-autoperm-daily, speakapp-chat-reader-daily, speakapp-notif-pipeline-daily, speakapp-stt-daily, speakapp-pilote-ia-daily, speakapp-plan-reader-daily, speakapp-question-handler-daily
Batch B : speakapp-dictee-contextuelle-healthcheck, speakapp-dictionnaire-intelligent-daily, speakapp-doc-sync-audit-weekly, speakapp-kb-maintenance, speakapp-monthly-platform-audit, speakapp-prd-coherence-weekly, speakapp-qa-daily, speakapp-skill-launcher-daily
...
```

---

## Phase 5 â€” Index global

CrÃ©er `~/.claude/routines-docs/README.md` :

```markdown
# Routines Claude â€” Index de migration

> GÃ©nÃ©rÃ© par `/migrate-routines-to-docs` le YYYY-MM-DD
> Source : `~/.claude/scheduled-tasks/` (N routines)
> Cible : recrÃ©ation locale via MCP `mcp__scheduled-tasks__` sur compte Claude Code de destination

## RÃ©sumÃ©

| Domaine | Actives | Mortes/One-shot | Total |
|---------|---------|-----------------|-------|
| speakapp | N | N | N |
| orchestration | N | N | N |
| business | N | N | N |
| design | N | N | N |
| maintenance | N | N | N |
| **TOTAL** | **N** | **N** | **N** |

## Index complet

| Slug | Domaine | Statut | Schedule | ModÃ¨le | Doc contexte |
|------|---------|--------|----------|--------|-------------|
| <slug> | <domaine> | ACTIVE | <cron> | Opus 4.7/Sonnet 4.6 | [lien](<domaine>/<slug>/00-contexte/<slug>-config.md) |

## Workflow migration LOCAL â†’ LOCAL (recommandÃ©)

**Compte source (export terminÃ©)** :
1. Configs crÃ©Ã©es en `~/.claude/routines-docs/`
2. `git add . && git commit -m "feat: export N routines" && git push`
3. **NE PAS supprimer `~/.claude/scheduled-tasks/`** avant validation cÃ´tÃ© cible (Phase 6 confirmÃ©e)

**Compte cible (rehydration locale)** :
1. `git pull` sur la machine cible
2. Lancer `/migrate-routines-to-docs rehydrate` â†’ recrÃ©e chaque routine via MCP `mcp__scheduled-tasks__create_scheduled_task`
3. VÃ©rifier dans `~/.claude/scheduled-tasks/` que les N dossiers sont lÃ 
4. Compte source : maintenant safe de supprimer les locales si centralisation voulue
```

---

## Phase 6 â€” Rehydration LOCAL (recrÃ©er routines via MCP scheduled-tasks)

> **Quand l'utiliser** : sur le compte CIBLE aprÃ¨s `git pull` du repo. RecrÃ©e les routines comme tÃ¢ches MCP locales.

### Ã‰tape 1 â€” Charger l'outil MCP

Le tool `mcp__scheduled-tasks__create_scheduled_task` doit Ãªtre disponible sur la machine cible. Si pas dans la liste des tools loaded, faire `ToolSearch select:create_scheduled_task` d'abord.

### Ã‰tape 2 â€” Pour chaque config.md, recrÃ©er

Boucler sur tous les `~/.claude/routines-docs/<domaine>/<slug>/00-contexte/<slug>-config.md` :

1. **Parser le config.md** â€” extraire :
   - `slug` (depuis `> **Slug MCP local** : <slug>`)
   - `schedule` (depuis `## âš ï¸ PrÃ©-requis critiques` Â§ Schedule)
   - `description` (depuis `## 2. Objectif` 1Ã¨re ligne)
   - `prompt` complet (extraire **Â§5 ProcÃ©dure dÃ©taillÃ©e** = contenu SKILL.md original)

2. **Appeler le MCP** :
   ```
   mcp__scheduled-tasks__create_scheduled_task(
     name=<slug>,
     description=<description courte>,
     prompt=<contenu Â§5 du config.md>,
     schedule=<expression cron ou humaine>
   )
   ```

3. **Valider** : vÃ©rifier que `~/.claude/scheduled-tasks/<slug>/SKILL.md` existe.

### Ã‰tape 3 â€” Dispatch parallÃ¨le

Comme Phase 4, batch de 8 via `/dispatch` pour aller vite. VÃ©rification finale `Get-ChildItem ~/.claude/scheduled-tasks/ -Directory | Measure-Object`.

### Anti-pattern Ã  Ã©viter

- âŒ Ne PAS Ã©crire directement dans `~/.claude/scheduled-tasks/<slug>/SKILL.md` (le MCP gÃ¨re le manifest interne).
- âŒ Ne PAS appeler `/schedule` ou `RemoteTrigger create` (Ã§a crÃ©e du cloud Anthropic, pas du local).
- âœ… Toujours passer par `mcp__scheduled-tasks__create_scheduled_task`.

### âš ï¸ PiÃ¨ge â€” suppression dÃ©finitive via fichiers AppData (mÃ©thode validÃ©e 2026-05-13)

`Remove-Item ~/.claude/scheduled-tasks/<slug>/` **NE supprime PAS** la routine du store interne du MCP. Le store rÃ©el est dans **AppData**, pas dans `~/.claude/scheduled-tasks/`.

**OÃ¹ vit le vrai store :**
```
C:\Users\Utilisateur\AppData\Roaming\Claude\claude-code-sessions\<session-uuid>\<run-uuid>\scheduled-tasks.json
```
Plusieurs fichiers (`Glob **\scheduled-tasks.json` dans `AppData\Roaming\Claude\`) â€” le MCP agrÃ¨ge toutes les sessions. Fichier secondaire : `~/.claude/.scheduled-tasks-cache.json` (cache local, Ã  vider aussi).

**ProcÃ©dure de purge complÃ¨te :**

1. Trouver tous les stores :
   ```powershell
   Get-ChildItem "$env:APPDATA\Claude" -Recurse -Filter "scheduled-tasks.json" | Select FullName
   ```

2. Backup (optionnel) :
   ```powershell
   Copy-Item <path>\scheduled-tasks.json <path>\scheduled-tasks.json.bak
   ```

3. Vider chaque fichier trouvÃ© (Ã©crire `{"scheduledTasks": []}`) + vider le cache :
   ```powershell
   '{"scheduledTasks": []}' | Set-Content -Path "<path>\scheduled-tasks.json" -Encoding UTF8
   '[]' | Set-Content -Path "$env:USERPROFILE\.claude\.scheduled-tasks-cache.json" -Encoding UTF8
   ```

4. **RedÃ©marrer Claude Code** â€” le MCP charge les fichiers au dÃ©marrage (pas de live-reload). AprÃ¨s restart, `list_scheduled_tasks` retourne `[]`.

**Note** : le MCP n'expose que `list / create / update` â€” pas de `delete`. L'UI Claude Code (sidebar scheduled tasks â†’ delete) fonctionne aussi mais nÃ©cessite Computer Use pour 38+ entrÃ©es.

---

## Phase 7 â€” Suivi statut PENDING / LIVE (compte cible cloud)

**Source unique de vÃ©ritÃ©** : `docs/routines-migration/README.md` (dÃ©pÃ´t speak-app-dev)

Chaque routine dans les tables individuelles a une colonne `Statut` :
- `â³ PENDING` â€” config doc prÃªte, routine PAS encore crÃ©Ã©e sur claude.ai/code
- `âœ… LIVE (YYYY-MM-DD)` â€” routine crÃ©Ã©e et active sur le compte cible

### Consulter le statut en un coup d'Å“il

```bash
# Toutes les PENDING
grep "PENDING" docs/routines-migration/README.md

# Toutes les LIVE
grep "LIVE" docs/routines-migration/README.md

# Comptes
grep -c "PENDING" docs/routines-migration/README.md
grep -c "LIVE" docs/routines-migration/README.md
```

### Marquer une routine LIVE aprÃ¨s crÃ©ation sur claude.ai/code

1. Ã‰diter `docs/routines-migration/README.md`
2. Trouver la ligne de la routine â†’ changer `â³ PENDING` â†’ `âœ… LIVE (YYYY-MM-DD)`
3. Mettre Ã  jour le tableau rÃ©cap en haut du README (PENDING -1, LIVE +1)
4. Commit : `docs: mark <slug> LIVE on claude.ai/code`

Exemple aprÃ¨s crÃ©ation :
```
| `speakapp-stt-daily` | daily | Sonnet 4.6 | âœ… LIVE (2026-05-12) | [lien](...) |
```

### Workflow crÃ©ation sur claude.ai/code (par routine PENDING)

1. Ouvrir https://claude.ai/code/scheduled â†’ "New Routine"
2. Copier le bloc **"Prompt claude.ai/code"** depuis `docs/routines-migration/<domaine>/<slug>/00-contexte/<slug>-config.md`
3. RÃ©gler le schedule + modÃ¨le (voir colonnes Schedule/ModÃ¨le dans README)
4. Activer la routine
5. Marquer `âœ… LIVE` dans README + commit

âš ï¸ Routines Ã  NE PAS migrer vers cloud (garder local uniquement) :
- `routines-watchdog-hebdo` â€” nÃ©cessite `mcp__scheduled-tasks__list_scheduled_tasks`
- `speakapp-scheduled-tasks-selfcheck` â€” nÃ©cessite `mcp__scheduled-tasks__list_scheduled_tasks`
- `speakapp-monthly-platform-audit` â€” Computer Use local
- `delete-tab-groups-4am` â€” Computer Use local

**Pour la migration entre comptes** : ce piÃ¨ge est sans impact. Sur le compte cible, le MCP a son propre store vide. La rehydration via Phase 6 crÃ©e les routines dans CE store. Les fantÃ´mes du compte source restent visuellement lÃ  tant que Florent ne les delete pas manuellement, mais ils sont inactifs (`enabled: false`) donc inoffensifs.

---

## Phase 7 â€” Cloud Anthropic Remote Trigger (OPTIONNEL)

> **Quand l'utiliser** : SEULEMENT si Florent demande explicitement Â« pousse en cloud Â» / Â« routines remote Â». Par dÃ©faut, ne PAS lancer cette phase.

### âš ï¸ Distinction critique

- **Phase 6 (LOCAL)** = MCP `mcp__scheduled-tasks__` â†’ tourne sur la machine de Florent dans Claude Code/Desktop
- **Phase 7 (CLOUD)** = `/schedule` + `RemoteTrigger` â†’ tourne dans l'infra Anthropic, visible https://claude.ai/code/routines

Les 2 ne sont PAS interchangeables. Le cloud nÃ©cessite que le repo soit poussÃ© sur GitHub et accessible Ã  `claude.ai/code` (Install GitHub App).

### Ã‰tape â€” invoquer `/schedule` skill

Le skill cloud a son propre workflow (load `RemoteTrigger`, batch de 10, stagger cron pour max 4 simultanÃ©es, etc.). Voir le SKILL.md de `/schedule` directement.

**PrÃ©-requis cloud** :
- Repo GitHub privÃ© existant (avec `~/.claude/routines-docs/` pushÃ©)
- GitHub App Anthropic installÃ©e sur claude.ai/code â†’ ParamÃ¨tres â†’ GitHub
- Connecteurs MCP cloud connectÃ©s si routine en a besoin (Notion/Gmail/etc.) â†’ https://claude.ai/customize/connectors

---

## VÃ©rification finale

### Mode normal (Phase 1-5 export uniquement)

```bash
# Compter les fichiers gÃ©nÃ©rÃ©s
find docs/routines-migration -name "*-config.md" | wc -l
# Doit correspondre au nombre de routines ACTIVE (total - mortes - one-shot)

# Spot-check 3 routines
ls ~/.claude/routines-docs/speakapp/speakapp-stt-daily/00-contexte/
ls ~/.claude/routines-docs/orchestration/orchestrateur-synthese-hebdo/00-contexte/
ls ~/.claude/routines-docs/maintenance/email-digest-matin/00-contexte/
```

Chaque fichier doit avoir les 8 sections + bloc "Prompt claude.ai/code".

### Mode rehydrate (aprÃ¨s Phase 6)

```powershell
(Get-ChildItem "$env:USERPROFILE\.claude\scheduled-tasks\" -Directory).Count
# Doit correspondre au nombre de configs migrÃ©es
```
