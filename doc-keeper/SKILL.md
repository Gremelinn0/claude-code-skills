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

## Document Registry — SpeakApp Project

Les docs sont dans `.claude/projects/<project-key>/memory/` :

```
MEMORY.md          — INDEX principal (< 200 lignes). Lu automatiquement au demarrage.
                     Contient : nom produit, modele business, features, etat actuel,
                     raccourcis, commandes Vosk, priorites, preferences, notes techniques.

todo.md            — To-do list actions concretes, triees par priorite.
                     Mettre a jour : cocher les items DONE, ajouter les nouveaux.

deployment.md      — Deploiement SaaS : credentials Supabase, repos GitHub, etat Loveable,
                     TODO prompts Loveable, auth flow, faisabilite Mac.

loveable.md        — Loveable Cloud : role, process (2 modes), credentials, etat web.

architecture.md    — Structure fichiers, classes, moteurs STT, auth flow, tech stack.

roadmap.md         — SUPPRIME. Remplace par v1-roadmap.html (dashboard HTML unifie).
                     Utiliser le skill update-roadmap pour marquer les taches DONE.

changelog.md       — Historique complet des changements (Mars 2026).

testing.md         — Plan de tests, checklist PASS/FAIL, bugs trouves.

pricing.md         — Calculs couts STT et recommandations prix abo.

status.md          — Etat actuel rapide (resume en 15 lignes).
```

Autres docs (dans le projet) :
```
USER_STORIES.html  — speak-app-dev/ (12 user stories, criteres d'acceptation)
CLAUDE.md          — Racine projet (regles, stack, skills)
```

## Map Changes → Documents

| Change Type | Documents to Update |
|-------------|-------------------|
| New feature implemented | MEMORY.md (features list), changelog.md, v1-roadmap.html (skill update-roadmap), todo.md (cocher) |
| Modified feature | MEMORY.md (update description), changelog.md |
| Bug fix | changelog.md, todo.md (si dans la liste) |
| New config key | MEMORY.md (si critique) ou architecture.md |
| New hotkey | MEMORY.md (raccourcis section) |
| New voice command | MEMORY.md (commandes Vosk section) |
| UI change | MEMORY.md (couleurs voyants si concerne) |
| New file created | architecture.md |
| Auth / SaaS change | deployment.md, loveable.md |
| Roadmap task done | v1-roadmap.html (skill update-roadmap), todo.md (cocher) |
| Dependency | architecture.md (tech stack) |
| New test added | testing.md (mettre a jour le compte) |

## QA Sync — Boucle d'amelioration

**Apres chaque mise a jour des docs, verifier si le skill QA doit etre mis a jour :**

1. **Nouvelle feature** → ajouter un check dans le qa-agent scheduled task (speakapp-qa-daily)
2. **Nouveau bug fixe** → ajouter un pattern a verifier dans la Phase 3 du qa-agent
3. **Nouvelle commande Vosk** → mettre a jour le count dans test_speakapp.py
4. **Nouveau raccourci** → ajouter dans la checklist manuelle du qa-agent
5. **Changement UI** → ajouter dans la verification Widget UI (Agent 1)

**Comment mettre a jour le QA scheduled task :**
```
Utiliser mcp__scheduled-tasks__update_scheduled_task avec taskId="speakapp-qa-daily"
et un prompt mis a jour incluant les nouveaux checks.
```

## Update Protocol

### Step 1: Read before writing
Toujours lire le fichier concerne AVANT de le modifier. Ne jamais editer a l'aveugle.

### Step 2: Edit surgically
Changer uniquement ce qui est necessaire. Preserver la structure existante.

### Step 3: Cross-check consistency
- Noms de features coherents entre MEMORY.md et v1-roadmap.html
- Config keys coherents entre docs et config.json reel
- Status (DONE/TODO) coherents entre v1-roadmap.html, changelog.md, et todo.md
- Nombre de tests dans testing.md = nombre reel dans test_speakapp.py
- Nombre de commandes Vosk dans MEMORY.md = nombre reel dans app.py

### Step 4: Keep MEMORY.md under 200 lines
Si MEMORY.md depasse 200 lignes apres une mise a jour :
1. Identifier ce qui peut etre deplace dans un sous-fichier
2. Deplacer le detail, garder un resume + lien dans MEMORY.md
3. Verifier que l'index des sous-fichiers est a jour

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

**Every code change = immediate doc update + QA update. Same message. No "I'll do it later."**
