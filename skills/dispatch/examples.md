# Sonnet Agents — Exemples concrets

3 tâches <your-project> dispatcheées en parallèle. Référence pour rédiger un prompt sub-agent.

## Tâche 1 : `GAP-CLCHAT-03` — Dismiss popup Routines sur claude.ai/chat

```
Fichier : wisper-bridge/content_scripts/detector.js
Ajouter : détection + clic sur button[text="Compris"] dans le popup Routines
Style à suivre : chercher "dismiss" ou "popup" dans le fichier pour voir comment c'est déjà fait
```

## Tâche 2 : `GAP-CLCODE-05` — Prefix `[Plan] :` avant lecture TTS

```
Fichier : app.py
Ajouter : prefix "[Plan] : " dans la fonction qui lit les plans TTS
Style : chercher d'autres prefixes comme "[Question] :" pour voir le pattern
```

## Tâche 3 : `GAP-GEM-04` — Mapping modèle Gemini

```
Fichier : app.py ou detector.js
Ajouter : mapping "opus" → "2.5 Ultra", "sonnet" → "2.5 Pro", "haiku" → "2.5 Flash"
Style : chercher MODEL_MAP ou model_mapping pour voir le pattern existant
```

Ces 3 tâches touchent des fichiers différents → 3 agents en parallèle, safe.

---

## Pourquoi ces tâches sont des bons candidats Sonnet

- **Scope clair** : 1 fichier, 1 endroit, 1 modification additive
- **Style à copier** : un pattern existant dans le fichier sert de référence
- **Pas de logique complexe** : ajouter une entrée dans une liste/dict, un préfixe, un mapping
- **Tests existants** : `python -m pytest test_speakapp.py -x -q` valide la non-régression

## Anti-exemples (à NE PAS donner à Sonnet)

- "Refactore la détection auto-perm pour qu'elle gère les 3 plateformes en commun" → trop large, scope flou
- "Fix le bug de race condition dans le watchdog" → debug, pas additif
- "Améliore la performance du Chat Reader" → pas mesurable, trop vague
- "Ajoute une feature : appuyer sur F2 lit le dernier message" → multi-fichiers + UX décisions
