# Skill — Skool Community Scraper

## Quand utiliser ce skill

Déclenché quand l'utilisateur veut :
- Scraper une communauté Skool (classroom, leçons, fichiers)
- Récupérer le contenu d'une Skool (descriptions, vidéos, ressources)
- Extraire les assets d'une Skool pour les indexer ou les importer (Supabase, Notion, etc.)

---

## Contexte — Comment fonctionne Skool

Skool est une app Next.js. Toutes les données de la page sont dans `window.__NEXT_DATA__` côté client.

**Deux communautés déjà scrapées dans le Marketplace :**
- `<skool-community-slug>` — 514 leçons, terminé (`%USERPROFILE%\PROJECTS\<your-projects>\1- Agence & Content\Skool Scraper\data\<skool-community-slug>\`)
- `ai-automation-society-plus` (Nate Herk) — 480 leçons, partiellement terminé

**Stack :**
- Chrome MCP (`mcp__Claude_in_Chrome__*`) pour naviguer et lire le DOM
- Python scripts dans le dossier Skool Scraper pour sauvegarder les JSON
- `window.AwsWafIntegration.fetch` pour télécharger les fichiers Skool directement

---

## Workflow — Scraper une communauté Skool

### Étape 1 — Discovery : lister tous les chapitres

Naviguer vers `https://www.skool.com/<slug>/classroom`.

Extraire la structure via JavaScript dans la console :
```javascript
// Récupérer les données Next.js
const nd = window.__NEXT_DATA__?.props?.pageProps;

// Skool V1 (Jack) — renderData.course
const course = nd?.renderData?.course || nd?.course;

// Chapitres et leçons
const chapters = course?.children || [];
chapters.forEach((ch, i) => {
  console.log(`Ch${i+1}: ${ch.name} (${ch.children?.length || 0} leçons)`);
});
```

### Étape 2 — Extraire les leçons d'un chapitre

Pour chaque chapitre, naviguer vers son URL et extraire :
```javascript
const nd = window.__NEXT_DATA__?.props?.pageProps;
const course = nd?.renderData?.course || nd?.course;

// Leçons du chapitre courant
const lessons = course?.children || [];
const result = lessons.map(lesson => ({
  lesson_id: lesson.id,
  title: lesson.name,
  slug: lesson.slug,
  url: `https://www.skool.com/${SLUG}/classroom/${CHAPTER_SLUG}?md=${lesson.id}`,
  has_video: !!lesson.videoUrl,
  video_link: lesson.videoUrl || null,
  resources: lesson.attachments || []
}));
console.log(JSON.stringify(result, null, 2));
```

### Étape 3 — Scraper le contenu d'une leçon

Pour chaque leçon, naviguer vers son URL et extraire :
```javascript
// Corps de la leçon
const bodyEl = document.querySelector('[data-testid="post-body"]') 
            || document.querySelector('.post-body')
            || document.querySelector('.lesson-content');
const overview = bodyEl?.innerText?.trim() || '';

// iframes vidéo (YouTube, Vimeo, etc.)
const iframes = [...document.querySelectorAll('iframe')].map(f => f.src).filter(Boolean);

// Liens de téléchargement externes
const dlLinks = [...document.querySelectorAll('a[href]')]
  .filter(a => /drive\.google|dropbox|notion\.so|loom\.com/i.test(a.href))
  .map(a => ({ text: a.innerText.trim(), href: a.href }));

// Fichiers Skool natifs (bouton de téléchargement)
const skoolFiles = [...document.querySelectorAll('[data-file-name], .attachment-name')]
  .map(el => el.textContent.trim()).filter(Boolean);

console.log(JSON.stringify({ overview, iframes, dlLinks, skoolFiles }));
```

Sauvegarder avec `save_scrape.py` :
```bash
python save_scrape.py <path_to_lesson.json> '<json_result>'
```

### Étape 4 — Télécharger les fichiers Skool natifs

Les fichiers Skool utilisent l'API `api2.skool.com` avec AWS WAF :
```javascript
async function downloadSkoolFile(fileId, fileName) {
  const signedUrl = await window.AwsWafIntegration.fetch(
    'https://api2.skool.com/files/' + fileId + '/download-url',
    { method: 'POST', credentials: 'include' }
  ).then(res => res.text());
  
  const blob = await fetch(signedUrl.trim()).then(res => res.blob());
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}
```

**Important** : attendre ~2s entre chaque téléchargement pour ne pas se faire bloquer.

---

## Structure des données — JSON par leçon

```json
{
  "url": "https://www.skool.com/<slug>/classroom/<chapter_slug>?md=<lesson_id>",
  "community": "<slug>",
  "chapter": "Vault",
  "chapter_number": 7,
  "section": "Social Media",
  "lesson_index": 1,
  "title": "Fire Your $100k Social Agency",
  "body_text": "Texte complet de la page...",
  "video_urls": ["https://youtube.com/watch?v=..."],
  "download_links": [{"text": "Blueprint", "href": "https://drive.google.com/..."}],
  "skool_files": ["Upload me to n8n.json", "transcript.txt"],
  "has_video": true,
  "has_downloads": true,
  "scrape_status": "done",
  "scraped_at": "2026-04-15T10:00:00Z"
}
```

---

## Structure des dossiers

```
data/
  <community-slug>/
    _summary.csv          # Vue d'ensemble toutes leçons
    _progress.json        # Statut par chapitre
    chapter-01/
      lesson-001-<slug>.json
      lesson-002-<slug>.json
      files/
        lesson-001-<slug>/
          blueprint.json
          transcript.txt
    chapter-02/
      ...
```

---

## Outils disponibles dans le Marketplace

Dossier : `%USERPROFILE%\PROJECTS\<your-projects>\1- Agence & Content\Skool Scraper\`

| Fichier | Rôle |
|---------|------|
| `save_scrape.py` | Sauvegarder le résultat d'un scrape dans un JSON leçon |
| `watcher.py` | Surveiller le dossier Downloads et déplacer les fichiers automatiquement |
| `_devtools_missing_files.js` | Script DevTools pour télécharger des fichiers manquants en batch |
| `SUIVI_SCRAPING.md` | Template de suivi par chapitre |
| `INSTRUCTIONS_AITS.md` | Instructions complètes pour une communauté (template réutilisable) |

---

## Règles importantes

1. **Ne jamais toucher aux données déjà scrapées** sans instruction explicite
2. **Toujours vérifier** `_progress.json` avant de commencer pour éviter les doublons
3. **Délai 2s minimum** entre les téléchargements de fichiers Skool
4. **Chrome MCP** pour naviguer (pas computer-use — Skool est une web app)
5. Si la communauté utilise `renderData` vs `course` → tester les deux (`AITS+ = renderData`)
6. Les chapitres "locked" → ne pas tenter de scraper, les marquer `locked` dans `_progress.json`
