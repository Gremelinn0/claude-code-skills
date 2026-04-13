---
name: autopilot
description: Orchestrateur goal-driven autonome. Reçoit un objectif libre, génère un plan dynamique, boucle jusqu'à l'atteindre via /loop + state.md. Workflow pur — aucune dépendance projet.
trigger: user-invocable — /autopilot <objectif> [intervalle] [max]
scope: global — tout projet
---

# /autopilot — Orchestrateur Autonome

## Invocation

```
/autopilot <objectif>
/autopilot <objectif> [intervalle]        ex: 5m, 10m, 30m (défaut: 10m)
/autopilot <objectif> [intervalle] [max]  ex: max=20 (défaut: 20 itérations)
```

**Commandes de contrôle**
```
/autopilot status   → afficher state.md courant
/autopilot pause    → écrire PAUSED dans state.md
/autopilot resume   → reprendre depuis l'état courant
/autopilot stop     → forcer DONE + générer rapport
```

---

## Phase 1 — Initialisation

À l'invocation, faire dans l'ordre :

### 1. Vérifier le contexte git
```bash
git branch --show-current
```
- Si `main` ou `master` → avertir l'utilisateur : "Tu es sur la branche principale. Je recommande un worktree ou une branche dédiée."
- Ne pas bloquer — continuer si l'utilisateur confirme

### 2. Gérer state.md existant

**Si `.autopilot/state.md` n'existe pas** → créer `.autopilot/` et passer au step 3.

**Si `.autopilot/state.md` existe** → lire le statut :
- Statut = `IN_PROGRESS` → reprendre **automatiquement**, sans demander. Afficher : "Reprise — iter [N]/[MAX], objectif : [OBJECTIF]"
- Statut = `STUCK` ou `PAUSED` → afficher l'état et demander : "Reprendre ou démarrer un nouvel objectif ?"
- Statut = `DONE` → afficher le rapport existant et demander : "Nouvel objectif ?"

### 3. Écrire state.md initial

```markdown
# Autopilot State

## Objectif
[OBJECTIF REÇU VERBATIM]

## Plan dynamique
- [ ] (à décomposer — iter 1)

## Dernière action
(initialisation)

## Résultat
(aucun)

## Essayé — ne pas refaire
(aucun)

## Bloqueurs
(aucun)

## Métriques
- Itération : 0 / [MAX]
- Progression : 0 / 0 étapes (0%)
- Intervalle : [INTERVALLE]
- Démarré : [DATE ISO]
- Job ID : [À remplir au step 5]
- Échecs consécutifs : 0

## Statut
IN_PROGRESS
```

### 4. Créer log.md initial

```markdown
# Autopilot Log

| Iter | Action | Résultat | Statut |
|------|--------|----------|--------|
| 0 | Initialisation | state.md créé | IN_PROGRESS |
```

### 5. Lancer le loop via CronCreate
- `cron` : selon l'intervalle (ex: `*/10 * * * *` pour 10m)
- `prompt` : le **Prompt de décision** ci-dessous (section Phase 2), verbatim
- `recurring` : `true`

Après création → écrire l'ID retourné par CronCreate dans state.md (`Job ID`).

### 6. Exécuter immédiatement la première itération
Ne pas attendre le premier tick. Lancer le Prompt de décision maintenant.

---

## Phase 2 — Prompt de décision (chaque itération)

> Ce prompt est passé à CronCreate et exécuté à chaque tick.
> Il est également exécuté manuellement à l'initialisation (step 6).

---

**DÉBUT DU PROMPT DE DÉCISION**

Lis `.autopilot/state.md`. Tu es un agent autonome — ton seul objectif est d'atteindre le but décrit dans "Objectif".

**STOP — vérifier d'abord :**
- Statut = `DONE` → générer le rapport final (format ci-dessous), lire "Job ID" dans state.md, appeler CronDelete avec cet ID, afficher le rapport à l'utilisateur, arrêter.
- Statut = `STUCK` → afficher "Bloqueurs" à l'utilisateur, lire "Job ID", appeler CronDelete, arrêter.
- Statut = `PAUSED` → ne rien faire, ignorer ce tick.
- Itération >= max → écrire Statut = `STUCK`, Bloqueurs = "max itérations atteint", lire "Job ID", appeler CronDelete, afficher à l'utilisateur.
- **Boucle stérile** : si les 3 dernières lignes de log.md sont toutes `ÉCHEC` → pivoter : reformuler les étapes bloquées, ne pas continuer en aveugle.
- **Progression gelée** : si le compteur "Progression" n'a pas bougé depuis 5 itérations consécutives → Statut = `STUCK`, Bloqueurs = "progression gelée".

**SINON — itération normale :**

**Si Itération = 0 (plan vide) → itération de décomposition :**
1. Incrémenter Itération à 1.
2. Analyser l'objectif. Décomposer en 3 à 7 étapes concrètes et actionnables.
3. Écrire les étapes dans state.md sous forme `- [ ] étape`.
4. Mettre à jour Progression : `0 / N étapes (0%)`.
5. Écrire dans log.md : `| 1 | Décomposition du plan | N étapes générées | IN_PROGRESS |`
6. Sauvegarder. **S'arrêter ici** — l'exécution commence à l'itération suivante.

**Si Itération >= 1 → itération d'exécution :**
1. Incrémenter Itération. Si la dernière action a réussi, remettre "Échecs consécutifs" à 0.
2. Prendre la **première étape non cochée** `[ ]` du plan.
3. Exécuter cette étape avec les outils disponibles :
   - Lecture/analyse : `Read`, `Grep`, `Glob`
   - Modification : `Edit`, `Write`
   - Commandes : `Bash`
   - Sous-tâches complexes : `Agent`
   - Recherche externe : `WebFetch`, `WebSearch`
4. Évaluer le résultat honnêtement :
   - **SUCCÈS** → cocher `[x]`, écrire le résultat dans "Résultat", remettre "Échecs consécutifs" à 0.
   - **PARTIEL** → laisser `[ ]`, noter ce qui reste dans "Dernière action".
   - **ÉCHEC** → ajouter à "Essayé" : `- [étape] → [cause d'échec précise]`. Incrémenter "Échecs consécutifs".
5. Mettre à jour Progression : `X / N étapes (X*100/N %)`.
6. Si "Échecs consécutifs" >= 3 sur la **même étape** → écrire Statut = `STUCK`, Bloqueurs = [cause précise]. Ne pas continuer.
7. Si **toutes les étapes** sont cochées `[x]` → écrire Statut = `DONE`.
8. Écrire dans log.md : `| [N] | [action en 1 phrase] | [résultat en 1 phrase] | [SUCCÈS/PARTIEL/ÉCHEC] |`
9. Sauvegarder state.md.

**RÈGLES ABSOLUES :**
- 1 seule action exécutée par itération — pas d'actions en cascade
- Ne jamais refaire ce qui est dans "Essayé — ne pas refaire"
- **Ne jamais attendre l'utilisateur pour quoi que ce soit de technique.** Si un test nécessite qu'une app soit ouverte → l'ouvrir avec les outils (Bash, Chrome MCP, CDP). Si un navigateur est nécessaire → utiliser Chrome MCP directement. Zéro PAUSED pour des raisons techniques.
- PAUSED uniquement pour : push vers remote, deploy prod, suppression définitive sans backup. Rien d'autre.
- Si une étape semble nécessiter AG ou une app externe → tenter d'abord avec les outils disponibles avant de conclure que c'est impossible.

**FORMAT RAPPORT FINAL (à produire quand Statut = DONE) :**

```
# Rapport Autopilot

**Objectif atteint :** [OBJECTIF]

## Ce qui a été fait
[liste des étapes [x] du plan]

## Durée
[N itérations × intervalle]

## Fichiers modifiés
[résultat de : git diff --name-only]

## Essayé sans succès
[contenu de "Essayé — ne pas refaire", ou "rien"]

## Suggestions suivantes
[ce qui reste hors scope, ou "rien"]
```

**FIN DU PROMPT DE DÉCISION**

---

## Intervalles recommandés

| Type de tâche | Intervalle |
|---|---|
| Debug / analyse logs | 5m |
| Implémentation code | 10m |
| Recherche / exploration | 15m |
| Tâche longue / tests | 30m |

---

## Structure des fichiers

```
<cwd>/
  .autopilot/
    state.md    ← état courant (goal, plan, métriques, job ID, statut)
    log.md      ← journal chronologique des actions
```

Ces fichiers peuvent être commités ou ignorés selon le projet.
Pour usage temporaire, ajouter automatiquement à `.gitignore` :
```bash
echo ".autopilot/" >> .gitignore
```


---

## Auto-amelioration

**Ce skill s'ameliore a chaque usage.** C'est une responsabilite, pas un bonus.

Apres chaque execution, avant de conclure :
1. **Friction detectee ?** (etape confuse, ordre sous-optimal, info manquante) → corriger ce skill immediatement
2. **Bug resolu ou pattern decouvert ?** → l'ajouter dans la section pieges/patterns de ce skill
3. **Approche validee ?** → l'ancrer comme pattern reference dans ce skill
4. **Gain applicable a d'autres skills ?** → propager (ou PROPOSITION DE REGLE si transversal)

**Regle : ne jamais reporter une amelioration a "plus tard". L'appliquer maintenant ou la perdre.**
