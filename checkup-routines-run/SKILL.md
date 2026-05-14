---
name: checkup-routines-run
description: DEPRECATED — fusionné dans `/checkup-routines-create` (skill canonique routines). Pour lancer une routine à la demande, utiliser `/schedule run <slug>` (cloud) OU `/checkup-routines-create run [scope]` (local on-demand via sub-agents Sonnet, dépôt-aware). Ce skill ne fait plus que rediriger.
---

# checkup-routines-run — DEPRECATED (2026-05-08)

## Pourquoi ce skill ne fait plus rien

Florent verbatim 2026-05-08 : *"tu peux utiliser le skill pr lancer toutes les routines avec /schedule et pas run routine qui sert à rien — il faut les fusionner"*.

Fusion : la logique d'exécution on-demand des routines (filtre dépôt + sub-agents Sonnet en batch) a été absorbée dans **`/checkup-routines-create` § Run on-demand (local)**.

## Redirection

| Tu voulais... | Utiliser maintenant |
|---------------|---------------------|
| Lancer 1 routine cloud à la demande | `/schedule run <slug>` (skill builtin Anthropic) |
| Lancer toutes routines locales du dépôt actif (sub-agents Sonnet) | `/checkup-routines-create run` |
| Lancer toutes routines (cloud + local) cross-repo | `/checkup-routines-create run --all-repos` |
| Lancer un scope précis (auto, health) | `/checkup-routines-create run <scope>` |

## Note technique — différence cloud vs local

- **Cloud RemoteTrigger routines** : tournent sur l'infra Anthropic, gérées via API `/schedule`. Run on-demand = `/schedule run <trigger_id>`.
- **Local MCP scheduled-tasks** : tournent sur PC Windows via daemon MCP. Run on-demand = sub-agent Sonnet qui lit le SKILL.md prompt + l'exécute. C'est ce que fait `/checkup-routines-create run`.

Les deux mécanismes sont distincts. La distinction cloud/local est dans le frontmatter `repo:` des SKILL.md (le repo détermine où la routine vit logiquement, mais le type physique cloud/local est dans le SKILL.md frontmatter aussi via field `type:` éventuel ou par défaut local).

## Archive

Le contenu original (logique batch parallèle Sonnet + filtre dépôt) est maintenant dans `/checkup-routines-create` skill. Pas d'autre archive nécessaire (git history conserve l'ancien contenu).
