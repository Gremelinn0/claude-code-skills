# Templates de feedback "Needs work" — Claude Design

Quand on marque un brand ref en "Needs work...", le textarea demande un feedback a Claude pour qu'il refasse. Voici des templates a adapter.

**Regle absolue** : zero em-dash (`—`). Utiliser virgule, deux-points, parentheses, points.

## Template 1 — Typographie fade

```
La typographie manque de personnalite. Le display font ressemble a Inter/Roboto (aspect generique AI). Remplace par un serif editorial (ex: Recoleta, Editorial New, Canela) pour le display, et garde Inter pour le body. Teste un ecart de taille plus fort entre h1 (72px+) et body (16px).
```

## Template 2 — Couleurs trop saturees / fades

```
La palette manque de conviction. Choisis une dominante forte (ex: noir 95%, bleu electric 5%) au lieu d'etaler 5 couleurs pastel de force egale. Un accent vif sur fond sobre marche mieux.
```

## Template 3 — Hero generique "AI slop"

```
Le hero ressemble a un template Framer par defaut : background degrade violet/bleu, headline 3 lignes, 2 CTA cote a cote, stats en bas. Reprends avec une aesthetic plus radicale : soit tres minimaliste (Stripe), soit editorial (The Atlantic), soit brutalist (Balenciaga). Commits a un vrai point de vue.
```

## Template 4 — CTA pas assez saillants

```
Les CTA se fondent dans le fond. Augmente le contraste (fill solide, pas ghost), ajoute une ombre portee subtile, et utilise une couleur qui n'apparait nulle part ailleurs dans la page. Test un hover state avec translate-y ou shadow qui bouge.
```

## Template 5 — Trop dense, pas de respiration

```
La page est trop dense, manque de negative space. Double le padding des sections (py-32 minimum). Reduis le nombre d'elements par section (3 cards max, pas 6). Laisse respirer entre les sections avec de vrais "break" visuels.
```

## Template 6 — Manque de hierarchie

```
Tout a la meme importance visuelle. Cree une vraie hierarchie : h1 enormous (plus de 72px), h2 moyen (48px), body petit (16px). Utilise le weight aussi (700 pour les titres, 400 pour le body). Le lecteur doit savoir en 1 seconde ou regarder.
```

## Template 7 — Tokens non respectes

```
La direction ne respecte pas les tokens de marque. Rappel : couleur signature gradient bleu vers violet (#3B82F6 vers #8B5CF6), background dark #050508, typographie Inter. Retravaille avec ces valeurs exactes et pas des substituts.
```

## Template 8 — Ton de voix incorrect

```
Le copy utilise "on" ou "nous" alors que c'est une page personnelle d'un consultant solo. Reprends avec "je" partout. Zero em-dash dans le texte. Pas de buzzwords ("synergies", "ecosysteme"). Vocabulaire concret : "automatiser ta prospection", "eviter de ressaisir des donnees".
```

## Template 9 — Mobile cassee

```
Le layout mobile (375px) est mal gere. Elements trop serres, texte trop petit, CTA impossible a cliquer. Refais le mobile comme un design a part entiere (pas un scale du desktop). Stack vertical, padding genereux, font sizes minimum 16px, tap targets 44x44px.
```

## Template 10 — Trop de CTA concurrents

```
Il y a 6+ CTA qui crient en meme temps sur la page. Reduis a 1 CTA primaire + 1 secondaire max par section. Le primaire unique doit rester visible tout le long de la lecture (sticky nav ou repetition aux moments cles).
```

## Template 11 — Photos stock generiques

```
Les images sont du stock (poignees de main, equipe multiculturelle souriante, graphiques abstraits). Remplace par un placeholder marque [Photo Florent - a uploader] ou par une illustration abstraite Antigravity (particules, gradients geometriques). Pas de stock generique.
```

## Template 12 — Pricing pas lisible

```
La grille pricing est rigide et peu lisible. Reprends avec soit: (a) un slider de budget qui montre ce qu'on obtient selon le range, (b) 4 paliers clairs avec nom distinctif (Diagnostic 500 EUR, Pilote 2-5k, Deploiement 5-15k, Partenariat 15k+), (c) mise en avant forte du palier milieu.
```

## Template 13 — Proof / Cas clients absents

```
La page parle de resultats mais ne montre aucun cas client. Ajoute une section testimonials avec: logo client (ou initiales si NDA), nom + role, quote courte (2 lignes max), metrique chiffree (+40% de rdv, 8h/semaine recuperees, etc). 3 cas clients minimum pour la credibilite.
```

## Template 14 — Section "process" manquante

```
La page saute directement de "ce que je fais" a "book un rdv" sans expliquer comment ca se passe concretement. Ajoute une section "process" : 3 a 5 etapes visuelles (Diagnostic -> Audit -> POC -> Deploiement -> Suivi), chacune avec une ligne explicative et un delai indicatif.
```

## Template 15 — Composant deja vu

```
Cette direction ressemble trop a la direction <autre ref>. Ecarte-toi franchement : si <autre ref> est tres minimal, celle-ci peut etre tres editoriale. Si l'autre est sobre, celle-ci peut etre audacieuse. Objectif : les 2 directions doivent etre visuellement opposees, pas des variantes proches.
```

---

## Comment choisir le bon template

| Probleme observe | Template |
|------------------|----------|
| "C'est beau mais generique" | 1, 3 |
| "Ca se fond, on ne voit rien" | 2, 4, 6 |
| "Trop charge" | 5, 10 |
| "Les regles Florent pas respectees" | 7, 8 |
| "Mobile HS" | 9 |
| "Images bofs" | 11 |
| "Pricing bloquant" | 12 |
| "Pas credible" | 13 |
| "Manque d'etapes" | 14 |
| "2 refs se ressemblent" | 15 |

## Concatenation

Tu peux combiner 2-3 templates si plusieurs problemes coexistent. Exemple : "Hero generique + mobile cassee + pas de cas clients" = templates 3 + 9 + 13 colles bout a bout, en 1 feedback structure a puces.
