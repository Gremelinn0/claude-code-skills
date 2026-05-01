# Sonnet Agents — Review Opus finale

Détail de l'étape de review obligatoire après que tous les agents Sonnet ont fini.

## Pourquoi une review Opus

Sonnet peut avoir :
- Ajouté du code au bon endroit mais avec un bug subtil
- Suivi le style superficiellement mais raté une convention importante
- Introduit une régression que les tests unitaires ne couvrent pas
- Fait quelque chose de "techniquement correct" mais architecturalement mauvais

Opus relit avec plus de contexte et juge si le code est sain.

## Ce que chaque agent Sonnet doit écrire (avant la review)

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

## Comment lancer la review

Utiliser le sous-agent pré-configuré **`feature-dev:code-reviewer`** (déjà orienté review, confidence-based filtering — ne remonte que les problèmes qui comptent vraiment). Pas besoin de Opus brut.

```
Agent({
  description: "Review sonnet batch",
  subagent_type: "feature-dev:code-reviewer",
  prompt: <le prompt ci-dessous>
})
```

## Le prompt de review

```
Tu es un reviewer senior. Des agents Sonnet ont effectué des micro-modifications sur la codebase <your-project>.
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

## Emplacement du fichier batch

```
<projet>/docs/sonnet-batch/
    2026-04-15-batch-1.md   ← tous les agents du même jour/batch
    2026-04-16-batch-1.md
    ...
```

Un fichier par batch (une session de dispatch). Plusieurs GAPs dans le même fichier.

## Auto-amélioration

Après chaque batch + review :
1. Un agent a fait de la merde malgré le prompt ? → ajouter l'erreur dans `SKILL.md` "Erreurs fréquentes"
2. Une règle s'est révélée insuffisante ? → la renforcer dans `SKILL.md`
3. Un pattern de tâche bien adapté à Sonnet ? → l'ajouter dans `examples.md`
