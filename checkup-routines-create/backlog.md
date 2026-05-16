# Backlog routines — demandes depuis comptes secondaires

> **Synced cross-PC + cross-account** via skill `/migration-pc` (repo `~/.claude/`).
> **Consommé** uniquement par main account routines (`florent.maisoncelle@gmail.com`) au début de chaque invocation `/routine-create`.
> **Format** : append-only, 1 demande = 1 bloc. Cf SKILL.md Phase 0bis bis.

---

## verif-dictee-dico-apps-ia-daily — 2026-05-13

**Statut** : 🟢 open
**Compte secondaire source** : ton-email@exemple.com (session worktree gallant-panini-1679bc speak-app-dev)
**Type** : create
**Cadence souhaitée** : daily (tous les 3 jours acceptable, 1h-5h Paris)
**Skill orchestrateur invoqué dans prompt** : `/test-dictionnaire-intelligent` + `/stt-health-check` + `/vosk-dictation-health-check`
**Repo concerné** : `speak-app-dev`

### Objectif fonctionnel
Vérifier en autonomie que la **dictée** (STT Gladia/Deepgram/Vosk) et le **dictionnaire intelligent V1** (silent learn cross-platform) fonctionnent toujours correctement sur **apps IA cibles** : Claude.ai (Chrome WS Bridge), ChatGPT, Gemini, AntiGravity (CDP), Claude Desktop (UIA BP-046). Output = rapport `memory/reports/verif-dictee-dico-apps-ia-daily-YYYY-MM-DD.md` qui résume health par plateforme + alertes si régression.

### Critères de vérification
- **STT health** : `logs/stt_calls.jsonl` last 24h → success rate ≥95%, retry rate <10%, fallback rate <5% par engine (Gladia/Deepgram/Vosk). Top 3 erreurs si présentes.
- **Dico silent learn AG** : `logs/dict_intelli_calls.jsonl` last 24h → fires depuis plateforme AG présents (cherche `platform=ag` OU `[DictIntel-AG]` dans debug.log) + dernière capture (`workspace_hint` propagé BP-389 visible ws=`<workspace>` logs).
- **Dico silent learn Chrome** : pareil pour `platform=claude_chrome|claude_code|chatgpt|gemini` — fires depuis WS Bridge `user_message_posted` event présents si Florent a dicté.
- **Dico silent learn CD** : `cd_sent_text_capturer` polling actif (BP-046) — fires si Florent a dicté dans CD.
- **Vosk health** : `logs/vosk_events.jsonl` last 24h → success keyword→action ≥90%, reject rate <15%.
- **Régression watchdog port 9222** : grep `debug.log` last 24h pour erreurs CDP contention (`CDP probe failed` simultané à `DictIntel-AG capture error`) → 0 attendu après BP-389.

### Notes / contexte
- BP-389 livré 2026-05-13 (commit local `b3c0cd41`, pas encore pushed) : fix `_di_capture_ag_user_turn` wrap `with _ag_fetch_lock:` + cooldown par session + propagation `workspace_hint`. Cette routine doit valider en continu que la contention port 9222 ne réapparaît pas.
- Feature doc maître : `memory/features/dictionnaire-intelligent.md` (V1 livré, validation N4 user pending).
- Skills health-check existants à composer : `/stt-health-check` (Gladia/Deepgram), `/vosk-dictation-health-check` (Vosk). Cette routine = wrapper qui ajoute le volet "dico cross-platform" et croise avec STT health.
- **VÉRIFIER D'ABORD si routine équivalente existe déjà** côté cloud (`RemoteTrigger list | grep -i dictee\|dico`) OU locale (`ls ~/.claude/scheduled-tasks/ | grep -i dictee\|dico`). Si oui → mode `verify-existing` (audit specs vs ce backlog, optimize si drift). Si non → mode `create` Phase 1 (cloud Sonnet, repo speak-app-dev attaché).

---

## veille-gladia-streaming-options — 2026-05-15

**Statut** : 🟢 open
**Compte secondaire source** : compte secondaire — Florent confirmé 2026-05-15. (Champ `userEmail` système affichait `florent.maisoncelle@gmail.com` mais Florent a indiqué explicitement NON-main → détection compte non fiable cette session, se fier au verbatim Florent.)
**Type** : create
**Cadence souhaitée** : mensuelle (Florent verbatim : « tous les mois ou tous les deux mois »)
**Skill orchestrateur invoqué dans prompt** : aucun skill orchestrateur existant — routine de veille directe (WebFetch doc Gladia). À la création, suivre Phase 1 (cloud de préférence : WebFetch only, aucun fichier local requis).
**Repo concerné** : `speak-app-dev`

### Objectif fonctionnel
Veille externe mensuelle : vérifier si l'API **streaming** de Gladia (`/v2/live`) propose désormais les options `punctuation_enhanced` et/ou `sentences`. Actuellement (vérifié 2026-05-14, cf BP-416) ces options sont **batch-only** — l'API `/v2/live` ne les supporte pas. Comme la dictée user SpeakApp est en **streaming par défaut** (doctrine `path-streaming-vs-batch-dictation`), elle ne bénéficie d'aucune ponctuation enrichie. Si Gladia ajoute ces options au streaming → **notifier Florent** : SpeakApp pourrait alors les activer dans `stt_engine.py:_start_listening_gladia` et la dictée quotidienne gagnerait une vraie ponctuation.

### Critères de vérification
- WebFetch `https://docs.gladia.io/api-reference/v2/live/init` (+ pages live-stt features si pertinent) → chercher `punctuation_enhanced` et `sentences` dans les paramètres de l'API live/streaming.
- Si AUCUN des deux trouvé → rapport « no action — OK » (état inchangé depuis 2026-05-14).
- Si l'un ou l'autre apparaît → **ALERTE** : notifier Florent + pointer `dictee-vocale.md` § Décisions stratégiques `formatage-texte-dicte-options-gladia` (la condition de re-évaluation anti-yoyo y est gravée : « Gladia ajoute punctuation_enhanced/sentences à /v2/live → les activer aussi côté streaming »).

### Notes / contexte
- Décision stratégique source : `memory/features/dictee-vocale.md` § Décisions stratégiques `formatage-texte-dicte-options-gladia` (gravée 2026-05-14).
- État des options Gladia batch vs streaming : `memory/core/stt-routing.md` § « Options API Gladia (payload envoyé) ».
- BP lié : BP-416 — activation `punctuation_enhanced` + `sentences` sur le flow **batch** Gladia (commit `a6ff904b`, repo speak-app-dev).
- Routine = veille pure, sans urgence — c'est un filet pour ne pas rater un upgrade Gladia. Cloud de préférence (WebFetch only). Cadence mensuelle suffit.
- **VÉRIFIER D'ABORD si routine équivalente existe déjà** côté cloud (`RemoteTrigger list | grep -i gladia`) OU locale (`ls ~/.claude/scheduled-tasks/ | grep -i gladia`). Si oui → mode `verify-existing`. Si non → mode `create` Phase 1.

---

## cd-multi-panel-regression-guard — 2026-05-15

**Statut** : 🟢 open
**Compte secondaire source** : session worktree distracted-mccarthy-3c8546 speak-app-dev (`mcp__scheduled-tasks__create_scheduled_task` indisponible en mode unsupervised — n'a pas pu exec, demande tracée ici).
**Type** : create
**Cadence souhaitée** : hebdomadaire, dimanche 4h Paris (`cron 0 4 * * 0`)
**Skill orchestrateur invoqué dans prompt** : aucun — routine = lance directement 2 suites pytest + écrit rapport.
**Repo concerné** : `speak-app-dev`
**⚠️ À créer `enabled: false` jusqu'à la v2** — cf décision gravée `project_routines-disabled-until-v2-2026-05-14.md` (toutes les routines SpeakApp désactivées jusqu'à v2) + précédent `toast-platform-coverage-checkup` (créée puis désactivée dans la foulée). Routine = LOCALE (pytest + fichiers locaux requis → pas cloud).

### Objectif fonctionnel
Garde anti-régression de la détection/routing Claude Desktop multi-panneau (1/2/3/4 panneaux + grille 2×2). Vérifie dans le temps que le pipeline qui identifie « quelle session est dans quel panneau » continue de marcher. Une régression silencieuse = SpeakApp cible la mauvaise session en split-view → bug invisible jusqu'à ce qu'un user le remarque (c'est exactement le bug que BP-414 a corrigé). Output = rapport `memory/reports/cd-multi-panel-regression-guard-<YYYY-MM-DD>.md`.

### Critères de vérification
- Lancer avec l'interpréteur Python 3.14 de l'app (`C:\Users\Administrateur\AppData\Local\Python\pythoncore-3.14-64\python.exe -m pytest`) :
  - `tests/test_cd_split_detector.py -q` → **26/26 attendus** (BP-414. Classe `DetectCdSplitScreenPanelCountTests` = 10 tests couvrant explicitement `detect_cd_split_screen` sur 1/2/3/4 panneaux + grille 2×2 + filtres géométrie/non-dframe + ordre de lecture + rightmost déterministe + focused wiring).
  - `tests/test_cd_session_resolver.py -q` → **29/29 attendus** (BP-404, sœur de BP-414 — cascade resolver M0-M4 détection session multi-panneau).
- 2 suites vertes → `no action — OK`.
- ≥1 test FAIL → régression du pipeline CD multi-panneau : identifier le(s) test(s), `git log -5` sur `tools/cd_split_detector.py` + `cd_session_resolver.py`, ouvrir un ticket dans le Plan vivant de `memory/features/chat-reader.md`. NE PAS fixer en autonomie — seulement tracer.

### Notes / contexte
- BP-414 livré 2026-05-14 (commit `cd26f8b4` code + `f5d81cdb` tests). Réécriture `detect_cd_split_screen` : scan `Group class~"dframe-pane"` (bbox uniques) au lieu de 2 noms UIA hardcodés → gère 1/2/3/4 panneaux. Sœur BP-404 (`cd_session_resolver` cascade M0-M4).
- Doc maître : `memory/references/bug-patterns.md` BP-414 + BP-404 · feature doc `memory/features/chat-reader.md` (Phase A.6).
- SKILL.md template canonique = Phase 2.4 (`### Rapport local (OBLIGATOIRE)` + `memory/reports/` + `Note 2026-05-09` obligatoires — validation gate Phase 1.4bis). Prompt complet déjà rédigé dans la session source, peut être repris tel quel.
- **VÉRIFIER D'ABORD si routine équivalente existe déjà** : `ls ~/.claude/scheduled-tasks/ | grep -i "cd-multi-panel\|cd-split"`. Si oui → `verify-existing`. Si non → `create` Phase 2 (LOCAL, `enabled: false`).

---
