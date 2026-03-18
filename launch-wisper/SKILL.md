---
name: launch-wisper
description: Lance l'app Wisper (speak-app-dev) en background. PROACTIF — lancer automatiquement apres toute modification de code dans speak-app-dev/ pour que l'utilisateur puisse tester. Ne pas attendre qu'il le demande.
user_invocable: true
command: wisper
---

# Launch Wisper

Lance `python app.py` depuis `speak-app-dev/` en arriere-plan.

## Quand utiliser ce skill

**PROACTIF** — Ce skill doit etre utilise automatiquement, sans que l'utilisateur le demande :
- Apres toute modification de fichier dans `speak-app-dev/` (app.py, llm_engine.py, etc.)
- Quand l'utilisateur doit tester, verifier ou voir un changement sur l'app
- Quand l'utilisateur parle de "lancer", "ouvrir", "tester", "verifier" l'app

**Ne pas demander de confirmation.** C'est systematique.

## Instructions

1. **Tuer l'instance SpeakApp via PID file AVANT de lancer** :
```bash
PID_FILE="C:/Users/Administrateur/PROJECTS/3- Wisper/speak-app-dev/speakapp.pid"; if [ -f "$PID_FILE" ]; then PID=$(cat "$PID_FILE"); taskkill //F //T //PID $PID 2>/dev/null; rm -f "$PID_FILE"; fi; sleep 2; cd "C:\Users\Administrateur\PROJECTS\3- Wisper\speak-app-dev" && python app.py
```
Utiliser `run_in_background: true`.

**Le fichier `speakapp.pid` contient le PID exact de l'app.** Ca tue UNIQUEMENT SpeakApp, pas les autres processus Python (Claude, scripts, etc.).
**Note : utiliser `taskkill //F //T //PID` (double-slash en bash Windows), pas `kill -f`.**

4. Confirmer brievement : "App relancee." ou "App lancee." — pas de pave.

5. **Si ce lancement fait suite a une modification de code** → enchainer ces 3 actions :
   a. **`doc-keeper`** — mettre a jour MEMORY.md, changelog.md, roadmap.md, todo.md
   b. **`qa-agent` (rapide)** — mettre a jour le skill qa-agent si la modif ajoute de nouvelles features, commandes, ou change des comportements a verifier. Ajouter les nouveaux checks dans le prompt du scheduled task `speakapp-qa-daily`.
   c. **`run-tests`** — lancer les tests pour verifier qu'il n'y a pas de regression. Si un test casse a cause d'un changement volontaire (ex: nombre de commandes change), mettre a jour le test.

## Boucle d'amelioration continue

```
Code modifie
    → launch-wisper (restart app)
    → doc-keeper (docs a jour)
    → qa-agent mis a jour (nouveaux checks)
    → run-tests (pas de regression)
    → utilisateur teste manuellement
    → bugs trouves → on fixe → retour au debut
```

Le QA quotidien (2h du matin) verifie tout automatiquement avec les checks les plus recents.

## Pour arreter l'app
```bash
PID_FILE="C:/Users/Administrateur/PROJECTS/3- Wisper/speak-app-dev/speakapp.pid"; if [ -f "$PID_FILE" ]; then PID=$(cat "$PID_FILE"); taskkill //F //T //PID $PID 2>/dev/null; rm -f "$PID_FILE"; fi
```
Alternative brute (tue TOUS les Python) : `taskkill //F //T //IM python.exe`
