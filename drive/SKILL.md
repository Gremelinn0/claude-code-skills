---
name: drive
description: Dérouler la session active en autonomie — prendre les décisions techniques sans s'arrêter, finaliser proprement ou passer un handoff tracé à /autopilot. Invoquer quand Florent dit "drive", "finis ça", "déroule", "enchaîne", "va jusqu'au bout", "finalise".
trigger: user-invocable — /drive [note optionnelle]
scope: global — tout projet
---

# /drive — Finir la session en autonomie

Ce skill est le complement de `/autopilot`. `/autopilot` tourne en background sur un objectif separe. `/drive` **deroule la session active inline**, prend les decisions techniques seul, et finalise proprement.

**But : zero question evitable. La session sort soit en DONE, soit en HANDOFF traite pour que `/autopilot` puisse reprendre.**

---

## Regle absolue — perimetre = LA session active, rien d'autre

`/drive` finit la mission sur laquelle Florent et Claude travaillent **dans cette conversation**. 

**INTERDIT** d'ouvrir `roadmap.md`, `BACKLOG.md`, `handoff.md`, un feature doc ou tout autre fichier de backlog pour y piocher une tache a faire. `/drive` ne prend JAMAIS du travail en dehors de ce qui a ete discute dans la session. 

Si rien n'est en cours dans la session → dire "rien a drive, utilise `/autopilot <objectif>`" et s'arreter.

---

## Regle absolue — TOUS les sujets de la session, chacun a 100%

`/drive` est responsable de verifier que **chaque sujet aborde dans la session** est boucle a 100%, pas juste le dernier en cours.

**Phase 1 obligatoire : scanner la session entiere** et lister TOUS les sujets/chantiers ouverts (feature modifiee, bug evoque, doc a mettre a jour, commit a pousser, question en suspens). Pour CHAQUE sujet, verifier :
- Le code est-il ecrit / le doc est-il a jour / le commit est-il fait et pushe ?
- Les criteres de "fini" du sujet sont-ils remplis ?
- Y a-t-il une trace (commit, doc, handoff) pour le retrouver plus tard ?

Si un sujet aborde dans la session reste "a moitie" → c'est dans le perimetre de `/drive`, pas un truc "pour plus tard".

**Interdit** de finaliser `/drive` avec juste le dernier sujet boucle si 3 autres sujets ont ete evoques et laisses en suspens dans la meme session.

---

## Phase 1 — Cadrer l'objectif (scan complet de la session)

**A l'invocation :**

0. **Claim du handoff (si pickup)** — si la session reprend un `memory/session-handoff.md` ou `.autopilot/handoff.md` existant : verifier s'il contient deja un bloc `🔒 IN_PROGRESS`. Si oui ET < 4h → STOP, demander a l'utilisateur. Si non OU > 4h → poser le claim en tete du fichier (format CLAUDE.md global "Claim du handoff au pickup") + commit immediat avant toute action. Ref : CLAUDE.md global section "Claim du handoff au pickup".
1. **Relire la session entiere** (pas juste les 5-10 derniers messages) et lister TOUS les sujets abordes : features modifiees, bugs evoques, docs a jour a faire, commits a pousser, decisions prises a tracer, handoffs a ecrire.
2. Pour chaque sujet, noter son **etat actuel** : fini / a moitie / pas commence / ambigu.
3. **Lister a l'utilisateur** la vue d'ensemble avant de commencer (pas en silence) :
   ```
   J'ai identifie N sujets dans la session :
   1. [sujet] — etat : [fini / a moitie / pas commence]
   2. [sujet] — etat : ...
   Je vais tout finir. Scope exclu : [ce que je ne touche PAS, ex: roadmap, backlog].
   ```
4. Si un sujet est ambigu (2 directions possibles, pivot recent) → poser **UNE** question courte pour trancher. Sinon : continuer.
5. Note optionnelle passee a l'invocation (`/drive <note>`) = contrainte ou precision a injecter dans le plan.

**Format interne :**
```
Sujets de la session : [liste numerotee avec etat de chacun]
Objectif /drive : boucler les N sujets a 100%
Hors scope : roadmap, backlog, tout sujet non aborde dans la session
```

---

## Phase 2 — Decomposer en etapes finissables

Decomposer en 3 a 7 etapes concretes. Criteres :
- Chaque etape est **verifiable** (fichier ecrit, test passe, commit fait, deploy OK)
- L'ordre respecte les dependances
- Si une etape depasse clairement le scope session → la marquer `[HANDOFF]` des le plan (on ne la fera pas, on la trace)

**Si 2-8 etapes sont des micro-taches additives independantes** (ajout selecteur, mapping, prefixe, sur fichiers differents) → ne pas les executer une par une, **invoquer `/dispatch`** apres validation du plan pour les lancer en parallele via N sous-agents Sonnet + review Opus finale. Le plan reste sous responsabilite de `/drive`, `/dispatch` est juste l'executeur.

**Ecrire le plan en debut de reponse, puis attaquer.**

---

## Phase 3 — Executer en decidant

**Pour chaque etape, executer sans demander. Decider selon cette matrice :**

### Je decide seul (zero question) — 95% des cas

- Choix technique (nom de variable, structure de fichier, ordre des refactors)
- Detail d'implementation (algorithme, pattern, lib interne)
- Scope d'un fix (inclure le test ? oui, si c'est 5 lignes)
- Ordre des commits, nom de commit, message
- Reformulation de doc, renommage interne
- Run / relance / deploy quand c'est le flow normal du projet
- Investigation : quelle piste suivre en premier
- Gestion des erreurs non-critiques (log, retry, ignore selon contexte)

**Regle : si je me demande "est-ce que je demande ?" et que ce n'est PAS dans la liste escalade ci-dessous → je decide.**

### J'escalade (j'arrete et je demande) — 5% des cas

Liste stricte — seuls ces cas justifient une pause :

1. **Suppression / modification comportementale d'une feature visible utilisateur** (raccourci, setting, page, bouton que l'utilisateur utilise)
2. **Action irreversible a fort impact** (force push main, drop DB, suppression fichiers non reversibles, send email/message externe, deploy prod d'une breaking change)
3. **Credentials sensibles** (password, CB, cles API a generer ou revoquer, tokens auth)
4. **Decision produit majeure** (positionnement, pricing, scope V1, archi globale, business model)
5. **Conflit avec une regle CLAUDE.md** projet ou global — ne pas contourner, demander

**Hors de ces 5 cas : decider et logguer le choix dans le recap final.**

### Interdits formels

- Dire "je propose X, valide ?" pour un choix technique → decide et fais
- Dire "il faudrait que tu ouvres X" pour une app IA → automatiser (regle SpeakApp) ou route vers `/automation-first`
- S'arreter a la premiere friction → diagnostiquer, pivoter, finir ou handoff explicite
- Laisser une etape "a moitie" sans la cocher ou la handoff

---

## Phase 3.5 — Doc-routing gate (OBLIGATOIRE avant commit/fin de phase)

**Probleme historique (2026-04-18)** : session `/drive` a modifie 4 fichiers de code (clipboard gate, CDP gate, warm-up gate, dev_mode flag) + matrice + roadmap + handoff, mais a oublie 5 docs downstream (`chat-reader.md`, `cc-expand.md`, `cd-auto-permissions.md`, `control-center.md`, `platforms/claude-desktop.md`). Florent a detecte : "tres grave" — une session `/drive` sans doc-routing complet cree de la dette invisible.

**Regle : a la fin de chaque PHASE** (pas juste en fin de session), poser les 3 questions du doc-routing gate (CLAUDE.md projet §5) AVANT de committer :

| Q | Declencheur | Doc(s) cible(s) |
|---|-------------|----------------|
| **Q1** | Nouveau SELECTEUR / URL / DOM structure / UIA name / endpoint / ENV VAR / flag config decouvert ? | `memory/platforms/<plateforme>.md` (Axe A — dev) |
| **Q2** | Nouveau MECANISME / PATTERN transverse / decision architecturale / garde-fou ? | `memory/references/interaction-mechanisms-matrix.md` §9 Journal + §2 si impact capacite |
| **Q3** | STATUT FEATURE change (WIP→V1, bloqueur leve, critere valide, feature degrade en prod) ? | **TOUT** `memory/features/<feature>.md` impactee — pas seulement la feature "principale". Lister feature par feature. |

### Checklist obligatoire a derouler mentalement (OU en texte) avant chaque commit

**Etape 1 — recenser les fichiers code touches dans la phase** :
```
git diff --name-only HEAD~<N>..HEAD  # N = commits de la phase
```

**Etape 2 — pour CHAQUE fichier code modifie, lister les features downstream impactees** :
- `devtools_reader.py` → Chat Reader, CC Expand, Plan Reader, Question Handler, Chat Reader CD
- `app.py` (branche CD auto-perm) → CD Auto-Permissions, Control Center, Autopilote
- `app.py` (branche AG) → AG Auto-Permissions, CC Expand, Chat Reader AG, Watchdog
- `watchdog_engine.py` → Control Center, toutes features qui consomment les events (DONE, SIMPLE_CONFIRM, etc.)
- `cdp_reader.py` / `cdp_state_probe.py` → CC Expand, Chat Reader AG, Auto-Permissions AG
- `ws_bridge.py` → Chat Reader Chrome, CC Expand Chrome, Plan Reader Chrome, Question Handler Chrome
- `cc_ui/*` → Control Center + toute feature affichee dans le CC
- Nouveau flag config / ENV VAR → Axe A platform doc OU core doc + lister TOUTES les features qui consomment ce flag

**Etape 3 — ouvrir chaque doc impactee et ajouter (au MINIMUM)** :
- Une mention de la nouvelle gate/comportement en haut de l'etat actuel
- Une entree dans la section "Bugs connus" ou "Decisions de design" ou "Historique"
- Un renvoi `Ref : matrice §10 Dette #X` ou `§9 Journal YYYY-MM-DD` pour la tracabilite

**Etape 4 — ecrire dans le message de commit la liste des docs mises a jour** :
```
[PROD GATE] M1 DevTools CD clipboard fallback

- devtools_reader.py : gate fallback clipboard prod
- app.py : _dev_mode flag + 2 gates auto-perm
- [DOCS] chat-reader.md, cc-expand.md, cd-auto-permissions.md, control-center.md
- [DOCS] platforms/claude-desktop.md
- [DOCS] matrice §9 Journal + §10 Dette
- [DOCS] roadmap.md section Dette DevTools
```

### Interdits explicites

- **Committer un changement de code sans avoir liste les docs impactees** → si liste vide, ecrire explicitement `[DOCS] aucune (justification: bugfix isole, Q1/Q2/Q3 = N/A)`
- **Mettre a jour SEULEMENT matrice + roadmap** en oubliant les features downstream → c'est la friction qui a genere cette regle
- **Considerer "j'updaterai les docs plus tard"** → a faire AVANT le push, pas apres
- **Updater 1 feature doc "principale"** en oubliant les autres features impactees indirectement (ex: oublier que CC Expand consomme `devtools_reader`)

### Fast-path si la phase est petite

Pour un bugfix de 1-3 lignes :
- [x] Q1 : N/A
- [x] Q2 : N/A
- [x] Q3 : [feature X] bug documente dans la section Bugs

Ca reste 1 doc update minimum (la feature qui a le bug). Le fast-path n'est pas "skip", c'est "minimal".

### Auto-audit a la fin de la session

**Avant le recap final, relire la liste des commits de la session** (`git log origin/dev..HEAD --oneline`). Pour chacun, verifier que les docs downstream ont bien ete touchees. Si oui, mentionner dans le recap la liste `[DOCS]`. Si non → STOP, updater maintenant, pas de session en PARTIAL_DONE avec de la dette invisible.

---

## Phase 4 — Finaliser (obligatoire)

**Une session `/drive` ne se termine JAMAIS sur "j'ai fait une partie, a toi de voir".** Elle se termine dans un de ces 3 etats, explicitement.

### Tracabilite — toujours 2 ecritures (et 3 si projet avec roadmap)

**A chaque fin de `/drive`, quel que soit l'etat**, ecrire :

1. **Journal chrono (obligatoire)** — `<cwd>/.autopilot/drive-log.md`, append-only, 1 ligne compacte :
   ```
   | 2026-04-18 14:32 | DONE | Fix bug X reader | commit a3f9b2 | - |
   | 2026-04-18 16:05 | PARTIAL_DONE | Refacto module Y | commit b7d1c4 | handoff: reste tests E2E |
   | 2026-04-18 18:20 | BLOCKED | Deploy v2 prod | commit c8e3f6 | question: revenir a v1 si 500 ? |
   ```
   Creer le fichier avec header si inexistant :
   ```markdown
   # /drive — Journal chronologique

   | Date | Etat | Objectif | Commit | Note |
   |------|------|----------|--------|------|
   ```

2. **Handoff detaille** (si PARTIAL_DONE ou BLOCKED) — `<cwd>/.autopilot/handoff.md`, append-only (cf. format ci-dessous).

3. **Roadmap projet (si existe)** — si `<cwd>/memory/roadmap/roadmap.md` existe, ajouter/mettre a jour la section `## [DRIVE] Sessions autonomes` avec une entree :
   ```markdown
   ### 2026-04-18 — [OBJECTIF COURT]
   - **Etat** : DONE | PARTIAL_DONE | BLOCKED
   - **Fait** : [resume 1 ligne]
   - **Reste** : [1 ligne, ou "rien"]
   - **Commit** : [hash]
   - **Lien reprise** : `.autopilot/handoff.md` si PARTIAL/BLOCKED
   ```
   Si le fichier n'a pas la section `## [DRIVE]`, la creer a la fin.

**Regle : retrouver une execution = `grep <mot> .autopilot/drive-log.md` ou lire la section `[DRIVE]` de roadmap.md.**

### Etat DONE — tout est fait

- Toutes les etapes cochees `[x]`
- Tests pertinents passent (quand applicable)
- Commit + push effectue si le projet l'exige (voir CLAUDE.md projet)
- **Ecrire journal + roadmap** (cf. ci-dessus)
- **Invoquer `/wrapup` AUTOMATIQUEMENT** (cloture KB : memories, NotebookLM Brain, `memory/session-handoff.md` pour switch de compte). Obligatoire en DONE, pas en PARTIAL_DONE ni BLOCKED (session pas finie = capture prematuree).
- Recap final **humain** → **invoquer `/recap` separement** APRES `/wrapup`. `/drive` ne produit plus le recap final lui-meme, c'est la responsabilite de `/recap`.

**Ordre obligatoire en etat DONE** : commit+push → journal+roadmap → `/wrapup` → `/recap`.

### Etat PARTIAL_DONE — une partie faite, reste trace pour `/autopilot`

Quand le temps/scope force un arret mais qu'il reste du travail **reprendable sans moi** :

1. Commit + push ce qui est stable
2. **Ecrire journal + roadmap + handoff** :
   ```markdown
   ---
   ## [DATE ISO] — [TITRE COURT]

   **Origine** : session `/drive` du [DATE]
   **Objectif initial** : [1 phrase]

   **Ce qui est fait** :
   - [liste des etapes [x]]

   **Ce qui reste** :
   - [ ] [etape concrete 1 + fichier cible + critere de fin]
   - [ ] [etape concrete 2 + ...]

   **Contexte pour reprise** :
   - [1-3 lignes pour qu'une session cold puisse reprendre]

   **Commit de base** : [hash]
   **Bloqueur eventuel** : [rien | description]
   ```
3. Dire a l'utilisateur : "Handoff ecrit + trace dans roadmap. Relancer avec `/autopilot` quand tu veux."

### Etat BLOCKED — besoin de l'utilisateur

Quand un des 5 cas d'escalade est rencontre **ET** ne peut pas etre contourne :

1. Commit + push ce qui est stable avant le blocage
2. **Ecrire journal + roadmap + handoff** avec `Bloqueur : [cas precis, question a trancher]`
3. Poser la question a l'utilisateur, **une seule**, courte, binaire quand possible

**Interdit :** terminer en etat ambigu sans les 2 ecritures minimum (journal + handoff si applicable).

---

## Regles absolues

1. **Zero question technique** — si la reponse est deductible du contexte/docs/code, je decide. Je n'empile pas les "tu veux que je fasse X ou Y ?" pour des details.
2. **Lire avant de coder** — si le projet a un `CLAUDE.md` + `memory/`, les regles projet s'appliquent (preflight pour SpeakApp, doc-routing-gate, anti-boucle, TTS chunking, etc.)
3. **Mode Autonome Etendu 95%** — confirmer le 5% restant, pas plus
4. **Toute action utilisateur sur plateforme IA = a automatiser** — ne jamais dire "clique ici", integrer dans le code
5. **Finaliser obligatoirement** — DONE, PARTIAL_DONE avec handoff, ou BLOCKED avec handoff + question. Jamais rien d'autre
6. **Log les decisions non-evidentes** dans le recap final (1 ligne max par decision) — pas les details triviaux
7. **Sessions longues** : commits intermediaires reguliers, jamais un seul gros commit en fin
8. **Ne jamais contourner un garde-fou CLAUDE.md** pour "gagner du temps" — escalader proprement

---

## Cloture — 3 skills enchaines en DONE, 1 seul en PARTIAL/BLOCKED

**`/drive` ne produit plus le recap final lui-meme.** Il execute, commit, push, ecrit journal/handoff/roadmap — puis **enchaine les skills de cloture**.

**Pourquoi la separation :**
- `/drive` agit : execute, commit, push, journal/handoff/roadmap
- `/wrapup` capitalise : memories, NotebookLM Brain, `session-handoff.md` cross-compte
- `/recap` parle : message humain final lisible par Florent

**Workflow en DONE — ordre obligatoire :**
1. `/drive` finalise techniquement (commit + push + journal + roadmap)
2. `/drive` **invoque automatiquement `/wrapup`** (KB long-terme)
3. `/drive` **invoque automatiquement `/recap`** (message humain final)

**Workflow en PARTIAL_DONE ou BLOCKED :**
1. `/drive` ecrit `.autopilot/handoff.md` + journal + roadmap
2. `/drive` invoque `/recap` directement (**PAS `/wrapup`** — la session n'est pas finie, capture KB prematuree)
3. Florent reprendra avec `/autopilot` ou nouvelle session `/drive`

**Pourquoi `/wrapup` uniquement en DONE :** une session coupee a moitie ne doit pas polluer le NotebookLM Brain avec un summary partiel. Quand la session reprendra (via `/autopilot` ou nouvelle session), un nouveau `/drive` DONE declenchera alors le `/wrapup` complet.

**Florent peut toujours invoquer `/recap` seul a tout moment** (en cours de session) pour un point d'etape sans finaliser.

---

## Quand NE PAS utiliser `/drive`

| Situation | Utiliser plutot |
|---|---|
| Objectif nouveau, pas encore commence | `/autopilot <objectif>` |
| Exploration libre, brainstorm | conversation normale |
| Debug interactif ou je dois voir les reactions | conversation normale |
| Decision produit a valider avec utilisateur | demander directement |
| Tache physique requise (micro, ecran, validation visuelle) | escalade immediate |

`/drive` = **finir ce qui est en cours**. Si rien n'est en cours, c'est `/autopilot`.

---

## Auto-amelioration

Apres chaque usage, avant de conclure :
1. **Question posee que j'aurais du trancher seul ?** → reviser la matrice Phase 3, la rendre plus explicite
2. **Friction dans le handoff** (format pas repris proprement par `/autopilot`) → ajuster le format
3. **Bloqueur legitime rencontre ?** → verifier qu'il est bien dans les 5 cas — si pas, ajouter un 6e cas avec justification
4. **Gain applicable a `/autopilot` ?** → propager

Ne jamais reporter une amelioration. Appliquer maintenant ou la perdre.
