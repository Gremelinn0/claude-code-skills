---
name: formation-consolider
description: Consolide toutes les sources brutes d'une formation dans une page Notion principale + 1 sous-page par partie. Mot-pour-mot, zéro analyse, traçabilité totale. Réutilisable sur n'importe quelle formation.
---

# formation-consolider

Skill pour construire la **base de travail Notion** d'une formation à partir de toutes les sources existantes (fichiers locaux, pages Notion, dashboards, posts, transcripts).

## Quand l'utiliser

- l'utilisateur lance la consolidation d'une formation (Claude Code, Antigravity, Cursor, etc.)
- Plusieurs sources dispersées (fichiers .md, .html, Notion, dashboards Vercel, posts LinkedIn) doivent être rassemblées
- But : une base Notion propre, 1 sous-page par partie, où chaque bloc porte sa référence, pour que l'utilisateur puisse ensuite retravailler chaque partie à son rythme

**Pas pour :** rédiger des posts LinkedIn, écrire du texte nouveau, faire de l'analyse/synthèse. Juste de la **consolidation verbatim**.

## Principes absolus (non négociables)

1. **Mot-pour-mot** — copier-coller verbatim des sources, aucune reformulation, aucun "j'ai nettoyé", aucun résumé
2. **Zéro analyse pendant la consolidation** — pas de flags `[FLAG — à valider]`, pas de `[FLAG DOUBLON]`, pas de divergences, pas de dédup. Si deux sources disent la même chose de façon légèrement différente, on met les deux, point
3. **Toutes les sources scannées dès la 1ère passe** — pas de `[POSTS À SCANNER]`, pas de "à faire plus tard". Tout est indexé avant la moindre écriture Notion
4. **Traçabilité systématique** — chaque bloc source porte :
   - Fichier local → `chemin/fichier:lignes` (ex: `formations/claude-code-script.md:19-57`)
   - Page Notion → URL complète
   - Dashboard / site web → URL complète
   - Post / vidéo → URL + ID
5. **1 sous-page Notion par partie** — jamais de contenu linéaire dans la page principale. La page principale = intro + TOC cliquable vers les sous-pages + bloc "Références globales"
6. **Séquentiel** — une partie terminée, validation l'utilisateur ("OK"), puis la suivante. Jamais deux parties en parallèle
7. **Préférer l'API Notion MCP** (`mcp__notion__*`, `mcp__decc5ebf-*__notion-*`) au Chrome MCP — plus fiable, pas de déconnexion

## Input attendu

l'utilisateur (ou un plan validé) fournit :

- **Sujet** de la formation (ex: "Claude Code", "Antigravity", "Cursor")
- **TOC figée** — liste numérotée des parties (ex: 15 parties de Claude Code)
- **Catalogue de sources** — liste exhaustive avec labels courts :
  - Fichiers locaux (chemin + rôle)
  - Pages Notion (URL + rôle)
  - Bases Notion (collection ID + description)
  - Dashboards / sites (URL)
  - Posts / vidéos (URL + ID)
  - Mémoire Claude (chemins)
- **Page Notion parent** sous laquelle créer la base (ex: FORMATION CLAUDE TIPS)

Si un élément manque → demander avant de démarrer. Ne pas deviner.

## Phases d'exécution

### Phase 0 — Scan exhaustif (avant toute écriture Notion)

**But :** indexer quel passage de quelle source va dans quelle partie. Rien n'est laissé "à scanner plus tard".

Pour chaque source du catalogue :
1. Lire intégralement (Read pour fichier local, `mcp__decc5ebf-*__notion-fetch` pour Notion, WebFetch ou Chrome MCP pour dashboard)
2. Découper en passages
3. Pour chaque passage, noter :
   - Partie cible (numéro de la TOC)
   - Référence (chemin + lignes ou URL)
   - Court titre interne pour s'y retrouver (pas pour Notion)
4. Si un passage ne rentre dans aucune partie → le noter dans un bloc "Hors TOC" à vider à la fin avec l'utilisateur
5. Si une partie n'a aucun passage → le noter aussi (gap à combler plus tard)

**Résultat :** une map `partie N → liste de (source, référence, passage)` prête à être déversée dans Notion.

**Règle :** ne pas passer à la Phase 1 tant que TOUTES les sources sont scannées. Pas de "je commence par la partie 1 et je scanne le reste plus tard".

### Phase 1 — Page principale Notion

**But :** créer (ou nettoyer) la page Notion racine de la formation.

Structure de la page principale :
- **H1** : nom de la formation (ex: `📘 Formation Claude Code — Base de travail`)
- **Paragraphe intro** : 2-3 lignes en texte simple (pas de bloc code, pas de blockquote) qui disent : ce qu'est ce document, le workflow (scan exhaustif → sous-pages par partie → retravail ultérieur), et rappel "document de travail".
- **H2** `Table des matières` : liste numérotée des 15 parties. Chaque item sera un **lien vers sa sous-page** une fois celle-ci créée. À la première passe, simple liste numérotée.
- **H2** `Références globales` (à remplir au fur et à mesure) : catalogue complet des sources utilisées (chemins de fichiers + URLs Notion + URLs dashboards). Format : liste à puces avec label + ref.

**Si la page existe déjà** (cas refonte / V2) : nettoyer tout contenu précédent qui ne matche pas cette structure. Garder uniquement intro + TOC + bloc Références globales.

Outils privilégiés :
- `mcp__decc5ebf-*__notion-create-pages` (création)
- `mcp__decc5ebf-*__notion-update-page` (mise à jour contenu)
- `mcp__decc5ebf-*__notion-fetch` (vérification état actuel)

### Phase 2 — Sous-pages (1 par partie)

**Pour chaque partie de la TOC, dans l'ordre :**

Créer une sous-page enfant de la page principale avec la structure figée suivante :

- **H1** : `Partie N — Titre de la partie` (exact wording du TOC)
- **H2** : `Sources consolidées (brut, mot-pour-mot)`
- Pour chaque source scannée en Phase 0 qui contribue à cette partie :
  - **H3** : identifiant court de la source + référence courte (ex: `Source B1 — formations/claude-code-script.md:19-57`)
  - **Paragraphe sous le H3** : texte verbatim, tel quel, sans reformulation. Conserver le formatage original du mieux possible (titres Markdown du source → sous-titres Notion, listes → listes Notion, italique → italique). Ne pas "nettoyer" les coquilles, ne pas retirer les emojis, ne pas retirer les `[🎬 DÉMO]` ou `[📌 TODO]` du source.
  - Si le passage source contient lui-même des sous-sections, les conserver.
- **Pas** de H2 "Texte retravaillé" à cette étape. Le retravail = phase ultérieure, déclenchée explicitement par l'utilisateur, partie par partie.
- **Pas** de flags, de divergences, de notes "à dédupliquer", de "à voir plus tard". Rien.

**Ordre des sources dans la sous-page** : par ordre de création / pertinence, pas d'ordre strict. Si l'utilisateur préfère un ordre spécifique, il le dit.

**Une fois la sous-page créée** :
1. Revenir sur la page principale
2. Mettre à jour l'item de la TOC pour qu'il pointe en lien vers la sous-page (`notion-update-page`)
3. Ajouter les sources utilisées au bloc "Références globales" si pas déjà présentes

### Phase 3 — Validation l'utilisateur entre chaque partie

**Règle absolue** : après la création de chaque sous-page, présenter à l'utilisateur un message court :

> Partie N `<titre>` consolidée dans Notion. Sources incluses : B1, A2, C5, D1. Lien : `<url>`. OK pour passer à la Partie N+1 ?

Attendre le "OK" explicite. Pas de passage à la partie suivante sans validation.

Si l'utilisateur signale un oubli / un problème sur la partie N → corriger la partie N avant de continuer.

### Phase 4 — Miroir local optionnel

Si utile pour la session suivante (ex: gros scan à re-parcourir, aide mémoire), générer en parallèle un fichier `.md` dans le projet (ex: `formations/CONSOLIDE_<SUJET>.md`) avec la même structure que les sous-pages Notion. Mais **Notion reste la source de vérité**.

Ne PAS générer ce miroir par défaut — uniquement si l'utilisateur le demande ou si c'est explicitement utile pour continuer le travail plus tard.

### Phase 5 — Finalisation

Une fois les N sous-pages créées et validées :
1. Vérifier que la TOC de la page principale pointe bien vers chaque sous-page (liens cliquables)
2. Vérifier que le bloc "Références globales" liste bien toutes les sources utilisées
3. Présenter à l'utilisateur un message de clôture : nombre de sous-pages, nombre de sources, URL de la page principale

## Ce que le skill NE fait PAS

- **Pas de retravail / réécriture** — même pas "je nettoie les coquilles", même pas "je reformule pour plus de clarté"
- **Pas de synthèse / dédup / analyse de divergences** — si deux sources se contredisent, on garde les deux, l'utilisateur tranchera plus tard
- **Pas de création de posts LinkedIn** — ce skill ne génère jamais de post. Pour ça, voir `/linkedin-post-creator`
- **Pas de scraping YouTube / Skool** — si une vidéo YouTube doit être incluse, passer par `/youtube-scraper` en amont, mettre le transcript dans une source locale, puis inclure cette source
- **Pas de montage vidéo, pas de Jack Roberts** — sujets hors scope

## Outils utilisés (ordre de préférence)

1. **Notion API MCP** (`mcp__notion__*`, `mcp__decc5ebf-*__notion-*`) — création, fetch, update, move
2. **Read** — lecture fichiers locaux
3. **WebFetch** — pages web publiques (dashboards Vercel, sites)
4. **Chrome MCP** (`mcp__Claude_in_Chrome__*`) — fallback si API Notion indisponible, ou si la page Notion nécessite vraiment une interaction UI

## Structure Notion cible (rappel visuel)

```
📘 Formation <sujet> — Base de travail (page principale)
  H1 + intro + TOC cliquable + Références globales
  
  ├── 📄 Partie 1 — Titre
  │   H2 Sources consolidées (brut, mot-pour-mot)
  │   ├── H3 Source B1 — ref
  │   │   verbatim
  │   ├── H3 Source A2 — ref
  │   │   verbatim
  │   └── ...
  │
  ├── 📄 Partie 2 — Titre
  │   ...
  │
  └── 📄 Partie N — Titre
      ...
```

## Exemple d'utilisation

```
l'utilisateur : "On consolide la formation Cursor. 10 parties, sources :
- cursor-script.md (local)
- hub/cursor.html (local)
- Notion page Cursor (URL)
- speakapp-dashboards.vercel.app/cursor-training.html
- Base Notion posts (23 entrées)"

Claude :
1. Phase 0 — Lit tout, mappe les passages par partie
2. Phase 1 — Crée page "📘 Formation Cursor — Base de travail" avec intro + TOC 10 items
3. Phase 2 — Crée sous-page "Partie 1 — Intro", y met H2 + H3 par source + verbatim
4. Dit à l'utilisateur : "Partie 1 faite, sources : X, Y, Z. OK pour Partie 2 ?"
5. Attend OK, enchaîne.
```

## Checklist pré-vol

Avant de démarrer :
- [ ] TOC figée reçue (numérotée, titres clairs)
- [ ] Catalogue complet des sources reçu (avec labels B1, A2, etc. ou équivalent)
- [ ] Page Notion parent identifiée
- [ ] MCP Notion disponible (sinon fallback Chrome MCP documenté)
- [ ] Aucune source "à scanner plus tard"
- [ ] Règle mot-pour-mot rappelée
- [ ] Workflow validation partie-par-partie acté avec l'utilisateur

Si une case n'est pas cochable → demander à l'utilisateur avant de démarrer la Phase 0.
