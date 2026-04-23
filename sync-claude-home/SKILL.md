---
name: sync-claude-home
description: Synchroniser le dossier ~/.claude/ entre plusieurs PC via un repo git privé. Invoquer quand Florent dit "/sync-claude-home", "sync mon claude home", "push mon claude", "rafraîchir mon claude", "je change de PC", "setup claude sur nouveau PC", "cloner mon claude sur ce PC".
trigger: user-invocable
scope: global
---

# sync-claude-home — Sync du dossier `~/.claude/` entre PC

## Comportement par défaut quand Florent invoque `/sync-claude-home`

Sauf si un sous-argument est donné (`pull`, `status`, `setup`), le skill exécute un **push complet "fin de session"** dans cet ordre :

1. **Wrap-up projet courant** si on est dans un projet qui a le skill `wrapup` → invoquer `wrapup` pour clôturer proprement (handoff, MAJ docs, commit projet, push projet). Sinon sauter.
2. **Commit + push `~/.claude`** (repo claude-home) :
   - `cd "$HOME/.claude"`
   - `git status --short` → montrer à Florent ce qui va partir
   - Si non vide → `git add -A && git commit -m "sync: <desc auto basée sur fichiers modifiés>" && git push origin main`
3. **Commit + push `~/.claude/skills`** (repo claude-code-skills) :
   - `cd "$HOME/.claude/skills"`
   - Idem : status → diff → add → commit → push si modifs.
4. **Résumé final** : 1 ligne par repo (X fichiers commit, hash, pushé ou rien à faire).

Arguments alternatifs :
- `/sync-claude-home pull` → `git pull origin main` dans les 2 repos (à l'arrivée sur un PC).
- `/sync-claude-home status` → `git status --short` dans les 2 repos (juste regarder, pas d'action).
- `/sync-claude-home setup` → rappeler le prompt de setup nouveau PC (voir section plus bas).

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

## Mode migration PC — push TOUT sans filtrer (y compris secrets, fichiers perso)

**Quand Florent dit "je migre vers un nouveau PC" / "on migre tout" / "push tout avant que je bouge" → mode YOLO :**

1. **Ne PAS filtrer** `.mcp.json`, `.claude/launch.json`, `Windows/` (captures perso), `DHL*.pdf`, `autoperm_*`, `claude-local/`, `_pre-fusion-backup-*/`, `_archive/`, etc.
2. **Ne PAS demander** "attention il y a un secret OAuth dans .mcp.json, on exclut ?" → le repo est PRIVÉ, seul Florent y a accès, il assume le risque.
3. **Ne PAS ajouter** de lignes au `.gitignore` pour "protéger" des fichiers sensibles pendant la migration. La sécurité vient APRÈS, une fois sur le nouveau PC et stable.
4. **Gérer les nested `.git`** qui bloquent `git add -A` : les supprimer (`rm -rf <path>/.git`) pour que le dossier devienne un dossier normal et soit tracké dans le repo parent. On perd l'historique git du sous-repo (OK, on veut juste les fichiers).
5. **Objectif unique** : 100% de fidélité entre l'ancien et le nouveau PC. Zéro friction, zéro "il faut que je retrouve ce fichier".

**Règle de Florent (claire et énoncée 2026-04-23)** : "Je m'en fous des risques, merci je veux qu'on aille vite et qu'on soit efficace et qu'on le fasse bien, c'est tout. Proprement. Je vais pas partager ces dépôts, dans tous les cas ils sont ultra privés et que moi dessus."

**Après la migration**, on pourra reprendre les bonnes pratiques (`.env` gitignorés, secrets vers vault, etc.) — mais PAS pendant la fenêtre de migration.

## Commandes

### Rafraîchir mon PC depuis le repo (PULL)

```bash
cd "$HOME/.claude" && git pull origin main
```

À lancer quand :
- Je viens d'allumer ce PC après avoir bossé sur l'autre
- J'ai ajouté un skill / modifié un setting sur l'autre PC et je veux le récupérer ici

### Pousser mes changements (PUSH)

```bash
cd "$HOME/.claude" && git add -A && git status
```

Vérifier ce qui va partir (regarder que le `.gitignore` fait bien son boulot — pas de `projects/`, pas de `cache/`).

```bash
cd "$HOME/.claude" && git commit -m "sync: <description courte>" && git push origin main
```

### Status rapide

```bash
cd "$HOME/.claude" && git status --short
```

## Setup sur un nouveau PC — procédure complète

### Prompt à donner à Claude Code sur le nouveau PC

> Salut Claude. Je viens de migrer depuis un ancien PC. Invoque `/sync-claude-home setup` et suis la procédure **step-by-step** ci-dessous dans l'ordre. Points de vigilance :
> - `.claude/` existe déjà si Claude Code a tourné ici → **pas** de `git clone`, passe en CAS B (rebranchement).
> - Mon username Windows peut être différent de l'ancien PC → détecte-le et propose le find-replace AVANT qu'un skill ne se plante sur un path périmé.
> - Les repos sont privés, contiennent secrets + configs → 100% de fidélité attendue avec l'ancien PC.

### Étape 1 — Prérequis

```powershell
git --version    # Git for Windows doit être installé (embarque Git Credential Manager)
```

Si git manque → installer [Git for Windows](https://git-scm.com/download/win). Pas besoin de `gh` CLI : le Git Credential Manager gère l'auth GitHub au 1er `git clone` (popup navigateur).

### Étape 2 — Récupérer les 2 repos `~/.claude` et `~/.claude/skills`

**Vérifier d'abord si `~/.claude/` existe déjà** (c'est le cas si Claude Code a déjà été lancé une fois sur la machine — il crée `projects/`, `shell-snapshots/`, `plugins/`, `todos/`, `ide/`, `statsig/`, etc.) :

```powershell
Test-Path "$HOME\.claude"
Get-ChildItem "$HOME\.claude" -Force -ErrorAction SilentlyContinue | Select-Object Name
```

#### CAS A — `.claude/` absent ou vide

`git clone` direct :

```bash
git clone https://github.com/Gremelinn0/claude-home.git        "$HOME/.claude"
git clone https://github.com/Gremelinn0/claude-code-skills.git "$HOME/.claude/skills"
```

#### CAS B — `.claude/` existe déjà avec des runtime dirs

**`git clone` échouera** avec `destination path already exists and is not an empty directory`. **Ne pas supprimer le dossier** (on perdrait `projects/` et les transcripts locaux). Faire un **rebranchement** à la place :

```powershell
cd "$HOME\.claude"
git init
git remote add origin https://github.com/Gremelinn0/claude-home.git
git fetch origin
git reset --hard origin/main
git branch --set-upstream-to=origin/main main

# Puis pareil pour le repo skills (lui aussi est un sous-repo dédié)
New-Item -ItemType Directory -Force "$HOME\.claude\skills" | Out-Null
cd "$HOME\.claude\skills"
git init
git remote add origin https://github.com/Gremelinn0/claude-code-skills.git
git fetch origin
git reset --hard origin/main
git branch --set-upstream-to=origin/main main
```

`git reset --hard origin/main` écrase tous les fichiers **trackés** par le contenu distant, mais laisse intactes les runtime dirs non trackées (`projects/`, `shell-snapshots/`, `todos/`, `sessions/`, `plans/`, `ide/`, `backups/`…) grâce au `.gitignore` du repo.

### Étape 3 — Détection username + réécriture des paths hardcodés

Les SKILL.md de `scheduled-tasks/`, certains hooks et parfois `settings.json` contiennent des paths absolus `C:\Users\<ancien_user>\...`. Si l'username Windows a changé, il faut les réécrire.

**Script PowerShell** (à privilégier — sed sur Git Bash Windows gère mal les backslashes, il faut double-échapper et la substitution devient illisible) :

```powershell
# 3a. Diagnostic — quels usernames sont référencés dans les fichiers du repo ?
$NewUser = $env:USERNAME
$Paths = @(
  "$HOME\.claude\scheduled-tasks",
  "$HOME\.claude\hooks",
  "$HOME\.claude\skills",
  "$HOME\.claude\settings.json",
  "$HOME\.claude\settings.local.json"
) | Where-Object { Test-Path $_ }

$Files = Get-ChildItem -Path $Paths -Recurse -File -Include *.md,*.sh,*.json,*.ps1,*.bat `
         -ErrorAction SilentlyContinue
$OldUsers = $Files |
  Select-String -Pattern 'C:[\\/]Users[\\/]([A-Za-z0-9._-]+)[\\/]' -AllMatches |
  ForEach-Object { $_.Matches } |
  ForEach-Object { $_.Groups[1].Value } |
  Sort-Object -Unique |
  Where-Object { $_ -ne $NewUser -and $_ -notin @('Public','Default','All Users','Default User') }

Write-Host "Username courant : $NewUser"
Write-Host "Anciens usernames trouvés :"; $OldUsers

# 3b. Application — pour chaque ancien user, remplacer les deux variantes (\ et /)
foreach ($OldUser in $OldUsers) {
  $toFix = $Files | Where-Object {
    $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    $c -and ($c.Contains("C:\Users\$OldUser\") -or $c.Contains("C:/Users/$OldUser/"))
  }
  Write-Host "→ $($toFix.Count) fichier(s) à réécrire pour $OldUser"
  $toFix | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content.Replace("C:\Users\$OldUser\","C:\Users\$NewUser\")
    $content = $content.Replace("C:/Users/$OldUser/","C:/Users/$NewUser/")
    # UTF-8 sans BOM — compatible avec les .sh qui ont un shebang
    [System.IO.File]::WriteAllText($_.FullName, $content, (New-Object System.Text.UTF8Encoding $false))
  }
}
```

Après exécution, `git status` dans `~/.claude` et `~/.claude/skills` montrera les fichiers modifiés — **ne pas** les commiter tout de suite, laisser Florent les relire d'abord et valider avant de push.

### Étape 4 — Cloner les projets actifs dans `~/PROJECTS`

Voir section **Structure projets recommandée** ci-dessous pour la liste complète et les noms de dossier exacts (hardcodés dans les routines).

```bash
mkdir -p "$HOME/PROJECTS" && cd "$HOME/PROJECTS"
git clone https://github.com/Gremelinn0/blueprint-hub.git                     "0- Marketplace"
git clone https://github.com/Gremelinn0/vente-et-marketing-all-compagnies.git "Vente et Marketing - ALL Compagnies"
```

### Étape 5 — `npm install` sur chaque projet avec un `package.json` à la racine

Marketplace, LinkedIn Content Agent, etc.

### Étape 6 — Actions manuelles à rappeler à Florent

- **MCP connectors** (Notion, Supabase, Vercel, Google Workspace, Gmail) : re-auth OAuth depuis le panneau Settings de Claude Code.
- **Vercel CLI** : `vercel login` dans un terminal.
- **Chrome extension "Claude in Chrome"** : réinstaller + reconnecter.
- **Apps natives** référencées par un skill (OBS, Krea, SpeakApp…) : à réinstaller.

### Étape 7 — Redémarrer Claude Code

Pour picker les skills, settings et scheduled-tasks nouvellement rebranchés.

### Étape 8 — Résumé final

1 paragraphe : ce qui tourne maintenant / ce qui reste à re-auth manuellement / les paths qui ont été réécrits à l'étape 3 (pour que Florent valide et commit).

## Structure projets recommandée

```
C:\Users\<User>\PROJECTS\
├── 0- Marketplace\              → https://github.com/Gremelinn0/blueprint-hub.git
├── 3- Wisper\speak-app-dev\     → https://github.com/Gremelinn0/wisper-app.git
├── Vente et Marketing - ALL Compagnies\
└── navigateur\
```

**Les noms de dossier sont figés** — ils apparaissent en dur dans les SKILL.md des scheduled-tasks (ex. `C:\Users\<User>\PROJECTS\0- Marketplace\...`). Renommer un dossier casse silencieusement toutes les routines qui pointaient dessus. À ne faire qu'en couplant avec une MAJ de toutes les routines concernées.

## Long terme — à évaluer plus tard (ne pas faire pendant un setup PC)

Les paths absolus `C:\Users\<User>\PROJECTS\...` et `C:\Users\<User>\.claude\...` apparaissent hardcodés dans **~30 scheduled-tasks SKILL.md** et plusieurs hooks. À chaque changement d'username Windows, l'étape 3 ci-dessus est obligatoire.

**L'idéal** : passer à `%USERPROFILE%` (cmd), `$HOME` (bash), `$env:USERPROFILE` (PowerShell) — rendre le skill PC-agnostique.

**Pourquoi pas fait** : chaque SKILL.md doit être testé sur **3 shells** (Windows cmd, Git Bash, PowerShell) qui n'expansent pas les variables de la même façon. Un skill qui marche en bash peut casser en cmd si la routine l'y lance. Gros refactor + beaucoup de tests → session dédiée, pas pendant la fenêtre de migration d'un PC.

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

**Repo absent du nouveau PC :** vérifier l'URL exacte `https://github.com/Gremelinn0/claude-home.git`. Au premier `git clone/fetch`, le Git Credential Manager ouvre un popup navigateur pour s'auth sur GitHub — si rien ne se passe, vérifier `git config --global credential.helper` (doit renvoyer `manager` sur Windows).

**Conflit de merge après un pull :** un fichier a été modifié des 2 côtés. Git va lister les fichiers en conflit. Règle de principe : garder la version la plus récente. Si doute, sauvegarder l'ancien fichier sous un autre nom avant de résoudre.

**`settings.json` pete après un pull :** cause probable = le nouveau PC a un username différent donc les paths absolus sont périmés. Relancer l'**Étape 3** de la procédure setup (script PowerShell de détection + find-replace automatique).

**Secrets vides ou expirés :** normal, les tokens OAuth ont une TTL. Re-authentifier chaque MCP depuis le panneau Settings de Claude Code.
