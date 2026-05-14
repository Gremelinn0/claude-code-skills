---
name: checkup-routines-migrate
description: Migration routines `~/.claude/scheduled-tasks/` → docs portables **dans le dépôt actif** (cwd). Détection auto repo via git root, filtrage des routines par tag `repo:` (frontmatter SKILL.md) ou pattern slug. Phase 6 rehydrate, Phase 7 cloud optionnelle. Alias rétro-compat "/migrate-routines-to-docs".
type: skill
---

# Skill — migration-routines (locales → docs portables → autre compte local)

## ⚠️ Convention dépôt — TOUJOURS scope par dépôt actif

**Règle non-négociable** : Florent travaille TOUJOURS sur un seul dépôt à la fois. La migration filtre par défaut au dépôt actif. Cross-repo = `--all-repos` explicite.

### Détection du dépôt actif

```bash
DEPOT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DEPOT_NAME=$(basename "$DEPOT_ROOT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
```

Annoncer : `Migration scopée au dépôt **<DEPOT_NAME>** ($DEPOT_ROOT).`

### Filtrage routines → dépôt actif

Pour chaque `~/.claude/scheduled-tasks/<slug>/SKILL.md` :
- Lire frontmatter `repo:` → si == `$DEPOT_NAME` → garder
- Si `repo:` absent → fallback pattern slug (table dans skill `/checkup-routines-run`) → si match `$DEPOT_NAME` → garder
- Sinon → skip (routine d'un autre dépôt)

### Storage par dépôt (override path)

Output docs migration **dans le dépôt actif** :
- `$DEPOT_ROOT/docs/routines/<slug>/00-contexte/<slug>-config.md`
- `$DEPOT_ROOT/docs/routines/README.md` (index par dépôt)
- `$DEPOT_ROOT/memory/routines-inventory.md` (inventory par dépôt)

**Plus de chemin global** `~/.claude/routines-docs/` (legacy 2026-05-08 — sera retiré quand tous les dépôts auront leur version locale).

### Modes invocation

```
/migrate-routines-to-docs               # full pipeline (Phase 1-5) sur dépôt actif uniquement
/migrate-routines-to-docs check         # inventaire + classification scope dépôt actif
/migrate-routines-to-docs <slug>        # une seule routine (skip filtre dépôt)
/migrate-routines-to-docs rehydrate     # Phase 6 — recrée routines en local depuis docs DU DÉPÔT actif
/migrate-routines-to-docs cloud         # Phase 7 OPTIONNELLE — push cloud RemoteTrigger
/migrate-routines-to-docs --all-repos   # cross-repo (rare, explicite)
/migrate-routines-to-docs --repo <slug> # scope un autre dépôt explicite
```

## Usage

```
/migrate-routines-to-docs           # Migration complète (Phase 1-5)
/migrate-routines-to-docs check     # Phase 1+2 seulement — inventaire + classification
/migrate-routines-to-docs <slug>    # Migre une seule routine
/migrate-routines-to-docs rehydrate # Phase 6 — recrée routines en LOCAL sur compte courant depuis docs
/migrate-routines-to-docs cloud     # Phase 7 OPTIONNELLE — pousse en cloud Anthropic Remote Trigger
```

## ⚠️ Ne PAS confondre les deux systèmes

| Système | C'est quoi | Outil | Stockage |
|---------|-----------|-------|----------|
| **MCP scheduled-tasks LOCAL** | Tâches qui tournent dans Claude Code/Desktop sur la machine | `mcp__scheduled-tasks__create_scheduled_task` | `~/.claude/scheduled-tasks/<slug>/SKILL.md` |
| **Anthropic Remote Trigger CLOUD** | Routines qui tournent dans l'infra Anthropic via API | Skill `/schedule` + tool `RemoteTrigger` | API claude.ai (visible https://claude.ai/code/routines) |

**Le scope par défaut de ce skill = LOCAL.** L'objectif est de migrer les routines locales d'un compte Claude Code à un autre via un repo GitHub intermédiaire (export configs → pull sur compte cible → recréation MCP locale).

Le cloud (Phase 7) est une option secondaire — à ne lancer que si Florent demande explicitement.

## Guide de référence

Lire `docs/guide-routines-claude.md` AVANT d'exécuter la phase 3.
Structure cible par routine : `~/.claude/routines-docs/<domaine>/<slug>/00-contexte/<slug>-config.md`

---

## Phase 1 — Inventaire

```bash
ls /c/Users/Administrateur/.claude/scheduled-tasks/ | sort | wc -l
```

Pour chaque dossier dans `~/.claude/scheduled-tasks/*/SKILL.md` :
- Extraire `name` et `description` (frontmatter YAML)
- Extraire le schedule/cron (chercher : `cron:`, `tous les jours`, `daily`, `weekly`, `hourly`, `hebdo`, `mensuel`, pattern `0 [0-9]`)
- Détecter si la routine est morte/annulée (desc contient : `ANNULÉ`, `REMPLACÉ`, `FAIT`, `désactivé`, `ANNULÉE`)

Afficher tableau Markdown :

```
| # | Slug | Statut | Domaine | Schedule | Description courte |
|---|------|--------|---------|----------|-------------------|
```

Statuts : `ACTIVE` / `MORTE` / `ONE-SHOT` (investigation ponctuelle, jamais récurrente)

---

## Phase 2 — Classification

Grouper les 64 routines par domaine :

| Domaine | Pattern de détection |
|---------|---------------------|
| `speakapp` | slug préfixé `speakapp-` |
| `orchestration` | `orchestrateur-*`, `auto-[1-9]-*`, `cc-pipeline-*` |
| `business` | attestation, malt, gladia, cfe, inpi, intel, is-*, credit-* |
| `design` | `claude-design-*`, `linkedin-*` |
| `maintenance` | delete-tab-groups, email-digest, daily-email, marketplace, youtube, vosk-weekly, comfort-mirror, overnight-*, check-antigravity |
| `other` | tout le reste |

Routines mortes/one-shot connues (NE PAS migrer vers cloud Routines) :
- `attestation-regularite-fiscale` — ANNULÉ
- `inpi-cessation-activite` — REMPLACÉ
- `intel-warranty-followup` — désactivé
- `is-deadline-last-chance` — ANNULÉ
- `is-declaration-zero-rappel` — FAIT
- `speakapp-bisect-crash-ucrtbase-fastfail` — investigation one-shot
- `speakapp-bp098-v11-spawned-log-missing` — investigation one-shot
- `speakapp-overnight-run-01-tts-metric` — run one-shot terminé
- `check-antigravity-forum-reply` — check one-shot
- `linkedin-post-claude-design` — rappel one-shot
- `gladia-nego-round2` — négociation one-shot
- `wisper-deploy-live` — déploiement one-shot

**Si mode `check` → STOP ici.** Afficher tableau complet + comptes par domaine.

---

## Phase 3 — Conversion SKILL.md → fichier contexte

Pour chaque routine ACTIVE (non morte, non one-shot), créer :

```
~/.claude/routines-docs/<domaine>/<slug>/00-contexte/<slug>-config.md
```

### Template fichier contexte (8 sections)

```markdown
# <Nom lisible de la routine> — Configuration

> **Slug MCP local** : `<slug>`
> **Domaine** : `<domaine>`
> **Statut** : ACTIVE

## ⚠️ Pré-requis critiques

- **Schedule** : <cron ou description humaine du déclencheur>
- **Modèle recommandé** : <Opus 4.7 si tâche cognitive complexe, sinon Sonnet 4.6>
- **Connecteurs MCP** : <liste des connecteurs nécessaires détectés dans le SKILL.md>
- **Dépendances locales** : <fichiers/paths locaux référencés, le cas échéant>

## 1. Contexte business

<1-2 phrases : projet concerné (SpeakApp / Marketplace / Personnel), qui est Florent, pourquoi cette routine existe dans le système global>

## 2. Objectif

<Description directe de l'objectif — reprendre `description` du frontmatter SKILL.md + reformulation si trop courte>

## 3. Architecture (flux haut niveau)

<3-6 étapes numérotées extraites du contenu SKILL.md — vision macro>

## 4. Sources et cibles

<D'où viennent les données (fichiers logs, JSONL, API, GitHub, Notion…) et où vont les résultats (rapport MD, Notion, email, roadmap…)>

## 5. Procédure détaillée

<Contenu complet du SKILL.md original — coller tel quel, c'est le cerveau de la routine>

## 6. Règles strictes

<Extraire les contraintes, règles, garde-fous mentionnés dans le SKILL.md. Si aucune règle explicite, écrire :>
- Lire les fichiers sources AVANT toute action
- Ne pas modifier le code de production
- Signaler UNIQUEMENT si anomalie détectée (pas de rapport "tout va bien" verbeux)
- Ne jamais supprimer de données sans confirmation explicite

## 7. Format du livrable

<Décrire ce que la routine doit produire : rapport MD, sous-page Notion, email, commit, push…
Si le SKILL.md mentionne un format de sortie → le reprendre exactement>

## 8. Gestion des erreurs

<Que faire si une source est indisponible / un fichier manque / un API échoue.
Si non explicité dans le SKILL.md, écrire :>
- Source indisponible → logger l'erreur, ne pas planter, continuer avec les sources disponibles
- Aucune donnée dans la période → produire quand même un rapport vide daté
- Erreur sur un item → skipper et continuer (pas d'arrêt brutal)

---

## Prompt claude.ai/code (court)

> Coller ce bloc dans le champ "Instructions" lors de la création de la routine sur claude.ai/code.

```
Tu exécutes la routine "<Nom lisible>" pour le projet <projet>.

ÉTAPE 1 — CHARGEMENT DU CONTEXTE
Lis intégralement le fichier `<slug>/00-contexte/<slug>-config.md`
du dépôt cloné. Ce fichier contient la procédure complète.

ÉTAPE 2 — EXÉCUTION
Exécute la routine selon les instructions du fichier de contexte.
Respecte toutes les règles de la §6.

ÉTAPE 3 — LIVRABLE
<1 phrase : type de livrable attendu>

ÉTAPE 4 — CONFIRMATION
En fin d'exécution, afficher :
- Statut : SUCCÈS / PARTIEL / ÉCHEC
- Résumé en 2-3 lignes
- Lien(s) vers le(s) livrable(s) créé(s) si applicable
```
```

### Règles de conversion

1. **Modèle** : tâches cognitives complexes (synthèse, analyse logs, rédaction) → Opus 4.7. Tâches déterministes (grep, count, health check basique) → Sonnet 4.6.
2. **Connecteurs** : détecter dans le SKILL.md les mentions de Notion, Gmail, GitHub, Slack, Chrome, Supabase → les lister en §1.
3. **Dépendances locales** : si le SKILL.md référence des paths locaux (`logs/`, `memory/`, `tools/`) → noter en §1 que la routine nécessite accès dépôt GitHub + contexte local (donc candidat MCP local plutôt que cloud pur).
4. **Ne pas inventer** : si une section n'a pas de contenu dans le SKILL.md source → le dire explicitement ("Non spécifié dans la version locale — à compléter").

---

## Phase 4 — Dispatch parallèle

Traiter les routines par batch de 8 via `/dispatch` pour aller vite. Exemple :

```
Batch A : speakapp-agent-vocal-daily, speakapp-autoperm-daily, speakapp-chat-reader-daily, speakapp-notif-pipeline-daily, speakapp-stt-daily, speakapp-pilote-ia-daily, speakapp-plan-reader-daily, speakapp-question-handler-daily
Batch B : speakapp-dictee-contextuelle-healthcheck, speakapp-dictionnaire-intelligent-daily, speakapp-doc-sync-audit-weekly, speakapp-kb-maintenance, speakapp-monthly-platform-audit, speakapp-prd-coherence-weekly, speakapp-qa-daily, speakapp-skill-launcher-daily
...
```

---

## Phase 5 — Index global

Créer `~/.claude/routines-docs/README.md` :

```markdown
# Routines Claude — Index de migration

> Généré par `/migrate-routines-to-docs` le YYYY-MM-DD
> Source : `~/.claude/scheduled-tasks/` (N routines)
> Cible : recréation locale via MCP `mcp__scheduled-tasks__` sur compte Claude Code de destination

## Résumé

| Domaine | Actives | Mortes/One-shot | Total |
|---------|---------|-----------------|-------|
| speakapp | N | N | N |
| orchestration | N | N | N |
| business | N | N | N |
| design | N | N | N |
| maintenance | N | N | N |
| **TOTAL** | **N** | **N** | **N** |

## Index complet

| Slug | Domaine | Statut | Schedule | Modèle | Doc contexte |
|------|---------|--------|----------|--------|-------------|
| <slug> | <domaine> | ACTIVE | <cron> | Opus 4.7/Sonnet 4.6 | [lien](<domaine>/<slug>/00-contexte/<slug>-config.md) |

## Workflow migration LOCAL → LOCAL (recommandé)

**Compte source (export terminé)** :
1. Configs créées en `~/.claude/routines-docs/`
2. `git add . && git commit -m "feat: export N routines" && git push`
3. **NE PAS supprimer `~/.claude/scheduled-tasks/`** avant validation côté cible (Phase 6 confirmée)

**Compte cible (rehydration locale)** :
1. `git pull` sur la machine cible
2. Lancer `/migrate-routines-to-docs rehydrate` → recrée chaque routine via MCP `mcp__scheduled-tasks__create_scheduled_task`
3. Vérifier dans `~/.claude/scheduled-tasks/` que les N dossiers sont là
4. Compte source : maintenant safe de supprimer les locales si centralisation voulue
```

---

## Phase 6 — Rehydration LOCAL (recréer routines via MCP scheduled-tasks)

> **Quand l'utiliser** : sur le compte CIBLE après `git pull` du repo. Recrée les routines comme tâches MCP locales.

### Étape 1 — Charger l'outil MCP

Le tool `mcp__scheduled-tasks__create_scheduled_task` doit être disponible sur la machine cible. Si pas dans la liste des tools loaded, faire `ToolSearch select:create_scheduled_task` d'abord.

### Étape 2 — Pour chaque config.md, recréer

Boucler sur tous les `~/.claude/routines-docs/<domaine>/<slug>/00-contexte/<slug>-config.md` :

1. **Parser le config.md** — extraire :
   - `slug` (depuis `> **Slug MCP local** : <slug>`)
   - `schedule` (depuis `## ⚠️ Pré-requis critiques` § Schedule)
   - `description` (depuis `## 2. Objectif` 1ère ligne)
   - `prompt` complet (extraire **§5 Procédure détaillée** = contenu SKILL.md original)

2. **Appeler le MCP** :
   ```
   mcp__scheduled-tasks__create_scheduled_task(
     name=<slug>,
     description=<description courte>,
     prompt=<contenu §5 du config.md>,
     schedule=<expression cron ou humaine>
   )
   ```

3. **Valider** : vérifier que `~/.claude/scheduled-tasks/<slug>/SKILL.md` existe.

### Étape 3 — Dispatch parallèle

Comme Phase 4, batch de 8 via `/dispatch` pour aller vite. Vérification finale `Get-ChildItem ~/.claude/scheduled-tasks/ -Directory | Measure-Object`.

### Anti-pattern à éviter

- ❌ Ne PAS écrire directement dans `~/.claude/scheduled-tasks/<slug>/SKILL.md` (le MCP gère le manifest interne).
- ❌ Ne PAS appeler `/schedule` ou `RemoteTrigger create` (ça crée du cloud Anthropic, pas du local).
- ✅ Toujours passer par `mcp__scheduled-tasks__create_scheduled_task`.

### ⚠️ Piège — suppression définitive via fichiers AppData (méthode validée 2026-05-13)

`Remove-Item ~/.claude/scheduled-tasks/<slug>/` **NE supprime PAS** la routine du store interne du MCP. Le store réel est dans **AppData**, pas dans `~/.claude/scheduled-tasks/`.

**Où vit le vrai store :**
```
C:\Users\Administrateur\AppData\Roaming\Claude\claude-code-sessions\<session-uuid>\<run-uuid>\scheduled-tasks.json
```
Plusieurs fichiers (`Glob **\scheduled-tasks.json` dans `AppData\Roaming\Claude\`) — le MCP agrège toutes les sessions. Fichier secondaire : `~/.claude/.scheduled-tasks-cache.json` (cache local, à vider aussi).

**Procédure de purge complète :**

1. Trouver tous les stores :
   ```powershell
   Get-ChildItem "$env:APPDATA\Claude" -Recurse -Filter "scheduled-tasks.json" | Select FullName
   ```

2. Backup (optionnel) :
   ```powershell
   Copy-Item <path>\scheduled-tasks.json <path>\scheduled-tasks.json.bak
   ```

3. Vider chaque fichier trouvé (écrire `{"scheduledTasks": []}`) + vider le cache :
   ```powershell
   '{"scheduledTasks": []}' | Set-Content -Path "<path>\scheduled-tasks.json" -Encoding UTF8
   '[]' | Set-Content -Path "$env:USERPROFILE\.claude\.scheduled-tasks-cache.json" -Encoding UTF8
   ```

4. **Redémarrer Claude Code** — le MCP charge les fichiers au démarrage (pas de live-reload). Après restart, `list_scheduled_tasks` retourne `[]`.

**Note** : le MCP n'expose que `list / create / update` — pas de `delete`. L'UI Claude Code (sidebar scheduled tasks → delete) fonctionne aussi mais nécessite Computer Use pour 38+ entrées.

---

## Phase 7 — Suivi statut PENDING / LIVE (compte cible cloud)

**Source unique de vérité** : `docs/routines-migration/README.md` (dépôt speak-app-dev)

Chaque routine dans les tables individuelles a une colonne `Statut` :
- `⏳ PENDING` — config doc prête, routine PAS encore créée sur claude.ai/code
- `✅ LIVE (YYYY-MM-DD)` — routine créée et active sur le compte cible

### Consulter le statut en un coup d'œil

```bash
# Toutes les PENDING
grep "PENDING" docs/routines-migration/README.md

# Toutes les LIVE
grep "LIVE" docs/routines-migration/README.md

# Comptes
grep -c "PENDING" docs/routines-migration/README.md
grep -c "LIVE" docs/routines-migration/README.md
```

### Marquer une routine LIVE après création sur claude.ai/code

1. Éditer `docs/routines-migration/README.md`
2. Trouver la ligne de la routine → changer `⏳ PENDING` → `✅ LIVE (YYYY-MM-DD)`
3. Mettre à jour le tableau récap en haut du README (PENDING -1, LIVE +1)
4. Commit : `docs: mark <slug> LIVE on claude.ai/code`

Exemple après création :
```
| `speakapp-stt-daily` | daily | Sonnet 4.6 | ✅ LIVE (2026-05-12) | [lien](...) |
```

### Workflow création sur claude.ai/code (par routine PENDING)

1. Ouvrir https://claude.ai/code/scheduled → "New Routine"
2. Copier le bloc **"Prompt claude.ai/code"** depuis `docs/routines-migration/<domaine>/<slug>/00-contexte/<slug>-config.md`
3. Régler le schedule + modèle (voir colonnes Schedule/Modèle dans README)
4. Activer la routine
5. Marquer `✅ LIVE` dans README + commit

⚠️ Routines à NE PAS migrer vers cloud (garder local uniquement) :
- `routines-watchdog-hebdo` — nécessite `mcp__scheduled-tasks__list_scheduled_tasks`
- `speakapp-scheduled-tasks-selfcheck` — nécessite `mcp__scheduled-tasks__list_scheduled_tasks`
- `speakapp-monthly-platform-audit` — Computer Use local
- `delete-tab-groups-4am` — Computer Use local

**Pour la migration entre comptes** : ce piège est sans impact. Sur le compte cible, le MCP a son propre store vide. La rehydration via Phase 6 crée les routines dans CE store. Les fantômes du compte source restent visuellement là tant que Florent ne les delete pas manuellement, mais ils sont inactifs (`enabled: false`) donc inoffensifs.

---

## Phase 7 — Cloud Anthropic Remote Trigger (OPTIONNEL)

> **Quand l'utiliser** : SEULEMENT si Florent demande explicitement « pousse en cloud » / « routines remote ». Par défaut, ne PAS lancer cette phase.

### ⚠️ Distinction critique

- **Phase 6 (LOCAL)** = MCP `mcp__scheduled-tasks__` → tourne sur la machine de Florent dans Claude Code/Desktop
- **Phase 7 (CLOUD)** = `/schedule` + `RemoteTrigger` → tourne dans l'infra Anthropic, visible https://claude.ai/code/routines

Les 2 ne sont PAS interchangeables. Le cloud nécessite que le repo soit poussé sur GitHub et accessible à `claude.ai/code` (Install GitHub App).

### Étape — invoquer `/schedule` skill

Le skill cloud a son propre workflow (load `RemoteTrigger`, batch de 10, stagger cron pour max 4 simultanées, etc.). Voir le SKILL.md de `/schedule` directement.

**Pré-requis cloud** :
- Repo GitHub privé existant (avec `~/.claude/routines-docs/` pushé)
- GitHub App Anthropic installée sur claude.ai/code → Paramètres → GitHub
- Connecteurs MCP cloud connectés si routine en a besoin (Notion/Gmail/etc.) → https://claude.ai/customize/connectors

---

## Vérification finale

### Mode normal (Phase 1-5 export uniquement)

```bash
# Compter les fichiers générés
find docs/routines-migration -name "*-config.md" | wc -l
# Doit correspondre au nombre de routines ACTIVE (total - mortes - one-shot)

# Spot-check 3 routines
ls ~/.claude/routines-docs/speakapp/speakapp-stt-daily/00-contexte/
ls ~/.claude/routines-docs/orchestration/orchestrateur-synthese-hebdo/00-contexte/
ls ~/.claude/routines-docs/maintenance/email-digest-matin/00-contexte/
```

Chaque fichier doit avoir les 8 sections + bloc "Prompt claude.ai/code".

### Mode rehydrate (après Phase 6)

```powershell
(Get-ChildItem "$env:USERPROFILE\.claude\scheduled-tasks\" -Directory).Count
# Doit correspondre au nombre de configs migrées
```
