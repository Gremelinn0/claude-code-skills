---
name: doc-keeper
description: Systematically updates all project reference documents after any code change. Use after implementing features, fixing bugs, modifying configs, adding commands, or changing architecture. Triggers on any code modification that affects documented behavior.
---

# Doc Keeper — Systematic Documentation Sync

## Overview

Every code change MUST be reflected in the project's reference documents. Documentation drift causes repeated context loss, wasted conversations, and user frustration.

**Core principle:** Code changed = docs updated = QA updated. Same message. No exceptions.

## When To Apply

**ALWAYS after:**
- Implementing a new feature or modifying an existing one
- Adding/removing/changing config keys, hotkeys, voice commands
- Modifying UI elements (voyants, indicators, buttons, tooltips)
- Changing architecture (new files, renamed files, moved functions)
- Fixing bugs that change documented behavior
- Adding/removing dependencies
- Deploiement / auth / SaaS changes

## Document Registry

**Chaque projet a sa propre structure docs.** Consulter le CLAUDE.md du projet pour la liste exacte.

**Structure type SpeakApp (speak-app-dev) :**

| Couche | Fichiers | Role | Skill |
|--------|----------|------|-------|
| C1 — Hub HTML | `dashboards/*.html` | Fonctionnel (utilisateur) | `/define-feature` |
| C2 — Feature doc MD | `memory/features/*.md` | Technique (Claude) | `/doc-keeper` (ce skill) |
| C3 — Skill test-X | `.claude/skills/test-*/SKILL.md` | Dev+test (Claude) | `/create-feature-skill` |
| C4 — Program.md | `docs/autoresearch/*/program.md` | Autoresearch (optionnel) | `/autoresearch` |

**Autres docs projet :** `CLAUDE.md` (regles), `FEATURES.md` (source de verite features), `MEMORY.md` (index sous-fichiers), `memory/platforms/*.md` (par plateforme).

**Regle 4 couches :** zero duplication entre couches. Hub = arbitre en cas de divergence hub <-> doc.

## Map Changes → Documents

| Change Type | Documents to Update |
|-------------|-------------------|
| New feature implemented | Feature doc (`memory/features/`) + FEATURES.md + roadmap |
| Modified feature | Feature doc (section concernee) |
| Bug fix | Feature doc (tableau "Bugs resolus" — 1 ligne : cause + fix + date + commit) |
| Bug fix on a feature with skill | **Skill test-X** (classifier + acquis) + feature doc (bugs resolus) |
| New config key / constante | Feature doc (section "Constantes" avec rationale) |
| New hotkey | Feature doc + FEATURES.md (raccourcis) |
| New voice command | Feature doc + `memory/core/voice-commands.md` |
| UI change | Feature doc + hub HTML si visible utilisateur |
| New file created | Feature doc (section "Architecture — fichiers cles") |
| Roadmap task done | `v1-roadmap.html` (skill update-roadmap) |
| Architecture change | Feature doc + CLAUDE.md si transversal |
| Nouvelle validation N4 identifiee (action physique/micro/subjective, Florent requis) | `memory/validation-pending-n4.md` — ajouter ligne dans tableau Suivi + section detaillee |
| Validation N4 completee par Florent | `memory/validation-pending-n4.md` — cocher dans tableau Suivi (date + "Par: Florent") + feature doc critere correspondant |
| Mecanisme d'interaction change (UIA/CDP/DevTools/Win32/OCR/WS Bridge/hooks) | **Skill `/update-interaction-matrix` — OBLIGATOIRE.** MAJ atomique : matrice §2bis (Axe B feature×plateforme) + `memory/platforms/<p>.md` (Axe A selecteurs) + journal §9 (≤60 mots). Matrice gagne sur tout autre doc en cas de conflit. |
| Reader / methode lecture chat change (statut, limitation, nouveau reader, plateforme) | **Skill `/update-interaction-matrix` — OBLIGATOIRE.** Meme procedure (reader-solutions fusionne dans la matrice unique depuis 2026-04-15). MAJ §2bis feature "Lecture chat" ou "Artifact/Doc attache" + journal §9. |
| Nouveau selecteur / widget / etat decouvert (scan DOM, snapshot, debug) | **Axe A** : `memory/platforms/<plateforme>.md` (catalogue selecteurs). **Axe B** : matrice §2bis si ca change le statut d'une feature. Skill `/update-interaction-matrix` pour la procedure. |
| **Status lifecycle transition** (module/feature passe "a creer" → "V1 livre" → "V2 pending" → "V2 livre") | **Capitalisation parallele OBLIGATOIRE** sur TOUS les docs qui referencent ce module/feature. Voir section "Status lifecycle capitalization" ci-dessous. Zero doc ne doit rester avec l'ancien statut. |
| **Code feature modifie** (app.py, wisper-bridge/, cdp_*, devtools_*, cc_ui/, etc.) | **Section `## 📌 Plan vivant` du feature doc** — MAJ avec : sujet/statut/prochain pas/bloqueurs/derniere session (commit hash). Regle CLAUDE.md §3 "Plan vivant a jour en continu" (2026-04-25). Verification post-commit OBLIGATOIRE. |

## Status lifecycle capitalization — parallel cross-doc sync (2026-04-24)

**Contexte** : quand un module ou une feature change de statut lifecycle (ex : `devtools_stealth_reader.py` passe de "a creer" a "primitives V1 livrees, wiring V2 pending"), **toutes les references a ce module dans TOUS les docs doivent etre mises a jour dans la meme session**, avec les memes commits et la meme formule.

**Pourquoi c'est critique** :
- Un doc qui reste a "a creer" pendant qu'un autre dit "V1 livre" = desinformation + re-decouverte future "mais c'etait livre ou pas ?"
- Meme dans le meme commit, oublier 1 doc sur 5 = drift immediat
- Le user pose la question "c'est fait ?" et recoit une reponse contradictoire selon le doc consulte

**Procedure systematique (4 steps)** :

### Step A — Inventaire "tous les docs qui mentionnent ce module"

Avant toute edition, grep explicitement :
```bash
grep -rln "devtools_stealth_reader" memory/ .claude/ dashboards/ CLAUDE.md
```
**Toujours** etendre a tous les lieux : `memory/features/`, `memory/references/`, `memory/platforms/`, `memory/validation-pending-*.md`, `memory/roadmap/`, feature-capabilities-matrix.md, interaction-mechanisms-matrix.md, skills, CLAUDE.md, dashboards. Un lieu oublie = drift garanti.

### Step B — Formule canonique partagee

Definir **UNE SEULE** formule de statut (mot-a-mot) a copier-coller dans tous les docs. Exemple :
> "✅ **PRIMITIVES V1 LIVREES 2026-04-24** (commits `abc123`+`def456`+`ghi789`, N lignes, V1 gate PARTIAL_PASS smoke test). **V2 wiring pending** : ..."

**Zero reformulation par doc.** Chaque doc utilise exactement la meme chaine. Si un doc necessite un angle different (ex: matrice = vue capability, feature doc = vue implementation), garder la formule canonique + ajouter contexte specifique au doc, jamais reformuler la formule.

### Step C — Edits paralleles dans UN SEUL batch

Lancer tous les Edit dans **un seul message** avec tool calls paralleles. Jamais sequentiel. Raison : un echec partiel (3/5 OK, 2/5 KO) laisse le systeme dans etat inconsistant si on commit entre-temps.

### Step D — Verification post-edit

Apres batch :
```bash
grep -rln "a creer.*devtools_stealth_reader\|devtools_stealth_reader.*a creer" memory/
```
Doit retourner 0 match. Si > 0 → un doc a ete oublie → ajouter au batch, re-commit.

**Checklist avant commit `feat(status)` ou `docs(status-propagation)`** :
- [ ] Grep exhaustif fait (step A) ?
- [ ] Formule canonique definie (step B) ?
- [ ] Tous les edits dans un seul batch (step C) ?
- [ ] Grep "ancien statut" post-edit = 0 match (step D) ?
- [ ] Commits references coherents partout (meme liste de hashes dans tous les docs) ?

**Anti-pattern** : "je mets a jour le feature doc d'abord, je verrai les autres plus tard" → ne le fera pas. Immediate full propagation ou abandon.

## Qualite du contenu — regles anti-accumulation

**Le doc-keeper ecrit BIEN des le depart pour eviter les audits de nettoyage.**

| Regle | Exemple BON | Exemple MAUVAIS |
|-------|-------------|-----------------|
| **Faits, pas narratifs** | `Fix: guard _emit_gate (commit abc123)` | `On a essaye X puis Y puis Z a finalement marche` |
| **Rationale pour chaque constante** | `45px gap = marge sur 49px mesure, evite faux positifs headings (32px max)` | `_GAP_THRESHOLD = 45` (sans explication) |
| **Comprimer les checklists terminees** | Tableau resume `33/33` par categorie + commits | 33 lignes `[x]` individuelles |
| **Jalons, pas journal** | `04-06 \| Boundary guards + DONE-gated E2E \| 5b5aa0b` | 50 lignes de recit de la session du 06 |
| **Referencer, pas dupliquer** | `Voir mode-auto.md section Auto-permissions` | Copier 24 lignes d'un autre doc |

**Quand mettre a jour un feature doc :**
- **Bug fixe** → 1 ligne dans le tableau bugs (cause + fix + commit + date). Des faits, pas de prose.
- **Decision prise** → section "Decisions de design" : choix + alternative rejetee + pourquoi.
- **Constante ajoutee** → valeur + fichier + rationale (comment le nombre a ete derive).
- **Checklist 100% cochee** → comprimer en tableau resume avec scores par categorie + commits de reference.
- **Session terminee** → 1 ligne jalon (date + resultat cle + commit). Pas de recit.

## Update Protocol

### Step 1: Read before writing
Toujours lire le fichier concerne AVANT de le modifier. Ne jamais editer a l'aveugle.

### Step 2: Edit surgically
Changer uniquement ce qui est necessaire. Preserver la structure existante.

### Step 3: Cross-check consistency
- Feature doc coherent avec le hub HTML (`speakapp-hub.html` = arbitre)
- Constantes dans le doc = valeurs dans le code (fichier:ligne)
- Commandes vocales dans le doc = commandes dans `voice-commands.md` + code
- Si divergence hub <-> doc → corriger le doc, JAMAIS le hub
- **Plan vivant coherent avec le commit** (CLAUDE.md §3) : sujet refletant la session, statut refletant le changement (WIP→V1 si livre, etc.), prochain pas = etape suivante reelle, derniere session = commit hash courant. Si Plan vivant obsolete → MAJ avant de conclure le doc-keeper.

### Step 4: Capture des enseignements transversaux (nouveau 2026-04-14)

**Apres chaque session de debug/fix, se poser 3 questions avant de conclure :**

1. **Pattern reutilisable decouvert ?** (ex: "UIA Invoke flaky sur Electron", "toujours set cooldown apres succes fast-path")
   → Ancrer dans le skill transversal concerne (`working-on-claude-desktop`, `cd-auto-permissions`, etc.)
   → Section "Pieges" ou "Patterns" du skill, PAS dans la feature doc du jour

2. **Insight sur un outil/API externe ?** (ex: "CDP ne marche pas sur CD MSIX", "InvokePattern != clic reel")
   → Memory `feedback_*.md` si valable cross-projet
   → Skill `working-on-X` si specifique a une plateforme

3. **Regle ou convention emergente ?** (ex: "toute boucle DOIT avoir backoff", "après succes → cooldown obligatoire")
   → Proposition de regle dans CLAUDE.md (attendre validation utilisateur)
   → OU feedback memory si locale a un pattern

**Trigger manuel** : si l'utilisateur dit "je sens qu'on a fait quelque chose d'important" / "garde cet insight" / "enregistre ca quelque part" → activer ce Step 4 en priorite, meme sans code change.

**Difference cle avec les feature docs (Step 1-3) :**
- Step 1-3 = changement de code → doc feature/hub/skill-test-X
- Step 4 = changement d'**understanding** (pattern, piege, insight) → skill transversal / memory / regle

**Regle anti-roman** : 1 ligne dans la bonne section. Cause racine + fix + date. Pas de recit de session.

## Anti-Patterns

| Anti-Pattern | Pourquoi c'est mal |
|-------------|-------------------|
| "Je mettrai a jour plus tard" | Tu ne le feras pas. Maintenant. |
| Mettre a jour un seul fichier | Cree des incoherences |
| Sauter les petits changements | S'accumulent en drift majeur |
| Editer sans lire d'abord | Doublons et contradictions |
| Laisser MEMORY.md depasser 200 lignes | Tronque au chargement, info perdue |
| Ne pas mettre a jour le QA | Les nouveaux bugs ne seront pas detectes |

## The Bottom Line

**Every code change = immediate doc update. Faits + rationale. Zero narratif. Hub = arbitre.**


---

## Auto-amelioration

**Ce skill s'ameliore a chaque usage.** C'est une responsabilite, pas un bonus.

Apres chaque execution, avant de conclure :
1. **Friction detectee ?** (etape confuse, ordre sous-optimal, info manquante) → corriger ce skill immediatement
2. **Bug resolu ou pattern decouvert ?** → l'ajouter dans la section pieges/patterns de ce skill
3. **Approche validee ?** → l'ancrer comme pattern reference dans ce skill
4. **Gain applicable a d'autres skills ?** → propager (ou PROPOSITION DE REGLE si transversal)

**Regle : ne jamais reporter une amelioration a "plus tard". L'appliquer maintenant ou la perdre.**
