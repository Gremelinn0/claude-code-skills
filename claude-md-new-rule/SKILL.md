---
name: claude-md-new-rule
description: Crée 1 règle CLAUDE.md daily-use — check archive, audit 4Q (déjà couverte/hook/skill/scope), compression ≤2 lignes, placement large→spécifique, validation Florent, écriture atomique. Triggers "ajoute règle", "grave règle", "nouvelle règle". Délègue cleanup/audit/rename à parent /claude-md-skill-cleanup.
---

# claude-md-new-rule

Skill enfant léger de `/claude-md-skill-cleanup`. Scope = **1 règle nouvelle**, daily-use. Doctrine + cleanup + audit skills restent dans parent.

CLAUDE.md = budget tokens × N sessions × M projets. Ce skill garantit qu'aucune règle n'y entre sans audit + compression.

## Sommaire

- §1 Quand m'invoquer (vs parent)
- §2 Workflow 6 phases
- §3 Heuristiques placement
- §4 Compression express
- §5 Anti-patterns
- §6 Exemple end-to-end
- §7 Refs parent

## §1 Quand m'invoquer (vs parent)

| Demande Florent | Skill |
|-----------------|-------|
| "ajoute règle X" / "grave Y" / "nouvelle règle Z" / "Florent veut W" | **moi** (1 règle) |
| "nettoie CLAUDE.md" / "compresse" / "audit skills" / "rename skill" | **parent** (full-fichier) |
| ≥ 2 règles à graver d'un coup | **parent** (Workflow A) |

Garde-fou : si scope dépasse 1 règle isolée → switch explicite "Cette demande relève de `/claude-md-skill-cleanup`".

## §2 Workflow 6 phases

### Phase 0 — Check archive (~5s)

`Read memory/archive/claude-md-rules-archive/README.md` (projet courant).
- Variante existe → restaurer (skill ciblé > CLAUDE.md projet > **jamais global**)
- Déjà couverte ailleurs → dire "déjà à <path>", STOP, pas de duplication
- MAJ `_restored/<date>/` si restauration

→ Détails parent §3 Phase 0.

### Phase 1 — Audit 4 questions (parent §2.2)

Répondre EXPLICITEMENT (1 ligne par question) :

1. **Existe déjà ?** Grep CLAUDE.md projet + global + skills. OUI → étendre, STOP.
2. **Hook ou skill mieux ?** Trigger auto pré/post → hook (étendre PATTERNS, pas créer). Feature/plateforme → skill. NON aux 2 → CLAUDE.md.
3. **Vraiment transverse ?** S'applique sur autre feature demain ? NON → skill projet. OUI → continuer.
4. **Scope projet ou global ?** Arbitrer EXPLICITEMENT Florent (PAS trancher seul). Critères global parent §2.1 (3/3 : transverse, light, validé).

### Phase 1bis — Audit règles voisines DURE (gate avant Phase 2)

Q1 Phase 1 = grep keyword brut. Insuffisant. Phase 1bis force la chasse thématique + biais fusion.

**Process obligatoire** :

1. Identifier thème règle (cf. §3 placement → cible sous-§)
2. `Grep` toutes les règles existantes dans le sous-§ cible (CLAUDE.md projet + global + skill parent si pertinent)
3. Lister les **3 règles les plus voisines** sémantiquement (titre + ligne + 1 phrase résumé)
4. Pour CHAQUE voisine, décider :
   - 🟢 **FUSION inline** (compléter règle existante avec phrase/clause supplémentaire) ← **biais par défaut**
   - 🟡 **EXTEND** (ajouter sous-bullet sous règle existante)
   - 🔴 **### nouveau adjacent** (DERNIER recours — justifier pourquoi fusion impossible)
5. Présenter Florent : voisines identifiées + recommandation par défaut + alternatives

**Format présentation** :
```
RÈGLES VOISINES (sous-§ <X>) :
1. "<titre voisine 1>" (ligne N) — résumé 1 phrase
2. "<titre voisine 2>" (ligne M) — résumé 1 phrase
3. "<titre voisine 3>" (ligne P) — résumé 1 phrase

RECO : FUSION inline dans #1 — clause "<bout de phrase à ajouter>"
ALTERNATIVES : (a) EXTEND #2 sous-bullet (b) ### nouveau adjacent #1 (justif : ...)

Ton choix ?
```

**Anti-pattern bloquant** :
- ❌ Créer ### nouveau alors que règle voisine cousine existe à 3 lignes au-dessus
- ❌ Sauter Phase 1bis quand Phase 1 Q1 répond NON (thème peut exister sans match keyword direct)
- ❌ Présenter "voisine = aucune" sans avoir listé 3 candidates explicitement

**Cas concret violation 2026-05-02** : règle "trigger chip → spawn_task" ajoutée comme `### Trigger "chip"` adjacent à `### Prompt généré` au lieu de fusion inline (1 phrase) dans la règle existante. Florent : "il faut d'abord trouver la bonne règle ou les bonnes règle pour la compléter ok ?!". Refactor commit `a7361e89` après-coup.

### Phase 2 — Compression forcée ≤ 2 lignes

**6 coupes systématiques** :
- Coupe "Pourquoi cette règle existe" prose
- Coupe "Cette règle COMPLÈTE/REMPLACE/PRÉCISE..."
- Coupe descriptifs déductibles ("Visible", "Stocké", "Survit")
- Coupe "sauf X" / "parce que Y" justifications
- Coupe sub-rules adjacentes (relégué skill)
- Coupe meta-infrastructure (paths automation → skill)

**Format final imposé** :
```
### Titre court

Règle 1-2 phrases. Verbatim daté COURT si gravage marbre.
- Anti-pattern 1
- Anti-pattern 2 (si comportement non-évident)
```

**Cible numérique** : 3-8 lignes idéal, 15 max absolu. > 15 → revoir Phase 1 (probablement skill).

→ Patterns détaillés + exemple 19→6 lignes : parent §5.

### Phase 3 — Placement (large→spécifique)

1. Identifier thème règle (cf. §3 ci-dessous)
2. Localiser sous-§ thématique dans CLAUDE.md cible
3. Au sein du sous-§, ordre = cardinale → dérivée → cas particulier
4. Si règle "complète X" / "précise X" → APRÈS X
5. Si cite/référence depuis autres → AVANT (cardinale)

**Output** : "Insérer après ligne N (voisine = '<titre>'), avant ligne M, justification = cardinale/dérivée/particulier".

### Phase 4 — Présentation Florent + validation (GATE)

```
RÈGLE COMPRESSÉE :
<bloc final>

PLACEMENT :
Fichier : <path CLAUDE.md projet|global>
Position : ligne N, après "<voisine>"
Thème : <sous-§>

JUSTIF :
- Audit 4Q : Q1=non, Q2=non, Q3=oui, Q4=<arbitrage>
- Archive : pas trouvé
- Compression : -X% vs verbatim brut
```

ATTENDRE GO EXPLICITE. Pas d'écriture sans validation.

### Phase 5 — Écriture atomique + log

1. `Edit` CLAUDE.md cible (1 opération atomique)
2. Vérifier voisine cite toujours bien (pas de regression)
3. Logger parent §7 : `YYYY-MM-DD — new-rule — <thème> — <delta lignes>`
4. Recap 1 ligne : "Gravée. Ligne N. Compress -X%."

## §3 Heuristiques placement

| Thème règle | Sous-§ CLAUDE.md cible |
|-------------|------------------------|
| Workflow général (autopilote, validation produit, sub-agents) | §3 Workflow |
| Style/communication (ton, format réponse, recap) | §3 Style |
| Mindset (User-first, économie tokens, gravage marbre) | §3 Mindset |
| Architecture/code (simple, e2e, conventions) | §3 Architecture |
| Plateformes IA (CD/AG/Chrome/CLI) | §3 Plateformes |
| Tests/validation (live, E2E, lecture chat) | §3 Tests |
| Docs/meta (skills, hooks, MEMORY, archive) | §3 Docs-meta |

**Aucun match** → STOP, signal règle = skill-candidate, PAS CLAUDE.md inline. Revoir Phase 1 Q2/Q3.

## §4 Compression express

Avant Phase 4, vérifier suppression de :
- ❌ "Pourquoi cette règle existe : ..."
- ❌ "Cette règle COMPLÈTE/REMPLACE..."
- ❌ "Cas inaugural <date>" (→ skill ou commit message)
- ❌ Tables > 8 lignes inline (→ skill)
- ❌ Exemples > 1 (garder 1 max si contre-intuitif)
- ❌ Verbatim Florent > 1 phrase (reformuler règle 1 ligne + verbatim court entre quotes)

## §5 Anti-patterns

- Sauter Phase 0 (check archive) → recréer règle archivée = drift inverse
- Sauter Phase 1 Q4 (arbitrage projet/global Florent) → défaut silencieux global = pollution
- Sauter Phase 4 (validation) → écriture sans go = violation gate
- Écrire CLAUDE.md sans avoir tenté skill/hook (Phase 1 Q2)
- Charger parent `/claude-md-skill-cleanup` pour 1 règle (lourd 600 lignes — moi suffis)
- Dupliquer contenu parent ici (tables, Workflow A/C, store §3quater) — référencer
- Format final non-respecté (manque source datée OU anti-patterns si non-évident)
- Placement chronologique au lieu de large→spécifique

## §6 Exemple end-to-end

### Input brut Florent (2026-05-02)
> "ajoute règle : à chaque édition d'un hook .py il faut vérifier qu'il est déclaré dans .claude/settings.json sinon il sert à rien, on a perdu 2h cette semaine à debug pour rien"

### Phase 0 — Archive
Grep README archive "hook"/"settings.json" → 0 hit. Continue.

### Phase 1 — Audit 4Q
- Q1 Existe ? Grep CLAUDE.md "settings.json" → §3 Docs-meta mentionne hooks mais pas check pré-edit. NON.
- Q2 Hook/skill mieux ? **OUI candidate hook** : pattern `tools/.*_hook\.py` dans `preflight_hook.py` PATTERNS → injection rappel "vérifie déclaration settings.json".
- Q3/Q4 : moot (hook gagne).

→ **Décision : MIGRATE vers hook, PAS CLAUDE.md inline.**

### Phase 4 — Présentation
```
PROPOSITION : NE PAS écrire dans CLAUDE.md.
Cible recommandée = pattern dans preflight_hook.py PATTERNS.
Règle compressée 3 lignes prête si tu insistes CLAUDE.md.
Ton arbitrage ?
```

### Phase 5 (après go "ok hook")
Edit `tools/preflight_hook.py` PATTERNS → `r"tools/.*_hook\.py$"` + msg.
Log parent §7 : `2026-05-02 — new-rule — docs-meta hook check — 0 lignes CLAUDE.md, +3 lignes preflight_hook`.

**Leçon** : bon résultat ≠ toujours écrire dans CLAUDE.md. Skill = arbitrage hook/skill avant écriture.

## §7 Refs parent

| Besoin | Section parent |
|--------|----------------|
| Doctrine économie tokens | §1 |
| Scope skill global vs projet | §2.1 |
| Table cible règle (4 options) | §2.2 |
| Phase 0 check archive détails | §3 Phase 0 |
| Ordre large→spécifique | §3 Phase 1 |
| Patterns compression 1-6 + exemple 19→6 lignes | §5 |
| Anti-patterns CLAUDE.md génériques | §6 |
| Format journal | §7 |
| Hooks projet où sont-ils définis | §8 |

Switch explicite si scope dépasse 1 règle : "Cette demande relève de `/claude-md-skill-cleanup` (cleanup full / audit skills / rename). Switch parent ?"
