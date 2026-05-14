---
name: wrapup
description: End-of-session wrap-up — summarizes the session, saves key memories, and pushes a session log to the user's AI Brain NotebookLM notebook. Trigger on "/wrapup" or when user says "wrap up", "save this session", "end of session", "session summary".
---

# Session Wrap-Up

Run this at the end of every session to capture what happened and commit it to long-term memory.

## Step 0bis : Anti-race parallel sessions (gravée 2026-05-13 — incident BP-377 cascade Phase 2)

> **🚨 RÈGLE NON-NÉGOCIABLE — Empêcher `/wrapup` parallèles de s'écraser mutuellement les working trees**
>
> **Pourquoi cette règle existe** : pendant la session BP-377 cascade Phase 2 (Florent N4 live validation Grok+DeepSeek+Mistral 2026-05-12), plusieurs sessions Claude en parallèle sur le même repo SpeakApp ont eu leurs working trees écrasés silencieusement par des `/wrapup` concurrents. Ma session a perdu des edits sur `wisper-bridge/manifest.json` + `memory/references/bug-patterns.md` 3 fois de suite avant de comprendre la cause. Verbatim Florent : *"oula j'en ai aucune idée je pense que c'est d'autres session qui bossent en mm temps mais je vois pas pq elles feraient ca en vrai donc je sai pas du tout"*.

### Mécanisme de protection — lockfile + heartbeat

**Avant TOUTE opération git (`git add`, `git commit`, `git stash`, `git pull`, `git push`) du skill `/wrapup`** :

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
       echo "⛔ /wrapup déjà actif sur ce repo. Owner : $LOCK_OWNER (lock age $LOCK_AGE_SECONDS sec). Abort."
       exit 1
     else
       echo "⚠️ Lock stale (>10min). Take over."
     fi
   fi
   ```

3. **Acquérir le lock** :
   ```bash
   echo "$USER@$HOSTNAME pid=$$ session=<session_id_or_pwd> started=$(date -Iseconds)" > "$LOCK_FILE"
   trap "rm -f '$LOCK_FILE'" EXIT INT TERM
   ```

4. **À la fin du skill** (Step 5 cleanup) : `rm -f "$LOCK_FILE"` automatique via trap.

### Détection edits en cours d'autres sessions — pre-write guard

**Avant tout `git add` du skill `/wrapup`**, scanner le working tree pour des modifications NON faites par la session courante :

```bash
# 1. Lister fichiers modifiés/staged
git status --porcelain > /tmp/wrapup_pre_status_$$.txt

# 2. Comparer mtime des fichiers modifiés vs début de session
SESSION_START_TS="<timestamp_session_start>"  # à capturer en début de session
for f in $(git diff --name-only HEAD); do
  FILE_MTIME=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")
  if [ "$FILE_MTIME" -gt "$SESSION_START_TS" ]; then
    # Vérifier que CETTE session a touché ce fichier (cf. Edit/Write log session)
    if ! grep -q "$f" "$SESSION_TOUCHED_LOG"; then
      echo "⚠️ $f modified by another process (mtime=$FILE_MTIME, session_start=$SESSION_START_TS)"
      ABORT_SUSPECT=1
    fi
  fi
done

if [ -n "$ABORT_SUSPECT" ]; then
  echo "⛔ Working tree contient des modifs d'une autre session. Synchronisation requise avant /wrapup."
  echo "Action : `git stash --include-untracked` puis re-run /wrapup."
  exit 1
fi
```

### Cas inaugural BP-377 — patterns d'écrasement observés

Pendant la session 2026-05-12 22:30-23:55 :
1. **`wisper-bridge/manifest.json`** edit (ajout grok.com + chat.deepseek.com) reverted **3 fois** par autres sessions (probablement /wrapup qui faisait `git checkout HEAD --` ou rebase qui résolvait le conflit en favorisant l'autre branche)
2. **`memory/references/bug-patterns.md`** BP-369 entry reverted (allocation BP-369 perdue, j'ai dû ré-allouer en BP-377 après race avec autre session qui a aussi alloué BP-376 pour un autre sujet ChatGPT canvas)
3. **`memory/references/bp-registry.json`** désynchronisé — BP-369 + BP-370 manquants localement, présents upstream → pre-commit hook bloquait jusqu'à `--no-verify` avec approbation explicite Florent

### Règles dérivées (à appliquer dans CE skill et autres skills git-touch)

1. **Skill `/wrapup`** : section ci-dessus à appliquer AVANT chaque Step 1.5 / 2.5 / 3d / 3e.
2. **Skill `/checkup-doc-sync`** : ne PAS faire `git stash` / `git checkout` sur fichiers NON modifiés par la session courante.
3. **Skill `/git-safe-push`** : déjà fait stash auto Florent WIP — étendre logique pour détecter modifs d'autres sessions et avorter avec message clair plutôt que stash agressif.
4. **Hook PreToolUse `git_safe_op_hook.py` à créer** (Sprint follow-up) : intercepter tout `git stash` / `git checkout` / `git reset` / `git rebase` venant d'un skill, scanner fichiers impactés, refuser si modifs d'une autre session détectées.

### Anti-pattern interdit (gravage cette règle)

- ❌ `git stash` aveugle au début de `/wrapup` (Step 3d implicite actuel) sans vérifier que les modifs sont à la session courante
- ❌ `git checkout HEAD -- <fichier>` "pour nettoyer" sans diff visible Florent
- ❌ `git pull --rebase` automatique en cas de push rejected sans alerter l'user + sans préserver les working tree edits d'autres sessions
- ❌ Régen d'index files (PLANS-INDEX.md, MEMORY.md, BP-INDEX.md) sans coordination — 2 sessions qui régen en parallèle se chevauchent et créent des diffs incohérents

### Action user immédiate si suspect

Si Claude détecte signal d'une autre session active :
- **STOP /wrapup**
- Afficher : *"Une autre session Claude semble active sur ce repo (lock $LOCK_FILE pid=X started=Y). Veux-tu : A — attendre 60s puis re-check, B — forcer takeover (perte possible des modifs autre session), C — abandonner /wrapup ?"*
- Attendre réponse explicite avant tout `git` op.

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

**If pending live tests found:** add them to `memory/validation-pending-n4.md` (table row + section entry) before continuing with Step 1.5.

## Step 1.5: Sync code↔docs via /checkup-doc-sync (gravé 2026-05-10)

**Objectif** : avant de pousser des memories obsolètes dans la KB long-terme (Step 3), garantir que les docs feature + bug-patterns + plan vivant + matrices reflètent bien le code committé pendant la session.

**Procédure** : invoquer `/checkup-doc-sync` comme sous-étape automatique. Il fera :
- Map "Change Type → Documents to Update" pour chaque commit de la session
- MAJ feature docs (PRD, Plan vivant, BPs connus)
- MAJ `bug-patterns.md` si nouveaux BPs alloués
- MAJ matrices (`platform-scenario-matrix.md`, `interaction-mechanisms-matrix.md`) si mécanisme/sélecteur a bougé
- MAJ `voice-commands.md` si hotkey/voix change
- MAJ `roadmap.md` si tâche livrée

**Distinction avec Step 2.5/2.6** :
- **Step 1.5** = **toute la doc projet large** (BPs, matrices, voice, roadmap, mécanismes) — délégation à `/checkup-doc-sync`
- **Step 2.5** = Plan vivant per feature touchée (frontmatter + tickets)
- **Step 2.6** = § Description fonctionnelle 2 niveaux (user-facing + technique)

`/checkup-doc-sync` reste appelable seul à chaque commit intra-session (pour pas attendre fin de session). Ici en Step 1.5 = filet final qui rattrape les éventuelles oublis intra-session.

**Skip légitime** : session 100% docs/memory sans code feature → mention `[step 1.5 skip: aucun code committé]` et passer Step 2.

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

**🚨 FORMAT MEMORY.md NON-NÉGOCIABLE (gravée 2026-05-13)** : MEMORY.md est un **INDEX**, pas un conteneur. Chaque entrée = **UNE LIGNE ≤150 chars** au format `- [Title](file.md) — hook 1-phrase.`. Le **contenu détaillé** (verbatim Florent, contexte, diagnostic, commits, why, how to apply) va **dans le topic file** (`feedback_<slug>.md`, `project_<slug>.md`, etc.), JAMAIS inline MEMORY.md. Workflow correct : (1) créer/MAJ topic file avec frontmatter + contenu complet, (2) ajouter/MAJ 1 ligne pointer dans MEMORY.md. **Anti-pattern interdit** : copier 500-2000 chars de résumé directement dans MEMORY.md → fichier explose au-dessus du quota 25KB en quelques sessions. Le hook `tools/memory_line_length_hook.py` warn si ligne ajoutée > 150 chars.

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

## Step 2.6: MAJ § Description fonctionnelle TOUT LE TEMPS — 2 niveaux (gravée 2026-05-05, élargie 2026-05-06, pilote intelligent 2026-05-13)

**🚨 CHANGEMENT DE PORTÉE 2026-05-06** : ce step ne se déclenche PLUS uniquement "si statut V1 change". Il se déclenche **à chaque session qui touche une feature**, peu importe la nature du changement (code, doc, fix, refactor, décision tranchée, spec UX clarifiée, paire validée).

**🎯 PILOTE INTELLIGENT 2026-05-13 (BP-389 V1.2)** — pour les features SpeakApp (repo `speak-app-dev`), l'écriture/MAJ de la § Description fonctionnelle est désormais **déléguée au skill pilote** `/update-feature-functional-doc <feature>` :
- Workflow 6 étapes (read sources / plan section / rédaction langage user / écriture / validation / reporting)
- Briques de référence (Quoi / Comment l'utiliser / Modes & options / Cas d'usage / Plateformes supportées / Limites V1)
- Anti-patterns explicites (zéro jargon, zéro pitch court — doc COMPLÈTE 3000-7000 chars, pas 3 paragraphes)
- Validation auto via pre-commit `tools/precommit_feature_doc_check.py`

**Quand invoquer `/update-feature-functional-doc <feature>` dans Step 2.6** :
- § Description fonctionnelle absente ou < 1500 chars → invocation immédiate
- § présente mais polluée par jargon technique → invocation pour refactor
- Spec UX / mode / option / cas d'usage / plateforme nouveau cité ou modifié en session → invocation pour MAJ
- Sinon (section déjà complète et propre, MAJ purement technique du niveau 2) → skip, MAJ niveau 2 directement

Florent verbatim 2026-05-13 : *"pas comme un pinguin"* — pas de bricolage en mode "ajoute 3 paragraphes vite fait", déléguer à l'outil pilote.

**Articulation hook PostToolUse `feature_doc_sync_hook.py`** : pendant la session, ce hook a probablement déjà émis une alerte `📐 FEATURE DOC GATE — <feature> non conforme CLAUDE.md §3.7` quand tu as touché code feature sans MAJ doc. Si oui → Step 2.6 = exécuter `/update-feature-functional-doc` pour purger la dette. Sinon → audit manuel selon critères ci-dessus.

Florent verbatim 2026-05-06 : *"ce qui m'intéresse, c'est que la fonctionnalité elle soit bien décrite à tout moment, d'un point de vue purement fonctionnel pour qu'on puisse derrière décliner tout ça en site web, démo, posts LinkedIn et réseaux sociaux etc, et la partie technique évidemment pour que tu saches comment ça marche et que tu puisses t'y référer si t'as des questions."*

### Les 2 niveaux à maintenir DANS chaque feature doc

**Niveau 1 — § Description fonctionnelle pure** (user-facing, copier-collable site web/démo/LinkedIn)
- Langage humain, zéro jargon technique
- Argumentaire produit : ce que l'utilisateur peut faire concrètement, dès maintenant
- Statuts paires/plateformes lisibles d'un coup d'œil (✅ validé / 🔧 in-progress / ❌ deprecated + date)
- Procédure user en 3-5 étapes claires (langage user)
- Argumentaire pitch / sales : "Avec SpeakApp, tu peux X depuis ton clavier sans toucher la souris" — pas "le pipeline UIA Invoke fire en background sur le hwnd CD"

**Niveau 2 — § Implémentation technique** (Claude-facing, pour debug/extend)
- PRD §1 (sections 1.1-1.8) avec règles R-N
- Code paths `app.py:NNNN`, adapters, engines, watchdog
- Mécanismes M1-M5, sélecteurs UIA / CDP / DOM
- BPs allocés, traps connus, cooldowns/gates
- Plateformes par plateforme (statut V1 + adapter + entry point)

### Procédure obligatoire (à exécuter SYSTÉMATIQUEMENT, pas conditionnel)

1. **Pour CHAQUE feature touchée dans la session** (cf. `git log --oneline origin/dev..HEAD --name-only` Step 2.5) :
   - Ouvrir `memory/features/<feature>.md`
   - Auditer **niveau 1** : la § Description fonctionnelle reflète-t-elle l'état actuel ? Manque-t-il une nouvelle paire/plateforme/scénario/limitation/décision UX ?
   - Auditer **niveau 2** : la § Implémentation technique cite-t-elle bien les nouveaux code paths / mécanismes / BPs / sélecteurs touchés cette session ?
   - Si gap niveau 1 OU niveau 2 → MAJ AVANT commit final wrapup

2. **Trigger systématique, pas conditionnel** :
   - ✅ Test live PASS → MAJ niveau 1 (statut, date, procédure user) + niveau 2 (preuves logs, BP)
   - ✅ Fix livré → MAJ niveau 1 (limite levée si user-visible) + niveau 2 (BP, code path, fix)
   - ✅ Spec UX clarifiée par Florent verbatim → MAJ niveau 1 (nouvelle UX décrite) + niveau 2 (code path + § Décisions stratégiques §9bis)
   - ✅ Refactor / nouvelle archi → MAJ niveau 2 (nouveaux fichiers, mécanisme révisé)
   - ✅ Nouvelle plateforme support → MAJ niveau 1 (statut tableau plateformes) + niveau 2 (adapter, sélecteurs)
   - ✅ Décision tranchée avec options → §9bis Décisions stratégiques + niveau 1 si UX impacte user

3. **Gabarit minimal niveau 1** (si § Description fonctionnelle absente, créer stub) :
   ```markdown
   ## 1.ter Description fonctionnelle pure (langage user, zero technique)

   ### Ce que l'utilisateur peut faire dès maintenant
   <2-4 paragraphes argumentaire produit, langage humain>

   ### Comment l'utiliser (procédure 3-5 étapes)
   1. ...
   2. ...

   ### Statuts par plateforme / paire
   | Plateforme | Statut | Date validation | Limites V1 |
   |-----------|--------|-----------------|------------|
   | ... | ✅ V1 | 2026-XX-XX | ... |

   ### Argumentaire pitch (déclinable)
   <1-2 phrases punch pour site web / LinkedIn / démo>
   ```

4. **Anti-patterns interdits** :
   - ❌ MAJ uniquement niveau 2 (technique) sans toucher niveau 1 (fonctionnel) → Florent ne peut plus décliner en marketing
   - ❌ MAJ uniquement niveau 1 sans niveau 2 → Claude futur doit re-grep le code à chaque question
   - ❌ "Pas de commit code aujourd'hui donc pas de doc à MAJ" → décision UX clarifiée verbatim Florent change le niveau 1 sans toucher au code
   - ❌ Attendre statut V1 change pour MAJ → niveau 1 doit refléter le statut À TOUT MOMENT

### Cas inaugural 2026-05-06 — toast role A pilote-ia

Florent re-explique 3× que le toast role A a 2 boutons Manager/Exécutant. Cause : niveau 1 (§ Description fonctionnelle) de pilote-ia.md ne décrivait pas explicitement le flow toast (manquait la partie "user clique 1 bouton"). Niveau 2 (code) avait la vérité dans `app.py:19517-19527`. Gap niveau 1↔2 → re-questionnement. Fix : flow gravé 2026-05-06 dans §1.ter + §9bis Décisions stratégiques.

### Cas inaugural 2026-05-05 — V1.1.C-CD-AG-STEP3 PASS T4

Test live T4 12:56 a validé paire commerciale CD→AG (pilote AG depuis CD avec Sonnet). Mais la § "1.ter Triggers user-facing" de `pilote-ia.md` n'a pas été MAJ par /wrapup → aucune mention "✅ paire CD↔AG validée 2026-05-05" → Florent demande "comment je test ?" alors que la réponse était évidente (Vosk `autopilote` + sélection sessions). Gap système découvert.

---

## Step 2.6 (legacy — fusionné dans nouveau Step 2.6 ci-dessus 2026-05-06)

Section conservée pour référence historique. Procédure complète = Step 2.6 nouveau ci-dessus.

### Détails legacy (sub-section 2026-05-05)

**Gap historique identifié** : Plan vivant (Step 2.5) maj la couche **technique** (status ticket, prochain pas, bloqueurs). MAIS la § **Description fonctionnelle** (`memory/features/<feature>.md` § "Description fonctionnelle pure (langage user, zero technique)" — argumentaire client / ce que l'utilisateur peut faire) reste figée.

Conséquence : si un test live PASS valide une nouvelle paire/plateforme/scénario, la doc fonctionnelle continue d'afficher l'état d'avant-hier → Florent et Claude Code futures sessions n'ont pas la vue à jour de "ce que l'utilisateur peut faire dès maintenant".

**Florent verbatim 2026-05-05** : *"j'ai l'impression que ça ne met pas à jour la documentation fonctionnelle de la fonctionnalité. Ça ne met à jour que la documentation technique. Et ça c'est très problématique."*

### Procédure obligatoire

1. **Détecter changement statut V1** dans la session : test live PASS, fix livré, feature flip ON, nouvelle paire/plateforme validée, nouveau scénario passé, déprecation feature.
   ```bash
   # grep YAML pending verdict=PASS récents OU commits feat/fix
   ls memory/pending-verifications/*.yaml | xargs grep -l "verdict: PASS" | head
   git log --oneline origin/dev..HEAD | grep -E "^[a-f0-9]+ (feat|fix)\("
   ```

2. **Pour chaque feature impactée**, ouvrir `memory/features/<feature>.md` et localiser la § Description fonctionnelle (sous-titres typiques : "Description fonctionnelle pure", "1.ter Triggers user-facing", "Statuts paires plateformes", "Comment ça marche", "User stories"). MAJ :
   - **Tableau statuts** : refléter le nouveau statut (✅ PASS, 🔧 in-progress, ❌ deprecated)
   - **Date validation** : `2026-XX-XX (slug-ticket)`
   - **Procédure utilisateur** : "Comment l'utilisateur teste/utilise cette nouveauté dès maintenant" (3-5 étapes claires, langage user, zero technique)
   - **Limites V1 connues** : si bug résiduel non bloquant (BP alloué) → mention courte + workaround
   - **Argumentaire pitch** : si paire/scénario commercial → graver "✅ livré depuis 2026-XX-XX"

3. **Anti-patterns interdits** :
   - ❌ MAJ uniquement Plan vivant (technique) sans toucher § Description fonctionnelle (user-facing)
   - ❌ Laisser § Description fonctionnelle figée alors qu'un test live PASS aujourd'hui change le statut
   - ❌ "Pas de commit code aujourd'hui donc pas de doc à MAJ" — un test live PASS sans commit code DOIT quand même MAJ § Description fonctionnelle

4. **Cas particuliers** :
   - Session 100% docs/memory/refactor sans changement statut V1 → skip ce step
   - Session change statut V1 d'une feature pas encore dotée de § Description fonctionnelle → créer stub minimal (template `feature-doc-template.md` §1bis si dispo, sinon bloc 5 lignes)

### Cas inaugural 2026-05-05 — V1.1.C-CD-AG-STEP3 PASS T4

Test live T4 12:56 a validé paire commerciale CD→AG (pilote AG depuis CD avec Sonnet). Mais la § "1.ter Triggers user-facing" de `pilote-ia.md` ligne 1380+ n'a pas été MAJ par /wrapup → aucune mention "✅ paire CD↔AG validée 2026-05-05" → Florent demande "comment je test ?" alors que la réponse était évidente (Vosk `autopilote` + sélection sessions). Gap système découvert.

## Step 2.7: Audit doc feature vs décisions/specs clarifiées en session (gravée 2026-05-06)

**Gap système identifié** : Step 2.5 MAJ Plan vivant (technique) + Step 2.6 MAJ Description fonctionnelle (user-facing si statut V1 change). MAIS aucun step ne couvre le cas "Florent a clarifié verbatim une spec UX en session, sans commit code, sans changement statut V1" → la doc reste figée alors que le contexte session a tranché.

**Cas inaugural 2026-05-06** : Florent verbatim *"juste la 1ière t'as raison tu choisis 1 et le 2ieme sera evidemment l'autre"* (toast role A pilote-ia). Décision tranchée, options évaluées, conditions re-éval — mais la doc `pilote-ia.md` ne capturait que le code, pas la décision. Sans gravage explicite, Claude future session re-pose la question 3 fois.

### Procédure obligatoire

1. **Scan transcript session** : repérer
   - Verbatim Florent qui tranche un débat ("on garde X parce que...", "juste Y", "on revient PAS sur ça")
   - Specs UX clarifiées (boutons, hotkeys, flows, langage) que Florent confirme/corrige
   - Décisions stratégiques avec options évaluées (cf. critères CLAUDE.md §3.7 invocation `/decision-log`)
   - Specs déduites par investigation code que Florent valide ("OK c'est ça")

2. **Pour chaque clarification, vérifier qu'elle est gravée dans la doc feature** :
   - **Spec fonctionnelle** → `memory/features/<feature>.md` § PRD §1 (sections 1.1-1.8)
   - **Comportement UX** → § Description fonctionnelle / § Triggers user-facing
   - **Décision tranchée avec options/verbatim/conditions** → invoquer `/decision-log <feature> <slug>` (section `## Décisions stratégiques` du feature doc)
   - **Convention/règle émergente** → `PROPOSITION DE REGLE` via `/rule-creator`

3. **Si gap détecté** → MAJ AVANT commit final wrapup. Pas de "session fermée + spec verbatim non gravée".

4. **Articulation hook `feature_doc_sync_hook.py`** (PostToolUse Edit/Write) : le hook fire quand code feature touché sans MAJ doc dans la session. Si rappel hook déjà ignoré dans la session avec justification `[doc-sync skip: <raison>]`, accepter. Sinon → MAJ doc obligatoire ici.

5. **Critère PASS Step 2.7** : 0 verbatim Florent qui tranche un débat dans la session courante reste sans graver dans la doc feature concernée.

### Anti-patterns interdits

- ❌ Clôturer wrapup avec "j'ai entendu Florent dire X mais j'ai pas eu le temps de mettre à jour la doc"
- ❌ Attendre la prochaine session pour graver une décision tranchée → décision perdue dans le vent (cf. CLAUDE.md §3.7 *"j'ai trop de trucs à penser. Si tu n'enregistres pas, c'est perdu dans le vent"*)
- ❌ Mettre la décision uniquement dans le commit message → invisible aux invocations skill futures

### Référence règle source

CLAUDE.md projet ligne 449 (gravage 2026-05-06) : *"Skills + feature docs = MAJ same-commit que code/doc référencé. Code path change → MAJ `memory/features/<feature>.md` + skill MEME commit (sinon doc dérive du code, je re-questionne Florent sur des specs déjà gravées — cas toast role A 2026-05-06)."*

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

**3c-bis NON-NÉGOCIABLE — MAJ § "🎯 Plan global SpeakApp" dans roadmap.md (DEV pur) [BP-383 gravée 2026-05-13]** :

> **🚨 RÈGLE NON-NÉGOCIABLE** — Florent verbatim 2026-05-13 : *"tu n'as aucuns plan globale pour dev l'app ce qui était supposé etre la roadmap mais tu as pas l'air de l'alimenter"* + *"tu mélanges les skills, tu mélanges toutes les compétences, la roadmap"*. Cette sous-étape MAJ **uniquement la couche DEV** (roadmap.md). Le NON-DEV (Notion) est délégué intégralement au skill `/chef-projet-speakapp-notion` — appeler ce skill séparément si session a touché un sujet non-dev. Séparation propre obligatoire, ZÉRO mélange.

### Procédure rigoureuse — Florent ne doit RIEN se rappeler, Claude exécute tout

> **PRINCIPE** : Claude scanne la session de bout en bout AVANT de toucher roadmap.md. Pas de "j'oublie", pas de "skip". Si Claude ferme une session de code sans avoir exécuté cette procédure → faille système, à graver dans MEMORY.md feedback.

#### Étape 1 — Scan session (5 commandes obligatoires, ZÉRO interprétation)

```bash
cd "C:/Users/Administrateur/PROJECTS/3- Wisper/speak-app-dev"

# 1a — Tous commits depuis last wrapup
LAST_WRAPUP=$(git log --oneline --grep="^chore(wrapup)" -1 --format=%H)
git log --oneline "$LAST_WRAPUP"..HEAD 2>/dev/null > /tmp/wrapup_commits.txt
cat /tmp/wrapup_commits.txt

# 1b — Verbatim Florent significatifs cette session (extraits messages user)
# → Claude scanne sa propre transcript pour patterns suivants :
#    "on garde X parce que" / "on revient PAS sur" / "scope V1 c'est"
#    "ça c'est bloquant" / "priorité numéro 1" / "à différer"
#    "date cible" / "go-live le" / "Beta privée le"
#    "valide" / "PASS" / "ça marche" / "✅" sur un critère prêt go-live
#    "site web" / "packaging" / "Mac" / "ventes" / "marketing" / "pricing"
#    "support" / "juridique" / "i18n" / "internationalisation"

# 1c — Fichiers touchés (pour détection non-dev)
git diff --name-only "$LAST_WRAPUP"..HEAD 2>/dev/null | sort -u > /tmp/wrapup_files.txt
cat /tmp/wrapup_files.txt

# 1d — YAMLs verdict PASS récents (critères prêt cochables)
ls -t memory/pending-verifications/_confirmed/ 2>/dev/null | head -10

# 1e — Lecture état actuel § Plan global
grep -A 80 "^## 🎯 Plan global SpeakApp" memory/roadmap/roadmap.md > /tmp/wrapup_plan_global_before.txt
```

#### Étape 2 — Audit 4 sous-sections (checklist binaire, 1 ligne par item)

> **Pour CHAQUE item ci-dessous, Claude écrit explicitement OUI ou NON dans la session avant de continuer. Pas de "probablement", pas de "à voir".**

**Item 2.1 — Vision V1** :
- Question : un des verbatims Florent §1b cette session change-t-il le périmètre user / la liste features V1 / les plateformes ciblées / l'exclusion CD ?
- Si OUI → MAJ paragraphe Vision V1 avec verbatim exact entre guillemets.
- Si NON → écrire dans transcript "Vision V1 : intact".

**Item 2.2 — Top 5 bloqueurs (LEVÉ)** :
- Question : un commit `fix(...)` / `feat(...)` §1a livré cette session correspond-il au slug ou BP-NNN d'un bloqueur du Top 5 actuel ?
- Si OUI → retirer ce bloqueur du Top 5 + le déplacer dans § "🟡 Code livré N4 pending" + écrire dans transcript "Bloqueur X levé code → N4 pending".
- Si NON → écrire dans transcript "Aucun bloqueur Top 5 levé code cette session".

**Item 2.3 — Top 5 bloqueurs (NOUVEAU)** :
- Question : un verbatim Florent §1b contient-il "ça c'est bloquant" / "priorité 1" / "il faut absolument" / "sans ça pas de go-live" ?
- Si OUI → ajouter dans Top 5 (position selon priorité Florent dictée) avec verbatim entre guillemets.
- Si NON → écrire dans transcript "Aucun nouveau bloqueur Florent verbatim".

**Item 2.4 — Critères "prêt go-live"** :
- Question : un YAML §1d récemment archivé `_confirmed/` correspond-il à un critère listé OU un verbatim Florent §1b dit "ça marche" / "PASS" / "✅" sur un critère ?
- Si OUI → cocher `- [x] <critère>` + date + ref commit dans la checklist.
- Si NON → écrire dans transcript "Aucun critère prêt nouveau coché".

**Item 2.5 — Date cible** :
- Question : un verbatim Florent §1b mentionne-t-il "date cible" / "go-live le" / "Beta privée fin X" / "deadline" ?
- Si OUI → MAJ paragraphe Date cible avec date + verbatim.
- Si NON → écrire dans transcript "Date cible intacte".

#### Étape 3 — Détection non-dev (auto, scan fichiers + verbatims)

```bash
# Auto-détection sujet non-dev touché
NON_DEV_PATTERNS="site.web|landing|loveable|vercel|packaging|msix|setup|installer|mac|portage|ventes|marketing|linkedin|carousel|post|pricing|stripe|payment|support|onboarding|juridique|legal|cgu|cgv|privacy|terms|i18n|internationali|traduction"

# Files touched matching non-dev :
grep -iE "$NON_DEV_PATTERNS" /tmp/wrapup_files.txt | head -10

# Florent verbatim non-dev cette session ? (Claude scanne sa transcript)
# → liste manuelle des patterns détectés
```

Si UN match → **invoquer `/chef-projet-speakapp-notion`** pour MAJ Notion. Si zéro match → mention "non-dev intact" dans Historique.

#### Étape 4 — Ligne § Historique session courante (format strict obligatoire)

Format exact :
```
- **YYYY-MM-DD HH:MM** [session-slug-court] : <résumé 1 phrase action principale>
  · vision=<intact|MAJ-verbatim>
  · top5=<intact|+N nouveau|−N levé code|réordonné>
  · critères=<X/11 cochés (+N nouveau)|intact>
  · date=<intact|MAJ JJ/MM/YYYY>
  · non-dev=<intact|délégué /chef-projet-speakapp-notion>
```

#### Critère PASS Step 3c bis (NON-NÉGOCIABLE)

Claude a écrit dans la transcript : 5 lignes Étape 2 (OUI/NON par item) + 1 ligne § Historique format strict + invocation effective `/chef-projet-speakapp-notion` si non-dev détecté. **Sans ces 6 lignes, Step 3c bis n'est PAS terminé**. Claude ne passe pas Step 3d (commit final).

#### Anti-patterns interdits (gravage permanent)

- ❌ Skipper Step 3c bis "parce que la session était purement technique" → audit 4 sous-sections quand même + ligne "intact" obligatoire.
- ❌ Ne mettre à jour QUE "✅ Livré récemment" en oubliant § Plan global → les 2 sont indépendants, MAJ les 2.
- ❌ Inventer un bloqueur Florent n'a pas validé verbatim → marquer "⚠️ Florent à confirmer" si proposition Claude.
- ❌ Sauter Étape 3 détection non-dev → /chef-projet-speakapp-notion oublié = Notion désynchronisé.
- ❌ Format ligne Historique libre → format strict 7 lignes obligatoire pour grep ultérieur.
- ❌ Florent doit deviner ce qu'il manque → Claude scanne, Claude décide, Claude écrit. Florent valide en lecture finale.

**3c-ter — Appel `/doc-keeper` si code modifié** :

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
