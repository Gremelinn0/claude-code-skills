---
name: computer-use-rules
description: Regles strictes pour l'usage de computer-use — ecran secondaire, fenetres utilisateur, verification avant action. A lire AVANT toute session computer-use.
trigger: Avant d'utiliser computer-use, avant request_access, avant toute interaction avec des fenetres natives.
scope: global — tous les projets
---

# computer-use-rules — Regles strictes

## Pourquoi ce skill existe

Florent a perdu ~30 min de session parce que Claude :
- A swiché sur le mauvais écran (principal au lieu du secondaire)
- A essayé d'ouvrir/fermer des fenêtres de l'utilisateur
- A cliqué dans le vide sans vérifier ce qui était ouvert

Ces erreurs se répètent. Ce skill est le garde-fou.

---

## Règle 1 — Écran secondaire TOUJOURS

```
display secondaire = "display 3988289358"  ← peut changer (spacedesk dynamique)
display principal  = "PHL 241E1"
```

**AVANT toute première screenshot de la session :**
```python
switch_display("display 3988289358")
screenshot()
# Si erreur "No monitor named..." → faire screenshot() sans switch pour voir les monitors dispo
```

**Ce qui vit sur le secondaire :**
- AntiGravity (AG)
- **Claude Desktop (Electron) + sa DevTools** — les DEUX sur le secondaire, sans exception. Voir Règle 1bis ci-dessous.
- Control Center (pywebview = SpeakApp)
- Toutes apps natives Python/GUI du projet

**Ce qui vit sur le principal :**
- Chrome (Claude.ai, ChatGPT, Gemini)
- Pour Chrome → utiliser Chrome MCP (`mcp__Claude_in_Chrome__*`), PAS computer-use (tier "read", clics bloqués)
- **Tout ce que Florent utilise pour bosser** (IDE, terminal, navigateur). Ne jamais remonter une app Claude/CD/AG sur le principal.

---

## Règle 1bis — Claude Desktop + DevTools = TOUJOURS sur le secondaire (setup "parallel work")

**Setup canonique pour bosser en parallèle pendant que CD tourne :**

```
[Écran secondaire "display 3988289358"]       [Écran principal "PHL 241E1"]
  ┌─────────────────────────────┐               ┌─────────────────────────────┐
  │  Claude Desktop (Electron)  │               │                             │
  │  (plein écran ou maximisée) │               │   Florent bosse ici :       │
  │                             │               │   IDE, Chrome, terminal,    │
  │  ┌──────────────────┐       │               │   etc.                      │
  │  │ DevTools 700x500 │       │               │                             │
  │  │  top-left        │       │               │                             │
  │  └──────────────────┘       │               │                             │
  └─────────────────────────────┘               └─────────────────────────────┘
```

**Règles :**
1. **CD (l'app Electron)** → maximisée sur écran secondaire. Jamais sur le principal.
2. **DevTools CD** → ouverte via `Ctrl+Alt+I`, repositionnée en 700x500 top-left **sur le même écran secondaire** qu'CD. Jamais qu'elle atterrisse sur le principal (flash visuel + vole le focus Florent).
3. **Pourquoi** : CD + DevTools sur le secondaire = Florent peut bosser sur le principal sans être dérangé. Si CD ou DevTools apparaît sur le principal → vol de focus, vol de clipboard, interruption.
4. **Avant tout `switch_display` vers le principal** : vérifier que CD et DevTools ne viennent pas d'être repositionnés sur le principal par erreur. Les ramener sur le secondaire via `tools/cd_show_devtools.py` si besoin.
5. **Prérequis pour lancer CD en journée** : Florent doit dire explicitement "OK, CD peut tourner pendant que je bosse" OU on est en session overnight. Par défaut : ne pas lancer CD live sans son go.

**Check au début de toute session CD live** :
```python
switch_display("display 3988289358")
screenshot()
# Vérifier : CD visible sur le secondaire ? DevTools visible sur le secondaire ?
# Si non → demander à Florent OU repositionner via tools/cd_show_devtools.py
```

**Corollaire** : la règle historique "CD overnight only" s'assouplit — CD peut tourner en journée **si et seulement si** ce setup parallel-work est respecté + Florent a dit OK.

---

## Règle 2 — Fermer/minimiser = interdit, ouvrir = OK si nécessaire

`open_application(...)` est autorisé quand c'est nécessaire pour la tâche (ex: ouvrir Chrome pour un test).

**INTERDIT :**
- Fermer, minimiser, maximiser une fenêtre de Florent
- Alt+Tab, Win+Tab, Win+D pour changer la fenêtre active de Florent
- Redimensionner une fenêtre sans demander

**AUTORISÉ :**
- `open_application(...)` — pour ouvrir une app nécessaire
- `switch_display(...)` — switcher l'écran capturé
- `screenshot()` — observer
- `zoom(...)` — agrandir une zone

---

## Règle 3 — Screenshot + vérification AVANT toute action

**Séquence obligatoire au début de chaque session computer-use :**

1. `switch_display("display 3988289358")`
2. `screenshot()` — observer ce qui est ouvert
3. Analyser : est-ce que tout ce dont j'ai besoin est visible ?
4. Si oui → `request_access(apps=[...])` avec seulement ce qui est nécessaire → agir
5. Si non → **STOP**, dire à Florent : _"J'ai besoin que [X] soit ouvert sur l'écran secondaire. Tu peux l'ouvrir ?"_
6. Attendre "ok" explicite avant de continuer

**Jamais :**
- Clique "au cas où"
- `request_access` sur des apps pas encore vérifiées
- Action sans screenshot récent (<30s)

---

## Règle 4 — request_access = minimal

Ne demander accès qu'aux apps réellement nécessaires pour la tâche en cours.

**Bon :**
```python
request_access(apps=["SpeakApp"], reason="Vérifier le Control Center")
```

**Mauvais :**
```python
request_access(apps=["SpeakApp", "Google Chrome", "Claude", "Antigravity", "Visual Studio Code"], reason="...")
```

Trop d'apps dans l'allowlist = les autres fenêtres sont masquées = screenshots inutiles.

---

## Règle 5 — pywebview = Chrome = tier "read"

Control Center = subprocess pywebview = détecté comme Chrome = **tier "read"**.

**Conséquence :** les clics ET le typing sont bloqués par computer-use sur le CC.

**Comment interagir avec le CC :**
- **Lire/vérifier** → screenshot + zoom (OK)
- **Envoyer une commande** → écrire dans `cc_cmd.json` puis vérifier l'effet au screenshot suivant
- **Raccourcis clavier** → OK si la fenêtre CC a le focus (mais vérifier d'abord au screenshot)

---

## Règle 6 — Chrome MCP déconnecté → open_application, retry, PAS de workaround

Quand `mcp__Claude_in_Chrome__tabs_context_mcp` retourne "not connected" :

**Séquence OBLIGATOIRE :**
```
1. open_application("Google Chrome")   ← amène Chrome au premier plan
2. wait(2)                             ← laisse l'extension se reconnecter
3. tabs_context_mcp()                  ← retry
```

**INTERDIT quand Chrome MCP est déco :**
- Playwright (nlm-venv ou autre)
- Python requests pour contourner LinkedIn/YouTube
- Toute tentative de scraping/automation hors Chrome MCP
- Dire "Chrome est déconnecté" et s'arrêter là

**Si après 2 retries Chrome MCP ne se reconnecte pas :**
→ Dire à Florent : _"Chrome MCP ne se reconnecte pas. Tu peux vérifier que l'extension Claude est bien activée dans Chrome ?"_
→ Continuer les tâches qui ne nécessitent pas Chrome pendant ce temps.

---

## Règle 7 (ancienne 6) — Pas de question si les logs peuvent répondre

Avant de demander à Florent ce qui se passe dans l'app :
1. Lire les logs via Bash : `tail -50 debug.log | grep -E "\[CC|lecture|TTS"`
2. Lire `cc_state.json` via Python
3. Vérifier le screenshot

Florent = validation visuelle + actions physiques (micro, fenêtre). Claude = logs, code, screenshots, Chrome MCP.

---

## Checklist rapide avant d'utiliser computer-use

```
[ ] Je suis sur l'écran secondaire ? (switch_display + screenshot)
[ ] J'ai vérifié ce qui est ouvert avant request_access ?
[ ] Je vais fermer/minimiser une fenêtre de Florent ? → STOP, interdit
[ ] La cible est Chrome/pywebview ? → Utiliser Chrome MCP à la place
[ ] request_access = uniquement les apps nécessaires ?
```

---

## Historique

- **2026-04-14** — Créé suite à erreurs répétées d'écran + fenêtres. Validé par Florent.
