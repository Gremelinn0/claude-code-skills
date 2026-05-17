# Skill â€” Montage VidÃ©o AutomatisÃ© avec Claude Code

## Quand utiliser ce skill

DÃ©clencher quand Florent veut :
- Nettoyer automatiquement une vidÃ©o de formation brute (screencast + webcam)
- Supprimer les silences, les "je coupe", les hÃ©sitations d'une vidÃ©o MP4
- Enrichir une vidÃ©o propre avec des animations / motion graphics
- Finaliser l'audio d'une vidÃ©o (nettoyage, mastering, loudness)
- Choisir entre les outils disponibles (Descript, Claude Design, Hyperframes, Remotion, Auphonic)

---

## Repos GitHub Ã  cloner automatiquement

**Au premier usage de ce skill, Claude Code doit cloner ces repos dans le projet actif :**

| Repo | URL | RÃ´le |
|---|---|---|
| Hyperframes (officiel HeyGen) | https://github.com/heygen-com/hyperframes | Moteur motion graphics HTML â†’ MP4 |
| Hyperframes Student Kit (Nate Herk) | https://github.com/nateherkai/hyperframes-student-kit | 12 projets vidÃ©o finis + 7 skills Claude Code auto-chargÃ©s |

**Commande de clone rapide :**

```bash
cd "<dossier projet>/tools/"
git clone --depth 1 https://github.com/nateherkai/hyperframes-student-kit.git
cd hyperframes-student-kit && npm install
npx hyperframes browser ensure        # tÃ©lÃ©charge Chromium headless (~100 MB)
npx hyperframes doctor                # vÃ©rifie Node, FFmpeg, Chrome
```

**Alternative "paste URL + explique"** (mÃ©thode recommandÃ©e par Jack Roberts pour dÃ©couvrir l'outil) :
> Coller cette URL dans une nouvelle session Claude Code :
> `https://github.com/heygen-com/hyperframes`
> Puis demander : *"Download this repo for me. In 5 bullet points, what are the coolest things it can do? Then edit example.mp4 in 3 different ways (name tag, captions, lower thirds)."*

---

## ModÃ¨les Claude recommandÃ©s â€” Ã©conomie de tokens

*(Conseil Jack Roberts, session 2026-04-21)*

| Phase | ModÃ¨le | Pourquoi |
|---|---|---|
| Setup initial, architecture du projet vidÃ©o, crÃ©ation de compositions complexes | **Opus 4.7** | Meilleur raisonnement pour poser la structure |
| Ã‰ditions ponctuelles (timing, couleurs, ajustements, ajout d'un block, captions) | **Sonnet 4.6** | 99% des cas â€” Opus 4.7 est "affamÃ©" en tokens (cf. Jack Roberts) |
| Rendu final / commandes shell / lint | **Sonnet 4.6** ou **Haiku** | TÃ¢ches mÃ©caniques, pas de crÃ©ativitÃ© requise |

Basculer de modÃ¨le en cours de session : `/model claude-sonnet-4-6` ou `/model claude-opus-4-7`.

---

## Pipeline complet validÃ© (session 2026-04-21)

### LES 3 CAS â€” NE PAS CONFONDRE

| Cas | Besoin | Outil |
|-----|--------|-------|
| CAS 1 | Nettoyer une vidÃ©o brute (silences, erreurs, "je coupe") | **Descript** |
| CAS 2 | Habiller une vidÃ©o propre (animations, textes, motion graphics) | **Claude Design, Hyperframes ou Remotion** |
| CAS 3 | Finaliser l'audio (nettoyage pro, mastering, loudness broadcast) | **Auphonic** (via API depuis Claude Code) |

---

## Guide d'enregistrement â€” bonnes pratiques

*(Sources : NotebookLM "FFmpeg+Whisper+Claude Code" + "Descript vs Tella vs Loom", validÃ©es 2026-04-21)*

### Avant d'enregistrer

1. **Micro de qualitÃ©** â€” rÃ©duit le travail de Studio Sound (moins d'Ã©cho Ã  corriger)
2. **Enregistrer directement dans Descript** si possible â€” transcription en temps rÃ©el, pas de fichier Ã  transfÃ©rer
3. **Encadrer uniquement la fenÃªtre app** â€” pas le bureau entier ni les autres apps (meilleure dÃ©tection OCR + clips plus propres)

### Pendant l'enregistrement

4. **RÃ©pÃ©ter la phrase ratÃ©e** plutÃ´t que dire "je coupe" â†’ Descript "Remove retakes" dÃ©tecte les rÃ©pÃ©titions et garde la meilleure prise automatiquement
5. **Laisser 2-4 secondes de silence** entre les prises â†’ "Shorten word gaps" les supprime en 1 clic
6. **Changer de scÃ¨ne pendant un silence** (raccourcis Descript ou OBS) â€” les transitions seront propres
7. **Ne pas stresser pour les "euh"** â€” "Remove filler words" les supprime tous en batch
8. **Enregistrer en plusieurs clips si c'est long** â†’ Claude Code peut les assembler avec le prompt Stitch (cf. section Prompts)

### Bonus Descript

- Un seul mot ratÃ© â†’ **Overdub** le remplace par synthÃ¨se vocale sans re-enregistrer
- Regard camÃ©ra â†’ **Eye Contact** (tÃ©lÃ©prompter intÃ©grÃ©) corrige la direction du regard
- Long enregistrement â†’ dÃ©couper en scÃ¨nes avec **"/"** dans la transcription (navigation rapide)
- Ordre de travail : **IA en premier** (Remove retakes â†’ Shorten gaps â†’ Remove fillers â†’ Studio Sound), puis corrections manuelles

### Ce qu'il ne faut PAS faire

- âŒ Dire "je coupe" (force une recherche manuelle dans la transcription)
- âŒ Enregistrer le bureau entier avec toutes les apps visibles
- âŒ S'arrÃªter pour corriger chaque erreur â€” finir la phrase, reprendre proprement, Descript gÃ¨re
- âŒ FFmpeg + Python pour le nettoyage (trop lent, aucun contrÃ´le visuel â€” confirmÃ© par Nate Herk + Sandy Lee)

---

## CAS 1 â€” Nettoyage screencast brut (besoin principal de Florent)

### Ã‰tape 0 : Enregistrement

**Option A â€” Enregistrer directement dans Descript (recommandÃ©e)**
Descript a un enregistreur intÃ©grÃ© qui capture Ã©cran + webcam + micro. Avantage majeur : la transcription se gÃ©nÃ¨re en temps rÃ©el pendant l'enregistrement. Pas de fichier Ã  transfÃ©rer.

**Option B â€” Tella puis import dans Descript**
Tella = bon pour les vidÃ©os courtes et soignÃ©es, systÃ¨me de mises en page visuelles, enregistrement par petits clips (Ã©vite de tout recommencer si erreur sur une section). Exporter en MP4 â†’ importer dans Descript.

**Ã€ Ã©viter : Loom**
Loom = outil de partage de liens vidÃ©o, pas d'Ã©dition post-enregistrement. Non adaptÃ© au montage lourd.

### Ã‰tape 1 : Nettoyage dans Descript

1. Importer le MP4 â†’ transcription automatique
2. **Template Descript** (Brendan Jowett) â€” appliquer via "Templates > Created by me" : *"Please remove all repeating sentences. Usually, the last repeated sentence is the correct one after all the mistakes."* Simple et efficace.
3. **"Remove retakes"** â€” l'IA dÃ©tecte les phrases rÃ©pÃ©tÃ©es, garde la meilleure prise
4. **"Shorten word gaps"** â€” trouver tous les gaps > **0.2 sec**, les raccourcir Ã  **0.2 sec** (Brendan) ou > 1-2 sec pour un rÃ©sultat plus naturel (Nate)
5. **"Remove filler words"** â€” supprime les "euh", "donc", hÃ©sitations
6. Pour les "je coupe" : chercher le texte dans la transcription â†’ sÃ©lectionner + touche Suppr. InstantanÃ©.
7. **"Studio Sound"** â€” nettoie l'audio en 1 clic (supprime l'Ã©cho, amÃ©liore le micro)
8. **Musique** (optionnel) : ajouter via Epidemic Sound dans Descript avant l'export (pas de copyright)
9. Exporter le MP4 propre

**Output : 2h de brut â†’ ~30 min propre, audio impeccable.**

### Pourquoi PAS Python + FFmpeg pour le nettoyage brut

Approche testÃ©e et abandonnÃ©e par Nate Herk et Sandy Lee (confirmÃ© par les 2 notebooks NotebookLM le 2026-04-21) :
- Trop lent, pas de contrÃ´le visuel
- Donner des timestamps Ã  FFmpeg ("coupe de 4 Ã  7 secondes") prend plus de temps que de le faire manuellement
- Sandy Lee : "tellement lente et frustrante" qu'elle est revenue aux outils dÃ©diÃ©s

---

## CAS 2 â€” Motion graphics / animations (sur vidÃ©o propre)

### PrÃ©requis : Transcription Whisper avec timestamps

**OBLIGATOIRE** pour les 2 options. Whisper transcrit la vidÃ©o mot par mot avec l'horodatage exact. Sans Ã§a, Claude ne sait pas synchroniser les animations avec la parole.

- Via Claude Code (il installe et exÃ©cute automatiquement)
- Via API OpenAI si whisper local ralentit la machine
- Via FFmpeg 8.1+ (Whisper intÃ©grÃ© nativement depuis aoÃ»t 2025)

### Option A â€” Claude Design (simple, web-based)

**C'est quoi :** l'app web Anthropic (comme Claude.ai) spÃ©cialisÃ©e animations HTML. Pas de code. Interface navigateur.

**Workflow :**
1. Aller sur Claude Design (app web Anthropic)
2. CrÃ©er un "Design System" : charger logo, couleurs, typo â†’ mÃ©morisÃ© pour toutes les vidÃ©os suivantes
3. Nouveau projet "Animation" â†’ donner le clip MP4 propre + transcription Whisper + description du style
4. Claude gÃ©nÃ¨re du HTML animÃ© (textes sync, graphiques, transitions)
5. Export : screen record le navigateur OU commande Claude Code pour render MP4 via ffmpeg

**Limite :** Claude Design ne peut pas "entendre" la vidÃ©o â€” la transcription Whisper est obligatoire.
**CoÃ»t :** inclus dans l'abonnement Anthropic.

### Option B â€” Hyperframes via Claude Code (plus puissant)

**ðŸ“Ž Repo Ã  cloner :** `https://github.com/heygen-com/hyperframes` (officiel HeyGen)
**ðŸ“Ž Kit de starters :** `https://github.com/nateherkai/hyperframes-student-kit` (12 projets vidÃ©o finis + 7 skills Claude Code)
**ðŸ“Ž ModÃ¨le recommandÃ© :** Opus 4.7 pour le setup initial, Sonnet 4.6 pour toutes les Ã©ditions ensuite

**C'est quoi :** outil open source (GitHub) que Claude Code pilote. HTML â†’ navigateur â†’ ffmpeg â†’ MP4. Plus de contrÃ´le que Claude Design.

**Workflow :**
1. Cloner le repo Hyperframes dans le projet Claude Code (VS Code)
2. Donner Ã  Claude Code : vidÃ©o + transcription Whisper avec timestamps
3. Claude Code gÃ©nÃ¨re des compositions HTML (animations, textes sync, graphiques)
4. Preview en local â†’ feedback prÃ©cis avec timestamps â†’ itÃ©rer
5. Render final : ffmpeg â†’ MP4

**Point clÃ© :** chaque itÃ©ration amÃ©liore le "studio". Au bout de 10 vidÃ©os, Claude connaÃ®t le style de Florent.
**CoÃ»t :** ~10% du plan $200/mois par projet vidÃ©o (beaucoup de tokens pour gÃ©nÃ©rer le HTML).
**Repo officiel :** https://github.com/heygen-com/hyperframes (HeyGen, sorti avril 2026, Apache 2.0)
**Installation :** 1 commande dans Claude Code â†’ skills `/hyperframes`, `/hyperframes-cli`, `/gsap` disponibles
**Kit Nate Herk :** https://github.com/nateherkai/hyperframes-student-kit (12 projets finis, bon point de dÃ©part)

---

## Statut d'intÃ©gration Hyperframes + Kit Nate Herk (2026-04-21)

### Ce qui EST dans ce skill

- âœ… Hyperframes rÃ©fÃ©rencÃ© comme Option B dans CAS 2 (motion graphics)
- âœ… URL du kit Nate Herk : `https://github.com/nateherkai/hyperframes-student-kit`
- âœ… Conclusions de Nate sur ses 60+ vidÃ©os
- âœ… Sa vidÃ©o 152k listÃ©e dans les sources

### Ce qui N'EST PAS fait (backlog)

- â³ Le kit clonÃ© localement â†’ en cours dans `PROJECTS/Vente et Marketing - ALL Compagnies/tools/hyperframes-student-kit/`
- â³ Les 7 slash commands Claude Code fournis dans le kit (Ã  activer aprÃ¨s clone)
- â³ Tester un des 12 projets finis (starter recommandÃ© : `claude-edit-intro`)

### Le repo contient-il un skill ?

**OUI â€” 7 skills Claude Code prÃªts Ã  l'emploi** dans `.claude/skills/` du kit :
- `/hyperframes` â€” crÃ©er/Ã©diter des compositions
- `/hyperframes-cli` â€” rÃ©fÃ©rence CLI (init, lint, preview, render)
- `/gsap` â€” animations GSAP (timelines, easing, stagger)
- `/hyperframes-registry` â€” catalog de blocks/components
- `/website-to-hyperframes` â€” transformer une URL en vidÃ©o
- `/make-a-video` â€” flow dÃ©butant end-to-end
- `/short-form-video` â€” playbook 9:16 talking-head

### Pertinence pour la phase 3 (motion graphics)

**OUI** â€” c'est exactement le use case CAS 2 (habiller une vidÃ©o propre avec motion graphics). Le kit livre 12 projets finis (shorts 9:16, landscape 16:9, product promos, lessons, brand hype) qu'on peut cloner/modifier.

### DiffÃ©rence clÃ© Remotion vs Hyperframes

| | Remotion (Brendan) | Hyperframes (Nate) |
|---|---|---|
| Stack | React + TypeScript | HTML + GSAP, pas de React |
| Preview | Remotion Studio | `npx hyperframes preview` (localhost) |
| Render | Node render Ã  30fps | Chromium headless + ffmpeg |
| Courbe | Plus propre si tu connais React | Plus simple si tu connais HTML/CSS |

### Plan d'implÃ©mentation (en cours)

1. **Cloner le kit** dans `PROJECTS/Vente et Marketing - ALL Compagnies/tools/hyperframes-student-kit/` (outil projet, pas global)
2. **Lire** `CLAUDE.md` + `MOTION_PHILOSOPHY.md` du repo (docs principales de Nate)
3. **Tester** sur `claude-edit-intro` (projet le plus lÃ©ger, brand minimal â€” bon starter)
4. **Ajouter** une section "Comment utiliser le kit" dans ce SKILL.md avec les commandes concrÃ¨tes
5. **Mettre Ã  jour** la page Notion mÃ©thodologie avec l'approche Hyperframes opÃ©rationnelle

**Source Skool :** https://www.skool.com/ai-automation-society/new-video-claude-just-changed-video-editing-forever
**VidÃ©o YouTube :** https://www.youtube.com/watch?v=ZNbgOhxhzXg (152k vues)

---

## Comment utiliser le kit Hyperframes (Ã©tape par Ã©tape)

### Installation â€” dÃ©jÃ  fait

**Kit clonÃ©** : `C:\Users\Utilisateur\PROJECTS\Vente et Marketing - ALL Compagnies\tools\hyperframes-student-kit\` (560 MB, shallow clone).

**Skills Claude Code auto-chargÃ©s** â€” ils apparaissent dans la liste des skills disponibles dÃ¨s qu'on ouvre une session dans ce dossier :
- `/hyperframes` Â· `/hyperframes-cli` Â· `/gsap`
- `/hyperframes-registry` Â· `/website-to-hyperframes`
- `/make-a-video` Â· `/short-form-video`

### Premier test â€” starter `claude-edit-intro`

```bash
cd "C:/Users/Utilisateur/PROJECTS/Vente et Marketing - ALL Compagnies/tools/hyperframes-student-kit"
npm install                                    # 1 seule fois, Ã  la racine du kit
cd video-projects/claude-edit-intro            # projet starter, brand minimal
npx hyperframes doctor                         # vÃ©rifie Node, FFmpeg, Chrome
npx hyperframes preview                        # ouvre Studio sur localhost:3002
# ouvrir final.mp4 Ã  cÃ´tÃ© pour comparer ce qu'on doit atteindre
```

### Commandes clÃ©s (toujours depuis un dossier `video-projects/<nom>/`)

| Commande | Action |
|---|---|
| `npx hyperframes lint` | Check HTML avant render (obligatoire) |
| `npx hyperframes preview` | Studio live (hot reload, scrubbable timeline) |
| `npx hyperframes render --quality draft --output renders/draft.mp4` | Render rapide CRF 28 (1-3 min) |
| `npx hyperframes render --quality standard --output renders/final.mp4` | Render final 1080p (visually lossless) |
| `npx hyperframes transcribe <file> --model small.en --json` | Timestamps par mot (Ã©quivalent Whisper, intÃ©grÃ©) |
| `npx hyperframes tts "texte" --voice am_adam --output narration.wav` | TTS local Kokoro-82M |
| `npx hyperframes catalog --type block` | Liste les 38 blocks prÃªts Ã  installer |
| `npx hyperframes add <nom>` | Installe un block du registry |

### PrÃ©requis systÃ¨me

- **Node 20+** (check : `node --version`)
- **FFmpeg** sur le PATH
- **Chrome** (Hyperframes render via Chromium headless)
- **16 GB RAM** recommandÃ© pour le Studio preview
- ~5 GB libre disque (node_modules + renders)

### Docs Ã  lire dans l'ordre

1. `tools/hyperframes-student-kit/README.md` â€” vue d'ensemble + les 12 projets
2. `tools/hyperframes-student-kit/CLAUDE.md` â€” guide Claude Code workspace (20k)
3. `tools/hyperframes-student-kit/MOTION_PHILOSOPHY.md` â€” philosophie motion, obligatoire avant de brainstormer (39k)
4. `tools/hyperframes-student-kit/DESIGN.ais-example.md` â€” exemple complet de brand spec AIS

### Les 12 projets du kit (starters clonables)

| Projet | Format | AIS coupling | Commentaire |
|---|---|---|---|
| `claude-edit-intro` | 16:9 1080p 60fps | Minimal | **Starter recommandÃ©** |
| `may-shorts-19` | 9:16 1080Ã—1920 | Minimal | Le plus poli â€” skill `/short-form-video` Ã©crit autour |
| `may-shorts-18` | 9:16 | Minimal | Version antÃ©rieure, comparer avec v19 |
| `may-shorts-6` | 16:9 | Minimal | Landscape cut talking-head |
| `clickup-demo` | 16:9 | Minimal | 60s SaaS product demo, heavy registry |
| `linear-promo-30s` | 16:9 | Minimal | 30s promo, draft Ã  finir (exercice) |
| `hyperframes-sizzle` | 16:9 | Minimal | Sizzle reel Hyperframes Ã— Claude Code |
| `first-agent-promo` | 16:9 | Minimal | React-via-Babel (counter-example) |
| `aisoc-lesson-5-1` | 16:9 | Heavy | Full lesson face-cam + motion graphics |
| `golden-ratio-demo` | 16:9 | Heavy | Lesson AIS proportion layout |
| `aisoc-hype` | 16:9 | Heavy | 30s AIS brand hype â€” scaffold rÃ©fÃ©rence |
| `aisoc-app-release` | 16:9 | Heavy | 30s AIS mobile â€” HANDOFF.md dÃ©taillÃ© |

**Heavy AIS coupling** = ne pas rÃ©utiliser tel quel (couleurs hardcodÃ©es, logo AIS). Rebuild from scratch.
**Minimal** = bon starter, swap des brand-tokens suffit.

### CrÃ©ation d'un projet vidÃ©o perso

```bash
cd video-projects
mkdir formation-claude-code-ep1
cd formation-claude-code-ep1
npx hyperframes init
# ou plus rapide : copier hyperframes.json + meta.json d'un projet sibling
cp ../claude-edit-intro/{hyperframes.json,meta.json} .
# Ã©diter meta.json pour changer id/name/dimensions
```

---

## Ce que Nate Herk a appris aprÃ¨s 60+ vidÃ©os en une journÃ©e

Nate Herk a gÃ©nÃ©rÃ© plus de 60 rendus en une seule journÃ©e pour tester les deux mÃ©thodes (Claude Design + Hyperframes). Ses conclusions :

1. **Le goÃ»t reste l'avantage concurrentiel.** Quelqu'un avec un sens du visuel + ces outils = x10 productivitÃ©. Quelqu'un sans goÃ»t = rÃ©sultats moyens malgrÃ© l'outil. L'IA amplifie le talent, ne le remplace pas.

2. **L'itÃ©ration est le vrai workflow.** Pas de "parfait du premier coup". Le bon Ã©tat d'esprit : expÃ©rimenter vite, pas Ã©diter longtemps. Donner du feedback comme Ã  un monteur humain : "Ã  5 secondes le texte est flou, Ã  12 secondes le pourcentage dÃ©passe le cadre".

3. **Les Shorts ne sont pas encore au niveau.** Trop mÃ©caniques, manquent d'Ã©nergie et d'accroche pour les rÃ©seaux sociaux. Nate le dit lui-mÃªme : "je ne posterais pas Ã§a". Encore trop tÃ´t.

4. **Les dÃ©mos SaaS perdent leur Ã©nergie Ã  mi-chemin.** Le test ClickUp : rÃ©sultat intÃ©ressant mais devient statique. L'IA n'a pas encore l'instinct humain pour maintenir le rythme visuel.

5. **GÃ©rer les ressources.** Effacer le contexte Claude Code entre les sessions (il Ã©tait Ã  263k tokens / 1M). Ne pas rendre plusieurs vidÃ©os simultanÃ©ment pendant qu'on enregistre â€” Ã§a fait glitcher la webcam.

6. **La valeur cumulative.** Chaque vidÃ©o crÃ©Ã©e nourrit le studio (skills, design docs, templates). Ce n'est pas un outil ponctuel, c'est un studio qui s'amÃ©liore.

---

## Patterns d'usage techniques (Nate Herk)

*(Extrait + synthÃ¨se 2026-04-22 de la vidÃ©o ZNbgOhxhzXg â€” transcript complet avec timestamps dans `data/nateherk/`)*

Cette section complÃ¨te "Ce que Nate a appris" avec les gestes concrets Ã  reproduire dans Claude Code.

### Pattern 1 â€” Claude Design comme rampe d'accÃ¨s sans code

Pour dÃ©marrer vite **sans installer Hyperframes**, utiliser Claude Design (app web Anthropic). Workflow court :

1. Design System (logo, couleurs, typo) configurÃ© une seule fois â†’ rÃ©utilisÃ© partout
2. Nouveau projet `From Template > Animation` â†’ import MP4 + transcript JSON word-level
3. RÃ©pondre aux questions guidÃ©es : talking head position / visual energy / motion graphics types / theme / end card CTA
4. Claude Design gÃ©nÃ¨re l'animation HTML en ~2 min
5. **Export** (limite clÃ©) : pas de bouton MP4 direct. Deux sorties possibles :
   - **Screen record** la preview full screen (OK pour clips courts)
   - **Hand-off to Claude Code** : bouton dÃ©diÃ© qui copie une commande. Coller dans Claude Code â†’ "render this as MP4" â†’ Hyperframes produit le MP4 derriÃ¨re

> *Limite honnÃªte :* Claude Design ne peut pas transcrire la vidÃ©o. Il faut fournir le transcript timestamped en input. Hyperframes via Claude Code automatise cette Ã©tape.

### Pattern 2 â€” Feedback Ã©diteur humain (timestamped)

Le prompt d'Ã©dition doit ressembler Ã  ce qu'on dirait Ã  un monteur humain. Pas de jargon technique. Timestamps explicites.

**Template Ã  copier :**

> "Overall, I like the vibe and the logic. I just need some aesthetic changes.
>
> 1. At about 5 seconds, when the hero title comes in, we can't see it because there's a blur effect on top of it. Move the blur behind the text.
> 2. At 12 seconds, the right half of the percentage sign is blurred and part of the 6 is out of frame. Scale down or re-center.
> 3. The next scene (15s onwards) looks solid â€” no changes.
>
> Please make those and render V2."

**Pourquoi Ã§a marche :**
- Un dÃ©faut = un timestamp prÃ©cis = une correction isolÃ©e
- Ce qui est bon est dit explicitement â†’ Claude ne casse pas ce qui marche
- Pas de "rends Ã§a mieux" flou qui force Claude Ã  tout refaire

### Pattern 3 â€” Pre-render check frame by frame

Pour Ã©viter un render aller-retour qui gaspille des tokens :

> "Before you ever render or give me any output to review, look at every single frame first, extract all of them, check for alignment/readability/timing issues, fix what you find, and THEN render."

Effet : la V1 qui sort est dÃ©jÃ  V2 en qualitÃ©. Moins d'itÃ©rations nÃ©cessaires.

### Pattern 4 â€” Gestion du contexte long (summary + clear)

Une session Hyperframes mange vite 200-260K tokens (beaucoup d'HTML gÃ©nÃ©rÃ©). Avant de saturer :

**Ã‰tape 1 â€” Demander le handoff summary :**

> "Give me a full summary of everything you've built, where the key files are, what design decisions you've made, and what's next. I'm going to clear the session."

**Ã‰tape 2 â€” Clear session (`/clear` ou nouvelle fenÃªtre).**

**Ã‰tape 3 â€” Coller le summary dans la nouvelle session** + "Continue from here with the feedback below." + feedback.

Gain : la nouvelle session repart Ã  ~5K tokens avec tout le contexte nÃ©cessaire, au lieu de hÃ©riter de 260K.

### Pattern 5 â€” Hand-off Claude Design â†’ Claude Code (export MP4)

Claude Design ne rend pas de MP4 directement. ProcÃ©dure :

1. Dans Claude Design, bouton **"Hand off to Claude Code"** â†’ copie une commande dans le presse-papier
2. Ouvrir Claude Code dans un projet Hyperframes (ou le dossier courant si Hyperframes installÃ©)
3. Coller + "Render this as MP4 at 1080p"
4. Claude Code exÃ©cute : HTML (depuis Claude Design) â†’ Hyperframes render â†’ ffmpeg â†’ MP4
5. Fichier disponible dans `renders/`

Astuce : la mÃªme logique marche pour convertir n'importe quelle page HTML Claude Design en vidÃ©o.

### Pattern 6 â€” Un render Ã  la fois (RAM safety)

Nate a eu un facecam glitchy en enregistrant une vidÃ©o pendant que 4 autres rendus tournaient en parallÃ¨le. RÃ¨gle simple :

- **Pendant que Claude Code render** â†’ pas d'enregistrement webcam
- **Max 1 render simultanÃ©** par machine standard (16-32 GB RAM)
- Si plusieurs projets Ã  rendre â†’ les queue-r sÃ©quentiellement, pas en parallÃ¨le

### Pattern 7 â€” Signal coÃ»t rÃ©aliste

Pour briefer un client ou pitcher la mÃ©thode :

| MÃ©trique | Valeur (Nate, plan Max $200/mois) |
|---|---|
| Context consommÃ© pour 1 projet vidÃ©o complet (30-40s) | 125K Ã  260K tokens |
| Part de la session 5h Max | ~10% (= 10 projets possibles sur une session) |
| Temps humain effectif | ~20 min de dialogue + itÃ©rations (vs 2-3h manuel) |
| Nombre de renders possibles par journÃ©e de test | 60+ (Nate a tout testÃ© en 1 journÃ©e) |

---

## Patterns d'usage avancÃ©s (Nate Herk â€” vidÃ©o Aw3BkmhYu4I, 2026-04-22)

*(Extrait + synthÃ¨se de la nouvelle vidÃ©o "Claude + HyperFrames Just Solved Video Editing" â€” transcript complet dans `data/nateherk/Aw3BkmhYu4I_*`)*

**Delta clÃ© vs la vidÃ©o prÃ©cÃ©dente (ZNbgOhxhzXg) :** avant, Nate faisait le trim + edit MANUELLEMENT avant de passer Hyperframes. Maintenant, un nouvel outil **`video-use`** automatise le trim/filler/retakes. Le pipeline devient **end-to-end sans intervention humaine sur le trim** :

```
raw .mp4 -> video-use (trim mistakes + filler + retakes + transcription)
         -> handoff
         -> Hyperframes (motion graphics HTML)
         -> ffmpeg (render MP4)
```

### Pattern 8 â€” `video-use` comme trim automatique

Nouvel outil dans l'Ã©cosystÃ¨me vidÃ©o Claude Code. Scope : trim + filler removal + retakes detection + transcription word-level. Avant lui, Claude ne faisait que les motion graphics, le trim restait manuel dans Descript.

**Prompt type Ã  copier :**

> "Hey Claude Code, I would like you to use the video-use tool just to edit this video. I want you to analyze it. I want you to remove any filler words or silences or retakes. Then we're going to use hyperframes to actually add the motion graphics to it. Your first task is just to edit out the mistakes and the filler words."

Le skill dÃ©diÃ© dans video-use s'appelle **"edit only for hyperframes handoff"** â€” il sort le JSON transcript + l'edited MP4 sans faire les motion graphics. C'est Hyperframes qui prend la suite avec ces 2 fichiers.

### Pattern 9 â€” Architecture dossier `video projects/<name>/`

Claude crÃ©e automatiquement cette structure sur nouvelle demande de montage :

```
video projects/
  <nom-projet>/
    assets/
      clips/              # raw files + edited aprÃ¨s video-use
      transcripts/        # JSON word-by-word (ElevenLabs/Whisper)
    compositions/         # beats HTML (1 par scÃ¨ne)
    components/           # reusables (lower-third, caption style, logo)
    final-renders/
    verification-screenshots/
```

Chaque changement dans le timeline editor Hyperframes se reflÃ¨te dans les HTML compositions et vice-versa.

### Pattern 10 â€” Plan mode avant motion graphics render

**AVANT** de gÃ©nÃ©rer les HTML motion graphics, switcher Claude en **plan mode**. Il lit le transcript timestamped, reÃ§oit la demande en langage naturel, et retourne un plan dÃ©taillÃ© (beats, timings, colors, anchors). Sans cramer de tokens en code HTML.

**BÃ©nÃ©fice concret :** Ã©conomie substantielle de tokens. On approuve ou itÃ¨re sur le plan, PUIS on exÃ©cute le code HTML. Ã‰vite le cycle "il a codÃ© 2000 lignes de HTML mais le concept est pas bon".

**Raccourci Claude Code :** Shift+Tab â†’ bascule en Plan Mode.

### Pattern 11 â€” Training data par type de vidÃ©o

CrÃ©er des sous-dossiers par format rÃ©current :

```
video projects/
  lessons/           # 1 dossier par leÃ§on crÃ©Ã©e
  intros/            # openers rÃ©utilisables
  shorts/            # format 9:16
```

Chaque projet rÃ©ussi devient rÃ©fÃ©rence. AprÃ¨s 3-5 vidÃ©os du mÃªme type, Claude peut automatiser l'essentiel via un fichier `<type>-design-philosophy.md` Ã  la racine du dossier type. Citation Nate : "All of these videos are training data. So, let's say I make five different lessons. Now, I can basically say, okay, cool, build a lesson design markdown philosophy file, which means every time I build a lesson, just use that."

### Pattern 12 â€” Screenshots verification par Claude

Instruire Claude explicitement dans le prompt initial :

> "Take screenshots of what's going on in each scene to make sure that it looks good."

Claude rend une frame PNG, la lit comme image, vÃ©rifie visuellement (alignement, crop, texte hors cadre, couleur illisible) avant de valider la scÃ¨ne. Ã‰vite les rendus "Ã§a a l'air OK dans le code mais c'est nul visuellement".

Les screenshots vont dans `verification-screenshots/` dans l'architecture Pattern 9.

### Pattern 13 â€” Timeline editor bidirectionnel

L'UI Hyperframes Studio permet de shorten / delete / move / rÃ©ordonner les beats directement Ã  la souris. Le changement est **Ã©crit dans le HTML sous-jacent**. Ã€ la prochaine itÃ©ration, Claude voit le changement et le respecte.

**Workflow gagnant :**
1. Claude gÃ©nÃ¨re la V1 motion graphics
2. Florent ouvre `npx hyperframes preview` et ajuste les timings Ã  la souris (drag des beats)
3. Florent repasse dans Claude Code avec du texte : "now add a subtitle at beat 3"
4. Claude lit le HTML modifiÃ© et applique par-dessus les modifs manuelles de Florent

Raccourci massif pour les ajustements de timing. La UI remplace "Ã  5.2s le texte part trop vite" par un drag.

### Pattern 14 â€” Voice-to-text pour prompts longs

Pour donner les specs de motion graphics (scene par scÃ¨ne, 4-10 beats, style, couleurs, sync avec phrases), Nate utilise son outil voice-to-text. Parler est plus naturel que taper pour dÃ©crire 20+ specs visuelles sÃ©quentielles.

**Avantages concrets :** plus d'infos dans le prompt, phrasÃ© plus naturel qui donne un meilleur parsing Claude, moins de fatigue clavier sur des prompts de 300+ mots.

### Pattern 15 â€” ElevenLabs API > Whisper pour les cuts

Par dÃ©faut Hyperframes utilise **OpenAI Whisper** pour la transcription. Nate a comparÃ© et passe maintenant sur **ElevenLabs API** :

> "Hyperframes likes to default to OpenAI whisper. For this video I am using 11 Labs API because I think that it's actually better at finding the right moments to cut."

**Options disponibles :**

| Transcripteur | CoÃ»t | QualitÃ© cuts | Note |
|---|---|---|---|
| OpenAI Whisper API | ~$0.006/min | Bonne | DÃ©faut Hyperframes |
| ElevenLabs API | ~$0.01/min | **Meilleure pour cuts** selon Nate | Choix actuel Nate |
| Whisper local | Gratuit | Bonne | Consomme RAM pendant le process |

ClÃ© Ã  ajouter dans `.env` : `ELEVENLABS_API_KEY=xxx`

### Pattern 16 â€” Handoff explicite video-use â†’ Hyperframes

Quand on veut que video-use fasse UNIQUEMENT la partie trim/transcription et laisse Hyperframes gÃ©rer les motion graphics, demander explicitement :

> "Use the video-use skill 'edit only for hyperframes handoff' on this raw file."

Ce skill dÃ©diÃ© sort :
- `edited.mp4` â€” le MP4 trimmed
- `transcript.json` â€” le word-level timestamps prÃªt pour Hyperframes

Puis enchaÃ®ner : "Now use Hyperframes to add motion graphics based on `transcript.json`."

Ã‰vite que video-use essaie de faire les animations (pas son rÃ´le) ou que Hyperframes refasse le trim (dÃ©jÃ  fait).

### Pattern 17 â€” `.env` obligatoire pour les API keys

**RÃ¨gle de sÃ©curitÃ© rappelÃ©e par Nate :**

> "I typically try to avoid just pasting it [API key] straight into the actual chat. The reason for that is just because that would stay in the conversation history and just best practice to not do that."

**Ã€ faire :**
- Via VS Code : ouvrir `.env` Ã  la racine du projet, paste la clÃ©
- Via Claude Code Desktop : "Claude Code, create me the .env file and drop my 11Labs API key inside it" puis paste dans l'Ã©diteur de fichier qu'il ouvre

**Ã€ Ã©viter :** coller la clÃ© dans le chat Claude, mÃªme temporairement. Elle reste dans l'historique de session et peut leak si la session est partagÃ©e ou si quelqu'un lit le transcript.

**RÃ¨gle :** `.env` au `.gitignore`, `.env.example` commitÃ© avec les noms de clÃ©s sans les valeurs.

### Signal coÃ»t actualisÃ© (Aw3BkmhYu4I)

| MÃ©trique | Valeur |
|---|---|
| VidÃ©o prÃ©cÃ©dente (ZNbgOhxhzXg) | ~260K tokens |
| Nouvelle vidÃ©o (Aw3BkmhYu4I) avec video-use + Hyperframes | **238K tokens** |
| Plafond 5h session $200 Max | ~10-12% par vidÃ©o de 30 min |
| DurÃ©e session humain | ~25-30 min de dialogue + itÃ©rations |

Conclusion Nate : "This took us about 238,000 tokens. So, not too bad, but not great either because this will eat some tokens. And that's why the more specific you can be with your planning and with your iterating, the better." â†’ **Plan mode (Pattern 10) est ce qui fait la diffÃ©rence.**

---

## CAS 3 â€” Audio pro avec Auphonic

*(AjoutÃ© 2026-04-21 sur recommandation Jack Roberts â€” vidÃ©o "Claude just changed Content Creation Forever")*

### Pourquoi

AprÃ¨s le nettoyage Descript (CAS 1) et les motion graphics Hyperframes (CAS 2), il reste souvent un dÃ©faut audio subtil : volume inÃ©gal, normalisation non-broadcast, bruit de fond rÃ©siduel. **Auphonic** est un service web spÃ©cialisÃ© dans le mastering audio pour podcasts et vidÃ©os, avec une **API qui permet Ã  Claude Code de traiter l'audio programmatiquement**.

### Ce que Auphonic fait mieux que Descript Studio Sound

- **Leveler adaptatif** : Ã©galise les volumes entre le micro principal et la voix off, mÃªme si l'un est fort et l'autre faible
- **Loudness target broadcast** : -16 LUFS (YouTube), -23 LUFS (EBU R128), -14 LUFS (Spotify) â€” Descript ne fait pas Ã§a
- **Suppression de bruit intelligent** (hum, hiss, click, breathing) â€” plus prÃ©cis que Studio Sound
- **MÃ©tadonnÃ©es + chapitres automatiques**

### Setup

1. CrÃ©er un compte sur [auphonic.com](https://auphonic.com) (free tier = 2h audio/mois, plan payant = illimitÃ©)
2. Aller dans **Settings > API** et crÃ©er une clÃ© API
3. Stocker la clÃ© dans le `.env` du projet vidÃ©o : `AUPHONIC_API_KEY=xxx`

### IntÃ©gration dans Claude Code

Prompt type Ã  donner Ã  Claude Code aprÃ¨s le render Hyperframes :

> "Awesome, I'd now like you to run the entire audio through Auphonic. Here's my API key in the .env. Let me know when that's complete."

Claude Code fait alors :
1. Extrait l'audio du MP4 Hyperframes avec ffmpeg
2. Upload vers Auphonic via l'API
3. Applique un preset (leveler + loudness + noise reduction)
4. TÃ©lÃ©charge l'audio traitÃ©
5. RÃ©intÃ¨gre l'audio propre dans le MP4 final

### Endpoints API Auphonic clÃ©s

```bash
# CrÃ©er une production (upload + traitement)
POST https://auphonic.com/api/productions.json

# RÃ©cupÃ©rer le rÃ©sultat
GET https://auphonic.com/api/production/{uuid}.json

# TÃ©lÃ©charger le fichier final
GET https://auphonic.com/download/audio-result/{uuid}/{filename}
```

Docs complÃ¨tes : https://auphonic.com/help/api/

---

## Repos GitHub de rÃ©fÃ©rence

| Repo | Usage | Limite |
|------|-------|--------|
| seedprod/video-editor-for-claude-code | Supprime pauses sur screencasts Claude Code | DÃ©tecte message orange "esc" â€” fonctionne seulement si Claude Code visible |
| barefootford/buttercut | Transcrit + discute les coupes avec Claude | Sort XML timeline (Premiere/DaVinci requis), pas un MP4 |
| digitalsamba/claude-code-video-toolkit | Studio complet (Remotion, ElevenLabs, musique IA) | Trop complexe pour simple nettoyage |

---

## Notebooks NotebookLM de rÃ©fÃ©rence

| Notebook | URL | Contenu |
|---|---|---|
| Descript vs Tella vs Loom | https://notebooklm.google.com/notebook/156956d1-7fb1-4bc0-ba10-fdbad75076ce | Comparatif outils montage â€” 8 sources |
| Montage Claude Code + FFmpeg + Whisper | https://notebooklm.google.com/notebook/ab3d2330-e931-4177-a4ff-6a8fe8825372 | Pipeline technique + repos + prompts â€” 12 sources |

---

## Sources vidÃ©o clÃ©s (triÃ©es par pertinence)

| ChaÃ®ne | VidÃ©o | Vues | Lien |
|---|---|---|---|
| Brendan Jowett | How I Fully Automated My Video Editing (Claude Code) | 47k | https://youtube.com/watch?v=G0EH0xdy2-E |
| Nate Herk | Claude Just Destroyed Every Video Editing Tool | 152k | https://youtube.com/watch?v=ZNbgOhxhzXg |
| **Nate Herk** | **Claude + HyperFrames Just Solved Video Editing** (video-use end-to-end) | **7.5k** | **https://youtube.com/watch?v=Aw3BkmhYu4I** |
| Ben AI | Claude Code Changed Content Creation Forever | 21k | https://youtube.com/watch?v=BJuevX91ExM |
| Brendan Jowett | How To Edit Videos With Claude Code | 20k | https://youtube.com/watch?v=3hzXfTjqiKg |
| **Jack Roberts** | **Claude just changed Content Creation Forever** (Hyperframes walkthrough + Auphonic) | **7k** | **https://youtube.com/watch?v=34VoezbEvLw** |
| Kevin Stratvert | Descript AI Video Editing Tutorial 2024 | 100k | https://youtube.com/watch?v=Dk1TxDKzb68 |

---

## Prompts exacts des crÃ©ateurs (source : NotebookLM 2026-04-21)

Ces prompts sont copiables tels quels dans Claude Code.

### 1. MEGA PROMPT â€” CrÃ©er un skill rÃ©utilisable (Ben AI)

> âš ï¸ **STATUT : Ã€ EXPÃ‰RIMENTER â€” non validÃ© en prod (2026-04-21)**
> L'approche tout-automatique via Claude Code (assembly + transcription + cuts automatiques) s'est rÃ©vÃ©lÃ©e trop complexe et peu fiable en pratique. ConfirmÃ© par les deux notebooks NotebookLM. L'outil Ã©volue vite â†’ re-tester dans 3-6 mois. **Pour l'instant : CAS 1 = Descript (GUI), Claude Code = seulement CAS 2 (Hyperframes/animations).**

Ã€ utiliser UNE FOIS aprÃ¨s avoir fait un premier montage rÃ©ussi. Claude mÃ©morise tout le process et crÃ©e une commande `/YouTube edit` rÃ©utilisable pour toutes les vidÃ©os suivantes.

> "now I want you to create a new skill that follows this exact process of editing my YouTube videos so every time this YouTube editing skill is invoked I want you to stitch together the videos transcribe the videos always then suggest um parts of text to highlight for me when I confirm the text to highlight use the exact style of the one that we had that we did here to highlight the texts also suggest me a part of the script to add in the overlay um sped up version and also suggest me parts of the video where we can add in transition slides in the same style that we did in this uh project lastly suggest me one or two clips that would be under five minutes and interesting to share on LinkedIn when I confirm use the same style of captions and cut it up for LinkedIn"

### 2. Prompt â€” Assembler et transcrire plusieurs clips
Quand on a enregistrÃ© par petits morceaux (ex: via Tella) et qu'on veut tout assembler avant de travailler.

> "first stitch the videos together into one long video and also transcribed the video so you understand what this video is about"

### 3. Prompt â€” Couper par sujet (langage naturel)
Pour garder uniquement les passages qui parlent d'un sujet prÃ©cis, sans avoir Ã  indiquer des timestamps.

> "keep only the parts where kind of Claude goes off the rail and goes crazy"
> "only keep the clips that talk about money"

### 4. Prompts â€” CrÃ©er des clips LinkedIn depuis un long enregistrement

> "identify from the transcript um when I switch over from one to the other and cut it up into three different clips for LinkedIn i don't want the intro for LinkedIn"

Pour les sous-titres cohÃ©rents sur les clips LinkedIn :

> "for LinkedIn is I want to add captions in the same style that we have done before uh like the highlights for the entire video for LinkedIn"

---

## Prochaines Ã©tapes

1. [x] RÃ©cupÃ©rer le Breakdown Sheet de Brendan Jowett â€” âœ… 2026-04-21 via `/skool-scraper` â†’ `data/brendanjowett/brendan-jowett-breakdown-sheet.md`
2. [x] Guide d'enregistrement â€” âœ… 2026-04-21 â†’ ajoutÃ© dans ce skill + page Notion
3. [ ] Tester Descript sur une vraie vidÃ©o de formation de Florent (5-10 min)
4. [ ] VÃ©rifier si Descript recorder suffit ou si Tella reste nÃ©cessaire
5. [ ] Setup Remotion dans Claude Desktop App (demander "install Remotion" â€” setup automatique)
6. [ ] CrÃ©er le skill `/video-edit` rÃ©utilisable (utiliser le MEGA PROMPT de Ben AI aprÃ¨s premier montage rÃ©ussi)
