---
name: dashboards-hub-master
description: Skill global LIGHT — workflow déploiement Vercel + Master Hub central pour TOUS les projets PROJECTS/. Invoquer dès qu'un dashboard HTML / hub / page web est créé ou modifié dans un projet (Marketplace, Vente et Marketing, Vote app, <your-project>, etc.). Triggers — "dashboard", "html", "vercel deploy", "master hub", "hub projet", "redéploie".
---

# dashboards-hub-master

Skill global pour gérer dashboards HTML + déploiement Vercel + Master Hub central. **Light** — workflow uniquement, pas catalog exhaustif.

## §1 Règle absolue

**Tout dashboard HTML déployé sur Vercel IMMÉDIATEMENT.** Un dashboard non déployé n'existe pas. Pas de version locale qui dérive de la prod.

Conséquence : pas besoin de "protection HTML" inline — Vercel + git couvrent.

## §2 Workflow par projet (1 projet = 1 URL Vercel)

Chaque projet a UNE URL Vercel qui regroupe TOUS ses dashboards.

Création/modif HTML dans un projet :
1. Placer dans `<projet>/dashboards/`
2. Ajouter dans hub projet (`<projet>-hub.html` ou `index.html`)
3. Enregistrer dans `<projet>/CLAUDE.md` (registre URL)
4. Déployer : `cd "<projet>/dashboards" && npx vercel deploy --prod --yes`
5. Ouvrir via URL Vercel uniquement, jamais en local

**Nouveau projet sans `dashboards/`** : créer dossier + `index.html` (hub) + `npx vercel --prod --yes` pour créer projet Vercel + noter URL dans `<projet>/CLAUDE.md`.

**Interdits** : 1 projet Vercel par fichier HTML · modifier sans redéployer · ouvrir en local quand Vercel existe.

## §3 Master Hub central

URL : `https://antigravity-master-hub.vercel.app/`
Source : `<your-project-folder>/hub/master-hub/index.html`

**TOUT dashboard / hub projet / URL Vercel transversale** doit être référencé depuis le Master Hub. Pas de dashboard orphelin.

Workflow à chaque création/modif dashboard projet :
1. Créer/modifier dashboard dans son projet
2. Déployer sur Vercel projet
3. Éditer Master Hub `<your-project-folder>/hub/master-hub/index.html` — ajouter carte ou MAJ section projet
4. Déployer Master Hub : `cd "<your-project-folder>/hub/master-hub" && npx vercel deploy --prod --yes`
5. Vérifier `https://antigravity-master-hub.vercel.app/` pointe bien vers nouveau dashboard

## §4 Hub & Backlog interne (source vérité projet)

Chaque projet a un fichier central de suivi (`BACKLOG_ROADMAP.md` ou `roadmap.md`) = unique source de vérité INTERNE (Claude + skills).

- **Début session** : lire (priorisation, bloqueurs, dépendances, dette)
- **Fin session** : MAJ proactive (✅ FAIT / ❌ PAS FAIT / 🔄 RESTE)

Hub Dashboard HTML = lien VISIBLE vers le fichier de suivi. Divergence fichier ↔ Hub → fichier interne arbitre.

Exception : `<your-project-folder>/<project-folder>/` utilise `memory/roadmap/roadmap.md`.

## §5 Anti-patterns

- Modifier dashboard sans redéployer Vercel = "le dashboard n'existe pas"
- 1 projet Vercel par fichier HTML (pas 1 par projet)
- Dashboard orphelin (pas dans Master Hub)
- Lire hub HTML pour comprendre état projet (lire `<projet>/CLAUDE.md` ou roadmap.md à la place)
- Dupliquer ce contenu dans `<projet>/CLAUDE.md` (pointer ce skill suffit)
