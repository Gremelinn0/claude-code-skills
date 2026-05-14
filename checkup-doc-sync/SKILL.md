---
name: checkup-doc-sync
description: Systematically updates project docs AND skills after any code change. Use after implementing features, fixing bugs, modifying configs, adding commands, or changing architecture. Triggers on any code modification that affects documented behavior or skill procedures.
---

# Doc Keeper — Docs + Skills Sync

## Overview

Every code change MUST propagate to BOTH the project's reference docs AND the skills that reference them. Doc drift = repeated context loss. Skill drift = broken links + re-grep ad-hoc + tokens wasted.

**Core principle:** Code changed = docs updated = skills updated. Same commit. No exceptions.

## Step 0bis : Anti-race parallel sessions (gravée 2026-05-13 — héritée skill /wrapup)

> **🚨 RÈGLE NON-NÉGOCIABLE — Ne PAS éditer / regen des fichiers partagés (PLANS-INDEX.md, MEMORY.md, BP-INDEX.md, bp-registry.json, feature docs) si une autre session Claude est active sur le même repo.**

Avant toute édition / régen via ce skill (Step 1+) :

```bash
REPO_HASH=$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null | sha256sum | head -c 12)
WRAPUP_LOCK="$HOME/.claude/locks/wrapup-$REPO_HASH.lock"

# Check si /wrapup actif (priorité haute — /checkup-doc-sync est appelé par /wrapup en Step 1.5)
if [ -f "$WRAPUP_LOCK" ]; then
  WRAPUP_OWNER=$(cat "$WRAPUP_LOCK" 2>/dev/null | head -1)
  # Si lock owner = nous-même (delegation depuis /wrapup) → continuer
  # Sinon → abort
  if ! echo "$WRAPUP_OWNER" | grep -q "pid=$PPID\|pid=$$"; then
    AGE=$(($(date +%s) - $(stat -c %Y "$WRAPUP_LOCK" 2>/dev/null || stat -f %m "$WRAPUP_LOCK")))
    if [ "$AGE" -lt 600 ]; then
      echo "⛔ /wrapup actif sur ce repo (autre session, owner $WRAPUP_OWNER, age ${AGE}s). Abort /checkup-doc-sync."
      exit 1
    fi
  fi
fi
```

**Anti-patterns interdits (cf. wrapup SKILL.md Step 0bis 2026-05-13 cause BP-377)** :
- ❌ Régen `memory/PLANS-INDEX.md` / `memory/references/BP-INDEX.md` sans vérifier qu'une autre session ne régen pas en parallèle (2 régens concurrentes → diffs incohérents)
- ❌ Edit `bp-registry.json` sans avoir `git fetch` + comparer last_allocated upstream (race d'allocation BP-NNN)
- ❌ Régen feature docs Plan vivant sans `git status` propre (overwrite WIP cross-session)

**Cas inaugural** : session BP-377 cascade Phase 2 2026-05-12, BP-369 alloué local + BP-370 alloué upstream autre session sans propagation = registry désync = pre-commit hook bloque → `--no-verify` forcé avec approbation Florent.

Référence canonique complète : `~/.claude/skills/wrapup/SKILL.md` § Step 0bis.

---

## Invocation patterns (gravé 2026-05-10)

Ce skill a 2 patterns d'invocation légitimes :

1. **À chaque commit intra-session** (pattern principal) — invocation directe `/checkup-doc-sync` après un fix/feature livré, pour sync immédiate code↔doc avant le commit suivant. Granularité fine.

2. **Sous-étape automatique de `/wrapup`** (Step 1.5) — `/wrapup` délègue à ce skill pour la sync large fin de session. Filet final qui rattrape les oublis intra-session avant push KB long-terme. Florent appelle `/wrapup` → ce skill est invoqué automatiquement.

**Pas de fusion** entre les 2 skills : `/wrapup` reste orchestrateur fin-de-session (memories + KB + handoff), ce skill reste responsable du sync doc unitaire. Composition via délégation.

**Règle parente (CLAUDE.md §3, 2026-04-30)** : *Skills = porte d'entrée unique. Code path change → MAJ skill MEME commit. Skills listent en tête les docs/fichiers fondamentaux. Pas grep CLAUDE.md à part.*

## When To Apply

**ALWAYS after:**
- New feature / modified feature
- Adding/removing/changing config keys, hotkeys, voice commands
- UI elements changed (voyants, indicators, buttons, tooltips)
- Architecture change (new files, renamed files, moved functions, code path moved >50 lines)
- Bug fix that changes documented behavior
- New BP allocated (`tools/allocate_bp.py`)
- Restructuring docs (new canonical source, section moved, file renamed)
- Florent verbatim graving a rule

## Routing — WHERE.md is the entry point

**Lire `memory/WHERE.md` AVANT toute édition de doc.** Decision tree + table universelle "type d'info → fichier unique".

Ne pas dupliquer ici — le skill pointe, WHERE.md décrit. Si WHERE.md ne répond pas → MAJ WHERE.md d'abord, jamais inventer un dossier.

**Règle hub HTML** : déprécié depuis 2026-04-27 (CLAUDE.md §3). NE PAS consulter pour comprendre l'état d'une feature. NE PAS aligner doc interne dessus. Désynchro hub vs feature doc = intentionnel.

## Map — Code change → Docs to update

| Change Type | Documents to Update |
|-------------|-------------------|
| Code feature modifié (app.py, wisper-bridge/, cdp_*, devtools_*, cc_ui/, etc.) | **Plan vivant §0bis** du feature doc — sujet/statut/prochain pas/derniere session (commit hash) |
| New feature implemented | Feature doc (`memory/features/<feature>.md`) — section §1bis PRD + Plan vivant + roadmap |
| Bug fix classé BP | `memory/references/bug-patterns.md` (BP-XXX entry) + YAML `pending-verifications/fix-bpXXX-<slug>-<date>.yaml` + feature doc (Bugs connus) |
| New config key / constante | Feature doc § "Constantes" avec rationale (comment le nombre a été dérivé) |
| New hotkey | Feature doc + `memory/core/voice-commands.md` si voix équivalente |
| New voice command | Feature doc + `memory/core/voice-commands.md` |
| UI change visible utilisateur | Feature doc (hub HTML laissé mourir, pas de MAJ) |
| New file created | Feature doc § "Architecture — fichiers clés" |
| Roadmap task done | `memory/roadmap/roadmap.md` (item livré) + Plan vivant feature (déplacer "🔧 En cours" → "✅ Récemment livré") |
| **Tout changement vision V1 / nouveau bloqueur émergé / critère "prêt go-live" cochéable** (gravée 2026-05-13 BP-383) | **OBLIGATOIRE MAJ § "🎯 Plan global SpeakApp"** dans `memory/roadmap/roadmap.md` (haut du fichier, AVANT § Tickets actifs). 4 sous-sections : Vision V1 / Top 5 bloqueurs ordre Florent / Critères "prêt go-live" checklist binaire / Date cible. Ajouter 1 ligne § Historique session courante. Trigger session courante : test live PASS N4 coche critère / Florent verbatim "ça c'est bloquant" / bug critique découvert / décision UX qui change archi / Florent reformule scope V1. JAMAIS skipper cette sous-section sous prétexte "session technique". Florent verbatim 2026-05-13 : *"tu n'as aucuns plan globale pour dev l'app ce qui était supposé etre la roadmap mais tu as pas l'air de l'alimenter"*. |
| **Nouveau ticket FUTUR / V1.1+ / dette technique non-bloquante** | `memory/roadmap/roadmap.md` UNIQUEMENT — JAMAIS Plan vivant feature. Plan vivant = tickets ACTIFS session, pas backlog. Si déjà dans Plan vivant et reporté → cut Plan vivant + ajout roadmap (pas duplication). Erreur fréquente 2026-05-02 : créer ticket V1.1 dans Plan vivant au lieu de roadmap. |
| Architecture change transversale | Feature docs concernés + CLAUDE.md §3 si nouvelle règle émerge |
| Validation N4 identifiée | `memory/validation-pending-n4.md` — ajouter ligne tableau Suivi |
| Validation N4 complétée par Florent | `memory/validation-pending-n4.md` (cocher) + feature doc critère |
| Mécanisme d'interaction change (UIA/CDP/DevTools/Win32/OCR/WS Bridge/hooks) | **Skill `/update-interaction-matrix` OBLIGATOIRE** : matrice §2bis + `memory/platforms/<p>.md` + journal §9 |
| Reader / méthode lecture chat change | **Skill `/update-interaction-matrix` OBLIGATOIRE** : §2bis feature "Lecture chat" + journal §9 |
| Nouveau sélecteur / widget / état découvert | Axe A: `memory/platforms/<plateforme>.md` · Axe B: matrice §2bis si change statut feature |
| Status lifecycle transition (V1 livré → V2 pending → V2 livré) | **Capitalisation parallèle OBLIGATOIRE** sur tous docs référençant module/feature (voir section "Status lifecycle capitalization") |
| **Test live PASS valide statut V1 (paire/plateforme/scénario) — MEME sans commit code** (gravée 2026-05-05) | **OBLIGATOIRE MAJ § Description fonctionnelle** (`memory/features/<feature>.md` § "Description fonctionnelle pure" / "Triggers user-facing" / "Statuts paires plateformes") en plus du Plan vivant (technique). Tableau statuts + date validation + procédure user 3-5 étapes + limites V1 + argumentaire pitch. Florent verbatim 2026-05-05 : *"ça ne met à jour que la documentation technique. Et ça c'est très problématique."* Cas inaugural V1.1.C-CD-AG-STEP3 PASS T4 (skill `/wrapup` Step 2.6). |
| Nouvelle règle gravée par Florent | CLAUDE.md §3 (verbatim source + règle compressée) |
| **Nouveau dossier `memory/<sujet>/` créé** (gravée 2026-05-06) | `<sujet>/README.md` OBLIGATOIRE même commit (structure interne + ressources externes Notion/Vercel/web + skills associés + conventions) + ajout ligne dans `memory/WHERE.md` table universelle. Convention CLAUDE.md §4. |
| **Fichier orphelin détecté `memory/`** | Claude réorganise sans demander (CLAUDE.md §4) — déplacer dans dossier thématique cohérent OU créer dossier `<sujet>/` si pas de home naturel. MAJ `WHERE.md` + `<sujet>/README.md`. |
| **Spec/UX/comportement clarifié par Florent en session (verbatim, décision tranchée, options évaluées)** (gravée 2026-05-06) | OBLIGATOIRE MAJ `memory/features/<feature>.md` MEME session — pas attendre commit. Sections cibles : §1 PRD si spec fonctionnelle, § Description fonctionnelle si UX user-facing, § Décisions stratégiques (§9bis cerveau externalisé) si décision tranchée avec options. Verbatim Florent obligatoire dans la section. Cas inaugural toast role A 2026-05-06 (Florent re-explique 3 fois car doc pas synchro avec code `app.py:19517-19527`). |
| **2 niveaux dans feature doc à jour TOUT LE TEMPS** (gravée 2026-05-06, CLAUDE.md ligne 449+, pilote intelligent 2026-05-13 BP-389 V1.2) | (1) **§ Description fonctionnelle pure** user-facing — langage humain, **doc COMPLÈTE** (modes, options, parcours, cas d'usage, plateformes, limites V1, 3000-7000 chars), source pour démos / marketing / site web / posts LinkedIn / argumentaire investisseur. (2) **§ Implémentation technique** Claude-facing — PRD §1, code paths `app.py:NNNN`, mécanismes M1-M5, BPs, sélecteurs. Trigger MAJ = TOUTE session qui touche la feature. **🎯 ÉCRITURE/MAJ DE NIVEAU 1 → DÉLÉGUÉE au skill pilote `/update-feature-functional-doc <feature>`** (workflow 6 étapes, briques de référence, anti-patterns explicites — Florent verbatim 2026-05-13 *"pas comme un pinguin"*). Ce skill `/checkup-doc-sync` détecte le gap mais N'ÉCRIT PAS lui-même la § Description fonctionnelle : il invoque ou suggère `/update-feature-functional-doc`. Le pre-commit hook `tools/precommit_feature_doc_check.py` bloque commits non conformes (section absente / < 50 chars / sans frontmatter `type: subdoc`). |
| **Hook `tools/feature_doc_sync_hook.py` détecte gap code↔doc en session** (gravée 2026-05-06) | Fire 1× / session / feature quand code feature touché AVANT que `memory/features/<feature>.md` soit edité. Réagir au rappel : (a) MAJ doc immédiatement OU (b) commit message contient `[doc-sync skip: <raison>]` justifié. Sentinel reset après edit doc feature. |
| **Question user révèle gap doc feature** (gravée 2026-05-09) — user pose question sur comportement feature, Claude répond, user corrige *"non c'est pas exactement ça"* / *"normalement on fait l'inventaire de tout ça dans la doc"* / *"je pensais que ça marchait autrement"* → la doc manque description fonctionnelle pure OU inventaire complet des mécanismes | MAJ `memory/features/<feature>.md` MEME session, sans demander confirmation Florent (autonomie max CLAUDE.md §3.1) : (1) **§ X.0 Description fonctionnelle pure** au top de § 1 (langage user, déclinable site web / posts / argumentaire). (2) **§ Inventaire complet des mécanismes <verbe>/<verbe>** (paste, inject, click, scroll, read, etc. selon feature) — tableau exhaustif des chemins code possibles, quand chacun est choisi (trigger runtime), code path précis (`fichier:ligne`), apps cibles, pourquoi cette voie. Inclure récap visuel en arbre de routage. (3) **§ Distinction vocabulaire** si quiproquo récurrent identifié (ex : "Ctrl+V SpeakApp auto" vs "Ctrl+V user manuel" — même geste technique, deux exécutants différents). Template canonique = `memory/features/dictee-vocale.md` § 1.0 + § "Inventaire complet des mécanismes paste/inject (gravé 2026-05-09)". Cas inaugural session 2026-05-09 — Florent verbatim : *"normalement dans les docs de la fonctionnalité on fait l'inventaire de tout ça"* + *"celui-là je ne crois pas c'est juste le back-up pour les user en cas de soucis"*. |

## Skill lifecycle — Archive / Fusion / Store → MAJ pointages (NEW 2026-05-13)

Quand un skill change de statut via `/checkup-skills-perso` (archive simple, fusion vers cible, déplacement vers `skills-store/`), **toutes les refs `/<skill>` dans la doc deviennent broken silencieusement**. Drift garanti sans audit auto.

**Workflow obligatoire same-commit** :

1. **Audit auto** : `python tools/audit_skill_refs.py` (script projet — auto-discover `_archive/skills-archive/<date>/` + `skills-store/` projet + global, scan `CLAUDE.md` + `memory/features/*.md` + `memory/platforms/*.md` + `memory/references/*.md` + skills actifs cross-refs)
2. **Exclusions historiques** built-in (filtrées par le script) : `_archive` / `post-session-checks` / `reports` / `pending-verifications` / `handoffs` / `_investigations` / `dev-notes` / `migrations` / `_confirmed`. Logs datés → réécrire = falsifier histoire = interdit.
3. **Pour chaque ref broken active** : ajouter marker explicite sur la même ligne
   - Archive : `` `/<skill>` (archivé YYYY-MM-DD, `.claude/skills/_archive/skills-archive/<date>/<skill>/`) ``
   - Fusion : `` `/<target>` (skill `/<source>` fusionné dedans YYYY-MM-DD) ``
   - Store : `` `/<skill>` (en `skills-store/` depuis YYYY-MM-DD — récupérer via `/checkup-skills-perso` workflow B avant usage) ``
4. **CLAUDE.md priorité absolue** (chargé chaque session) → fix obligatoire same-commit. Features docs / platforms docs → idem si refs actives.
5. **Mode strict optionnel** : `python tools/audit_skill_refs.py --strict` exit 1 si broken refs. Branchable pre-commit hook pour gate dur.

**Cas inaugural 2026-05-13** : `/checkup-skills-perso` workflow B a archivé 7 + fusionné 13 + stocké 2 skills → 8 refs CLAUDE.md fixées same-commit. Règle gravée CLAUDE.md SpeakApp §3.7.

## Map — Code change → Skills to update (NEW 2026-04-30)

**Quand un code change, demander : quels skills couvrent ce domaine ? Lister leurs liens/procédures et MAJ même commit.**

| Change Type | Skills to update |
|-------------|------------------|
| Procédure de test change (sélecteur, étape, timing, plateforme cible) | `test-<feature>/SKILL.md` |
| Code path renommé / déplacé >50 lignes | TOUT skill qui cite `app.py:NNNN` ou `<file>:NNNN` du chemin déplacé — grep `grep -rn "<filename>:" .claude/skills/` |
| Nouveau hook ou pre-flight pattern | `preflight/SKILL.md` |
| Nouveau pattern debug cross-feature | `systematic-debugging` ou `iterative-debug` ou `gil-thread-debug` |
| Nouveau mécanisme d'interaction plateforme | `update-interaction-matrix/SKILL.md` (procédure MAJ matrice) |
| Nouveau pattern routing doc | `doc-routing-gate/SKILL.md` |
| Nouvelle commande vocale ou pattern Vosk | `vosk-monitor/SKILL.md` |
| Plateforme working-on-X change comportement | `working-on-claude-desktop/SKILL.md` ou équivalent |
| Nouveau BP alloué touchant domaine couvert par skill | Skill concerné — ajouter entry "Bugs connus" / "Pièges" |
| Restructuration docs (fichier renommé, section déplacée, source canonique nouvelle) | TOUT skill qui pointe vers l'ancien chemin — grep le chemin ancien |
| Règle CLAUDE.md §3 ajoutée/modifiée | Skill concerné par le domaine — mirror court (ne pas dupliquer verbatim, pointer vers CLAUDE.md §3) |
| Nouveau skill créé | Skill `test-<feature>` → routine quotidienne `speakapp-<feature>-daily` MEME session (CLAUDE.md §3 "Tout skill test-X = routine quotidienne") |

**Trigger logic** : après MAJ docs, doc-keeper demande : *"ce changement affecte-t-il une procédure ou un lien dans un skill ?"* Si oui → Edit skill dans le même batch.

**Skills audit minimal à chaque MAJ** :
1. **Liens cassés** — chemins `memory/<x>.md` cités existent toujours ?
2. **Code refs périmées** — `app.py:NNNN` toujours valide ? Fonction toujours nommée pareil ?
3. **BPs périmés** — BP cité encore actuel (pas écarté) ?
4. **Procédures obsolètes** — étapes test mentionnent toujours l'API/UI actuelle ?

## Status lifecycle capitalization — parallel cross-doc sync (2026-04-24)

**Quand module/feature change de statut lifecycle (ex: `devtools_stealth_reader.py` "à créer" → "primitives V1 livrées, wiring V2 pending"), TOUTES les références dans TOUS les docs ET skills doivent être mises à jour dans la même session.**

**Procédure (4 steps)** :

### Step A — Inventaire exhaustif
```bash
grep -rln "<module_or_feature>" memory/ .claude/skills/ dashboards/ CLAUDE.md
```
Étendre à TOUS les lieux : `memory/features/`, `memory/references/`, `memory/platforms/`, `memory/validation-pending-*.md`, `memory/roadmap/`, skills, CLAUDE.md. Un lieu oublié = drift garanti.

### Step B — Formule canonique partagée
Définir UNE SEULE formule de statut (mot-à-mot) à copier-coller. Exemple :
> "✅ **PRIMITIVES V1 LIVREES 2026-04-24** (commits `abc123`+`def456`, V1 gate PARTIAL_PASS smoke test). **V2 wiring pending** : ..."

Zero reformulation par doc. Chaque doc utilise exactement la même chaîne.

### Step C — Edits parallèles batch
Tous les Edit dans UN SEUL message avec tool calls parallèles. Échec partiel = état inconsistant si commit entre-temps.

### Step D — Vérification post-edit
```bash
grep -rln "à créer.*<module>\|<module>.*à créer" memory/ .claude/skills/
```
Doit retourner 0 match.

**Checklist commit `feat(status)` ou `docs(status-propagation)`** :
- [ ] Grep exhaustif fait (Step A)
- [ ] Formule canonique définie (Step B)
- [ ] Tous edits batch unique (Step C)
- [ ] Grep post-edit = 0 match (Step D)
- [ ] Skills mis à jour aussi (pas seulement docs)

## Update Protocol

### Step 1 — Read before writing
Toujours lire fichier concerné AVANT de le modifier. Jamais éditer à l'aveugle.

### Step 2 — Edit surgically
Changer uniquement ce qui est nécessaire. Préserver structure existante.

### Step 3 — Cross-check consistency
- Constantes dans doc = valeurs dans code (`fichier:ligne`)
- Commandes vocales doc = commandes `voice-commands.md` + code
- Plan vivant cohérent avec commit (sujet, statut, prochain pas, dernière session = commit hash courant)
- Skills cohérents avec docs : liens valides, procédures à jour, BPs cités encore actuels
- Hub HTML désynchro = intentionnel, NE PAS aligner doc dessus

### Step 4 — Capture des enseignements transversaux

**Après chaque session debug/fix, 3 questions avant de conclure :**

1. **Pattern réutilisable découvert ?** → ancrer dans skill transversal concerné (section "Pièges" ou "Patterns"), PAS dans feature doc du jour
2. **Insight outil/API externe ?** → Memory `feedback_*.md` cross-projet OU skill `working-on-X` plateforme
3. **Règle ou convention émergente ?** → Proposition règle CLAUDE.md (attendre validation Florent) OU feedback memory si local

**Trigger manuel** : Florent dit "garde cet insight" / "enregistre ça quelque part" → activer Step 4 même sans code change.

**Différence Step 1-3 vs Step 4** :
- Step 1-3 = changement de **code** → docs feature/skill-test-X + skills affectés
- Step 4 = changement d'**understanding** (pattern, piège, insight) → skill transversal / memory / règle

**Anti-roman** : 1 ligne dans la bonne section. Cause racine + fix + date. Pas de récit.

## Qualité du contenu — règles anti-accumulation

| Règle | BON | MAUVAIS |
|-------|-----|---------|
| Faits, pas narratifs | `Fix: guard _emit_gate (commit abc123)` | `On a essayé X puis Y puis Z a finalement marché` |
| Rationale pour chaque constante | `45px gap = marge sur 49px mesure, évite faux positifs headings (32px max)` | `_GAP_THRESHOLD = 45` (sans explication) |
| Comprimer checklists terminées | Tableau résumé `33/33` par catégorie + commits | 33 lignes `[x]` individuelles |
| Jalons, pas journal | `04-06 \| Boundary guards + DONE-gated E2E \| 5b5aa0b` | 50 lignes de récit |
| Référencer, pas dupliquer | `Voir mode-auto.md section Auto-permissions` | Copier 24 lignes d'un autre doc |

## Anti-Patterns

| Anti-Pattern | Pourquoi c'est mal |
|-------------|-------------------|
| "Je mettrai à jour plus tard" | Tu ne le feras pas. Maintenant. |
| MAJ doc sans MAJ skill correspondant | Skill devient menteur, re-grep ad-hoc, tokens gaspillés |
| MAJ skill sans MAJ doc référencé | Lien cassé silencieux |
| Sauter petits changements | S'accumulent en drift majeur |
| Éditer sans lire d'abord | Doublons et contradictions |
| Aligner doc interne sur hub HTML | Hub désynchro intentionnel depuis 2026-04-27 |
| Mentionner `FEATURES.md` ou C1-C4 layers | Architecture obsolète |
| MEMORY.md > 200 lignes | Tronqué au chargement, info perdue |

## The Bottom Line

**Every code change = immediate update of BOTH docs AND skills covering the domain. Faits + rationale. Zero narratif. WHERE.md = routing entry point. Hub HTML laissé mourir.**

---

## Auto-amélioration

**Ce skill s'améliore à chaque usage.** Responsabilité, pas bonus.

Avant de conclure :
1. **Friction détectée ?** (étape confuse, ordre sous-optimal) → corriger ce skill maintenant
2. **Bug résolu ou pattern découvert ?** → ajouter section pièges/patterns
3. **Approche validée ?** → ancrer comme pattern référence
4. **Gain applicable autres skills ?** → propager (ou PROPOSITION DE RÈGLE si transversal)

**Règle : ne jamais reporter une amélioration à "plus tard". L'appliquer maintenant ou la perdre.**


---

## Fusionné depuis `checkup-doc-routing` (projet SpeakApp, 2026-05-13)

Contenu préservé. Source archivée: `speak-app-dev/.claude/skills/_archive/skills-archive/2026-05-13/checkup-doc-routing/`

# Doc-routing gate — triage des decouvertes avant commit

## Pourquoi ce skill existe

**Probleme observe** : quand une session valide un critere feature (ex: `im-d1`, `ap-l2`), le reflex est de :
1. Cocher la checklist dans `memory/features/<feature>.md`
2. Commit + push
3. Done

Mais pendant la session, **plusieurs decouvertes techniques** sont faites qui appartiennent a d'autres axes :
- Un selecteur DOM nouveau → `memory/platforms/<plateforme>.md` (**Axe A**)
- Un endpoint HTTP ajoute → Axe A (plateforme concernee)
- Un pattern code reutilisable (ex: standalone DevToolsReader) → Axe A
- Un mecanisme transverse qui s'etend → matrice `interaction-mechanisms-matrix.md` §9 Journal
- Le statut d'une feature change sur une plateforme → matrice §2bis ligne feature

**Oublier de router = dette invisible** : a la prochaine session, on re-decouvre le selecteur, on re-invente le pattern standalone, on reecrit le fix.

**Incident declencheur** : 2026-04-16 session image-extraction. `im-d1` + `im-d5` valides, selecteur `[data-message-author-role="assistant"]` decouvert sur claude.ai, endpoint `/extract_images` ajoute a `ws_bridge.py`, pattern standalone DevToolsReader stabilise. Reflex = cocher la checklist feature. Oublie = tout le reste.

## Les 3 questions (dans l'ordre)

**Avant de taper `git commit`, repondre EXPLICITEMENT a chacune** (dans la reponse au user OU dans le commit body).

### Q1 — Nouveau selecteur / URL / DOM / UIA name / endpoint decouvert ?

**Declencheurs :**
- J'ai ecrit un `document.querySelector('...')` dans un JS inject
- J'ai trouve un `data-testid` / `aria-label` / XPath dans un snapshot
- J'ai ajoute une route HTTP a `ws_bridge.py` ou equivalent
- J'ai identifie un UIA `AutomationId` / `Name`
- J'ai decouvert qu'une URL change selon le contexte (ex: `/chat` vs `/code`)

**Action si OUI :**
- Editer `memory/platforms/<plateforme>.md` (Axe A)
- Ajouter une ligne dans la bonne section (Boutons, Selecteurs, Endpoints)
- Format table quand possible : `Element | Contexte | Selecteur | Utilise par | Date`

### Q2 — Nouveau mecanisme / pattern transverse / decision architecturale ?

**Declencheurs :**
- J'ai stabilise un **pattern code** reutilisable par d'autres tools (ex: standalone DevToolsReader avec `_active=True` + `_ensure_devtools_open()`)
- J'ai ajoute une capacite a un mecanisme M1-M5 (ex: M5 WS Bridge gagne `C-READ images`)
- J'ai trouve une **limitation** qui modifie la matrice (ex: UIA ne peut pas lire `<img>`)
- J'ai arbitre entre 2 mecanismes et documente pourquoi

**Action si OUI :**
- Editer `memory/references/interaction-mechanisms-matrix.md`
- §9 Journal : entree dated avec contexte + decision + impact
- §2 Capacites : si une nouvelle capacite × mecanisme est validee
- §2bis : si une feature × plateforme change d'etat

### Q3 — Statut feature change (WIP→V1, bloqueur leve, critere valide) ?

**Declencheurs :**
- J'ai coche une checkbox `[x]` dans `memory/features/<feature>.md`
- Une plateforme passe de ❌/🔧 a ✅ pour cette feature
- Un bloqueur listé dans la roadmap est leve

**Action si OUI :**
- `memory/features/<feature>.md` : cocher + noter date + commit hash
- `memory/references/interaction-mechanisms-matrix.md` §2bis : MAJ la ligne feature
- `dashboards/*-hub.html` + `dashboards/v1-roadmap.html` : cocher le critere V1

## Protocole d'utilisation

**Quand invoquer ce skill :**
- Fin de session de dev, avant `git add` + `git commit`
- User demande "commit + push"
- Avant de repondre "feature validee" au user
- **Post-livraison rapport / analyse** (ex: rapport categorie, baseline pipeline, audit) — Q1/Q2 souvent N/A mais Q3 (statut feature) ET MAJ Plan vivant + roadmap section pertinente OBLIGATOIRES. Workflow d'application ci-dessous indispensable car worktree contient typiquement WIP Florent non-commit.

**Workflow :**

1. **Lire le diff** : `git diff --stat` + `git diff` sur les fichiers code (pas docs)

2. **Poser Q1 — Selecteurs / URL / endpoint ?**
   - Scanner les JS inject, regex `querySelector|getElementById|data-testid|aria-`
   - Scanner ws_bridge.py / HTTP handlers pour nouveaux endpoints
   - Scanner UIA code pour nouveaux `AutomationId`
   - Si OUI → noter la plateforme + l'element → aller editer `memory/platforms/<X>.md`

3. **Poser Q2 — Mecanisme / pattern ?**
   - Le code ajoute un pattern reutilisable ? (ex: "standalone setup for tool X")
   - Une capacite M1-M5 gagne/perd un cas ?
   - Une limitation technique emerge ?
   - Si OUI → entree dans matrice §9 Journal (min: date + contexte + decision + impact)

4. **Poser Q3 — Statut feature ?**
   - Checklist feature cochee ?
   - Plateforme change d'etat (🔧→✅) ?
   - Si OUI → feature doc + matrice §2bis

5. **Commit atomique** :
   - `git add` inclut : code + docs Axe A (Q1) + matrice (Q2) + feature doc (Q3)
   - Commit body format :
     ```
     <titre court>

     Q1 (selecteurs/URL) : <OUI + fichier edite | N/A>
     Q2 (mecanisme)      : <OUI + entree journal | N/A>
     Q3 (statut feature) : <OUI + critere | N/A>

     <details>
     ```

## Interdits explicites

- ❌ Cocher un critere feature sans poser Q1 (selecteurs decouverts ?) et Q2 (mecanisme transverse ?)
- ❌ Updater UN SEUL axe quand les 3 questions sont OUI
- ❌ Commit "wip" puis "doc update" separes → TOUJOURS atomique
- ❌ "Je mettrai a jour la matrice plus tard" → maintenant ou jamais (dette invisible)
- ❌ Editer un fichier doc/skill SANS stasher au prealable le WIP Florent du worktree → garantit conflit massif rebase/pop (ex: 10 fichiers UU stash pop, sandbox bloque reset --hard, nettoyage manuel) — cf "Workflow d'application safe" ci-dessous

## Workflow d'application safe (gravage 2026-05-10)

**Probleme observe** : edits doc-routing dans un worktree avec WIP Florent non-commit → soft reset commit accidentel mélange edits avec WIP Florent → stash pop génère 10 conflits UU → sandbox refuse `git reset --hard` → nettoyage pénible. Friction repétée 5x cette semaine sur les analyses categories.

**Workflow obligatoire 5 phases** quand on touche docs/skills SpeakApp dans un worktree :

### Phase 1 — Inventaire pre-edit
```bash
git status --short | head -20
git ls-files --others --exclude-standard | head -10
```
Si > 5 fichiers M / ?? = WIP Florent present → stash AVANT edits (Phase 2). Sinon edits direct OK.

### Phase 2 — Stash WIP isole
```bash
git stash push -u -m "doc-routing-$(date +%H%M%S)"
git status --short  # doit etre clean
```
Stash inclut tracked + untracked. Le marker `doc-routing-*` permet de retrouver facilement.

### Phase 3 — Edits doc-routing
Apply Q1/Q2/Q3 edits sur worktree clean. Re-Read entre Edit calls pour eviter l'erreur "File modified since read" (linter/hook auto-MAJ entre temps).

### Phase 4 — Commit + push via `/git-safe-push`
```bash
git add <files explicites> && git commit -m "..."
```
Puis invoquer skill `/git-safe-push` qui gere :
- fetch + rebase origin/dev
- auto-resolve `kb/features-index.json` conflit (`git checkout --theirs`, pre-commit hook regen au prochain edit)
- auto-resolve YAML pending-verifications conflits (`--theirs`)
- push HEAD:dev avec retry sur race condition multi-worktree

### Phase 5 — Stash pop ou skip
```bash
git stash pop  # tente restoration WIP Florent
```
**Si conflit pop massif (8+ UU)** = origin/dev a beaucoup avance pendant le push, le WIP est obsolete. Options :
- **A** (reco) : `git reset --hard HEAD` pour clean worktree, le `stash@{0}` reste intact pour `git stash apply` ultérieur sur base à jour
- **B** : resoudre les conflits manuellement fichier par fichier
- **C** : laisser le worktree, en creer un neuf depuis origin/dev

**Note sandbox** : `git reset --hard` peut être bloqué par le sandbox classifier. Si refus → demander explicitement à Florent de l'exécuter (1 commande), c'est lui qui debloque.

## Lecons capitalisées 2026-05-10

1. **3 ratés Edit sur 4 tentatives** quand on `Read` puis `Edit` un fichier feature doc avec hook plan-vivant actif : le hook MAJ le frontmatter entre Read et Edit → erreur "File modified since read". Solution : Re-Read systematique entre 2 Edit consécutifs sur même fichier.
2. **Race condition push multi-worktree** : push refusé non-fast-forward pendant qu'un autre worktree pushait sur dev. Solution : `/git-safe-push` retry boucle (fetch + rebase + push) intégrée.
3. **Stash pop massif après push doc-sync** : quand origin/dev a beaucoup avancé pendant le push (autres sessions actives), le stash devient inappropriable. Garder le stash, créer un worktree neuf, re-apply le stash dessus.
4. **kb/features-index.json conflit auto-resolvable** déjà géré par `/git-safe-push`. Pas besoin de procédure dédiée.

## Template reponse au user

Quand j'ai termine une session et que je vais commit :

```
Validation [feature].[critere] OK.

Doc-routing gate (CLAUDE.md §5) :
- Q1 (selecteurs/URL)   : OUI → memory/platforms/<X>.md (<resume>)
- Q2 (mecanisme)        : OUI → matrice §9 (<resume>) | N/A
- Q3 (statut feature)   : OUI → feature doc coche <critere>

Commit atomique prepare avec les 4 fichiers. Push ?
```

Si les 3 sont N/A :
```
Doc-routing gate : Q1/Q2/Q3 N/A — <raison, ex: simple bugfix ligne 847, pas de nouveau selecteur ni mecanisme ni statut>. Commit direct.
```

## References

- `CLAUDE.md` §5 "Git & Workflow → Doc-routing gate"
- `.claude/skills/update-interaction-matrix/SKILL.md` (post-discovery, plus general)
- `memory/references/interaction-mechanisms-matrix.md` §0.5 Index navigation
