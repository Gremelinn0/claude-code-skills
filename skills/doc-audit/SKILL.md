---
name: doc-audit
description: Verifie la coherence entre les fichiers memoire et le code. Detecte les orphelins (fichier memoire absent de MEMORY.md), les fantomes (reference dans MEMORY.md vers fichier inexistant), et les valeurs driftees (constantes dans le code vs dans les docs). Utiliser apres une session longue, avant un audit, ou quand on suspecte une incoherence.
---

# Doc Audit — Coherence 4 sources

## Les 4 sources de verite

| # | Source | Quoi verifier |
|---|--------|--------------|
| 1 | **Docs MD** (`memory/*.md`) | Valeurs, features, status, counts |
| 2 | **Code Python** (`<project-folder>/`) | Constantes, commandes, config, plans Stripe |
| 3 | **Settings/Config** (`config.json`, `settings_window.py`) | Plans affiches, prix, options, flags |
| 4 | **Site web** (`speakapp.work`) | Plans, prix, features affichees, CTA |

**Principe : une seule verite par information. Si 2 sources divergent → signaler + corriger.**

---

## Quand utiliser

- **Systematiquement** : apres `doc-keeper` (pipeline post-dev)
- **Periodiquement** : tache programmee `speakapp-health-check` (toutes les 2h)
- **Sur demande** : quand une valeur semble incoherente
- Quand l'utilisateur dit "attends, c'est quoi la valeur de X ?"

## Pipeline post-dev (ordre obligatoire)

```
Code modifie
    → launch-wisper       (relance l'app — immediat)
    → doc-keeper          (met a jour les docs MD)
    → doc-audit           (verifie coherence 4 sources)  ← CE SKILL
    → run-tests           (verifie que rien est casse)
```

---

## Ce que verifie cet audit

### 1. Orphelins (fichiers memoire pas dans MEMORY.md)

```
Lister tous les fichiers .md dans le dossier memory/ (sauf MEMORY.md).
Pour chacun, verifier qu'il apparait dans l'index de MEMORY.md.
Signaler tout fichier absent de l'index.
```

### 2. Fantomes (liens MEMORY.md vers fichiers inexistants)

```
Extraire tous les liens [fichier.md](./fichier.md) de MEMORY.md.
Pour chacun, verifier que le fichier existe sur disque.
Signaler les liens morts.
```

### 3. Valeurs driftees — MD vs Code

| Valeur | Ou dans les docs | Ou dans le code | Valeur attendue |
|--------|-----------------|-----------------|-----------------|
| idle_threshold | feedback_watchdog_ux.md (Regle 3) | watchdog_engine.py default | 60s |
| Vosk command count | MEMORY.md (Commandes Vosk) | app.py (VOSK_COMMANDS dict) | 32 clavier + 26 speciales |
| Test count | testing.md | test_speakapp.py (nb de tests) | doit correspondre |
| Sprint status | MEMORY.md (Etat actuel) | changelog.md | coherent |
| Pricing plan | pricing.md | settings_window.py + deployment.md | coherent |

### 4. Check Settings/Config (source 3)

Lire `<project-folder>/settings_window.py` et tout fichier `config.json` :
- Plans affiches dans l'interface : noms, prix, descriptions
- Comparer avec `pricing.md` et `deployment.md`
- Signaler tout ecart (ex: "settings dit 3 plans, pricing.md dit 1 plan")

Lire aussi `<project-folder>/config.json` si existant :
- Valeurs de seuils, timeouts, flags features
- Comparer avec les constantes documentees dans `memory/`

### 5. Check Site web (source 4) — speakapp.work

```
Utiliser WebFetch sur https://speakapp.work pour lire le contenu du site.
Extraire : plans affiches, prix, features mentionnees, CTA (boutons d'action).
Comparer avec pricing.md, deployment.md, loveable.md.
Signaler tout ecart entre ce qu'affiche le site et ce que disent les docs.
```

**Exemple d'incoherence detectee :** site affiche "Starter 9.99 + Pro 19.99" mais pricing.md dit "plan unique 9.99" → signaler + rediger prompt Loveable de correction.

**Note :** Si le site diverge → NE PAS modifier le code. Rediger un prompt Loveable pret a copier pour l'utilisateur.

### 6. Coherence interne des docs

- `changelog.md` : le dernier entry correspond-il a ce qui est dans `status.md` ?
- `deployment.md` : les URLs correspondent-elles a celles dans `loveable.md` ?
- `action-triggers.md` : les core functions mentionnees existent-elles dans `app.py` ?
- `watchdog-vision-v2.md` : l'idle_threshold mentionne (60s) est-il dans `watchdog_engine.py` ?
- `pricing.md` vs `deployment.md` vs `settings_window.py` vs `speakapp.work` : MEMES plans et prix ?

---

## Format de rapport

Apres l'audit, produire un rapport structure :

```
## Rapport Doc Audit — [date]

### Source 1 — Orphelins (N fichiers absents de MEMORY.md)
- fichier.md — [description courte du contenu]
→ Action : ajouter dans MEMORY.md sous la section [feature]

### Source 1 — Fantomes (N liens morts)
- lien dans MEMORY.md → fichier inexistant
→ Action : supprimer le lien ou recreer le fichier

### Sources 1+2 — Valeurs driftees (N incoherences MD↔Code)
- idle_threshold : docs disent Xs, code dit Ys
→ Action : corriger [lequel] pour matcher [lequel]

### Source 3 — Settings/Config (N incoherences)
- settings_window.py affiche 3 plans (Basic/Pro/Enterprise)
- pricing.md dit plan unique 9.99€
→ Action : [corriger le code OU mettre a jour pricing.md] + explication

### Source 4 — Site web speakapp.work (N incoherences)
- Site affiche : [ce que dit le site]
- Docs disent : [ce que disent les docs]
→ Action : prompt Loveable a envoyer (pret a copier)

### OK (N verifications passees)
- idle_threshold : 60s dans docs et code ✓
- Test count : 287 dans testing.md et test_speakapp.py ✓
- ...

### Actions a faire
1. ...
2. ...
```

---

## Regles apres l'audit

1. **Signaler AVANT de corriger** : montrer le rapport a l'utilisateur, ne pas corriger silencieusement
2. **Petit changement = petit edit** : corriger chirurgicalement, ne pas reecrire les fichiers
3. **Toujours lire avant d'editer** : ne jamais editer un fichier memoire a l'aveugle
4. **Mettre a jour MEMORY.md en dernier** : apres avoir corrige les fichiers individuels
5. **Site web divergent → prompt Loveable** : ne jamais toucher au code web directement

---

## Valeurs de reference (a jour 2026-04-11)

| Constante | Valeur validee | Fichier source de verite |
|-----------|---------------|--------------------------|
| idle_threshold | 3s (IDE) ou 10s (autres) — config par défaut | watchdog_engine.py ligne ~2065 (`_default_ilt`) |
| Panel refresh | 2 secondes | watchdog_panel.py |
| Pixel diff threshold | 5% | watchdog_engine.py |
| Pixel diff consecutive polls | 3 | watchdog_engine.py |
| OCR confirmation reads | 2 | watchdog_engine.py |
| Max watchdog duration | 1800s (30 min) | app.py config |
| Toast width (Style B) | 340px | app.py CARD_W |
| Pricing plan(s) | A VERIFIER via audit | pricing.md + deployment.md + settings_window.py + speakapp.work |
| Vosk always-on commands | 41 clavier | app.py VOSK_ALWAYS_ON_COMMANDS |
| Vosk special commands | 54 speciales (dont 7 auto-pilot 2026-04-11) | app.py VOSK_SPECIAL_COMMANDS |
| DONE debounce | 3.0s (`_DONE_DEBOUNCE_S`) | app.py:7774 |
| CLAUDE_SIDEBAR_RATIO | 0.25 | watchdog_engine.py:295 |
| CLAUDE_SIDEBAR_MAX_PX | 400px | watchdog_engine.py:298 |
| AG_SIDEBAR_SKIP | set de tokens UI a ignorer | watchdog_engine.py:385 (ex-`_CD_UI_TOKENS`) |
| _USER_X_MIN | 840 | uia_reader.py:1079 |
| _CHAT_SHORT_THRESHOLD | 12 phrases | app.py:3875 |
| Confidence seuil always-on default | avg 0.85 / min 0.80 | stt_engine.py:854-855 |
| Confidence seuil "stop" | avg 0.88 / min 0.84 | app.py:818 (abaisse — etait 0.95/0.92) |
| DEFAULT_SESSION_TIMEOUT_SEC (autopilot) | 300s | app.py config |
| DEFAULT_STUCK_THRESHOLD (autopilot) | 3 | app.py config |


---

## Auto-amelioration

**Ce skill s'ameliore a chaque usage.** C'est une responsabilite, pas un bonus.

Apres chaque execution, avant de conclure :
1. **Friction detectee ?** (etape confuse, ordre sous-optimal, info manquante) → corriger ce skill immediatement
2. **Bug resolu ou pattern decouvert ?** → l'ajouter dans la section pieges/patterns de ce skill
3. **Approche validee ?** → l'ancrer comme pattern reference dans ce skill
4. **Gain applicable a d'autres skills ?** → propager (ou PROPOSITION DE REGLE si transversal)

**Regle : ne jamais reporter une amelioration a "plus tard". L'appliquer maintenant ou la perdre.**
