---
name: conflicts
description: Détecte et résout les conflits Git en attente du système auto-sync inter-PC. Lit le marker `.conflicts-pending.yaml`, analyse les 2 versions backup (ours/theirs) en langage humain par fichier, identifie la nature de chaque divergence (ajouts différents, modifs même section, suppression vs garde), propose options A/B/C avec reco motivée et caveman OFF, exécute la résolution après validation Florent puis cleanup marker. Triggers "/conflicts", "résoudre conflits", "conflits git", "y a un conflit", "fix conflit", appel automatique dès apparition du rappel "⚠️ N conflits Git en attente" injecté par le hook UserPromptSubmit.
---

# Skill /conflicts — Résolution guidée conflits auto-sync

## Pourquoi ce skill existe

Le système auto-sync inter-PC (hooks `Stop` + `SessionStart` lançant `auto_sync_repos.sh` V3.1) résout automatiquement les conflits Git **safe** (logs append-only, fichiers auto-générés) et laisse manuels les **vrais conflits** (mémoire, règles, code, config) pour ne jamais écraser de travail valide.

Mais Florent n'est pas dev et ne parle pas Git. Ce skill traduit chaque conflit en langage humain, compare les 2 versions, propose des options claires avec recommandation motivée, et exécute après validation. **Aucune commande Git à taper manuellement.**

---

## Phase 1 — Détection

Read `~/.claude/.conflicts-pending.yaml`. Format des entries :

```yaml
- repo: "/c/Users/.../speak-app-dev"
  label: "session courante (speak-app-dev)"
  branch: "dev"
  ts: "2026-05-17 03:42:11"
  pc_local: "Portableflo"
  pc_remote: "PCFixe"
  backup_dir: "/c/Users/.../conflict-backups/2026-05-17_03-42-11/speak-app-dev"
  files:
    - path: "memory/MEMORY.md"
      topic: "mémoire user (MEMORY.md)"
    - path: "memory/features/auto-permission.md"
      topic: "feature SpeakApp (auto-permission)"
```

S'il y a **plusieurs entries** (plusieurs sessions de conflit empilées), les traiter dans l'ordre chronologique (plus ancien en premier).

Si le fichier est **vide ou absent** → output 1 ligne `Aucun conflit en attente` et stop.

---

## Phase 2 — Analyse fichier par fichier

Pour CHAQUE fichier dans CHAQUE entry, lire les 2 versions backup :
- `<backup_dir>/<file>.ours` = version locale (ce PC)
- `<backup_dir>/<file>.theirs` = version distante (autre PC)

**Outils** : `Read` pour lire les versions complètes. Si gros fichier (>500 lignes), Read par sections + Grep pour cibler les zones modifiées.

**Diff humain à produire** (pas un patch technique, une description en français) :

| Pattern observé | Description type |
|-----------------|------------------|
| Lignes ajoutées dans .theirs absentes dans .ours, même section | "PC fixe a ajouté la règle `<titre>` (ligne X). Ce PC ne l'a pas." |
| Lignes ajoutées dans .ours absentes dans .theirs, autre section | "Ce PC a ajouté l'entry `<titre>` dans la section <Y>. PC fixe ne l'a pas." |
| Même ligne modifiée différemment des 2 côtés | "Les 2 PC ont reformulé la même ligne différemment : ici `<extrait ours>`, là-bas `<extrait theirs>`." |
| Suppression d'un côté, conservation de l'autre | "Ce PC a supprimé la section `<X>`. PC fixe la garde." |
| Reformatage massif vs ajouts ponctuels | "Ce PC a compressé toute la section `<X>` (perte de N lignes). PC fixe a juste ajouté `<truc>`." |

**Règle d'or** : utiliser le NOM HUMAIN du sujet (la règle, l'entry, la section, la feature, le BP) pas les numéros de ligne ou les hash de commit.

---

## Phase 3 — Proposition options A/B/C

Pour chaque fichier en conflit, présenter le résultat de Phase 2 puis 3 options structurées :

```
### Conflit dans `memory/MEMORY.md` (mémoire user SpeakApp)

**PC fixe (PCFixe)** a fait à 10h12 :
- Ajout d'une règle "Hotkey ignore inputs synthétiques" dans la section "Architecture / Code patterns"

**Ce PC (Portableflo)** a fait à 11h45 (vieille session qui n'avait pas pull) :
- Compression de 14 vieilles entries de la section "Récents" (>14 jours)

Les 2 modifs touchent des sections différentes du même fichier — Git ne sait pas merger automatiquement mais c'est **fusionnable proprement**.

**Options** :
- **A — Fusionner les 2** *(Recommandé)*. Garde la compression d'ici + ajoute la règle du PC fixe. Aucune perte. Je construis la version fusionnée et te montre avant d'écrire.
- **B — Garder uniquement PC fixe**. Tu perds la compression (les vieilles entries reviennent).
- **C — Garder uniquement ce PC**. Tu perds la règle "Hotkey ignore inputs synthétiques".

**Ma reco** : A — la fusion est mécanique ici (zones différentes), pas de risque.

→ A / B / C ?
```

**Règles format** :
- Caveman OFF strict (cf §3.2 CLAUDE.md global)
- 3 options max
- Reco = option A si fusion safe, sinon "garder le plus complet" en justifiant
- Toujours expliquer ce que Florent perd dans B et C
- Si fusion impossible (modifs sur les mêmes lignes), pas de option A, juste B vs C avec reco basée sur le contenu

**Cas spéciaux** :
- Si `.ours` = `.theirs` (faux conflit, identique) → résoudre auto, pas demander
- Si l'un des 2 est vide alors que l'autre a du contenu → recommander fortement le non-vide
- Si fichier critique (`CLAUDE.md`, `settings.json`) → être ultra-prudent, montrer plus de contexte

---

## Phase 4 — Exécution après validation Florent

Florent répond A/B/C (ou une consigne libre type "garde la règle mais vire la compression").

**Pour appliquer la résolution** :

1. `cd "<repo>"` (le repo concerné)
2. Vérifier qu'on est bien en attente de résolution : `git status` doit montrer `rebase in progress` OU si pas en rebase actif (cas où le hook a déjà aborté), refaire `git pull --rebase --autostash`
3. Construire le contenu final selon le choix :
   - **Option A (fusion)** : Write le fichier avec le contenu fusionné (construit en Phase 3)
   - **Option B (theirs)** : `cp "<backup_dir>/<file>.theirs" "<file>"`
   - **Option C (ours)** : `cp "<backup_dir>/<file>.ours" "<file>"`
   - **Consigne libre** : Edit le fichier selon l'instruction
4. `git add "<file>"`
5. Répéter 3-4 pour chaque fichier de l'entry
6. `git -c core.editor=true rebase --continue` (ou `git commit -m "manual resolve <topic>"` si pas en rebase)
7. `git push origin <branch>`

**Si push échoue** (nouveau commit arrivé entre temps) → `git pull --rebase` à nouveau, re-vérifier nouveaux conflits éventuels, re-push.

---

## Phase 5 — Cleanup marker

Une fois TOUS les fichiers d'une entry résolus + commit + push OK :
- Retirer l'entry correspondante de `~/.claude/.conflicts-pending.yaml` (Edit + remove le bloc YAML)
- Si plus d'entries → Write fichier vide ou le supprimer
- Confirmer à Florent : `✓ Conflit dans <repo> résolu (N fichiers). Push <hash>.`

S'il reste d'autres entries (autres conflits empilés) → enchaîner direct sans demander, en présentant chacun comme en Phase 3.

---

## Anti-patterns interdits

- ❌ Présenter un diff technique avec `<<< HEAD === >>>` markers — Florent ne lit pas Git
- ❌ Demander "tu veux résoudre ce conflit ?" — Si on est dans le skill, c'est que oui. Avancer.
- ❌ Proposer "abandonne et garde le repo cassé" — toujours résoudre
- ❌ Modifier `git config` (jamais)
- ❌ Force push (jamais — même si le push normal échoue)
- ❌ Suggérer à Florent d'ouvrir le fichier dans VS Code et résoudre lui-même — c'est précisément ce que ce skill existe pour éviter
- ❌ Tableau dense pour les options — phrases complètes (§3.2 CLAUDE.md)

---

## Cas limite : marker existe mais le rebase a déjà été nettoyé

Possible si Florent a résolu manuellement entre temps (via VS Code ou autre). Pour chaque entry :
1. `cd "<repo>" && git status`
2. Si pas de `rebase in progress` ET `git log` montre que le commit distant a été intégré → conflit résolu, juste cleanup le marker (Phase 5)
3. Sinon → procéder normalement

---

## Test manuel du skill (debug)

Pour vérifier que la chaîne marche sans attendre un vrai conflit :
1. Crée un faux conflit : `echo "test ours" > /tmp/test-marker.yaml && echo "test theirs" > /tmp/test-marker.theirs.yaml`
2. Append une fake entry dans `~/.claude/.conflicts-pending.yaml` pointant vers /tmp
3. Invoque `/conflicts`
4. Vérifier que la détection + analyse fonctionne
5. Cleanup fichiers test
