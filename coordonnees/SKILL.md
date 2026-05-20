---
name: coordonnees
description: Source canonique UNIQUE des coordonnées + comptes + identifiants + emails + adresses + infos perso/pro de Florent — Notion comme source de vérité. Skill global cross-projets. Triggers "/coordonnees", "coordonnées", "mes identifiants", "où sont mes accès", "infos perso", "infos pro", "siret", "siren", "email pro", "compte Google", "compte Notion", "code APE", "Infogreffe", "Qonto login", "domaine speakapp.work", "PROSPECTPARTNER", "EI Florent", "mes mots de passe", "où c'est noté". Lecture obligatoire AVANT toute action admin/login/KYC/cert/contrat/email pro.
type: user-skill
---

# /coordonnees — Source canonique UNIQUE des infos perso/pro Florent

## 🎯 Règle absolue (gravée 2026-05-20 Florent verbatim)

> *« On n'ait QU'UNE SEULE source, définitivement une seule source, qui serait clairement Notion. (...) Si je te parle de coordonnées, je te parle directement de ça. Tu tiens toujours ce truc parfaitement à jour, qu'il soit propre et clair. »*

**Notion = LA source canonique unique** pour toutes les coordonnées Florent. Tout autre fichier (miroir local `memory/coordonnees.md` projet par projet, autres docs) = **MIROIR**, jamais source primaire.

## 🔗 URLs canoniques Notion (à ouvrir directement)

| Ressource | URL Notion |
|-----------|------------|
| **🔐 Coordonnées & Accès** (page maître) | https://www.notion.so/521e6926c82148b9ae394ba7b1fb5594 |
| **🏢 EI Florent de Maisoncelle — Infos administratives PROSPECTPARTNER** | https://www.notion.so/36501e69443c81bd8e4ff27ca04bd891 |
| **Comptes Pro** (sous-page) | https://www.notion.so/34901e69443c817f94b6cf8904de32ec |
| **Comptes Perso** (sous-page) | https://www.notion.so/34901e69443c81fd9e0bdebba3d8052b |
| **APIs & Infrastructure** | https://www.notion.so/34901e69443c8102b953d3d2ffdecbe0 |
| **Speak App** (sous-page coords) | https://www.notion.so/36601e69443c8056ad17d62259c5f11d |
| **🔐 Codes de secours 2FA `florent.maisoncelle@speakapp.work`** | https://www.notion.so/36601e69443c81cdb334fbcea437b7d1 |
| **Clients** | https://www.notion.so/1ad01e69443c80549cf8d98b5de924c1 |
| **Appartements & Logement** | https://www.notion.so/19e01e69443c80bfbe12e69cea6b7afd |

## 🚨 Anti-yoyo 2026-05-20 — Logins services administratifs (corrections post-domaine cassé)

| Service | Login confirmé 2026-05-20 | Ne PAS utiliser |
|---------|----------------------------|-----------------|
| **MonIdenum / Infogreffe** | `florent.maisoncelle@gmail.com` (ID Infogreffe `230827628418`) | ~~florent.maisoncelle@prospectpartner.fr~~ (domaine NXDOMAIN) |
| **INPI** | `florent.maisoncelle@gmail.com` | — |
| **Impôts Pro** | À vérifier (probablement Gmail aussi vu domaine cassé) | ~~florent.maisoncelle@prospectpartner.fr~~ |
| **Qonto** | `florent.maisoncelle@gmail.com` | — |
| **Google Workspace admin** | `florent.maisoncelle@speakapp.work` (auth index /u/3/) | — |
| **Gmail perso** (Workspace alias 0) | `florent.maisoncelle@gmail.com` (auth index /u/0/) | — |

**Détail identité personnelle + tél + 2FA pour KYC** : Notion privé page EI Infos administratives + Codes 2FA dédiée (URLs ci-dessus).

**Tél pro/perso unique Florent** : `+33 6 48 28 48 94` — utilisable comme tél pro EI dans tous KYC + contrats.

## 🚨 Anti-yoyo 2026-05-20 — EI micro-entreprise = INSEE-SIRENE, PAS Infogreffe

Florent = **EI micro-entreprise classique** (pas EIRL, pas SASU, pas SARL). Les registres Infogreffe (RCS / RSAC / RSEIRL) ne le couvrent PAS.

**Si KYC ou service externe demande infos légales EI** :
- ❌ **NE PAS aller sur** `monidenum.fr` / Infogreffe → refusera "Votre identité n'a pu être rapprochée avec aucune personne figurant sur les registres légaux"
- ✅ **Aller sur INSEE-SIRENE** (public, sans login, gratuit) :
  - **Fiche entreprise complète** : https://annuaire-entreprises.data.gouv.fr/entreprise/941122897 (code APE/NAF, adresse fiscale, date création, statut, lien Avis SIRENE)
  - **Avis SIRENE PDF** : bouton "Télécharger avis SIRENE" sur la fiche ci-dessus (équivalent Kbis pour EI, accepté KYC EV cert Certum)
  - **Recherche INSEE-SIRENE direct** : https://avis-situation-sirene.insee.fr/ (form SIREN/SIRET, génère PDF avis sans login)

**Si KYC d'un service externe exige absolument "Kbis"** (alors que tu es EI) :
- Répondre "Je suis EI micro-entrepreneur, le Kbis n'existe pas pour ce statut. Document équivalent = avis SIRENE INSEE (téléchargeable sur annuaire-entreprises.data.gouv.fr)"
- Si KYC refuse l'avis SIRENE → bascule fournisseur (cas Certum EV qui accepte avis SIRENE = OK, vs SSL.com EV qui exige formulaire US-typé inadapté EI FR = exclu, cf DS-PROD-003 `memory/features/production-readiness.md`)

**IDs Notion (pour MCP `notion-fetch`/`notion-update-page`/`notion-create-comment`)** :
- Coordonnées & Accès : `521e6926-c821-48b9-ae39-4ba7b1fb5594`
- EI Infos administratives : `36501e69-443c-81bd-8e4f-f27ca04bd891`
- Comptes Pro : `34901e69-443c-817f-94b6-cf8904de32ec`
- Comptes Perso : `34901e69-443c-81fd-9e0b-debba3d8052b`
- Speak App : `36601e69-443c-8056-ad17-d62259c5f11d`

## 📋 Workflow obligatoire

### Quand le user me demande une info perso/pro

1. **Lire la page Notion appropriée** via `notion-fetch` (jamais deviner ni inventer)
2. **Si pas trouvé dans Notion** → demander à Florent, JAMAIS inventer une valeur
3. **Si l'info change** → MAJ Notion via `notion-update-page` + propager dans le miroir local du projet courant (`memory/coordonnees.md` si SpeakApp)
4. **NE JAMAIS** créer une 3e source — pas de doc séparé, pas de mémoire auto, pas de skill dupliqué

### Quand une nouvelle info admin émerge (SIRET, nouveau service, nouvelle adresse, nouveau compte)

1. **Ajouter dans Notion DIRECTEMENT** via `notion-update-page` sur la page appropriée
2. **Propager dans le miroir local** du projet concerné (si applicable) avec timestamp + lien Notion
3. **NE JAMAIS** stocker la nouvelle info uniquement en local — toujours Notion d'abord

### Quand le user dit "où c'est noté ?" / "j'ai oublié mon X"

1. **Ouvrir directement le lien Notion approprié dans Chrome** (via `Claude_in_Chrome` MCP `navigate`)
2. Pas de devinette, pas de bavardage

## 🚨 Sécurité

- **Mots de passe** : RESTENT dans Notion privé UNIQUEMENT. **JAMAIS commités dans un repo git public** (cf miroir local `memory/coordonnees.md` SpeakApp qui dit "AUCUN mot de passe ici").
- **Si user demande un mot de passe** → l'envoyer chercher dans Notion (lien direct), ne JAMAIS le lui dire dans le chat (logs persistants).

## 🔑 API keys & secrets — stockage Notion automatique (gravée 2026-05-20)

**Verbatim Florent 2026-05-20** : *« A chaque fois que je te donne des clefs API, s'il te plaît, tu les stockes dans les coordonnées aussi. Je pense que c'est une règle globale : tu les stockes dans les bons endroits dans Notion, évidemment, parce qu'on a des fichiers pour chaque grand projet dans l'espace coordonnées. Voilà, tout est toujours centralisé là : toutes les coordonnées, les mots de passe, les machins, les API. »*

**Règle absolue** : à chaque fois que Florent me donne une **clé API / token / secret / credential** dans le chat, je le stocke **IMMÉDIATEMENT et SANS DEMANDER** dans la page Notion appropriée (jamais en clair dans un repo Git, jamais uniquement dans `memory/`).

### Workflow obligatoire

1. **Détecter un secret** dans le message Florent :
   - Patterns : `ntn_*` (Notion), `sk-*` (OpenAI/Anthropic/Dust), `ghp_*` / `github_pat_*` (GitHub), `xoxb-*` / `xoxp-*` (Slack), `AIza*` (Google), `AKIA*` / `ASIA*` (AWS), `pk_live_*` / `sk_live_*` (Stripe), `apify_api_*`, `re_*` (Resend), `xai-*` (xAI)
   - Mots-clés : "token API", "clé API", "API key", "secret", "credential", "mot de passe", "MDP"
2. **Identifier la page Notion appropriée** :

   | Type de secret | Page Notion cible | ID |
   |----------------|-------------------|-----|
   | Token API service tiers (Cloudflare, Google Cloud, Notion API, Apify, OpenAI, Stripe...) | **APIs & Infrastructure** | `34901e69-443c-8102-b953-d3d2ffdecbe0` |
   | MDP compte pro (Qonto, Stripe dashboard, Vercel, AWS console...) | **Comptes Pro** | `34901e69-443c-817f-94b6-cf8904de32ec` |
   | MDP compte perso (Gmail, Proton, services consumer...) | **Comptes Perso** | `34901e69-443c-81fd-9e0b-debba3d8052b` |
   | Identifiants admin EI (Infogreffe, INPI, Impôts Pro...) | **🏢 EI Infos administratives** | `36501e69-443c-81bd-8e4f-f27ca04bd891` |
   | Credentials spécifiques SpeakApp produit (Supabase service role, OAuth client secrets app, etc.) | **Speak App** | `36601e69-443c-8056-ad17-d62259c5f11d` |
   | Code 2FA / TOTP backup codes | **🔐 Codes de secours 2FA** | `36601e69-443c-81cd-b334-fbcea437b7d1` |

3. **Stocker via `notion-update-page` `update_content`** :
   - Insérer une ligne dans la table "Tokens & Secrets" appropriée avec colonnes `(Service, Clé, Valeur)`
   - Mentionner la date d'ajout dans la cellule "Clé" : `API Token (ajouté YYYY-MM-DD)`
   - Si scope/usage est important, l'ajouter aussi : `API Token (ajouté 2026-05-20) — scope full workspace, MCP Claude`

4. **JAMAIS** :
   - Stocker la valeur du secret dans un repo Git (même privé — on peut perdre le contrôle d'accès)
   - Stocker dans `memory/` qui est commité dans le repo SpeakApp public
   - Citer la valeur du secret dans le chat persistant (logs Claude conservés)
   - Demander à Florent où le mettre — si la table de routing ci-dessus matche, AGIR ; sinon prendre la décision la plus safe (APIs & Infrastructure par défaut pour tokens, et reporter une ligne brève au user)

5. **Si miroir local existe** pour le projet (ex `memory/coordonnees.md` SpeakApp) → mentionner uniquement *"Token `<service>` stocké dans Notion APIs & Infrastructure (ajouté YYYY-MM-DD)"* SANS la valeur. Lien de la page Notion en référence.

### Confirmation après stockage

Une fois le secret stocké dans Notion, confirmer à Florent en 1 ligne :
> *"Token `<service>` stocké dans Notion **APIs & Infrastructure** (ligne ajoutée 2026-05-20). Pas committé en clair côté repo."*

Pas plus, pas d'output verbeux, pas de répétition de la valeur.

### Triggers automatiques (s'ajoutent à ceux ci-dessus)

- "token API", "clé API", "API key", "API token"
- "secret", "credential", "auth token", "bearer token"
- Détection pattern : `ntn_`, `sk-`, `sk_live_`, `pk_live_`, `ghp_`, `github_pat_`, `xoxb-`, `xoxp-`, `AIza`, `AKIA`, `ASIA`, `apify_api_`, `re_`, `xai-`

## Miroirs locaux par projet

| Projet | Miroir local | Mise à jour |
|--------|--------------|-------------|
| SpeakApp (3- Wisper/speak-app-dev) | `memory/coordonnees.md` | À chaque commit qui touche admin/cert/contrat |
| Marketplace (0- Marketplace) | non créé encore | à créer si admin/contrat touchés |
| Vente et Marketing | non créé encore | idem |
| LinkedIn Content Agent | non créé encore | idem |

**Règle miroir local** : header obligatoire :
```markdown
> ⚠️ SOURCE CANONIQUE = Notion https://www.notion.so/521e6926c82148b9ae394ba7b1fb5594
> Ce fichier = miroir local mémoire courte Claude. **NE JAMAIS éditer ici sans propager dans Notion même commit.**
> AUCUN mot de passe dans ce fichier (git public).
```

## Anti-patterns interdits

- ❌ Inventer un SIRET / numéro / email / adresse → toujours fetch Notion d'abord
- ❌ Créer une nouvelle source ailleurs (skill dupliqué, doc séparé, mémoire auto) → tout passe par Notion
- ❌ Stocker un mot de passe dans un fichier git public → Notion privé uniquement
- ❌ Donner un mot de passe dans le chat → envoyer chercher dans Notion
- ❌ Demander à Florent une info qui est dans Notion (lui fait répéter) → fetch d'abord

## Trigger d'invocation

À invoquer automatiquement (sans demander) dès qu'un de ces mots apparaît dans le message Florent :
- coordonnées, accès, identifiants
- email pro, email perso, mes emails, mes comptes
- SIRET, SIREN, code APE, NAF, EI, micro-entreprise, PROSPECTPARTNER, auto-entrepreneur
- Infogreffe, monidenum, MonIdenum, Kbis, avis SIRENE, INSEE
- domaine speakapp.work, speakapp, mon domaine pro
- compte Google, Gmail perso, Gmail pro, Google Workspace, admin.google.com
- compte Notion, accès Notion, login Notion
- Stripe, Qonto, banque pro, RIB, IBAN
- adresse pro, adresse fiscale, mon adresse
- téléphone pro, mon tel, ma ligne
- "où c'est noté", "j'ai oublié", "j'ai plus en tête", "où sont mes"

## Verbatim Florent 2026-05-20 (gravage source)

> *« Ouais, redis-moi le nom du skill qui gère ou qui connaît ces pages-là. Parce que potentiellement il faut te le mettre en global, c'est ça, en global aussi. Avec toutes les coordonnées-là, mais juste les fichiers, juste les références des fichiers. Ça sert à rien de faire des grosses règles. Tu mets juste les références des fichiers. Si tu cherches des informations personnelles, des coordonnées, des adresses e-mails, tu cherches là. Et toutes mes coordonnées et toutes les informations, elles sont là. (...) Tu cherches toujours ici si tu cherches des trucs persos, des coordonnées, des trucs comme ça. C'est clair, et tu tiens toujours ce truc parfaitement à jour, qu'il soit propre et clair et qu'on arrête de bégayer. »*
