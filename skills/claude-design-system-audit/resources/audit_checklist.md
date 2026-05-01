# Audit Checklist — Claude Design System

Criteres detailles pour scorer un Design System. Adapter selon le contexte du projet (brand maturite, nombre de pages).

## 1. Surface (5 pts)

- [ ] Design system Published = ON
- [ ] Default = ON
- [ ] Titre de projet parlant (pas "Design System" generique)
- [ ] Description de projet remplie (brief initial visible)
- [ ] Pas de warnings critiques (fonts, assets, etc.)

## 2. Tokens couleur (10 pts)

- [ ] Primary color definie (1 ou gradient) — 2 pts
- [ ] Palette neutre complete (at least 5 niveaux : 50, 100, 300, 500, 700, 900) — 2 pts
- [ ] Couleurs semantiques (success, warning, error, info) — 2 pts
- [ ] Accent / signature color coherente sur tous les brand refs — 2 pts
- [ ] Dark mode tokens si applicable — 2 pts

## 3. Typographie (10 pts)

- [ ] Display font definie et uploadee — 3 pts
- [ ] Body font definie et uploadee — 3 pts
- [ ] Scale hierarchique visible (h1, h2, h3, body, caption) — 2 pts
- [ ] Weight range utilisee (400-600-700 minimum) — 1 pt
- [ ] Pas de "Missing brand fonts" warning — 1 pt

## 4. Composants couverts (20 pts, 2 pts chacun)

- [ ] Hero (avec CTA primaire)
- [ ] CTA primaire + secondaire (states hover/active/disabled visibles)
- [ ] Card product/feature
- [ ] Pricing card
- [ ] Testimonial
- [ ] Footer
- [ ] Nav header
- [ ] Badge / label
- [ ] Input / form field
- [ ] Modal / dialog

## 5. Coherence brand refs (15 pts)

- [ ] Au moins 3 brand refs approuvees (KEEP) — 3 pts
- [ ] Pas plus de 10 brand refs (eviter le bruit) — 2 pts
- [ ] Zero doublon entre refs (meme hero x2, meme pricing x3) — 3 pts
- [ ] Nomenclature claire et distinctive (pas "Design 1", "Design 2") — 2 pts
- [ ] Ton et voix coherents entre refs (pas melange "je" / "on" / "vous") — 3 pts
- [ ] Respect des regles absolues du projet (ex : zero em-dash pour Florent) — 2 pts

## 6. Accessibility (10 pts)

- [ ] Contrast text / background > 4.5:1 (via `design:accessibility-review`) — 3 pts
- [ ] Hierarchie visuelle claire (tailles, weights) — 2 pts
- [ ] Focus states visibles sur les interactifs — 2 pts
- [ ] Alt text / aria-label mentionne dans les refs — 1 pt
- [ ] Tailles de target clickable >= 44x44 px — 2 pts

## 7. States et variations (10 pts)

- [ ] Dark mode documente si le projet le supporte — 3 pts
- [ ] Mobile 375px visible sur tous les refs hero — 2 pts
- [ ] Hover / active states decrits — 2 pts
- [ ] Loading / empty / error states couverts — 3 pts

## 8. Reussite extrinseque (10 pts)

- [ ] Les refs sont implementables dans la stack cible (ex : React + Tailwind + shadcn pour Florent) — 3 pts
- [ ] Un dev peut coder a partir du ref sans ambiguite — 3 pts
- [ ] Le handoff est propre (screenshots desktop + mobile + annotations) — 2 pts
- [ ] Les tokens sont extractibles en CSS vars / JSON — 2 pts

## 9. Review hygiene (10 pts)

- [ ] Moins de 5 items en "Needs review" (sinon dette) — 3 pts
- [ ] Tous les refs ont un verdict explicite (KEEP / REWORK / DROP) — 3 pts
- [ ] Les feedbacks "Needs work" sont actionnables (pas vagues) — 2 pts
- [ ] Pas de ref oubliee depuis plus de 30 jours — 2 pts

---

## Scoring

- **90-100 pts** : systeme solide, pret pour production
- **70-89 pts** : bon, quelques gaps secondaires
- **50-69 pts** : moyen, plusieurs gaps a combler avant de generer en masse
- **30-49 pts** : fragile, risque de divergence sur les prochaines generations
- **< 30 pts** : systeme quasi vide, refaire l'initialisation

## Conversion score → note /10

Diviser par 10. Ex : 75 pts = 7.5/10.
