---
name: skill-finder
description: Recherche le bon skill Ã  utiliser pour une demande donnÃ©e. Parcourt les skills actifs (projet + global), les archives, les autres projets, puis internet si rien n'est trouvÃ©. Triggers "quel skill pour", "tu as un skill pour", "cherche un skill", "trouve-moi le skill", "/skill-finder".
trigger: user-invocable
scope: global â€” tout projet
---

# /find-skill â€” Trouver le bon skill pour une demande

**`/find-skill <description>` prend une description libre et identifie le ou les skills les plus pertinents**, en parcourant 4 niveaux dans l'ordre : actifs (projet + global) â†’ archives â†’ autres projets â†’ internet.

**ArrÃªter au premier niveau qui donne une correspondance directe.** Ne pas continuer au niveau suivant si une correspondance directe est trouvÃ©e. Continuer au niveau suivant uniquement si aucune correspondance directe n'est trouvÃ©e.

---

## Invocation

```
/find-skill <description de ce que tu veux faire>
```

**Exemples** :
- `/find-skill tester la dictÃ©e vocale`
- `/find-skill cherche un skill pour automatiser une permission Claude Desktop`
- `/find-skill exporter une feuille Google Sheets`
- `/find-skill health check de l'app`

---

## ProcÃ©dure â€” 4 niveaux dans l'ordre

### Niveau 1 â€” Skills actifs : projet courant + global (prioritÃ© maximale)

1. **Lire le catalogue global** si disponible :
   - Read `C:\Users\Utilisateur\.claude\skills\README.md`
   - Extraire les noms et descriptions listÃ©s â€” c'est la source la plus rapide

2. **Lire les SKILL.md du projet courant** :
   - Glob `{working_dir}\.claude\skills\*/SKILL.md`
   - Pour chaque fichier trouvÃ© : lire les champs `name` et `description` du frontmatter YAML

3. **Lire les SKILL.md globaux** (si pas dÃ©jÃ  dans README.md) :
   - Glob `C:\Users\Utilisateur\.claude\skills\*/SKILL.md`
   - MÃªme extraction frontmatter

4. **Matcher sÃ©mantiquement** : identifier les correspondances directes et proches avec les mots-clÃ©s de la requÃªte. Tenir compte des champs `description`, `trigger`, et du nom du skill.

**â†’ Si correspondance directe trouvÃ©e : aller directement au FORMAT DE SORTIE. Ne pas continuer aux niveaux suivants.**

---

### Niveau 2 â€” Archives (si rien trouvÃ© au niveau 1)

1. Glob `{working_dir}\.claude\skills\_archive\*/SKILL.md`
2. Glob `C:\Users\Utilisateur\.claude\skills\_archive\*/SKILL.md`
3. MÃªme extraction + matching
4. Signaler que le skill est **archivÃ©** (dÃ©sactivÃ© mais rÃ©activable en le copiant hors de `_archive/`)

**â†’ Si correspondance directe trouvÃ©e : aller au FORMAT DE SORTIE. Ne pas continuer au niveau 3.**

---

### Niveau 3 â€” Autres projets (si toujours rien)

Parcourir les autres projets connus sur la machine :

```
C:\Users\Utilisateur\PROJECTS\0- Marketplace\.claude\skills\*/SKILL.md
C:\Users\Utilisateur\PROJECTS\Clients & Agence\.claude\skills\*/SKILL.md
C:\Users\Utilisateur\PROJECTS\Vente et Marketing - ALL Compagnies\.claude\skills\*/SKILL.md
```

Glob + extraction frontmatter + matching. Signaler le projet d'origine dans le rÃ©sultat.

**â†’ Si correspondance trouvÃ©e : aller au FORMAT DE SORTIE. Ne pas continuer au niveau 4.**

---

### Niveau 4 â€” Internet (si toujours rien)

Utiliser WebSearch avec des requÃªtes ciblÃ©es :

```
anthropic claude code skill <mots-clÃ©s de la requÃªte>
claude.ai official skills plugins <mots-clÃ©s>
claude code community skills <mots-clÃ©s>
```

Retourner les liens pertinents avec une description courte. Ne pas halluciner â€” uniquement des rÃ©sultats rÃ©els trouvÃ©s.

---

## Format de sortie

```
ðŸ” RÃ©sultats pour "[requÃªte]"

âœ… Correspondances directes (actifs)
- /nom-skill â€” description â€” [projet ou global]

ðŸ” Correspondances proches (actifs)
- /nom-skill â€” description â€” [projet ou global]

ðŸ“¦ En archive (dÃ©sactivÃ©, rÃ©activable)
- /nom-skill â€” description â€” [chemin : {projet}/.claude/skills/_archive/ ou global/_archive/]
  â†’ Pour rÃ©activer : copier le dossier hors de _archive/

ðŸ“ Autres projets
- /nom-skill â€” description â€” [nom du projet]

ðŸŒ En ligne
- Nom â€” [URL] â€” description courte
```

Afficher uniquement les sections qui ont des rÃ©sultats. Sections vides = omises.

---

## RÃ¨gles

- **Ne jamais sauter de niveau** : toujours dans l'ordre 1 â†’ 2 â†’ 3 â†’ 4.
- **ArrÃªter au premier niveau avec correspondance directe** : Ã©vite le bruit inutile.
- **Pas de correspondance = le dire franchement** : "Aucun skill trouvÃ© pour cette requÃªte. Veux-tu que je cherche en ligne ou que je planifie la crÃ©ation d'un nouveau skill ?"
- **Plusieurs correspondances** : retourner les 3 meilleures maximum par catÃ©gorie.
- **Si le README.md global est Ã  jour** : il suffit souvent de le lire + les SKILL.md du projet courant pour couvrir 90% des cas.
