---
name: run-all-routines
description: Lance toutes les routines actives à la demande avec Sonnet. Lit les SKILL.md dans ~/.claude/scheduled-tasks/, filtre les tâches actives, exécute en parallèle via Agent(model="sonnet"). Usage: /run-all-routines [scope|task-id]
---

# run-all-routines

Lance toutes les routines actives à la demande avec Sonnet, sans modifier les définitions existantes.

## Syntaxe

```
/run-all-routines              → scope speakapp (défaut) : speakapp-* + auto-*
/run-all-routines all          → toutes catégories actives
/run-all-routines auto         → auto-1 à auto-6 uniquement
/run-all-routines health       → speakapp-*-daily + *-healthcheck uniquement
/run-all-routines <task-id>    → une seule tâche par son ID exact
```

---

## Étape 1 — Découverte

```bash
ls ~/.claude/scheduled-tasks/
```

Pour chaque répertoire trouvé, lire `~/.claude/scheduled-tasks/<id>/SKILL.md`.

---

## Étape 2 — Filtrage

**Exclure** toute tâche dont le SKILL.md (description ou body) contient l'un de ces mots :
- `ANNULÉ` · `ANNULE` · `FAIT` · `REMPLACÉ` · `REMPLACE`

**Exclure cloud-only** (nécessitent Gmail/Chrome/Malt — impossible en session locale) :
- `malt-monitor-2h`
- `daily-email-digest`
- `email-digest-matin`
- `malt-disponible-refresh`
- `overnight-cd-reminder`
- `overnight-claude-reminder`
- `linkedin-post-claude-design`
- `youtube-notebooklm-weekly-sync`

Ces tâches apparaissent dans le rapport final avec statut `⏭️ SKIP cloud-only`.

---

## Étape 3 — Application du scope

| Scope arg | Pattern taskId inclus |
|-----------|----------------------|
| `speakapp` (défaut) | `speakapp-*` et `auto-*` |
| `auto` | `auto-[0-9]*` uniquement |
| `health` | `speakapp-*-daily` et `speakapp-*-healthcheck` |
| `all` | tout ce qui passe l'étape 2 |
| `<task-id>` exact | cette tâche uniquement (skip filtrage scope) |

---

## Étape 4 — Lancement en batches parallèles

Regrouper les tâches retenues en batches de **6 maximum**.

Pour chaque batch, envoyer **un seul message** avec N appels Agent en parallèle :

```
Agent(
  subagent_type="general-purpose",
  model="sonnet",
  description="routine: <taskId>",
  prompt="""
Tu exécutes la routine SpeakApp suivante.
Working directory: C:\\Users\\Administrateur\\PROJECTS\\3- Wisper\\speak-app-dev

--- INSTRUCTIONS DE LA ROUTINE ---
<contenu complet du SKILL.md de la tâche>
---

Exécute toutes les étapes. À la fin, réponds en 2-3 lignes :
- Ce que tu as vérifié
- Statut : PASS / ALERT / FAIL
- Si ALERT ou FAIL : détail court
"""
)
```

Attendre les résultats du batch avant de lancer le suivant.

---

## Étape 5 — Rapport final

Afficher un tableau récapitulatif :

```
| task-id                          | statut          | résumé |
|----------------------------------|-----------------|--------|
| auto-1-cd-autoperm-analyse       | ✅ PASS         | 0 erreur détectée |
| speakapp-agent-vocal-daily       | ⚠️ ALERT        | TTS latence >2s |
| malt-monitor-2h                  | ⏭️ SKIP cloud   | nécessite Gmail/Chrome |
...
```

Statuts :
- `✅ PASS` — routine terminée sans anomalie
- `⚠️ ALERT` — anomalie non-bloquante détectée
- `❌ FAIL` — erreur bloquante ou exception
- `⏭️ SKIP cloud-only` — tâche cloud, non exécutable localement

Terminer par : **N PASS / M ALERT / P FAIL / Q SKIP**

---

## Notes

- Modèle fixe : **Sonnet** (jamais Opus pour cet usage on-demand)
- Le skill ne modifie PAS les définitions des tâches existantes
- Les agents tournent dans la session courante : accès aux MCPs connectés (Supabase, Notion, computer-use, scheduled-tasks)
- Si un agent timeout ou crash → marquer ❌ FAIL + continuer les autres
