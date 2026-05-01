# Direction Templates — 6 prompts pre-ecrits

Chaque template est un prompt complet a envoyer comme une conversation Claude Design. Les placeholders `{page}`, `{business_context}`, `{tokens}`, `{regles_absolues}` sont substitues dynamiquement par le skill.

**Regle** : zero em-dash (`—`) dans tous les prompts. Utiliser virgule, parentheses, deux-points, points.

---

## Template 1 — Stripe Minimal

```
Tu es un designer obsede par la simplicite. Cree une direction visuelle pour {page} dans le style Stripe (https://stripe.com/pricing) :

Contraintes visuelles :
- Fond blanc ou tres clair (#fafafa max)
- Typographie sans-serif minimaliste (Inter)
- Un seul accent couleur vif (respecter les tokens : {tokens})
- Beaucoup de whitespace, padding genereux (py-32 minimum entre sections)
- Elements alignes grid strict, pas d'asymetrie gratuite
- CTAs discrets mais contrastes (fond solide sur fond blanc)

Contenu :
{business_context}

Sections a produire :
1. Hero epure (headline + sub + 1 CTA)
2. Section features (3 a 5 cards minimalistes)
3. Pricing (grille clean)
4. FAQ (accordeon sobre)
5. Footer minimal

Livre :
- Desktop 1440px
- Mobile 375px
- Brief stratégique : pourquoi cette direction marche pour {page}, quel type de visiteur est vise

Regles absolues :
{regles_absolues}
```

---

## Template 2 — Linear Energetic

```
Tu es un designer obsede par l'energie visuelle controlee. Cree une direction pour {page} dans le style Linear (https://linear.app) :

Contraintes visuelles :
- Fond dark (#0a0a0a) avec accents lumineux
- Gradients subtils en background (mesh violet/bleu/noir)
- Typographie mix display (ex: Berkeley Mono ou serif display) + Inter body
- Effets de profondeur : shadows, glows, depth layers
- Animations implicites (hover states forts, scroll reveals)
- Dense mais lisible, hierarchie forte

Contenu :
{business_context}

Sections a produire :
1. Hero avec mesh gradient animated + headline gras + 2 CTA (primaire rempli, secondaire ghost)
2. Features avec cards glassmorphism (subtle border, fond semi-transparent)
3. Social proof (logos clients rangee continue)
4. Call to action final full-width sombre
5. Footer sombre avec grande typo

Livre :
- Desktop 1440px
- Mobile 375px
- Brief : ton cible (tech-savvy, ambitieux), micro-interactions suggerees

Regles absolues :
{regles_absolues}
```

---

## Template 3 — Editorial Warm

```
Tu es un designer editorial (think The Atlantic, Magazine Hermes, Notion affiliate). Cree une direction pour {page} chaude, narrative, personnelle :

Contraintes visuelles :
- Fond creme / ivoire (#faf8f3 ou similaire)
- Typographie serif display forte (ex: Editorial New, Recoleta, Canela) pour les titres + Inter body
- Accents couleur chauds (rouge brique, olive, moutarde) sur couleurs signature respectees dans tokens
- Photos et illustrations organiques, pas de vecteurs tech cliches
- Asymetrie editoriale (grandes typos decalees, colonnes variables)
- Ton de texte narratif, chapitres, "tu" intime

Contenu :
{business_context}

Sections a produire :
1. Hero narratif (intro personnelle, 2-3 lignes poetiques + CTA doux)
2. "Pourquoi j'ai commence" (storytelling avec photo placeholder)
3. "Ce que je fais concretement" (3 piliers en cards editoriales)
4. Testimonials chaleureux (grandes quotes, pas de logo-wall froid)
5. Pricing "invitation" (pas "plans" mais "formules d'accompagnement")
6. Footer editorial avec signature

Livre :
- Desktop 1440px
- Mobile 375px
- Brief : pour qui ca parle (clients qui cherchent une relation, pas un prestataire)

Regles absolues :
{regles_absolues}
```

---

## Template 4 — Brutalist Bold

```
Tu es un designer brutalist (think Balenciaga, Are.na, Bloomberg Beta). Cree une direction pour {page} radicale, disruptive, memorable :

Contraintes visuelles :
- Palette brute : noir pur (#000), blanc pur (#fff), 1 couleur d'accent neon (respecter tokens si compatible)
- Typographie sans-serif ultra bold (ex: Neue Haas Grotesk Display, Inter Black) ou mono (JetBrains Mono)
- Grid exposee, lignes noires, borders epaisses
- Pas de border-radius (angles droits)
- Typographie gigantesque (h1 >= 120px)
- Elements decales, overlap assume, hierarchie par la taille

Contenu :
{business_context}

Sections a produire :
1. Hero manifesto (headline 4 lignes XXL + CTA rectangulaire noir)
2. Sections avec gros chiffres (un chiffre de 200px par section, ex "01", "02")
3. Pricing table brutaliste (grille mono, border-black, pas d'ornement)
4. Testimonials en blockquote XXL sans avatar ni logo
5. Footer avec manifesto

Livre :
- Desktop 1440px
- Mobile 375px
- Brief : positionnement radical que cette direction communique

Regles absolues :
{regles_absolues}
```

---

## Template 5 — Ambitious Hormozi VSL

```
Tu es un designer conversion (think Alex Hormozi, Dan Koe long-form sales letter). Cree une direction pour {page} structuree pour maximiser les conversions :

Structure obligatoire VSL :
1. **Hero hook emotionnel** : 1 grande promesse + sous-titre qui nomme le probleme + CTA premier
2. **Problem agitation** : "Voila pourquoi ta methode actuelle ne marche pas" (3 douleurs specifiques)
3. **Solution unique** : "La methode {differenciateur}" (le pitch ecrit en gros)
4. **Mechanism** : comment ca marche concretement (3 a 5 etapes)
5. **Proof massif** : testimonials videos, cas clients chiffres, logos (autant que disponible)
6. **Offer** : ce qui est inclus, bullet list de value, equivalent en EUR
7. **Guarantee** : risk reversal (ex: "satisfait ou remboursement 14 jours")
8. **FAQ dedouane** : repondre aux objections frequentes
9. **CTA final fort** + rappel de la guarantee

Contraintes visuelles :
- Typographie lisible (Inter body + display forte pour les hooks)
- Couleurs respectent tokens mais avec emphase sur CTA (bouton orange ou rouge si autorise)
- CTAs repetes (minimum 5 sur la page)
- Longform assume, scroll long OK (1.5x la home classique)
- Punchy, direct, pas de fluff

Contenu :
{business_context}

Livre :
- Desktop 1440px (longform ~5000px de scroll)
- Mobile 375px (meme structure)
- Brief : hook choisi, angle principal, KPI primaire vise (% clic CTA, % scroll depth)

Regles absolues :
{regles_absolues}
```

---

## Template 6 — CRO Optimized

```
Tu es un expert CRO. Cree une direction pour {page} structuree pour maximiser la conversion sur un KPI precis.

Propose 3 structures alternatives pour {page} avec KPI primaire different :

A. **Mini-landing courte** (style Steph Smith, Tiny Studio)
   - Scroll court, tout above the fold
   - Hero percutant avec 1 seule promesse chiffree
   - 1 section "ce que tu obtiens en 30 min"
   - 3 logos clients cliquables
   - CTA en 2 endroits : top + bottom
   - KPI : % clic CTA, bookings < 30s de lecture

B. **Video-first landing**
   - Hero = placeholder video VSL pleine largeur ("Regarde cette video de 2 min")
   - Sous la video : embed booking direct (Cal.com iframe ou equivalent)
   - Sections basses sobres (FAQ, cas clients, pricing paliers)
   - KPI : % video played >50%, booking sans clic sortant

C. **Split test longform** (version courte de VSL)
   - Hero emotionnel + CTA
   - Problem/Solution condense en 3 sections
   - Proof inserree entre sections
   - CTA repete 3 fois
   - KPI : scroll depth + conversion globale

Pour chaque structure :
- Desktop 1440px + Mobile 375px
- KPI primaire annote en overlay
- Brief court : public cible, moment de la journee, intent de trafic

Contenu de base :
{business_context}

Regles absolues :
{regles_absolues}
```

---

## Guide de selection intelligente (defaut si utilisateur ne precise pas)

| Page cible | Selection recommandee (3 directions) |
|------------|---------------------------------------|
| `/agence` (page perso consultant) | Stripe Minimal + Editorial Warm + Hormozi VSL |
| `/pricing` | Stripe Minimal + Linear Energetic + CRO Optimized |
| `/vote` (feature request) | Linear Energetic + Editorial Warm + Brutalist |
| `/produit/:slug` | Stripe Minimal + Editorial Warm + Linear Energetic |
| `/` home | Linear Energetic + Editorial Warm + Hormozi VSL |

Pour 5-6 directions : piocher tous les templates du haut du tableau puis completer avec Brutalist et CRO.

## Substitution des placeholders

- `{page}` : ex "/agence", "/pricing"
- `{business_context}` : recap du brief utilisateur + cas clients + services (extrait de CLAUDE_DESIGN_PROJECT_INSTRUCTIONS.md ou brand-identity)
- `{tokens}` : couleurs, typos, signatures (ex : "gradient #3B82F6 vers #8B5CF6, dark #050508, Inter 300-800")
- `{regles_absolues}` : liste a puces des regles non-negociables (zero em-dash, "je" pas "on", etc.)
