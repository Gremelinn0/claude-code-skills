---
name: skill-finder
description: Recherche le bon skill à utiliser pour une demande donnée. Parcourt les skills actifs (projet + global), les archives, les autres projets, puis internet si rien n'est trouvé. Triggers "quel skill pour", "tu as un skill pour", "cherche un skill", "trouve-moi le skill", "/skill-finder".
trigger: user-invocable
scope: global — tout projet
---

# /find-skill — Trouver le bon skill pour une demande

**`/find-skill <description>` prend une description libre et identifie le ou les skills les plus pertinents**, en parcourant 4 niveaux dans l'ordre : actifs (projet + global) → archives → autres projets → internet.

**Arrêter au premier niveau qui donne une correspondance directe.** Ne pas continuer au niveau suivant si une correspondance directe est trouvée. Continuer au niveau suivant uniquement si aucune correspondance directe n'est trouvée.

---

## Invocation

```
/find-skill <description de ce que tu veux faire>
```

**Exemples** :
- `/find-skill tester la dictée vocale`
- `/find-skill cherche un skill pour automatiser une permission Claude Desktop`
- `/find-skill exporter une feuille Google Sheets`
- `/find-skill health check de l'app`

---

## Procédure — 4 niveaux dans l'ordre

### Niveau 1 — Skills actifs : projet courant + global (priorité maximale)

1. **Lire le catalogue global** si disponible :
   - Read `C:\Users\Administrateur\.claude\skills\README.md`
   - Extraire les noms et descriptions listés — c'est la source la plus rapide

2. **Lire les SKILL.md du projet courant** :
   - Glob `{working_dir}\.claude\skills\*/SKILL.md`
   - Pour chaque fichier trouvé : lire les champs `name` et `description` du frontmatter YAML

3. **Lire les SKILL.md globaux** (si pas déjà dans README.md) :
   - Glob `C:\Users\Administrateur\.claude\skills\*/SKILL.md`
   - Même extraction frontmatter

4. **Matcher sémantiquement** : identifier les correspondances directes et proches avec les mots-clés de la requête. Tenir compte des champs `description`, `trigger`, et du nom du skill.

**→ Si correspondance directe trouvée : aller directement au FORMAT DE SORTIE. Ne pas continuer aux niveaux suivants.**

---

### Niveau 2 — Archives (si rien trouvé au niveau 1)

1. Glob `{working_dir}\.claude\skills\_archive\*/SKILL.md`
2. Glob `C:\Users\Administrateur\.claude\skills\_archive\*/SKILL.md`
3. Même extraction + matching
4. Signaler que le skill est **archivé** (désactivé mais réactivable en le copiant hors de `_archive/`)

**→ Si correspondance directe trouvée : aller au FORMAT DE SORTIE. Ne pas continuer au niveau 3.**

---

### Niveau 3 — Autres projets (si toujours rien)

Parcourir les autres projets connus sur la machine :

```
C:\Users\Administrateur\PROJECTS\0- Marketplace\.claude\skills\*/SKILL.md
C:\Users\Administrateur\PROJECTS\Clients & Agence\.claude\skills\*/SKILL.md
C:\Users\Administrateur\PROJECTS\Vente et Marketing - ALL Compagnies\.claude\skills\*/SKILL.md
```

Glob + extraction frontmatter + matching. Signaler le projet d'origine dans le résultat.

**→ Si correspondance trouvée : aller au FORMAT DE SORTIE. Ne pas continuer au niveau 4.**

---

### Niveau 4 — Internet (si toujours rien)

Utiliser WebSearch avec des requêtes ciblées :

```
anthropic claude code skill <mots-clés de la requête>
claude.ai official skills plugins <mots-clés>
claude code community skills <mots-clés>
```

Retourner les liens pertinents avec une description courte. Ne pas halluciner — uniquement des résultats réels trouvés.

---

## Format de sortie

```
🔍 Résultats pour "[requête]"

✅ Correspondances directes (actifs)
- /nom-skill — description — [projet ou global]

🔍 Correspondances proches (actifs)
- /nom-skill — description — [projet ou global]

📦 En archive (désactivé, réactivable)
- /nom-skill — description — [chemin : {projet}/.claude/skills/_archive/ ou global/_archive/]
  → Pour réactiver : copier le dossier hors de _archive/

📁 Autres projets
- /nom-skill — description — [nom du projet]

🌐 En ligne
- Nom — [URL] — description courte
```

Afficher uniquement les sections qui ont des résultats. Sections vides = omises.

---

## Règles

- **Ne jamais sauter de niveau** : toujours dans l'ordre 1 → 2 → 3 → 4.
- **Arrêter au premier niveau avec correspondance directe** : évite le bruit inutile.
- **Pas de correspondance = le dire franchement** : "Aucun skill trouvé pour cette requête. Veux-tu que je cherche en ligne ou que je planifie la création d'un nouveau skill ?"
- **Plusieurs correspondances** : retourner les 3 meilleures maximum par catégorie.
- **Si le README.md global est à jour** : il suffit souvent de le lire + les SKILL.md du projet courant pour couvrir 90% des cas.
