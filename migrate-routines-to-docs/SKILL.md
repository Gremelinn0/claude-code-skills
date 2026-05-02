---
name: migrate-routines-to-docs
description: Migre les routines locales (~/.claude/scheduled-tasks/) vers des documents contexte GitHub (format guide NoesisAI). Produit docs/routines-migration/ prêt à pousser sur GitHub pour utilisation avec claude.ai/code Routines cloud.
type: skill
---

# Skill — migrate-routines-to-docs

## Usage

```
/migrate-routines-to-docs           # Migration complète (toutes les phases)
/migrate-routines-to-docs check     # Phase 1+2 seulement — inventaire + classification
/migrate-routines-to-docs <slug>    # Migre une seule routine
```

## Guide de référence

Lire `docs/guide-routines-claude.md` AVANT d'exécuter la phase 3.
Structure cible par routine : `docs/routines-migration/<domaine>/<slug>/00-contexte/<slug>-config.md`

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
docs/routines-migration/<domaine>/<slug>/00-contexte/<slug>-config.md
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

Créer `docs/routines-migration/README.md` :

```markdown
# Routines Claude — Index de migration

> Généré par `/migrate-routines-to-docs` le YYYY-MM-DD
> Source : `~/.claude/scheduled-tasks/` (64 routines)
> Dépôt GitHub cible suggéré : `florent-routines-claude` (privé)

## Résumé

| Domaine | Actives | Mortes/One-shot | Total |
|---------|---------|-----------------|-------|
| speakapp | N | N | N |
| orchestration | N | N | N |
| business | N | N | N |
| design | N | N | N |
| maintenance | N | N | N |
| other | N | N | N |
| **TOTAL** | **N** | **N** | **64** |

## Index complet

| Slug | Domaine | Statut | Schedule | Modèle | Doc contexte |
|------|---------|--------|----------|--------|-------------|
| speakapp-agent-vocal-daily | speakapp | ACTIVE | daily 9h05 | Opus 4.7 | [lien](speakapp/speakapp-agent-vocal-daily/00-contexte/speakapp-agent-vocal-daily-config.md) |
| ... | ... | ... | ... | ... | ... |

## Setup GitHub

1. Créer dépôt privé `florent-routines-claude` sur github.com
2. Connecter via Claude Code → Paramètres → GitHub → Install GitHub App
3. Depuis ce dossier :
   ```bash
   cd docs/routines-migration
   git init && git add . && git commit -m "feat: migration initiale 64 routines"
   git remote add origin git@github.com:florent/<repo>.git
   git push -u origin main
   ```
4. Pour chaque routine active → créer sur claude.ai/code/routines avec le prompt du §"Prompt claude.ai/code"
```

---

## Vérification finale

```bash
# Compter les fichiers générés
find docs/routines-migration -name "*-config.md" | wc -l
# Doit correspondre au nombre de routines ACTIVE (64 - mortes - one-shot)

# Spot-check 3 routines
ls docs/routines-migration/speakapp/speakapp-stt-daily/00-contexte/
ls docs/routines-migration/orchestration/orchestrateur-synthese-hebdo/00-contexte/
ls docs/routines-migration/maintenance/daily-email-digest/00-contexte/
```

Chaque fichier doit avoir les 8 sections + bloc "Prompt claude.ai/code".
