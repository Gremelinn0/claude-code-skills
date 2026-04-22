---
name: sync-claude-home
description: Synchroniser le dossier ~/.claude/ entre plusieurs PC via un repo git privé. Invoquer quand Florent dit "/sync-claude-home", "sync mon claude home", "push mon claude", "rafraîchir mon claude", "je change de PC", "setup claude sur nouveau PC", "cloner mon claude sur ce PC".
trigger: user-invocable
scope: global
---

# sync-claude-home — Sync du dossier `~/.claude/` entre PC

## But

**DEUX repos git privés** qui, ensemble, reconstituent `~/.claude/` sur un nouveau PC :

1. **`claude-home`** (https://github.com/Gremelinn0/claude-home) — config, scheduled-tasks, secrets, agents, hooks, commands.
2. **`claude-code-skills`** (https://github.com/Gremelinn0/claude-code-skills) — tous les skills globaux, qui vivent dans `~/.claude/skills/`.

Les 2 sont séparés car `skills/` a été mis en place en repo dédié il y a longtemps. On garde cette séparation.

## Règles absolues

1. **Repo TOUJOURS privé** — contient `secrets/` avec tokens API. Ne jamais passer public, même 2 secondes.
2. **`projects/` est exclu** — 5+ Go de transcripts, inutile à syncer. Pour récupérer le contexte d'une session sur un autre PC, utiliser les handoffs dans les repos projet (`memory/handoffs/`).
3. **Ne jamais faire de sync pendant que Claude Code est en train d'écrire** — risque de capturer un fichier en cours d'écriture. Idéalement fermer les sessions actives avant `git add`.
4. **Pull AVANT de modifier** sur un PC qui n'a pas été touché depuis longtemps, sinon conflits de merge.

## Commandes

### Rafraîchir mon PC depuis le repo (PULL)

```bash
cd "C:/Users/Administrateur/.claude" && git pull origin main
```

À lancer quand :
- Je viens d'allumer ce PC après avoir bossé sur l'autre
- J'ai ajouté un skill / modifié un setting sur l'autre PC et je veux le récupérer ici

### Pousser mes changements (PUSH)

```bash
cd "C:/Users/Administrateur/.claude" && git add -A && git status
```

Vérifier ce qui va partir (regarder que le `.gitignore` fait bien son boulot — pas de `projects/`, pas de `cache/`).

```bash
cd "C:/Users/Administrateur/.claude" && git commit -m "sync: <description courte>" && git push origin main
```

### Status rapide

```bash
cd "C:/Users/Administrateur/.claude" && git status --short
```

## Setup sur un nouveau PC — procédure complète

### Prompt à donner à Claude Code sur le nouveau PC

> Salut Claude. Je veux setup mon environnement Claude Code sur ce nouveau PC à partir de mon repo `claude-home`. Fais tout ce qui suit :
>
> 1. Vérifie que Git et GitHub CLI sont installés (`git --version` et `gh --version`). Si non, guide-moi pour les installer.
> 2. Authentifie-moi sur GitHub si ce n'est pas fait : `gh auth status`. Sinon `gh auth login`.
> 3. Clone les DEUX repos dans le bon emplacement :
>    ```
>    git clone https://github.com/Gremelinn0/claude-home.git "$HOME/.claude"
>    git clone https://github.com/Gremelinn0/claude-code-skills.git "$HOME/.claude/skills"
>    ```
>    (sur Windows, remplacer `$HOME` par `C:\Users\<mon-user>`)
> 4. Vérifie que les dossiers clés sont là : `skills/` (contenu du 2e repo), `commands/`, `agents/`, `scheduled-tasks/`, `settings.json`.
> 5. Redémarre Claude Code pour qu'il picke les skills, settings et scheduled-tasks.
> 6. Préviens-moi de ce qu'il faut reconfigurer manuellement :
>    - MCP connectors (Notion, Supabase, Vercel, Google Workspace, etc.) — certains demandent une re-auth OAuth
>    - Vercel CLI : `vercel login`
>    - Chrome extension (Claude in Chrome) — à réinstaller
>    - Toute app native référencée par un skill (OBS, Krea, etc.)
> 7. Résume-moi en fin de setup : ce qui tourne, ce qui demande encore une action manuelle.

### Attention — chemin identique ou pas

Si le nouveau PC a un username Windows différent (ex: `Florent` au lieu de `Administrateur`), les chemins absolus `C:\Users\Administrateur\...` dans les SKILL.md de `scheduled-tasks/` et dans certains settings peuvent casser. Solution rapide : chercher-remplacer après le clone.

## Cas d'usage — quand invoquer ce skill

| Situation | Action |
|-----------|--------|
| Je change de PC / PC portable | Push sur l'ancien → Clone sur le nouveau |
| J'ai modifié un skill global sur le PC A et je veux l'avoir sur le PC B | Push A → Pull B |
| J'ai ajouté une scheduled-task sur le PC A | Push A → Pull B (mais les routines ne tourneront toujours que sur le PC actif) |
| Je veux juste voir ce qui a changé sans pousser | `git status --short` puis `git diff` |

## Workflow recommandé — 2 PC (1 principal + 1 portable)

- **PC principal** = "home" des routines. Tourne en permanence. Sync fréquent.
- **PC portable** = usage ponctuel. `git pull` en arrivant, `git push` en partant.
- **Pas besoin de sync quotidien.** Uniquement quand on a modifié quelque chose qui mérite de voyager (nouveau skill, nouvelle routine, changement de settings).

## Gérer les routines locales entre 2 PC (éviter les doublons)

Les fichiers des routines (`scheduled-tasks/<id>/SKILL.md`) voyagent via git, MAIS l'exécution se fait sur **chaque PC où Claude Code est ouvert** en parallèle. Si les 2 PCs ont Claude Code ouvert avec le même `scheduled-tasks/` → la routine tourne **2 fois** (double email, double scan, double tout).

**Règle simple :**
1. Choisir UN seul PC "maison des routines" (typiquement le principal, celui qui tourne en permanence).
2. Sur l'AUTRE PC, après le premier pull, désactiver les routines qu'on ne veut pas voir tourner là-bas :
   - Option A (propre) : `mcp__scheduled-tasks__list_scheduled_tasks` → identifier les IDs → supprimer via l'interface Claude Code (sidebar "Scheduled" → delete).
   - Option B (brut) : supprimer le dossier `~/.claude/scheduled-tasks/<id>/` sur ce PC uniquement. Attention : **ne pas commiter cette suppression**, sinon au prochain push le PC principal va les perdre aussi. Faire un `git update-index --assume-unchanged` sur les dossiers concernés, ou juste ne jamais pusher depuis ce PC.

**Règle d'or :** un `scheduled-tasks/<id>/` présent sur 2 PCs actifs = 2 exécutions parallèles. Aucun mécanisme ne dédupliqué entre PCs — le `.lock` local protège juste contre un double-lancement sur le même PC.

## Exception Computer Use — la routine suit l'écran cible

Les routines qui font du **Computer Use** (screenshot, clic, pilotage d'une app native) doivent tourner sur le PC qui a physiquement accès à l'écran à piloter. Pas le choix.

Exemple : une routine qui check SpeakApp via Computer Use → doit tourner sur le PC où SpeakApp est lancée, même si ce n'est pas le PC "principal". Dans ce cas :
- On garde la routine active sur ce PC (on ne la désactive pas même si c'est le "secondaire")
- On la désactive sur tous les autres PCs (qui verraient un écran vide ou l'écran du mauvais poste)

Pareil pour toute routine Chrome MCP sur une app locale : suit la machine qui héberge Chrome avec l'extension connectée.

## Routines cloud (Remote Triggers Anthropic) — migration manuelle

Les routines cloud (créées via `/schedule`, visibles sur https://claude.ai/code/scheduled) sont liées à **UN compte Claude**, pas à un PC. Elles ne font pas partie du repo `claude-home` — elles vivent côté Anthropic.

Pour consolider sur un seul compte quand on en a 2 :
1. Lister les routines cloud du compte à abandonner (https://claude.ai/code/scheduled)
2. Recréer celles à garder sur le compte principal via le skill `/schedule`
3. Supprimer les anciennes sur le compte abandonné
4. Rien à sync côté git, elles vivent dans le cloud Anthropic

## Quand ce skill n'est PAS adapté

- Tu veux juste migrer un projet précis → ce skill est pour le dossier `~/.claude/` user-level, pas pour un repo projet (les repos projet voyagent déjà via leur propre git).
- Tu veux récupérer un transcript de conversation passée → non, `projects/` est exclu exprès (volumineux). Utilise les handoffs dans le repo projet concerné.
- Tu veux partager ta config avec quelqu'un d'autre → surtout pas, le repo contient tes secrets. C'est perso, un humain = un repo.

## Debug

**Repo absent du nouveau PC :** vérifier l'URL exacte `https://github.com/Gremelinn0/claude-home.git` et que l'auth GitHub est active (`gh auth status`).

**Conflit de merge après un pull :** un fichier a été modifié des 2 côtés. Git va lister les fichiers en conflit. Règle de principe : garder la version la plus récente. Si doute, sauvegarder l'ancien fichier sous un autre nom avant de résoudre.

**`settings.json` pete après un pull :** cause probable = le nouveau PC a un path différent. Rechercher `C:\\Users\\Administrateur\\` dans les fichiers de config et remplacer par le nouveau chemin user.

**Secrets vides ou expirés :** normal, les tokens OAuth ont une TTL. Re-authentifier chaque MCP depuis le panneau Settings de Claude Code.
