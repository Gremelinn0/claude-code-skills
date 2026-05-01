# Skill — Montage Vidéo Automatisé avec Claude Code

## Quand utiliser ce skill

Déclencher quand l'utilisateur veut :
- Nettoyer automatiquement une vidéo de formation brute (screencast + webcam)
- Supprimer les silences, les "je coupe", les hésitations d'une vidéo MP4
- Enrichir une vidéo propre avec des animations / motion graphics
- Finaliser l'audio d'une vidéo (nettoyage, mastering, loudness)
- Choisir entre les outils disponibles (Descript, Claude Design, Hyperframes, Remotion, Auphonic)

---

## Repos GitHub à cloner automatiquement

**Au premier usage de ce skill, Claude Code doit cloner ces repos dans le projet actif :**

| Repo | URL | Rôle |
|---|---|---|
| Hyperframes (officiel HeyGen) | https://github.com/heygen-com/hyperframes | Moteur motion graphics HTML → MP4 |
| Hyperframes Student Kit (Nate Herk) | https://github.com/nateherkai/hyperframes-student-kit | 12 projets vidéo finis + 7 skills Claude Code auto-chargés |

**Commande de clone rapide :**

```bash
cd "<dossier projet>/tools/"
git clone --depth 1 https://github.com/nateherkai/hyperframes-student-kit.git
cd hyperframes-student-kit && npm install
npx hyperframes browser ensure        # télécharge Chromium headless (~100 MB)
npx hyperframes doctor                # vérifie Node, FFmpeg, Chrome
```

**Alternative "paste URL + explique"** (méthode recommandée par Jack Roberts pour découvrir l'outil) :
> Coller cette URL dans une nouvelle session Claude Code :
> `https://github.com/heygen-com/hyperframes`
> Puis demander : *"Download this repo for me. In 5 bullet points, what are the coolest things it can do? Then edit example.mp4 in 3 different ways (name tag, captions, lower thirds)."*

---

## Modèles Claude recommandés — économie de tokens

*(Conseil Jack Roberts, session 2026-04-21)*

| Phase | Modèle | Pourquoi |
|---|---|---|
| Setup initial, architecture du projet vidéo, création de compositions complexes | **Opus 4.7** | Meilleur raisonnement pour poser la structure |
| Éditions ponctuelles (timing, couleurs, ajustements, ajout d'un block, captions) | **Sonnet 4.6** | 99% des cas — Opus 4.7 est "affamé" en tokens (cf. Jack Roberts) |
| Rendu final / commandes shell / lint | **Sonnet 4.6** ou **Haiku** | Tâches mécaniques, pas de créativité requise |

Basculer de modèle en cours de session : `/model claude-sonnet-4-6` ou `/model claude-opus-4-7`.

---

## Pipeline complet validé (session 2026-04-21)

### LES 3 CAS — NE PAS CONFONDRE

| Cas | Besoin | Outil |
|-----|--------|-------|
| CAS 1 | Nettoyer une vidéo brute (silences, erreurs, "je coupe") | **Descript** |
| CAS 2 | Habiller une vidéo propre (animations, textes, motion graphics) | **Claude Design, Hyperframes ou Remotion** |
| CAS 3 | Finaliser l'audio (nettoyage pro, mastering, loudness broadcast) | **Auphonic** (via API depuis Claude Code) |

---

## Guide d'enregistrement — bonnes pratiques

*(Sources : NotebookLM "FFmpeg+Whisper+Claude Code" + "Descript vs Tella vs Loom", validées 2026-04-21)*

### Avant d'enregistrer

1. **Micro de qualité** — réduit le travail de Studio Sound (moins d'écho à corriger)
2. **Enregistrer directement dans Descript** si possible — transcription en temps réel, pas de fichier à transférer
3. **Encadrer uniquement la fenêtre app** — pas le bureau entier ni les autres apps (meilleure détection OCR + clips plus propres)

### Pendant l'enregistrement

4. **Répéter la phrase ratée** plutôt que dire "je coupe" → Descript "Remove retakes" détecte les répétitions et garde la meilleure prise automatiquement
5. **Laisser 2-4 secondes de silence** entre les prises → "Shorten word gaps" les supprime en 1 clic
6. **Changer de scène pendant un silence** (raccourcis Descript ou OBS) — les transitions seront propres
7. **Ne pas stresser pour les "euh"** — "Remove filler words" les supprime tous en batch
8. **Enregistrer en plusieurs clips si c'est long** → Claude Code peut les assembler avec le prompt Stitch (cf. section Prompts)

### Bonus Descript

- Un seul mot raté → **Overdub** le remplace par synthèse vocale sans re-enregistrer
- Regard caméra → **Eye Contact** (téléprompter intégré) corrige la direction du regard
- Long enregistrement → découper en scènes avec **"/"** dans la transcription (navigation rapide)
- Ordre de travail : **IA en premier** (Remove retakes → Shorten gaps → Remove fillers → Studio Sound), puis corrections manuelles

### Ce qu'il ne faut PAS faire

- ❌ Dire "je coupe" (force une recherche manuelle dans la transcription)
- ❌ Enregistrer le bureau entier avec toutes les apps visibles
- ❌ S'arrêter pour corriger chaque erreur — finir la phrase, reprendre proprement, Descript gère
- ❌ FFmpeg + Python pour le nettoyage (trop lent, aucun contrôle visuel — confirmé par Nate Herk + Sandy Lee)

---

## CAS 1 — Nettoyage screencast brut (besoin principal de l'utilisateur)

### Étape 0 : Enregistrement

**Option A — Enregistrer directement dans Descript (recommandée)**
Descript a un enregistreur intégré qui capture écran + webcam + micro. Avantage majeur : la transcription se génère en temps réel pendant l'enregistrement. Pas de fichier à transférer.

**Option B — Tella puis import dans Descript**
Tella = bon pour les vidéos courtes et soignées, système de mises en page visuelles, enregistrement par petits clips (évite de tout recommencer si erreur sur une section). Exporter en MP4 → importer dans Descript.

**À éviter : Loom**
Loom = outil de partage de liens vidéo, pas d'édition post-enregistrement. Non adapté au montage lourd.

### Étape 1 : Nettoyage dans Descript

1. Importer le MP4 → transcription automatique
2. **Template Descript** (Brendan Jowett) — appliquer via "Templates > Created by me" : *"Please remove all repeating sentences. Usually, the last repeated sentence is the correct one after all the mistakes."* Simple et efficace.
3. **"Remove retakes"** — l'IA détecte les phrases répétées, garde la meilleure prise
4. **"Shorten word gaps"** — trouver tous les gaps > **0.2 sec**, les raccourcir à **0.2 sec** (Brendan) ou > 1-2 sec pour un résultat plus naturel (Nate)
5. **"Remove filler words"** — supprime les "euh", "donc", hésitations
6. Pour les "je coupe" : chercher le texte dans la transcription → sélectionner + touche Suppr. Instantané.
7. **"Studio Sound"** — nettoie l'audio en 1 clic (supprime l'écho, améliore le micro)
8. **Musique** (optionnel) : ajouter via Epidemic Sound dans Descript avant l'export (pas de copyright)
9. Exporter le MP4 propre

**Output : 2h de brut → ~30 min propre, audio impeccable.**

### Pourquoi PAS Python + FFmpeg pour le nettoyage brut

Approche testée et abandonnée par Nate Herk et Sandy Lee (confirmé par les 2 notebooks NotebookLM le 2026-04-21) :
- Trop lent, pas de contrôle visuel
- Donner des timestamps à FFmpeg ("coupe de 4 à 7 secondes") prend plus de temps que de le faire manuellement
- Sandy Lee : "tellement lente et frustrante" qu'elle est revenue aux outils dédiés

---

## CAS 2 — Motion graphics / animations (sur vidéo propre)

### Prérequis : Transcription Whisper avec timestamps

**OBLIGATOIRE** pour les 2 options. Whisper transcrit la vidéo mot par mot avec l'horodatage exact. Sans ça, Claude ne sait pas synchroniser les animations avec la parole.

- Via Claude Code (il installe et exécute automatiquement)
- Via API OpenAI si whisper local ralentit la machine
- Via FFmpeg 8.1+ (Whisper intégré nativement depuis août 2025)

### Option A — Claude Design (simple, web-based)

**C'est quoi :** l'app web Anthropic (comme Claude.ai) spécialisée animations HTML. Pas de code. Interface navigateur.

**Workflow :**
1. Aller sur Claude Design (app web Anthropic)
2. Créer un "Design System" : charger logo, couleurs, typo → mémorisé pour toutes les vidéos suivantes
3. Nouveau projet "Animation" → donner le clip MP4 propre + transcription Whisper + description du style
4. Claude génère du HTML animé (textes sync, graphiques, transitions)
5. Export : screen record le navigateur OU commande Claude Code pour render MP4 via ffmpeg

**Limite :** Claude Design ne peut pas "entendre" la vidéo — la transcription Whisper est obligatoire.
**Coût :** inclus dans l'abonnement Anthropic.

### Option B — Hyperframes via Claude Code (plus puissant)

**📎 Repo à cloner :** `https://github.com/heygen-com/hyperframes` (officiel HeyGen)
**📎 Kit de starters :** `https://github.com/nateherkai/hyperframes-student-kit` (12 projets vidéo finis + 7 skills Claude Code)
**📎 Modèle recommandé :** Opus 4.7 pour le setup initial, Sonnet 4.6 pour toutes les éditions ensuite

**C'est quoi :** outil open source (GitHub) que Claude Code pilote. HTML → navigateur → ffmpeg → MP4. Plus de contrôle que Claude Design.

**Workflow :**
1. Cloner le repo Hyperframes dans le projet Claude Code (VS Code)
2. Donner à Claude Code : vidéo + transcription Whisper avec timestamps
3. Claude Code génère des compositions HTML (animations, textes sync, graphiques)
4. Preview en local → feedback précis avec timestamps → itérer
5. Render final : ffmpeg → MP4

**Point clé :** chaque itération améliore le "studio". Au bout de 10 vidéos, Claude connaît le style de l'utilisateur.
**Coût :** ~10% du plan $200/mois par projet vidéo (beaucoup de tokens pour générer le HTML).
**Repo officiel :** https://github.com/heygen-com/hyperframes (HeyGen, sorti avril 2026, Apache 2.0)
**Installation :** 1 commande dans Claude Code → skills `/hyperframes`, `/hyperframes-cli`, `/gsap` disponibles
**Kit Nate Herk :** https://github.com/nateherkai/hyperframes-student-kit (12 projets finis, bon point de départ)

---

## Statut d'intégration Hyperframes + Kit Nate Herk (2026-04-21)

### Ce qui EST dans ce skill

- ✅ Hyperframes référencé comme Option B dans CAS 2 (motion graphics)
- ✅ URL du kit Nate Herk : `https://github.com/nateherkai/hyperframes-student-kit`
- ✅ Conclusions de Nate sur ses 60+ vidéos
- ✅ Sa vidéo 152k listée dans les sources

### Ce qui N'EST PAS fait (backlog)

- ⏳ Le kit cloné localement → en cours dans `PROJECTS/<your-project-folder>/tools/hyperframes-student-kit/`
- ⏳ Les 7 slash commands Claude Code fournis dans le kit (à activer après clone)
- ⏳ Tester un des 12 projets finis (starter recommandé : `claude-edit-intro`)

### Le repo contient-il un skill ?

**OUI — 7 skills Claude Code prêts à l'emploi** dans `.claude/skills/` du kit :
- `/hyperframes` — créer/éditer des compositions
- `/hyperframes-cli` — référence CLI (init, lint, preview, render)
- `/gsap` — animations GSAP (timelines, easing, stagger)
- `/hyperframes-registry` — catalog de blocks/components
- `/website-to-hyperframes` — transformer une URL en vidéo
- `/make-a-video` — flow débutant end-to-end
- `/short-form-video` — playbook 9:16 talking-head

### Pertinence pour la phase 3 (motion graphics)

**OUI** — c'est exactement le use case CAS 2 (habiller une vidéo propre avec motion graphics). Le kit livre 12 projets finis (shorts 9:16, landscape 16:9, product promos, lessons, brand hype) qu'on peut cloner/modifier.

### Différence clé Remotion vs Hyperframes

| | Remotion (Brendan) | Hyperframes (Nate) |
|---|---|---|
| Stack | React + TypeScript | HTML + GSAP, pas de React |
| Preview | Remotion Studio | `npx hyperframes preview` (localhost) |
| Render | Node render à 30fps | Chromium headless + ffmpeg |
| Courbe | Plus propre si tu connais React | Plus simple si tu connais HTML/CSS |

### Plan d'implémentation (en cours)

1. **Cloner le kit** dans `PROJECTS/<your-project-folder>/tools/hyperframes-student-kit/` (outil projet, pas global)
2. **Lire** `CLAUDE.md` + `MOTION_PHILOSOPHY.md` du repo (docs principales de Nate)
3. **Tester** sur `claude-edit-intro` (projet le plus léger, brand minimal — bon starter)
4. **Ajouter** une section "Comment utiliser le kit" dans ce SKILL.md avec les commandes concrètes
5. **Mettre à jour** la page Notion méthodologie avec l'approche Hyperframes opérationnelle

**Source Skool :** https://www.skool.com/ai-automation-society/new-video-claude-just-changed-video-editing-forever
**Vidéo YouTube :** https://www.youtube.com/watch?v=ZNbgOhxhzXg (152k vues)

---

## Comment utiliser le kit Hyperframes (étape par étape)

### Installation — déjà fait

**Kit cloné** : `%USERPROFILE%\PROJECTS\<your-project-folder>\tools\hyperframes-student-kit\` (560 MB, shallow clone).

**Skills Claude Code auto-chargés** — ils apparaissent dans la liste des skills disponibles dès qu'on ouvre une session dans ce dossier :
- `/hyperframes` · `/hyperframes-cli` · `/gsap`
- `/hyperframes-registry` · `/website-to-hyperframes`
- `/make-a-video` · `/short-form-video`

### Premier test — starter `claude-edit-intro`

```bash
cd "~/PROJECTS/<your-project-folder>/tools/hyperframes-student-kit"
npm install                                    # 1 seule fois, à la racine du kit
cd video-projects/claude-edit-intro            # projet starter, brand minimal
npx hyperframes doctor                         # vérifie Node, FFmpeg, Chrome
npx hyperframes preview                        # ouvre Studio sur localhost:3002
# ouvrir final.mp4 à côté pour comparer ce qu'on doit atteindre
```

### Commandes clés (toujours depuis un dossier `video-projects/<nom>/`)

| Commande | Action |
|---|---|
| `npx hyperframes lint` | Check HTML avant render (obligatoire) |
| `npx hyperframes preview` | Studio live (hot reload, scrubbable timeline) |
| `npx hyperframes render --quality draft --output renders/draft.mp4` | Render rapide CRF 28 (1-3 min) |
| `npx hyperframes render --quality standard --output renders/final.mp4` | Render final 1080p (visually lossless) |
| `npx hyperframes transcribe <file> --model small.en --json` | Timestamps par mot (équivalent Whisper, intégré) |
| `npx hyperframes tts "texte" --voice am_adam --output narration.wav` | TTS local Kokoro-82M |
| `npx hyperframes catalog --type block` | Liste les 38 blocks prêts à installer |
| `npx hyperframes add <nom>` | Installe un block du registry |

### Prérequis système

- **Node 20+** (check : `node --version`)
- **FFmpeg** sur le PATH
- **Chrome** (Hyperframes render via Chromium headless)
- **16 GB RAM** recommandé pour le Studio preview
- ~5 GB libre disque (node_modules + renders)

### Docs à lire dans l'ordre

1. `tools/hyperframes-student-kit/README.md` — vue d'ensemble + les 12 projets
2. `tools/hyperframes-student-kit/CLAUDE.md` — guide Claude Code workspace (20k)
3. `tools/hyperframes-student-kit/MOTION_PHILOSOPHY.md` — philosophie motion, obligatoire avant de brainstormer (39k)
4. `tools/hyperframes-student-kit/DESIGN.ais-example.md` — exemple complet de brand spec AIS

### Les 12 projets du kit (starters clonables)

| Projet | Format | AIS coupling | Commentaire |
|---|---|---|---|
| `claude-edit-intro` | 16:9 1080p 60fps | Minimal | **Starter recommandé** |
| `may-shorts-19` | 9:16 1080×1920 | Minimal | Le plus poli — skill `/short-form-video` écrit autour |
| `may-shorts-18` | 9:16 | Minimal | Version antérieure, comparer avec v19 |
| `may-shorts-6` | 16:9 | Minimal | Landscape cut talking-head |
| `clickup-demo` | 16:9 | Minimal | 60s SaaS product demo, heavy registry |
| `linear-promo-30s` | 16:9 | Minimal | 30s promo, draft à finir (exercice) |
| `hyperframes-sizzle` | 16:9 | Minimal | Sizzle reel Hyperframes × Claude Code |
| `first-agent-promo` | 16:9 | Minimal | React-via-Babel (counter-example) |
| `aisoc-lesson-5-1` | 16:9 | Heavy | Full lesson face-cam + motion graphics |
| `golden-ratio-demo` | 16:9 | Heavy | Lesson AIS proportion layout |
| `aisoc-hype` | 16:9 | Heavy | 30s AIS brand hype — scaffold référence |
| `aisoc-app-release` | 16:9 | Heavy | 30s AIS mobile — HANDOFF.md détaillé |

**Heavy AIS coupling** = ne pas réutiliser tel quel (couleurs hardcodées, logo AIS). Rebuild from scratch.
**Minimal** = bon starter, swap des brand-tokens suffit.

### Création d'un projet vidéo perso

```bash
cd video-projects
mkdir formation-claude-code-ep1
cd formation-claude-code-ep1
npx hyperframes init
# ou plus rapide : copier hyperframes.json + meta.json d'un projet sibling
cp ../claude-edit-intro/{hyperframes.json,meta.json} .
# éditer meta.json pour changer id/name/dimensions
```

---

## Ce que Nate Herk a appris après 60+ vidéos en une journée

Nate Herk a généré plus de 60 rendus en une seule journée pour tester les deux méthodes (Claude Design + Hyperframes). Ses conclusions :

1. **Le goût reste l'avantage concurrentiel.** Quelqu'un avec un sens du visuel + ces outils = x10 productivité. Quelqu'un sans goût = résultats moyens malgré l'outil. L'IA amplifie le talent, ne le remplace pas.

2. **L'itération est le vrai workflow.** Pas de "parfait du premier coup". Le bon état d'esprit : expérimenter vite, pas éditer longtemps. Donner du feedback comme à un monteur humain : "à 5 secondes le texte est flou, à 12 secondes le pourcentage dépasse le cadre".

3. **Les Shorts ne sont pas encore au niveau.** Trop mécaniques, manquent d'énergie et d'accroche pour les réseaux sociaux. Nate le dit lui-même : "je ne posterais pas ça". Encore trop tôt.

4. **Les démos SaaS perdent leur énergie à mi-chemin.** Le test ClickUp : résultat intéressant mais devient statique. L'IA n'a pas encore l'instinct humain pour maintenir le rythme visuel.

5. **Gérer les ressources.** Effacer le contexte Claude Code entre les sessions (il était à 263k tokens / 1M). Ne pas rendre plusieurs vidéos simultanément pendant qu'on enregistre — ça fait glitcher la webcam.

6. **La valeur cumulative.** Chaque vidéo créée nourrit le studio (skills, design docs, templates). Ce n'est pas un outil ponctuel, c'est un studio qui s'améliore.

---

## Patterns d'usage techniques (Nate Herk)

*(Extrait + synthèse 2026-04-22 de la vidéo ZNbgOhxhzXg — transcript complet avec timestamps dans `data/nateherk/`)*

Cette section complète "Ce que Nate a appris" avec les gestes concrets à reproduire dans Claude Code.

### Pattern 1 — Claude Design comme rampe d'accès sans code

Pour démarrer vite **sans installer Hyperframes**, utiliser Claude Design (app web Anthropic). Workflow court :

1. Design System (logo, couleurs, typo) configuré une seule fois → réutilisé partout
2. Nouveau projet `From Template > Animation` → import MP4 + transcript JSON word-level
3. Répondre aux questions guidées : talking head position / visual energy / motion graphics types / theme / end card CTA
4. Claude Design génère l'animation HTML en ~2 min
5. **Export** (limite clé) : pas de bouton MP4 direct. Deux sorties possibles :
   - **Screen record** la preview full screen (OK pour clips courts)
   - **Hand-off to Claude Code** : bouton dédié qui copie une commande. Coller dans Claude Code → "render this as MP4" → Hyperframes produit le MP4 derrière

> *Limite honnête :* Claude Design ne peut pas transcrire la vidéo. Il faut fournir le transcript timestamped en input. Hyperframes via Claude Code automatise cette étape.

### Pattern 2 — Feedback éditeur humain (timestamped)

Le prompt d'édition doit ressembler à ce qu'on dirait à un monteur humain. Pas de jargon technique. Timestamps explicites.

**Template à copier :**

> "Overall, I like the vibe and the logic. I just need some aesthetic changes.
>
> 1. At about 5 seconds, when the hero title comes in, we can't see it because there's a blur effect on top of it. Move the blur behind the text.
> 2. At 12 seconds, the right half of the percentage sign is blurred and part of the 6 is out of frame. Scale down or re-center.
> 3. The next scene (15s onwards) looks solid — no changes.
>
> Please make those and render V2."

**Pourquoi ça marche :**
- Un défaut = un timestamp précis = une correction isolée
- Ce qui est bon est dit explicitement → Claude ne casse pas ce qui marche
- Pas de "rends ça mieux" flou qui force Claude à tout refaire

### Pattern 3 — Pre-render check frame by frame

Pour éviter un render aller-retour qui gaspille des tokens :

> "Before you ever render or give me any output to review, look at every single frame first, extract all of them, check for alignment/readability/timing issues, fix what you find, and THEN render."

Effet : la V1 qui sort est déjà V2 en qualité. Moins d'itérations nécessaires.

### Pattern 4 — Gestion du contexte long (summary + clear)

Une session Hyperframes mange vite 200-260K tokens (beaucoup d'HTML généré). Avant de saturer :

**Étape 1 — Demander le handoff summary :**

> "Give me a full summary of everything you've built, where the key files are, what design decisions you've made, and what's next. I'm going to clear the session."

**Étape 2 — Clear session (`/clear` ou nouvelle fenêtre).**

**Étape 3 — Coller le summary dans la nouvelle session** + "Continue from here with the feedback below." + feedback.

Gain : la nouvelle session repart à ~5K tokens avec tout le contexte nécessaire, au lieu de hériter de 260K.

### Pattern 5 — Hand-off Claude Design → Claude Code (export MP4)

Claude Design ne rend pas de MP4 directement. Procédure :

1. Dans Claude Design, bouton **"Hand off to Claude Code"** → copie une commande dans le presse-papier
2. Ouvrir Claude Code dans un projet Hyperframes (ou le dossier courant si Hyperframes installé)
3. Coller + "Render this as MP4 at 1080p"
4. Claude Code exécute : HTML (depuis Claude Design) → Hyperframes render → ffmpeg → MP4
5. Fichier disponible dans `renders/`

Astuce : la même logique marche pour convertir n'importe quelle page HTML Claude Design en vidéo.

### Pattern 6 — Un render à la fois (RAM safety)

Nate a eu un facecam glitchy en enregistrant une vidéo pendant que 4 autres rendus tournaient en parallèle. Règle simple :

- **Pendant que Claude Code render** → pas d'enregistrement webcam
- **Max 1 render simultané** par machine standard (16-32 GB RAM)
- Si plusieurs projets à rendre → les queue-r séquentiellement, pas en parallèle

### Pattern 7 — Signal coût réaliste

Pour briefer un client ou pitcher la méthode :

| Métrique | Valeur (Nate, plan Max $200/mois) |
|---|---|
| Context consommé pour 1 projet vidéo complet (30-40s) | 125K à 260K tokens |
| Part de la session 5h Max | ~10% (= 10 projets possibles sur une session) |
| Temps humain effectif | ~20 min de dialogue + itérations (vs 2-3h manuel) |
| Nombre de renders possibles par journée de test | 60+ (Nate a tout testé en 1 journée) |

---

## Patterns d'usage avancés (Nate Herk — vidéo Aw3BkmhYu4I, 2026-04-22)

*(Extrait + synthèse de la nouvelle vidéo "Claude + HyperFrames Just Solved Video Editing" — transcript complet dans `data/nateherk/Aw3BkmhYu4I_*`)*

**Delta clé vs la vidéo précédente (ZNbgOhxhzXg) :** avant, Nate faisait le trim + edit MANUELLEMENT avant de passer Hyperframes. Maintenant, un nouvel outil **`video-use`** automatise le trim/filler/retakes. Le pipeline devient **end-to-end sans intervention humaine sur le trim** :

```
raw .mp4 -> video-use (trim mistakes + filler + retakes + transcription)
         -> handoff
         -> Hyperframes (motion graphics HTML)
         -> ffmpeg (render MP4)
```

### Pattern 8 — `video-use` comme trim automatique

Nouvel outil dans l'écosystème vidéo Claude Code. Scope : trim + filler removal + retakes detection + transcription word-level. Avant lui, Claude ne faisait que les motion graphics, le trim restait manuel dans Descript.

**Prompt type à copier :**

> "Hey Claude Code, I would like you to use the video-use tool just to edit this video. I want you to analyze it. I want you to remove any filler words or silences or retakes. Then we're going to use hyperframes to actually add the motion graphics to it. Your first task is just to edit out the mistakes and the filler words."

Le skill dédié dans video-use s'appelle **"edit only for hyperframes handoff"** — il sort le JSON transcript + l'edited MP4 sans faire les motion graphics. C'est Hyperframes qui prend la suite avec ces 2 fichiers.

### Pattern 9 — Architecture dossier `video projects/<name>/`

Claude crée automatiquement cette structure sur nouvelle demande de montage :

```
video projects/
  <nom-projet>/
    assets/
      clips/              # raw files + edited après video-use
      transcripts/        # JSON word-by-word (ElevenLabs/Whisper)
    compositions/         # beats HTML (1 par scène)
    components/           # reusables (lower-third, caption style, logo)
    final-renders/
    verification-screenshots/
```

Chaque changement dans le timeline editor Hyperframes se reflète dans les HTML compositions et vice-versa.

### Pattern 10 — Plan mode avant motion graphics render

**AVANT** de générer les HTML motion graphics, switcher Claude en **plan mode**. Il lit le transcript timestamped, reçoit la demande en langage naturel, et retourne un plan détaillé (beats, timings, colors, anchors). Sans cramer de tokens en code HTML.

**Bénéfice concret :** économie substantielle de tokens. On approuve ou itère sur le plan, PUIS on exécute le code HTML. Évite le cycle "il a codé 2000 lignes de HTML mais le concept est pas bon".

**Raccourci Claude Code :** Shift+Tab → bascule en Plan Mode.

### Pattern 11 — Training data par type de vidéo

Créer des sous-dossiers par format récurrent :

```
video projects/
  lessons/           # 1 dossier par leçon créée
  intros/            # openers réutilisables
  shorts/            # format 9:16
```

Chaque projet réussi devient référence. Après 3-5 vidéos du même type, Claude peut automatiser l'essentiel via un fichier `<type>-design-philosophy.md` à la racine du dossier type. Citation Nate : "All of these videos are training data. So, let's say I make five different lessons. Now, I can basically say, okay, cool, build a lesson design markdown philosophy file, which means every time I build a lesson, just use that."

### Pattern 12 — Screenshots verification par Claude

Instruire Claude explicitement dans le prompt initial :

> "Take screenshots of what's going on in each scene to make sure that it looks good."

Claude rend une frame PNG, la lit comme image, vérifie visuellement (alignement, crop, texte hors cadre, couleur illisible) avant de valider la scène. Évite les rendus "ça a l'air OK dans le code mais c'est nul visuellement".

Les screenshots vont dans `verification-screenshots/` dans l'architecture Pattern 9.

### Pattern 13 — Timeline editor bidirectionnel

L'UI Hyperframes Studio permet de shorten / delete / move / réordonner les beats directement à la souris. Le changement est **écrit dans le HTML sous-jacent**. À la prochaine itération, Claude voit le changement et le respecte.

**Workflow gagnant :**
1. Claude génère la V1 motion graphics
2. l'utilisateur ouvre `npx hyperframes preview` et ajuste les timings à la souris (drag des beats)
3. l'utilisateur repasse dans Claude Code avec du texte : "now add a subtitle at beat 3"
4. Claude lit le HTML modifié et applique par-dessus les modifs manuelles de l'utilisateur

Raccourci massif pour les ajustements de timing. La UI remplace "à 5.2s le texte part trop vite" par un drag.

### Pattern 14 — Voice-to-text pour prompts longs

Pour donner les specs de motion graphics (scene par scène, 4-10 beats, style, couleurs, sync avec phrases), Nate utilise son outil voice-to-text. Parler est plus naturel que taper pour décrire 20+ specs visuelles séquentielles.

**Avantages concrets :** plus d'infos dans le prompt, phrasé plus naturel qui donne un meilleur parsing Claude, moins de fatigue clavier sur des prompts de 300+ mots.

### Pattern 15 — ElevenLabs API > Whisper pour les cuts

Par défaut Hyperframes utilise **OpenAI Whisper** pour la transcription. Nate a comparé et passe maintenant sur **ElevenLabs API** :

> "Hyperframes likes to default to OpenAI whisper. For this video I am using 11 Labs API because I think that it's actually better at finding the right moments to cut."

**Options disponibles :**

| Transcripteur | Coût | Qualité cuts | Note |
|---|---|---|---|
| OpenAI Whisper API | ~$0.006/min | Bonne | Défaut Hyperframes |
| ElevenLabs API | ~$0.01/min | **Meilleure pour cuts** selon Nate | Choix actuel Nate |
| Whisper local | Gratuit | Bonne | Consomme RAM pendant le process |

Clé à ajouter dans `.env` : `ELEVENLABS_API_KEY=xxx`

### Pattern 16 — Handoff explicite video-use → Hyperframes

Quand on veut que video-use fasse UNIQUEMENT la partie trim/transcription et laisse Hyperframes gérer les motion graphics, demander explicitement :

> "Use the video-use skill 'edit only for hyperframes handoff' on this raw file."

Ce skill dédié sort :
- `edited.mp4` — le MP4 trimmed
- `transcript.json` — le word-level timestamps prêt pour Hyperframes

Puis enchaîner : "Now use Hyperframes to add motion graphics based on `transcript.json`."

Évite que video-use essaie de faire les animations (pas son rôle) ou que Hyperframes refasse le trim (déjà fait).

### Pattern 17 — `.env` obligatoire pour les API keys

**Règle de sécurité rappelée par Nate :**

> "I typically try to avoid just pasting it [API key] straight into the actual chat. The reason for that is just because that would stay in the conversation history and just best practice to not do that."

**À faire :**
- Via VS Code : ouvrir `.env` à la racine du projet, paste la clé
- Via Claude Code Desktop : "Claude Code, create me the .env file and drop my 11Labs API key inside it" puis paste dans l'éditeur de fichier qu'il ouvre

**À éviter :** coller la clé dans le chat Claude, même temporairement. Elle reste dans l'historique de session et peut leak si la session est partagée ou si quelqu'un lit le transcript.

**Règle :** `.env` au `.gitignore`, `.env.example` commité avec les noms de clés sans les valeurs.

### Signal coût actualisé (Aw3BkmhYu4I)

| Métrique | Valeur |
|---|---|
| Vidéo précédente (ZNbgOhxhzXg) | ~260K tokens |
| Nouvelle vidéo (Aw3BkmhYu4I) avec video-use + Hyperframes | **238K tokens** |
| Plafond 5h session $200 Max | ~10-12% par vidéo de 30 min |
| Durée session humain | ~25-30 min de dialogue + itérations |

Conclusion Nate : "This took us about 238,000 tokens. So, not too bad, but not great either because this will eat some tokens. And that's why the more specific you can be with your planning and with your iterating, the better." → **Plan mode (Pattern 10) est ce qui fait la différence.**

---

## CAS 3 — Audio pro avec Auphonic

*(Ajouté 2026-04-21 sur recommandation Jack Roberts — vidéo "Claude just changed Content Creation Forever")*

### Pourquoi

Après le nettoyage Descript (CAS 1) et les motion graphics Hyperframes (CAS 2), il reste souvent un défaut audio subtil : volume inégal, normalisation non-broadcast, bruit de fond résiduel. **Auphonic** est un service web spécialisé dans le mastering audio pour podcasts et vidéos, avec une **API qui permet à Claude Code de traiter l'audio programmatiquement**.

### Ce que Auphonic fait mieux que Descript Studio Sound

- **Leveler adaptatif** : égalise les volumes entre le micro principal et la voix off, même si l'un est fort et l'autre faible
- **Loudness target broadcast** : -16 LUFS (YouTube), -23 LUFS (EBU R128), -14 LUFS (Spotify) — Descript ne fait pas ça
- **Suppression de bruit intelligent** (hum, hiss, click, breathing) — plus précis que Studio Sound
- **Métadonnées + chapitres automatiques**

### Setup

1. Créer un compte sur [auphonic.com](https://auphonic.com) (free tier = 2h audio/mois, plan payant = illimité)
2. Aller dans **Settings > API** et créer une clé API
3. Stocker la clé dans le `.env` du projet vidéo : `AUPHONIC_API_KEY=xxx`

### Intégration dans Claude Code

Prompt type à donner à Claude Code après le render Hyperframes :

> "Awesome, I'd now like you to run the entire audio through Auphonic. Here's my API key in the .env. Let me know when that's complete."

Claude Code fait alors :
1. Extrait l'audio du MP4 Hyperframes avec ffmpeg
2. Upload vers Auphonic via l'API
3. Applique un preset (leveler + loudness + noise reduction)
4. Télécharge l'audio traité
5. Réintègre l'audio propre dans le MP4 final

### Endpoints API Auphonic clés

```bash
# Créer une production (upload + traitement)
POST https://auphonic.com/api/productions.json

# Récupérer le résultat
GET https://auphonic.com/api/production/{uuid}.json

# Télécharger le fichier final
GET https://auphonic.com/download/audio-result/{uuid}/{filename}
```

Docs complètes : https://auphonic.com/help/api/

---

## Repos GitHub de référence

| Repo | Usage | Limite |
|------|-------|--------|
| seedprod/video-editor-for-claude-code | Supprime pauses sur screencasts Claude Code | Détecte message orange "esc" — fonctionne seulement si Claude Code visible |
| barefootford/buttercut | Transcrit + discute les coupes avec Claude | Sort XML timeline (Premiere/DaVinci requis), pas un MP4 |
| digitalsamba/claude-code-video-toolkit | Studio complet (Remotion, ElevenLabs, musique IA) | Trop complexe pour simple nettoyage |

---

## Notebooks NotebookLM de référence

| Notebook | URL | Contenu |
|---|---|---|
| Descript vs Tella vs Loom | https://notebooklm.google.com/notebook/156956d1-7fb1-4bc0-ba10-fdbad75076ce | Comparatif outils montage — 8 sources |
| Montage Claude Code + FFmpeg + Whisper | https://notebooklm.google.com/notebook/ab3d2330-e931-4177-a4ff-6a8fe8825372 | Pipeline technique + repos + prompts — 12 sources |

---

## Sources vidéo clés (triées par pertinence)

| Chaîne | Vidéo | Vues | Lien |
|---|---|---|---|
| Brendan Jowett | How I Fully Automated My Video Editing (Claude Code) | 47k | https://youtube.com/watch?v=G0EH0xdy2-E |
| Nate Herk | Claude Just Destroyed Every Video Editing Tool | 152k | https://youtube.com/watch?v=ZNbgOhxhzXg |
| **Nate Herk** | **Claude + HyperFrames Just Solved Video Editing** (video-use end-to-end) | **7.5k** | **https://youtube.com/watch?v=Aw3BkmhYu4I** |
| Ben AI | Claude Code Changed Content Creation Forever | 21k | https://youtube.com/watch?v=BJuevX91ExM |
| Brendan Jowett | How To Edit Videos With Claude Code | 20k | https://youtube.com/watch?v=3hzXfTjqiKg |
| **Jack Roberts** | **Claude just changed Content Creation Forever** (Hyperframes walkthrough + Auphonic) | **7k** | **https://youtube.com/watch?v=34VoezbEvLw** |
| Kevin Stratvert | Descript AI Video Editing Tutorial 2024 | 100k | https://youtube.com/watch?v=Dk1TxDKzb68 |

---

## Prompts exacts des créateurs (source : NotebookLM 2026-04-21)

Ces prompts sont copiables tels quels dans Claude Code.

### 1. MEGA PROMPT — Créer un skill réutilisable (Ben AI)

> ⚠️ **STATUT : À EXPÉRIMENTER — non validé en prod (2026-04-21)**
> L'approche tout-automatique via Claude Code (assembly + transcription + cuts automatiques) s'est révélée trop complexe et peu fiable en pratique. Confirmé par les deux notebooks NotebookLM. L'outil évolue vite → re-tester dans 3-6 mois. **Pour l'instant : CAS 1 = Descript (GUI), Claude Code = seulement CAS 2 (Hyperframes/animations).**

À utiliser UNE FOIS après avoir fait un premier montage réussi. Claude mémorise tout le process et crée une commande `/YouTube edit` réutilisable pour toutes les vidéos suivantes.

> "now I want you to create a new skill that follows this exact process of editing my YouTube videos so every time this YouTube editing skill is invoked I want you to stitch together the videos transcribe the videos always then suggest um parts of text to highlight for me when I confirm the text to highlight use the exact style of the one that we had that we did here to highlight the texts also suggest me a part of the script to add in the overlay um sped up version and also suggest me parts of the video where we can add in transition slides in the same style that we did in this uh project lastly suggest me one or two clips that would be under five minutes and interesting to share on LinkedIn when I confirm use the same style of captions and cut it up for LinkedIn"

### 2. Prompt — Assembler et transcrire plusieurs clips
Quand on a enregistré par petits morceaux (ex: via Tella) et qu'on veut tout assembler avant de travailler.

> "first stitch the videos together into one long video and also transcribed the video so you understand what this video is about"

### 3. Prompt — Couper par sujet (langage naturel)
Pour garder uniquement les passages qui parlent d'un sujet précis, sans avoir à indiquer des timestamps.

> "keep only the parts where kind of Claude goes off the rail and goes crazy"
> "only keep the clips that talk about money"

### 4. Prompts — Créer des clips LinkedIn depuis un long enregistrement

> "identify from the transcript um when I switch over from one to the other and cut it up into three different clips for LinkedIn i don't want the intro for LinkedIn"

Pour les sous-titres cohérents sur les clips LinkedIn :

> "for LinkedIn is I want to add captions in the same style that we have done before uh like the highlights for the entire video for LinkedIn"

---

## Prochaines étapes

1. [x] Récupérer le Breakdown Sheet de Brendan Jowett — ✅ 2026-04-21 via `/skool-scraper` → `data/brendanjowett/brendan-jowett-breakdown-sheet.md`
2. [x] Guide d'enregistrement — ✅ 2026-04-21 → ajouté dans ce skill + page Notion
3. [ ] Tester Descript sur une vraie vidéo de formation de l'utilisateur (5-10 min)
4. [ ] Vérifier si Descript recorder suffit ou si Tella reste nécessaire
5. [ ] Setup Remotion dans Claude Desktop App (demander "install Remotion" — setup automatique)
6. [ ] Créer le skill `/video-edit` réutilisable (utiliser le MEGA PROMPT de Ben AI après premier montage réussi)
