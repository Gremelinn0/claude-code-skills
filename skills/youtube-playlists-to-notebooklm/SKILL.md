# Skill — YouTube Playlists → NotebookLM

## Quand utiliser ce skill

Déclenché quand l'utilisateur veut :
- Vérifier que les notebooks NotebookLM sont à jour avec les playlists YouTube
- Créer un nouveau notebook pour une playlist
- Ajouter les nouvelles vidéos d'une playlist à son notebook
- Nettoyer les vieilles vidéos obsolètes d'un notebook
- Découvrir et ajouter de nouvelles vidéos récentes et excellentes sur chaque sujet

---

## Setup requis

```bash
# Activer le venv notebooklm-py
source /c/Users/Administrateur/.notebooklm-venv/Scripts/activate

# Toujours préfixer les commandes notebooklm avec :
PYTHONIOENCODING=utf-8 notebooklm <commande>
```

Auth stockée dans `~/.notebooklm/storage_state.json`. Si expirée → relancer le login Playwright (voir skill `notebooklm`).

---

## Mapping complet Playlists → Notebooks

### 📋 Règle de nommage
- 1 playlist = 1 notebook (sauf fusions explicites ci-dessous)
- Notebook title = nom clair en français ou anglais cohérent avec le thème
- Les notebooks sont destinés au projet **Vente et Marketing** de Florent

---

### 🗺️ Table de référence

| Playlist YouTube | ID Playlist | Notebook NLM | ID NLM | Statut |
|---|---|---|---|---|
| Claude Code | PLLsnm64NWGpbIRL-8Swoh7m2hPoJ4cXFt | Claude Code | 803ef0c5-fcb7-46a2-8323-5df8ef06107f | ✅ Synced (44 sources) |
| Google Antigravity | PLLsnm64NWGpZ13PFqQpKIe9ypWononpw1 | Google Antigravity | ca59a862-df60-4469-a587-8bc85f5eba86 | ✅ Synced (16 sources, doublon supprimé) |
| n8n | PLLsnm64NWGpbaT43ucZJbkAb2nrkjJ_ce | n8n | c13d2e19-0edb-46e9-a793-a5271c362c13 | ✅ Synced (6 sources) |
| Web Apps & SaaS *(ex: WebbApp/n8n...)* | PLLsnm64NWGpZWFgmBUdI8M91uhwQTntBO | Web Apps & SaaS | 53018aaa-3c47-4b62-b50d-ac672d4a65f5 | ✅ Synced (15 sources) |
| Supabase vs Convex | PLLsnm64NWGpZFtIfclNWtRNxnakI-LelV | *(merge dans Web Apps & SaaS)* | 53018aaa-3c47-4b62-b50d-ac672d4a65f5 | ✅ Mergé |
| Vente BtoB | PLLsnm64NWGpZJfiDKZJPAoNGHwlkwlGmr | Vente BtoB | 15f8d60f-094d-4394-bb6f-ee0fbc4697ca | ✅ Synced (10 sources) |
| Prospection BtoB | PLLsnm64NWGpYxmUdbdY5fR6hJ_1SxekHO | Prospection BtoB | a527864c-93ad-4ae8-aa18-7bb040e9e451 | ✅ Synced (19 sources) |
| Vente BtoB + Prospection BtoB | *(les deux)* | Sales & Prospection BtoB | 6ec74243-102d-4bf6-abf7-3eb5885fc0ff | ✅ Synced (29 sources) |
| Website | PLLsnm64NWGpaOF1Bb4Qg5G9FQmDztSHbg | Web Design | 67d9ed17-994e-40fb-b0b2-5508ee3187e9 | ✅ Synced (9 sources) |
| WebSite | PLLsnm64NWGpZcPzVP6CY35KV4CY4-VLic | *(merge dans Web Design)* | 67d9ed17-994e-40fb-b0b2-5508ee3187e9 | ✅ Mergé |
| CONTENT / GROWTH PRODUCT | PLLsnm64NWGpbKgF0ymY1qvsK8ljvU9Ava | LinkedIn Content Bank | 787244d8-f1ed-4742-80c9-12a3b8fe47e6 | ✅ Synced (9 sources) |
| GROWTH | PLLsnm64NWGpaCwjXdshveRI3MWCOfetSq | *(merge dans LinkedIn Content Bank)* | 787244d8-f1ed-4742-80c9-12a3b8fe47e6 | ✅ Mergé |
| Agent IA (Products) | PLLsnm64NWGpY_oTJC1QbR0KBdt8naiapk | Formation Agents IA | 720028d5-e57e-4604-b5ec-3af59dd2bf49 | ✅ Synced (33 sources) |
| Agence IA | PLLsnm64NWGpYTpDZ9XmjeZBlSJO-SSz_4 | Agence IA | 7be36abd-3675-4ed3-b148-97800e3ef097 | ✅ Synced (1 source) |
| Présentation / Offre | PLLsnm64NWGpamIhNrHNKUFS5_KCJ9TjhV | Présentation & Offre | b996f3b7-8090-4349-a24e-d07ede420364 | ✅ Synced (5 sources) |
| Entrepreneuriat *(ex: Y.combPitchDeck)* | PLLsnm64NWGpYZnug7H6eY4fKgOoB13q4T | Entrepreneuriat | a4006a1a-7351-496c-8d31-1396db00e376 | ✅ Synced (1 source) |
| OpenClaw | PLLsnm64NWGpZB6f7vAHJxe4I07b2CZyKn | IA Locale | a57d1f3a-ca5c-412f-a445-9076aaf8b0a3 | ⚠️ Playlist vide/privée (0 sources) |
| ADHD | PLLsnm64NWGpbCvaEkbjP0_VJlGGZxW51B | ADHD | 0a2a683c-23eb-4540-9079-90926ee88b7f | ✅ Synced (1 source) |
| My Youtube channel | PLLsnm64NWGpbAKxQMLga_kbEgv27f6u1U | *(à clarifier)* | — | ❓ À décider avec Florent |
| Posts | PLLsnm64NWGpZcgUAxSBnFZ-QBwIUoi6ir | *(à clarifier)* | — | ❓ À décider avec Florent |

---

## Workflow principal — Vérification complète

### Étape 1 : Récupérer les vidéos de la playlist YouTube

```javascript
// Dans Chrome MCP (tab YouTube) — extraire toutes les vidéos d'une playlist
// Navigation : https://www.youtube.com/playlist?list=PLAYLIST_ID
// Puis JS :
const items = document.querySelectorAll('ytd-playlist-video-renderer');
const videos = Array.from(items).map(el => {
  const a = el.querySelector('a#video-title');
  return {
    title: a?.textContent?.trim(),
    url: 'https://www.youtube.com' + a?.getAttribute('href')?.split('&')[0]
  };
}).filter(v => v.title && v.url);
JSON.stringify(videos);
```

Ou via yt-dlp (plus fiable, batch) :
```bash
yt-dlp --flat-playlist --dump-json \
  "https://www.youtube.com/playlist?list=PLAYLIST_ID" \
  | python3 -c "import sys,json; [print(json.loads(l)['url'] + ' | ' + json.loads(l)['title']) for l in sys.stdin]"
```

### Étape 2 : Récupérer les sources actuelles du notebook

```bash
source /c/Users/Administrateur/.notebooklm-venv/Scripts/activate
PYTHONIOENCODING=utf-8 notebooklm use NOTEBOOK_ID
PYTHONIOENCODING=utf-8 notebooklm source list --json
```

### Étape 3 : Comparer — nouvelles vidéos à ajouter

Comparer les titres/URLs entre la playlist et les sources NLM.
- Vidéos dans playlist mais pas dans NLM → **ajouter**
- Sources NLM sans correspondance dans playlist → **vérifier si obsolètes**

### Étape 4 : Ajouter les nouvelles vidéos

```bash
PYTHONIOENCODING=utf-8 notebooklm source add "https://youtube.com/watch?v=VIDEO_ID"
PYTHONIOENCODING=utf-8 notebooklm source wait SOURCE_ID
```

**En batch :**
```bash
while IFS= read -r url; do
  echo "Adding: $url"
  PYTHONIOENCODING=utf-8 notebooklm source add "$url"
  sleep 2  # éviter rate limiting
done < urls_to_add.txt
```

---

## Workflow — Nettoyage des vieilles vidéos

**Objectif :** Supprimer les sources obsolètes (vidéos trop anciennes, remplacées, ou hors sujet) pour garder le notebook focalisé sur le contenu récent et excellent.

### Critères de nettoyage
1. **Date** : Vidéo datant de plus de 18 mois sur un sujet qui évolue vite (Claude Code, Antigravity, n8n...)
2. **Doublon** : Même titre ou même contenu en double → garder le plus récent
3. **Remplacé** : Une meilleure vidéo sur le même sujet existe dans la playlist → supprimer l'ancienne
4. **Hors sujet** : Source qui ne correspond plus au thème du notebook

### Commandes

```bash
# Lister les sources avec leur date
PYTHONIOENCODING=utf-8 notebooklm source list --json | python3 -c "
import sys, json
d = json.load(sys.stdin)
for s in d['sources']:
    print(f\"{s['index']:2}. [{s['created_at'][:10]}] {s['title']}\")
"

# Supprimer une source (demander confirmation d'abord !)
# ATTENTION : action destructive — TOUJOURS montrer la liste et demander validation
PYTHONIOENCODING=utf-8 notebooklm source delete SOURCE_ID
```

**Règle de sécurité :** Ne jamais supprimer sans montrer la liste des sources candidates à la suppression et attendre validation explicite de Florent.

---

## Workflow — Découverte de nouvelles vidéos

**Objectif :** Trouver les meilleures vidéos récentes (< 6 mois) sur chaque sujet et les ajouter au notebook.

### Méthode 1 — Via YouTube search (Chrome MCP)

```javascript
// Rechercher les vidéos récentes sur un sujet
// URL : https://www.youtube.com/results?search_query=QUERY&sp=EgIIAw%3D%3D
// (sp=EgIIAw == filtre "Ce mois-ci")
// Extraire les résultats et sélectionner les plus pertinents (vues, date, pertinence)
```

### Méthode 2 — Via yt-dlp search

```bash
# Chercher les 10 meilleures vidéos récentes sur un sujet
yt-dlp "ytsearch10:claude code 2026" --dump-json --skip-download \
  | python3 -c "
import sys, json
for line in sys.stdin:
    v = json.loads(line)
    print(f\"{v['upload_date']} | {v['view_count']:>8} vues | {v['title']}\")
"
```

### Critères de sélection
- Vidéo récente (< 6 mois de préférence)
- Bon ratio vues/date de publication
- Canal reconnu dans le domaine
- Contenu non redondant avec ce qui est déjà dans le notebook

---

## Procédure complète — Sync d'un notebook

```
1. notebooklm use NOTEBOOK_ID
2. Récupérer vidéos playlist via yt-dlp --flat-playlist
3. notebooklm source list → comparer
4. Ajouter les manquantes (notebooklm source add)
5. Identifier les potentiellement obsolètes → montrer à Florent → supprimer si validé
6. Rechercher nouvelles vidéos récentes → proposer à Florent → ajouter si validé
7. notebooklm source wait (attendre que tout soit ready)
```

---

## Notebooks NLM existants (hors playlists YouTube)

Ces notebooks existent déjà mais ne viennent pas des playlists YouTube. Les garder tels quels :

| Notebook | ID | Note |
|---|---|---|
| Mastering Local AI (Gemma 4) | d0112802 | Correspond potentiellement à IA Locale / OpenClaw |
| Architectural Foundations Voice AI | e2cb1b8d | SpeakApp related |
| Mastering Professional Web Design | 103a33cb | Pourrait merger dans Web Design |
| Agentic Workflow | 2c0b03f9 | Vérifier si redondant avec n8n/Agent IA |
| Lovable | b14fc32e | Outil no-code |
| Lovable Tips | 4dcf58f6 | Merger avec Lovable ? |
| Sell AI Agents / Stratégie | a9a27980 | Vérifier si redondant avec Agence IA |
| AGENT POST YOUTUBE | 1e1abead | LinkedIn content ? Vérifier |
| Formation Agents IA | 720028d5 | Match avec playlist "Agent IA (Products)" |
| Benchmark Agences IA | b09547ef | Garder tel quel |
| Email Marketing (Hormozi) | 73b7a289 | Garder tel quel |
| "" (titre vide) | 5a57b3bc | À renommer ou supprimer |

---

## Sauvegarde état — Mémoire

Après chaque session de sync, mettre à jour :
`C:/Users/Administrateur/.claude/projects/C--Users-Administrateur-PROJECTS-navigateur/memory/youtube_notebooks_state.md`

Format :
```
## État sync YouTube → NotebookLM
Dernière mise à jour : DATE

| Notebook | ID | Nb sources | Dernière sync | Playlists sources |
|---|---|---|---|---|
| Claude Code | 803ef0c5 | 6 | 2026-04-16 | PLLsnm64NWGpbIRL-8Swoh7m2hPoJ4cXFt |
...
```

---

## Règles importantes

1. **Un notebook = une thématique cohérente** — pas de mélange de sujets non liés
2. **Toujours vérifier avant de créer** : `notebooklm list --json` pour éviter doublons
3. **Nettoyage = validation Florent** — ne jamais supprimer sans confirmation
4. **Nouvelles vidéos = proposer avant d'ajouter** si non issues directement de la playlist
5. **Rate limiting Google** : attendre 2-3s entre chaque `source add`, max 10/min
6. **Encodage Windows** : toujours préfixer `PYTHONIOENCODING=utf-8`
