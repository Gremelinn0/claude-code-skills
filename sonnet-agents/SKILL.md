---
name: sonnet-agents
description: Dispatch Sonnet agents safely for small, additive tasks. Ultra-conservative mode — no regressions, no rewrites, additive only. Use when you have 2-8 micro-tasks that are independent and scoped to a single function or selector.
---

# Sonnet Agents — Micro-tâches en mode ultra-conservateur

## Pipeline complet (vue d'ensemble)

```
┌──────────────────────────────────────────────────────────────┐
│ [Avant — toi, une fois]                                      │
│   Liste des tâches candidates dans le prompt de relance      │
│   (extrait de la roadmap, pré-mâché)                         │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Session autonome — Sonnet fait TOUT                          │
│                                                              │
│  Phase 0a : Filtre rapide (Grep/Read ciblés)                 │
│    → SKIP si déjà implémenté                                 │
│    → GO si ligne exacte trouvée + modif évidente             │
│    → PENDING si sélecteur non confirmé ou ambiguïté          │
│                                                              │
│  Phase 0b : Investigation PENDING                            │
│    → code-explorer × N en parallèle (model="sonnet")        │
│    → chaque explorer : fichier:ligne + GO/SKIP confirmé      │
│                                                              │
│  Phase 1 : Exécution des GO en parallèle                     │
│    → 1 sous-agent Sonnet par tâche GO                        │
│    → fichiers différents = parallèle                         │
│    → même fichier = séquentiel                               │
│    → chaque agent : modif + tests + commit + batch doc       │
│                                                              │
│  Phase 2 : Écrire le bilan dans docs/sonnet-batch/*.md       │
│    → GO cochés avec hash commit                              │
│    → PENDING/SKIP avec raison courte                         │
│    → Push                                                    │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Review finale — code-reviewer (Opus)                         │
│   • Lit le fichier batch + vérifie chaque diff en contexte   │
│   • Verdict : ✅ OK / ⚠️ fix mineur / ❌ revert                 │
│   • Résumé lisible pour toi                                  │
└──────────────────────────────────────────────────────────────┘
```

**Comment ça marche techniquement :**

- La session autonome = Sonnet (le modèle actif dans la session)
- Sonnet dispatche des sous-agents via `Agent(...)` — chacun tourne dans un contexte frais
- `code-explorer` : `Agent(subagent_type="feature-dev:code-explorer", model="sonnet")` — investigation, zéro modif
- sous-agents exécuteurs : `Agent(model="sonnet")` — UNE modif additive chacun
- review finale : `Agent(subagent_type="feature-dev:code-reviewer", model="opus")` — Opus lit, pas Opus qui orchestre

**Opus n'est pas dans la boucle d'exécution.** Il apparaît seulement à la review finale, comme un relecteur externe.

**Principes de légèreté :**
- **Pas de TDD** sur micro-tâches (juste lancer les tests existants)
- **Pas de `subagent-driven-development`** (trop lourd — double review par tâche)
- **Pas de TodoWrite** dans les agents Sonnet (une seule tâche chacun)
- **Contexte externalisé** : rapport batch = fichier, pas conversation
- **Un seul round de review** : pas de boucle infinie
- **Max 6-8 tâches GO** par batch

---

## Pourquoi ce skill

Sonnet est moins fiable qu'Opus pour des tâches complexes. Si tu lui donnes trop de liberté, il va :
- Refactoriser du code qui marchait
- Supprimer des lignes "inutiles" qui ne l'étaient pas
- Introduire des bugs silencieux dans du code adjacent
- Interpréter la demande de manière créative

Ce skill force un cadre **chirurgical** : chaque agent fait UNE chose, lit avant de toucher, ne supprime rien, et vérifie que les tests passent encore.

## Quand utiliser ce skill

✅ Utiliser quand :
- Tu as 2-8 micro-tâches indépendantes (30 min chacune)
- Chaque tâche = ajouter un sélecteur, une constante, un préfixe, un mapping
- Aucune tâche ne nécessite de comprendre la logique globale du système
- Les tâches ne touchent pas les mêmes fichiers

❌ Ne pas utiliser si :
- La tâche nécessite de comprendre le flux complet d'une feature
- La tâche implique modifier une logique existante (pas juste ajouter)
- La tâche nécessite un test live (CD, AG, Chrome) — Sonnet ne peut pas faire ça
- Tu n'es pas sûr de ce que la tâche implique exactement

---

## Les 5 règles non-négociables pour un agent Sonnet

Ces règles s'appliquent à CHAQUE agent lancé avec ce skill. Les inclure dans le prompt.

### RÈGLE 1 — Additif uniquement
**Ne JAMAIS supprimer ou modifier du code existant.**
- Ajouter une entrée dans un dict → OK
- Ajouter un sélecteur dans une liste → OK
- Modifier un sélecteur existant → INTERDIT
- Supprimer une entrée "obsolète" → INTERDIT
- Renommer une variable → INTERDIT
- Refactoriser "pendant qu'on y est" → INTERDIT

### RÈGLE 2 — Lire avant de toucher
**TOUJOURS lire le fichier entier (ou la section concernée) avant d'éditer.**
- Voir exactement le contexte autour de ce qu'on ajoute
- Vérifier que ce qu'on ajoute n'existe pas déjà
- Comprendre le style du code (guillemets, indentation, nommage)

### RÈGLE 3 — Scope maximal : 1 fichier, 1 endroit
**Un agent = une modification dans un fichier.**
- Si la tâche implique 2 fichiers → décrire les 2 dans le prompt et accepter qu'il édite les 2
- Si la tâche implique 2 endroits distincts dans le même fichier → OK
- Si l'agent pense devoir toucher un 3e fichier "pour que ça marche" → STOP, demander d'abord

### RÈGLE 4 — Tests obligatoires
**TOUJOURS lancer les tests existants après chaque modification.**
- Commande : `cd <projet> && python -m pytest test_speakapp.py -x -q 2>&1 | tail -5`
- Si un test casse → revenir à l'état d'avant (git diff puis git checkout -- <fichier>)
- Ne JAMAIS commit si un test qui passait avant ne passe plus

### RÈGLE 5 — Commit atomique et descriptif
**Un commit = une tâche.**
- Message format : `fix(plateforme): [GAP-XXX] description courte en anglais`
- Le message doit dire CE QUI A ÉTÉ AJOUTÉ, pas juste "fix"
- Ne JAMAIS grouper plusieurs tâches dans un commit

---

## Template de prompt pour un agent Sonnet

Ces règles sont dans CHAQUE prompt sub-agent — pas seulement dans le skill.
L'agent ne peut pas les "oublier" : elles sont devant lui à chaque appel.

```
Tu es un agent Sonnet en mode ultra-conservateur. UNE seule modification. C'est tout.

══════════════════════════════════════════════
RÈGLES — LIS-LES EN PREMIER, AVANT TOUT
══════════════════════════════════════════════
R1. ADDITIF UNIQUEMENT. Ne supprime rien. Ne modifie pas de code existant. N'optimise pas.
    Si tu te retrouves à supprimer ou changer une ligne existante → STOP. Tu as mal compris la tâche.
R2. LIS le fichier avant d'éditer. Vérifie que ça n'existe pas déjà. Respecte le style exact.
R3. UN SEUL ENDROIT. Si tu penses devoir toucher un autre fichier → STOP, écris pourquoi, ne fais rien.
R4. TESTS après modif : `cd <chemin_projet> && python -m pytest test_speakapp.py -x -q 2>&1 | tail -3`
    Si un test casse → `git checkout -- <fichier>` immédiatement, puis STOP.
R5. DOUTE = STOP. Si tu n'es pas sûr à 100% → écris ton doute dans le rapport, ne code pas.
══════════════════════════════════════════════

## La tâche

**Fichier :** `<chemin/vers/fichier>`
**Quoi ajouter :** <description précise — une entrée, un sélecteur, une string>
**Où :** <fonction / ligne / section>
**Style à respecter** (copié du fichier réel) :
```
<coller 5-10 lignes de code existant adjacent>
```

## Ce que tu dois faire — dans cet ordre exact

1. Lire la section du fichier autour de l'endroit indiqué
2. Vérifier que ce qu'on te demande d'ajouter n'est pas déjà là
3. Faire la modification (additive, style identique)
4. Lancer les tests. Si KO → revert + STOP.
5. Vérifier le diff : `git diff HEAD` — est-ce que tu n'as touché QUE ce qui était demandé ?
   Si le diff contient autre chose → `git checkout -- <fichier>` et STOP.
6. Commit : `git commit -m "<type(scope): [GAP-XXX] description courte>"`
7. Écrire dans `docs/sonnet-batch/<YYYY-MM-DD>-batch-<N>.md` :

---
## [GAP-XXX] — <titre>
**Fichier :** `<chemin>`  **Commit :** `<hash>`
**Diff :**
```diff
<git diff HEAD~1 -- <fichier>>
```
**Tests avant / après :** `<N> passed` / `<N> passed`
**Ce que j'ai ajouté :** <1 phrase>
**Lignes existantes modifiées ou supprimées :** aucune / <si oui : PROBLÈME>
**Doutes :** <RAS ou description>
---

8. Retourner : hash commit + "batch doc écrit"
```

---

## Workflow de dispatch (orchestrateur)

### Phase 0 — Audit avant dispatch (OBLIGATOIRE)

**Lire le code de chaque tâche candidate AVANT de décider si on dispatch.**

Pour chaque tâche, appliquer ce filtre en 4 questions. Une réponse NON = tâche PENDING ou SKIP.

| Question | Si NON → |
|----------|----------|
| **1. C'est pas déjà fait ?** Chercher dans le code si la feature est présente | SKIP — fermer le GAP dans roadmap |
| **2. Le sélecteur/endroit est-il confirmé par le code ?** (pas inventé, pas "probable") | PENDING — besoin snapshot DOM live ou investigation |
| **3. La modification est-elle 100% additive ?** (pas de réécriture, pas de suppression) | PENDING — reformuler ou investiguer |
| **4. Le fichier est-il libre ?** (pas utilisé par une autre tâche GO du même batch) | SÉQUENTIEL — lancer après l'autre agent sur ce fichier |

**Causes de SKIP les plus fréquentes :**
- Feature déjà implémentée (string déjà là, sélecteur déjà là)
- GAP formulé vaguement dans la roadmap — la réalité du code diffère

**Causes de PENDING les plus fréquentes :**
- Besoin d'un snapshot DOM live pour confirmer le sélecteur
- Pas clair où exactement dans le fichier ajouter (la fonction exacte est ambiguë)
- La "modification" implique en réalité de la logique, pas juste une valeur

**Format du bilan Phase 0 (présenter à l'utilisateur avant de continuer) :**
```
GO     : GAP-X — raison (fichier:ligne) — "ajouter Y à côté de Z"
GO     : GAP-Y — raison (fichier:ligne) — "ajouter W à côté de V"
PENDING: GAP-Z — besoin snapshot DOM live du popup Routines
PENDING: GAP-W — formulation roadmap ambiguë, vérifier intention
SKIP   : GAP-V — déjà implémenté (app.py:14799 "Question : ")
```
→ Attendre validation utilisateur avant de passer à Phase 1.

### Phase 1 — Préparer chaque prompt GO

Pour chaque tâche :
1. Lire le fichier concerné (Grep ou Read)
2. Trouver la section exacte → copier 5-10 lignes de contexte
3. Remplir le template ci-dessus avec ce contexte
4. Vérifier le nombre de tests actuels : `python -m pytest test_speakapp.py -q 2>&1 | tail -1`

### 3. Lancer en parallèle

```
Agent 1 → Tâche A (fichier X)
Agent 2 → Tâche B (fichier Y)
Agent 3 → Tâche C (fichier Z)
```

⚠️ Ne JAMAIS lancer 2 agents sur le même fichier en parallèle → conflit git.

### 4. Review du résultat

Pour chaque agent qui revient :
- Vérifier le diff : est-ce que c'est bien ADDITIF uniquement ?
- Vérifier le résultat des tests : même nombre de tests ?
- Si un agent a touché plus que prévu → `git revert <commit>` et refaire avec un scope plus strict

---

## Erreurs fréquentes à éviter

| Erreur | Conséquence | Prévention |
|--------|-------------|------------|
| Scope trop large ("améliore aussi X") | Régression possible | Prompt explicite : "ne fais QUE ce qui est demandé" |
| Pas lire avant d'éditer | Doublon ou style cassé | RÈGLE 2 explicite dans le prompt |
| Oublier de lancer les tests | Régression silencieuse | RÈGLE 4 + commande copiée dans le prompt |
| 2 agents sur le même fichier | Conflit git | Vérifier les fichiers avant de dispatcher |
| "Pendant qu'on y est" | Code non voulu | RÈGLE 1 + "STOP si tu penses devoir toucher autre chose" |

---

## Étape finale — Review Opus

Après que tous les agents Sonnet ont fini et commité, une review Opus est obligatoire.

### Pourquoi

Sonnet peut avoir :
- Ajouté du code au bon endroit mais avec un bug subtil
- Suivi le style superficiellement mais raté une convention importante
- Introduit une régression que les tests unitaires ne couvrent pas
- Fait quelque chose de "techniquement correct" mais architecturalement mauvais

### Ce que chaque agent Sonnet doit écrire

À la fin de son travail, chaque agent Sonnet écrit dans un fichier partagé `docs/sonnet-batch/YYYY-MM-DD-batch-N.md` (créer si absent). Format :

```markdown
## [GAP-XXX] — <description courte>

**Fichier modifié :** `chemin/vers/fichier.py`
**Commit :** `<hash>`

**Diff exact :**
```
<coller le git diff de la modification>
```

**Tests avant :** `<N> passed`
**Tests après :** `<N> passed`

**Ce que j'ai ajouté :**
<1-2 phrases : quoi, où, pourquoi c'est correct>

**Ce dont je n'étais pas sûr :**
<toute hésitation, alternative écartée, hypothèse faite — ou "RAS" si tout était clair>
```

**L'agent Sonnet doit être honnête sur ses doutes.** Si il n'était pas sûr d'un choix, il l'écrit. C'est l'input le plus utile pour Opus.

### Comment lancer la review

Utiliser le sous-agent pré-configuré **`feature-dev:code-reviewer`** (déjà orienté review, confidence-based filtering — ne remonte que les problèmes qui comptent vraiment). Pas besoin de Opus brut.

```
Agent({
  description: "Review sonnet batch",
  subagent_type: "feature-dev:code-reviewer",
  prompt: <le prompt ci-dessous>
})
```

### Le prompt de review

```
Tu es un reviewer senior. Des agents Sonnet ont effectué des micro-modifications sur la codebase SpeakApp.
Chaque modification est documentée dans `docs/sonnet-batch/<fichier>.md`.

Lis ce fichier, puis pour CHAQUE modification :

1. Lis le diff
2. Lis le fichier concerné autour de la modification (5-10 lignes de contexte)
3. Évalue :
   - Le code ajouté est-il correct syntaxiquement et sémantiquement ?
   - Respecte-t-il le style et les conventions du fichier ?
   - Y a-t-il un bug potentiel même si les tests passent ?
   - L'agent a-t-il fait UNIQUEMENT ce qui était demandé (pas de créativité non voulue) ?
   - Les doutes signalés par l'agent sont-ils justifiés ? La réponse est-elle correcte ?

Pour chaque modification, rends un verdict :
- ✅ OK — rien à corriger
- ⚠️ ATTENTION — problème mineur, voici le fix
- ❌ REVERT — problème sérieux, voici pourquoi + `git revert <hash>`

Si tu trouves un ❌ ou ⚠️, fais le fix toi-même dans la foulée (additif ou correction minimale).
À la fin, résume : N ok / N attention fixés / N reverts.
```

### Emplacement du fichier batch

```
<projet>/docs/sonnet-batch/
    2026-04-15-batch-1.md   ← tous les agents du même jour/batch
    2026-04-16-batch-1.md
    ...
```

Un fichier par batch (une session de dispatch). Plusieurs GAPs dans le même fichier.

---

## Exemple concret : 3 agents pour SpeakApp

### Tâche 1 : `GAP-CLCHAT-03` — Dismiss popup Routines sur claude.ai/chat
```
Fichier : wisper-bridge/content_scripts/detector.js
Ajouter : détection + clic sur button[text="Compris"] dans le popup Routines
Style à suivre : chercher "dismiss" ou "popup" dans le fichier pour voir comment c'est déjà fait
```

### Tâche 2 : `GAP-CLCODE-05` — Prefix `[Plan] :` avant lecture TTS
```
Fichier : app.py
Ajouter : prefix "[Plan] : " dans la fonction qui lit les plans TTS
Style : chercher d'autres prefixes comme "[Question] :" pour voir le pattern
```

### Tâche 3 : `GAP-GEM-04` — Mapping modèle Gemini
```
Fichier : app.py ou detector.js
Ajouter : mapping "opus" → "2.5 Ultra", "sonnet" → "2.5 Pro", "haiku" → "2.5 Flash"
Style : chercher MODEL_MAP ou model_mapping pour voir le pattern existant
```

Ces 3 tâches touchent des fichiers différents → 3 agents en parallèle, safe.

---

## Prompt de relance (copier-coller pour démarrer une session)

```
Tu es un agent Sonnet autonome. Tu vas auditer, exécuter et documenter un batch de micro-tâches SpeakApp.
Pas d'Opus dans la boucle. Tu fais tout. À la fin, un code-reviewer Opus relit ce que tu as fait.

## Objectif
Faire le maximum de travail propre en parallèle via des agents Sonnet.
Maximum de travail = maximum de tâches GO validées, pas maximum de code écrit.

## Règle absolue — priorité #1
Zéro régression. Zéro merde.
Si tu as le moindre doute sur une tâche → PENDING, pas GO.
Tu documentes, tu analyses. Tu n'ajoutes du code QUE si tu es certain à 100%.
Un agent Sonnet qui fait une mauvaise modif coûte plus cher à réparer qu'une tâche laissée en PENDING.

## Ce que tu vas faire

### Phase 0a — Filtre rapide (toi, Grep/Read ciblés)
Pour chaque tâche candidate :
1. Grep rapide sur le mot-clé dans le fichier probable
2. Classer immédiatement : GO simple / GO complexe / PENDING / SKIP
   - SKIP : feature déjà présente dans le code
   - GO simple : ligne exacte trouvée, modification évidente (ajouter une entrée, un sélecteur)
   - GO complexe : logique à ajouter, mais où/comment n'est pas encore clair
   - PENDING : sélecteur DOM non confirmé (besoin snapshot live), ou ambiguïté totale

### Phase 0b — Investigation PENDING (code-explorer en parallèle)
Pour chaque tâche PENDING, dispatcher un `feature-dev:code-explorer` avec ce prompt type :
```
Projet : C:\Users\Administrateur\PROJECTS\3- Wisper\speak-app-dev\
Mission : Trouve où [X] est géré dans ce projet.
- Cherche dans [fichier probable]
- Retourne : fichier:ligne exact, 5 lignes de contexte, pattern utilisé
- Conclus : GO (avec le contexte exact) ou SKIP (déjà implémenté)
- NE PAS modifier de code. Investigation only.
```
Les explorers tournent en parallèle. Résultat : chaque PENDING devient GO+blueprint ou SKIP.

### Phase 1 — Préparer les prompts GO
- GO simple : coller 5-10 lignes de contexte dans le template Sonnet
- GO complexe : dispatcher un `feature-dev:code-architect` pour blueprint précis, puis coller le blueprint dans le prompt Sonnet
- Vérifier baseline : `python -m pytest test_speakapp.py -q 2>&1 | tail -1`
- Vérifier conflits : 2 tâches GO sur le même fichier → séquentiel

### Phase 2 — Dispatch Sonnet (en parallèle max)
- Lancer tous les agents GO en parallèle (sauf conflits fichier)
- Chaque agent : fait UNE modif, tests, commit, écrit rapport dans `docs/sonnet-batch/2026-04-15-batch-1.md`

### Phase 3 — Review (feature-dev:code-reviewer)
Après que TOUS les Sonnet ont terminé :
```
Lis docs/sonnet-batch/2026-04-15-batch-1.md.
Pour chaque modification : lis le diff + 10 lignes de contexte dans le fichier réel.
Verdict : ✅ OK / ⚠️ fix mineur (fais-le) / ❌ revert (git revert <hash>).
Résumé final : N ok / N fixés / N reverts.
```

### Phase 4 — Consolidation
- Appliquer fixes/reverts si nécessaire
- Update `memory/roadmap/roadmap.md` : GO cochés, PENDING/SKIP notés avec raison courte
- `git fetch origin && git rebase origin/dev && git push origin HEAD:dev`

## Tâches candidates (batch courant)
Issues identifiées dans la roadmap comme "30 min" ou "1h", P0/P1 :
- GAP-CLCHAT-03 : Dismiss popup Routines `button[text="Compris"]` — detector.js
- GAP-CLCODE-04 : Dismiss popup Routines claude.ai/code — detector.js
- GAP-CLCHAT-04 : Sélecteur Send fallback inject_message — detector.js
- GAP-CLCODE-05 : Prefix `[Plan] :` avant lecture TTS plan — app.py
- GAP-CLCODE-02 : Prefix `[Question]` concat lecture TTS — app.py
- GAP-GEM-04   : Mapping modèle Gemini (opus/sonnet/haiku → 2.5 Pro/Flash/Ultra) — detector.js
- GAP-GEM-05   : Stop button Gemini snapshot + sélecteur — detector.js
- GAP-CLCHAT-06 : Share/Retry buttons détection + sélecteurs — detector.js

> Audit déjà partiel effectué session précédente :
> - GAP-CLCODE-02 → probablement SKIP (déjà implémenté app.py:14799 `"Question : {_qtext_short}"`)
> - GAP-GEM-04 → table geminiModels existe detector.js:1449, valeurs à vérifier
> - Les GAPs CLCHAT/CLCODE-03/04 → mécanisme unknown_dialog existe, clic auto absent
> - GAP-CLCODE-05 → annonce plan trouvée app.py:14787, lecture contenu plan à localiser

## Chemin du projet
`C:\Users\Administrateur\PROJECTS\3- Wisper\speak-app-dev\`
Tests : `cd <projet> && python -m pytest test_speakapp.py -x -q 2>&1 | tail -3`
Batch doc : `docs/sonnet-batch/2026-04-15-batch-1.md` (créer si absent)

## Output attendu de ta part
1. Bilan Phase 0 (GO/PENDING/SKIP avec justification)
2. Agents Sonnet lancés en parallèle sur les tâches GO
3. Résultat du reviewer Opus
4. Roadmap mise à jour
5. Push effectué
```

---

## Auto-amélioration

Après chaque usage :
1. Un agent a fait de la merde malgré le prompt ? → ajouter l'erreur dans "Erreurs fréquentes"
2. Une règle s'est révélée insuffisante ? → la renforcer
3. Un pattern de tâche bien adapté à Sonnet ? → l'ajouter en exemple
