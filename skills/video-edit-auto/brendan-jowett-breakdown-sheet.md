# Brendan Jowett — Breakdown Sheet : How I Fully Automated My Video Editing

**Source :** https://www.skool.com/brendan/classroom/0ccaf2f5?md=33d1ddfad5b945c9983abe422f60a555  
**Vidéo YouTube :** https://youtu.be/G0EH0xdy2-E  
**Extrait le :** 2026-04-21

---

## How I Edit Videos

### The Stack

- **Remotion** — a React-based video framework. Every graphic, animation, and sequence is written as a React component rendered at 30fps
- **FFmpeg** — for extracting audio from video files
- **OpenAI Whisper API** — transcribes the audio and gives me word-level timestamps so I know exactly when you say each word

---

### The Process

1. **Transcribe** — I extract audio from your video, send it to the Whisper API, and get back a timestamped transcript with per-word timing

2. **Map graphics to speech** — I read through the transcript and identify key moments (topic introductions, stats, lists, comparisons) that benefit from a visual graphic. I use the word-level timestamps to place each graphic exactly when you start talking about that topic

3. **Build the composition** — I write a React/TypeScript file that layers your original video as the background, then overlays full-screen animated graphics at the right timestamps using `<Sequence>` components. Each graphic uses shared components (lists, comparison cards, process flows, etc.) with consistent branding

4. **Preview in Remotion Studio** — the studio runs locally and lets you scrub through the timeline, see every graphic, and give me feedback. I adjust timing, content, and styling based on what you say

5. **Render** — when you're happy, I run the Remotion CLI to render the final video as an MP4

---

### What I can control

- Graphic type, content, and styling (fonts, colors, icons, layout)
- Exact timing (when each graphic appears and how long it stays)
- Sound effects synced to animations
- Background music with volume control
- Ad insertion at natural break points
- Both landscape (16:9) and vertical (9:16) formats

---

## Notes d'analyse (l'utilisateur / Claude)

**Ce que Brendan fait que Descript ne fait PAS :**
- Motion graphics / animations synchronisées sur la parole (pas juste des sous-titres)
- Overlays graphiques full-screen (listes, cartes comparaison, process flows)
- Sound effects + musique de fond avec volume control
- Insertion de publicités sur les pauses naturelles

**Ce que Descript fait que ce pipeline ne fait PAS :**
- Suppression silences / filler words / "je coupe"
- Nettoyage audio (Studio Sound)
- Correction de l'enregistrement brut

**Conclusion workflow idéal pour l'utilisateur :**
1. Enregistrer avec Tella ou Descript recorder
2. Nettoyer dans Descript (silences, erreurs, filler words) → exporter MP4 propre
3. Passer le MP4 propre dans le pipeline Remotion+Whisper → motion graphics synchronisées

**Stack technique requis :**
- Node.js (Remotion)
- Python (FFmpeg + Whisper API calls)
- Clé API OpenAI (Whisper)
- Remotion CLI : `npx remotion render`
