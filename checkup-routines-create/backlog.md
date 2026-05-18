# Backlog routines à propager — `/checkup-routines-create`

Append-only. Une demande = 1 bloc YAML+md. Format canonique : skill `/checkup-routines-create` Phase 0bis bis.

**Workflow main account consommation** : lire entries `🟢 open` → pour chaque vérifier si routine existe cloud (`/schedule list`) ou locale (`~/.claude/scheduled-tasks/<slug>/`) → créer/optimize selon manque → marquer `[✅ traité YYYY-MM-DD commit <hash>]`.

---

## speakapp-dictionnaire-intelligent-daily — 2026-05-18

**Statut** : 🟢 open (sera `✅ traité YYYY-MM-DD commit <hash>` après exec main account quand infra remote remonte)
**Compte secondaire source** : main account `florent.maisoncelle@gmail.com` (CONFIRMÉ par Florent — pas un cas compte secondaire, mais entrée backlog car infra remote claude.ai temporairement down)
**Type** : create (cloud propagation)
**Cadence souhaitée** : cron `0 9 * * *` UTC (= 10h Paris hiver / 11h Paris été)
**Skill orchestrateur invoqué dans prompt** : direct (référence doc canonique repo `docs/routines-migration/speakapp/speakapp-dictionnaire-intelligent-daily/00-contexte/...config.md` §5)
**Repo concerné** : `speak-app-dev` (https://github.com/Gremelinn0/wisper-app)

### Objectif fonctionnel
Healthcheck quotidien Dictionnaire intelligent SpeakApp — voie 1 silent learn (BP-100/208/213) + voie 2 Smart Error Detect (BP-449 V1.x). Rapport `logs/feature_health_dictionnaire_<date>.md` généré chaque matin avec verdict OK / JAUNE / ORANGE / ROUGE et actions recommandées. Détecte régressions silencieuses (popup legacy réactivé, adaptive figé, FP émergents) sans intervention Florent.

### Critères de vérification
- Carte routine visible https://claude.ai/code/scheduled avec bon nom + cron + repo + model (Sonnet 4.5)
- Premier run on-demand génère `logs/feature_health_dictionnaire_<date>.md` parsable
- Verdict global = OK (système DICO sain confirmé snapshot 2026-05-11)
- Pipeline analyse logs (`tools/analyze_dico_smart_logs.py` via `py` launcher Python 3.12) opérationnel

### Notes / contexte
- **Infra Anthropic temporairement down** : `/schedule create` retourne *"We're having trouble connecting with your remote claude.ai account to set up a scheduled task. Please try /schedule again in a few minutes."* (tentée 2× le 2026-05-18 sans succès).
- Florent verbatim "azy go" → consentement explicite à propager, juste blocage infra externe.
- Doc routine + cron + prompt + tools + model **prêts à l'emploi** — copier-coller la spec dans `/schedule create` quand l'infra revient suffira.
- Lien feature doc : `memory/features/dictionnaire-intelligent.md` § Plan vivant ticket `propagate-routine-cloud-dico-blocked-infra-2026-05-18` (open P2)
- Lien skill owner : `/dico-logs` (pattern inaugural `/<feature>-logs`, BP-449 V1.2)
- Lien doc config routine : `docs/routines-migration/speakapp/speakapp-dictionnaire-intelligent-daily/00-contexte/speakapp-dictionnaire-intelligent-daily-config.md`
- BPs référence : BP-100 (popup legacy disabled), BP-208 (adaptive intensity), BP-213 (trivial punct skip), BP-449 (smart error detect V1.x)
- Pipeline d'analyse validé fonctionnel via workflow §5 skill `/dico-logs` (Run snapshot `py tools/analyze_dico_smart_logs.py --all` OK, rapport `daily-dico-fp-monitoring-2026-05-11.md` parsable, verdict ⚠️ WARN minimal sur `voilà` 34.7% sans ALERT).
