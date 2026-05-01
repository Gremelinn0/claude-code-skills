---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## Documentation Gate (SpeakApp / tout projet avec memory/)

**Déclenché automatiquement par hook après chaque `git push` (`.claude/settings.json`).**
**Source unique — remplace le pipeline post-dev de CLAUDE.md §5.**

**Clause skip** : si les 4 questions sont clairement NA (push docs-only, gate déjà passé dans cette session, commit trivial sans changement de comportement), dire en une phrase pourquoi et passer. Pas de cérémonie inutile sur un push qui ne touche rien.

**Sinon, poser ces 4 questions. Ce n'est pas optionnel.**

```
DOC GATE — à passer avant "c'est bon" / push final / fin de session :

1. Ce changement touche un reader / méthode de lecture chat ?
   → OUI → reader-solutions-matrix.md mis à jour ?  (sinon STOP)

2. Ce changement touche un mécanisme d'interaction (CDP/UIA/DevTools/Win32/OCR/WS Bridge/hooks) ?
   → OUI → interaction-mechanisms-matrix.md mis à jour ? (sinon STOP)

3. roadmap.md reflète l'état réel du code (bug fixé, bloqueur levé, commit ancré) ?
   → TOUJOURS vérifier — même si le changement semble mineur (sinon STOP)

4. Le skill test-X ou run-tests concerné est à jour ?
   → Nouveau pattern découvert ? Bug résolu ? Méthode de test prouvée ?
   → OUI → skill mis à jour ? (sinon STOP)
```

**Critères de jugement pour les points 1-4 :**

| La modif a de la valeur doc si... | Exemple |
|----------------------------------|---------|
| Un futur Claude passerait du temps à redécouvrir ça | Bug workspace suffix strip |
| Un test qui semblait "semi-auto" est prouvé "autonome" | PR-AG-03 |
| Un comportement inattendu de la plateforme est documenté | Plan BrowserView = CDP tab séparé |
| Un pattern de fix qui s'applique à d'autres endroits | strip suffixe titre CDP |
| Un status "en attente" est maintenant validé | E2E PASS avec commit et log |

**Ce qui ne mérite PAS une entrée doc :**
- Typo fixée
- Refactor purement interne sans changement de comportement
- Changement déjà documenté ailleurs (pas de doublon)

**Conséquence du skip :** la prochaine session relit du code périmé, re-diagnostique ce qui est déjà résolu, perd 20-30 min. Ce n'est pas de l'efficacité, c'est de la dette invisible.

## The Bottom Line

**No shortcuts for verification — code OR docs.**

Run the command. Read the output. Check the docs. THEN claim done.

This is non-negotiable.


---

## Auto-amelioration

**Ce skill s'ameliore a chaque usage.** C'est une responsabilite, pas un bonus.

Apres chaque execution, avant de conclure :
1. **Friction detectee ?** (etape confuse, ordre sous-optimal, info manquante) → corriger ce skill immediatement
2. **Bug resolu ou pattern decouvert ?** → l'ajouter dans la section pieges/patterns de ce skill
3. **Approche validee ?** → l'ancrer comme pattern reference dans ce skill
4. **Gain applicable a d'autres skills ?** → propager (ou PROPOSITION DE REGLE si transversal)

**Regle : ne jamais reporter une amelioration a "plus tard". L'appliquer maintenant ou la perdre.**
