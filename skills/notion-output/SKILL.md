---
name: notion-output
description: Skill global LIGHT — sortie info / Notion pages / Table Projets pour TOUS projets PROJECTS/ SAUF SpeakApp (qui utilise sa propre mémoire `memory/`). Invoquer dès qu'on collecte/synthétise des infos (URLs, vidéos, conclusions, livrables) destinées Notion. Triggers — "notion", "page notion", "ajoute notion", "table projets", "notebooklm", "ressources collectées", "livrable projet".
---

# notion-output

Skill global LIGHT pour Notion = mémoire persistante partagée cross-projet (sauf SpeakApp).

**Skip ce skill si projet courant = `3- Wisper/speak-app-dev/`** (SpeakApp utilise `memory/` interne).

## §1 Sortie info = Notion

Quand Claude collecte/recherche/synthétise infos (ressources, vidéos, liens, conclusions, analyses), sortie FINALE va dans Notion. Pas juste résumer dans le chat. Notion = mémoire persistante partagée toutes sessions.

**Va dans Notion** : URLs · vidéos YouTube · liens collectés · notebooks NotebookLM (titre + URL) · conclusions analyse · pages formation · dashboards déployés (URL Vercel).

**Procédure** : MCP Notion (déjà connecté) → chercher page parent appropriée → créer sous-page titre clair + contenu structuré.

## §2 Format texte Notion

**Interdit pour contenu humain** :
- Blocs de code (triple backticks) — parasite "javascript" au copier-coller
- Tout-en-blockquote — préfixe `>` toutes lignes = "citations vides"

**À utiliser** :
- Texte simple paragraphes normaux = défaut tout texte > 2 lignes
- Blockquote `>` uniquement lignes courtes (1-3 lignes max)
- Listes à puces `-` pour options/items
- Titres `##` / `###` pour sections
- Gras `**...**` pour labels
- Italique `_..._` pour annotations
- Callouts natifs Notion pour mises en garde

**Exception** : vrai code technique destiné à être exécuté → bloc de code OK.

## §3 Table Projets Notion = source vérité projets actifs

- **Table** : https://www.notion.so/prospectpartner/TO-DO-Mes-projets-et-t-ches-26501e69443c80bfa0c2c3fefa879b15
- **Projets DB** : `collection://26501e69-443c-81ad-9b91-000b97817f17`
- **Tâches DB** : `collection://26501e69-443c-8116-b237-000bdc32b867`

Début session : lire table Projets (statut, résumé, bloquants).
Fin session : MAJ ligne(s) concernée(s).

**Statuts valides** :
- Projets : `À faire` / `Terminé` / `Annulé` (pas "En cours")
- Tâches : `À faire` / `En cours` / `Terminé` / `Archivé`

**Relation Projet dans Tâches** : JSON array d'URLs : `["https://www.notion.so/<page_id>"]`.

## §4 Où créer pages Notion

| Ce que je crée | Où ça va |
|----------------|----------|
| Post LinkedIn (brouillon, hooks, visuels) | Table "Mon contenu" — `collection://a8d9fa9e-3614-4f19-be94-7e3c4ad163c1` |
| Projet, suivi, livrable projet | Table Projets — `collection://26501e69-443c-81ad-9b91-000b97817f17` |
| Tâche liée à un projet | Table Tâches — `collection://26501e69-443c-8116-b237-000bdc32b867` |

**JAMAIS** page flottante au niveau ROOT workspace. **JAMAIS** livrable projet dans "Mon contenu". Type de contenu pas clair → demander.

## §5 Anti-patterns

- Synthétiser dans le chat sans push Notion = info perdue prochaine session
- Page flottante root workspace = orpheline, introuvable
- Bloc code triple-backtick pour texte humain = parasite copier-coller
- Tout-en-blockquote = citations vides
- Mélanger livrable projet dans table "Mon contenu" (pour LinkedIn uniquement)
