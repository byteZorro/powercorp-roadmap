# PowerCorp — website

Plain HTML, CSS and JavaScript. No npm, no framework, no dependencies. GitHub Pages
serves the built files exactly as they are.

**The words live apart from the layout.** You write markdown in `content/`, run one
build, and it bakes your text into static HTML. You never touch a tag.

```
content/            <-- YOU EDIT THESE. Just words.
build.bat           <-- double-click after editing
index.html          <-- generated, do not edit
press/index.html    <-- generated, do not edit
templates/          <-- the layout (only touch to change design)
assets/             css, js, fonts, images
```

---

## The loop

1. Open a file in `content/` in any text editor.
2. Change the words.
3. Double-click **`build.bat`**.
4. Open `index.html` in a browser.

The build tells you if you broke something:

```
  Built, with things worth checking:
  04-systems.md has an odd number of cards - the last row will be half empty
  06-developer.md: missing or empty field 'pullquote'
```

**Everything you type is escaped before it reaches the page.** Quotes, angle brackets,
ampersands, stray markup — none of it can break the layout or inject anything. Write
freely.

---

## The content files

| File | What it controls |
|---|---|
| `site.md` | Title, meta description, every link, header nav, footer. Change a URL here and every button follows. |
| `01-hero.md` | The first screen |
| `02-loop.md` | "What you actually do" — the four steps |
| `03-media.md` | The screenshot strip (filenames, alt text, captions) |
| `04-systems.md` | The eight feature cards |
| `05-world.md` | The terminal blocks and the rotating lore line |
| `06-developer.md` | "Who made this" |
| `07-closing.md` | The final call to action |
| `press.md` | The whole press page |

---

## Syntax cheat sheet

Everything you need is in these six rules. Each content file also carries notes at the
top explaining its own fields.

**1. Fields** sit between the `---` fences at the top. Edit the bit after the colon.

```
heading: Four jobs. All of them yours.
```

**2. Lines starting with `#` are private notes.** They never appear on the site.

**3. Body text** is anything after the closing `---`. A blank line starts a new
paragraph. Single line breaks are ignored, so wrap however you like.

**4. `## Something` starts a repeating item** — one step, one card, one image, one
terminal block. Add or delete them freely.

**5. Inline formatting:** `**bold**`, `*italic*`, `[link text](https://url)`.

**6. `|` in a heading forces a line break.**

```
heading: Nobody is coming. | The schedule says so.
```

### Two extras

**Feature cards** (`04-systems.md`) put the lamp chip before a `|`. A leading `!` makes
the chip red:

```
## PWR | The grid sheds the engine, not the air
## !GLOAD | The seat is not the centre of mass
```

**Terminal blocks** (`05-world.md`) print the text inside ``` fences *exactly* as typed —
line breaks, blank lines and spacing all preserved, because it is meant to look like a
readout. Keep lines under ~46 characters so a half-width block doesn't scroll sideways.

---

## ⚠️ Before you deploy

**This folder must become its own repository. Do not `git init` the parent project
folder.** `WEBSITE/` currently sits inside the PowerCorp game project, and pushing from
the parent directory would publish the entire game source: every script, the narrative
content packs, `export_presets.cfg`, all of it.

The site depends on nothing outside this folder, so it moves cleanly.

**Commit the generated files.** `index.html` and `press/index.html` are what GitHub Pages
actually serves, so they belong in the repo alongside `content/`. Always run `build.bat`
before committing, or you will push old text.

---

## Deploying to GitHub Pages

**1.** From inside `WEBSITE/`:

```bash
git init -b main
git add .
git commit -m "PowerCorp website"
```

**2.** Create an empty repo on GitHub — no README, no .gitignore, no licence. Call it
something like `powercorp-site`.

**3.** Push:

```bash
git remote add origin https://github.com/YOURNAME/powercorp-site.git
git push -u origin main
```

**4.** In the repo: **Settings → Pages → Source: Deploy from a branch → Branch: `main` /
`/ (root)` → Save.**

Live at `https://YOURNAME.github.io/powercorp-site/` in a minute or two.

### A custom domain later

Every path is **relative**, so the site works at a repo subpath *and* at a domain root
with no changes.

1. Add a file called `CNAME` containing only your domain, e.g. `powercorpgame.com`
2. At your registrar: a `CNAME` record for `www` → `YOURNAME.github.io`, and four `A`
   records for the apex → `185.199.108.153`, `185.199.109.153`, `185.199.110.153`,
   `185.199.111.153`
3. **Settings → Pages**, enter the domain, tick **Enforce HTTPS**.

---

## Swapping in real screenshots

The frames are already correctly proportioned, so no layout changes are needed. Edit
`content/03-media.md`:

```
## Systems console
file: screenshot-01.jpg          <-- your file, dropped in assets/img/
alt: What the image shows
caption:                         <-- delete this line once it's real art
```

Four placeholders exist: `key-art.svg` (4:5, in the hero — change that one in
`templates/index.html`), and `screenshot-01/02/03.svg` (16:9). Aim for ~1600×900 JPGs
under about 400 KB each.

**The social card** (`assets/img/og-image.png`, 1200×630) is generated text on the game's
background colour. Replacing it with real key art is worth doing — it is what appears
whenever anyone posts the link in Discord, Reddit or Bluesky.

---

## Things left blank on purpose

Search `content/` for `[YOUR` — these are facts only you can supply, marked rather than
invented:

- `[YOUR CITY, COUNTRY]` and `[YOUR PRESS EMAIL]` in `press.md`
- Release date and price are both `TBA`

**The version number is deliberately absent.** Three values disagree in the game project:
`project.godot` says `0.3.1.2026`, the folder is named `0.3.4.2026`, and the main menu
hardcodes `Playtest Version 0.1.0`. The site says "In development · Playtest" instead of
picking one. Decide which is canonical, then edit `status_line` in `content/site.md`.

---

## Fonts and licensing

Fonts are self-hosted from the game's own `assets/fonts/`, so the site makes **no
third-party network requests at all** — nothing from Google, no CDN, no analytics.

| Face | Used for | Licence |
|---|---|---|
| Orbitron Black / SemiBold | Wordmark, headings, chrome | SIL Open Font License — self-hosting is fine |
| Ac437 IBM DOS ISO9 | Terminal blocks, labels, MET clock | Creative Commons, by VileR / int10h.org |

**Verify the DOS font's licence before the site goes public.** It ships as part of the
Ultimate Oldschool PC Font Pack and is Creative Commons, but the exact variant matters —
if it is CC BY-SA, the attribution already in the footer satisfies it, and you should
confirm that is sufficient. If you would rather not carry the question, `VT323` on Google
Fonts is a near-identical VT220-style face under the OFL; swapping it is a two-line change
in `assets/css/site.css`.

Body copy uses the reader's own system font — zero bytes, no licence question.

---

## Design notes

Palette and typography are lifted from the game, not invented:

- Colours from `assets/themes/console_theme.tres` (the default `powercorp` theme) and
  `scenes/views/systems/panels/console_palette.gd` (the semantic set that stays fixed
  across all five CRT themes).
- The wordmark's glow is a two-radius `text-shadow` — a tight core plus a long faint tail,
  the idea behind `hud_bloom.gdshader`, because that reads as projected light rather than
  a blurred copy.
- The `·` separator, the dashed `--` null-states and the annunciator lamp chips are the
  game's own UI vocabulary.

The direction is deliberately **not** a full-page CRT costume: no page-wide scanlines, no
boot animation, no screen curvature. Those make a landing page harder to read and harder
for press to scan, and a visitor who cannot understand the game in five seconds does not
wishlist it.

Body text colour pairs clear WCAG AA. The dimmer amber (`--text-dim`) is about 3.5:1 and
is restricted to large text and decoration. Every animation sits behind
`prefers-reduced-motion`.

---

## Changing the layout itself

Only if you want to move things around structurally:

- `templates/index.html` and `templates/press.html` — page skeletons. `{{tokens}}` are
  filled from `content/`.
- `templates/partials.html` — the markup for one step, one card, one terminal block, etc.
- `assets/css/site.css` — the whole design system, tokens at the top.
- `build.ps1` — the generator. Reads content, fills templates, escapes everything.
