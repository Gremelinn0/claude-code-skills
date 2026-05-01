# Skill — /plan

## Ce que fait ce skill

Quand l'utilisateur tape `/plan` :
1. Lire le fichier PLAN_XXX.md du projet courant
2. Identifier ce qui reste à faire (pas encore ✅)
3. Réécrire la section "ce qui reste" de façon ultra-synthétique — tableau court, une ligne par tâche, zéro blabla
4. Sauvegarder dans le fichier
5. **Push Notion** — pour chaque tâche manuelle (Qui = l'utilisateur), créer ou mettre à jour une tâche dans la DB Tâches Notion (`collection://26501e69-443c-8116-b237-000bdc32b867`), liée au projet concerné. Statut = "À faire". Comme ça l'utilisateur les voit dans son dashboard sans ouvrir le fichier.

## Règles

- **Ultra-synthétique** : une ligne par tâche, pas de colonne "Notes" longue
- **Indiquer qui fait quoi** : l'utilisateur / Claude / Bug bloquant

### Règle de validation — NE PAS SE TROMPER

| Statut | Condition | Marquage |
|--------|-----------|----------|
| ✅ Fait | Testé, confirmé, terminé en vrai | Déplacer dans section "Fait" |
| 🔄 En cours | Commencé mais pas terminé | Garder dans "Ce qui reste" avec note |
| ⚠️ Bloqué | Impossible à faire pour l'instant (bug, dépendance externe) | Garder avec la raison |
| ❌ À faire | Pas encore commencé | Garder |

**Interdits formels :**
- Marquer ✅ une tâche parce qu'on en a parlé — parler ≠ faire
- Marquer ✅ une tâche partiellement faite
- Supprimer une tâche parce qu'elle semble passée ou oubliée — si pas confirmé = reste dans le plan
- En cas de doute sur le statut → garder "À faire" plutôt que marquer fait

**Pas de recap dans le chat** — juste confirmer "Plan mis à jour" + afficher le tableau résultant

## Format de sortie dans le fichier

```
## Ce qui reste

| # | Tâche | Qui | Notes |
|---|-------|-----|-------|
| 1 | ... | l'utilisateur | ... |
| 2 | ... | Claude sur go | ... |
```

## Quel fichier PLAN cibler ?

- Si on est dans le dossier `YouTube Channel/` → `PLAN_YOUTUBE.md`
- Si on est dans `LinkedIn Content Agent/` → fichier plan LinkedIn
- Sinon → chercher le fichier `PLAN_*.md` dans le dossier du projet courant
