---
name: impots-fr
description: Aide Florent à préparer ses déclarations fiscales françaises (IR personnel, IS SASU, CFE, TVA). Agrège les revenus depuis Gmail (Shine exports comptables, Stripe, salaires, aide parentale), distingue les flux entreprise vs revenu personnel, et produit un récap chiffré prêt à reporter sur impots.gouv.fr. Triggers : "/impots", "/declaration", "déclaration revenus", "déclarer mes impôts", "IR 2025", "IS PROSPECTPARTNER", "préparer ma déclaration".
---

# Impôts FR — Préparation de déclaration

Skill pour préparer les déclarations fiscales françaises de Florent (IR perso, IS SASU PROSPECTPARTNER, CFE, TVA).

## Contexte structurel (à toujours appliquer)

Florent a **deux entités** distinctes — ne JAMAIS les mélanger :

| Entité | Identifiant | Impôt principal | Compte bancaire |
|---|---|---|---|
| **SASU PROSPECTPARTNER** | SIREN 951 070 309 | IS (société) | (à vérifier) |
| **EI Florent DE MAISONCELLE** | (perso) | IR — BIC/BNC selon activité | Shine "DE MAISONCELLE FLORENT" |
| **IR personnel Florent** | (foyer fiscal) | IR | — |

→ Le CA d'une entité **n'est pas** le revenu personnel à l'IR. Pour la SASU, seuls salaire + dividendes + boni de liquidation passent à l'IR perso. Pour l'EI, le CA passe en BIC/BNC sur l'IR avec abattement (à confirmer selon régime micro ou réel).

Lire aussi les mémoires `structure_pro.md`, `sasu_prospectpartner.md`, `shine_ei.md`, `aide_parentale_ir.md`.

## Étape 1 — Cadrer la demande

Avant toute recherche, demander à Florent (ou inférer du contexte) :
1. **Quelle année fiscale ?** (ex : revenus 2025 → IR campagne 2026)
2. **Quelle(s) déclaration(s) ?**
   - IR perso (formulaire 2042 + annexes)
   - IS SASU (formulaire 2065 + liasse, ou IS à 0 si inactive)
   - CFE (avis automatique en novembre)
   - TVA (CA12 annuelle ou CA3 mensuelle selon régime)
3. **Quel régime fiscal** pour l'EI ? (micro-BIC, micro-BNC, réel — change l'abattement)

## Étape 2 — Collecter les revenus depuis Gmail

Pour chaque source ci-dessous, lancer une recherche Gmail ciblée et compiler les montants.

### 2.1 EI — Compte Shine "DE MAISONCELLE FLORENT"

```
from:hello@shine.fr "export comptable" after:YYYY/01/01 before:(YYYY+1)/02/15
```

Récupérer les exports mensuels et/ou trimestriels.
**Si trous** (ex : Q3/Q4 manquants) → demander à Florent de télécharger depuis l'app Shine : *Comptabilité > Exports > Période > Télécharger CSV*.

Le CSV donne ligne-à-ligne crédits/débits. Sommer les crédits = CA brut. **Exclure** : virements internes, remboursements client, apports perso.

### 2.2 Stripe — paiements directs

```
from:notifications@stripe.com (virement OR payout) after:YYYY/01/01 before:(YYYY+1)/01/01
```

Pour chaque mail "Votre virement de X € est en cours" → noter montant et libellé.

### 2.3 Factures émises (vue client)

```
from:facture@shine.fr after:YYYY/01/01 before:(YYYY+1)/01/01
```

Liste des factures envoyées via Shine — utile pour repérer les impayés (mais ne pas double-compter, ce qui est payé est déjà dans 2.1).

### 2.4 Salaire SASU (si rémunération président)

```
(bulletin OR fiche OR paie OR salaire OR DSN) after:YYYY/01/01 before:(YYYY+1)/02/15
```

Si Florent s'est versé un salaire de la SASU, chercher les bulletins. **À l'IR** : montant net imposable.

### 2.5 Dividendes / boni de liquidation SASU

```
(dividende OR "boni de liquidation" OR distribution) after:YYYY/01/01 before:(YYYY+1)/05/31
```

→ Imposition au PFU (flat tax 30%) par défaut, ou option barème.

### 2.6 Aide parentale (pension alimentaire reçue)

Voir `aide_parentale_ir.md` :
- Papa : 4 808 €/an (confirmer chaque année par mail `from:jcmaisoncelle@gmail.com IR`)
- Maman : équivalent — **confirmer avec Florent** chaque année, pas garanti

```
from:jcmaisoncelle@gmail.com (IR OR déclaration OR revenus) after:YYYY/03/01 before:(YYYY+1)/06/30
```

### 2.7 Autres revenus à ne pas oublier

- Allocations chômage / France Travail (attestation annuelle)
- Revenus fonciers (loyers perçus)
- Intérêts livrets, dividendes actions hors SASU, crypto (PVMV)
- Crédits d'impôt (dons, services à la personne, etc.)

## Étape 3 — Mapping vers les cases impots.gouv.fr

Une fois les chiffres collectés, produire un tableau :

```
| Source                     | Montant € | Case 2042         | Vérifié ? |
|----------------------------|-----------|-------------------|-----------|
| Salaire SASU (net imp.)    | XXXX      | 1AJ               | ☐         |
| EI micro-BIC (CA brut)     | XXXX      | 5KO               | ☐         |
| EI micro-BNC (CA brut)     | XXXX      | 5HQ               | ☐         |
| Dividendes SASU (brut)     | XXXX      | 2DC               | ☐         |
| Aide parentale reçue       | 9 616     | 1AO (pensions)    | ☐         |
| Allocations chômage        | XXXX      | 1AP               | ☐         |
```

⚠️ Toujours préciser que les numéros de cases doivent être confirmés sur impots.gouv.fr (ils peuvent évoluer d'une année à l'autre).

## Étape 4 — IS SASU PROSPECTPARTNER

Cas particulier : **si la SASU est inactive / en cours de liquidation** (cf `sasu_prospectpartner.md`) :
- **IS à 0** à déclarer via espace pro impots.gouv.fr → formulaire 2065 simplifié
- Deadline : **20 mai** de l'année N+1 pour l'exercice N
- Joindre liasse 2050-2059 même à 0
- Toujours vérifier dans Gmail : `from:noreply@inpi.fr` + `from:dgfip` pour l'état réel du dossier

## Étape 5 — Produire le livrable

À la fin du process, output un message structuré :

```
## IR 20XX — Récap

### À reporter sur 2042
- Salaires (1AJ) : XXX €
- Pensions reçues (1AO) : 9 616 €
- ...

### À reporter sur 2042-C-PRO
- EI micro-BIC (5KO) : XXX €
- ...

### Manquant — à fournir/télécharger
- ☐ Q3 2025 Shine (app > Comptabilité > Exports)
- ☐ Confirmation montant maman 20XX
- ☐ ...

### Échéances proches
- ☐ IR 20XX : date limite en ligne (variable selon zone)
- ☐ IS PROSPECTPARTNER : 20 mai 20XX
- ☐ CFE : avis novembre
```

## Garde-fous

1. **Ne JAMAIS valider/soumettre à la place de Florent** — toujours produire le récap et le laisser le saisir lui-même sur impots.gouv.fr.
2. **Distinguer entité** à chaque chiffre. Si doute SASU vs EI → demander.
3. **Pas de conseil d'optimisation fiscale agressif** — rester sur le déclaratif. Pour optimisation, renvoyer vers expert-comptable (le papa, Jean-Claude, joue ce rôle).
4. **Cases de déclaration** : toujours préciser "à vérifier sur impots.gouv.fr" car peuvent changer.
5. **Si écart entre mail papa et autre source** → flagger, ne pas trancher seul.

## Cas d'usage — exemples de prompts qui doivent déclencher ce skill

- "Je dois faire ma déclaration de revenus"
- "/impots 2025"
- "Combien j'ai gagné en 2025 sur mon Shine ?"
- "Faut que je déclare l'IS de PROSPECTPARTNER"
- "Tu peux me sortir mes revenus pour la déclaration"
