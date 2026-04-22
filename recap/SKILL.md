---
name: recap
description: Recap instantane de la session en cours, en langage humain pour Florent (qui n'est pas dev). Invoquer quand Florent dit "/recap", "fais-moi un recap", "resume ce qu'on a fait", "fais le point", "bilan", "on fait le point". Pas de commit, pas de push, pas de KB — juste le recap propre de ce qui a ete fait dans la session en cours.
trigger: user-invocable — /recap
scope: global — tout projet
---

# /recap — Recap propre de la session en cours

**But** : repondre a "fais-moi un recap" en 30 secondes, en langage humain, sans jargon, sans code, sans hash.

Ce skill ne fait QUE le recap. Il ne commite pas, ne push pas, ne touche pas la KB, n'ecrit pas de handoff. **Juste un message clair dans le chat.**

---

## Regle absolue — perimetre = LA session active

Le recap couvre **uniquement ce qui a ete fait dans cette conversation**. Pas de roadmap, pas de backlog, pas de chantier evoque en aparte. Si Florent dit "/recap" a 5 min du demarrage, le recap est tres court — c'est normal.

**Applique aussi a la section "Ce qu'il reste a faire"** : elle contient UNIQUEMENT ce qui decoule directement de la session en cours pour boucler ce qu'on a commence (tester ce qu'on vient de coder, commiter/pousser, mettre a jour les docs qu'on a touchees). EXCLURE : chantiers ouverts du projet en general, questions produit legacy d'anciennes sessions, roadmap globale, features futures evoquees en passant. Si ca ne vient pas de CETTE conversation, ca ne va pas dans le recap. Florent perd le fil si "ce qu'il reste" melange session + app.

---

## Workflow

### Phase 1 — Relire la session entiere

**Pas juste les 5 derniers messages.** Relire tout ce qui a ete fait/dit depuis le debut de la conversation et identifier :
- Qu'est-ce que Florent avait demande au depart (son/ses intentions initiales)
- Quels sujets ont ete abordes (fusions, bugs, decisions, features)
- Pour chaque sujet : ce qui est FAIT / a moitie / pas fait
- Quelles decisions non-triviales ont ete prises seul par Claude
- Ce qui reste a faire pour boucler le sujet

### Phase 2 — Ecrire le recap

**Format obligatoire** :

```markdown
## Recap — ce qu'on a fait cette session

**Tu m'avais demande [N choses] :**
1. [demande 1 reformulee en langage simple]
2. [demande 2 reformulee]
...

**Voila ce que j'ai fait pour chaque point.**

### 1. [Titre humain de l'item 1]
[1-2 paragraphes qui expliquent ce qui a change et pourquoi, en langage simple.]

**Les choix que j'ai tranches seul :**
- **[Question en langage humain]** → J'ai choisi **[reponse]**. [Phrase sur la raison : ce que ca evite / ce que ca gagne.]

### 2. [Titre humain de l'item 2]
...

### Ce qu'il reste a faire
- [action suivante en 1 phrase simple]
- [...]

---
**Annexe technique** (ignorable) : commits, fichiers modifies, IDs. Regroupe a la fin si vraiment utile.
```

---

## 7 regles de forme (obligatoires)

1. **Vraies phrases, pas de liste a puces seche**
   - BON : "J'ai fusionne Chat Reader et Lecture Chat & Docs parce que c'est la meme feature, juste un scope etendu pour les documents attaches."
   - MAUVAIS : "- Fusion CR+LCD OK / - CLAUDE.md §1 updated / - matrix updated"

2. **Zero jargon technique sans traduction**
   - "commit" → "sauvegarde"
   - "cron" → "tache programmee qui tourne a [heure]"
   - "rebase" → "synchroniser avec la derniere version"
   - "feature doc" → "le document qui decrit la fonctionnalite"
   - "matrice" → "le tableau de reference qui..."
   - "gate" / "pipeline" / "dispatcher" → traduire ou expliquer

3. **Pas de chemin fichier, pas de hash, pas de code dans le corps**
   - Si necessaire pour tracabilite → bloc "Annexe technique" a la fin, explicitement ignorable
   - Dans le corps, parler des **effets**, pas des fichiers

4. **Expliquer les choix non-triviaux**
   - Chaque decision tranchee seule = 1 phrase sur le choix + 1 phrase sur **pourquoi**
   - Florent doit pouvoir dire "ok j'aurais fait pareil" ou "non, reviens en arriere"

5. **Longueur = ce qu'il faut pour etre clair**
   - Pas de plafond artificiel a 100 mots
   - Un recap clair de 500 mots >> un recap compact illisible de 80 mots
   - Mais pas de blabla : chaque phrase apporte quelque chose

6. **Structure narrative**
   - Introduction : ce que Florent avait demande
   - Developpement : un paragraphe par item
   - Conclusion : ce qui reste (si quelque chose reste)

7. **"Ce qu'il reste a faire" = session seulement, jamais projet**
   - Inclure : tester ce qu'on vient de coder, commiter/pousser, mettre a jour les docs qu'on a touchees dans la session
   - Exclure : questions produit legacy d'anciennes sessions, chantiers ouverts du projet, roadmap globale, V2 evoquee en passant
   - Filtre mental : "est-ce que cette action decoule de CETTE conversation ?" → si non, elle n'a rien a faire dans le recap
   - Pour les chantiers projet : c'est `memory/roadmap/roadmap.md` ou le backlog qui les suit, pas le recap

---

## Test de relecture — AVANT d'envoyer

Relire le recap et se poser la question :

> "Si Florent relit ce recap dans 2 semaines sans avoir le contexte de la session, comprend-il :
> (a) ce qui a change dans son projet ?
> (b) pourquoi Claude a choisi X plutot que Y sur les decisions importantes ?
> (c) ce qu'il reste a faire ?"

**Si non a l'une des 3 questions → reecrire.**

---

## Anti-patterns interdits

| Interdit | Pourquoi | A la place |
|----------|----------|------------|
| Liste a puces seche "Fait : X, Y, Z" | Florent ne comprend pas le contexte | Vraies phrases avec la raison |
| Chemins de fichiers dans le corps | Florent n'est pas dev, s'en fiche | Parler des effets, annexe technique a la fin |
| Commits hash en premiere lecture | Bruit, illisible | Annexe technique si necessaire |
| Decisions listees sans "pourquoi" | Florent ne peut pas juger a posteriori | 1 phrase raison a chaque choix |
| Plafond artificiel 100 mots | Force la compression illisible | Aussi long que necessaire, pas plus |
| Recap du dernier item seul | 3 autres sujets ont ete evoques aussi | Scanner TOUTE la session |
| Blabla "j'ai fait plein de trucs" | Vide | Concret, item par item |
| "Voici un resume technique detaille..." | Florent n'est pas dev | Langage humain |
| "Ce qu'il reste" qui melange session + chantiers projet | Florent perd le fil | Scoper strict session ; chantiers projet → roadmap, pas recap |

---

## Cas particuliers

### Session tres courte (< 5 echanges)

Recap tres bref OK, mais garde la structure :
```
## Recap

**Tu m'avais demande** [1 phrase].

**Voila ce que j'ai fait** : [1-2 paragraphes clairs].

**Ce qui reste** : [rien | 1 ligne].
```

### Session qui a pivote plusieurs fois

Mentionner les pivots explicitement dans l'intro :
```
**Tu m'avais demande X, puis on a pivote vers Y, puis Z.**

Voila ce qu'il reste de cette session...
```

### Rien de concret fait (exploration, brainstorm)

Dire explicitement :
```
## Recap

Session d'exploration — rien n'a ete code/modifie, mais on a clarifie :
- [decision 1]
- [decision 2]

**Prochaine etape** : [action concrete qui ressort de l'exploration].
```

---

## Ce que `/recap` NE fait PAS

- ❌ Pas de commit, pas de push
- ❌ Pas d'ecriture dans handoff.md ou roadmap
- ❌ Pas de push vers NotebookLM (c'est `/wrapup` qui fait ca)
- ❌ Pas de memoires sauvees (c'est `/wrapup`)
- ❌ Pas d'action sur les fichiers du projet

`/recap` = **uniquement un message dans le chat**. Si Florent veut finaliser/sauvegarder, il invoquera `/drive` ou `/wrapup` separement.

---

## Difference avec les skills voisins

| Skill | Objectif | Actions |
|-------|----------|---------|
| `/recap` | Recap instantane dans le chat | Juste un message |
| `/drive` | Finir les sujets de la session a 100% | Code + commit + handoff + recap final |
| `/wrapup` | Fin de session longue avec sauvegarde KB | Memoires + NotebookLM + recap |
| `/autopilot` | Lancer un nouvel objectif en background | Tache parallele |

Si Florent dit "fais le point", "bilan", "recap", "resume" → `/recap`.
Si Florent dit "finis", "boucle", "va au bout" → `/drive`.
Si Florent dit "sauvegarde la session", "end of session" → `/wrapup`.
