# Reponses calibrees aux questions de clarification — Claude Design

Claude Design pose souvent des questions de clarification avant de generer (surtout Sonnet/Opus en mode reflechi). Ces templates permettent de repondre automatiquement sans bloquer le pipeline.

## Protocole

1. Le skill detecte une question → extrait le contenu (liste numerotee ou choix A/B/C/D)
2. Match contre les patterns ci-dessous
3. Si match → envoie la reponse correspondante
4. Si pas de match → flagger la conversation comme "needs user" et laisser pour validation manuelle

## Pattern 1 — Options A/B/C avec preference defensive

**Detection** : le message contient "Option A", "Option B", "Option C" numerotees, la question est "Laquelle preferes-tu ?"

**Reponse par defaut** :
```
Option A, vas-y. Lance directement. Si tu as plusieurs approches possibles, prends la plus audacieuse et assume le point de vue. Je prefere voir une direction forte que 3 compromis.
```

## Pattern 2 — Fichiers a fournir ou reconstruire

**Detection** : "Tu as deja un design system / maquette / fichier X a partager ?" ou "Souhaites-tu que je reutilise un template existant ?"

**Reponse** :
```
Pas de fichiers a fournir. Reconstruis a partir du brief et des tokens que je t'ai donnes. Utilise le Design System du projet comme reference de marque.
```

## Pattern 3 — URL du site actuel

**Detection** : "Peux-tu me donner l'URL du site actuel ?" ou "As-tu un lien vers le live ?"

**Reponse (dynamique a generer par le skill)** :
```
Oui : {site_url}. Inspire-toi de la structure mais ne la copie pas. L'objectif est de montrer des alternatives convaincantes.
```

Extraire `{site_url}` depuis `CLAUDE_DESIGN_PROJECT_INSTRUCTIONS.md` ou la brand identity. Defaut pour Florent : `https://marketplace-iaaa.vercel.app`.

## Pattern 4 — Traitement des photos

**Detection** : "Comment gerer les photos / images ? Placeholder ou vrai asset ?"

**Reponse** :
```
Placeholder clair avec label "[Photo <sujet> a uploader]" ou "[Logo client X]". Pas de stock photos generiques, pas de portraits IA. Si la section a besoin d'une vraie photo (Florent perso), indique-le explicitement en overlay.
```

## Pattern 5 — Ton de voix et copy

**Detection** : "Quel ton adopter ? Formel, decontracte, expert ?"

**Reponse** :
```
Direct, factuel, preuves chiffrees. Pas de buzzwords (synergies, ecosysteme, disruption). Ton "je" (consultant solo), pas "on" ni "nous". Zero em-dash ni tirets longs dans le texte. Ecris comme un consultant qui parle a un prospect interesse, pas comme une agence qui se vend.
```

## Pattern 6 — Clients et preuves

**Detection** : "As-tu des cas clients / logos a utiliser ?"

**Reponse** :
```
Si tu as un contexte business clair (fourni dans le brief) utilise les references chiffrees mentionnees. Sinon, utilise des placeholders clairement marques "[Cas client X a confirmer]". N'invente pas de logos ou metriques.
```

## Pattern 7 — Nomenclature pricing

**Detection** : "Comment nommer les paliers pricing ? Starter/Growth/Enterprise ?"

**Reponse** :
```
Noms plus parlants type Diagnostic / Pilote / Deploiement / Partenariat, pas Starter/Growth/Enterprise (generique SaaS). Garde les paliers de budget fournis dans le brief. Ajoute un nom courte phrase d'objectif par palier.
```

## Pattern 8 — Structure du header

**Detection** : "Quel style de header ? Minimaliste ? Avec menu burger ? Logo + liens ?"

**Reponse** :
```
Logo + 4 liens ancres vers les sections principales + CTA primaire a droite. Mobile : menu burger simple. Sticky ou non selon la direction (minimaliste = pas sticky, energique = sticky oui).
```

## Pattern 9 — Sections additionnelles

**Detection** : "Veux-tu ajouter une section X ? (FAQ, cas clients, about, blog, etc.)"

**Reponse** :
```
Ajoute une section process (3 a 5 etapes) + une section cas clients avec metriques chiffrees. FAQ optionnelle en bas (4-6 questions). Pas de blog, pas de newsletter signup.
```

## Pattern 10 — Livrable et format

**Detection** : "Comment livres-tu ? HTML, React, Figma ?"

**Reponse** :
```
Design canvas avec 3 colonnes (une par direction). Chaque direction contient desktop 1440px + mobile 375px + annotations courtes (KPI, public cible). Pas de code React a ce stade, juste des mockups visuels.
```

## Pattern 11 — Interactivite

**Detection** : "Dois-je inclure de l'interactivite ? CTAs cliquables, ancres ?"

**Reponse** :
```
Cliquable : CTAs fonctionnels (simuler le clic avec un toast "Redirection Cal.com" par exemple), ancres internes vers les sections, menu mobile qui ouvre et ferme. Pas de vraie submission de formulaire, pas de vrai embed video.
```

## Pattern 12 — Nombre de directions

**Detection** : "Combien de directions veux-tu ? 2, 3, 4 ?"

**Reponse (dynamique)** :
```
{count} directions (valeur fournie par le skill). Elles doivent etre VRAIMENT differentes visuellement, pas des variantes proches. Si j'ai demande 3 : sobre + energique + editorial par exemple. Pas 3 minimales.
```

## Pattern 13 — Mobile-first ou desktop-first

**Detection** : "Prefer tu mobile-first ou desktop-first ?"

**Reponse** :
```
Desktop 1440px d'abord (cible principale pour B2B consultant), mobile 375px en complement. Les 2 doivent etre livres pour chaque direction.
```

## Pattern 14 — Services a detailler

**Detection** : "Peux-tu detailler tes services ?"

**Reponse** :
Ecrire selon le contexte fourni. Template par defaut pour consultant automatisation :
```
Automatisation no-code : connecter tes outils (HubSpot, Notion, Slack) sans dev.
Agent IA : rediger, qualifier, relancer en automatique.
CRM prospection : structurer et accelerer ta pipeline BtoB.
```

## Pattern 15 — Fallback generique

Si aucun pattern ne matche :
```
Vas-y avec ton meilleur jugement. Prends la decision qui maximise l'impact visuel et respecte les contraintes de marque que je t'ai donnees. Si le doute est vraiment critique, genere plutot 2 variantes et je choisirai.
```

---

## Algorithme de matching (pour le skill)

```
FUNCTION matchClarificationQuestion(message_text):
  normalized = message_text.toLowerCase()
  IF contains_any(normalized, ["option a", "option b", "option c"]):
    RETURN pattern_1
  IF contains_any(normalized, ["fichier", "maquette existante", "template existant"]):
    RETURN pattern_2
  IF contains_any(normalized, ["url", "lien vers", "site actuel", "live"]):
    RETURN pattern_3
  IF contains_any(normalized, ["photo", "image", "placeholder"]):
    RETURN pattern_4
  IF contains_any(normalized, ["ton", "voix", "formel", "decontracte"]):
    RETURN pattern_5
  IF contains_any(normalized, ["cas clients", "logos", "testimonial"]):
    RETURN pattern_6
  IF contains_any(normalized, ["pricing", "palier", "starter", "growth"]):
    RETURN pattern_7
  IF contains_any(normalized, ["header", "navigation", "menu"]):
    RETURN pattern_8
  IF contains_any(normalized, ["section additionnelle", "ajouter une section", "faq", "a propos"]):
    RETURN pattern_9
  IF contains_any(normalized, ["livrable", "format", "figma", "html"]):
    RETURN pattern_10
  IF contains_any(normalized, ["interactif", "cliquable", "ancre"]):
    RETURN pattern_11
  IF contains_any(normalized, ["combien de directions", "nombre de variantes"]):
    RETURN pattern_12
  IF contains_any(normalized, ["mobile-first", "desktop-first", "responsive"]):
    RETURN pattern_13
  IF contains_any(normalized, ["services", "detaille", "proposition"]):
    RETURN pattern_14
  
  RETURN pattern_15 // fallback generique
```
