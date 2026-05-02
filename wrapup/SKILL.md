---
name: wrapup
description: End-of-session wrap-up — summarizes the session, saves key memories, and pushes a session log to the user's AI Brain NotebookLM notebook. Trigger on "/wrapup" or when user says "wrap up", "save this session", "end of session", "session summary".
---

# Session Wrap-Up

Run this at the end of every session to capture what happened and commit it to long-term memory.

## Step 0: Ensure AI Brain Notebook Exists

Before doing anything else, check if the user already has a Brain notebook set up.

**Check for saved notebook ID:**
Look for a memory file or config that stores the Brain notebook ID. Check the memory index for a reference like `brain_notebook_id`.

**If no notebook ID is saved:**

1. List existing notebooks: `notebooklm list --json`
2. Look for one titled "AI Brain" or similar (e.g. "[Name]'s AI Brain")
3. **If found:** Use that notebook's ID going forward
4. **If NOT found:** Tell the user:
   > "You don't have an AI Brain notebook yet. This is where I'll save a summary of every session so you can search, query, or generate reports from your history over time. Want me to create it now?"
5. If the user agrees, create it: `notebooklm create "[Name]'s AI Brain" --json`
6. Save the notebook ID to a memory file so future sessions find it automatically:
   ```
   Memory file: reference_brain_notebook.md
   Content: Brain notebook ID, title, and when it was created
   ```
   Also update the MEMORY.md index.

**If notebook ID IS saved:** Verify it still exists with `notebooklm list --json`. If it's been deleted, repeat the creation flow above.

## Step 1: Review the Session

Look back through the entire conversation and identify:

- **Decisions made** — what was decided and why
- **Work completed** — what was built, fixed, configured, or shipped
- **Key learnings** — anything surprising or non-obvious that came up
- **Open threads** — anything left unfinished or to revisit next time
- **User preferences revealed** — any new feedback about how the user likes to work
- **Pending live tests** — any test mentioned as "can't do now / requires live conditions / session dédié / prérequis absent" that isn't already in `memory/validation-pending-n4.md`

**If pending live tests found:** add them to `memory/validation-pending-n4.md` (table row + section entry) before continuing with Step 2.

## Step 2: Save & Improve Memories

**Objectif : améliorer l'état des memories, pas juste en ajouter.**

**2a — Nouvelles memories :** sauvegarder ce qui est appris dans cette session :

- **feedback** — corrections ou approches confirmées
- **project** — travail en cours, objectifs, deadlines, contexte
- **user** — nouvelles préférences ou connaissances révélées
- **reference** — ressources ou systèmes externes référencés

**2b — Mise à jour des memories existantes (PROACTIF) :** parcourir MEMORY.md et identifier les memories qui peuvent être améliorées grâce à ce qui a été découvert dans cette session :

- Une memory marquée OBSOLETE → la mettre à jour ou la supprimer
- Une memory dont le contenu est maintenant plus précis → l'enrichir
- Une date relative qui a tourné → la corriger en date absolue
- Une memory "projet" dont le statut a changé → refléter le nouvel état
- Une memory de feedback dont la règle a été affinée → préciser

**Règles :**
- Ne pas dupliquer — mettre à jour les existantes plutôt qu'en créer
- Ne pas sauvegarder ce qui est déductible du code ou du git history
- Convertir les dates relatives en dates absolues
- Inclure **Why:** et **How to apply:** pour les memories feedback et project

## Step 2.5: Plan vivant à jour (OBLIGATOIRE — règle CLAUDE.md §3)

**Source unique session + multi-compte** = Plan vivant dans `memory/features/<feature>.md` § Plan vivant (gravée 2026-05-01). Aucun handoff séparé.

Le hook PostToolUse `tools/plan_vivant_update_hook.py` met à jour automatiquement les blocs `<!-- ticket: ... -->` actifs (champs `last_session`, `last_account`, `commits[]`) à chaque `git commit`. Cette étape vérifie que la couche structurelle (statut, prochain pas, bloqueurs) reflète bien la session.

**Procédure** :

1. **Lister les features touchées** :
   ```bash
   git log --oneline origin/dev..HEAD --name-only | grep -E "memory/features/|app\.py|wisper-bridge/|cdp_|devtools_|cc_ui/" | sort -u | head -20
   ```

2. **Pour chaque feature concernée**, ouvrir `memory/features/<feature>.md` § Plan vivant et vérifier ses blocs `<!-- ticket: ... -->` :
   - **status** correct (`in-progress` → `closed` si objectif atteint et tests PASS)
   - **closed: YYYY-MM-DD** posé si fermeture
   - **priority** réévaluée si scope a changé
   - **Prochain pas** dans le corps Markdown (1-3 bullets) cohérent
   - **Bloqueurs** à jour (ou "aucun")
   - `last_session` / `last_account` / `commits` → laissés au hook (auto)

3. **Nouveau ticket** dans cette session (slug pas encore présent) → ajouter le bloc complet dans la sous-section `🔧 En cours` AVANT le commit final. Format :
   ```markdown
   <!-- ticket: <slug>
   status: in-progress
   opened: YYYY-MM-DD
   priority: P0|P1|P2
   account: florent.maisoncelle@gmail.com
   last_session: YYYY-MM-DD HH:MM
   last_account: florent.maisoncelle@gmail.com
   commits: []
   -->

   **[<slug>]** — Titre court
   - **Statut** : description
   - **Prochain pas** : 1-3 bullets
   - **Bloqueurs** : aucun
   ```

4. **Régénération automatique** : le hook `tools/plans_index_hook.py` régénère `memory/PLANS-INDEX.md` à chaque Edit/Write d'une feature doc. Aucune action manuelle. Vérifier que le diff `PLANS-INDEX.md` est cohérent dans le commit final.

**Règle** : aucun commit `/wrapup` ne sort si un ticket touché n'a pas son frontmatter à jour OU si la feature doc concernée n'a pas de section `## 📌 Plan vivant` (créer stub minimal sinon).

**Cas particuliers** :
- Session 100% docs/memory/config sans code feature → skip ce step
- Session touche 2-3 features → MAJ les blocs concernés dans chaque feature doc
- Refacto transversal → 1 ticket dominant, mentionner le scope dans le corps

## Step 3: Session Summary + Commit

**3a — Session summary** (pour NotebookLM Brain):

Créer un markdown court de la session avec date du jour. Concis mais complet.

```markdown
# Session Summary — YYYY-MM-DD

## What We Did
- Bullet points of key work completed

## Decisions Made
- Key decisions and their reasoning

## Key Learnings
- Non-obvious insights or discoveries

## Open Threads
- Anything to pick up next time

## Tools & Systems Touched
- List of tools, repos, services involved
```

Sauvegarder dans `/tmp/session-summary-YYYY-MM-DD.md` (counter `-2.md` si plusieurs sessions/jour).

**3b — PAS de handoff séparé (gravée 2026-05-01)**

Florent verbatim 2026-05-01 : *"ca sert a rien de créer des handoff si on a deja dans plans vivants"*. Le système handoff a été remplacé par les blocs `<!-- ticket: ... -->` dans le Plan vivant feature (cf. Step 2.5).

**Switch de compte multi-PC** = `git push` côté A puis `git pull` côté B suffit. Le Plan vivant est versionné, le hook a déjà MAJ `last_session` / `last_account` / `commits`. Pickup : `/migration-pickup <feature>` lit `memory/PLANS-INDEX.md` filtré par `last_account != current_account`.

**`memory/handoffs/`** : archive historique uniquement (`memory/_archive/handoffs-pre-2026-05-01/`). Pas de nouveau handoff créé. Si session laisse du WIP technique non-évident, le détailler dans le corps Markdown du ticket Plan vivant.

**3c — Mise à jour `roadmap.md`** :

Si la session a changé le statut d'une feature, levé un bloqueur, ou ajouté une tâche → mettre à jour `memory/roadmap/roadmap.md` section concernée MAINTENANT, avant de pusher. Ne pas laisser roadmap.md en retard sur ce qui vient d'être fait.

**3c-bis — Appel `/doc-keeper` si code modifié** :

Vérifier si la session contient des commits qui touchent du code :
```bash
git log --oneline origin/dev..HEAD | grep -vE "^[a-f0-9]+ (chore|docs|memory|wrapup)"
```

Si des commits code sont présents (`.py`, `.js`, `.html` dans `cc_ui/`, `wisper-bridge/`, `app.py`, etc.) → invoquer le skill `/doc-keeper` maintenant, avant le commit final.

`/doc-keeper` identifiera automatiquement les docs à mettre à jour (feature docs, platforms, FEATURES.md, interaction-mechanisms-matrix, validation-pending-n4.md) en fonction des fichiers touchés dans la session. Les mises à jour doc-keeper seront incluses dans le commit 3d.

Si la session est 100% docs/memory/config sans code → skip cette étape.

**3d — Commit + push du wrap-up** :

```bash
git add memory/features/ memory/PLANS-INDEX.md memory/roadmap/roadmap.md
git commit -m "chore(wrapup): session YYYY-MM-DD"
git push origin HEAD:dev
```

Plan vivant déjà MAJ par hook `plan_vivant_update_hook.py` au commit principal de la session. Cette étape pousse le wrap-up final (réorganisation tickets / closures / nouveaux blocs).

**3e — Validation tracker (OBLIGATOIRE — etendu 2026-04-26)** :

Objectif : pour CHAQUE livraison de la session (`fix`/`feat`/`docs`/`refactor`/`perf`), poser un mecanisme de verification ulterieure. Sans ca, regression silencieuse.

**Le hook PostToolUse `tools/validation_tracker_hook.py` se declenche AUTO sur chaque `git push` pendant la session** — il propose le mecanisme par type. Cette etape de `/wrapup` est le **filet de securite final** qui garantit que rien n'est passe entre les mailles.

**Workflow :**

1. **Detecter TOUS les commits livres de la session (pas juste fix) :**
   ```bash
   git log --oneline origin/dev@{1}..origin/dev | grep -iE "^[a-f0-9]+ (fix|feat|docs|refactor|perf)\("
   # Fallback : git log --oneline HEAD~20..HEAD | grep -iE "(fix|feat|docs|refactor|perf)\("
   ```

2. **Pour chaque commit, verifier le mecanisme depose** (cf. routing skill `/validation-tracker`) :

   | Type | Mecanisme attendu | Ou |
   |------|-------------------|-----|
   | `fix(...)` | YAML pending-verifications/ + BP (si classe) | `memory/pending-verifications/` |
   | `feat(...)` UI/voix/4 plateformes | Entree `validation-pending-n4.md` | `memory/validation-pending-n4.md` |
   | `feat(...)` log-able | YAML pending-verifications/ | `memory/pending-verifications/` |
   | `refactor(...)` significatif | YAML anti-regression | `memory/pending-verifications/` |
   | `docs(...)` alignement (dashboards/matrices) | post-session-check | `memory/post-session-checks/<date>-<slug>.md` |
   | `perf(...)` | YAML latence/CPU | `memory/pending-verifications/` |
   | `chore/test/build/ci/style/wrapup` | SKIP | — |

3. **Si un commit n'a PAS son mecanisme** → invoquer `/validation-tracker` pour le poser MAINTENANT. Refuser de cloturer `/wrapup` si gap detecte.

4. **Detail complet du routing** : skill `/validation-tracker` (point d'entree central, idempotent via cache JSON par session_id).

**Pour les `fix(...)` specifiquement (regle existante 2026-04-19) :**

2. **Pour chaque `fix(...)` commit, 2 actions :**

   **(a) Proposer MAJ de `memory/references/bug-patterns.md`** si la cause est une **classe de bug** (pas un one-shot). Signes :
   - Peut se reproduire ailleurs dans le code
   - Cause = pattern connu (thread, race, polling, permission, UIA/CDP, action auto sans cooldown, etc.)
   - Fix touche zone sensible (shutdown, auto-action, reader, watchdog)

   Structure pattern : Symptomes / Cause racine / Fix pattern / Detection logs / Declencheurs / Regle d'or.
   Jamais ecraser un BP existant — completer. Numero incremental BP-00X.

   **(b) Creer un YAML post-mortem** dans `memory/pending-verifications/fix-<slug>-YYYY-MM-DD.yaml` :
   ```yaml
   id: fix-<slug>-YYYY-MM-DD
   commit: <hash>
   description: <1 ligne — symptome que le fix doit supprimer>
   pattern_ref: BP-00X  # si pattern connu
   log_window: next_session  # ou "24h" / "7d"
   expect_absent_patterns:
     - regex: "<regex qui NE DOIT PAS matcher>"
       after_marker: "<marker optionnel>"
       max_occurrences: 0
   expect_present_patterns:
     - regex: "<regex qui DOIT matcher au moins 1x>"
       min_occurrences: 1
   tours: 0
   check_history: []
   ```
   Les regex sortent de la section "Detection logs" du BP. Pas de BP → brainstormer 1 regex `expect_absent` base sur les logs du bug d'origine.

3. **Commit les artefacts :**
   ```bash
   git add memory/references/bug-patterns.md memory/pending-verifications/*.yaml
   git commit -m "docs(bug-patterns): capitalize <slug> — BP-00X + YAML post-mortem"
   git push origin HEAD:dev
   ```

4. **Invoquer `/verify-fixes`** pour scanner les YAMLs pending contre les logs actuels (archive PASS / ticket FAIL / reverif INCONCLUSIVE).

**Regle absolue :** ZERO `fix(...)` commit ne sort d'une session sans YAML associe + sans tentative de capitalisation BP. Pas de YAML → pas de `/wrapup` fini. Si aucune classe de bug identifiee → `pattern_ref` vide mais YAML reste obligatoire.

**3f — Mise à jour pipeline de vérification continu (OBLIGATOIRE si nouveaux YAMLs)** :

Si la session a déposé au moins 1 nouveau YAML dans `memory/pending-verifications/`, s'assurer que le pipeline quotidien les verra :

1. **Confirmer** que les YAMLs sont bien dans `memory/pending-verifications/` (pas dans `_confirmed/` ni `_archive/`) — la tâche `speakapp-verify-fixes` (9h00 quotidien) scanne ce dossier automatiquement, rien à faire de plus.
2. **Si c'est la 1ère fois qu'on touche à ce pipeline dans la session** → vérifier que le workspace dans `~/.claude/scheduled-tasks/speakapp-verify-fixes/SKILL.md` contient bien `C:\Users\Administrateur\PROJECTS\3- Wisper\speak-app-dev` (et non `Utilisateur`).
3. **Résumé à donner à Florent** : "X nouveaux YAMLs déposés. `/verify-fixes` invoqué (tour 1). Pipeline quotidien `speakapp-verify-fixes` les scannera à 9h00."

**Note** : les YAMLs archivés dans `_confirmed/` (fixes déjà validés live) ne sont PAS rescannés — ils servent uniquement de preuve de non-régression consultable manuellement.

## Step 4: Push to NotebookLM Brain

**Méthode : Chrome MCP** (le CLI Playwright ne fonctionne pas quand Chrome est ouvert sur le PC de Florent).

Notebook : `https://notebooklm.google.com/notebook/662af98a-984c-4a8d-9a3d-1bf3d4a7f23c`
ID de référence : `memory/reference_brain_notebook.md`

**Procédure :**
1. Récupérer un tab via `tabs_context_mcp` (créer si vide)
2. Naviguer vers l'URL du Brain notebook
3. Trouver et cliquer le bouton "Ajouter une source" → option "Texte copié"
4. Coller le contenu de `/tmp/session-summary-YYYY-MM-DD.md` comme source texte
5. Titre de la source : `Session YYYY-MM-DD — [titre court]`

Si Chrome MCP indisponible → skip cette étape, les memories locales sont suffisantes.

## Step 5: Confirm

Tell the user:
- How many memories were saved/updated
- That the session summary was added to the Brain notebook (or skipped)
- Que les Plan vivants des features touchées sont à jour + `memory/PLANS-INDEX.md` régénéré (lecture côté autre compte = `git pull` + `/migration-pickup <feature>`)
- La PROCHAINE ACTION IMMÉDIATE en 1 phrase

Keep it brief. No need to read back the full summary — just confirm it's done.

## Error Handling

- If Chrome MCP unavailable: save memories locally, skip the notebook push, tell the user
- If the Brain notebook was deleted: re-créer via Chrome MCP sur notebooklm.google.com, mettre à jour `memory/reference_brain_notebook.md`
- If there's nothing meaningful to save: just say so, don't force empty memories

## Prerequisites

- Chrome MCP connecté (extension Claude in Chrome active dans le navigateur de Florent)
- Brain notebook ID dans `memory/reference_brain_notebook.md`
3. The skill handles everything else automatically on first run
