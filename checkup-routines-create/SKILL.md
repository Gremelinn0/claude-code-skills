---
name: checkup-routines-create
description: Crée, gère, migre **et lance on-demand** les routines Claude Code (cloud ou locale) **toujours scopées au dépôt actif (cwd)**. Détection auto repo via git root + frontmatter `repo:` canonique. Création propre du premier coup + connecteurs MCP + repo GitHub + vérif visuelle. Migration routines locales → docs GitHub format cloud. Run on-demand sub-agents Sonnet batch. Alias /migrate-routines-to-docs et /run-all-routines (fusionné 2026-05-08) intégrés.
---

# /routine-create — Routines Claude Code (création + audit + migration)

## ⚠️ Phase 0bis — Documents-first + question compte seulement à la propagation (NON-NÉGOCIABLE, gravée 2026-05-13, refonte 2026-05-16)

**Règle centrale** : toutes les routines (cloud + locales) sont **représentées par un document** dans le repo (`~/.claude/scheduled-tasks/<slug>/SKILL.md` pour les locales, ou doc équivalent pour les cloud — cf Phase 1). Les docs sont la **source unique** : ils décrivent la routine (cron, prompt, scope, critères), ils sont consultables et modifiables à tout moment depuis n'importe quel compte. La propagation document → routine vivante (côté Anthropic remote trigger ou MCP local) est centralisée sur **UN SEUL compte Claude = main account routines** (Florent verbatim 2026-05-13 : *"toutes les routines je les centralise sur un compte uniquement"*).

### MAIN_ACCOUNT_ROUTINES_EMAIL = `florent.maisoncelle@gmail.com`

(constante gravée 2026-05-13. Synced cross-PC via skill `/migration-pc`.)

### Règle de comportement par défaut (refonte 2026-05-16)

**Florent verbatim 2026-05-16** :
> *"Par défaut, quand je te parle de créer une routine, tu me demandes sur quel compte on est. Tu fais pas la vérification toi-même, parce que tu sais pas. Sauf si tu me dis que tu sais. Vu que tu sais pas, par défaut, autant que tu créés directement le document avec le skill. Et moi, j'appelle le skill quand je suis sur le bon compte, fin d'histoire. Toutes les routines passent par des documents, ce qui te permet de consulter directement les routines pour les modifier depuis les documents. Dès que je te parle de routine, tu vas chercher le document de la routine. La question du compte, c'est juste pour la création à proprement parler. Quand on me demande de créer une routine, tu vérifies d'abord les routines existantes et tu modifies la bonne routine. Si elle n'existe pas, tu la crées."*

**Workflow par défaut quand Florent dit "crée routine X" (ordre strict)** :

1. **Lire d'abord les routines existantes** = scanner `~/.claude/scheduled-tasks/` (locales) + lister docs cloud si tracées dans le repo. Vérifier si une routine couvre déjà le besoin (slug proche, objectif similaire, même feature/scope).
2. **Si une routine existante matche le besoin** → **modifier le document existant** (cron, prompt, scope, critères). Pas de duplication. Annoncer à Florent : *"Routine `<slug>` existante MAJ — relance le skill sur le bon compte pour propager"*.
3. **Si aucune routine ne matche** → **créer le document** complet (slug + 5 champs canoniques Phase 0bis ter + procédure). Annoncer : *"Document `<slug>` créé — relance le skill sur le bon compte pour activation"*.
4. **NE PAS** essayer d'activer/propager côté Anthropic ou MCP. Cette étape (propagation document → routine vivante) est ce qui exige le bon compte, et **c'est Florent qui appelle le skill quand il est sur le main account**, point.

**Pour TOUT le reste (consulter, modifier, auditer, comprendre une routine existante)** → libre accès, pas de question, je lis et modifie les documents directement. C'est ça l'intérêt du pattern document-first.

### La question du compte = uniquement à la propagation

**Quand est-ce que la question du compte se pose ?** Une seule situation : quand on essaie d'activer/propager une routine du document vers la vraie infra (cloud Anthropic ou MCP local). C'est l'étape finale, et c'est Florent qui la déclenche en appelant `/checkup-routines-create` (ou `/schedule create` pour cloud direct) sur le main account.

**Si Florent me dit explicitement "je suis sur le main account, propage"** → OK je peux exécuter la propagation directement (Phase 1 cloud ou Phase 2 locale ci-dessous).

**Si Florent ne le dit pas et que je dois propager** → je lui pose une question courte : *"Pour propager la routine côté infra, je dois savoir si tu es sur le main account routines (florent.maisoncelle@gmail.com) ou un autre compte. Tu es sur lequel ?"* Je ne devine jamais via `userEmail` ou autre signal silencieux — je demande.

**Si Florent confirme compte secondaire** → je n'active rien, j'appende la demande dans `backlog.md` (Phase 0bis bis) et je préviens : *"Compte secondaire — demande notée dans backlog, sera propagée au prochain appel /checkup-routines-create depuis le main account"*. Le document de la routine reste créé/modifié dans le repo (ça ne demande pas le main account).

### Anti-patterns interdits

- ❌ Deviner le compte via `userEmail` silencieux ou autre signal → **JE DEMANDE, point**
- ❌ Créer un document de routine en double parce que j'ai pas vérifié l'existant d'abord → **je liste avant de créer, toujours**
- ❌ Refuser de modifier le document d'une routine existante sous prétexte du compte → **le document est modifiable depuis n'importe quel compte**, c'est juste la propagation qui exige le main
- ❌ Tenter de propager (cloud / MCP) sans vérification explicite du compte par Florent → **demander d'abord**
- ❌ Stocker backlog ailleurs que `~/.claude/skills/checkup-routines-create/backlog.md` (1 source unique synced /migration-pc)
- ❌ Affirmer "toutes les routines sont désactivées" comme une généralité — **faux**, sur le main account elles vivent. C'est juste une règle d'isolation par compte, pas une désactivation.

---

## Phase 0bis bis — Format `backlog.md`

Append-only. Une demande = 1 bloc YAML+md. Template :

```markdown
## <slug-routine> — <date YYYY-MM-DD>

**Statut** : 🟢 open (sera `✅ traité YYYY-MM-DD commit <hash>` après exec main account)
**Compte secondaire source** : <email>
**Type** : create | optimize | verify-existing | audit
**Cadence souhaitée** : <cron daily 3h-5h Paris | hebdo | mensuel | one-shot fireAt | ad-hoc>
**Skill orchestrateur invoqué dans prompt** : `/test-X` ou `/audit-Y` ou direct
**Repo concerné** : <slug-repo, ex `speak-app-dev`>

### Objectif fonctionnel
<2-3 lignes : quoi, pourquoi, output attendu>

### Critères de vérification
- <critère 1>
- <critère 2>

### Notes / contexte
<lien feature doc, BP référence, conversation Florent, etc.>
```

**Workflow main account consommation** :
1. Read `backlog.md` → liste entries `🟢 open`
2. Pour chaque entry : vérifier si routine EXISTE déjà côté cloud (`RemoteTrigger list`) OU locale (`~/.claude/scheduled-tasks/<slug>/`)
   - Si existe + matche specs backlog → marquer `✅ existante` (pas re-créer, juste audit Phase 2.5)
   - Si manquante → créer via Phase 1 (cloud) ou Phase 2 (local) selon critères
   - Si existe mais drift (cron différent, prompt obsolète) → optimize via `RemoteTrigger update` Phase 1.5
3. Marquer entrée traitée dans backlog : `[✅ traité YYYY-MM-DD commit <hash>]` + `Statut : ✅ traité`
4. Commit backlog.md changes (compte main → push automatique via `/migration-pc`)

---

## ⚠️ PARAMÈTRES CANONIQUES D'UNE ROUTINE — RÈGLES NON-NÉGOCIABLES (gravées 2026-05-08)

Toute routine = exactement **5 champs**. Pas plus, pas moins. Pas d'invention.

| # | Champ | Règle |
|---|-------|-------|
| 1 | **taskId** | Slug kebab-case (ex : `speakapp-stt-daily`). Identifie la routine de manière unique. |
| 2 | **prompt** | ⚠️ **JAMAIS de prompt direct/verbatim**. Toujours référence à un skill OU à un document. Ex : `Invoque le skill /xyz` OU `Lis le document <path>/<file>.md et exécute la procédure §5`. La logique vit dans le skill/doc, pas dupliquée dans la routine. |
| 3 | **mode** | 3 choix mutuellement exclusifs : **ad-hoc** (manuel, pas de cron, déclenché via skill) · **cron auto** (récurrent — ⚠️ **TOUJOURS via skill `/schedule`**, jamais via `mcp__scheduled-tasks__create` direct avec cronExpression) · **one-time** (`fireAt` ISO timestamp). |
| 4 | **repo** | Tag dépôt canonique dans frontmatter SKILL.md (ex : `repo: speak-app-dev`). Source unique du dépôt d'appartenance. Plus de fallback pattern. |
| 5 | **enabled** | `true` (active) ou `false` (pause sans suppression). |

### Règles d'or non-négociables

**RÈGLE 1 — Prompt = skill ou doc, JAMAIS verbatim** : la procédure complète vit dans un skill (`~/.claude/skills/<name>/SKILL.md`) ou un document (`docs/routines/<slug>/...config.md`). La routine se contente d'invoquer la référence. Sinon → duplication, drift, maintenance impossible.

**RÈGLE 2 — Cron = skill `/schedule`, JAMAIS direct MCP** : pour programmer un cron récurrent, passer obligatoirement par le skill builtin `/schedule` (cloud RemoteTrigger) qui gère la programmation propre. Ne PAS appeler `mcp__scheduled-tasks__create_scheduled_task` avec `cronExpression` directement.

**RÈGLE 3 — Mode ad-hoc = MCP local OK** : pour une routine manuelle (pas de cron), `mcp__scheduled-tasks__create_scheduled_task` SANS `cronExpression` ni `fireAt` est OK (mode "ad-hoc Manual only").

**RÈGLE 4 — Repo tag obligatoire** : toute routine créée DOIT avoir `repo: <slug-dépôt>` dans son frontmatter. Pas d'exception.

**RÈGLE 5 — Scope dépôt actif** : voir Convention dépôt ci-dessous.

**RÈGLE 6 — Routines locales = horaires de NUIT obligatoires (gravée 2026-05-09)** : toute routine locale (MCP scheduled-tasks) utilise directement le PC de Florent (Computer Use, focus écran, sub-agents Sonnet, navigation Chrome, etc.). Florent ne doit PAS être dérangé pendant son travail diurne. **Cron par défaut entre 3h00 et 5h00 du matin (heure locale Paris)**. Étalement automatique toutes les 2-3 minutes pour répartir N routines sur la fenêtre 3h-5h. Florent verbatim 2026-05-09 : *"ça doit tourner la nuit parce que ça utilise mon ordinateur directement et que ça a besoin du champ libre"*. Exceptions autorisées : routines vraiment instantanées sans focus écran (ex: grep pur sur fichier, pas de sub-agent) — à justifier au cas par cas dans le SKILL.md.

**RÈGLE 6 — Rapport local OBLIGATOIRE (gravée 2026-05-11)** : toute nouvelle routine DOIT avoir une section `### Rapport local (OBLIGATOIRE)` dans son SKILL.md qui force l'écriture du rapport de run dans `memory/reports/<slug>-<YYYY-MM-DD>.md` (ajouter `-<HHmm>` si cron horaire/sub-daily). Sans cette section, la routine va tourner silencieusement au cron, son output disparaîtra et personne ne saura ce qui se passe — c'est le bug systémique détecté 2026-05-11 sur 19 routines `speakapp-*` dont les SKILL.md étaient tronqués à 100-660 octets utiles (cf rapport `memory/reports/CATEGORY-SpeakApp-features-2026-05-09.md`). Format canonique de la section : voir Phase 2.4 ci-dessous. La validation gate Phase 1.4bis bloque la finalisation si la section est absente.

---

## ⚠️ Convention dépôt — TOUJOURS scope par dépôt actif

**Règle non-négociable** : Florent travaille TOUJOURS sur un seul dépôt à la fois. Toute création/audit/migration de routine est par défaut **scopée au dépôt actif** (cwd).

### Détection du dépôt actif

```bash
DEPOT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DEPOT_NAME=$(basename "$DEPOT_ROOT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
DEPOT_REPO_URL=$(git -C "$DEPOT_ROOT" remote get-url origin 2>/dev/null)
```

Annoncer à Florent dès le début : `Routines scopées au dépôt **<DEPOT_NAME>**.`

### Tagging routine → dépôt (frontmatter canonique)

Toute routine créée DOIT avoir `repo:` dans son frontmatter SKILL.md :

```yaml
---
name: <slug>
description: <desc>
repo: speak-app-dev          # ← TAG DÉPÔT canonique (kebab-case = $DEPOT_NAME)
---
```

Pour les routines cloud (`RemoteTrigger create`) : le repo est dans `session_context.sources.git_repository.url`. Le tag dépôt = nom court de ce repo.

### Storage par dépôt (override des chemins par défaut)

Toute documentation/inventory générée par ce skill va dans le dépôt actif :
- Inventory : `<DEPOT_ROOT>/memory/routines-inventory.md`
- Docs structurés : `<DEPOT_ROOT>/docs/routines/<slug>/00-contexte/<slug>-config.md`
- Active routines registry : `<DEPOT_ROOT>/memory/active-routines.md`

**Plus d'output global** dans `~/.claude/routines-docs/` ou `~/.claude/routines-inventory.md` (legacy 2026-05-08 — à archiver/migrer).

### Mapping fallback slug → repo (rétro-compat routines existantes sans frontmatter)

Voir skill `/checkup-routines-run` § "Convention dépôt" pour la table complète.

## TL;DR — modes disponibles

| Invocation | Ce que ça fait |
|---|---|
| `/routine-create` | Créer une nouvelle routine (cloud ou locale) |
| `/routine-create audit` | Auditer toutes les routines cloud existantes |
| `/routine-create migrate` | Migrer routines locales → docs GitHub format cloud |
| `/routine-create migrate check` | Inventaire + classification seulement (pas de génération) |
| `/routine-create migrate <slug>` | Migrer une seule routine |
| `/routine-create run [scope]` | **Lance** on-demand toutes routines locales du dépôt actif via sub-agents Sonnet (Phase 5 ci-dessous) |
| `/routine-create run --all-repos` | Run cross-repo (rare, explicite) |
| `/migrate-routines-to-docs` | Alias rétro-compat → même chose que `migrate` |
| `/run-all-routines` | Alias rétro-compat → redirige vers `run` ci-dessus (fusionné 2026-05-08) |
| `/schedule run <slug>` | Pour lancer une routine **CLOUD** (RemoteTrigger) — skill builtin Anthropic, distinct du local |

**Workflow création** : Phase 0 (cloud/local ?) → Phase 1 (cloud) OU Phase 2 (local) → Phase 1.4 (vérif visuelle) → Phase 3 (enregistrement + watchdog).

**Modification existante** : TOUJOURS `RemoteTrigger get` → modifier → `RemoteTrigger update` body ENTIER. Jamais partiel (Phase 1.5).

**Migration** : Phase M1 (inventaire) → M2 (classification) → M3 (conversion) → M4 (dispatch) → M5 (index).

---

## Phase 0 — Décider cloud ou local

**Cloud (défaut)** quand la tâche n'a besoin que de :
- APIs web, SaaS (Gmail, Drive, Notion…)
- Recherche web, analyse texte, drafts
- Écriture fichiers dans repo GitHub attaché

**Local (forcé)** quand la tâche a besoin de :
- Fichiers Windows locaux sur le PC
- Computer Use (clic écran)
- Chrome MCP avec sessions/cookies personnelles
- Python local, scripts spécifiques au PC
- Tout ce qui suppose la machine allumée

**Si hésitation** : cloud d'abord, replier local si dépendance locale découverte.

---

## Matrice de capacités — ce que RemoteTrigger permet

### ✅ Modifiable via `update`

| Champ | Exemple validé |
|---|---|
| **Modèle** | `claude-sonnet-4-5` → autre modèle |
| **Prompt** | Réécrire `events[0].data.message.content` |
| **Cron** | Changer `cron_expression` (UTC, min 1h) |
| **Repo GitHub** | Ajouter/changer `session_context.sources.git_repository.url` |
| **`allowed_tools`** | Ajouter/retirer tools |
| **Connecteurs MCP** | Ajouter/retirer dans `mcp_connections` |
| **État actif** | `enabled: true/false` |
| **Nom** | Renommer via `name` |

### ❌ Non-faisable via API
- Découvrir UUID d'un connecteur neuf → astuce Phase 0 obligatoire
- Voir historique d'exécution → uniquement web UI
- Lister connecteurs MCP du compte → https://claude.ai/settings/connectors

### Astuce UUID — débloquer un connecteur neuf

1. Florent crée 1 routine manuellement sur https://claude.ai/code/scheduled avec le connecteur voulu
2. `RemoteTrigger get <trigger_id>` → lire `mcp_connections[].connector_uuid` + `url` + `name`
3. Sauvegarder dans `memory/reference_mcp_connector_uuids.md`

**UUIDs Florent déjà captés** (account `396ceaa2-9b3c-40e5-9e12-14b05f4692ba`) :
- **Gmail** : `4ea3ada1-92a3-4085-84c1-cf184fdd5fd1` — `https://gmailmcp.googleapis.com/mcp/v1`
- **Google-Drive** : `ab2affa6-e372-4a20-bcd4-46d76a9b4193` — `https://drivemcp.googleapis.com/mcp/v1`
- **Notion** : `decc5ebf-9cb1-424d-aeb1-45f165a0842b` — `https://mcp.notion.com/mcp`

---

## Phase 1 — Routine CLOUD

### 1. Inputs obligatoires

- **Nom** : slug kebab-case (`malt-digest-matin-cloud`)
- **Cron UTC** : min 1h. Ex : `0 6 * * 1-5` (jours ouvrés 6h UTC)
- **Prompt complet** : comportement, sources, output attendu
- **Connecteurs** : parmi `gmail`, `drive`, `notion`
- **Repo GitHub** : repo local ouvert dans la session

### 2. Choisir le modèle

- **Sonnet 4.5** (défaut) : health checks, grep, count, tâches déterministes
- **Opus 4.7** : synthèse cognitive, analyse logs complexe, rédaction créative — uniquement si explicitement nécessaire

### 3. Construire le body et créer

```json
{
  "name": "<nom-routine>",
  "cron_expression": "<cron UTC>",
  "enabled": true,
  "job_config": {
    "ccr": {
      "environment_id": "env_01PTAfZ28fETTQwtdN88mzXT",
      "events": [{"data": {"message": {"content": "<PROMPT>", "role": "user"}, "type": "user"}}],
      "session_context": {
        "allowed_tools": ["WebSearch", "WebFetch", "Read", "Write"],
        "model": "claude-sonnet-4-5",
        "sources": [{"git_repository": {"url": "https://github.com/<owner>/<repo>", "allow_unrestricted_git_push": true}}]
      }
    }
  },
  "mcp_connections": [
    {"connector_uuid": "<uuid>", "name": "<Name-kebab>", "url": "<mcp-url>", "permitted_tools": []}
  ]
}
```

Appeler via `RemoteTrigger` action `create`. Le `name` d'un connecteur MCP = `[a-zA-Z0-9_-]` uniquement (`Google-Drive`, pas `Google Drive`).

### 4. Vérification visuelle post-création (NON OPTIONNELLE)

Chrome MCP → https://claude.ai/code/scheduled. Vérifier sur la carte :
1. Bon nom + bon cron
2. Tag repo affiché
3. Connecteurs listés (icônes Gmail/Notion/Google-Drive)
4. Bon modèle (cliquer la carte pour voir)

KO → corriger via `RemoteTrigger update` ou UI web si API insuffit.

---

## Phase 1.5 — PIÈGE CRITIQUE : update partiel efface `events`

**Bug prod 2026-04-22. Ne jamais reproduire.**

Si le body d'un `update` ne contient PAS `events` → `events` est écrasé à vide silencieusement. Prompt disparu, aucun warning API.

### Règle absolue pour tout `update`

1. `RemoteTrigger get <trigger_id>` → config actuelle
2. Modifier uniquement le champ ciblé
3. Renvoyer le body ENTIER via `update`

### Body minimum obligatoire

```json
{
  "name": "<nom>",
  "cron_expression": "<cron>",
  "enabled": true,
  "job_config": {
    "ccr": {
      "environment_id": "env_01PTAfZ28fETTQwtdN88mzXT",
      "events": [{"data": {"message": {"content": "<PROMPT COMPLET>", "role": "user"}, "type": "user"}}],
      "session_context": {
        "allowed_tools": ["..."],
        "model": "claude-sonnet-4-5",
        "sources": [{"git_repository": {"url": "...", "allow_unrestricted_git_push": true}}]
      }
    }
  },
  "mcp_connections": [{"connector_uuid": "...", "name": "...", "url": "...", "permitted_tools": []}]
}
```

### Récupération si prompt effacé

1. `RemoteTrigger get` → confirmer `events` vide
2. Retrouver prompt original : historique session → `memory/active-routines.md` → demander Florent (pire cas)
3. `update` complet avec events + session_context restaurés
4. Vérif visuelle https://claude.ai/code/scheduled

---

## Phase 2 — Routine LOCALE

Utiliser `mcp__scheduled-tasks__create_scheduled_task`. Stockage auto dans `~/.claude/scheduled-tasks/<taskId>/SKILL.md`.

Permet : Chrome MCP sessions personnelles, Computer Use, filesystem Windows, Python local.

Vérif post-création : tâche visible dans sidebar "Scheduled" de Claude Code desktop.

⚠️ **Le SKILL.md généré DOIT contenir la section "### Rapport local (OBLIGATOIRE)" canonique** (voir Phase 2.4 ci-dessous). C'est NON-NÉGOCIABLE. Sans elle, la routine tourne silencieusement et son output disparaît → bug systémique 2026-05-11 (19 routines `speakapp-*` tronquées). Validation gate Phase 1.4bis bloque la finalisation si absente.

---

## Phase 2.4 — Template canonique SKILL.md routine locale (gravée 2026-05-11)

**Toute routine locale créée DOIT suivre ce template strict.** Le contenu peut être adapté à la mission, mais les **5 sections obligatoires** (frontmatter + Mission + Étapes + Rapport local + Note 2026-05-09) DOIVENT être présentes.

### Template

```markdown
---
name: <slug>
description: <1 phrase mission>
repo: <repo-slug>          # ex: speak-app-dev (RÈGLE 4)
---

## <slug> — <Nom lisible>

Projet : <chemin absolu repo>

### Mission
<2-4 lignes : quoi, pourquoi, output attendu>

### Étapes
1. <étape 1>
2. <étape 2>
3. <étape 3>
...
N. Si aucune anomalie détectée : écrire "no action — OK" et exit

### Rapport local (OBLIGATOIRE)
Écrire dans `memory/reports/<slug>-<YYYY-MM-DD>.md` (10-20 lignes) :
- Date/heure run
- Métriques clés (nombre items analysés, success rate, etc.)
- Top 3 patterns détectés (ou "rien à signaler")
- Actions prises (hash commit si modif) OU "no action — OK"
- Actions recommandées pour orchestrateur

**Note 2026-05-09** : publication Notion retirée. Notion = équipe uniquement. Les rapports restent locaux dans `memory/reports/`.
```

### Règles de path rapport

- **Cron daily / weekly / monthly / ad-hoc** → `memory/reports/<slug>-<YYYY-MM-DD>.md`
- **Cron horaire ou sub-daily** → `memory/reports/<slug>-<YYYY-MM-DD>-<HHmm>.md` (évite écrasement multi-runs même jour)
- **One-shot ponctuel** → `memory/reports/<slug>-<YYYY-MM-DD>.md` + commentaire "one-shot" dans le rapport

### Pourquoi cette règle est non-négociable (contexte 2026-05-11)

19 routines `speakapp-*` dans `~/.claude/scheduled-tasks/` ont été détectées avec SKILL.md tronqués à 100-660 octets utiles. Conséquence : routines tournaient au cron, mais le prompt n'avait pas d'instruction "écris ton rapport dans `memory/reports/...`". Résultat = rapports invisibles, drift silencieux, impossible de savoir ce qui se passait. Fix immédiat : 20 SKILL.md réécrits via sub-agents. Mais sans cette règle gravée dans le skill `/checkup-routines-create`, toute nouvelle routine retombait dans le piège dès le lendemain.

Référence : `memory/reports/CATEGORY-SpeakApp-features-2026-05-09.md` (analyse causale).

---

## Phase 1.4bis — Validation gate "Rapport local" (NON OPTIONNELLE — gravée 2026-05-11)

**Avant d'annoncer la routine créée à Florent, exécuter cette validation gate sur le SKILL.md généré.**

### Check obligatoire

```bash
SKILL_PATH="$HOME/.claude/scheduled-tasks/<slug>/SKILL.md"
grep -q "### Rapport local (OBLIGATOIRE)" "$SKILL_PATH" && \
grep -q "memory/reports/" "$SKILL_PATH" && \
grep -q "Note 2026-05-09" "$SKILL_PATH"
```

### Verdict

- **3/3 PASS** → finalisation OK, annoncer routine créée à Florent.
- **≥1 FAIL** → **REFUSER finalisation**. Output strict : `❌ Routine <slug> SKILL.md incomplet — section "### Rapport local (OBLIGATOIRE)" manquante. Patch obligatoire avant activation. Cf skill /checkup-routines-create Phase 2.4 template.` Puis appliquer le patch via `Edit` sur le SKILL.md généré → re-run gate → annoncer OK.

### Anti-pattern interdit

- ❌ Annoncer "routine créée" sans avoir passé cette gate.
- ❌ Skipper la gate "parce que c'est trivial".
- ❌ Considérer la note 2026-05-09 comme optionnelle (signal de drift Notion vs local — doit rester gravée).
- ❌ Mettre la section dans une autre partie du SKILL.md que `### Rapport local (OBLIGATOIRE)` (le check `grep` exact bloque le mauvais nommage).

---

## Phase 2.6 — Routines OVERNIGHT avec Computer Use (gravée 2026-05-06)

> **Contexte** : Florent dort à partir de 18h. Routines locales avec Computer Use peuvent tourner overnight, mais 1 seul écran principal = pas de parallélisme Computer Use possible.

### Règles non-négociables overnight Computer Use

1. **Étalement temporel obligatoire** — 1h minimum entre 2 routines Computer Use. Pas de parallélisme. Cron staggered (18h00, 19h00, 20h00, etc.).

2. **Mode bypass permission max** — chaque routine overnight DOIT démarrer par toggle `permissions.defaultMode: bypassPermissions` dans `settings.json` ON, et restore OFF en `finally` à la fin. Sinon dialog `request_access` bloque la routine.

3. **Whitelist apps obligatoire** — pas de bypass perm aveugle. Whitelist explicite dans le prompt routine :
   ```
   Apps autorisées Computer Use : AntiGravity, Claude (CD), Chrome, SpeakApp.
   Refuser tout autre app demandé. Logger refus dans logs/routine-grants.jsonl.
   Refuser tout grant systemKeyCombos automatique.
   ```

4. **Fenêtre temporelle** — cron entre 18h00 et 06h00 uniquement (Florent dort). Hors fenêtre = abort silent (vérifier `datetime.now().hour` au début).

5. **Audit log obligatoire** — chaque routine append dans `logs/routine-grants.jsonl` :
   ```json
   {"ts":"...","routine":"<slug>","apps_requested":[...],"apps_granted":[...],"verdict":"PASS|FAIL|ABORT"}
   ```

6. **Setup une fois, tournent seules** — Florent setup en 1 fois (ce skill), puis routines tournent automatiquement via cron Windows. Pas d'activation manuelle quotidienne.

7. **Lifecycle bypass perm** :
   ```python
   # Début routine
   try:
       settings = json.load(open("~/.claude/settings.json"))
       _orig_mode = settings.get("permissions", {}).get("defaultMode", "default")
       settings["permissions"]["defaultMode"] = "bypassPermissions"
       json.dump(settings, open("~/.claude/settings.json", "w"))
       # ... routine logic ...
   finally:
       settings["permissions"]["defaultMode"] = _orig_mode
       json.dump(settings, open("~/.claude/settings.json", "w"))
   ```

### Pattern routine overnight Computer Use

**Frontmatter SKILL.md** :
```yaml
---
name: <slug>-overnight
schedule: "0 <H> 1 * *"  # mensuel ou daily selon besoin
description: <action> via Computer Use overnight (Florent dort). Bypass perm + whitelist apps.
overnight: true
computer_use: true
apps_whitelist: ["AntiGravity", "Claude", "Chrome", "SpeakApp"]
---
```

**Prompt routine canonique** :
```
🎯 OBJECTIF : <action> via Computer Use.

⏰ FENÊTRE : 18h-06h uniquement. Si hors fenêtre → abort.

🔒 SECURITY :
1. Toggle permissions.defaultMode=bypassPermissions ON (start)
2. Whitelist apps : [AntiGravity, Claude, Chrome, SpeakApp]
3. Refuse tout autre app + tout grant systemKeyCombos
4. Audit log logs/routine-grants.jsonl
5. Restore permissions.defaultMode original (finally)

📝 ACTION : <détail tâche>

📦 LIVRABLE : <fichier MAJ + commit>

✅ PASS : <critère>
```

### Étalement canonique 5 plateformes (audit settings mensuel exemple)

| Heure | Routine | Plateforme | Cron |
|-------|---------|-----------|------|
| 18h00 | `audit-settings-ag-monthly` | AntiGravity | `0 18 1 * *` |
| 19h00 | `audit-settings-cd-monthly` | Claude Desktop | `0 19 1 * *` |
| 20h00 | `audit-settings-chrome-monthly` | Chrome (claude.ai/chat + /code) | `0 20 1 * *` |
| 21h00 | `audit-settings-chatgpt-monthly` | ChatGPT | `0 21 1 * *` |
| 22h00 | `audit-settings-gemini-monthly` | Gemini | `0 22 1 * *` |

Cron UTC = local Paris -1h (hiver) ou -2h (été). Vérifier conversion avant create.

### Trigger user canonique (gravée 2026-05-06)

Florent dit : `programme overnight <tâche>` — Claude exécute :

1. **Identifier scope** (1 phrase). Flou → demander 1 question.
2. **Choisir cron récurrent OU `fireAt` one-shot** :
   - Récurrent (audit mensuel, health daily) → `cronExpression`
   - Test ce soir / one-shot ponctuel → `fireAt` ISO timestamp avec offset Paris (ex `2026-05-06T19:00:00+02:00`)
3. **Skill `/routine-create` Phase 2 + Phase 2.6** → `mcp__scheduled-tasks__create_scheduled_task` ou `update_scheduled_task`
4. **Pattern Phase 2.6 obligatoire** (fenêtre check + bypass perm try/finally + whitelist + audit log + commit auto)
5. **Activer** (`enabled: true`)
6. **Recommander Run now 1×** si récurrent (pre-approve tools, sinon 1ère exec mensuelle bloque sur perm)

### Use cases overnight courants

| Trigger user | Skill orchestrateur invoqué dans prompt routine | Notes |
|--------------|-----------------------------------------------|-------|
| `programme overnight audit AG settings` | (direct, pas de skill orchestrateur) | One-shot fireAt ce soir 19h+ |
| `programme overnight tests autopilote séquentiels` | `/autopilot` (skill global) | Tests un par un (jamais parallèle), 1 test par sub-phase, log par test |
| `programme overnight audit dev orchestrateur` | `/dev-orchestrator` (skill projet SpeakApp) | Bilan avancement + priorisation features + santé docs/skills/hub/tests |
| `programme overnight planifier intervalles réguliers <feature>` | `/dev-orchestrator` + `/loop` (skill global) | Loop X min sur sub-phase feature pour développer/tester |
| `programme overnight cleanup logs/ + push` | (direct) | Bash + git, pas Computer Use |

**Règle Autopilote tests séquentiels** : tests Autopilote = 1 test par 1, 1h gap minimum entre 2 (pas parallèle, conflit Computer Use). Idéal overnight séquentiel (Florent dort, tests s'enchaînent).

### Multi-compte Florent — handoff via Plan vivant feature (2026-05-06)

Florent a **1 compte Claude par fonctionnalité** (autopilote = compte X, AG settings = compte Y, etc.). Pattern overnight peut être gravé sur compte A mais déclenché depuis compte B.

**Workflow handoff multi-compte** :
1. Compte A grave skill (`/routine-create` Phase 2.6) — fait 1 fois, pousse via repo `~/.claude/` (skill `/migration-pc`)
2. Compte A push aussi le Plan vivant feature concernée (skill `/migration-session-handoff`) si tâche overnight liée à une feature SpeakApp en cours
3. Compte B `git pull` skills + Plan vivant (skill `/migration-pickup`)
4. Compte B trigger `programme overnight <tâche>` — skill applique pattern Phase 2.6 identiquement
5. Routine exec autonome pendant Florent dort (peu importe compte actif au moment cron — scheduled-tasks tournent par taskId, pas par compte)

**Important** : routines locales `mcp__scheduled-tasks` stockées dans `~/.claude/scheduled-tasks/` partagé entre tous les comptes (1 seul home Windows). Donc routine créée compte A est visible/exécutable depuis compte B sans handoff supplémentaire (Plan vivant suffit pour passer contexte feature).

### Anti-patterns interdits overnight Computer Use

- ❌ 2 routines Computer Use même heure (conflit écran principal)
- ❌ Bypass perm sans whitelist (chèque blanc)
- ❌ Whitelist sans audit log (pas de traçabilité)
- ❌ Tests Autopilote en parallèle (1 par 1 obligatoire)
- ❌ Créer routine sur mauvais compte sans push skill + Plan vivant pour autres comptes
- ❌ Demander Florent confirme heure si verbatim "programme overnight" sans précision → défaut = 19h ce soir Paris pour one-shot, sinon cron mensuel/daily selon récurrence évidente
- ❌ Activation manuelle quotidienne ("Florent dois lancer chaque soir")
- ❌ Cron hors 18h-06h (Florent éveillé = Computer Use vole le focus)
- ❌ Pas de restore `permissions.defaultMode` original en finally (bypass persiste matin)

---

## Phase 2.5 — Audit routines cloud existantes

**Déclencher** : entrée en session avec routines existantes OU comportement bizarre signalé.

1. `RemoteTrigger list` → toutes les routines du compte
2. Pour chacune, `RemoteTrigger get <id>` et vérifier :

| Champ | Attendu | Action si KO |
|---|---|---|
| `session_context.model` | Sonnet (ou Opus si justifié) | Mettre à jour |
| `session_context.sources` | Repo utile pointé | Ajouter repo GitHub |
| `events[0].data.message.content` | Prompt non-vide | ⚠️ Routine cassée — voir Phase 1.5 |
| `mcp_connections` | Connecteurs cohérents avec le prompt | Ajouter manquant |
| `enabled` | `true` si doit tourner | Activer ou documenter pourquoi désactivée |
| `cron_expression` | ≥1h UTC | Corriger |

**Inspection croisée** : prompt dit "lire Gmail" mais pas de connecteur Gmail → routine cassée silencieuse. Fixer immédiatement.

**Rapport** : `trig_<id> — <nom> — <model> — repo: yes/no — connecteurs: <liste> — prompt: OK/VIDE — statut: OK/FIXED/À FIXER`

---

## Phase 3 — Enregistrement et watchdog

Ajouter dans `memory/active-routines.md` :
```
- <nom> — <cloud|local> — <cron> — créée <date> — connecteurs: <liste>
```

**Watchdog (dès ≥2 routines)** : proposer `cloud-tasks-watchdog-hebdo` (dimanche soir). Vérifie exécution de la semaine, envoie email ✅/⚠️ par routine. Needs `RemoteTrigger` dans `allowed_tools`.

---

## Phase 4 — Dépannage

**Routine sans repo après création** : `get` → ajouter `session_context.sources` → `update` complet.

**Mauvais modèle** : `get` → changer `session_context.model` → `update` complet.

**Connecteur absent** : `get` → ajouter entrée `mcp_connections` (UUID connu) → `update` complet.

**Prompt effacé** : voir Phase 1.5 récupération.

**API refuse l'update** : UI web https://claude.ai/code/scheduled → modifier manuellement → sauver (synchro desktop + web).

**Routine visible dans app mais pas dans `list`** : désactivée (`enabled: false`) ou orpheline → vérifier UI web.

---

## Phase M1 — Migration : Inventaire

```bash
ls ~/.claude/scheduled-tasks/ | sort | wc -l
```

Pour chaque `~/.claude/scheduled-tasks/*/SKILL.md` :
- Extraire `name` + `description` (frontmatter YAML)
- Extraire schedule/cron (chercher : `cron:`, `daily`, `weekly`, `hourly`, `hebdo`, `mensuel`, pattern `0 [0-9]`)
- Détecter morte/annulée : desc contient `ANNULÉ`, `REMPLACÉ`, `FAIT`, `désactivé`

Afficher :

```
| # | Slug | Statut | Domaine | Schedule | Description courte |
|---|------|--------|---------|----------|-------------------|
```

Statuts : `ACTIVE` / `MORTE` / `ONE-SHOT`

---

## Phase M2 — Migration : Classification

| Domaine | Pattern |
|---------|---------|
| `speakapp` | slug `speakapp-*` |
| `orchestration` | `orchestrateur-*`, `auto-[1-9]-*`, `cc-pipeline-*` |
| `business` | attestation, malt, gladia, cfe, inpi, intel, is-*, credit-* |
| `design` | `claude-design-*`, `linkedin-*` |
| `maintenance` | delete-tab-groups, email-digest, daily-email, marketplace, youtube, vosk-weekly, comfort-mirror, overnight-*, check-antigravity |
| `other` | reste |

**Routines mortes/one-shot — NE PAS migrer vers cloud** :
- `attestation-regularite-fiscale` — ANNULÉ
- `inpi-cessation-activite` — REMPLACÉ
- `intel-warranty-followup` — désactivé
- `is-deadline-last-chance` — ANNULÉ
- `is-declaration-zero-rappel` — FAIT
- `speakapp-bisect-crash-ucrtbase-fastfail` — one-shot
- `speakapp-bp098-v11-spawned-log-missing` — one-shot
- `speakapp-overnight-run-01-tts-metric` — one-shot terminé
- `check-antigravity-forum-reply` — one-shot
- `linkedin-post-claude-design` — one-shot
- `gladia-nego-round2` — one-shot
- `wisper-deploy-live` — one-shot

**Si mode `check` → STOP ici.** Afficher tableau + comptes par domaine.

---

## Phase M3 — Migration : Conversion SKILL.md → fichier contexte

Pour chaque routine ACTIVE, créer :

```
docs/routines-migration/<domaine>/<slug>/00-contexte/<slug>-config.md
```

### Template (8 sections)

```markdown
# <Nom lisible> — Configuration

> **Slug MCP local** : `<slug>`
> **Domaine** : `<domaine>`
> **Statut** : ACTIVE

## ⚠️ Pré-requis critiques

- **Schedule** : <cron ou description humaine>
- **Modèle recommandé** : <Opus 4.7 si cognitif complexe, sinon Sonnet 4.5>
- **Connecteurs MCP** : <liste détectés dans le SKILL.md>
- **Dépendances locales** : <paths locaux référencés>

## 1. Contexte business

<1-2 phrases : projet (SpeakApp/Marketplace/Personnel), pourquoi cette routine>

## 2. Objectif

<Reprendre description frontmatter + reformulation si trop courte>

## 3. Architecture (flux haut niveau)

<3-6 étapes numérotées extraites du SKILL.md — vision macro>

## 4. Sources et cibles

<D'où viennent les données, où vont les résultats>

## 5. Procédure détaillée

<Contenu complet du SKILL.md original — coller tel quel>

## 6. Règles strictes

<Contraintes extraites du SKILL.md. Si aucune explicite :>
- Lire sources AVANT toute action
- Ne pas modifier code de production
- Signaler UNIQUEMENT si anomalie (pas de rapport "tout va bien" verbeux)
- Ne jamais supprimer sans confirmation explicite

## 7. Format du livrable

<Ce que la routine produit : rapport MD, page Notion, email, commit…>

## 8. Gestion des erreurs

<Que faire si source indisponible / fichier manque / API échoue. Si non spécifié :>
- Source indisponible → logger, continuer avec sources disponibles
- Aucune donnée → produire rapport vide daté
- Erreur item → skipper, continuer (pas d'arrêt brutal)

---

## Prompt claude.ai/code (court)

> Coller dans "Instructions" lors de la création sur claude.ai/code/routines.

```
Tu exécutes la routine "<Nom lisible>" pour le projet <projet>.

ÉTAPE 1 — CHARGEMENT DU CONTEXTE
Lis intégralement `<slug>/00-contexte/<slug>-config.md` du dépôt cloné.

ÉTAPE 2 — EXÉCUTION
Exécute selon les instructions du fichier. Respecte §6.

ÉTAPE 3 — LIVRABLE
<1 phrase : type de livrable attendu>

ÉTAPE 4 — CONFIRMATION
- Statut : SUCCÈS / PARTIEL / ÉCHEC
- Résumé 2-3 lignes
- Lien(s) livrable(s) si applicable
```
```

### Règles de conversion

1. **Modèle** : cognitif complexe (synthèse, analyse, rédaction) → Opus 4.7. Déterministe (grep, count, health check) → Sonnet 4.5.
2. **Connecteurs** : détecter Notion, Gmail, GitHub, Supabase dans le SKILL.md → lister §1.
3. **Dépendances locales** : si SKILL.md référence `logs/`, `memory/`, `tools/` → noter en §1 candidat MCP local plutôt que cloud pur.
4. **Ne pas inventer** : section sans contenu → écrire "Non spécifié — à compléter".

---

## Phase M4 — Migration : Dispatch parallèle

Traiter par batch de 8 via `/dispatch`. Exemple :

```
Batch A : speakapp-agent-vocal-daily, speakapp-autoperm-daily, speakapp-chat-reader-daily, speakapp-notif-pipeline-daily, speakapp-stt-daily, speakapp-pilote-ia-daily, speakapp-plan-reader-daily, speakapp-question-handler-daily
Batch B : speakapp-dictee-contextuelle-healthcheck, speakapp-dictionnaire-intelligent-daily, speakapp-doc-sync-audit-weekly, speakapp-kb-maintenance, speakapp-monthly-platform-audit, speakapp-prd-coherence-weekly, speakapp-qa-daily, speakapp-skill-launcher-daily
...
```

---

## Phase M5 — Migration : Index global

Créer `docs/routines-migration/README.md` :

```markdown
# Routines Claude — Index de migration

> Généré par `/routine-create migrate` le YYYY-MM-DD
> Source : `~/.claude/scheduled-tasks/`

## Résumé

| Domaine | Actives | Mortes/One-shot | Total |
|---------|---------|-----------------|-------|
| speakapp | N | N | N |
| orchestration | N | N | N |
| business | N | N | N |
| design | N | N | N |
| maintenance | N | N | N |
| other | N | N | N |

## Index complet

| Slug | Domaine | Statut | Schedule | Modèle | Doc contexte |
|------|---------|--------|----------|--------|-------------|
| ... | ... | ... | ... | ... | ... |

## Setup GitHub

1. Créer dépôt privé `florent-routines-claude`
2. Connecter via Claude Code → Paramètres → GitHub
3. Push depuis `docs/routines-migration/`
4. Pour chaque routine ACTIVE → créer sur claude.ai/code/routines avec prompt §"Prompt claude.ai/code"
```

### Vérification finale

```bash
find docs/routines-migration -name "*-config.md" | wc -l
# Doit = nombre de routines ACTIVE
```

---

## Règles de communication

1. Toujours préciser "visible app desktop ET web" (même backend synchronisé).
2. Ne pas annoncer "routine créée" avant vérif visuelle Phase 1.4.
3. Format réponse finale : 1 ligne par routine (ID, cadence, rôle) + URL https://claude.ai/code/scheduled.
4. **Routine locale** : ne pas annoncer "routine créée" avant validation gate Phase 1.4bis (grep `### Rapport local (OBLIGATOIRE)` + `memory/reports/` + `Note 2026-05-09` dans SKILL.md). Sans gate PASS → REFUSER finalisation et patcher avant.
