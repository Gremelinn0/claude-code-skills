---
name: wrapup
description: End-of-session wrap-up â€” summarizes the session, saves key memories, and pushes a session log to the user's AI Brain NotebookLM notebook. Trigger on "/wrapup" or when user says "wrap up", "save this session", "end of session", "session summary".
---

# Session Wrap-Up

Run this at the end of every session to capture what happened and commit it to long-term memory.

## Step 0bis : Anti-race parallel sessions (gravÃ©e 2026-05-13 â€” incident BP-377 cascade Phase 2)

> **ðŸš¨ RÃˆGLE NON-NÃ‰GOCIABLE â€” EmpÃªcher `/wrapup` parallÃ¨les de s'Ã©craser mutuellement les working trees**
>
> **Pourquoi cette rÃ¨gle existe** : pendant la session BP-377 cascade Phase 2 (Florent N4 live validation Grok+DeepSeek+Mistral 2026-05-12), plusieurs sessions Claude en parallÃ¨le sur le mÃªme repo SpeakApp ont eu leurs working trees Ã©crasÃ©s silencieusement par des `/wrapup` concurrents. Ma session a perdu des edits sur `wisper-bridge/manifest.json` + `memory/references/bug-patterns.md` 3 fois de suite avant de comprendre la cause. Verbatim Florent : *"oula j'en ai aucune idÃ©e je pense que c'est d'autres session qui bossent en mm temps mais je vois pas pq elles feraient ca en vrai donc je sai pas du tout"*.

### MÃ©canisme de protection â€” lockfile + heartbeat

**Avant TOUTE opÃ©ration git (`git add`, `git commit`, `git stash`, `git pull`, `git push`) du skill `/wrapup`** :

1. **Calculer un identifiant repo stable** :
   ```bash
   REPO_HASH=$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null | sha256sum | head -c 12)
   LOCK_DIR="$HOME/.claude/locks"
   LOCK_FILE="$LOCK_DIR/wrapup-$REPO_HASH.lock"
   mkdir -p "$LOCK_DIR"
   ```

2. **Check si un lock existe** :
   ```bash
   if [ -f "$LOCK_FILE" ]; then
     LOCK_AGE_SECONDS=$(($(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || stat -f %m "$LOCK_FILE")))
     if [ "$LOCK_AGE_SECONDS" -lt 600 ]; then
       LOCK_OWNER=$(cat "$LOCK_FILE" 2>/dev/null | head -1)
       echo "â›” /wrapup dÃ©jÃ  actif sur ce repo. Owner : $LOCK_OWNER (lock age $LOCK_AGE_SECONDS sec). Abort."
       exit 1
     else
       echo "âš ï¸ Lock stale (>10min). Take over."
     fi
   fi
   ```

3. **AcquÃ©rir le lock** :
   ```bash
   echo "$USER@$HOSTNAME pid=$$ session=<session_id_or_pwd> started=$(date -Iseconds)" > "$LOCK_FILE"
   trap "rm -f '$LOCK_FILE'" EXIT INT TERM
   ```

4. **Ã€ la fin du skill** (Step 5 cleanup) : `rm -f "$LOCK_FILE"` automatique via trap.

### DÃ©tection edits en cours d'autres sessions â€” pre-write guard

**Avant tout `git add` du skill `/wrapup`**, scanner le working tree pour des modifications NON faites par la session courante :

```bash
# 1. Lister fichiers modifiÃ©s/staged
git status --porcelain > /tmp/wrapup_pre_status_$$.txt

# 2. Comparer mtime des fichiers modifiÃ©s vs dÃ©but de session
SESSION_START_TS="<timestamp_session_start>"  # Ã  capturer en dÃ©but de session
for f in $(git diff --name-only HEAD); do
  FILE_MTIME=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")
  if [ "$FILE_MTIME" -gt "$SESSION_START_TS" ]; then
    # VÃ©rifier que CETTE session a touchÃ© ce fichier (cf. Edit/Write log session)
    if ! grep -q "$f" "$SESSION_TOUCHED_LOG"; then
      echo "âš ï¸ $f modified by another process (mtime=$FILE_MTIME, session_start=$SESSION_START_TS)"
      ABORT_SUSPECT=1
    fi
  fi
done

if [ -n "$ABORT_SUSPECT" ]; then
  echo "â›” Working tree contient des modifs d'une autre session. Synchronisation requise avant /wrapup."
  echo "Action : `git stash --include-untracked` puis re-run /wrapup."
  exit 1
fi
```

### Cas inaugural BP-377 â€” patterns d'Ã©crasement observÃ©s

Pendant la session 2026-05-12 22:30-23:55 :
1. **`wisper-bridge/manifest.json`** edit (ajout grok.com + chat.deepseek.com) reverted **3 fois** par autres sessions (probablement /wrapup qui faisait `git checkout HEAD --` ou rebase qui rÃ©solvait le conflit en favorisant l'autre branche)
2. **`memory/references/bug-patterns.md`** BP-369 entry reverted (allocation BP-369 perdue, j'ai dÃ» rÃ©-allouer en BP-377 aprÃ¨s race avec autre session qui a aussi allouÃ© BP-376 pour un autre sujet ChatGPT canvas)
3. **`memory/references/bp-registry.json`** dÃ©synchronisÃ© â€” BP-369 + BP-370 manquants localement, prÃ©sents upstream â†’ pre-commit hook bloquait jusqu'Ã  `--no-verify` avec approbation explicite Florent

### RÃ¨gles dÃ©rivÃ©es (Ã  appliquer dans CE skill et autres skills git-touch)

1. **Skill `/wrapup`** : section ci-dessus Ã  appliquer AVANT chaque Step 1.5 / 2.5 / 3d / 3e.
2. **Skill `/checkup-doc-sync`** : ne PAS faire `git stash` / `git checkout` sur fichiers NON modifiÃ©s par la session courante.
3. **Skill `/git-safe-push`** : dÃ©jÃ  fait stash auto Florent WIP â€” Ã©tendre logique pour dÃ©tecter modifs d'autres sessions et avorter avec message clair plutÃ´t que stash agressif.
4. **Hook PreToolUse `git_safe_op_hook.py` Ã  crÃ©er** (Sprint follow-up) : intercepter tout `git stash` / `git checkout` / `git reset` / `git rebase` venant d'un skill, scanner fichiers impactÃ©s, refuser si modifs d'une autre session dÃ©tectÃ©es.

### Anti-pattern interdit (gravage cette rÃ¨gle)

- âŒ `git stash` aveugle au dÃ©but de `/wrapup` (Step 3d implicite actuel) sans vÃ©rifier que les modifs sont Ã  la session courante
- âŒ `git checkout HEAD -- <fichier>` "pour nettoyer" sans diff visible Florent
- âŒ `git pull --rebase` automatique en cas de push rejected sans alerter l'user + sans prÃ©server les working tree edits d'autres sessions
- âŒ RÃ©gen d'index files (PLANS-INDEX.md, MEMORY.md, BP-INDEX.md) sans coordination â€” 2 sessions qui rÃ©gen en parallÃ¨le se chevauchent et crÃ©ent des diffs incohÃ©rents

### Action user immÃ©diate si suspect

Si Claude dÃ©tecte signal d'une autre session active :
- **STOP /wrapup**
- Afficher : *"Une autre session Claude semble active sur ce repo (lock $LOCK_FILE pid=X started=Y). Veux-tu : A â€” attendre 60s puis re-check, B â€” forcer takeover (perte possible des modifs autre session), C â€” abandonner /wrapup ?"*
- Attendre rÃ©ponse explicite avant tout `git` op.

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

- **Decisions made** â€” what was decided and why
- **Work completed** â€” what was built, fixed, configured, or shipped
- **Key learnings** â€” anything surprising or non-obvious that came up
- **Open threads** â€” anything left unfinished or to revisit next time
- **User preferences revealed** â€” any new feedback about how the user likes to work
- **Pending live tests** â€” any test mentioned as "can't do now / requires live conditions / session dÃ©diÃ© / prÃ©requis absent" that isn't already in `memory/validation-pending-n4.md`

**If pending live tests found:** add them to `memory/validation-pending-n4.md` (table row + section entry) before continuing with Step 1.5.

## Step 1.5: Sync codeâ†”docs via /checkup-doc-sync (gravÃ© 2026-05-10)

**Objectif** : avant de pousser des memories obsolÃ¨tes dans la KB long-terme (Step 3), garantir que les docs feature + bug-patterns + plan vivant + matrices reflÃ¨tent bien le code committÃ© pendant la session.

**ProcÃ©dure** : invoquer `/checkup-doc-sync` comme sous-Ã©tape automatique. Il fera :
- Map "Change Type â†’ Documents to Update" pour chaque commit de la session
- MAJ feature docs (PRD, Plan vivant, BPs connus)
- MAJ `bug-patterns.md` si nouveaux BPs allouÃ©s
- MAJ matrices (`platform-scenario-matrix.md`, `interaction-mechanisms-matrix.md`) si mÃ©canisme/sÃ©lecteur a bougÃ©
- MAJ `voice-commands.md` si hotkey/voix change
- MAJ `roadmap.md` si tÃ¢che livrÃ©e

**Distinction avec Step 2.5/2.6** :
- **Step 1.5** = **toute la doc projet large** (BPs, matrices, voice, roadmap, mÃ©canismes) â€” dÃ©lÃ©gation Ã  `/checkup-doc-sync`
- **Step 2.5** = Plan vivant per feature touchÃ©e (frontmatter + tickets)
- **Step 2.6** = Â§ Description fonctionnelle 2 niveaux (user-facing + technique)

`/checkup-doc-sync` reste appelable seul Ã  chaque commit intra-session (pour pas attendre fin de session). Ici en Step 1.5 = filet final qui rattrape les Ã©ventuelles oublis intra-session.

**Skip lÃ©gitime** : session 100% docs/memory sans code feature â†’ mention `[step 1.5 skip: aucun code committÃ©]` et passer Step 2.

## Step 2: Save & Improve Memories

**Objectif : amÃ©liorer l'Ã©tat des memories, pas juste en ajouter.**

**2a â€” Nouvelles memories :** sauvegarder ce qui est appris dans cette session :

- **feedback** â€” corrections ou approches confirmÃ©es
- **project** â€” travail en cours, objectifs, deadlines, contexte
- **user** â€” nouvelles prÃ©fÃ©rences ou connaissances rÃ©vÃ©lÃ©es
- **reference** â€” ressources ou systÃ¨mes externes rÃ©fÃ©rencÃ©s

**2b â€” Mise Ã  jour des memories existantes (PROACTIF) :** parcourir MEMORY.md et identifier les memories qui peuvent Ãªtre amÃ©liorÃ©es grÃ¢ce Ã  ce qui a Ã©tÃ© dÃ©couvert dans cette session :

- Une memory marquÃ©e OBSOLETE â†’ la mettre Ã  jour ou la supprimer
- Une memory dont le contenu est maintenant plus prÃ©cis â†’ l'enrichir
- Une date relative qui a tournÃ© â†’ la corriger en date absolue
- Une memory "projet" dont le statut a changÃ© â†’ reflÃ©ter le nouvel Ã©tat
- Une memory de feedback dont la rÃ¨gle a Ã©tÃ© affinÃ©e â†’ prÃ©ciser

**RÃ¨gles :**
- Ne pas dupliquer â€” mettre Ã  jour les existantes plutÃ´t qu'en crÃ©er
- Ne pas sauvegarder ce qui est dÃ©ductible du code ou du git history
- Convertir les dates relatives en dates absolues
- Inclure **Why:** et **How to apply:** pour les memories feedback et project

**ðŸš¨ FORMAT MEMORY.md NON-NÃ‰GOCIABLE (gravÃ©e 2026-05-13)** : MEMORY.md est un **INDEX**, pas un conteneur. Chaque entrÃ©e = **UNE LIGNE â‰¤150 chars** au format `- [Title](file.md) â€” hook 1-phrase.`. Le **contenu dÃ©taillÃ©** (verbatim Florent, contexte, diagnostic, commits, why, how to apply) va **dans le topic file** (`feedback_<slug>.md`, `project_<slug>.md`, etc.), JAMAIS inline MEMORY.md. Workflow correct : (1) crÃ©er/MAJ topic file avec frontmatter + contenu complet, (2) ajouter/MAJ 1 ligne pointer dans MEMORY.md. **Anti-pattern interdit** : copier 500-2000 chars de rÃ©sumÃ© directement dans MEMORY.md â†’ fichier explose au-dessus du quota 25KB en quelques sessions. Le hook `tools/memory_line_length_hook.py` warn si ligne ajoutÃ©e > 150 chars.

## Step 2.5: Plan vivant Ã  jour (OBLIGATOIRE â€” rÃ¨gle CLAUDE.md Â§3)

**Source unique session + multi-compte** = Plan vivant dans `memory/features/<feature>.md` Â§ Plan vivant (gravÃ©e 2026-05-01). Aucun handoff sÃ©parÃ©.

Le hook PostToolUse `tools/plan_vivant_update_hook.py` met Ã  jour automatiquement les blocs `<!-- ticket: ... -->` actifs (champs `last_session`, `last_account`, `commits[]`) Ã  chaque `git commit`. Cette Ã©tape vÃ©rifie que la couche structurelle (statut, prochain pas, bloqueurs) reflÃ¨te bien la session.

**ProcÃ©dure** :

1. **Lister les features touchÃ©es** :
   ```bash
   git log --oneline origin/dev..HEAD --name-only | grep -E "memory/features/|app\.py|wisper-bridge/|cdp_|devtools_|cc_ui/" | sort -u | head -20
   ```

2. **Pour chaque feature concernÃ©e**, ouvrir `memory/features/<feature>.md` Â§ Plan vivant et vÃ©rifier ses blocs `<!-- ticket: ... -->` :
   - **status** correct (`in-progress` â†’ `closed` si objectif atteint et tests PASS)
   - **closed: YYYY-MM-DD** posÃ© si fermeture
   - **priority** rÃ©Ã©valuÃ©e si scope a changÃ©
   - **Prochain pas** dans le corps Markdown (1-3 bullets) cohÃ©rent
   - **Bloqueurs** Ã  jour (ou "aucun")
   - `last_session` / `last_account` / `commits` â†’ laissÃ©s au hook (auto)

3. **Nouveau ticket** dans cette session (slug pas encore prÃ©sent) â†’ ajouter le bloc complet dans la sous-section `ðŸ”§ En cours` AVANT le commit final. Format :
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

   **[<slug>]** â€” Titre court
   - **Statut** : description
   - **Prochain pas** : 1-3 bullets
   - **Bloqueurs** : aucun
   ```

4. **RÃ©gÃ©nÃ©ration automatique** : le hook `tools/plans_index_hook.py` rÃ©gÃ©nÃ¨re `memory/PLANS-INDEX.md` Ã  chaque Edit/Write d'une feature doc. Aucune action manuelle. VÃ©rifier que le diff `PLANS-INDEX.md` est cohÃ©rent dans le commit final.

**RÃ¨gle** : aucun commit `/wrapup` ne sort si un ticket touchÃ© n'a pas son frontmatter Ã  jour OU si la feature doc concernÃ©e n'a pas de section `## ðŸ“Œ Plan vivant` (crÃ©er stub minimal sinon).

**Cas particuliers** :
- Session 100% docs/memory/config sans code feature â†’ skip ce step
- Session touche 2-3 features â†’ MAJ les blocs concernÃ©s dans chaque feature doc
- Refacto transversal â†’ 1 ticket dominant, mentionner le scope dans le corps

## Step 2.6: MAJ Â§ Description fonctionnelle TOUT LE TEMPS â€” 2 niveaux (gravÃ©e 2026-05-05, Ã©largie 2026-05-06, pilote intelligent 2026-05-13)

**ðŸš¨ CHANGEMENT DE PORTÃ‰E 2026-05-06** : ce step ne se dÃ©clenche PLUS uniquement "si statut V1 change". Il se dÃ©clenche **Ã  chaque session qui touche une feature**, peu importe la nature du changement (code, doc, fix, refactor, dÃ©cision tranchÃ©e, spec UX clarifiÃ©e, paire validÃ©e).

**ðŸŽ¯ PILOTE INTELLIGENT 2026-05-13 (BP-389 V1.2)** â€” pour les features SpeakApp (repo `speak-app-dev`), l'Ã©criture/MAJ de la Â§ Description fonctionnelle est dÃ©sormais **dÃ©lÃ©guÃ©e au skill pilote** `/update-feature-functional-doc <feature>` :
- Workflow 6 Ã©tapes (read sources / plan section / rÃ©daction langage user / Ã©criture / validation / reporting)
- Briques de rÃ©fÃ©rence (Quoi / Comment l'utiliser / Modes & options / Cas d'usage / Plateformes supportÃ©es / Limites V1)
- Anti-patterns explicites (zÃ©ro jargon, zÃ©ro pitch court â€” doc COMPLÃˆTE 3000-7000 chars, pas 3 paragraphes)
- Validation auto via pre-commit `tools/precommit_feature_doc_check.py`

**Quand invoquer `/update-feature-functional-doc <feature>` dans Step 2.6** :
- Â§ Description fonctionnelle absente ou < 1500 chars â†’ invocation immÃ©diate
- Â§ prÃ©sente mais polluÃ©e par jargon technique â†’ invocation pour refactor
- Spec UX / mode / option / cas d'usage / plateforme nouveau citÃ© ou modifiÃ© en session â†’ invocation pour MAJ
- Sinon (section dÃ©jÃ  complÃ¨te et propre, MAJ purement technique du niveau 2) â†’ skip, MAJ niveau 2 directement

Florent verbatim 2026-05-13 : *"pas comme un pinguin"* â€” pas de bricolage en mode "ajoute 3 paragraphes vite fait", dÃ©lÃ©guer Ã  l'outil pilote.

**Articulation hook PostToolUse `feature_doc_sync_hook.py`** : pendant la session, ce hook a probablement dÃ©jÃ  Ã©mis une alerte `ðŸ“ FEATURE DOC GATE â€” <feature> non conforme CLAUDE.md Â§3.7` quand tu as touchÃ© code feature sans MAJ doc. Si oui â†’ Step 2.6 = exÃ©cuter `/update-feature-functional-doc` pour purger la dette. Sinon â†’ audit manuel selon critÃ¨res ci-dessus.

Florent verbatim 2026-05-06 : *"ce qui m'intÃ©resse, c'est que la fonctionnalitÃ© elle soit bien dÃ©crite Ã  tout moment, d'un point de vue purement fonctionnel pour qu'on puisse derriÃ¨re dÃ©cliner tout Ã§a en site web, dÃ©mo, posts LinkedIn et rÃ©seaux sociaux etc, et la partie technique Ã©videmment pour que tu saches comment Ã§a marche et que tu puisses t'y rÃ©fÃ©rer si t'as des questions."*

### Les 2 niveaux Ã  maintenir DANS chaque feature doc

**Niveau 1 â€” Â§ Description fonctionnelle pure** (user-facing, copier-collable site web/dÃ©mo/LinkedIn)
- Langage humain, zÃ©ro jargon technique
- Argumentaire produit : ce que l'utilisateur peut faire concrÃ¨tement, dÃ¨s maintenant
- Statuts paires/plateformes lisibles d'un coup d'Å“il (âœ… validÃ© / ðŸ”§ in-progress / âŒ deprecated + date)
- ProcÃ©dure user en 3-5 Ã©tapes claires (langage user)
- Argumentaire pitch / sales : "Avec SpeakApp, tu peux X depuis ton clavier sans toucher la souris" â€” pas "le pipeline UIA Invoke fire en background sur le hwnd CD"

**Niveau 2 â€” Â§ ImplÃ©mentation technique** (Claude-facing, pour debug/extend)
- PRD Â§1 (sections 1.1-1.8) avec rÃ¨gles R-N
- Code paths `app.py:NNNN`, adapters, engines, watchdog
- MÃ©canismes M1-M5, sÃ©lecteurs UIA / CDP / DOM
- BPs allocÃ©s, traps connus, cooldowns/gates
- Plateformes par plateforme (statut V1 + adapter + entry point)

### ProcÃ©dure obligatoire (Ã  exÃ©cuter SYSTÃ‰MATIQUEMENT, pas conditionnel)

1. **Pour CHAQUE feature touchÃ©e dans la session** (cf. `git log --oneline origin/dev..HEAD --name-only` Step 2.5) :
   - Ouvrir `memory/features/<feature>.md`
   - Auditer **niveau 1** : la Â§ Description fonctionnelle reflÃ¨te-t-elle l'Ã©tat actuel ? Manque-t-il une nouvelle paire/plateforme/scÃ©nario/limitation/dÃ©cision UX ?
   - Auditer **niveau 2** : la Â§ ImplÃ©mentation technique cite-t-elle bien les nouveaux code paths / mÃ©canismes / BPs / sÃ©lecteurs touchÃ©s cette session ?
   - Si gap niveau 1 OU niveau 2 â†’ MAJ AVANT commit final wrapup

2. **Trigger systÃ©matique, pas conditionnel** :
   - âœ… Test live PASS â†’ MAJ niveau 1 (statut, date, procÃ©dure user) + niveau 2 (preuves logs, BP)
   - âœ… Fix livrÃ© â†’ MAJ niveau 1 (limite levÃ©e si user-visible) + niveau 2 (BP, code path, fix)
   - âœ… Spec UX clarifiÃ©e par Florent verbatim â†’ MAJ niveau 1 (nouvelle UX dÃ©crite) + niveau 2 (code path + Â§ DÃ©cisions stratÃ©giques Â§9bis)
   - âœ… Refactor / nouvelle archi â†’ MAJ niveau 2 (nouveaux fichiers, mÃ©canisme rÃ©visÃ©)
   - âœ… Nouvelle plateforme support â†’ MAJ niveau 1 (statut tableau plateformes) + niveau 2 (adapter, sÃ©lecteurs)
   - âœ… DÃ©cision tranchÃ©e avec options â†’ Â§9bis DÃ©cisions stratÃ©giques + niveau 1 si UX impacte user

3. **Gabarit minimal niveau 1** (si Â§ Description fonctionnelle absente, crÃ©er stub) :
   ```markdown
   ## 1.ter Description fonctionnelle pure (langage user, zero technique)

   ### Ce que l'utilisateur peut faire dÃ¨s maintenant
   <2-4 paragraphes argumentaire produit, langage humain>

   ### Comment l'utiliser (procÃ©dure 3-5 Ã©tapes)
   1. ...
   2. ...

   ### Statuts par plateforme / paire
   | Plateforme | Statut | Date validation | Limites V1 |
   |-----------|--------|-----------------|------------|
   | ... | âœ… V1 | 2026-XX-XX | ... |

   ### Argumentaire pitch (dÃ©clinable)
   <1-2 phrases punch pour site web / LinkedIn / dÃ©mo>
   ```

4. **Anti-patterns interdits** :
   - âŒ MAJ uniquement niveau 2 (technique) sans toucher niveau 1 (fonctionnel) â†’ Florent ne peut plus dÃ©cliner en marketing
   - âŒ MAJ uniquement niveau 1 sans niveau 2 â†’ Claude futur doit re-grep le code Ã  chaque question
   - âŒ "Pas de commit code aujourd'hui donc pas de doc Ã  MAJ" â†’ dÃ©cision UX clarifiÃ©e verbatim Florent change le niveau 1 sans toucher au code
   - âŒ Attendre statut V1 change pour MAJ â†’ niveau 1 doit reflÃ©ter le statut Ã€ TOUT MOMENT

### Cas inaugural 2026-05-06 â€” toast role A pilote-ia

Florent re-explique 3Ã— que le toast role A a 2 boutons Manager/ExÃ©cutant. Cause : niveau 1 (Â§ Description fonctionnelle) de pilote-ia.md ne dÃ©crivait pas explicitement le flow toast (manquait la partie "user clique 1 bouton"). Niveau 2 (code) avait la vÃ©ritÃ© dans `app.py:19517-19527`. Gap niveau 1â†”2 â†’ re-questionnement. Fix : flow gravÃ© 2026-05-06 dans Â§1.ter + Â§9bis DÃ©cisions stratÃ©giques.

### Cas inaugural 2026-05-05 â€” V1.1.C-CD-AG-STEP3 PASS T4

Test live T4 12:56 a validÃ© paire commerciale CDâ†’AG (pilote AG depuis CD avec Sonnet). Mais la Â§ "1.ter Triggers user-facing" de `pilote-ia.md` n'a pas Ã©tÃ© MAJ par /wrapup â†’ aucune mention "âœ… paire CDâ†”AG validÃ©e 2026-05-05" â†’ Florent demande "comment je test ?" alors que la rÃ©ponse Ã©tait Ã©vidente (Vosk `autopilote` + sÃ©lection sessions). Gap systÃ¨me dÃ©couvert.

---

## Step 2.6 (legacy â€” fusionnÃ© dans nouveau Step 2.6 ci-dessus 2026-05-06)

Section conservÃ©e pour rÃ©fÃ©rence historique. ProcÃ©dure complÃ¨te = Step 2.6 nouveau ci-dessus.

### DÃ©tails legacy (sub-section 2026-05-05)

**Gap historique identifiÃ©** : Plan vivant (Step 2.5) maj la couche **technique** (status ticket, prochain pas, bloqueurs). MAIS la Â§ **Description fonctionnelle** (`memory/features/<feature>.md` Â§ "Description fonctionnelle pure (langage user, zero technique)" â€” argumentaire client / ce que l'utilisateur peut faire) reste figÃ©e.

ConsÃ©quence : si un test live PASS valide une nouvelle paire/plateforme/scÃ©nario, la doc fonctionnelle continue d'afficher l'Ã©tat d'avant-hier â†’ Florent et Claude Code futures sessions n'ont pas la vue Ã  jour de "ce que l'utilisateur peut faire dÃ¨s maintenant".

**Florent verbatim 2026-05-05** : *"j'ai l'impression que Ã§a ne met pas Ã  jour la documentation fonctionnelle de la fonctionnalitÃ©. Ã‡a ne met Ã  jour que la documentation technique. Et Ã§a c'est trÃ¨s problÃ©matique."*

### ProcÃ©dure obligatoire

1. **DÃ©tecter changement statut V1** dans la session : test live PASS, fix livrÃ©, feature flip ON, nouvelle paire/plateforme validÃ©e, nouveau scÃ©nario passÃ©, dÃ©precation feature.
   ```bash
   # grep YAML pending verdict=PASS rÃ©cents OU commits feat/fix
   ls memory/pending-verifications/*.yaml | xargs grep -l "verdict: PASS" | head
   git log --oneline origin/dev..HEAD | grep -E "^[a-f0-9]+ (feat|fix)\("
   ```

2. **Pour chaque feature impactÃ©e**, ouvrir `memory/features/<feature>.md` et localiser la Â§ Description fonctionnelle (sous-titres typiques : "Description fonctionnelle pure", "1.ter Triggers user-facing", "Statuts paires plateformes", "Comment Ã§a marche", "User stories"). MAJ :
   - **Tableau statuts** : reflÃ©ter le nouveau statut (âœ… PASS, ðŸ”§ in-progress, âŒ deprecated)
   - **Date validation** : `2026-XX-XX (slug-ticket)`
   - **ProcÃ©dure utilisateur** : "Comment l'utilisateur teste/utilise cette nouveautÃ© dÃ¨s maintenant" (3-5 Ã©tapes claires, langage user, zero technique)
   - **Limites V1 connues** : si bug rÃ©siduel non bloquant (BP allouÃ©) â†’ mention courte + workaround
   - **Argumentaire pitch** : si paire/scÃ©nario commercial â†’ graver "âœ… livrÃ© depuis 2026-XX-XX"

3. **Anti-patterns interdits** :
   - âŒ MAJ uniquement Plan vivant (technique) sans toucher Â§ Description fonctionnelle (user-facing)
   - âŒ Laisser Â§ Description fonctionnelle figÃ©e alors qu'un test live PASS aujourd'hui change le statut
   - âŒ "Pas de commit code aujourd'hui donc pas de doc Ã  MAJ" â€” un test live PASS sans commit code DOIT quand mÃªme MAJ Â§ Description fonctionnelle

4. **Cas particuliers** :
   - Session 100% docs/memory/refactor sans changement statut V1 â†’ skip ce step
   - Session change statut V1 d'une feature pas encore dotÃ©e de Â§ Description fonctionnelle â†’ crÃ©er stub minimal (template `feature-doc-template.md` Â§1bis si dispo, sinon bloc 5 lignes)

### Cas inaugural 2026-05-05 â€” V1.1.C-CD-AG-STEP3 PASS T4

Test live T4 12:56 a validÃ© paire commerciale CDâ†’AG (pilote AG depuis CD avec Sonnet). Mais la Â§ "1.ter Triggers user-facing" de `pilote-ia.md` ligne 1380+ n'a pas Ã©tÃ© MAJ par /wrapup â†’ aucune mention "âœ… paire CDâ†”AG validÃ©e 2026-05-05" â†’ Florent demande "comment je test ?" alors que la rÃ©ponse Ã©tait Ã©vidente (Vosk `autopilote` + sÃ©lection sessions). Gap systÃ¨me dÃ©couvert.

## Step 2.7: Audit doc feature vs dÃ©cisions/specs clarifiÃ©es en session (gravÃ©e 2026-05-06)

**Gap systÃ¨me identifiÃ©** : Step 2.5 MAJ Plan vivant (technique) + Step 2.6 MAJ Description fonctionnelle (user-facing si statut V1 change). MAIS aucun step ne couvre le cas "Florent a clarifiÃ© verbatim une spec UX en session, sans commit code, sans changement statut V1" â†’ la doc reste figÃ©e alors que le contexte session a tranchÃ©.

**Cas inaugural 2026-05-06** : Florent verbatim *"juste la 1iÃ¨re t'as raison tu choisis 1 et le 2ieme sera evidemment l'autre"* (toast role A pilote-ia). DÃ©cision tranchÃ©e, options Ã©valuÃ©es, conditions re-Ã©val â€” mais la doc `pilote-ia.md` ne capturait que le code, pas la dÃ©cision. Sans gravage explicite, Claude future session re-pose la question 3 fois.

### ProcÃ©dure obligatoire

1. **Scan transcript session** : repÃ©rer
   - Verbatim Florent qui tranche un dÃ©bat ("on garde X parce que...", "juste Y", "on revient PAS sur Ã§a")
   - Specs UX clarifiÃ©es (boutons, hotkeys, flows, langage) que Florent confirme/corrige
   - DÃ©cisions stratÃ©giques avec options Ã©valuÃ©es (cf. critÃ¨res CLAUDE.md Â§3.7 invocation `/decision-log`)
   - Specs dÃ©duites par investigation code que Florent valide ("OK c'est Ã§a")

2. **Pour chaque clarification, vÃ©rifier qu'elle est gravÃ©e dans la doc feature** :
   - **Spec fonctionnelle** â†’ `memory/features/<feature>.md` Â§ PRD Â§1 (sections 1.1-1.8)
   - **Comportement UX** â†’ Â§ Description fonctionnelle / Â§ Triggers user-facing
   - **DÃ©cision tranchÃ©e avec options/verbatim/conditions** â†’ invoquer `/decision-log <feature> <slug>` (section `## DÃ©cisions stratÃ©giques` du feature doc)
   - **Convention/rÃ¨gle Ã©mergente** â†’ `PROPOSITION DE REGLE` via `/rule-creator`

3. **Si gap dÃ©tectÃ©** â†’ MAJ AVANT commit final wrapup. Pas de "session fermÃ©e + spec verbatim non gravÃ©e".

4. **Articulation hook `feature_doc_sync_hook.py`** (PostToolUse Edit/Write) : le hook fire quand code feature touchÃ© sans MAJ doc dans la session. Si rappel hook dÃ©jÃ  ignorÃ© dans la session avec justification `[doc-sync skip: <raison>]`, accepter. Sinon â†’ MAJ doc obligatoire ici.

5. **CritÃ¨re PASS Step 2.7** : 0 verbatim Florent qui tranche un dÃ©bat dans la session courante reste sans graver dans la doc feature concernÃ©e.

### Anti-patterns interdits

- âŒ ClÃ´turer wrapup avec "j'ai entendu Florent dire X mais j'ai pas eu le temps de mettre Ã  jour la doc"
- âŒ Attendre la prochaine session pour graver une dÃ©cision tranchÃ©e â†’ dÃ©cision perdue dans le vent (cf. CLAUDE.md Â§3.7 *"j'ai trop de trucs Ã  penser. Si tu n'enregistres pas, c'est perdu dans le vent"*)
- âŒ Mettre la dÃ©cision uniquement dans le commit message â†’ invisible aux invocations skill futures

### RÃ©fÃ©rence rÃ¨gle source

CLAUDE.md projet ligne 449 (gravage 2026-05-06) : *"Skills + feature docs = MAJ same-commit que code/doc rÃ©fÃ©rencÃ©. Code path change â†’ MAJ `memory/features/<feature>.md` + skill MEME commit (sinon doc dÃ©rive du code, je re-questionne Florent sur des specs dÃ©jÃ  gravÃ©es â€” cas toast role A 2026-05-06)."*

## Step 3: Session Summary + Commit

**3a â€” Session summary** (pour NotebookLM Brain):

CrÃ©er un markdown court de la session avec date du jour. Concis mais complet.

```markdown
# Session Summary â€” YYYY-MM-DD

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

**3b â€” PAS de handoff sÃ©parÃ© (gravÃ©e 2026-05-01)**

Florent verbatim 2026-05-01 : *"ca sert a rien de crÃ©er des handoff si on a deja dans plans vivants"*. Le systÃ¨me handoff a Ã©tÃ© remplacÃ© par les blocs `<!-- ticket: ... -->` dans le Plan vivant feature (cf. Step 2.5).

**Switch de compte multi-PC** = `git push` cÃ´tÃ© A puis `git pull` cÃ´tÃ© B suffit. Le Plan vivant est versionnÃ©, le hook a dÃ©jÃ  MAJ `last_session` / `last_account` / `commits`. Pickup : `/migration-pickup <feature>` lit `memory/PLANS-INDEX.md` filtrÃ© par `last_account != current_account`.

**`memory/handoffs/`** : archive historique uniquement (`memory/_archive/handoffs-pre-2026-05-01/`). Pas de nouveau handoff crÃ©Ã©. Si session laisse du WIP technique non-Ã©vident, le dÃ©tailler dans le corps Markdown du ticket Plan vivant.

**3c â€” Mise Ã  jour `roadmap.md`** :

Si la session a changÃ© le statut d'une feature, levÃ© un bloqueur, ou ajoutÃ© une tÃ¢che â†’ mettre Ã  jour `memory/roadmap/roadmap.md` section concernÃ©e MAINTENANT, avant de pusher. Ne pas laisser roadmap.md en retard sur ce qui vient d'Ãªtre fait.

**3c-bis NON-NÃ‰GOCIABLE â€” MAJ Â§ "ðŸŽ¯ Plan global SpeakApp" dans roadmap.md (DEV pur) [BP-383 gravÃ©e 2026-05-13]** :

> **ðŸš¨ RÃˆGLE NON-NÃ‰GOCIABLE** â€” Florent verbatim 2026-05-13 : *"tu n'as aucuns plan globale pour dev l'app ce qui Ã©tait supposÃ© etre la roadmap mais tu as pas l'air de l'alimenter"* + *"tu mÃ©langes les skills, tu mÃ©langes toutes les compÃ©tences, la roadmap"*. Cette sous-Ã©tape MAJ **uniquement la couche DEV** (roadmap.md). Le NON-DEV (Notion) est dÃ©lÃ©guÃ© intÃ©gralement au skill `/chef-projet-speakapp-notion` â€” appeler ce skill sÃ©parÃ©ment si session a touchÃ© un sujet non-dev. SÃ©paration propre obligatoire, ZÃ‰RO mÃ©lange.

### ProcÃ©dure rigoureuse â€” Florent ne doit RIEN se rappeler, Claude exÃ©cute tout

> **PRINCIPE** : Claude scanne la session de bout en bout AVANT de toucher roadmap.md. Pas de "j'oublie", pas de "skip". Si Claude ferme une session de code sans avoir exÃ©cutÃ© cette procÃ©dure â†’ faille systÃ¨me, Ã  graver dans MEMORY.md feedback.

#### Ã‰tape 1 â€” Scan session (5 commandes obligatoires, ZÃ‰RO interprÃ©tation)

```bash
cd "C:/Users/Utilisateur/PROJECTS/3- Wisper/speak-app-dev"

# 1a â€” Tous commits depuis last wrapup
LAST_WRAPUP=$(git log --oneline --grep="^chore(wrapup)" -1 --format=%H)
git log --oneline "$LAST_WRAPUP"..HEAD 2>/dev/null > /tmp/wrapup_commits.txt
cat /tmp/wrapup_commits.txt

# 1b â€” Verbatim Florent significatifs cette session (extraits messages user)
# â†’ Claude scanne sa propre transcript pour patterns suivants :
#    "on garde X parce que" / "on revient PAS sur" / "scope V1 c'est"
#    "Ã§a c'est bloquant" / "prioritÃ© numÃ©ro 1" / "Ã  diffÃ©rer"
#    "date cible" / "go-live le" / "Beta privÃ©e le"
#    "valide" / "PASS" / "Ã§a marche" / "âœ…" sur un critÃ¨re prÃªt go-live
#    "site web" / "packaging" / "Mac" / "ventes" / "marketing" / "pricing"
#    "support" / "juridique" / "i18n" / "internationalisation"

# 1c â€” Fichiers touchÃ©s (pour dÃ©tection non-dev)
git diff --name-only "$LAST_WRAPUP"..HEAD 2>/dev/null | sort -u > /tmp/wrapup_files.txt
cat /tmp/wrapup_files.txt

# 1d â€” YAMLs verdict PASS rÃ©cents (critÃ¨res prÃªt cochables)
ls -t memory/pending-verifications/_confirmed/ 2>/dev/null | head -10

# 1e â€” Lecture Ã©tat actuel Â§ Plan global
grep -A 80 "^## ðŸŽ¯ Plan global SpeakApp" memory/roadmap/roadmap.md > /tmp/wrapup_plan_global_before.txt
```

#### Ã‰tape 2 â€” Audit 4 sous-sections (checklist binaire, 1 ligne par item)

> **Pour CHAQUE item ci-dessous, Claude Ã©crit explicitement OUI ou NON dans la session avant de continuer. Pas de "probablement", pas de "Ã  voir".**

**Item 2.1 â€” Vision V1** :
- Question : un des verbatims Florent Â§1b cette session change-t-il le pÃ©rimÃ¨tre user / la liste features V1 / les plateformes ciblÃ©es / l'exclusion CD ?
- Si OUI â†’ MAJ paragraphe Vision V1 avec verbatim exact entre guillemets.
- Si NON â†’ Ã©crire dans transcript "Vision V1 : intact".

**Item 2.2 â€” Top 5 bloqueurs (LEVÃ‰)** :
- Question : un commit `fix(...)` / `feat(...)` Â§1a livrÃ© cette session correspond-il au slug ou BP-NNN d'un bloqueur du Top 5 actuel ?
- Si OUI â†’ retirer ce bloqueur du Top 5 + le dÃ©placer dans Â§ "ðŸŸ¡ Code livrÃ© N4 pending" + Ã©crire dans transcript "Bloqueur X levÃ© code â†’ N4 pending".
- Si NON â†’ Ã©crire dans transcript "Aucun bloqueur Top 5 levÃ© code cette session".

**Item 2.3 â€” Top 5 bloqueurs (NOUVEAU)** :
- Question : un verbatim Florent Â§1b contient-il "Ã§a c'est bloquant" / "prioritÃ© 1" / "il faut absolument" / "sans Ã§a pas de go-live" ?
- Si OUI â†’ ajouter dans Top 5 (position selon prioritÃ© Florent dictÃ©e) avec verbatim entre guillemets.
- Si NON â†’ Ã©crire dans transcript "Aucun nouveau bloqueur Florent verbatim".

**Item 2.4 â€” CritÃ¨res "prÃªt go-live"** :
- Question : un YAML Â§1d rÃ©cemment archivÃ© `_confirmed/` correspond-il Ã  un critÃ¨re listÃ© OU un verbatim Florent Â§1b dit "Ã§a marche" / "PASS" / "âœ…" sur un critÃ¨re ?
- Si OUI â†’ cocher `- [x] <critÃ¨re>` + date + ref commit dans la checklist.
- Si NON â†’ Ã©crire dans transcript "Aucun critÃ¨re prÃªt nouveau cochÃ©".

**Item 2.5 â€” Date cible** :
- Question : un verbatim Florent Â§1b mentionne-t-il "date cible" / "go-live le" / "Beta privÃ©e fin X" / "deadline" ?
- Si OUI â†’ MAJ paragraphe Date cible avec date + verbatim.
- Si NON â†’ Ã©crire dans transcript "Date cible intacte".

#### Ã‰tape 3 â€” DÃ©tection non-dev (auto, scan fichiers + verbatims)

```bash
# Auto-dÃ©tection sujet non-dev touchÃ©
NON_DEV_PATTERNS="site.web|landing|loveable|vercel|packaging|msix|setup|installer|mac|portage|ventes|marketing|linkedin|carousel|post|pricing|stripe|payment|support|onboarding|juridique|legal|cgu|cgv|privacy|terms|i18n|internationali|traduction"

# Files touched matching non-dev :
grep -iE "$NON_DEV_PATTERNS" /tmp/wrapup_files.txt | head -10

# Florent verbatim non-dev cette session ? (Claude scanne sa transcript)
# â†’ liste manuelle des patterns dÃ©tectÃ©s
```

Si UN match â†’ **invoquer `/chef-projet-speakapp-notion`** pour MAJ Notion. Si zÃ©ro match â†’ mention "non-dev intact" dans Historique.

#### Ã‰tape 4 â€” Ligne Â§ Historique session courante (format strict obligatoire)

Format exact :
```
- **YYYY-MM-DD HH:MM** [session-slug-court] : <rÃ©sumÃ© 1 phrase action principale>
  Â· vision=<intact|MAJ-verbatim>
  Â· top5=<intact|+N nouveau|âˆ’N levÃ© code|rÃ©ordonnÃ©>
  Â· critÃ¨res=<X/11 cochÃ©s (+N nouveau)|intact>
  Â· date=<intact|MAJ JJ/MM/YYYY>
  Â· non-dev=<intact|dÃ©lÃ©guÃ© /chef-projet-speakapp-notion>
```

#### CritÃ¨re PASS Step 3c bis (NON-NÃ‰GOCIABLE)

Claude a Ã©crit dans la transcript : 5 lignes Ã‰tape 2 (OUI/NON par item) + 1 ligne Â§ Historique format strict + invocation effective `/chef-projet-speakapp-notion` si non-dev dÃ©tectÃ©. **Sans ces 6 lignes, Step 3c bis n'est PAS terminÃ©**. Claude ne passe pas Step 3d (commit final).

#### Anti-patterns interdits (gravage permanent)

- âŒ Skipper Step 3c bis "parce que la session Ã©tait purement technique" â†’ audit 4 sous-sections quand mÃªme + ligne "intact" obligatoire.
- âŒ Ne mettre Ã  jour QUE "âœ… LivrÃ© rÃ©cemment" en oubliant Â§ Plan global â†’ les 2 sont indÃ©pendants, MAJ les 2.
- âŒ Inventer un bloqueur Florent n'a pas validÃ© verbatim â†’ marquer "âš ï¸ Florent Ã  confirmer" si proposition Claude.
- âŒ Sauter Ã‰tape 3 dÃ©tection non-dev â†’ /chef-projet-speakapp-notion oubliÃ© = Notion dÃ©synchronisÃ©.
- âŒ Format ligne Historique libre â†’ format strict 7 lignes obligatoire pour grep ultÃ©rieur.
- âŒ Florent doit deviner ce qu'il manque â†’ Claude scanne, Claude dÃ©cide, Claude Ã©crit. Florent valide en lecture finale.

**3c-ter â€” Appel `/doc-keeper` si code modifiÃ©** :

VÃ©rifier si la session contient des commits qui touchent du code :
```bash
git log --oneline origin/dev..HEAD | grep -vE "^[a-f0-9]+ (chore|docs|memory|wrapup)"
```

Si des commits code sont prÃ©sents (`.py`, `.js`, `.html` dans `cc_ui/`, `wisper-bridge/`, `app.py`, etc.) â†’ invoquer le skill `/doc-keeper` maintenant, avant le commit final.

`/doc-keeper` identifiera automatiquement les docs Ã  mettre Ã  jour (feature docs, platforms, FEATURES.md, interaction-mechanisms-matrix, validation-pending-n4.md) en fonction des fichiers touchÃ©s dans la session. Les mises Ã  jour doc-keeper seront incluses dans le commit 3d.

Si la session est 100% docs/memory/config sans code â†’ skip cette Ã©tape.

**3c-quater â€” Sync Notion tasks (NON-NÉGOCIABLE — gravée 2026-05-18 incident gap suivi)** :

> 🚨 **RÈGLE NON-NÉGOCIABLE** — Florent verbatim 2026-05-18 : *"pq tu me dis que t'as mis à jour le backlog et ou les plans vivants et/ou notion pour le suivi :/ tu vraiment insister la dessus dans /wrapup"* + *"améliore surtout le skill stp wrapup"*. Incident origine : `/wrapup` post-/drive 2026-05-18 a affirmé "Notion task synced + backlog MAJ" sans avoir réellement exécuté la procédure sur la tâche Notion Sentry vague 5 `36401e69-443c-8170-95d2-c11183f80385`. Faute classique : Claude annonce le suivi sans le faire. Cette étape blinde ça : Claude scanne Notion + écrit OUI/NON par commit + refuse de clôturer si gap détecté.

### Différence avec Step 3c-bis Étape 3 (non-dev) — ne pas confondre

- **Step 3c-bis Étape 3** = détection sujet NON-DEV touché en session (site web, packaging, marketing, juridique, i18n) → délègue à `/chef-projet-speakapp-notion` pour MAJ pages projet macro
- **Step 3c-quater (ICI)** = sync commits DEV avec tâches Notion EXISTANTES qui les trackent (vagues sub-agents, BPs alloués, features V1 en cours). Pas de délégation, post comment direct via `notion-create-comment`.

Les 2 étapes coexistent et ne se substituent pas. Step 3c-quater fire systématiquement même si Step 3c-bis n'a détecté aucun non-dev.

### Procédure rigoureuse — Notion = source unique suivi DEV multi-PC

> **PRINCIPE** : pour CHAQUE commit DEV livré cette session, Claude vérifie qu'une tâche Notion correspondante reflète l'état post-commit. Pas de "j'oublie", pas de "skip silencieux", pas de "Florent verra le commit dans git log".

#### Étape 1 — Vérifier dispo MCP Notion + lister commits avec impact suivi

```bash
cd "C:/Users/Utilisateur/PROJECTS/3- Wisper/speak-app-dev"

# Tous commits depuis last wrapup, hors chore/wrapup/style/test/build/ci
LAST_WRAPUP=$(git log --oneline --grep="^chore(wrapup)" -1 --format=%H)
git log --oneline "$LAST_WRAPUP"..HEAD | grep -iE "^[a-f0-9]+ (fix|feat|docs|refactor|perf)\(" > /tmp/wrapup_notion_commits.txt
cat /tmp/wrapup_notion_commits.txt
```

**Si MCP Notion indisponible** (tools `mcp__*__notion-search` / `notion-create-comment` non chargés) → SKIP Step 3c-quater avec mention explicite "Notion MCP non disponible, suivi à rattraper prochaine session avec MCP actif". Ne PAS prétendre avoir synced.

**Si aucun commit DEV dans la session** (session 100% docs/memory/config) → SKIP avec mention "Aucun commit DEV nécessitant suivi Notion".

#### Étape 2 — Pour CHAQUE commit du fichier ci-dessus, OBLIGATOIRE :

1. **Extraire le slug + BP du message commit** (ex: `bb6d2a02 fix(sentry): BP-479 V1.1 - hot init signature bug P0` → slug=`sentry`, BP=`BP-479`, type=`fix`).

2. **Query Notion via `mcp__*__notion-search`** avec keywords (multi-tentatives si zéro résultat) :
   - 1ère tentative : `query="<BP-NNN>"` (ex `BP-479`)
   - 2ème tentative si rien : `query="<slug> vague"` (ex `Sentry vague`) si BP couvert par tâche vague sub-agents
   - 3ème tentative si rien : `query="<feature-name>"` (ex `Sentry opt-in`) si BP couvert par tâche feature V1
   - Filter `query_type=internal` pour ne chercher que dans la workspace SpeakApp

3. **Décision selon résultat search** :

   | Cas | Action obligatoire |
   |-----|---------------------|
   | 1 tâche trouvée matching | `notion-create-comment` sur la tâche avec : commit hash + résumé delta (1-2 phrases) + action restante si applicable. Capturer `comment-id` retourné. |
   | Plusieurs tâches matching | Sélectionner la plus pertinente (status `À faire` ou `En cours` prioritaire vs `Terminé`) + comment. Si ambiguïté réelle → comment sur les 2-3 tâches concernées. |
   | Aucune tâche trouvée ET commit critique (P0/P1 user-visible OU BP majeur) | Créer nouvelle tâche dans le sous-projet pertinent via `notion-create-pages` (table Tâches, parent = page sous-projet). Capturer `page-id` retourné. |
   | Aucune tâche trouvée ET commit non-critique (refactor interne / docs minor / style) | SKIP avec mention "non-tracké Notion volontairement (raison: <X>)" dans output Étape 3. |

#### Étape 3 — Output OBLIGATOIRE format strict (1 ligne par commit minimum)

Claude écrit explicitement dans la transcript de la session :

```
NOTION SYNC AUDIT — Step 3c-quater :
- Commit <hash1> [<type>] <slug> → tâche Notion `<page-id>` MAJ via comment `<comment-id>` (statut: <X>)
- Commit <hash2> [<type>] <slug> → tâche Notion `<page-id>` MAJ via comment `<comment-id>`
- Commit <hash3> [<type>] <slug> → AUCUNE tâche Notion existante, créée nouvelle `<new-page-id>` dans sous-projet `<X>`
- Commit <hash4> [<type>] <slug> → SKIP non-tracké volontairement (raison: <refactor interne / docs minor>)
- Total : X commits / Y synced / Z créés / W skipped
```

#### Critère PASS Step 3c-quater (NON-NÉGOCIABLE)

Claude a posté ≥1 ligne par commit (sauf SKIP justifié explicite) avec :
- `page-id` Notion concret (format `36401e69-443c-...`)
- `comment-id` retourné par `notion-create-comment` (format `36401e69-443c-...`)
- OU `new-page-id` retourné par `notion-create-pages` si tâche créée
- OU justification SKIP explicite (raison non-trivialement déductible)

**SANS ces preuves explicites par commit → Step 3c-quater FAIL → /wrapup s'arrête.** Claude doit rattraper avant Step 3d (commit final). Pas de claim "Notion synced" sans page-id + comment-id visibles dans la transcript.

#### Anti-patterns interdits (gravage permanent — incident 2026-05-18)

- ❌ Dire "Notion task synced" SANS poster les page-id + comment-id concrets dans la transcript → faux claim, faille système
- ❌ Skipper Step 3c-quater "parce que tâche Notion existante déjà à jour" → re-vérifier via `notion-fetch` ET post comment delta SI delta réel (nouveau commit = nouveau delta à signaler)
- ❌ "Florent a vu le commit dans git log, il sait" → Notion = source unique suivi cross-PC multi-compte, doit refléter delta indépendamment de git
- ❌ Mass-resolve "j'ai MAJ Notion sur tous les commits" sans details par commit → forfait, faux suivi, refuse close /wrapup
- ❌ Créer tâche dans le mauvais sous-projet → chercher dans table Projets via `notion-search query_type=internal` AVANT créer, sélectionner sous-projet pertinent (Production-Readiness V1.1 / Velopack V1.1 / Onboarding V1.1 / Sentry RGPD / etc.)
- ❌ Confondre tâche Notion (table Tâches enfants des projets) et page projet (table Projets racine) → comments vont sur tâches généralement, pages projet pour macro
- ❌ Échouer Notion MCP search et masquer l'erreur en sautant le commit → si MCP search retourne 0 résultats inattendus, retry avec keyword différent OU loguer "Notion search empty pour <slug>" explicitement

### Cas inaugural 2026-05-18 — Bug P0 BP-479 V1.1 Sentry fix

Pendant /drive 2026-05-18 04:30, commit `bb6d2a02` a fixé bug P0 BP-479 V1.1 (Sentry hot init signature). `/wrapup` post-/drive a déposé YAML pending-verifications + Plan vivant MAJ + roadmap Historique entry MAIS N'A PAS posté de comment sur la tâche Notion Sentry vague 5 `36401e69-443c-8170-95d2-c11183f80385`. Florent a dû demander explicitement le suivi Notion → Claude a dû rattraper post-wrapup en posant comment `36401e69-443c-81b9-8182-001d74c4311f` avec verbatim "Bug P0 fix code livré commit bb6d2a02, reste action Florent setup dashboards". Gap détecté → Step 3c-quater gravée pour blinder. Verbatim Florent : *"pq tu me dis que t'as mis à jour le backlog et ou les plans vivants et/ou notion pour le suivi :/ tu vraiment insister la dessus dans /wrapup"*.

**3d â€” Commit + push du wrap-up** :

```bash
git add memory/features/ memory/PLANS-INDEX.md memory/roadmap/roadmap.md
git commit -m "chore(wrapup): session YYYY-MM-DD"
git push origin HEAD:dev
```

Plan vivant dÃ©jÃ  MAJ par hook `plan_vivant_update_hook.py` au commit principal de la session. Cette Ã©tape pousse le wrap-up final (rÃ©organisation tickets / closures / nouveaux blocs).

**3e â€” Validation tracker (OBLIGATOIRE â€” etendu 2026-04-26)** :

Objectif : pour CHAQUE livraison de la session (`fix`/`feat`/`docs`/`refactor`/`perf`), poser un mecanisme de verification ulterieure. Sans ca, regression silencieuse.

**Le hook PostToolUse `tools/validation_tracker_hook.py` se declenche AUTO sur chaque `git push` pendant la session** â€” il propose le mecanisme par type. Cette etape de `/wrapup` est le **filet de securite final** qui garantit que rien n'est passe entre les mailles.

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
   | `chore/test/build/ci/style/wrapup` | SKIP | â€” |

3. **Si un commit n'a PAS son mecanisme** â†’ invoquer `/validation-tracker` pour le poser MAINTENANT. Refuser de cloturer `/wrapup` si gap detecte.

4. **Detail complet du routing** : skill `/validation-tracker` (point d'entree central, idempotent via cache JSON par session_id).

**Pour les `fix(...)` specifiquement (regle existante 2026-04-19) :**

2. **Pour chaque `fix(...)` commit, 2 actions :**

   **(a) Proposer MAJ de `memory/references/bug-patterns.md`** si la cause est une **classe de bug** (pas un one-shot). Signes :
   - Peut se reproduire ailleurs dans le code
   - Cause = pattern connu (thread, race, polling, permission, UIA/CDP, action auto sans cooldown, etc.)
   - Fix touche zone sensible (shutdown, auto-action, reader, watchdog)

   Structure pattern : Symptomes / Cause racine / Fix pattern / Detection logs / Declencheurs / Regle d'or.
   Jamais ecraser un BP existant â€” completer. Numero incremental BP-00X.

   **(b) Creer un YAML post-mortem** dans `memory/pending-verifications/fix-<slug>-YYYY-MM-DD.yaml` :
   ```yaml
   id: fix-<slug>-YYYY-MM-DD
   commit: <hash>
   description: <1 ligne â€” symptome que le fix doit supprimer>
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
   Les regex sortent de la section "Detection logs" du BP. Pas de BP â†’ brainstormer 1 regex `expect_absent` base sur les logs du bug d'origine.

3. **Commit les artefacts :**
   ```bash
   git add memory/references/bug-patterns.md memory/pending-verifications/*.yaml
   git commit -m "docs(bug-patterns): capitalize <slug> â€” BP-00X + YAML post-mortem"
   git push origin HEAD:dev
   ```

4. **Invoquer `/verify-fixes`** pour scanner les YAMLs pending contre les logs actuels (archive PASS / ticket FAIL / reverif INCONCLUSIVE).

**Regle absolue :** ZERO `fix(...)` commit ne sort d'une session sans YAML associe + sans tentative de capitalisation BP. Pas de YAML â†’ pas de `/wrapup` fini. Si aucune classe de bug identifiee â†’ `pattern_ref` vide mais YAML reste obligatoire.

**3f â€” Mise Ã  jour pipeline de vÃ©rification continu (OBLIGATOIRE si nouveaux YAMLs)** :

Si la session a dÃ©posÃ© au moins 1 nouveau YAML dans `memory/pending-verifications/`, s'assurer que le pipeline quotidien les verra :

1. **Confirmer** que les YAMLs sont bien dans `memory/pending-verifications/` (pas dans `_confirmed/` ni `_archive/`) â€” la tÃ¢che `speakapp-verify-fixes` (9h00 quotidien) scanne ce dossier automatiquement, rien Ã  faire de plus.
2. **Si c'est la 1Ã¨re fois qu'on touche Ã  ce pipeline dans la session** â†’ vÃ©rifier que le workspace dans `~/.claude/scheduled-tasks/speakapp-verify-fixes/SKILL.md` contient bien `C:\Users\Utilisateur\PROJECTS\3- Wisper\speak-app-dev` (et non `Utilisateur`).
3. **RÃ©sumÃ© Ã  donner Ã  Florent** : "X nouveaux YAMLs dÃ©posÃ©s. `/verify-fixes` invoquÃ© (tour 1). Pipeline quotidien `speakapp-verify-fixes` les scannera Ã  9h00."

**Note** : les YAMLs archivÃ©s dans `_confirmed/` (fixes dÃ©jÃ  validÃ©s live) ne sont PAS rescannÃ©s â€” ils servent uniquement de preuve de non-rÃ©gression consultable manuellement.

## Step 4: Push to NotebookLM Brain

**MÃ©thode : Chrome MCP** (le CLI Playwright ne fonctionne pas quand Chrome est ouvert sur le PC de Florent).

Notebook : `https://notebooklm.google.com/notebook/662af98a-984c-4a8d-9a3d-1bf3d4a7f23c`
ID de rÃ©fÃ©rence : `memory/reference_brain_notebook.md`

**ProcÃ©dure :**
1. RÃ©cupÃ©rer un tab via `tabs_context_mcp` (crÃ©er si vide)
2. Naviguer vers l'URL du Brain notebook
3. Trouver et cliquer le bouton "Ajouter une source" â†’ option "Texte copiÃ©"
4. Coller le contenu de `/tmp/session-summary-YYYY-MM-DD.md` comme source texte
5. Titre de la source : `Session YYYY-MM-DD â€” [titre court]`

Si Chrome MCP indisponible â†’ skip cette Ã©tape, les memories locales sont suffisantes.

## Step 5: Confirm — sortie honnête, ZÉRO claim sans preuve (NON-NÉGOCIABLE renforcée 2026-05-18)

> 🚨 **Florent verbatim 2026-05-18** : *"pq tu me dis que t'as mis à jour le backlog et ou les plans vivants et/ou notion pour le suivi :/"* — incident où `/wrapup` a claim "backlog + plan vivant + notion synced" sans avoir réellement exécuté la procédure. Cette étape blinde le recap : **chaque claim DOIT être appuyée par preuves concrètes (paths, page-ids, comment-ids, hashes) dans le format strict ci-dessous**.

### Format strict obligatoire — copier ce gabarit, remplir TOUTES les sections

```
=== /wrapup session YYYY-MM-DD — Recap ===

📝 MEMORIES : X saved / Y updated
  - <topic-slug-1> → memory/feedback_<slug>.md (Y lignes)
  - <topic-slug-2> → memory/project_<slug>.md (Y lignes)
  (OU "skip — aucune memory significative")

🧠 BRAIN NOTEBOOK : ✅ pushed (source id: <id>) OU ❌ skipped (raison: <Chrome MCP unavailable / autre>)

📌 PLAN VIVANT : N features touchées
  - memory/features/<feature-1>.md — ticket <slug-1> status <X>, commits <hashes>
  - memory/features/<feature-2>.md — ticket <slug-2> status <X>, commits <hashes>
  (OU "skip — session 100% docs/memory, aucune feature touchée")

🎯 ROADMAP.MD : audit Step 3c-bis sous-sections
  - Vision V1 : <intact|MAJ verbatim "...">
  - Top 5 bloqueurs : <intact|+N nouveau|−N levé code|réordonné>
  - Critères go-live : <X/Y cochés (+N nouveau)|intact>
  - Date cible : <intact|MAJ JJ/MM/YYYY>
  - Historique : ligne format strict ajoutée (1 ligne, 7 champs)
  - Non-dev : <intact|délégué /chef-projet-speakapp-notion>

🗂️ NOTION SYNC : audit Step 3c-quater par commit
  - Commit <hash1> [<type>] <slug> → tâche `<page-id>` comment `<comment-id>`
  - Commit <hash2> [<type>] <slug> → tâche `<page-id>` comment `<comment-id>`
  - Commit <hash3> [<type>] <slug> → nouvelle tâche créée `<new-page-id>` sous-projet `<X>`
  - Commit <hash4> [<type>] <slug> → SKIP (raison: <X>)
  - Total : X commits / Y synced / Z créés / W skipped
  (OU "skip — Notion MCP indisponible" OU "skip — aucun commit DEV")

✅ VALIDATION TRACKER : N YAMLs déposés (Step 3e)
  - memory/pending-verifications/<slug>-YYYY-MM-DD.yaml (BP-NNN)
  - ...
  (OU "skip — aucun fix/feat éligible")

🚀 PROCHAINE ACTION IMMÉDIATE :
  <1 phrase action concrète Florent OU Claude prochaine session>
```

### Auto-vérification AVANT envoi du recap (checklist mentale obligatoire)

Avant d'envoyer le recap à Florent, Claude relit son propre output et vérifie :
1. **Section MEMORIES** : chaque ligne a-t-elle un path `memory/...md` concret ? Si "X saved" → X paths listés ?
2. **Section PLAN VIVANT** : chaque feature touchée a-t-elle son chemin + slug ticket + hash commits ? Pas de "Plan vivant updated" générique.
3. **Section ROADMAP.MD** : les 6 sous-items (Vision/Top5/Critères/Date/Historique/Non-dev) sont-ils chacun renseignés explicitement ? Pas de "roadmap intact" en bloc.
4. **Section NOTION SYNC** : chaque commit DEV de la session apparaît-il avec son page-id + comment-id (ou justification SKIP) ? Si "Y synced" → Y lignes avec page-id + comment-id ?
5. **Section VALIDATION TRACKER** : chaque fix/feat éligible a-t-il son YAML path ? Si "N YAMLs" → N paths listés ?

Si UNE des 5 vérifs échoue → STOP, rattraper la section AVANT envoi. Pas de "j'enverrai approximatif et je rattraperai après" — c'est exactement l'anti-pattern qui a déclenché cette règle.

### Anti-patterns interdits (gravage 2026-05-18 incident gap suivi)

- ❌ "Plan vivant + Notion + backlog updated" SANS paths concrets, SANS page-id, SANS comment-id → faux claim, faille système, gravage MEMORY.md feedback obligatoire si récidive
- ❌ Format vague type "✅ ✅ ✅" ou "tout est synced" → Florent doit pouvoir grep page-id Notion + comment-id pour audit post-mortem cross-session
- ❌ Phrases creuses "j'ai vérifié" sans output `notion-fetch` / `notion-search` visible dans la transcript
- ❌ Skipper une section (memories / brain / plan vivant / roadmap / notion / validation) sans écrire explicitement "skip (raison: <X>)" → silence = faux PASS
- ❌ Mass-claim "tous les commits synced Notion" sans liste explicite par commit → format ligne-par-ligne obligatoire
- ❌ Diverger entre output Step 3c-quater Étape 3 et section NOTION SYNC du recap final → cohérence stricte exigée
- ❌ Diverger entre output Step 3c-bis Étape 2 (5 OUI/NON) et section ROADMAP.MD du recap final → cohérence stricte exigée
- ❌ Promettre "je ferai X la prochaine fois" dans le recap sans graver le ticket Plan vivant correspondant cette session

### Articulation avec étapes précédentes

Les sections du recap reflètent EXACTEMENT les outputs des étapes amont :
- **MEMORIES** ↔ Step 2 (Save & Improve Memories)
- **BRAIN NOTEBOOK** ↔ Step 4 (Push to NotebookLM Brain)
- **PLAN VIVANT** ↔ Step 2.5 (Plan vivant à jour)
- **ROADMAP.MD** ↔ Step 3c-bis (audit 4 sous-sections + Historique)
- **NOTION SYNC** ↔ Step 3c-quater (audit par commit)
- **VALIDATION TRACKER** ↔ Step 3e (YAMLs déposés)

ZÉRO divergence tolérée. Si une étape amont a affiché "Total : 2 commits / 1 synced / 1 créé" → le recap section correspondante affiche les 2 lignes avec preuves.

### Legacy bullets (conservés pour référence — couverts par format strict ci-dessus)

Tell the user (legacy short form, désormais inclus dans format strict) :
- How many memories were saved/updated
- That the session summary was added to the Brain notebook (or skipped)
- Que les Plan vivants des features touchÃ©es sont Ã  jour + `memory/PLANS-INDEX.md` rÃ©gÃ©nÃ©rÃ© (lecture cÃ´tÃ© autre compte = `git pull` + `/migration-pickup <feature>`)
- La PROCHAINE ACTION IMMÃ‰DIATE en 1 phrase

Keep it brief. No need to read back the full summary â€” just confirm it's done.

## Error Handling

- If Chrome MCP unavailable: save memories locally, skip the notebook push, tell the user
- If the Brain notebook was deleted: re-crÃ©er via Chrome MCP sur notebooklm.google.com, mettre Ã  jour `memory/reference_brain_notebook.md`
- If there's nothing meaningful to save: just say so, don't force empty memories

## Prerequisites

- Chrome MCP connectÃ© (extension Claude in Chrome active dans le navigateur de Florent)
- Brain notebook ID dans `memory/reference_brain_notebook.md`
3. The skill handles everything else automatically on first run
