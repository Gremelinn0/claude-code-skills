---
name: routine-create
description: Crée, gère et migre les routines Claude Code (cloud ou locale). Création propre du premier coup + connecteurs MCP + repo GitHub + vérif visuelle. Migration routines locales → docs GitHub format cloud. Alias /migrate-routines-to-docs intégré.
---

# /routine-create — Routines Claude Code (création + audit + migration)

## TL;DR — modes disponibles

| Invocation | Ce que ça fait |
|---|---|
| `/routine-create` | Créer une nouvelle routine (cloud ou locale) |
| `/routine-create audit` | Auditer toutes les routines cloud existantes |
| `/routine-create migrate` | Migrer routines locales → docs GitHub format cloud |
| `/routine-create migrate check` | Inventaire + classification seulement (pas de génération) |
| `/routine-create migrate <slug>` | Migrer une seule routine |
| `/migrate-routines-to-docs` | Alias rétro-compat → même chose que `migrate` |

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
