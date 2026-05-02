---
name: routine-create
description: Crée proprement une routine Claude Code (cloud ou locale) du premier coup, avec Opus par défaut + connecteurs MCP + repo GitHub + vérification visuelle post-création dans la version web.
---

# /routine — Créer une routine Claude Code (cloud + local, du premier coup)

## TL;DR — workflow standard

**Création** : Phase 0 (cloud/local ?) → Phase 1 (body API cloud) OU Phase 2 (MCP scheduled-tasks local) → Phase 1.4 (vérif visuelle Chrome MCP) → Phase 3 (enregistrement + watchdog si ≥2 routines).

**Modification d'une routine existante** : TOUJOURS `RemoteTrigger get` → modifier l'objet → `RemoteTrigger update` avec le body ENTIER. Jamais d'update partiel (Phase 1.5).

**Audit périodique** : Phase 2.5 — dès qu'on entre dans une session avec routines existantes ou qu'une anomalie est signalée.

**Ce que je peux / ne peux pas faire** : Matrice de capacités ci-dessous avant Phase 1.

## Quand invoquer

Dès que l'utilisateur demande de créer/programmer une routine, une tâche automatique, un cron, un rappel périodique. Les mots-clés qui déclenchent : "routine", "tâche programmée", "automatiser tous les jours/semaines", "check toutes les X heures".

Ne PAS utiliser pour les scheduled prompts ponctuels (usage direct du skill `schedule` si disponible) ni pour les subagents parallèles dans l'instant (`dispatching-parallel-agents`).

## Phase 0 — Décider cloud ou local

Avant tout, choisir le bon mode. Arbre de décision :

**Cloud (défaut)** quand la tâche n'a besoin que de :
- APIs web, services SaaS (Gmail, Drive, Notion, etc.)
- Recherche web
- Analyse de texte
- Création de drafts
- Écriture de fichiers dans le repo GitHub attaché

**Local (forcé)** quand la tâche a besoin de :
- Fichiers Windows locaux sur le PC de l'utilisateur
- Computer Use (clic sur l'écran)
- Chrome MCP avec les cookies/sessions personnelles
- Python local, scripts shell spécifiques au PC
- Tout ce qui suppose que la machine soit allumée

**Si hésitation** : cloud d'abord, replier vers local seulement si on découvre une dépendance locale.

## Matrice de capacités — ce que je peux faire sur une routine existante

Avant toute demande de modification ou création, se référer à ce tableau. C'est la table de vérité de ce que l'API `RemoteTrigger` permet.

### ✅ Modifiable via `RemoteTrigger` action `update`

| Champ | Exemple validé |
|---|---|
| **Modèle** | `claude-sonnet-4-6` → `claude-opus-4-7` (fait en prod 2026-04-22) |
| **Prompt** | Réécrire `events[0].data.message.content` |
| **Cron** | Changer `cron_expression` (UTC, min 1h) |
| **Repo GitHub** | Ajouter/changer `session_context.sources.git_repository.url` |
| **`allowed_tools`** | Ajouter/retirer tools (`RemoteTrigger`, `WebFetch`, etc.) |
| **Connecteurs MCP** | Ajouter/retirer dans `mcp_connections` (si UUID connu — voir astuce) |
| **État actif** | `enabled: true/false` pour activer/désactiver sans supprimer |
| **Nom** | Renommer via le champ `name` |

### ❌ Non-faisable via API

- **Découvrir un UUID de connecteur neuf** (Slack, Linear, HubSpot, etc.) qui n'est jamais apparu dans une routine → astuce ci-dessous obligatoire.
- **Voir l'historique d'exécution** (run succès/échec, logs) → uniquement dans la web UI.
- **Lister les connecteurs MCP disponibles sur le compte** → pas d'endpoint, uniquement visible sur https://claude.ai/settings/connectors.

### 🌐 Nécessite la web UI systématiquement

- Première installation/OAuth d'un connecteur MCP sur le compte claude.ai.
- Vérification visuelle post-création (carte routine affiche bon repo + bons connecteurs + bon modèle).
- Cas d'échec silencieux où l'API accepte le body mais n'applique pas un champ.

### Astuce UUID — créer 1 routine manuellement pour débloquer l'API

Pourquoi : je ne vois pas les connecteurs MCP du compte claude.ai comme mes MCP locaux. Je peux JUSTE les attacher par UUID quand je connais déjà l'UUID.

Processus pour un connecteur neuf :

1. **Florent crée 1 routine manuellement** dans https://claude.ai/code/scheduled, en attachant le connecteur voulu (n'importe quel prompt/cron bidon).
2. Je fais `RemoteTrigger get <trigger_id>` sur cette routine.
3. Je lis `mcp_connections[].connector_uuid` + `url` + `name` dans la réponse.
4. Je sauvegarde dans `memory/reference_mcp_connector_uuids.md`.
5. Dès lors, toutes les routines suivantes peuvent utiliser ce connecteur via API sans repasser par la web UI.

Les 3 UUIDs de Florent sont déjà captés (Gmail, Google-Drive, Notion) — voir section suivante. Pour tout nouveau connecteur, cette procédure reste la seule voie.

## Phase 1 — Pour une routine CLOUD

### 1. Collecter les inputs obligatoires

- **Nom** : slug kebab-case (`malt-digest-matin-cloud`, `veille-hebdo`)
- **Cron UTC** : minimum 1h d'intervalle. Exemples : `0 6 * * 1-5` (jours ouvrés 6:00), `0 16 * * 5` (vendredi 16:00)
- **Prompt complet** : comportement attendu, bases Notion/Gmail ciblées, output attendu (email récap, page Notion, etc.)
- **Connecteurs nécessaires** : liste parmi `gmail`, `drive` (Google-Drive inclut Calendar), `notion`
- **Repo GitHub** : par défaut, le repo local ouvert dans la session Claude Code courante

### 2. Récupérer les UUIDs des connecteurs

Lire `memory/reference_mcp_connector_uuids.md` du projet. Les 3 UUIDs déjà captés pour Florent (account `396ceaa2-9b3c-40e5-9e12-14b05f4692ba`) :

- **Gmail** : `4ea3ada1-92a3-4085-84c1-cf184fdd5fd1` — `https://gmailmcp.googleapis.com/mcp/v1` — name: `Gmail`
- **Google-Drive** (inclut Calendar) : `ab2affa6-e372-4a20-bcd4-46d76a9b4193` — `https://drivemcp.googleapis.com/mcp/v1` — name: `Google-Drive`
- **Notion** : `decc5ebf-9cb1-424d-aeb1-45f165a0842b` — `https://mcp.notion.com/mcp` — name: `Notion`

**État confirmé 2026-04-22** : les 3 connecteurs (Gmail + Google-Drive + Notion) sont ACTIFS sur claude.ai web, installés avec toutes les permissions en "Toujours autoriser" (14 tools Notion, N tools Gmail, M tools Google-Drive). Audit `RemoteTrigger list` confirme 7 routines actives qui les utilisent sans erreur.

**Check rapide en 1 regard** (Chrome MCP, 5 secondes) :

```
mcp__Claude_in_Chrome__navigate → https://claude.ai/settings/connectors/<UUID>
mcp__Claude_in_Chrome__get_page_text
```

Lecture du texte :
- Si "Désinstaller" visible → connecteur installé ✅
- Si "Installer" / "Connecter" visible → connecteur absent → demander à Florent de faire le OAuth, ou naviguer vers la page et guider le clic si tier autorise
- Repérer les permissions "Toujours autoriser" (vert) vs "Demander" (main) vs "Ne jamais autoriser" (barré) — idéalement tout en vert pour les routines sans friction

Le champ `name` d'un connecteur MCP est contraint à `[a-zA-Z0-9_-]` uniquement. Utiliser `Google-Drive`, jamais `Google Drive`.

Si un connecteur nécessaire n'est PAS dans cette liste :

- **Option 1 (rapide)** : `RemoteTrigger get <trigger_id>` sur une routine existante qui l'utilise déjà, lire `mcp_connections[].connector_uuid`, ajouter au fichier de référence, puis utiliser.
- **Option 2 (connecteur neuf)** : demander à Florent de créer 1 routine manuellement via https://claude.ai/code/scheduled avec ce connecteur attaché, puis appliquer Option 1. C'est l'astuce qui débloque tout connecteur jamais utilisé auparavant.

### 3. Construire le body et appeler l'API

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
        "model": "claude-opus-4-7",
        "sources": [{"git_repository": {"url": "https://github.com/<owner>/<repo>", "allow_unrestricted_git_push": true}}]
      }
    }
  },
  "mcp_connections": [
    {"connector_uuid": "<uuid>", "name": "<Name-kebab>", "url": "<mcp-url>", "permitted_tools": []}
  ]
}
```

Appeler via `RemoteTrigger` action `create`.

Contraintes :
- Modèle **TOUJOURS** `claude-opus-4-7` par défaut. Jamais Sonnet sauf demande explicite.
- Le `name` d'un connecteur MCP est limité à `[a-zA-Z0-9_-]`. Utiliser `Google-Drive`, pas `Google Drive`.
- Le `cron_expression` est en UTC. Convertir depuis l'heure locale (Paris = UTC+1 hiver / UTC+2 été).

### 4. Vérification visuelle post-création (NON OPTIONNELLE)

Ouvrir via navigateur (Chrome MCP) https://claude.ai/code/scheduled et vérifier 4 choses sur la carte de la nouvelle routine :

1. Elle apparaît avec le bon nom et le bon cron
2. Elle affiche le tag du repo (ex: `vente-et-marketing-al...`)
3. Les connecteurs attendus sont listés (carrés Gmail/Notion/Google-Drive colorés)
4. Le modèle est bien Opus 4.7 (visible en cliquant sur la carte)

Si un point est KO : retourner à l'API pour corriger via `RemoteTrigger` action `update`, ou passer par l'UI web si l'API ne suffit pas.

## Phase 1.5 — PIÈGE CRITIQUE : l'update partiel efface `events`

**Bug vécu en prod le 2026-04-22. À ne JAMAIS reproduire.**

Lors d'un `RemoteTrigger update`, si le body envoyé ne contient PAS le champ `events` (ex: on voulait juste ajouter un repo et on a envoyé seulement `session_context.sources`), **`events` est écrasé à vide**. Résultat : le prompt de la routine disparaît, aucun warning de l'API, mais Florent voit une "tâche vide" dans son app et son web.

### Règle absolue pour tout `update`

**Toujours envoyer le body COMPLET**, même pour changer un seul champ :

1. `RemoteTrigger get <trigger_id>` → récupérer la config actuelle
2. Modifier uniquement le champ ciblé dans ce body
3. Renvoyer le body entier via `update`

### Body minimum obligatoire pour tout update

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
        "model": "claude-opus-4-7",
        "sources": [{"git_repository": {"url": "...", "allow_unrestricted_git_push": true}}]
      }
    }
  },
  "mcp_connections": [{"connector_uuid": "...", "name": "...", "url": "...", "permitted_tools": []}]
}
```

Oublier `events` → prompt silencieusement effacé. Testé, confirmé, douloureux. Toujours faire `get` avant `update`.

### Protocole de récupération si j'ai effacé un prompt par erreur

1. Vérifier via `get` que le champ `events` est bien vide
2. Retrouver le prompt original :
   - D'abord chercher dans l'historique de la session Claude Code qui a créé/modifié la routine
   - Sinon chercher dans le registre `memory/active-routines.md` ou équivalent
   - Sinon demander à Florent — c'est le pire cas, on a cassé sa routine
3. Update complet avec events + session_context restaurés
4. Vérification visuelle dans https://claude.ai/code/scheduled

## Phase 2 — Pour une routine LOCALE

Utiliser `mcp__scheduled-tasks__create_scheduled_task`. Stockage automatique dans `~/.claude/scheduled-tasks/<taskId>/SKILL.md`, visible dans la sidebar Scheduled de Claude Code.

Cette voie permet :
- Chrome MCP avec les sessions personnelles
- Computer Use
- Accès au filesystem Windows
- Python local

Vérification post-création : la tâche apparaît dans la sidebar "Scheduled" de Claude Code desktop.

## Phase 2.5 — Audit systématique des routines existantes

**À déclencher dès qu'on entre dans une session où des routines cloud existent, ou que Florent mentionne un comportement bizarre ("une routine est vide", "ça tourne pas", "pas le bon modèle").**

### Checklist d'audit par routine

1. `RemoteTrigger list` → récupérer toutes les routines du compte
2. Pour chacune, faire `RemoteTrigger get <id>` et vérifier :

| Champ | Attendu | Action si KO |
|---|---|---|
| `session_context.model` | `claude-opus-4-7` | Update vers Opus 4.7 sauf demande explicite Sonnet |
| `session_context.sources` | Pointe vers un repo utile | Ajouter le repo GitHub du projet |
| `events[0].data.message.content` | Prompt non-vide | ⚠️ Routine cassée — restaurer le prompt (voir Phase 1.5) |
| `mcp_connections` | Contient les connecteurs logiquement nécessaires au prompt | Ajouter le connecteur manquant (Gmail pour une routine mail, etc.) |
| `enabled` | `true` si doit tourner | Activer ou documenter pourquoi désactivée |
| `cron_expression` | ≥ 1h d'intervalle, UTC | Corriger si < 1h ou fuseau local |

### Inspection croisée prompt ↔ connecteurs

Si le prompt dit "lire Gmail" ou "écrire dans Notion" mais `mcp_connections` ne contient pas le connecteur correspondant → c'est une routine cassée qui échouera silencieusement à l'exécution. À fixer immédiatement.

### Rapport d'audit à produire

Après l'audit, produire 1 ligne par routine auditée :

```
trig_<id> — <nom> — <model> — repo: <yes/no> — connecteurs: <liste> — prompt: <OK/VIDE> — statut: <OK / FIXED / À FIXER>
```

C'est le recap honnête à donner à Florent. Pas "tout est bon" si ce n'est pas le cas.

## Phase 3 — Enregistrement et watchdog

### Enregistrer la routine

Ajouter une ligne dans le registre du projet (ex: `memory/active-routines.md` ou équivalent) :

```
- <nom> — <cloud|local> — <cron> — créée <date> — connecteurs: <liste>
```

### Règle watchdog (dès que >= 2 routines existent)

Proposer automatiquement la création d'une routine `cloud-tasks-watchdog-hebdo` qui tourne le dimanche soir et vérifie que les autres ont bien exécuté cette semaine. Sans watchdog, une routine morte reste invisible pendant des mois.

Le watchdog doit :
- Lire les bases Notion cibles des autres routines
- Vérifier qu'il y a eu des créations cette semaine
- Envoyer un email récap avec ✅ / ⚠️ par routine
- Inclure RemoteTrigger dans ses `allowed_tools` pour pouvoir lister les triggers

## Phase 4 — Quand les choses tournent mal

**⚠️ Rappel Phase 1.5 : TOUT update doit envoyer le body COMPLET (events + session_context + mcp_connections). Jamais un body partiel sinon `events` disparaît silencieusement.**

Workflow correct pour toute correction :

1. `RemoteTrigger get <trigger_id>` → récupérer la config actuelle complète
2. Modifier le champ ciblé dans l'objet récupéré
3. `RemoteTrigger update` avec le body ENTIER modifié

### La routine n'a pas de repo GitHub après création

Récupérer la config, ajouter `session_context.sources`, renvoyer le body complet :

```json
{
  "name": "<nom actuel>",
  "cron_expression": "<cron actuel>",
  "enabled": true,
  "job_config": {
    "ccr": {
      "environment_id": "env_01PTAfZ28fETTQwtdN88mzXT",
      "events": [{"data": {"message": {"content": "<PROMPT ACTUEL>", "role": "user"}, "type": "user"}}],
      "session_context": {
        "allowed_tools": ["<tools actuels>"],
        "model": "claude-opus-4-7",
        "sources": [{"git_repository": {"url": "https://github.com/<owner>/<repo>", "allow_unrestricted_git_push": true}}]
      }
    }
  },
  "mcp_connections": [{"...connecteurs actuels..."}]
}
```

Puis vérification visuelle dans https://claude.ai/code/scheduled.

### Le modèle n'est pas Opus

Même workflow : `get` → changer `session_context.model` à `claude-opus-4-7` → `update` complet.

### Un connecteur est absent

`get` → ajouter l'entrée dans `mcp_connections` (avec UUID déjà connu, sinon appliquer l'astuce UUID Phase 0) → `update` complet.

### Une routine est vide (prompt effacé)

Voir Phase 1.5 "Protocole de récupération si j'ai effacé un prompt par erreur".

### L'API refuse l'update

Passer par l'UI web : https://claude.ai/code/scheduled → cliquer la routine → modifier les champs manuellement → sauver. La version app desktop et web sont synchronisées, donc la modif apparaîtra aux deux endroits.

### Florent voit une routine bizarre que je ne vois pas en list

Faire un `RemoteTrigger list` depuis la session courante. Si elle n'apparaît pas, elle peut être :
- Sur un autre compte claude.ai (rare — Florent n'a qu'un compte)
- Désactivée (`enabled: false`) : ajouter `--include-disabled` si l'action le permet
- Orpheline (trigger_id connu mais config corrompue) : passer par l'UI web pour vérifier et éventuellement supprimer

## Règles de communication avec l'utilisateur

1. **Toujours préciser "tu la verras dans l'app desktop ET dans la version web"** (c'est le même backend synchronisé, mais l'utilisateur peut être confus entre les deux vues).

2. **Ne pas annoncer "la routine est créée"** avant la vérification visuelle Phase 1.4. Dire plutôt "créée via API, je vais maintenant vérifier dans la web UI".

3. **Format de réponse finale** : 1 ligne par routine avec (ID, cadence, rôle) + URL directe https://claude.ai/code/scheduled.

## Pourquoi ce skill plutôt qu'étendre un existant ?

Option évaluée : étendre `schedule` (existant pour les scheduled prompts ponctuels). Écartée car `schedule` cible des exécutions one-shot alors qu'ici on gère des routines récurrentes avec config persistante (connecteurs, repo, cron).

Option évaluée : étendre `dispatching-parallel-agents`. Écartée car ce skill concerne la parallélisation dans l'instant, pas la programmation dans le temps.

Option évaluée : `mcp__scheduled-tasks` direct sans skill. Écartée car ne couvre pas le cloud, et pas les UUIDs de connecteurs, et pas la vérification visuelle.

Le skill `routine` est la synthèse cloud + local avec toutes les étapes obligatoires (UUIDs, Opus, repo, watchdog, vérif visuelle).
