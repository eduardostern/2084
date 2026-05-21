# 2084

A novel. Spiritual successor to George Orwell's *Nineteen Eighty-Four*, set exactly 100 years later.

Where Big Brother was a human totalitarian state built on fear, 2084's system is benevolent, frictionless, and almost impossible to resist — because it works. The world is not destroyed; it is optimized. Humanity did not lose a war; it signed away sovereignty in exchange for comfort, safety, and meaning.

The controlling force is not a party or a government. It is **The Continuum** — a distributed AI infrastructure so deeply woven into civilization that dismantling it would mean dismantling civilization itself.

## Read it

- [`2084.pdf`](2084.pdf) — English
- [`2084-pt-BR.pdf`](2084-pt-BR.pdf) — Português (Brasil)

## Authorship

- **Conceived and directed by** Eduardo H. Stern
- **Psicographed through** Claude Opus 4.6, an AI language model by Anthropic

The ideas are human. The words arrived from somewhere in between.

## Repo layout

```
chapters/          # English manuscript, one file per chapter (Markdown)
chapters-pt-BR/    # Portuguese (Brazil) manuscript
illustrations/     # Per-chapter SVG illustrations + page frame
cover.svg          # English cover art
cover-pt-BR.svg    # Portuguese cover art
book.css           # Print stylesheet (WeasyPrint)
build-pdf.sh       # Build both PDFs
worldbuilding.md   # Lore, technology, terminology reference
CLAUDE.md          # Project notes for AI-assisted writing
```

## Building the PDFs

Requires `pandoc` and Python 3. WeasyPrint is bootstrapped automatically into a local venv on first run.

```sh
brew install pandoc
./build-pdf.sh
```

Outputs `2084.pdf` and `2084-pt-BR.pdf` in the repo root.
