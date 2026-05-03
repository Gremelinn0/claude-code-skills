---
name: dispatch
description: Exécute en parallèle batch 2-8 micro-tâches additives (sub-agents Sonnet) après plan validé en amont. Mode strict — additif uniquement, pas de refactor. Couvre aussi cas debug parallèle indep (3+ tests fail causes différentes). Triggers "dispatch ce batch", "lance agents parallèle", "exécute plan parallèle".
trigger: user-invocable OR invoqué par /drive, /dev-orchestrator quand le plan contient 2-8 tâches indépendantes
scope: global — tout projet
---

# /dispatch — Exécution parallèle d'un batch de micro-tâches

**`/dispatch` est un OUTIL, pas un workflow complet.** Il prend en entrée un plan déjà validé (liste de tâches GO marquées par un agent en amont) et les exécute en parallèle via N sous-agents Sonnet, avec une review Opus finale.

**`/dispatch` ne fait PAS** : audit, priorisation, plan, choix des tâches. Ces étapes sont la responsabilité de l'invocateur (`/drive`, `/dev-orchestrator`, ou Claude main session après audit explicite).

---

## Quand utiliser

| Situation | Chemin |
|-----------|--------|
| Florent dit explicitement "dispatch ce batch" / "lance les agents sur ces tâches" | `/dispatch` direct |
| `/drive` arrive sur une session avec 5+ petits items indépendants | `/drive` STOP, propose à Florent d'invoquer `/dispatch` (cf règle ci-dessous) |
| `/dev-orchestrator` a fait son bilan et identifié 3-8 GAPs additifs prêts | `/dev-orchestrator` STOP, propose à Florent d'invoquer `/dispatch` (cf règle ci-dessous) |
| Main session après audit explicite (Phase 0 faite, GO/PENDING/SKIP déterminés) | Invoquer `/dispatch` avec la liste des GO |
| Debug 3+ test files / sous-systèmes en panne avec causes racines DIFFÉRENTES (pas de shared state) | Invoquer `/dispatch` mode "debug parallèle indep" — 1 agent par bug, R1-R5 relax (investigation = pas additif) |

> **Note fusion 2026-05-02** : skill `/dispatch-parallel-agents` (pattern debug parallèle) absorbé dans cette table. Stocké dans `~/.claude/skills-store/`. Récupérable via `/skill-store` si besoin du contenu détaillé.

### Règle non-négociable — STOP + handoff Florent avant `/dispatch` (jamais de chaining auto)

Quand `/drive` ou `/dev-orchestrator` arrive au point d'invoquer `/dispatch`, il **NE LE FAIT PAS LUI-MÊME**. Il doit :

1. **STOP** — finir son audit + plan, ne pas chainer automatiquement vers `/dispatch`
2. **Présenter à Florent** : "Plan prêt — N tâches GO : [liste 1 ligne par tâche]. Change de modèle (Sonnet conseillé) puis invoque `/dispatch`."
3. **Attendre** — c'est Florent qui décide quand lancer le dispatch (et avec quel modèle).

**Pourquoi** : Florent gère manuellement les transitions de modèle (Opus pour réfléchir/auditer, Sonnet pour exécuter en batch). Le chaining auto `/drive → /dispatch` priverait Florent de ce contrôle. Le pattern correct est **STOP + handoff explicite**, pas auto-chaining.

**Exception** : si Florent dit explicitement "lance le dispatch direct" ou "enchaîne", alors le skill peut chainer sans stopper.

✅ **Conditions pour lancer `/dispatch` (toutes obligatoires)** :
- 2-8 micro-tâches **indépendantes** (≤30 min chacune)
- Chaque tâche = ajouter sélecteur, constante, préfixe, mapping (pas modifier de logique)
- Tâches sur fichiers **différents** (sinon séquentiel)
- **Plan déjà validé en amont** (audit Phase 0 fait par l'invocateur, pas par `/dispatch`)
- Pas de test live requis (CD, AG, Chrome) — Sonnet ne peut pas

❌ **Refuser `/dispatch` si** :
- Aucun plan en amont — l'invocateur doit auditer d'abord
- Une tâche modifie de la logique existante (refactor) — trop risqué pour Sonnet, basculer sur Opus direct
- Une tâche nécessite de comprendre le flux complet d'une feature
- Doute sur le scope d'une tâche — bloquer, demander clarification à l'invocateur

---

## Articulation avec les autres skills

```
┌─────────────────────────────────────────────────────────────┐
│  PLAN (responsabilité de l'invocateur — PAS /dispatch)      │
│                                                              │
│  /drive          → finit la session active, identifie       │
│                    les sujets, fait l'audit Phase 0          │
│  /dev-orchestrator → bilan macro projet, priorise les GAPs  │
│                      candidats, fait l'audit Phase 0         │
│  Main session    → Florent ou Claude détermine les tâches   │
│                    GO après Read/Grep/scan explicite         │
└─────────────────────────────────────────────────────────────┘
                              ↓
                  Plan validé : N tâches GO
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  /dispatch — EXÉCUTION (ce skill)                            │
│                                                              │
│  1. Reçoit la liste GO (de l'invocateur)                    │
│  2. Vérifie : conflits fichiers ? séquentiel sinon ||       │
│  3. Dispatch N sous-agents Sonnet en parallèle              │
│  4. Chaque agent : 5 règles + template prompt + tests       │
│  5. Review finale Opus (code-reviewer)                      │
│  6. Retourne : N commits + verdict review + push            │
└─────────────────────────────────────────────────────────────┘
                              ↓
              Retour à l'invocateur (drive / orchestrator)
                              ↓
       Checklist 7 étapes BLOQUANTE produit-ready
       (cf CLAUDE.md SpeakApp § Délégation tactique)
```

**Différence avec `/drive`** : `/drive` finit UN sujet de la session courante en autonomie inline (1 sujet, dans la conv). `/dispatch` exécute N tâches isolées en parallèle dans des sub-agents (N tâches, sub-agents séparés).

**Différence avec `/dev-orchestrator`** : `/dev-orchestrator` est un orchestrateur niveau **projet** (bilan macro, scan multi-sources, priorisation). `/dispatch` est un exécuteur niveau **batch** (lance les agents).

**Différence avec `/autopilot`** : `/autopilot` lance un agent qui boucle en background sur un objectif goal-driven (multi-itérations avec state.md). `/dispatch` exécute N tâches one-shot en parallèle, pas de boucle.

---

## Pipeline d'exécution (interne — quand /dispatch est invoqué)

```
Phase 1 : Sanity check du plan reçu (PAS re-audit)
          → Tâches sont-elles bien GO ? Files indépendants ?

Phase 2 : Dispatch Sonnet en parallèle (1 agent par tâche GO)
          → Tâches même fichier = séquentiel (sinon conflit git)

Phase 3 : Chaque agent : 5 règles + template + tests + commit
          → Bilan dans docs/sonnet-batch/<date>-batch-<N>.md

Phase 4 : Review finale Opus (feature-dev:code-reviewer)
          → ✅ OK / ⚠️ fix mineur / ❌ revert

Phase 5 : Retour à l'invocateur avec : N commits + verdict
```

**Comment ça marche techniquement :**
- Claude (modèle actif) dispatche des sous-agents via le tool `Agent(...)`
- Sous-agents exécuteurs : `Agent(model="sonnet")` — UNE modif additive chacun
- Review finale : `Agent(subagent_type="feature-dev:code-reviewer", model="sonnet")` — Sonnet relit, n'orchestre pas

**Principes de légèreté :**
- Pas de TDD sur micro-tâches
- Pas de TodoWrite dans les agents Sonnet
- Contexte externalisé (rapport batch = fichier, pas conversation)
- Un seul round de review
- Max 6-8 tâches GO par batch

---

## Sanity check du plan reçu (Phase 1 interne)

**`/dispatch` ne refait pas l'audit Phase 0 — c'est l'invocateur qui a déjà fait ça.** Mais avant de lancer N agents, vérifier 4 choses :

| Vérif | Si NON → |
|-------|---------|
| Liste de tâches reçue avec format clair (GAP-XXX + fichier + quoi ajouter + style) ? | STOP, demander à l'invocateur de formaliser |
| Tâches marquées GO (pas PENDING ni SKIP) ? | STOP, dispatcher uniquement les GO |
| Files différents pour chaque tâche (ou séquentiel explicitement marqué) ? | Réordonner : tâches même fichier = séquentiel |
| Pas de tâche qui implique modifier de la logique existante ? | STOP, refuser cette tâche, demander basculement sur Opus direct |

Si le sanity check échoue → bloquer, ne pas lancer, retourner à l'invocateur avec le problème.

---

## Les 5 règles non-négociables — à inclure dans CHAQUE prompt agent Sonnet

### R1 — Additif uniquement
Ne JAMAIS supprimer ou modifier du code existant. Ajouter une entrée OK. Modifier/supprimer/renommer/refactoriser INTERDIT.

### R2 — Lire avant de toucher
TOUJOURS lire le fichier (ou la section) avant d'éditer. Vérifier l'absence de doublon. Respecter le style.

### R3 — Scope maximal : 1 fichier, 1 endroit
Un agent = une modification dans un fichier. Si l'agent pense devoir toucher un 3e fichier → STOP, demander d'abord.

### R4 — Tests obligatoires
Lancer `cd <projet> && python -m pytest test_speakapp.py -x -q 2>&1 | tail -5` après chaque modif. Si KO → `git checkout -- <fichier>`. Pas de commit si test cassé.

### R5 — Commit atomique
Un commit = une tâche. Format : `fix(plateforme): [GAP-XXX] description courte`.

---

## Template de prompt sub-agent (court)

```
Tu es un agent Sonnet en mode ultra-conservateur. UNE seule modification. C'est tout.

══════════════════════════════════════════════
RÈGLES — LIS-LES EN PREMIER, AVANT TOUT
══════════════════════════════════════════════
R1. ADDITIF UNIQUEMENT. Ne supprime rien. Ne modifie pas. N'optimise pas. Si tu te retrouves à supprimer/changer une ligne → STOP.
R2. LIS le fichier avant d'éditer. Vérifie l'absence de doublon. Respecte le style exact.
R3. UN SEUL ENDROIT. Si tu penses devoir toucher un autre fichier → STOP, écris pourquoi, ne fais rien.
R4. TESTS après modif : `cd <chemin_projet> && python -m pytest test_speakapp.py -x -q 2>&1 | tail -3`. Si test KO → `git checkout -- <fichier>` puis STOP.
R5. DOUTE = STOP. Si pas sûr à 100% → écris ton doute, ne code pas.
══════════════════════════════════════════════

## La tâche
**Fichier :** `<chemin/vers/fichier>`
**Quoi ajouter :** <description précise>
**Où :** <fonction / ligne / section>
**Style à respecter** (copié du fichier réel) :
```
<5-10 lignes de code existant adjacent>
```

## Workflow exact
1. Lire la section autour de l'endroit indiqué
2. Vérifier que ce qu'on demande d'ajouter n'est pas déjà là
3. Faire la modification (additive, style identique)
4. Lancer les tests. Si KO → revert + STOP
5. Vérifier `git diff HEAD` — touché QUE ce qui est demandé ?
6. Commit : `git commit -m "<type(scope): [GAP-XXX] description>"`
7. Écrire dans `docs/sonnet-batch/<date>-batch-<N>.md` (format dans review-opus.md)
8. Retourner : hash commit + "batch doc écrit"
```

---

## Erreurs fréquentes à éviter

| Erreur | Conséquence | Prévention |
|--------|-------------|------------|
| Lancer `/dispatch` sans plan validé en amont | Agents Sonnet auditent eux-mêmes = mauvais résultat | Refuser, exiger plan de l'invocateur |
| Scope trop large ("améliore aussi X") dans le prompt | Régression | Prompt explicite : "QUE ce qui est demandé" |
| Pas lire avant éditer | Doublon ou style cassé | R2 explicite |
| Oublier les tests | Régression silencieuse | R4 + commande copiée dans le prompt |
| 2 agents sur même fichier en parallèle | Conflit git | Sanity check Phase 1 → séquentiel |
| "Pendant qu'on y est" | Code non voulu | R1 + STOP si touche autre chose |

---

## Documents compagnons

- **`examples.md`** — 3 exemples concrets de tâches SpeakApp + anti-exemples
- **`prompt-relance.md`** — prompt long pour le cas rare où Florent invoque `/dispatch` directement avec un brief macro (Phase 0 audit incluse à titre exceptionnel)
- **`review-opus.md`** — détail de l'étape review finale (format batch doc + prompt reviewer)

---

## Auto-amélioration

Après chaque batch :
1. Un agent a fait de la merde malgré le prompt → ajouter dans "Erreurs fréquentes"
2. Une règle insuffisante → la renforcer
3. Pattern de tâche bien adapté → ajouter dans `examples.md`
4. L'invocateur a fait un mauvais audit (tâche listée GO mais en fait PENDING/SKIP) → remonter à l'invocateur (`/drive` ou `/dev-orchestrator`) pour renforcer son audit
