---
name: notion-cleanup
description: Skill Notion tout-en-un — ménage/consolidation 2 passes + règles création nouveau contenu + routing (où poster quoi) + format texte. Triggers — "nettoyer notion", "organiser notion", "cleanup notion", "centraliser notion", "ranger notion", "ménage notion", "consolider notion", "notion", "page notion", "ajoute notion", "table projets", "ressources collectées", "livrable projet".
---

# notion-cleanup

Skill global progressif pour nettoyer/centraliser le workspace Notion de Florent.

## Philosophie

**1 sujet = 1 hub** = page maîtresse qui centralise TOUT sur ce sujet.
- Pages satellites → sous le hub (ou liens depuis le hub)
- Pages client = exception OK mais référencées depuis hub
- Vieux contenus → 📦 Archive (jamais delete)
- Objectif : zéro déchet, tout trouvable en 2 clics, format simple

---

## §1 — RÈGLE D'OR : 2 PASSES (ne jamais mélanger)

### PASSE 1 — CONSOLIDATION PURE

Objectif : centraliser pages sous bons hubs + vue d'ensemble. Sans toucher leur contenu.

**Autorisé :**
- ✅ Créer hub neuf (page propre, vierge — JUSTE titres + liens)
- ✅ Déplacer pages sous hub (avec table rollback obligatoire — voir §3)
- ✅ Trier liens dans hub par date modif : récent EN HAUT, vieux EN BAS

**Interdit :**
- ❌ Archiver
- ❌ Supprimer
- ❌ Toucher au contenu/texte des pages
- ❌ Fusionner pages
- ❌ Renommer pages
- ❌ Catégoriser thématiquement (vient passe 2)

**Pourquoi :** tant que pages pas consolidées sous bon hub, on n'a pas la vision complète. Toucher contenu = casser sans savoir. Consolide d'abord, vois tout, ménage ensuite.

Florent verbatim 2026-05-03 : *"On ne touche pas au texte parce qu'on n'a pas une vision complète"*.

### PASSE 2 — MÉNAGE

Une fois hub propre + tout dedans + trié chrono → Florent voit la liste complète.

Claude propose bloc par bloc :
- *"Ces 3 pages en bas (très vieilles) → archive ?"*
- *"Ces 4 pages sur même sujet → fusion en 1 doc propre ?"*
- *"Cette série de 5 pages → table Notion plus pratique ?"*
- *"Ce paquet de pages clients → sous-hub Clients dédié ?"*

Florent décide bloc par bloc. Claude exécute.

---

## §2 — Sécurité déplacement pages (passe 1B obligatoire)

**Risque** : déplacer page = changer son `parent`. Erreur = page "perdue" (retrouvable mais friction).

**Protocole obligatoire** :
1. Logger `page_id` + titre + parent_avant dans table rollback session AVANT chaque move
2. Une page à la fois, pas batch silencieux
3. Vérifier après move via `mcp__notion__API-retrieve-a-page` → confirmer nouveau parent OK
4. Si Florent dit "annule" → restaurer parent_avant via table rollback

Format table rollback :
```
| page_id | titre | parent_avant | parent_après | status |
|---------|-------|--------------|--------------|--------|
| 19201e69... | Prospection | xxx-yyy | hub-prospection-id | ✓ |
```

**Sous-passe optionnelle 1A (encore + safe)** : créer hub neuf avec liens des pages SANS déplacement → Florent valide la liste → puis 1B déplacement réel. Recommandé pour gros périmètres (>15 pages).

---

## §3 — Workflow détaillé passe 1

### Étape 1 : Scan + identification hub candidates

Actions :
1. Demander périmètre : *"Quel périmètre ? (ex: Marketing, Clients, Personnel, Tout, ou nom projet)"*
2. Lire memory files Notion existants (§5) → récupérer IDs/contexte déjà connu
3. Scanner via `mcp__notion__API-post-search` (queries ciblées, pas trop large — résultats > 100k chars timeout)
4. Pour DBs déjà identifiées comme hubs (§5), `mcp__notion__API-get-block-children` sur leur ID
5. Construire map : pages perso vs templates (n8n/marketplace = bruit, hors scope)
6. Présenter rapport scan court à Florent :

```
SCAN [PÉRIMÈTRE] — [date]

Pages perso trouvées : N (filtrées du bruit templates)

CANDIDATES HUB :
- [Page X] (id, date) — [pourquoi candidate]

PAGES SATELLITES (rattacher au hub) :
- [Page A] (id, date)
- [Page B] (id, date)

DOUBLONS DÉTECTÉS :
- [Page A] vs [Page B] sur même topic

QUESTIONS (max 3, simples 1/2/3) :
Q1 — Hub [topic] : promouvoir page X ou créer hub neuf ?
```

### Étape 2 : Création hub neuf

Format hub passe 1 (NEUF, vierge, propre) :
```
# 🎯 Hub [Topic]

> Centralisation [topic]. Liens vers toutes pages [topic]. Tri chrono — récent en haut.

## Pages sous ce hub

- [Titre A](url) — 2026-XX
- [Titre B](url) — 2026-XX
- [Titre Z](url) — 2024-XX
```

**Règles** :
- Hub = page NEUVE de préférence (propre, vierge — pas réutiliser page bordélique)
- Si Florent dit "promeut page X en hub" → OK mais nettoyer header de cette page (juste liens)
- Liens cliquables format `[Titre](URL Notion)`
- Tri par `last_edited_time` desc strict
- Pas de catégorisation thématique en passe 1
- Référencer hub dans HUB Florent central (`34c01e69...`) si nouveau topic + accès dispo (sinon noter en §8)

### Étape 3 : Déplacement (passe 1B)

Pour chaque page satellite identifiée :
1. Logger ligne table rollback (page_id, titre, parent_avant)
2. `mcp__notion__API-move-page` parent = hub_id
3. `mcp__notion__API-retrieve-a-page` → vérifier nouveau parent
4. MAJ table rollback (parent_après, status ✓)
5. Continuer page suivante

À la fin : annoncer compte (X pages déplacées sous Hub Y).

---

## §4 — Workflow détaillé passe 2 (ménage)

Activé seulement si passe 1 validée par Florent ET il dit "on attaque le ménage".

Pour chaque hub :
1. Lister pages dedans triées chrono
2. Identifier blocs de pages similaires (même date approx, même thème, doublons)
3. Proposer décisions par bloc :

```
Bloc détecté : [N pages] sur [topic] entre [date1] et [date2]
- [Page A] — [résumé 1 ligne]
- [Page B] — [résumé 1 ligne]
- ...

→ Proposition Claude : FUSION en 1 doc / ARCHIVE TOUT / TABLE / GARDER TEL QUEL
→ Tu valides ? (1/2/3/4)
```

Critères auto-archive (Claude propose direct) :
- Page vide ou < 3 blocs
- Page taggée `[ARCHIVE]` titre
- Doublon évident (titre+contenu très similaires)
- Page > 12 mois sans modif (proposer, pas exécuter)

Critères → demander Florent obligatoire :
- Suppression définitive (défaut = archive)
- Page client
- Contenu substantiel à fusionner
- Fusion > 2 pages

### Archive
- Page racine `📦 Archive` (créer si manque, sous parent accessible)
- Sous-pages par année si volume
- `mcp__notion__API-move-page` parent = Archive (jamais delete)
- Préfixer titre `[ARCHIVE]` au move (cohérence visuelle)

---

## §5 — Contexte existant (point de départ)

### HUB Florent central (créé 2026-04-24)

- URL : https://www.notion.so/34c01e69443c818e9982ea27209eb3c8
- ID : `34c01e69-443c-818e-9982-ea27209eb3c8`
- Parent : Prospect Partner page (`620e7db03ed44db6b7cbcb4bb71fbc66`)
- ⚠️ ACCÈS LIMITÉ — voir §8

### Hubs thématiques validés

| Topic | Hub | ID |
|-------|-----|-----|
| Montage vidéo Claude Code | 🎬 Méthodologie Montage Vidéo Auto | `34901e69-443c-819c-8fe9-f4509e34a7bf` |
| Formation Claude Code | FORMATION CLAUDE TIPS | `34a01e69-443c-8046-b9ca-ca2cd8bc0f12` |
| Hub Claude Code général | Claude Code — Hub de contenus | `33101e69-443c-811e-9390-ef75a7aaf172` |
| Coordonnées | Coordonnées & Accès | `521e6926-c821-48b9-ae39-4ba7b1fb5594` |
| Skills Marketplace | 🎁 Skills Marketplace Florent | `34d01e69-443c-81fa-8abb-db32267e7668` |
| Posts réseaux sociaux | Posts Réseaux sociaux Production (DB) | `a8d9fa9e-3614-4f19-be94-7e3c4ad163c1` |
| Projets/Tâches | TO-DO Mes projets et tâches (DB) | `26501e69-443c-81ad-9b91-000b97817f17` |
| Suivi missions Malt | Suivi des missions Malt (DB) | `2b801e69-443c-80f9-977c-e20cba33e9cf` |
| Projets Growth | Projets Growth Déploiement prospection (DB) | `65204466-4896-4111-a7e1-b15dc5d1c497` |

### Hubs candidats (en cours validation 2026-05-03)

| Topic | Page candidate | ID | Statut |
|-------|----------------|-----|--------|
| Prospection | Prospection | `19201e69` | 🟡 candidate hub |
| Clients | Clients - Accès | `1ad01e69` | 🟡 candidate hub |
| Sales/Vente | Sales & Marketing Skills | `34801e69` | 🟡 candidate hub |

### Règles codifiées (CLAUDE.md projets non-Wisper)

1. HUB Notion central obligatoire — page nouvelle passe par hub thématique référencé dans HUB Florent
2. Identifier+valider page Notion AVANT d'écrire
3. Notion-first pour Sales (jamais .md locaux)
4. Auto-push posts LinkedIn → Notion "Mon contenu"
5. Coordonnées Notion = source vérité infos perso (Dashlane = credentials)

### Memory files de référence

- `~/.claude/projects/C--Users-Administrateur-PROJECTS-Vente-et-Marketing---ALL-Compagnies/memory/reference_notion_pages_index.md` — index pages principales avec IDs
- `~/.claude/projects/C--Users-Administrateur-PROJECTS-Vente-et-Marketing---ALL-Compagnies/memory/reference_notion_doc_routines_claude_code.md`

---

## §6 — Outils Notion MCP

Charger via ToolSearch début session :
```
ToolSearch query: "select:mcp__notion__API-post-search,mcp__notion__API-retrieve-a-page,mcp__notion__API-get-block-children,mcp__notion__API-move-page,mcp__notion__API-patch-page,mcp__notion__API-post-page,mcp__notion__API-query-data-source"
```

**Pièges API connus** :
- `post-search` query large = >100k chars = timeout. Préférer queries ciblées (5-10 mots-clés max).
- Si search renvoie templates n8n marketplace (parent DB `2da01e69`, `2e201e69`, `2d801e69`, `2ff01e69`) → c'est du bruit, filtrer hors scope.
- `get-block-children` ne renvoie pas les sous-pages d'une page si l'intégration n'a pas accès.

---

## §7 — Démarrage session cleanup

1. Charger outils Notion MCP (§6)
2. Lire §5 + §9 contexte accumulé
3. Demander périmètre + sous-passe (1A liens-only ou 1B move réel)
4. Étape 1 — scan + rapport + validation hubs
5. Étape 2 — création hub neuf avec liens triés chrono
6. (Si 1B) Étape 3 — déplacement avec table rollback
7. Fin session — auto-update §9 si patterns détectés (annoncer)

**Jamais** : agir sans scan, créer hub sans validation, déplacer sans table rollback, toucher contenu en passe 1.

---

## §8 — Limitations connues (intégration Notion MCP)

L'intégration MCP Notion utilisée s'appelle **"Make & n8n"** (id `c9b82f89-afd1-43fb-a4cf-72d45dce90a5`).

**Pages NON accessibles via cette intégration** (404) :
- HUB Florent (`34c01e69-443c-818e-9982-ea27209eb3c8`) — page non partagée avec intégration
- Prospect Partner page (`620e7db0-3ed4-4db6-b7cb-cb4bb71fbc66`) — page non partagée

**Workaround possibles** :
1. Demander Florent share HUB Florent + Prospect Partner avec intégration "Make & n8n" (ouvrir page Notion → Share → Add connection → "Make & n8n")
2. Créer hub neuf sous une page parent accessible (chercher pages déjà accessibles via search)
3. Créer hub neuf avec parent = `workspace` (racine workspace) — ensuite Florent peut déplacer manuellement

**Toujours détecter accès AVANT de tenter create** : `mcp__notion__API-retrieve-a-page` sur ID parent visé. Si 404 → demander Florent share OU choisir autre parent.

---

## §9 — Auto-évolution + patterns appris

### Mécanisme

Après chaque session, Claude DOIT :
1. Détecter patterns dans décisions Florent (validations répétées, refus répétés, préférences)
2. MAJ ce skill (§9 patterns + §5 nouveaux hubs)
3. Annoncer ce qui est ajouté, pas demander (sauf si pattern ambigu)

### Limites auto-update

- Claude peut MAJ §5 (nouveaux hubs validés) et §9 (patterns)
- Claude NE TOUCHE PAS §1-§8 sans validation explicite Florent (structure du skill)

### Patterns Florent observés

- **2026-04-23** : préfère fusion contenu dans page mère plutôt que 2 pages parallèles (incident Nate Herk doublon)
- **2026-04-24** : tout passe par HUB Florent central, plus de pages flottantes
- **2026-04-25** : avant publication externe → ménage doublons obligatoire (incident Skills Marketplace)
- **2026-05-02** : workflow progressif validé — étape 1 hubs, étape 2 décisions, étape 3 structure
- **2026-05-03** : RÈGLE DES 2 PASSES gravée — passe 1 = consolide+trie SANS contenu, passe 2 = ménage
- **2026-05-03** : hub neuf préféré (pas réutiliser page bordélique)
- **2026-05-03** : tri chrono strict récent EN HAUT vieux EN BAS dans hub
- **2026-05-03** : passe 1 = JUSTE liens, pas catégorisation thématique
- **2026-05-03** : sécurité déplacement obligatoire (table rollback id+parent_avant)
- **2026-05-03** : verbatim *"on ne touche pas au texte parce qu'on n'a pas une vision complète"*
- **2026-05-03** : verbatim *"fais attention quand on déplace les trucs, pages perdues à droite à gauche"*
- **2026-05-03** : pas besoin lire toutes les tables au début — démarrer simple

### Anti-patterns détectés

- ❌ Halluciner contenu (incident inventaire skills 2026-04-25)
- ❌ Créer page sans chercher existante d'abord
- ❌ Multiples questions en même temps → user perdu
- ❌ Recap spontané hors plan vivant session
- ❌ Tenter créer page sans vérifier accès parent avant (404 silencieux possible)
- ❌ Search Notion query trop large → timeout >100k chars

---

## §10 — Activation par projet

Skill global → actif partout. Invoqué via :
- `/notion-cleanup`
- Triggers naturels : "nettoie notion", "ménage notion", "consolide notion", "organise notion"

### Prompt réutilisable par projet

À coller en session ouverte dans n'importe quel dépôt projet :
```
/notion-cleanup

Périmètre = ce projet uniquement. Passe 1 SEULEMENT (consolidation hub neuf + liens triés chrono, zéro touche contenu).

1. Lis CLAUDE.md projet courant pour identifier sujets/clients/topics
2. Lis memory files Notion existants si présents
3. Scan Notion ciblé (queries 5-10 mots du projet)
4. Identifie pages perso (filtre bruit templates n8n)
5. Présente rapport scan : candidates hub + pages satellites + doublons
6. Attends validation hubs avant créer

NE FAIS RIEN encore sans validation. Juste diagnostic.
```

---

## §11 — Créer du nouveau contenu dans Notion (ex notion-output)

### Règle de base

Quand Claude collecte/synthétise infos (URLs, vidéos, conclusions, livrables) → sortie va dans Notion. Pas juste résumer dans le chat. Notion = mémoire persistante cross-sessions.

**Va dans Notion** : URLs · vidéos YouTube · notebooks NotebookLM (titre + URL) · conclusions analyse · pages formation · dashboards déployés (URL Vercel).

### Routing — où créer les pages

| Ce que je crée | Où ça va |
|----------------|----------|
| Post LinkedIn (brouillon, hooks, visuels) | Table "Mon contenu" — `collection://a8d9fa9e-3614-4f19-be94-7e3c4ad163c1` |
| Projet, suivi, livrable projet | Table Projets — `collection://26501e69-443c-81ad-9b91-000b97817f17` |
| Tâche liée à un projet | Table Tâches — `collection://26501e69-443c-8116-b237-000bdc32b867` |

**JAMAIS** page flottante au niveau ROOT workspace. **JAMAIS** livrable projet dans "Mon contenu". Type pas clair → demander.

**Table Projets** : https://www.notion.so/prospectpartner/TO-DO-Mes-projets-et-t-ches-26501e69443c80bfa0c2c3fefa879b15
- Statuts Projets valides : `À faire` / `Terminé` / `Annulé`
- Statuts Tâches valides : `À faire` / `En cours` / `Terminé` / `Archivé`
- Relation Projet dans Tâches : JSON array d'URLs `["https://www.notion.so/<page_id>"]`

### Format texte Notion

**Interdit pour contenu humain** :
- Blocs de code (triple backticks) — parasite "javascript" au copier-coller
- Tout-en-blockquote — préfixe `>` toutes lignes = "citations vides"

**À utiliser** :
- Texte simple paragraphes normaux = défaut tout texte > 2 lignes
- Blockquote `>` uniquement lignes courtes (1-3 lignes max)
- Listes `-` pour options/items
- Titres `##` / `###` pour sections
- Gras `**...**` pour labels, italique `_..._` pour annotations

**Exception** : vrai code technique exécutable → bloc de code OK.

### Anti-patterns (notion-output)

- ❌ Synthétiser dans le chat sans push Notion = info perdue prochaine session
- ❌ Page flottante root workspace = orpheline, introuvable
- ❌ Bloc code triple-backtick pour texte humain = parasite copier-coller
- ❌ Mélanger livrable projet dans table "Mon contenu" (LinkedIn uniquement)

---

## §12 — Consolidation finale (1 sujet = 1 page centrale unique)

**Quand l'utiliser** : Florent veut UNE page centrale propre par sujet (marketplace, sales, formation, etc.). Anciennes versions rangées MAIS accessibles. Important visible en haut.

### Pattern "Page centrale finale"

Structure obligatoire d'une page centrale propre :

```
# 🎯 [Sujet]

> 1 phrase qui dit ce qu'est ce sujet aujourd'hui (état réel actuel).

## 🔥 ACTUEL (top of mind)
- [Page la plus active] — état actuel, dernière update
- [2-3 docs vivants max]

## 📌 Référence (à jour)
- [Doc ref 1] — rôle
- [Doc ref 2] — rôle
- [Doc ref 3] — rôle

## 🗂️ Sous-thèmes
### Thème A
- pages liées
### Thème B
- pages liées

## 📦 Anciennes versions / archives
> Conservées pour historique. Pas pour usage quotidien.
- [Vieux doc] — date archivage + raison
- [Vieille version] — remplacé par [nouveau]

## ⚠️ À traiter (ménage en cours)
- [Page X] — décision pending : fusionner/archiver/supprimer ?
```

### Workflow consolidation finale (sur sujet déjà scanné en passe 1)

1. **Lister tout ce qui existe** (passe 1 déjà faite) → liste plate triée chrono
2. **Classifier en 5 buckets** :
   - 🔥 ACTUEL (1-3 pages max, top of mind)
   - 📌 Référence (docs stables, à jour, consultés régulièrement)
   - 🗂️ Sous-thèmes (groupe par topic secondaire)
   - 📦 Archives (vieilles versions à garder accessibles)
   - ⚠️ À traiter (décisions Florent pending)
3. **Présenter classification à Florent** bloc par bloc → valider
4. **Construire page centrale** avec structure ci-dessus
5. **Déplacer pages** sous bonne section (table rollback obligatoire — voir §2)
6. **Archives → sous-page "📦 Archives [Sujet]"** sous page centrale
7. **Lien retour** depuis page centrale vers HUB Florent global

### Règles d'or consolidation finale

- **1 page centrale par sujet, jamais 2** → si 2 pages se disputent ce rôle, fusionner ou supprimer une
- **🔥 ACTUEL = max 3 items** sinon perd intérêt visuel
- **Anciennes versions = conservées toujours** (jamais delete) → section 📦 dédiée
- **Date dernière revue** en bas de page centrale (Claude met à jour à chaque session)
- **Pas de duplication** : un doc est dans UN bucket. Si actuel + référence → choisir actuel.

### Quand sujet déjà a une "page d'inventaire" (cas marketplace 2026-04-22)

Si Florent a déjà une page d'inventaire (liste plate avec 🟢/🔴/🟡) :
1. Cette page = **étape intermédiaire** entre passe 1 et page centrale finale
2. Utiliser ses décisions (🔴 archivés, 🟢 gardés, 🟡 traités) pour alimenter buckets §12
3. **Remplacer** page inventaire par page centrale finale (ou la promouvoir et la restructurer)
4. Page inventaire archivée si plus utile

### Pattern Florent verbatim 2026-05-04

> *"tout consolider, tout nettoyer, faire un truc bien propre, où j'ai tout dedans même les anciennes versions, tout absolument tout est bien rangé. Avec les trucs plus importants tout en haut bien visible. À jour."*

→ Page centrale = vitrine du sujet. Si Florent l'ouvre dans 6 mois et comprend immédiatement où il en est = OBJECTIF ATTEINT.
