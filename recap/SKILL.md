---
name: recap
description: Recap COURT du sujet en cours uniquement (PB + fix/etat en quelques lignes). Pas un bilan de toute la session. Toujours commencer par UNE phrase decrivant le PB qu'on cherche a resoudre. Invoquer quand Florent dit "/recap", "fais-moi un recap", "resume", "fais le point", "bilan", "on fait le point", "ou on en est". Pour bilan COMPLET de toute la session item par item, utiliser /recap-full. Pas de commit, pas de push, pas de KB — juste un message clair dans le chat.
trigger: user-invocable — /recap
scope: global — tout projet
---

# /recap — Recap court du sujet en cours

**But** : repondre a "fais-moi un recap" en 30 secondes sur LE SUJET EN COURS uniquement, en langage humain, sans jargon, sans code, sans hash.

Ce skill ne fait QUE le recap. Il ne commite pas, ne push pas, ne touche pas la KB, n'ecrit pas de handoff. **Juste un message clair dans le chat.**

---

## Regle 1 — perimetre = sujet(s) en cours, pas toute la session

Le `/recap` couvre **uniquement le ou les sujets encore ouverts au moment de la demande**. Pas un bilan de toute la conversation. Pas un journal des items deja boucles depuis le debut.

- Si la session a 5 sujets dont 4 sont fermes et 1 en cours → recap = uniquement le 1 en cours
- Si 2 sujets sont en cours en parallele → recap les 2 brievement
- Si tout est ferme → 1 ligne "tout est livre, rien d'ouvert" + sujet le plus recent en rappel

**Pour le bilan complet de toute la session item par item → c'est `/recap-full`.** Si Florent veut explicitement le bilan total, il invoquera `/recap-full`.

---

## Regle 2 — TOUJOURS commencer par UNE phrase sur le PB qu'on cherche a resoudre

**Non-negociable.** Premiere ligne du recap = phrase qui dit clairement ce qu'on essaie de resoudre. Comme ca Florent retrouve le contexte instantanement meme s'il revient apres 3 jours.

Format : `**Le problème** : [1 phrase, langage humain, pas jargon]`.

Exemples bons :
- "Quand l'auto-collage de la dictée échoue, le toast disait 'Texte copié' mais le presse-papier était vide → Ctrl+V collait rien."
- "Le clic auto sur le bouton 'Allow' d'AntiGravity tournait en boucle même quand le dialog avait disparu, spammant des fausses validations."
- "Florent voulait un bilan visuel des dictées rapides accessible en 1 clic depuis l'app."

Exemples interdits :
- "Bug `_copy_to_clipboard` BP-186 fix tkinter clipboard volatile" → jargon, hash, illisible
- "Refactor de la fonction" → vide, pas le PB

---

## Format obligatoire du recap court

```markdown
## Recap court — [titre du sujet en 4-6 mots]

**Le problème** : [1 phrase sur ce qu'on cherche a resoudre, langage humain]

**Le fix (ou l'etat actuel)** : [1-2 paragraphes simples sur ce qu'on a fait pour le resoudre, OU ou on en est si pas fini, en langage humain]

**Statut** : [livre + push / en cours / test pending / bloque sur X]
```

Si plusieurs sujets en cours, repeter le bloc pour chaque sujet (max 2-3 sujets ; au-dela proposer `/recap-full`).

---

## 7 regles de forme (obligatoires)

1. **PB = phrase 1 obligatoire** — Florent doit comprendre le contexte sans rien deviner.
2. **Vraies phrases, pas de liste a puces seche.**
3. **Zero jargon technique sans traduction** : "commit" → "sauvegarde", "tkinter" → "la lib graphique de l'app", "CF_UNICODETEXT" → "le format texte standard Windows", "rebase" → "synchroniser avec la derniere version", etc.
4. **Pas de chemin fichier, pas de hash, pas de code dans le corps.**
5. **Court** — 8-15 lignes max. Si tu vises 30 lignes c'est `/recap-full`.
6. **Statut explicite a la fin** — Florent sait s'il doit attendre / tester / oublier.
7. **Une decision tranchee non-triviale = 1 phrase qui explique pourquoi.** Sinon Florent ne peut pas dire "ok" ou "non, reviens".

---

## Test de relecture — AVANT d'envoyer

Florent relit ce recap dans 2 jours sans avoir le contexte. Comprend-il :
(a) **le PB** qu'on cherchait a resoudre ?
(b) **ce qui a change** dans son projet (ou ou on en est) ?
(c) **ce qu'il doit faire** (rien / tester / valider / autre) ?

Si non a l'une des 3 → reecrire.

---

## Anti-patterns interdits

| Interdit | Pourquoi | A la place |
|----------|----------|------------|
| Pas de phrase PB en intro | Florent perd le fil sans contexte | Phrase 1 toujours = "**Le problème** : ..." |
| Recap de toute la session | C'est le boulot de `/recap-full` | Sujet en cours uniquement |
| Liste a puces seche | Florent ne comprend pas le pourquoi | Vraies phrases avec raison |
| Chemins fichiers / hash dans le corps | Bruit, illisible | Annexe technique a la fin si vraiment utile |
| Jargon technique non traduit | Florent n'est pas dev | Traduction systematique |
| > 20 lignes | Pas un recap court, c'est `/recap-full` | Compresser ou rediriger vers /recap-full |
| Pas de statut a la fin | Florent ne sait pas quoi faire ensuite | Statut explicite obligatoire |

---

## Cas particuliers

### Aucun sujet en cours (tout est ferme)

```
## Recap court

**Le problème** : tout est livre et boucle pour le moment.

Dernier chantier ferme : [nom court du sujet] — [statut].

**Prochain pas** : aucun en attente. Dis-moi sur quoi tu veux bosser.
```

### Sujet bloque sur Florent (test live, decision produit)

```
## Recap court — [sujet]

**Le problème** : [phrase].

**Le fix (livre)** : [paragraphe court].

**Statut** : code livre + pousse. **En attente de toi** : [test live a faire / decision a prendre / valider X].
```

### Plusieurs sujets en cours

```
## Recap court — 2 sujets en cours

### 1. [Sujet A]
**Le problème** : ...
**Etat** : ...

### 2. [Sujet B]
**Le problème** : ...
**Etat** : ...
```

Si > 3 sujets : proposer `/recap-full` au lieu de tasser dans `/recap`.

---

## Ce que `/recap` NE fait PAS

- ❌ Pas de commit, pas de push
- ❌ Pas d'ecriture dans handoff.md ou roadmap
- ❌ Pas de push vers NotebookLM (c'est `/wrapup`)
- ❌ Pas de memoires sauvees (c'est `/wrapup`)
- ❌ Pas d'action sur les fichiers du projet
- ❌ **Pas de recap de toute la session** (c'est `/recap-full`)

`/recap` = **un message court dans le chat sur le sujet en cours**.

---

## Difference avec les skills voisins

| Skill | Objectif | Longueur | Quand |
|-------|----------|----------|-------|
| `/recap` | Sujet en cours uniquement, PB + fix | 8-15 lignes | "fais-moi un recap", "ou on en est" |
| `/recap-full` | Toute la session item par item | aussi long que necessaire | "bilan complet", "recap toute la session" |
| `/drive` | Finir les sujets a 100% | action, pas message | "finis ca", "boucle" |
| `/wrapup` | Fin de session + sauvegarde KB | action + recap | "wrap up", "end of session" |

Si Florent dit "fais le point", "bilan", "recap", "resume", "ou on en est" → `/recap` (court, sujet en cours).
Si Florent dit "bilan complet", "recap toute la session", "fais-moi le point detaille" → `/recap-full`.
Si Florent dit "finis", "boucle", "va au bout" → `/drive`.
Si Florent dit "sauvegarde la session", "end of session" → `/wrapup`.
