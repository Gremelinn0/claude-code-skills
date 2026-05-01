---
name: doc-keeper
description: Systematically updates project docs AND skills after any code change. Use after implementing features, fixing bugs, modifying configs, adding commands, or changing architecture. Triggers on any code modification that affects documented behavior or skill procedures.
---

# Doc Keeper — Docs + Skills Sync

## Overview

Every code change MUST propagate to BOTH the project's reference docs AND the skills that reference them. Doc drift = repeated context loss. Skill drift = broken links + re-grep ad-hoc + tokens wasted.

**Core principle:** Code changed = docs updated = skills updated. Same commit. No exceptions.

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
| Architecture change transversale | Feature docs concernés + CLAUDE.md §3 si nouvelle règle émerge |
| Validation N4 identifiée | `memory/validation-pending-n4.md` — ajouter ligne tableau Suivi |
| Validation N4 complétée par Florent | `memory/validation-pending-n4.md` (cocher) + feature doc critère |
| Mécanisme d'interaction change (UIA/CDP/DevTools/Win32/OCR/WS Bridge/hooks) | **Skill `/update-interaction-matrix` OBLIGATOIRE** : matrice §2bis + `memory/platforms/<p>.md` + journal §9 |
| Reader / méthode lecture chat change | **Skill `/update-interaction-matrix` OBLIGATOIRE** : §2bis feature "Lecture chat" + journal §9 |
| Nouveau sélecteur / widget / état découvert | Axe A: `memory/platforms/<plateforme>.md` · Axe B: matrice §2bis si change statut feature |
| Status lifecycle transition (V1 livré → V2 pending → V2 livré) | **Capitalisation parallèle OBLIGATOIRE** sur tous docs référençant module/feature (voir section "Status lifecycle capitalization") |
| Nouvelle règle gravée par Florent | CLAUDE.md §3 (verbatim source + règle compressée) |

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
