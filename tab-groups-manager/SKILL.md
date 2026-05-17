---
name: tab-groups-manager
description: Exporte les groupes d'onglets Chrome vers Edge (ou tout Chromium). Lit le LevelDB de sync Chrome, reconstruit la structure groupes+URLs, crée les vrais groupes nommés dans Edge via CDP + extension MV3. Commande courte : /tab-groups-manager
---

# /tab-groups-manager — Chrome → Edge Tab Groups

## TL;DR

**Méthode qui marche (validée 2026-04-23) :**
1. Lire le LevelDB Chrome Sync → extraire groupes + onglets
2. Lancer Edge avec `--remote-debugging-port=9223 --load-extension` (extension mini MV3)
3. Naviguer vers la page options de l'extension via CDP
4. Appeler `createAllGroups()` depuis la page options → groupes créés avec noms + couleurs

## Quand invoquer

- "transfère mes onglets Chrome vers Edge"
- "duplique mes groupes d'onglets"
- "ouvre mes groupes dans Edge"
- "exporte les groupes Chrome"

## Fichiers persistants

| Fichier | Rôle |
|---------|------|
| `%TEMP%\chrome_groups_final.json` | Données groupes extraites (source de vérité) |
| `%TEMP%\chrome-to-edge-launcher.html` | Launcher HTML de secours |
| `%TEMP%\tab-group-ext\` | Extension MV3 Edge (réutilisable) |

## Architecture technique validée

### Problème clé : chrome.tabGroups non disponible dans MV2 Edge

En Edge 140, `chrome.tabGroups` est `undefined` dans les background pages MV2.
**Solution** : MV3 + page options → `chrome.tabGroups` est disponible dans les pages d'extension.

### Flux complet

```
Chrome LevelDB → JSON groups → Edge CDP + extension → chrome.tabGroups.create()
```

## Phase 1 — Extraction des groupes (LevelDB Chrome Sync)

Le Chrome Sync LevelDB est dans :
`C:\Users\<USER>\AppData\Local\Google\Chrome\User Data\Default\Sync Data\LevelDB\`

Les fichiers `.ldb` contiennent des entrées `saved_tab_group-dt-<uuid>` avec :
- Si la valeur contient un nom court lisible → c'est une **définition de groupe** (clé = GROUP_UUID)
- Si la valeur contient `$<group_uuid>` + URL + titre → c'est un **onglet** appartenant au groupe

```powershell
# Extraction rapide — coller dans PowerShell
$ldbPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Sync Data\LevelDB"
$allText = ""
foreach ($f in Get-ChildItem $ldbPath -Filter "*.ldb") {
    $fs = [System.IO.File]::Open($f.FullName, 'Open', 'Read', 'ReadWrite')
    $b = New-Object byte[] $fs.Length; $fs.Read($b,0,$b.Length)|Out-Null; $fs.Close()
    $allText += [Text.Encoding]::GetEncoding('iso-8859-1').GetString($b)
}
# Pattern: $<GROUP_UUID>[bytes]<URL>"<TITLE>
$pat = '\$([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})[^\$]{0,50}(https?://[^\x00-\x1F\x7F"<>\s\\]{8,})"([^"\x00-\x1F]{3,80})'
[regex]::Matches($allText, $pat) | ForEach-Object {
    [PSCustomObject]@{ GroupId=$_.Groups[1].Value; Url=$_.Groups[2].Value; Title=$_.Groups[3].Value }
} | Group-Object GroupId
```

### Limitation SNSS (fichiers session actifs)

Les groupes OUVERTS mais non-sauvegardés sont dans les fichiers SNSS Session de Chrome **verrouillés** pendant que Chrome tourne.
- **Option recommandée** : Sauvegarder les groupes dans Chrome (clic sur l'icône groupe → "Sauvegarder") → ils apparaissent dans LevelDB

## Phase 2 — Extension MV3 Edge (Tab Group Creator)

### Créer les fichiers de l'extension

```powershell
$extPath = "$env:TEMP\tab-group-ext"
New-Item -ItemType Directory $extPath -Force | Out-Null
```

**`manifest.json`** :
```json
{
  "manifest_version": 3,
  "name": "Tab Group Creator",
  "version": "1.0",
  "description": "Creates tab groups programmatically via CDP",
  "permissions": ["tabs", "tabGroups"],
  "options_page": "options.html",
  "background": { "service_worker": "background.js" },
  "action": {}
}
```

**`options.html`** :
```html
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Tab Group Creator</title></head>
<body><div id="status">Ready</div><script src="options.js"></script></body></html>
```

**`options.js`** (page avec accès complet à chrome.tabGroups) :
```javascript
window.createTabGroup = async function(urls, groupName, color) {
  const tabIds = [];
  for (const url of urls) {
    const tab = await chrome.tabs.create({ url: url, active: false });
    tabIds.push(tab.id);
  }
  const groupId = await chrome.tabs.group({ tabIds: tabIds });
  if (chrome.tabGroups) {
    await chrome.tabGroups.update(groupId, { title: groupName, color: color || 'cyan' });
  }
  return { groupId: groupId, tabIds: tabIds, groupName: groupName };
};

window.createAllGroups = async function(groups) {
  const results = [];
  for (const g of groups) {
    try {
      const r = await window.createTabGroup(g.tabs.map(function(t) { return t.url; }), g.name, g.edgeColor || 'cyan');
      results.push({ name: g.name, ok: true, groupId: r.groupId, count: r.tabIds.length });
    } catch(e) {
      results.push({ name: g.name, ok: false, error: e.message });
    }
  }
  return results;
};
```

**`background.js`** (service worker, juste pour keepalive) :
```javascript
console.log('[Tab Group Creator] Service worker ready');
```

## Phase 3 — Lancer Edge CDP + créer les groupes

```powershell
# 1. Lancer Edge avec l'extension
$extPath = "$env:TEMP\tab-group-ext"
$profilePath = "$env:TEMP\edge-fresh-profile"
New-Item -ItemType Directory $profilePath -Force | Out-Null

Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" `
    "--remote-debugging-port=9223 --user-data-dir=`"$profilePath`" --load-extension=`"$extPath`" --no-first-run --disable-sync about:blank"
Start-Sleep -Seconds 5

# 2. Trouver l'extension ID + naviguer vers la page options
$targets = Invoke-RestMethod "http://localhost:9223/json"
$pageTarget = $targets | Where-Object { $_.type -eq "page" } | Select-Object -First 1
# La page options de l'extension (l'ID est deterministe basé sur le path de l'extension)
# Pour connaître l'ID : chercher dans les targets le service_worker de l'extension

# 3. Naviguer vers la page options
# [Utiliser CDP pour naviguer le about:blank vers chrome-extension://<ID>/options.html]
# puis connecter en WebSocket CDP à cette page et appeler window.createAllGroups(groups)
```

### Script PowerShell complet (CDP WebSocket)

```powershell
# Compiler le client WebSocket C#
$code = @"
using System; using System.Net.WebSockets; using System.Text; using System.Threading;
public class EdgeCdp {
    private ClientWebSocket _ws = new ClientWebSocket();
    public bool Connect(string wsUrl, out string err) {
        err = "";
        try { _ws.ConnectAsync(new Uri(wsUrl), CancellationToken.None).Wait(8000); return _ws.State == WebSocketState.Open; }
        catch (AggregateException ae) { err = ae.InnerException != null ? ae.InnerException.Message : ae.Message; return false; }
    }
    public string Send(string msg) {
        var bytes = Encoding.UTF8.GetBytes(msg);
        _ws.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None).Wait(5000);
        var buf = new byte[1048576]; var sb = new System.Text.StringBuilder(); WebSocketReceiveResult r;
        do { var cts = new CancellationTokenSource(120000); r = _ws.ReceiveAsync(new ArraySegment<byte>(buf), cts.Token).GetAwaiter().GetResult(); sb.Append(Encoding.UTF8.GetString(buf, 0, r.Count)); } while (!r.EndOfMessage);
        return sb.ToString();
    }
}
"@
Add-Type -TypeDefinition $code

# Naviguer la page about:blank vers la page options de l'extension
$targets = Invoke-RestMethod "http://localhost:9223/json"
$pageWs = ($targets | Where-Object { $_.type -eq "page" } | Select-Object -First 1).webSocketDebuggerUrl
$cdp = New-Object EdgeCdp; $err = ""; $cdp.Connect($pageWs, [ref]$err) | Out-Null
$extId = "ojneegljainpehijglgglcpjjapabcjo"  # ATTENTION: cet ID dépend du path de l'extension
$cdp.Send("{`"id`":1,`"method`":`"Page.navigate`",`"params`":{`"url`":`"chrome-extension://$extId/options.html`"}}") | Out-Null
Start-Sleep -Seconds 2

# Connecter à la page options
$targets2 = Invoke-RestMethod "http://localhost:9223/json"
$optWs = ($targets2 | Where-Object { $_.url -like "*$extId*" }).webSocketDebuggerUrl
$cdp2 = New-Object EdgeCdp; $err2 = ""; $cdp2.Connect($optWs, [ref]$err2) | Out-Null

# Appeler createAllGroups avec les données JSON
$script = @'
(async function() {
  const groups = [/* ... vos groupes ici ... */];
  return JSON.stringify(await window.createAllGroups(groups));
})()
'@
$result = $cdp2.Send((@{id=2;method="Runtime.evaluate";params=@{expression=$script;returnByValue=$true;awaitPromise=$true}} | ConvertTo-Json -Compress -Depth 10))
Write-Host $result
```

## Couleurs Edge disponibles

| Valeur | Couleur |
|--------|---------|
| `yellow` | Jaune |
| `purple` | Violet |
| `green` | Vert |
| `red` | Rouge |
| `orange` | Orange |
| `blue` | Bleu |
| `cyan` | Cyan |
| `pink` | Rose |
| `grey` | Gris |

## Notes techniques

- **`chrome.tabGroups` dans MV2** : Non disponible dans Edge 140 (undefined). Bug connu.
- **`chrome.tabGroups` dans options page MV3** : ✅ Fonctionne parfaitement.
- **Extension ID** : Basé sur le hash du path absolu de l'extension. Constant pour `%TEMP%\tab-group-ext` = `ojneegljainpehijglgglcpjjapabcjo`
- **LevelDB accessible** même si Chrome est ouvert (FileShare.ReadWrite)
- **SNSS Session** verrouillé exclusivement par Chrome → nécessite sauvegarde groupe ou fermeture Chrome
- **Profil Edge temporaire** : Les onglets ouverts dans le profil debug nécessitent un re-login

## Phase 1bis — Extraction des groupes NON-SAUVEGARDÉS (SNSS Session)

**Validée 2026-04-23** — Les groupes non-sauvegardés sont dans le fichier **Current Session** (lisible avec `FileShare.ReadWrite`) même si le fichier `Tabs_*` est verrouillé exclusivement par Chrome.

> **Note Chrome moderne** : Dans Chrome 120+, il n'y a pas de fichier `Default\Current Session` au niveau du profil. Le fichier "Current Session" correspond au `Session_*` le plus récent dans `Default\Sessions\`. Le fichier `Tabs_*` (le plus récent) est exclusivement verrouillé — ne pas l'utiliser.

### Format SNSS (Chrome 135+)

Les commandes sont : **2 bytes size** (inclut le type byte) + **1 byte type** + **data**.

| Type | Rôle |
|------|------|
| **27** | Groupe metadata (nom UTF-16 LE + UUID binaire 16 bytes + couleur) |
| **25** | Assignation tab→groupe (tab token 8 bytes + groupe UUID binaire 16 bytes) |
| **6** | État complet d'un onglet (URL courante à offset data+12 = longueur, +16 = URL UTF-8) |

### Script PowerShell complet — extraction SNSS

```powershell
$sessDir = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Sessions"
# "Current Session" = le Session_* le plus récent et non vide (readable avec FileShare.ReadWrite)
# NE PAS utiliser Tabs_* : verrouillé exclusivement par Chrome
$sessFile = Get-ChildItem $sessDir -Filter "Session_*" | Where-Object { $_.Length -gt 1000 } | Sort-Object LastWriteTime -Descending | Select-Object -First 1

$fs = [System.IO.File]::Open($sessFile.FullName, 'Open', 'Read', 'ReadWrite')
$bytes = New-Object byte[] $fs.Length
$fs.Read($bytes, 0, $bytes.Length) | Out-Null
$fs.Close()

# Parser les commandes SNSS
$pos = 8; $allCmds = @()
while ($pos + 3 -le $bytes.Length) {
    $size = [BitConverter]::ToUInt16($bytes, $pos)
    $type = $bytes[$pos + 2]
    if ($size -eq 0 -or ($pos + 2 + $size) -gt $bytes.Length) { $pos++; continue }
    $dataLen = $size - 1
    $dataBytes = if ($dataLen -gt 0) { $bytes[($pos+3)..($pos+1+$size)] } else { @() }
    $allCmds += [PSCustomObject]@{ Pos=$pos; Type=$type; Size=$size; DataLen=$dataLen; Data=$dataBytes }
    $pos += 2 + $size
}

# Type 27 → groupes (UUID binaire bytes 4-19, nom UTF-16 longueur à byte 20, couleur après nom)
$groupMap = @{}
$allCmds | Where-Object { $_.Type -eq 27 } | ForEach-Object {
    $d = $_.Data
    if ($d.Length -lt 24) { return }
    $key = ($d[4..19] | ForEach-Object { $_.ToString("X2") }) -join ""
    $nameLen = [BitConverter]::ToUInt32($d, 20) * 2
    if ($nameLen -gt 0 -and 24 + $nameLen -le $d.Length) {
        $name = [Text.Encoding]::Unicode.GetString($d, 24, $nameLen)
        if (-not $groupMap.ContainsKey($key)) { $groupMap[$key] = $name }
    }
}

# Type 25 → tab token (bytes 0-3) → groupe UUID (bytes 8-23)
$tabToGroup = @{}
$allCmds | Where-Object { $_.Type -eq 25 -and $_.DataLen -ge 24 } | ForEach-Object {
    $d = $_.Data
    $tabToken = ($d[0..3] | ForEach-Object { $_.ToString("X2") }) -join ""
    $groupKey = ($d[8..23] | ForEach-Object { $_.ToString("X2") }) -join ""
    if ($groupMap.ContainsKey($groupKey)) { $tabToGroup[$tabToken] = $groupMap[$groupKey] }
}

# Type 6 → URL courante (token bytes 4-7, longueur URL bytes 12-15, URL bytes 16+)
$tabToUrl = @{}
$allCmds | Where-Object { $_.Type -eq 6 -and $_.DataLen -ge 20 } | ForEach-Object {
    $d = $_.Data
    if ($d.Length -lt 16) { return }
    $tabToken = ($d[4..7] | ForEach-Object { $_.ToString("X2") }) -join ""
    $urlLen = [BitConverter]::ToUInt32($d, 12)
    if ($urlLen -gt 0 -and $urlLen -lt 4096 -and 16 + $urlLen -le $d.Length) {
        $url = [Text.Encoding]::UTF8.GetString($d, 16, $urlLen)
        if ($url -match '^https?://') { $tabToUrl[$tabToken] = $url }
    }
}

# Résultat : groupes → URLs
$groupUrls = @{}
$tabToGroup.GetEnumerator() | ForEach-Object {
    $url = $tabToUrl[$_.Key]
    if ($url -and $url -notmatch 'chrome://') {
        if (-not $groupUrls.ContainsKey($_.Value)) { $groupUrls[$_.Value] = @() }
        $groupUrls[$_.Value] += $url
    }
}
$groupUrls.GetEnumerator() | ForEach-Object {
    "$($_.Key): $($_.Value.Count) tabs"
    $_.Value | Sort-Object -Unique | ForEach-Object { "  $_" }
}
```

### Couleur SNSS → Edge

| Valeur SNSS | Couleur Chrome | Edge color |
|-------------|---------------|------------|
| 0 | yellow | `yellow` |
| 1 | blue | `blue` |
| 2 | red | `red` |
| 3 | green | `green` |
| 4 | cyan | `cyan` |
| 5 | orange | `orange` |

### Limitation SNSS (groupes non-sauvegardés)

Le fichier `Tabs_*` est verrouillé exclusivement par Chrome → inaccessible.
Le fichier `Session_*` (snapshot) est lisible avec `FileShare.ReadWrite` et contient toutes les données de groupe.
→ Aucune action de l'utilisateur nécessaire si Chrome est en cours d'exécution.

## Groupes connus (carte statique)

Mis à jour à chaque exécution. Dernière extraction + création Edge : 2026-04-23.

| Groupe Chrome | Couleur Edge | Onglets |
|--------------|-------------|---------|
| Claude Design | yellow | Claude design, Vercel previews, Canva designs (6) |
| Canva - Bannière LinkedIn | purple | 11 designs Canva (Facebook covers + bannières) |
| Claude FORMATION | green | Notion formation, LinkedIn, Skool (6) |
| WebSite Antigravity AI | red | localhost, Vercel live, Cal.com, SpeakApp (6) |
| SALES AGENT | orange | Gmail, Malt messages (2) |
| Prosp / LinkedIn | blue | Jack Roberts, Lemlist, Taplio (4) |
| LK | blue | LinkedIn feed, profil, Notion posts/stratégie, Skool, GitHub (13) |
| YT | yellow | YouTube channel setup Notion, hub YT, NotebookLM, dashboards (4) |
| Projects | green | TO-DO Notion, Pipeline Vente, projets Notion, Chrome Web Store (4) |
| SW | red | YouTube playlists Star Wars, Brain.fm, Notion page (7) |

## Conseil pour le workflow quotidien

**Avant de fermer Chrome** : Sauvegarder tous les groupes ouverts (clic sur chaque nom de groupe → "Sauvegarder le groupe"). Ils seront alors dans le LevelDB et ce skill pourra les lire directement à la prochaine session.
