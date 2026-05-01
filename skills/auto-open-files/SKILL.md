# Auto-Open Files

Ouvre automatiquement tout fichier ou page genere pour que l'utilisateur puisse le voir. Claude Code n'a pas de preview integree — il faut TOUJOURS ouvrir dans le navigateur ou l'app appropriee.

## Regle absolue

**Des qu'un fichier est cree ou modifie et que l'utilisateur doit le VOIR, l'ouvrir immediatement. Ne JAMAIS attendre qu'il le demande.**

## Quoi ouvrir et comment

| Type de fichier | Comment ouvrir |
|-----------------|----------------|
| HTML / preview web | Servir via `python -m http.server` (port libre) + ouvrir dans Chrome via MCP `navigate` |
| PDF | `start "" "chemin/fichier.pdf"` (Windows ouvre avec le viewer par defaut) |
| Image (PNG, JPG, SVG) | `start "" "chemin/fichier.png"` |
| Markdown (.md) | Si preview necessaire → convertir en HTML + ouvrir dans navigateur |
| Excel / CSV | `start "" "chemin/fichier.xlsx"` |
| Word / DOCX | `start "" "chemin/fichier.docx"` |
| PowerPoint | `start "" "chemin/fichier.pptx"` |
| JSON (dashboard, data viz) | Creer un HTML viewer + ouvrir dans navigateur |
| Localhost (dev server deja up) | Naviguer directement via MCP Chrome `navigate` |

## Methode navigateur (MCP Chrome)

1. `tabs_context_mcp` — recuperer les onglets existants
2. Soit reutiliser un onglet localhost existant, soit `tabs_create_mcp` pour en creer un
3. `navigate` vers l'URL du fichier

## Methode fichier local (Windows)

```bash
start "" "C:/chemin/vers/fichier.ext"
```

Cela ouvre avec l'application par defaut de Windows.

## Serveur statique rapide

Si le fichier est un HTML et qu'aucun serveur ne tourne :

```bash
# Verifier si le port est libre
netstat -ano | findstr :8888
# Lancer le serveur
cd "dossier/parent" && python -m http.server 8888
# Puis naviguer via Chrome MCP
```

## Regles

- **PROACTIF** : ouvrir AVANT de dire a l'utilisateur "c'est pret"
- **Pas de question** : ne pas demander "tu veux que je l'ouvre ?" — juste l'ouvrir
- **Intelligent** : si un serveur tourne deja sur le bon port, reutiliser
- **Feedback** : prendre un screenshot apres ouverture pour confirmer que ca s'affiche bien
