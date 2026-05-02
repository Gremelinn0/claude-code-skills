---
name: speakapp-partners
description: Hub associés SpeakApp — présentation externe produit pour partage avec associés/investisseurs. Contenu, déploiement Vercel, règles de langage public-facing.
type: project-skill
---

# speakapp-partners — Hub Associés

Page publique SpeakApp déployée sur Vercel, partageable avec associés et investisseurs.

## URLs

| Ressource | URL |
|-----------|-----|
| **Page live** | https://speakapp-partners.vercel.app |
| **Master Hub** | https://antigravity-master-hub.vercel.app |

## Fichiers source

| Fichier | Rôle |
|---------|------|
| `dashboards/speakapp-partners.html` | Source de vérité — éditer ici |
| `C:\Users\Administrateur\PROJECTS\3- Wisper\speakapp-partners\index.html` | Copie pour projet Vercel (sync obligatoire avant deploy) |

## Sources de contenu

| Source | Ce qu'on y prend |
|--------|-----------------|
| `memory/features/README.md` | Statuts V1 actuels (source de vérité features) |
| `memory/core/product-identity.md` | Business model, pricing tiers, URLs Vercel |
| `memory/roadmap/roadmap.md` | Phases roadmap (lire §1 pour priorisation) |
| `FEATURES.md` | Descriptions features orientées utilisateur |

## Déploiement (obligatoire après toute modif)

```bash
# 1. Sync dashboards → projet Vercel
cp "dashboards/speakapp-partners.html" "C:/Users/Administrateur/PROJECTS/3- Wisper/speakapp-partners/index.html"

# 2. Deploy
cd "C:/Users/Administrateur/PROJECTS/3- Wisper/speakapp-partners"
npx vercel deploy --prod --yes
```

## Sections de la page

1. **Hero** — tagline + plateformes + statut V1
2. **3 briques** — Dictée / Lecture / Control Center
3. **Boucle vocale** — diagramme flow interactif
4. **Features V1** — grid cartes avec badges statut
5. **Plateformes** — Claude / ChatGPT / Gemini / AntiGravity
6. **Pricing** — Free / Pro / Team
7. **Roadmap** — 3 phases user-centric
8. **Footer** — contact + liens

## Badges statut features

| Badge | CSS class | Quand utiliser |
|-------|-----------|----------------|
| **Live** | `badge-done` (vert) | Feature ✅ V1 dans README.md |
| **Bêta** | `badge-wip` (orange) | Feature 🔧 code ready, validation en cours |
| **En développement** | `badge-dev` (violet) | Feature en cours, pas encore bêta |

## Règles de contenu — NON NÉGOCIABLES

**Public-facing = zéro jargon technique :**
- ❌ Noms STT engine (Gladia, Vosk, Edge TTS)
- ❌ Termes internes (BP-XXX, UIA, CDP, WS Bridge, hooks JSONL)
- ❌ Détails d'implémentation (cooldowns, guards, watchdog)
- ❌ Raccourcis système bruts (Ctrl+Alt+K) dans la roadmap

**✅ Uniquement :**
- Gain ressenti par l'utilisateur ("parler sans toucher le clavier")
- Ce que l'user voit / entend / ressent
- Langage simple, phrases courtes, orienté bénéfice

**Roadmap = 3 phases user-facing :**
- "Mains libres" (Mai 2026)
- "Votre assistant" (Été 2026)
- "Pour toute l'équipe" (Fin 2026)

Pas de numéros de version techniques (V1.1, V2) dans les titres de phase.

## ⚡ Chantier en cours — Redesign complet (session suivante)

**Problème identifié session 2026-05-01** : page trop proche d'un hub dev interne, roadmap "naze" visuellement, branding pas aligné avec l'identité visuelle du widget SpeakApp.

**Brief redesign :**
1. **Roadmap** — refaire entièrement : belle, design, mémorable. Pas un tableau ou une liste. Quelque chose qui donne envie, qui raconte une histoire.
2. **Branding & thème visuel** — proposer 2-3 univers / directions visuelles cohérents avec l'identité du widget original. Référence obligatoire : skill `/widget` (lire AVANT de proposer quoi que ce soit).
3. **Cohérence globale** — la page doit ressembler à un vrai site produit, pas à un dashboard interne.

**Référence design widget** : invoquer `/widget` pour récupérer l'identité visuelle (couleurs, formes, animations, ambiance). Le widget = la "vraie" identité de SpeakApp. La page partners doit être dans le même univers.

**Livrable attendu** :
- Proposer 2-3 directions thématiques (nom + description + palette + vibe) avant de coder
- Florent choisit une direction
- Implémenter + déployer via workflow standard ci-dessus
