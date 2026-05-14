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
