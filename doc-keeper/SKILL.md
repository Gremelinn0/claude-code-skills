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
