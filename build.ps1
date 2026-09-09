# =============================================================================
#  PowerCorp website build
#  -----------------------------------------------------------------------------
#  Reads   content/*.md   (your words)
#  Fills   templates/*    (the layout)
#  Writes  index.html + press/index.html   (what actually ships)
#
#  Run it by double-clicking build.bat, or:  powershell -File build.ps1
#
#  Everything authored in content/ is HTML-escaped before it reaches a template,
#  so no amount of punctuation, brackets or stray markup in your copy can break
#  the page. That is the whole point of the split.
# =============================================================================

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$warnings = @()

function Read-TextFile([string]$path) {
  if (-not (Test-Path $path)) { throw "Missing file: $path" }
  return [System.IO.File]::ReadAllText($path)
}

function Write-TextFile([string]$path, [string]$text) {
  $enc = New-Object System.Text.UTF8Encoding($false)   # UTF-8, no BOM
  [System.IO.File]::WriteAllText($path, $text, $enc)
}

# --- Inline formatting ------------------------------------------------------
# Escape FIRST, then apply markdown. Order matters: it is what stops authored
# text from injecting markup.
function Convert-Inline([string]$s) {
  if ($null -eq $s) { return '' }
  # The double quote matters as much as the angle brackets: several fields land
  # inside HTML attributes (img alt, meta content), where a bare " would escape
  # the attribute. &quot; still renders as a normal " in visible text.
  $s = $s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;'
  $s = $s -replace '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2" target="_blank" rel="noopener">$1</a>'
  $s = $s -replace '\*\*([^*]+)\*\*', '<strong>$1</strong>'
  $s = $s -replace '(?<!\*)\*([^*]+)\*(?!\*)', '<em>$1</em>'
  # A bare URL typed in the copy becomes a link. The lookbehind keeps it from
  # matching inside an href="..." or the text of a link made just above.
  $s = $s -replace '(?<![">])(https?://[^\s<]+[^\s<.,;:!?)])', '<a href="$1" target="_blank" rel="noopener">$1</a>'
  return $s
}

# A heading may use | to force a line break.
function Convert-Heading([string]$s) {
  return (Convert-Inline $s) -replace '\s*\|\s*', '<br>'
}

# Escape only - for verbatim readouts inside terminal blocks.
function Convert-Verbatim([string]$s) {
  if ($null -eq $s) { return '' }
  return $s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;'
}

# Is this line a bullet? Accepts "- " and "* ", but never a whole line that is
# just *italics*, which would otherwise look like a bullet.
function Test-Bullet([string]$t) {
  if ($t.StartsWith('- ')) { return $true }
  if ($t.StartsWith('* ') -and $t -notmatch '^\*[^*]+\*$') { return $true }
  return $false
}

# Body text: blank-line-separated paragraphs, plus bullet runs turned into a
# list wherever they appear, so a section can mix prose and bullets in order.
function Convert-Body([string]$s, [string]$indent = '            ') {
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  $lines = [regex]::Split($s.Trim(), '\r?\n')
  $out  = New-Object System.Collections.ArrayList
  $para = New-Object System.Collections.ArrayList
  $bul  = New-Object System.Collections.ArrayList

  function Add-Para {
    if ($para.Count) {
      [void]$out.Add("$indent<p>" + (Convert-Inline (($para -join ' ').Trim())) + '</p>')
      $para.Clear()
    }
  }
  function Add-List {
    if ($bul.Count) {
      $li = @()
      foreach ($b in $bul) { $li += ("$indent  <li>" + (Convert-Inline $b) + '</li>') }
      [void]$out.Add("$indent<ul class=""bullets"">`n" + ($li -join "`n") + "`n$indent</ul>")
      $bul.Clear()
    }
  }

  foreach ($ln in $lines) {
    $t = $ln.Trim()
    if (Test-Bullet $t) { Add-Para; [void]$bul.Add($t.Substring(2).Trim()); continue }
    if ($t -eq '')      { Add-Para; Add-List; continue }
    Add-List
    [void]$para.Add($t)
  }
  Add-Para; Add-List
  return ($out -join "`n")
}

function ConvertTo-JsonArray([string[]]$items) {
  $parts = @()
  foreach ($i in $items) {
    $e = $i -replace '\\', '\\' -replace '"', '\"'
    $parts += '"' + $e + '"'
  }
  return '[' + ($parts -join ',') + ']'
}

# --- Content parsing --------------------------------------------------------
# Returns @{ fields = @{}; intro = ''; blocks = @( @{ title; fields; body; fence; list; subs } ) }
# $Sections, when given, names the ONLY "## " headings that start a new section.
# Any other "## " is then treated as a sub-heading inside the current one, which
# is what lets the press page carry free-form copy with its own headings.
function Read-Content([string]$name, [string[]]$Sections = @()) {
  $text  = Read-TextFile (Join-Path $root "content\$name")
  $lines = [regex]::Split($text, '\r?\n')

  $fields = @{}
  $blocks = New-Object System.Collections.ArrayList
  $intro  = New-Object System.Collections.ArrayList

  $inFront = $false; $frontDone = $false
  $cur = $null; $sub = $null
  $inFence = $false; $fence = New-Object System.Collections.ArrayList
  $inHeader = $false

  foreach ($line in $lines) {
    $t = $line.Trim()

    # front matter fences
    if (-not $frontDone -and $t -eq '---') {
      if (-not $inFront) { $inFront = $true; continue }
      $inFront = $false; $frontDone = $true; continue
    }
    if ($inFront) {
      if ($t.StartsWith('#') -or $t -eq '') { continue }          # author notes
      $i = $t.IndexOf(':')
      if ($i -gt 0) { $fields[$t.Substring(0, $i).Trim()] = $t.Substring($i + 1).Trim() }
      continue
    }

    # verbatim fences
    if ($t.StartsWith('```')) {
      if (-not $inFence) { $inFence = $true; $fence.Clear(); $inHeader = $false }
      else { $inFence = $false; if ($cur) { $cur.fence = ($fence -join "`n") } }
      continue
    }
    if ($inFence) { [void]$fence.Add($line); continue }

    if ($t.StartsWith('# ') -or $t -eq '#') { continue }          # author notes

    # sub-item (### Title)
    if ($t.StartsWith('### ')) {
      $sub = @{ title = $t.Substring(4).Trim(); body = New-Object System.Collections.ArrayList }
      if ($cur) { [void]$cur.subs.Add($sub) }
      continue
    }

    # block (## Title)
    if ($t.StartsWith('## ')) {
      $name2 = $t.Substring(3).Trim()
      # In sectioned mode an unrecognised "## " is a sub-heading, not a section.
      if ($Sections.Count -gt 0 -and ($Sections -notcontains $name2)) {
        $sub = @{ title = $name2; body = New-Object System.Collections.ArrayList }
        if ($cur) { [void]$cur.subs.Add($sub) }
        $inHeader = $false
        continue
      }
      $cur = @{
        title  = $t.Substring(3).Trim()
        fields = @{}
        body   = New-Object System.Collections.ArrayList
        fence  = ''
        list   = New-Object System.Collections.ArrayList
        subs   = New-Object System.Collections.ArrayList
      }
      [void]$blocks.Add($cur)
      $sub = $null
      $inHeader = $true
      continue
    }

    # list item. Inside a sub-heading it stays in the body stream so prose and
    # bullets keep their authored order; at section level it feeds .list, which
    # is what the fact sheet and the feature list are built from.
    if (Test-Bullet $t) {
      $inHeader = $false
      if ($sub)     { [void]$sub.body.Add($line) }
      elseif ($cur) { [void]$cur.list.Add($t.Substring(2).Trim()) }
      continue
    }

    # a field line, but only in a block's header zone, and only a bare
    # lowercase identifier - so ordinary prose containing a colon is safe.
    if ($cur -and $inHeader -and $t -match '^[a-z_]+:\s*') {
      $i = $t.IndexOf(':')
      $cur.fields[$t.Substring(0, $i).Trim()] = $t.Substring($i + 1).Trim()
      continue
    }

    if ($t -ne '') { $inHeader = $false }

    # body text
    if ($sub)      { [void]$sub.body.Add($line) }
    elseif ($cur)  { [void]$cur.body.Add($line) }
    else           { [void]$intro.Add($line) }
  }

  return @{
    fields = $fields
    intro  = ($intro -join "`n")
    blocks = $blocks
  }
}

# $script:ctx names the file currently being read, so a warning can point at it.
$script:ctx = ''
function Get-Field($bag, [string]$key, [string]$fallback = '') {
  if ($bag.ContainsKey($key) -and -not [string]::IsNullOrWhiteSpace($bag[$key])) { return $bag[$key] }
  if ($fallback -eq '') { $script:warnings += ("  " + $script:ctx + ": missing or empty field '" + $key + "'") }
  return $fallback
}

# --- Partials ---------------------------------------------------------------
$partialText = Read-TextFile (Join-Path $root 'templates\partials.html')
$partials = @{}
$chunks = [regex]::Split($partialText, '<!--\s*@([a-z_]+)\s*-->')
for ($i = 1; $i -lt $chunks.Length; $i += 2) {
  $partials[$chunks[$i]] = $chunks[$i + 1].TrimEnd()
}

function Use-Partial([string]$name, [hashtable]$vars) {
  if (-not $partials.ContainsKey($name)) { throw "Unknown partial: $name" }
  $out = $partials[$name]
  foreach ($k in $vars.Keys) { $out = $out.Replace('{{' + $k + '}}', [string]$vars[$k]) }
  return $out.Trim("`r", "`n")
}

function Expand-Template([string]$tpl, [hashtable]$vars) {
  foreach ($k in $vars.Keys) { $tpl = $tpl.Replace('{{' + $k + '}}', [string]$vars[$k]) }
  $left = [regex]::Matches($tpl, '\{\{([a-z_.]+)\}\}')
  foreach ($m in $left) { $script:warnings += ("  unresolved token " + $m.Value) }
  return ($tpl -replace '\{\{[a-z_.]+\}\}', '')
}

Write-Host ""
Write-Host "  Building PowerCorp website..." -ForegroundColor Yellow

# =============================================================================
#  LOAD CONTENT
# =============================================================================
$site   = (Read-Content 'site.md').fields
$hero   = Read-Content '01-hero.md'
$loop   = Read-Content '02-loop.md'
$media  = Read-Content '03-media.md'
$sys    = Read-Content '04-systems.md'
$world  = Read-Content '05-world.md'
$dev    = Read-Content '06-developer.md'
$close  = Read-Content '07-closing.md'
$press  = Read-Content 'press.md' -Sections @('FACTS','DESCRIPTIONS','FEATURES','ASSETS','ABOUT')

$V = @{}
foreach ($k in $site.Keys) {
  # Links go in raw; everything else is escaped.
  if ($site[$k] -match '^https?://') { $V["site.$k"] = $site[$k] }
  else { $V["site.$k"] = Convert-Inline $site[$k] }
}

# --- Hero -------------------------------------------------------------------
$script:ctx = '01-hero.md'
$V['hero.stamp']           = Convert-Inline (Get-Field $hero.fields 'stamp')
$V['hero.headline']        = Convert-Heading (Get-Field $hero.fields 'headline')
$V['hero.headline_accent'] = Convert-Heading (Get-Field $hero.fields 'headline_accent')
$V['hero.cta_primary']     = Convert-Inline (Get-Field $hero.fields 'cta_primary')
$V['hero.cta_secondary']   = Convert-Inline (Get-Field $hero.fields 'cta_secondary')
$V['hero.meta']            = Convert-Inline (Get-Field $hero.fields 'meta')
$V['hero.body']            = Convert-Body $hero.intro
$V['hero.image']           = Get-Field $hero.fields 'image' 'key-art.svg'
$V['hero.image_alt']       = Convert-Inline (Get-Field $hero.fields 'image_alt' 'PowerCorp key art')
$heroCap = Get-Field $hero.fields 'image_caption' ' '
$V['hero.image_caption_html'] = if ($heroCap.Trim()) { Use-Partial 'frame_caption' @{ caption = (Convert-Inline $heroCap) } } else { '' }

# --- Loop -------------------------------------------------------------------
$script:ctx = '02-loop.md'
$V['loop.eyebrow'] = Convert-Inline (Get-Field $loop.fields 'eyebrow')
$V['loop.heading'] = Convert-Heading (Get-Field $loop.fields 'heading')
$V['loop.body']    = Convert-Body $loop.intro
$items = @()
foreach ($b in $loop.blocks) {
  $items += Use-Partial 'step' @{
    title = (Convert-Inline $b.title)
    body  = (Convert-Inline ((($b.body -join ' ') -replace '\s+', ' ').Trim()))
  }
}
$V['loop.items'] = ($items -join "`n")
if ($items.Count -eq 0) { $warnings += "  02-loop.md has no '## ' steps" }

# --- Media (built per page, because the image path differs) ------------------
function Build-Media([string]$prefix) {
  $script:ctx = '03-media.md'
  $out = @()
  foreach ($b in $media.blocks) {
    $cap = Get-Field $b.fields 'caption' ' '
    $out += Use-Partial 'frame' @{
      src     = $prefix + 'assets/img/' + (Get-Field $b.fields 'file')
      alt     = (Convert-Inline (Get-Field $b.fields 'alt' $b.title))
      caption = $(if ($cap.Trim()) { Use-Partial 'frame_caption' @{ caption = (Convert-Inline $cap) } } else { '' })
    }
  }
  return ($out -join "`n")
}
$script:ctx = '03-media.md'
$V['media.eyebrow'] = Convert-Inline (Get-Field $media.fields 'eyebrow')
$V['media.heading'] = Convert-Heading (Get-Field $media.fields 'heading')

# --- Systems ----------------------------------------------------------------
$script:ctx = '04-systems.md'
$V['systems.eyebrow'] = Convert-Inline (Get-Field $sys.fields 'eyebrow')
$V['systems.heading'] = Convert-Heading (Get-Field $sys.fields 'heading')
$V['systems.body']    = Convert-Body $sys.intro
$items = @()
foreach ($b in $sys.blocks) {
  $lamp = $b.title; $title = $b.title
  if ($b.title -match '^(.+?)\s*\|\s*(.+)$') { $lamp = $Matches[1].Trim(); $title = $Matches[2].Trim() }
  $cls = ''
  if ($lamp.StartsWith('!')) { $cls = ' lamp--warn'; $lamp = $lamp.Substring(1).Trim() }
  $items += Use-Partial 'card' @{
    lamp       = (Convert-Inline $lamp)
    lamp_class = $cls
    title      = (Convert-Inline $title)
    body       = (Convert-Inline ((($b.body -join ' ') -replace '\s+', ' ').Trim()))
  }
}
$V['systems.items'] = ($items -join "`n")
if ($items.Count % 2 -ne 0) { $warnings += "  04-systems.md has an odd number of cards - the last row will be half empty" }

# --- World ------------------------------------------------------------------
$script:ctx = '05-world.md'
$V['world.eyebrow'] = Convert-Inline (Get-Field $world.fields 'eyebrow')
$V['world.heading'] = Convert-Heading (Get-Field $world.fields 'heading')
$V['world.body']    = Convert-Body $world.intro
$full = @(); $half = @(); $lore = @(); $tickerLabel = ''
foreach ($b in $world.blocks) {
  if ($b.title -eq 'TICKER') {
    $tickerLabel = Get-Field $b.fields 'label' ' '
    foreach ($l in $b.list) { $lore += $l }
    continue
  }
  $footL = ''; $footR = ''
  $foot = Get-Field $b.fields 'foot' ' '
  if ($foot -match '^(.*?)\s*\|\|\s*(.*)$') { $footL = $Matches[1].Trim(); $footR = $Matches[2].Trim() }
  else { $footL = $foot.Trim() }
  $status = Get-Field $b.fields 'status' ' '
  $cap    = Get-Field $b.fields 'caption' ' '
  $html = Use-Partial 'terminal' @{
    head       = (Convert-Inline (Get-Field $b.fields 'head' $b.title))
    status     = $(if ($status.Trim()) { Use-Partial 'terminal_status' @{ status = (Convert-Inline $status) } } else { '' })
    body       = (Convert-Verbatim $b.fence)
    foot_left  = (Convert-Inline $footL)
    foot_right = (Convert-Inline $footR)
    caption    = $(if ($cap.Trim()) { Use-Partial 'terminal_caption' @{ caption = (Convert-Inline $cap) } } else { '' })
  }
  if ((Get-Field $b.fields 'layout' 'half') -eq 'full') { $full += $html } else { $half += "        <div>`n$html`n        </div>" }
  if ([string]::IsNullOrWhiteSpace($b.fence)) { $warnings += ('  05-world.md: block "' + $b.title + '" has no fenced text block, so it renders empty') }
}
$V['world.full_items']   = ($full -join "`n")
$V['world.half_items']   = ($half -join "`n")
$V['world.ticker_label'] = Convert-Inline $tickerLabel
$V['world.ticker_first'] = $(if ($lore.Count) { Convert-Inline $lore[0] } else { '' })
$V['world.ticker_json']  = ConvertTo-JsonArray $lore

# --- Developer --------------------------------------------------------------
$script:ctx = '06-developer.md'
$V['developer.eyebrow']      = Convert-Inline (Get-Field $dev.fields 'eyebrow')
$V['developer.pullquote']    = Convert-Heading (Get-Field $dev.fields 'pullquote')
$V['developer.attribution']  = Convert-Inline (Get-Field $dev.fields 'attribution')
$V['developer.btn_feedback'] = Convert-Inline (Get-Field $dev.fields 'btn_feedback')
$V['developer.btn_bug']      = Convert-Inline (Get-Field $dev.fields 'btn_bug')
$V['developer.body']         = Convert-Body $dev.intro '          '

# --- Closing ----------------------------------------------------------------
$script:ctx = '07-closing.md'
$V['closing.heading']       = Convert-Heading (Get-Field $close.fields 'heading')
$V['closing.cta_primary']   = Convert-Inline (Get-Field $close.fields 'cta_primary')
$V['closing.cta_secondary'] = Convert-Inline (Get-Field $close.fields 'cta_secondary')
$V['closing.body']          = Convert-Body $close.intro '      '

# --- Press ------------------------------------------------------------------
$script:ctx = 'press.md'
$V['press.eyebrow'] = Convert-Inline (Get-Field $press.fields 'eyebrow')
$V['press.heading'] = Convert-Heading (Get-Field $press.fields 'heading')
$V['press.body']    = Convert-Body $press.intro '      '

# Optional sections default to nothing, so deleting a block from press.md drops
# its whole section instead of leaving an empty shell on the page.
$V['features.section']   = ''
$V['descriptions.items'] = ''
$V['facts.items']        = ''

foreach ($b in $press.blocks) {
  $key = $b.title.ToLower()
  $V["$key.eyebrow"] = Convert-Inline (Get-Field $b.fields 'eyebrow' ' ')
  $V["$key.heading"] = Convert-Heading (Get-Field $b.fields 'heading' ' ')
  $V["$key.button"]  = Convert-Inline (Get-Field $b.fields 'button' ' ')
  $V["$key.body"]    = Convert-Body ($b.body -join "`n") '      '

  switch ($b.title) {
    'FACTS' {
      $rows = @()
      foreach ($l in $b.list) {
        $lbl = $l; $val = ''
        if ($l -match '^(.*?)\s*\|\s*(.*)$') { $lbl = $Matches[1].Trim(); $val = $Matches[2].Trim() }
        $rows += Use-Partial 'factrow' @{ label = (Convert-Inline $lbl); value = (Convert-Inline $val) }
      }
      $V['facts.items'] = ($rows -join "`n")
    }
    'DESCRIPTIONS' {
      $blocksOut = @()
      foreach ($s in $b.subs) {
        $blocksOut += Use-Partial 'copyblock' @{
          title = (Convert-Inline $s.title)
          body  = (Convert-Body ($s.body -join "`n") '        ')
        }
      }
      $V['descriptions.items'] = ($blocksOut -join "`n")
    }
    'FEATURES' {
      $b2 = @()
      foreach ($l in $b.list) { $b2 += Use-Partial 'bullet' @{ body = (Convert-Inline $l) } }
      $V['features.section'] = Use-Partial 'features_section' @{
        eyebrow = $V['features.eyebrow']
        heading = $V['features.heading']
        items   = ($b2 -join "`n")
      }
    }
    'ABOUT' {
      $V['about.pullquote']   = Convert-Heading (Get-Field $b.fields 'pullquote')
      $V['about.attribution'] = Convert-Inline (Get-Field $b.fields 'attribution')
    }
  }
}

# =============================================================================
#  RENDER
# =============================================================================
$V['media.items'] = Build-Media ''
$out = Expand-Template (Read-TextFile (Join-Path $root 'templates\index.html')) $V
Write-TextFile (Join-Path $root 'index.html') $out
Write-Host ("    index.html          " + $out.Length + " bytes") -ForegroundColor DarkGray

$V['media.items'] = Build-Media '../'
$out = Expand-Template (Read-TextFile (Join-Path $root 'templates\press.html')) $V
Write-TextFile (Join-Path $root 'press\index.html') $out
Write-Host ("    press/index.html    " + $out.Length + " bytes") -ForegroundColor DarkGray

# --- Report -----------------------------------------------------------------
Write-Host ""
if ($warnings.Count) {
  Write-Host "  Built, with things worth checking:" -ForegroundColor Yellow
  $warnings | Sort-Object -Unique | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
} else {
  Write-Host "  Built cleanly. Open index.html to see it." -ForegroundColor Green
}
Write-Host ""
