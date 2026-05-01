# Skill — YouTube Scraper

## Quand utiliser ce skill

Déclenché quand l'utilisateur veut :
- Scraper des vidéos YouTube (métadonnées, transcripts, commentaires)
- Extraire le transcript d'une vidéo pour l'analyser ou l'ingérer
- Récupérer les données d'une chaîne (vidéos, stats, descriptions)
- Automatiser la récupération de contenu YouTube pour un pipeline de contenu

---

## Méthodes disponibles

### Méthode 1 — Transcript via Chrome MCP (sans API key)

**Avantage** : gratuit, pas de quota, fonctionne pour toute vidéo avec sous-titres.

```javascript
// Sur une page YouTube watch?v=VIDEO_ID
// Ouvrir les sous-titres, puis extraire le transcript

// Méthode 1 : via ytInitialData (page YouTube)
const data = window.ytInitialData;
const captions = data?.playerOverlays?.playerOverlayRenderer
  ?.decoratedPlayerBarRenderer?.decoratedPlayerBarRenderer
  ?.playerBar?.multiMarkersPlayerBarRenderer?.markersMap;

// Méthode 2 : via l'API transcript YouTube (endpoint public)
const videoId = new URLSearchParams(location.search).get('v');
const transcriptUrl = `https://www.youtube.com/api/timedtext?lang=fr&v=${videoId}&fmt=json3`;
const resp = await fetch(transcriptUrl);
const data = await resp.json();
const text = data.events
  ?.filter(e => e.segs)
  ?.map(e => e.segs.map(s => s.utf8).join(''))
  ?.join(' ');
console.log(text);
```

### Méthode 2 — yt-dlp (outil CLI, transcripts + métadonnées)

**Prérequis** : `yt-dlp` installé (`pip install yt-dlp` ou binaire)

```bash
# Télécharger le transcript (sans la vidéo)
yt-dlp --write-sub --sub-lang fr --skip-download -o "%(title)s" "https://youtube.com/watch?v=VIDEO_ID"

# Métadonnées JSON complètes
yt-dlp --dump-json "https://youtube.com/watch?v=VIDEO_ID" > video_metadata.json

# Toutes les vidéos d'une chaîne (métadonnées uniquement)
yt-dlp --dump-json "https://www.youtube.com/@CHANNEL_HANDLE/videos" > channel_videos.json

# Sous-titres auto-générés
yt-dlp --write-auto-sub --sub-lang fr --skip-download "URL"
```

### Méthode 3 — YouTube Data API v3

**Prérequis** : clé API dans `YOUTUBE_API_KEY` env var.

```python
import requests, os

API_KEY = os.environ['YOUTUBE_API_KEY']

def get_video_details(video_id):
    url = f"https://www.googleapis.com/youtube/v3/videos"
    params = {
        'key': API_KEY,
        'id': video_id,
        'part': 'snippet,statistics,contentDetails'
    }
    return requests.get(url, params=params).json()

def get_channel_videos(channel_id, max_results=50):
    url = "https://www.googleapis.com/youtube/v3/search"
    params = {
        'key': API_KEY,
        'channelId': channel_id,
        'part': 'snippet',
        'order': 'date',
        'maxResults': max_results,
        'type': 'video'
    }
    return requests.get(url, params=params).json()

def get_video_comments(video_id, max_results=100):
    url = "https://www.googleapis.com/youtube/v3/commentThreads"
    params = {
        'key': API_KEY,
        'videoId': video_id,
        'part': 'snippet',
        'maxResults': max_results,
        'order': 'relevance'
    }
    return requests.get(url, params=params).json()
```

### Méthode 4 — youtube-transcript-api (Python, sans API key)

```bash
pip install youtube-transcript-api
```

```python
from youtube_transcript_api import YouTubeTranscriptApi

# Transcript d'une vidéo
transcript = YouTubeTranscriptApi.get_transcript('VIDEO_ID', languages=['fr', 'en'])
text = ' '.join([t['text'] for t in transcript])

# Toutes les langues disponibles
transcripts = YouTubeTranscriptApi.list_transcripts('VIDEO_ID')
for t in transcripts:
    print(f"{t.language_code} — {'auto' if t.is_generated else 'manual'}")
```

---

## Workflow recommandé selon le besoin

### "Je veux le transcript d'une vidéo"
1. Essayer `youtube-transcript-api` (plus rapide, sans browser)
2. Si pas de transcript → yt-dlp avec `--write-auto-sub`
3. En dernier recours → Chrome MCP sur la page YouTube

### "Je veux les métadonnées d'une chaîne"
1. `yt-dlp --dump-json` sur l'URL `/videos` de la chaîne
2. Parser le JSON (titre, description, vues, date, durée, id)

### "Je veux les commentaires d'une vidéo"
1. YouTube Data API v3 (méthode 3) — le plus fiable
2. Sans API key → Chrome MCP + scroll infini (lent)

### "Je veux scraper en batch (50+ vidéos)"
1. Créer une liste d'IDs vidéo (`video_ids.txt`)
2. Boucle `yt-dlp --dump-json` ou API v3 avec pagination
3. Sauvegarder en JSON par vidéo dans `data/<channel>/`

---

## Structure des données — JSON par vidéo

```json
{
  "video_id": "dQw4w9WgXcQ",
  "url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
  "channel": "Rick Astley",
  "channel_id": "UCuAXFkgsw1L7xaCfnd5JJOw",
  "title": "Never Gonna Give You Up",
  "description": "...",
  "published_at": "2009-10-25T06:57:33Z",
  "duration_seconds": 212,
  "views": 1500000000,
  "likes": 15000000,
  "transcript": "We're no strangers to love...",
  "transcript_language": "en",
  "transcript_auto_generated": false,
  "tags": ["rick astley", "pop"],
  "scraped_at": "2026-04-15T10:00:00Z"
}
```

---

## Assets Make.com disponibles dans le Marketplace

Dossier : `%USERPROFILE%\PROJECTS\<your-projects>\1- Agence & Content\Skool Scraper\data\<skool-community-slug>\`

Workflows Make.com téléchargés (blueprints JSON) :
- `Youtube Comment Scraper 1:2.json` + `2:2.json` — scraper de commentaires YouTube
- `Viral Youtube 1:3.json` + `2:3` + `3:3` — pipeline de création de contenu viral
- `YouTube Translation Full Process.json` — traduction automatique de vidéos
- `YouTube Summariser Agent` — résumé automatique de vidéos

Pour les utiliser : importer dans Make.com via "Import Blueprint".

---

## Blueprints prompts disponibles

Dans les assets Skool (fichiers `.txt`) :
- `YouTube Transcript Code` — code Python pour extraire transcripts
- `YouTube Thumbnail Analysis Bot` — analyser les miniatures avec vision AI
- `YouTube Idea Generator` — générer des idées de vidéos depuis un transcript
- `Youtube 0CodeKit Transcript - Troubleshoot` — troubleshooting des transcripts
- `How to Scrape Youtube Video Comments` — guide complet

---

## Règles importantes

1. **youtube-transcript-api en premier** — pas de quota, pas de browser
2. **yt-dlp** pour les métadonnées en batch — le plus complet
3. **API YouTube v3** uniquement si quota disponible (10k units/jour gratuit)
4. **Ne pas télécharger les vidéos** sauf si explicitement demandé
5. **Respecter les rate limits** : max 10 requêtes/seconde sans API key
6. Stocker les résultats dans `data/<channel-slug>/` avec un JSON par vidéo
