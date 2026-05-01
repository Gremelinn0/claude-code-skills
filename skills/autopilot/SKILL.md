---
name: autopilot
description: Orchestrateur goal-driven autonome. Reçoit un objectif libre, génère un plan dynamique, boucle jusqu'à l'atteindre via /loop + state.md. Workflow pur — aucune dépendance projet.
trigger: user-invocable — /autopilot <objectif> [intervalle] [max]
scope: global — tout projet
---

# /autopilot — Orchestrateur Autonome

## Articulation avec les autres skills

| Skill | Scope | Articulation avec `/autopilot` |
|-------|-------|------------------------------|
| **`/drive`** | Session courante en autonomie inline (cette conv) | Different scope — `/drive` finit ce qui est dans la conv, `/autopilot` lance un objectif separe |
| **`/dev-orchestrator`** | Bilan macro projet, priorisation | Peut proposer a l'utilisateur de lancer une next step goal-driven via `/autopilot <objectif>` (cf section "Articulation /autopilot" dans `dev-orchestrator/SKILL.md`) |
| **`/dispatch`** | Execution parallele d'un batch additif | Different — `/autopilot` boucle sur un objectif (multi-iterations), `/dispatch` execute N micro-taches one-shot |
| **Main session** | l'utilisateur invoque `/autopilot <objectif>` directement | Cas le plus courant |

**Resume** : `/autopilot` = agent goal-driven en background sur un objectif **separe** de la session courante. Multi-iterations via `/loop` + `state.md`. Lance-able par l'utilisateur directement OU par `/dev-orchestrator` quand il identifie une next step qui merite un agent autonome.

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

### 2. Gérer state.md existant + claim du handoff

**Claim obligatoire** : si le projet a un `memory/session-handoff.md` ou `.autopilot/handoff.md` lie a l'objectif → poser un claim `🔒 IN_PROGRESS` en tete du fichier AVANT la 1ere action + commit immediat. Si un claim existant < 4h → STOP et demander a l'utilisateur. Ref : CLAUDE.md global section "Claim du handoff au pickup".

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

**Principe** : le rapport est lu par l'utilisateur qui n'est pas développeur. Il doit comprendre **ce qui a changé**, **pourquoi j'ai fait les choix que j'ai faits**, et **ce qui arrive après** — sans jargon technique et sans relire le log.

**Règles de forme (obligatoires)** :
1. **Vraies phrases, pas de tableau de logs** en sortie principale
2. **Langage simple** — remplacer le jargon par des équivalents lisibles (ex: "CronDelete" → "tâche programmée supprimée", "git diff --name-only" → "la liste des fichiers modifiés", "itération" → "cycle de travail")
3. **Expliquer les choix** — chaque décision non-triviale = ce que j'ai choisi + **pourquoi** (ce que ça évite ou ce que ça gagne). l'utilisateur doit pouvoir dire "ok" ou "reviens en arrière".
4. **Structure narrative** — intro (ce qu'on voulait faire) → développement (ce qui a été fait, item par item, avec les choix expliqués) → conclusion (ce qui reste)
5. **Pas de plafond de longueur** — clair > compact. Un rapport clair de 500 mots > rapport obscur de 80 mots.
6. **Pas de code, de hash, ni de chemin fichier** dans le corps. Si vraiment nécessaire, dans une annexe technique ignorable à la fin.

**Structure recommandée** :

```markdown
# Ce qui s'est passé (en clair)

**Tu m'avais demandé :** [reformuler l'objectif en langage humain]

## Ce que j'ai fait concrètement

### 1. [Titre humain du premier bloc de travail]
[1-2 paragraphes qui expliquent ce qui a changé et pourquoi.]

**Les choix que j'ai dû trancher seul :**
- **[Question]** → J'ai choisi **[réponse]**. [Phrase qui explique la raison : ce que ça évite / ce que ça gagne.]

### 2. [Titre humain du second bloc]
...

## Ce qui a été essayé sans succès
[Si "Essayé — ne pas refaire" contient des entrées : les reformuler en phrases lisibles. Sinon : "rien".]

## Ce qu'il reste à faire
- [action suivante en 1 phrase simple]
- [...]

---
**Annexe technique** (si utile) : liste des fichiers modifiés, durée totale, nombre de cycles. Ignorable.
```

**Anti-patterns interdits** :
- Liste à puces sèche "Fait: X, Y, Z" sans contexte ni raison
- Plus de jargon que de mots courants
- Décisions listées sans expliquer pourquoi
- Plafond artificiel de longueur qui force la compression illisible

**Test de relecture** (Claude fait ce check avant d'envoyer) :
> "Si l'utilisateur relit ce rapport dans 2 semaines sans contexte, comprend-il (a) ce qui a changé, (b) pourquoi j'ai choisi X plutôt que Y, (c) ce qu'il doit faire ensuite ?" Si non → réécrire.

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
