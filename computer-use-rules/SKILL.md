---
name: computer-use-rules
description: Regles strictes pour l'usage de computer-use — 1 ecran principal, fenetres utilisateur, verification avant action. A lire AVANT toute session computer-use.
trigger: Avant d'utiliser computer-use, avant request_access, avant toute interaction avec des fenetres natives.
scope: global — tous les projets
---

# computer-use-rules — Regles strictes

## Pourquoi ce skill existe

Florent a perdu ~30 min de session parce que Claude :
- A essayé d'ouvrir/fermer des fenêtres de l'utilisateur
- A cliqué dans le vide sans vérifier ce qui était ouvert
- A switché vers un display qui n'existe plus (anciennes sessions : spacedesk retiré 2026-04-23)

Ces erreurs se répètent. Ce skill est le garde-fou.

---

## Règle 1 — 1 seul écran, pas de `switch_display` nécessaire

**Setup actuel (2026-04-23) :** Florent a **1 seul écran principal**. L'écran secondaire spacedesk (`display 3988289358`) a été retiré.

```
display principal = unique écran disponible
```

**Conséquence :**
- `switch_display(...)` n'est **plus nécessaire** et **plus demandé** par défaut.
- Faire `screenshot()` directement, sans switch préalable.
- Si on tombe sur une session très ancienne qui parle de "display 3988289358" ou "écran secondaire" → règle obsolète, ignorer.

**Apps qui vivent sur ce seul écran :**
- AntiGravity (AG)
- **Claude Desktop (Electron) + sa DevTools** (voir Règle 1bis ci-dessous — pilotage prioritaire via scripts UIA/Python, pas computer-use)
- Control Center (pywebview = SpeakApp)
- Chrome (Claude.ai, ChatGPT, Gemini) → **Chrome MCP préférable** à computer-use (tier "read", clics bloqués)
- Toutes apps natives Python/GUI du projet
- **Tout ce que Florent utilise pour bosser** (IDE, terminal, navigateur)

**Cohabitation :** puisqu'il n'y a qu'un seul écran, Claude doit être **le plus discret possible** — pas de flash DevTools, pas de vol de focus. Privilégier les mécanismes qui travaillent en arrière-plan (UIA Invoke, CDP, WS Bridge, hooks JSONL). Computer-use reste le **dernier recours** pour du vrai GUI natif.

---

## Règle 1bis — Claude Desktop = pilotage prioritaire via scripts UIA/Python, pas computer-use

**Ce qu'il faut savoir :** quand Florent bosse sur CD, la **sidebar est souvent repliée** (zone étroite, boutons sessions collapsed).

**Bonne nouvelle :** les éléments UIA restent présents dans l'arbre même sidebar repliée. `cd_uia_scan.py` voit tout, `cd_nav_to_session.py` peut invoquer la bonne session sans que l'état visuel de la sidebar bouge.

**Conséquence :** pour observer/piloter CD, **utiliser les scripts Python UIA/DevTools** en priorité :

| Scénario | Outil prioritaire |
|----------|-------------------|
| Lister les sessions CD | `python tools/cd_uia_scan.py` |
| Naviguer vers une session | `python tools/cd_nav_to_session.py <nom>` |
| Injecter un script DOM | `python tools/cd_inject_*.py` (libre à toute heure depuis 2026-04-23) |
| Cliquer un bouton de permission | UIA Invoke via `app.py` (auto-perm prod) |
| Bench / scan discovery | `python tools/cd_uia_invoke_bench.py` |

**Ces scripts fonctionnent indépendamment de :**
- la visibilité de la fenêtre (CD peut être minimisée, cachée, derrière une autre app)
- l'état de la sidebar (repliée ou étendue)
- ce que Florent est en train de faire ailleurs

**Computer-use sur CD = fallback exotique uniquement** (cas où UIA ne voit pas un élément, ou validation visuelle d'un pixel). Sinon → scripts Python.

**Règle DevTools CD inject (2026-04-23) :** libre à toute heure, jour comme nuit. Florent : "Tu ne me perturberas jamais, le PC est complètement disponible. Pour faire les scans DOM, il ne faut vraiment pas que tu hésites."

---

## Règle 2 — Fermer/minimiser = interdit, ouvrir = OK si nécessaire

`open_application(...)` est autorisé quand c'est nécessaire pour la tâche (ex: ouvrir Chrome pour un test).

**INTERDIT :**
- Fermer, minimiser, maximiser une fenêtre de Florent
- Alt+Tab, Win+Tab, Win+D pour changer la fenêtre active de Florent
- Redimensionner une fenêtre sans demander

**AUTORISÉ :**
- `open_application(...)` — pour ouvrir une app nécessaire
- `screenshot()` — observer
- `zoom(...)` — agrandir une zone

---

## Règle 3 — Screenshot + vérification AVANT toute action

**Séquence obligatoire au début de chaque session computer-use :**

1. `screenshot()` — observer ce qui est ouvert
2. Analyser : est-ce que tout ce dont j'ai besoin est visible ?
3. Si oui → `request_access(apps=[...])` avec seulement ce qui est nécessaire → agir
4. Si non → **STOP**, dire à Florent : _"J'ai besoin que [X] soit ouvert. Tu peux l'ouvrir ?"_
5. Attendre "ok" explicite avant de continuer

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

## Règle 7 — Pas de question si les logs peuvent répondre

Avant de demander à Florent ce qui se passe dans l'app :
1. Lire les logs via Bash : `tail -50 debug.log | grep -E "\[CC|lecture|TTS"`
2. Lire `cc_state.json` via Python
3. Vérifier le screenshot

Florent = validation visuelle + actions physiques (micro, fenêtre). Claude = logs, code, screenshots, Chrome MCP, scripts Python UIA.

---

## Checklist rapide avant d'utiliser computer-use

```
[ ] La cible est Claude Desktop ? → privilégier scripts UIA/Python (cd_uia_scan, cd_nav_to_session)
[ ] La cible est Chrome/pywebview ? → Chrome MCP à la place
[ ] J'ai vérifié ce qui est ouvert avant request_access ?
[ ] Je vais fermer/minimiser une fenêtre de Florent ? → STOP, interdit
[ ] request_access = uniquement les apps nécessaires ?
```

---

## Historique

- **2026-04-14** — Créé suite à erreurs répétées d'écran + fenêtres. Validé par Florent.
- **2026-04-23** — Écran secondaire spacedesk retiré par Florent. Règles 1 + 1bis réécrites : 1 seul écran, pas de `switch_display`, pilotage CD via scripts UIA/Python en priorité (sidebar repliée = pas bloquant car UIA voit tout). Computer-use = fallback exotique.
