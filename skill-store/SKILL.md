---
name: skill-store
description: Skill GLOBAL gérant le vivier (store) de skills dormants — stocker / récupérer / lister. Permet d'économiser tokens en sortant skills peu utilisés du chargement automatique sans les supprimer. 2 stores supportés : projet (`.claude/skills-store/`) + global (`~/.claude/skills-store/`). INDEX.md = pointeur consultable on-demand. Trigger : "/skill-store", "stocker skill", "récupérer skill", "skill au store", "ressors skill", "skills dormants", "skill pas trouvé" (auto-lookup INDEX), "vivier skills".
trigger: "stocker skill", "stock", "récupérer skill", "ressors", "INDEX skills", "skills dormants", "skill pas trouvé", "vivier"
scope: gestion lifecycle skills actifs ↔ stockés (déplacement folder + INDEX + commit)
---

# Skill Store — Vivier de skills dormants

## Philosophie

**Problème** : chaque skill chargé = description en tokens × N sessions. Skills peu utilisés (1× / mois ou ponctuels) coûtent autant que skills quotidiens.

**Solution** : sortir skills dormants du chargement auto sans les supprimer. Stocker dans `skills-store/` (PAS scanné par Claude). INDEX.md = pointeur consultable on-demand.

**Workflow lazy-read** :
1. Skills actifs `.claude/skills/` → descriptions chargées chaque session (coût tokens)
2. Skills stockés `.claude/skills-store/` → PAS chargés (zéro coût tokens default)
3. INDEX.md `.claude/skills-store/INDEX.md` → 1 ligne par skill stocké (description résumée)
4. Si Claude/Florent cherche skill non trouvé → consulter INDEX → ressortir si match

---

## 2 stores supportés

| Store | Path | Pour |
|-------|------|------|
| **Projet** | `.claude/skills-store/` | Skills SpeakApp-spécifiques peu utilisés |
| **Global** | `~/.claude/skills-store/` | Skills universels rarement utilisés (legal-*, infographic, formation-*, etc.) |

**Règle** : skill stocké reste dans son scope d'origine. Skill projet → store projet. Skill global → store global.

---

## Workflow A — Stocker skill (sortir du chargement)

```bash
# 1. Vérifier scope skill (projet vs global)
ls .claude/skills/<skill-name> 2>/dev/null && SCOPE="projet" || SCOPE="global"

# 2. Move vers store
if [ "$SCOPE" = "projet" ]; then
  mv .claude/skills/<skill-name> .claude/skills-store/<skill-name>
  STORE_INDEX=".claude/skills-store/INDEX.md"
else
  mv ~/.claude/skills/<skill-name> ~/.claude/skills-store/<skill-name>
  STORE_INDEX="~/.claude/skills-store/INDEX.md"
fi

# 3. Ajouter ligne INDEX (description résumée 1 ligne)
# Format : | <skill-name> | <usage 1 phrase> | <quand récupérer> | <date stock> |

# 4. Commit (si projet) — sync (si global via /sync-claude-home)
git add .claude/skills-store/ && git commit -m "chore(store): stocker /<skill-name> (peu utilisé)"
```

## Workflow B — Récupérer skill (réactiver)

```bash
# 1. Localiser dans store
[ -d .claude/skills-store/<skill-name> ] && SCOPE="projet" || SCOPE="global"

# 2. Move retour vers skills/
if [ "$SCOPE" = "projet" ]; then
  mv .claude/skills-store/<skill-name> .claude/skills/<skill-name>
else
  mv ~/.claude/skills-store/<skill-name> ~/.claude/skills/<skill-name>
fi

# 3. Retirer ligne INDEX

# 4. Commit / sync
git add .claude/ && git commit -m "chore(store): ressortir /<skill-name> (réactivation)"
```

## Workflow C — Skill pas trouvé (lookup INDEX)

Quand Claude/Florent cherche skill `/X` non trouvé dans `/help` ou skills list :
1. Lire `.claude/skills-store/INDEX.md` projet
2. Lire `~/.claude/skills-store/INDEX.md` global
3. Match nom ou usage → proposer ressortir
4. Pas de match → skill n'existe vraiment pas, créer via `/skill-builder`

---

## Format INDEX.md

```markdown
# Skill Store — INDEX

> Skills stockés (pas chargés auto). Récupérer via `/skill-store récupérer <name>`.

| Skill | Usage 1 phrase | Quand récupérer | Stocké le |
|-------|---------------|-----------------|-----------|
| `cd-devtools-inject` | Inject JS dans DevTools console CD via clavier+clipboard | Re-investigation DevTools CD (deprecated BP-033) | 2026-05-02 |
| `python-migrate` | Procédure migration Python 3.X→3.Y avec gates rollback | Prochaine migration Python | 2026-05-02 |
| ... |
```

---

## Règles

1. **Stocker = pas supprimer** — `mv`, jamais `rm`. Skill récupérable à tout moment.
2. **INDEX 1 ligne par skill** — usage résumé bref. Détails restent dans SKILL.md du skill stocké.
3. **Scope intact** — skill projet → store projet. Skill global → store global. Pas de cross-scope sans raison.
4. **Commit atomique** — `mv` + INDEX update dans même commit.
5. **Pas de stock agressif** — skill utilisé même rarement (1× / 2 mois) reste actif si gain tokens marginal vs coût récupération.
6. **Lookup avant créer** — chercher dans INDEX (les 2) AVANT de créer skill nouveau (évite doublon avec stocké oublié).

---

## Anti-patterns

- ❌ `rm -rf .claude/skills/X` — perdu à jamais. Toujours `mv` vers store.
- ❌ Stocker sans MAJ INDEX — skill devient invisible (perdu sans grep).
- ❌ Stocker skill quotidien — gain tokens nul vs friction réactivation constante.
- ❌ Cross-scope mv (projet → store global) sans raison — perd contexte projet.
- ❌ Créer skill avant lookup INDEX — risque doublon avec stocké.

---

## Quand NE PAS utiliser

| Situation | Skill plutôt |
|-----------|--------------|
| Créer skill nouveau | `/skill-builder` |
| Audit/cleanup skills actifs | `/claude-md-skill-cleanup` Workflow C |
| Renommer skill (cohérence préfixe) | `/claude-md-skill-cleanup` §3ter |
| Supprimer définitivement skill | NE PAS — toujours stocker (récupérable plus tard) |

---

## Exemples

| Action | Commande |
|--------|----------|
| Stock projet `cd-devtools-inject` | `mv .claude/skills/cd-devtools-inject .claude/skills-store/` + INDEX add |
| Récup projet `python-migrate` | `mv .claude/skills-store/python-migrate .claude/skills/` + INDEX remove |
| Stock global `infographic` | `mv ~/.claude/skills/infographic ~/.claude/skills-store/` + INDEX global add |
| Lookup "skill pour debug GIL ?" | `cat .claude/skills-store/INDEX.md` → match `gil-thread-debug` → propose récup |
