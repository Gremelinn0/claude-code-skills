---
name: speakapp-partners
description: Hub associÃ©s SpeakApp â€” prÃ©sentation externe produit pour partage avec associÃ©s/investisseurs. Contenu, dÃ©ploiement Vercel, rÃ¨gles de langage public-facing.
type: project-skill
---

# speakapp-partners â€” Hub AssociÃ©s

Page publique SpeakApp dÃ©ployÃ©e sur Vercel, partageable avec associÃ©s et investisseurs.

## URLs

| Ressource | URL |
|-----------|-----|
| **Page live** | https://speakapp-partners.vercel.app |
| **Master Hub** | https://antigravity-master-hub.vercel.app |

## Fichiers source

| Fichier | RÃ´le |
|---------|------|
| `dashboards/speakapp-partners.html` | Source de vÃ©ritÃ© â€” Ã©diter ici |
| `C:\Users\Utilisateur\PROJECTS\3- Wisper\speakapp-partners\index.html` | Copie pour projet Vercel (sync obligatoire avant deploy) |

## Sources de contenu

| Source | Ce qu'on y prend |
|--------|-----------------|
| `memory/features/README.md` | Statuts V1 actuels (source de vÃ©ritÃ© features) |
| `memory/core/product-identity.md` | Business model, pricing tiers, URLs Vercel |
| `memory/roadmap/roadmap.md` | Phases roadmap (lire Â§1 pour priorisation) |
| `FEATURES.md` | Descriptions features orientÃ©es utilisateur |

## DÃ©ploiement (obligatoire aprÃ¨s toute modif)

```bash
# 1. Sync dashboards â†’ projet Vercel
cp "dashboards/speakapp-partners.html" "C:/Users/Utilisateur/PROJECTS/3- Wisper/speakapp-partners/index.html"

# 2. Deploy
cd "C:/Users/Utilisateur/PROJECTS/3- Wisper/speakapp-partners"
npx vercel deploy --prod --yes
```

## Sections de la page

1. **Hero** â€” tagline + plateformes + statut V1
2. **3 briques** â€” DictÃ©e / Lecture / Control Center
3. **Boucle vocale** â€” diagramme flow interactif
4. **Features V1** â€” grid cartes avec badges statut
5. **Plateformes** â€” Claude / ChatGPT / Gemini / AntiGravity
6. **Pricing** â€” Free / Pro / Team
7. **Roadmap** â€” 3 phases user-centric
8. **Footer** â€” contact + liens

## Badges statut features

| Badge | CSS class | Quand utiliser |
|-------|-----------|----------------|
| **Live** | `badge-done` (vert) | Feature âœ… V1 dans README.md |
| **BÃªta** | `badge-wip` (orange) | Feature ðŸ”§ code ready, validation en cours |
| **En dÃ©veloppement** | `badge-dev` (violet) | Feature en cours, pas encore bÃªta |

## RÃ¨gles de contenu â€” NON NÃ‰GOCIABLES

**Public-facing = zÃ©ro jargon technique :**
- âŒ Noms STT engine (Gladia, Vosk, Edge TTS)
- âŒ Termes internes (BP-XXX, UIA, CDP, WS Bridge, hooks JSONL)
- âŒ DÃ©tails d'implÃ©mentation (cooldowns, guards, watchdog)
- âŒ Raccourcis systÃ¨me bruts (Ctrl+Alt+K) dans la roadmap

**âœ… Uniquement :**
- Gain ressenti par l'utilisateur ("parler sans toucher le clavier")
- Ce que l'user voit / entend / ressent
- Langage simple, phrases courtes, orientÃ© bÃ©nÃ©fice

**Roadmap = 3 phases user-facing :**
- "Mains libres" (Mai 2026)
- "Votre assistant" (Ã‰tÃ© 2026)
- "Pour toute l'Ã©quipe" (Fin 2026)

Pas de numÃ©ros de version techniques (V1.1, V2) dans les titres de phase.

## âš¡ Chantier en cours â€” Redesign complet (session suivante)

**ProblÃ¨me identifiÃ© session 2026-05-01** : page trop proche d'un hub dev interne, roadmap "naze" visuellement, branding pas alignÃ© avec l'identitÃ© visuelle du widget SpeakApp.

**Brief redesign :**
1. **Roadmap** â€” refaire entiÃ¨rement : belle, design, mÃ©morable. Pas un tableau ou une liste. Quelque chose qui donne envie, qui raconte une histoire.
2. **Branding & thÃ¨me visuel** â€” proposer 2-3 univers / directions visuelles cohÃ©rents avec l'identitÃ© du widget original. RÃ©fÃ©rence obligatoire : skill `/widget` (lire AVANT de proposer quoi que ce soit).
3. **CohÃ©rence globale** â€” la page doit ressembler Ã  un vrai site produit, pas Ã  un dashboard interne.

**RÃ©fÃ©rence design widget** : invoquer `/widget` pour rÃ©cupÃ©rer l'identitÃ© visuelle (couleurs, formes, animations, ambiance). Le widget = la "vraie" identitÃ© de SpeakApp. La page partners doit Ãªtre dans le mÃªme univers.

**Livrable attendu** :
- Proposer 2-3 directions thÃ©matiques (nom + description + palette + vibe) avant de coder
- Florent choisit une direction
- ImplÃ©menter + dÃ©ployer via workflow standard ci-dessus
