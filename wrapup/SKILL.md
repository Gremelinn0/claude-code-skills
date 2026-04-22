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

## Step 2: Save Memories

Check the existing memory index and save or update memories as needed:

- **feedback** — any corrections or confirmed approaches from this session
- **project** — ongoing work, goals, deadlines, or context that future sessions need
- **user** — anything new learned about the user's role, preferences, or knowledge
- **reference** — any external resources, tools, or systems referenced

Rules:
- Don't duplicate existing memories — update them instead
- Don't save things derivable from code or git history
- Convert relative dates to absolute dates
- Include **Why:** and **How to apply:** for feedback and project memories

## Step 3: Write Session Summary + Handoff File

**3a — Session summary** (for NotebookLM Brain):

Create a markdown session summary with today's date. Keep it concise but complete.

Format:
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

Save this to a temp file at `/tmp/session-summary-YYYY-MM-DD.md`.

If there are multiple sessions in the same day, append a counter: `/tmp/session-summary-YYYY-MM-DD-2.md`

**3b — Persistent handoff file** (UNIQUEMENT si demande explicite OU si session PARTIAL_DONE / BLOCKED / WIP):

**NE PAS CREER de handoff par defaut.** Florent 2026-04-19 : "ça ne sert absolument à rien" de creer un handoff quand la session est close proprement et que tout est pushe. Les vrais documents (roadmap, feature docs, bug-patterns, matrices) suffisent.

**Creer un handoff UNIQUEMENT si :**
- L'user a explicitement demande "cree un handoff" / "je switch de compte"
- La session est PARTIAL_DONE / BLOCKED (travail interrompu a reprendre precisement)
- Il y a du WIP non-commite ou un etat mental a transmettre qui n'est pas deductible du git log + roadmap

**Si session DONE + tout pushe + rien en WIP** → skip ce step entierement. Passer direct a 3c.

**Liberation du claim (si cette session avait pose un claim au pickup) :**
Si cette session a commence par un pickup de handoff (bloc `🔒 IN_PROGRESS` pose en tete), le nouveau fichier handoff genere ci-dessous DOIT refleter l'etat final :
- Session **DONE** → pas de bloc claim en tete (handoff propre, libre pour reprise future si besoin)
- Session **PARTIAL_DONE / BLOCKED** → ajouter un bloc `⏸️ PAUSED — YYYY-MM-DD HH:MM — reprendre sur <etape>` en tete
- Dans tous les cas, le bloc `🔒 IN_PROGRESS` de l'ancien fichier ne doit PAS etre recopie dans le nouveau.
Ref : CLAUDE.md global section "Claim du handoff au pickup".

**Règle de naming — 1 fichier par session, PAS d'écrasement :**

Chaque `/wrapup` crée un NOUVEAU fichier dans `memory/handoffs/` :

```
memory/handoffs/YYYY-MM-DD-HHhMM-slug.md
```

Exemples :
- `memory/handoffs/2026-04-19-05h08-widget-maquette-html.md`
- `memory/handoffs/2026-04-19-14h32-chat-reader-ag-fix.md`

**Slug** = 2-4 mots kebab-case qui résument le sujet principal de la session (pas la date, pas "session").

**Contenu (identique à l'ancien format) :**

```markdown
# Session Handoff — YYYY-MM-DD HH:MM

## Projet / contexte
<Nom du projet, branche git, dernier commit hash>

## Ce qui a été fait dans cette session
<3-5 bullets max, actions concrètes>

## PROCHAINE ACTION IMMÉDIATE
<1 seule action claire, actionnable sans contexte additionnel>
<Ex: "Tester T18 dans /test-control-center — conditions: onglet Chrome ouvert, AG actif">

## WIP (travail en cours interrompu)
<Si la session s'est arrêtée au milieu de quelque chose : fichier modifié, où on en est, ce qui restait>
<Si rien en cours : "RAS — session proprement terminée">

## Bloqueurs actifs
<Ce qui bloque la prochaine action si applicable>

## Fichiers touchés dans cette session
<Liste des fichiers modifiés / créés>

## Comment reprendre (pour une nouvelle session / nouveau compte)
1. Lire ce fichier
2. Lire `memory/roadmap/roadmap.md` §1 priorité
3. Lancer `/preflight <feature>` si session coding
4. Exécuter "PROCHAINE ACTION IMMÉDIATE" ci-dessus
```

**3b-bis — Pointeur "latest" + index** :

Après avoir créé le fichier daté, mettre à jour 2 fichiers complémentaires :

1. **`memory/session-handoff.md`** — copie du dernier handoff (pour compat outils/skills qui lisent ce path). Ajouter un header au top :
   ```markdown
   > **Dernier handoff** — copie de `memory/handoffs/YYYY-MM-DD-HHhMM-slug.md`
   > Historique complet : [memory/handoffs/INDEX.md](handoffs/INDEX.md)
   ```

2. **`memory/handoffs/INDEX.md`** — ajouter une ligne EN HAUT (ordre anti-chronologique) :
   ```markdown
   - [YYYY-MM-DD HH:MM — slug](YYYY-MM-DD-HHhMM-slug.md) — 1 ligne résumé
   ```

**Règle :** tous les handoffs sont git-tracké. Chaque session a SON fichier permanent — jamais d'écrasement. `session-handoff.md` est un pointeur "latest" pratique, mais la vérité est dans `memory/handoffs/`.

**3c — Mise à jour `roadmap.md`** :

Si la session a changé le statut d'une feature, levé un bloqueur, ou ajouté une tâche → mettre à jour `memory/roadmap/roadmap.md` section concernée MAINTENANT, avant de pusher. Ne pas laisser roadmap.md en retard sur ce qui vient d'être fait.

**3d — Commit + push du handoff** :

```bash
git add memory/session-handoff.md memory/roadmap/roadmap.md
git commit -m "chore(wrapup): handoff session YYYY-MM-DD"
git push origin HEAD:dev
```

**3e — Bug-pattern capitalization + YAML post-mortem (OBLIGATOIRE)** :

Objectif : graver dans le marbre chaque bug resolu dans la session + verifier automatiquement que les fixes marchent via scan logs.

**Workflow :**

1. **Detecter les commits `fix(...)` de la session :**
   ```bash
   git log --oneline origin/dev..HEAD | grep -iE "^[a-f0-9]+ fix\("
   # Fallback si branche deja sync : git log --oneline HEAD~20..HEAD | grep -iE "fix\("
   ```

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
- Que le fichier `memory/session-handoff.md` a été commité et pushé (c'est le fichier à lire pour reprendre sur un autre compte)
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
