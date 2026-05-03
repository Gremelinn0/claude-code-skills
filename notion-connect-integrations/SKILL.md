---
name: notion-connect-integrations
description: Connecte les 2 intégrations Notion (Florent + Make & n8n) à chaque page parent du workspace via Chrome MCP. Priorise pages récemment modifiées (gain 90% temps). Pause auto avant compactage avec chip handoff. Triggers — "connecte intégrations notion", "share notion intégrations", "add connection notion toutes pages", "notion connect florent make".
---

# notion-connect-integrations

Skill mono-tâche : ajouter les 2 intégrations Notion (**Florent** + **Make & n8n**) à chaque page parent du workspace.

## Pourquoi ce skill existe

- Notion API ne permet PAS d'ajouter une connection à une page programmatiquement (UI-only)
- Donc Chrome MCP obligatoire : ouvrir page → Share → Add connections
- Beaucoup de pages → besoin de prioriser + persister état + reprendre après compactage

---

## §0 — RÈGLE ABSOLUE (gravée 2026-05-03)

> ⛔ **PAGES RACINES UNIQUEMENT. AUCUNE SOUS-PAGE. SANS EXCEPTION.**
>
> Une page racine = `parent.type == "workspace"` uniquement.
> Toute page avec `parent.type == "page_id"` ou `parent.type == "database_id"` = **SKIP immédiat, sans vérification, sans navigation**.
> Les sous-pages héritent automatiquement des connexions du parent → les traiter = gaspillage pur.

---

## §1 — Stratégie de priorisation (90% gain)

### Cibler en priorité

1. **Pages racine uniquement** (`parent.type == "workspace"`) — jamais de sous-pages (enfants)
2. **Espaces d'équipe (teamspaces) en premier** — sidebar Notion > sections partagées
3. **Tri last_edited_time desc** — récent = activement utilisé = priorité haute

### Skip — OBLIGATOIRE

- **Toutes sous-pages** (`parent.type == "page_id"` ou `parent.type == "database_id"`) — héritent des connexions du parent, inutile
- Pages templates n8n marketplace (parent DB `2da01e69`, `2e201e69`, `2d801e69`, `2ff01e69`)
- Pages déjà traitées (check fichier état)
- Pages archivées (`is_archived: true`)

> **Règle absolue** : si `parent.type != "workspace"` → SKIP, sans exception.

---

## §2 — Outils requis

```
ToolSearch query: "select:mcp__notion__API-post-search,mcp__notion__API-retrieve-a-page"
ToolSearch query: "claude-in-chrome"  # tous tools Chrome MCP
```

Chrome MCP doit être actif. Vérifier `mcp__Claude_in_Chrome__list_connected_browsers` avant démarrer.

---

## §3 — Workflow

### Phase A : Construction liste pages cibles

**Note** : l'API Notion renvoie uniquement les pages où l'intégration est déjà active (biais). Pour avoir TOUTES les pages racines → utiliser Chrome MCP sidebar scroll (voir note §9).

1. `API-post-search` filter `object=page` sort `last_edited_time desc` page_size 100
2. Filtrer côté client :
   - **GARDER** : `parent.type == "workspace"` uniquement (pages racines)
   - **REJETER** : `parent.type == "page_id"` — sous-pages = SKIP sans exception
   - Exclure parents dans liste templates n8n (voir §1)
   - Exclure `is_archived`
3. Paginer si `has_more` jusqu'à liste complète
4. **Espaces d'équipe en premier** : trier pour traiter les teamspaces partagés avant les pages privées
5. Sauver liste dans `state.json` (voir §5)

### Phase B : Boucle Chrome MCP par page (workflow UI VALIDÉ 2026-05-03)

**Important** : interface Notion de Florent en **FRANÇAIS**. Bouton "Share" = "Partager".

**Important** : nom exact intégrations = **"Florent's"** (avec apostrophe) + **"Make & n8n"**. PAS "Florent" simple.

**Note** : Notion modal "Partager" = invitations utilisateurs/emails seulement. Connexions intégrations = ailleurs (menu Actions).

Pour chaque page non-traitée :
1. `navigate` URL = `https://www.notion.so/<page_id_sans_tirets>`
2. `wait 4s` (Notion long à charger, skeleton placeholder d'abord)
3. `resize_window` 1400x900 si pas fait (toolbar pas visible si window trop petite)
4. `hover` top-right `[1300, 25]` pour révéler toolbar (icônes cachées par défaut)
5. `find` query="More options menu (three dots, ellipsis)" → ref bouton "Actions" (⋯)
6. Click bouton Actions
7. Scroll dans menu (5 ticks) — "Connexions" caché en bas
8. Click "Connexions" → sous-menu "Connexions actives" s'ouvre à droite
9. **Vérifier état actuel** :
   - Liste affiche connexions déjà actives (ex: "Make & n8n", "Florent's", "Dust")
   - Si "Florent's" ET "Make & n8n" déjà présents → page = `done`, skip
   - Si manque une ou les 2 → click "+ Ajouter une connexion"
10. Modal recherche connexion → tape nom exact → click résultat
11. Répéter pour 2e intégration si nécessaire
12. Press Escape pour fermer
13. MAJ `state.json` : page_id → status `done`, timestamp + connexions ajoutées
14. Page suivante

### Phase C : Vérification finale (optionnel)

Pour échantillon 5 pages aléatoires : `API-retrieve-a-page` → vérifier accès OK (pas 404 → intégration fonctionne).

---

## §4 — Pause intelligente (avant compactage)

**Surveillance contexte continu** : avant chaque page Chrome MCP, estimer contexte.

Seuils :
- < 70% : continue normal
- 70-85% : ralentit, finalise page courante puis check
- > 85% : **STOP IMMÉDIAT** — sauve état, spawn chip handoff

### Mécanisme handoff

Quand seuil > 85% atteint :

1. Finir page en cours (jamais laisser page mid-Share)
2. MAJ `state.json` complet (pages done, pending, current=null)
3. `mcp__ccd_session__spawn_task` avec :

```
Title: Reprend connexion intégrations Notion
TLDR: Continue ajout intégrations "Florent" + "Make & n8n" sur pages parent Notion. État repris depuis state.json.
Prompt:
/notion-connect-integrations resume

État précédent dans : ~/.claude/skills/notion-connect-integrations/state.json
- Pages done : N1
- Pages pending : N2
- Dernière page traitée : <id> à <timestamp>

Reprends Phase B sur première page pending. Même seuil 85% pour pause.
```

4. Annoncer à Florent : *"Compactage approche. Chip handoff créé. Reprise propre disponible."*

---

## §5 — État persistant

Fichier : `~/.claude/skills/notion-connect-integrations/state.json`

Format :
```json
{
  "started_at": "2026-05-03T14:00:00Z",
  "last_updated": "2026-05-03T14:35:00Z",
  "total_pages": 87,
  "pages_done": 23,
  "pages_pending": 64,
  "pages": [
    {"id": "34c01e69...", "title": "HUB Florent", "last_edited": "2026-04-24", "status": "done", "completed_at": "2026-05-03T14:05:00Z"},
    {"id": "19201e69...", "title": "Prospection", "last_edited": "2025-11-27", "status": "pending"},
    {"id": "abc...", "title": "X", "last_edited": "2025-09-10", "status": "skipped", "reason": "archived"}
  ],
  "integrations_added": ["Florent", "Make & n8n"]
}
```

Statuts pages : `pending` / `done` / `skipped` / `error`.

### Reprise

Si invocation = `resume` → lire state.json, sauter pages `done`/`skipped`, reprendre première `pending`.

---

## §6 — Gestion erreurs

| Erreur | Action |
|--------|--------|
| Page chargement timeout Chrome | Retry 1× max, sinon `status: error` + raison |
| Bouton Share introuvable (UI Notion changée) | STOP, demander Florent (UI peut-être différente) |
| Intégration "Florent" pas trouvée dans dropdown | Demander Florent (peut-être renommée) |
| Page 404 (supprimée entre scan et traitement) | `skipped` raison `not_found` |
| Modal "share with workspace" inattendu | Décliner (juste add connection, pas share workspace) |

**Ne jamais** : continuer après 3 erreurs consécutives → STOP, rapport Florent.

---

## §7 — Démarrage session

1. Charger outils (§2)
2. Vérifier Chrome MCP connecté + Florent loggé Notion (`list_connected_browsers`)
3. Si invocation = `resume` → lire state.json, sinon Phase A nouveau scan
4. Confirmer à Florent : *"N pages cibles trouvées. Démarre boucle. Pause auto à 85% contexte."*
5. Phase B boucle
6. Si pause → spawn chip + stop
7. Si fini → résumé : N done, N skipped, N erreurs

---

## §8 — Anti-patterns

- ❌ Traiter pages sous-sous-niveau (héritent du parent → gaspille tokens)
- ❌ Continuer si UI Notion comportement bizarre (stop demander)
- ❌ Batch silencieux sans MAJ state.json à chaque page
- ❌ Laisser page mid-Share quand pause atteinte (toujours finir page courante)
- ❌ Ne pas annoncer chip handoff à Florent
- ❌ Re-traiter pages déjà `done` (check state.json strict)

---

## §9 — Patterns appris (auto-enrichi)

### Découvertes 2026-05-03 (test Pastry Chef)

- **Nom intégration "Florent" = "Florent's"** (apostrophe) — toujours utiliser nom exact
- **Notion UI = français** chez Florent — "Share" → "Partager", "Actions" menu, "Connexions"
- **Toolbar top-right cachée** par défaut — `hover [1300, 25]` pour révéler avant click
- **Window resize 1400x900 obligatoire** sinon toolbar coupée
- **Notion lent à charger** : `wait 4s` minimum après navigate (skeleton placeholders)
- **Connexions PAS dans modal Partager** — accessibles via menu Actions (⋯) → scroll → Connexions
- **API search "Make & n8n" filter biais** : ne renvoie QUE pages où intégration déjà présente. Donc la liste de 100 pages = pages où intégration "Make & n8n" est DÉJÀ active. Pour ajouter "Florent's" sur ces pages = utile. Pour découvrir pages SANS "Make & n8n" = besoin Chrome MCP scroll sidebar Notion.
- **Pages WORKSPACE top-level scan** : seulement 3 visibles via API (Pastry Chef, migration /wrapup-migration/, MON CRM). Cohérent avec biais ci-dessus.

### Format ajout

Quand pattern détecté (UI changement, sélecteur fragile, intégration renommée, etc.) :
- Enregistrer date + observation + workaround
- Pas modifier §1-§8 sans validation Florent
