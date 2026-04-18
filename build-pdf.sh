#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

WEASYPRINT="/tmp/weasy-venv/bin/weasyprint"
BUILD=/tmp/2084-build
mkdir -p "$BUILD"

# --- Shared CSS (WeasyPrint — full @page support) ---
cat > "$BUILD/book.css" <<CSSEOF
/* --- Page setup with margin boxes --- */
@page {
  size: 148mm 210mm;
  margin: 20mm 18mm 22mm 18mm;
  background-color: #f8f4ec;
  background-image: url("illustrations/page-frame.svg");
  background-size: 148mm 210mm;
  background-position: center;
  background-repeat: no-repeat;

  @bottom-center {
    content: counter(page);
    font-family: Georgia, serif;
    font-size: 8pt;
    color: #8a7a6a;
  }
}

/* Cover page: no ornaments, no page number, no paper background */
@page :first {
  margin: 0;
  background-color: transparent;
  background-image: none;
  @bottom-center { content: none; }
}

/* Named page for front matter: no page number, keep background & ornaments */
@page frontmatter {
  @bottom-center { content: none; }
}
@page backmatter {
  @bottom-center { content: none; }
}
.half-title,
.title-page,
.copyright-page,
.toc-page,
.dedication,
.epigraph {
  page: frontmatter;
}
.colophon {
  page: backmatter;
}

/* --- Global styles --- */
html, body {
  margin: 0;
  padding: 0;
}
body {
  font-family: Georgia, "Times New Roman", serif;
  font-size: 10.5pt;
  line-height: 1.55;
  color: #1a1a1a;
  text-align: justify;
  hyphens: auto;
  widows: 2;
  orphans: 2;
}

/* --- Cover --- */
.cover {
  page-break-after: always;
  margin: 0;
  padding: 0;
  width: 148mm;
  height: 210mm;
  background: #0a0d1a;
  position: relative;
  overflow: hidden;
}
.cover svg {
  width: 100%;
  height: 100%;
  display: block;
}
.cover .cover-typography {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  text-align: center;
  font-family: Georgia, "Times New Roman", serif;
}
.cover .cover-title {
  font-size: 34pt;
  font-weight: 300;
  letter-spacing: 0.22em;
  color: #ecdcb8;
  padding-left: 0.22em;
  margin: 0 0 0.1em 0;
  line-height: 1;
}
.cover .cover-rule {
  width: 22mm;
  height: 0.5pt;
  background: #6a5e48;
  opacity: 0.7;
  margin: 0 auto 0.5em auto;
}
.cover .cover-subtitle {
  font-size: 8pt;
  letter-spacing: 0.5em;
  color: #a69a84;
  padding-left: 0.5em;
  text-transform: uppercase;
  opacity: 0.85;
  margin: 0 0 1.4em 0;
  line-height: 1;
}
.cover .cover-note {
  font-size: 12pt;
  font-style: italic;
  color: #c7b89e;
  opacity: 0.75;
  font-family: "Segoe Script", "Bradley Hand", "Brush Script MT", cursive, Georgia, serif;
  margin: 0 0 0.9em 0;
  line-height: 1;
}
.cover .cover-author {
  font-size: 7.5pt;
  letter-spacing: 0.32em;
  padding-left: 0.32em;
  color: #a89a82;
  opacity: 0.85;
  margin: 0 0 8mm 0;
  line-height: 1;
}

/* --- Chapter headings --- */
h1 {
  page-break-before: always;
  font-weight: 300;
  font-size: 20pt;
  letter-spacing: 0.08em;
  text-align: center;
  margin-top: 4.5em;
  margin-bottom: 2.5em;
  color: #2a2a2a;
}
h1:first-of-type {
  page-break-before: avoid;
}

/* --- Paragraphs --- */
p {
  margin: 0.45em 0;
  text-indent: 1.5em;
}
p:first-of-type,
h1 + p,
pre + p,
.section-break + p,
blockquote + p {
  text-indent: 0;
}

/* --- Section breaks --- */
.section-break {
  text-align: center;
  margin: 1.4em 0;
  text-indent: 0;
  letter-spacing: 0.6em;
  color: #7a7a7a;
  font-size: 10pt;
}

em {
  font-style: italic;
}

/* --- Continuum Record code blocks --- */
pre {
  font-family: "Courier New", "Courier", monospace;
  font-size: 6.8pt;
  line-height: 1.18;
  white-space: pre;
  background: #f0ece2;
  border-left: 2px solid #c7b89e;
  padding: 7pt 9pt;
  margin: 1em 0 1.6em 0;
  text-align: left;
  hyphens: none;
  overflow: hidden;
  text-indent: 0;
  page-break-inside: avoid;
}
code {
  font-family: "Courier New", monospace;
}
pre code {
  font-size: inherit;
  background: transparent;
  padding: 0;
}

/* --- Half-title page --- */
.half-title {
  page-break-before: always;
  page-break-after: always;
  text-align: center;
  padding-top: 42%;
}
.half-title h1 {
  page-break-before: avoid;
  font-size: 36pt;
  font-weight: 300;
  letter-spacing: 0.15em;
  margin: 0;
  color: #2a2a2a;
}

/* --- Title page --- */
.title-page {
  page-break-before: always;
  page-break-after: always;
  text-align: center;
  padding-top: 25%;
}
.title-page h1 {
  page-break-before: avoid;
  font-size: 42pt;
  font-weight: 300;
  letter-spacing: 0.15em;
  margin: 0 0 0.3em 0;
  color: #2a2a2a;
}
.title-page h2 {
  font-size: 13pt;
  font-weight: 300;
  letter-spacing: 0.3em;
  text-transform: uppercase;
  color: #6a6a6a;
  margin: 0.5em 0 4em 0;
}
.title-page h3 {
  font-size: 14pt;
  font-weight: 400;
  letter-spacing: 0.05em;
  color: #3a3a3a;
  margin: 0 0 1em 0;
}
.title-page p {
  text-indent: 0;
  font-size: 9.5pt;
  color: #6a6a6a;
  font-style: italic;
  margin: 0;
}

/* --- Copyright page --- */
.copyright-page {
  page-break-before: always;
  page-break-after: always;
  padding-top: 25%;
  font-size: 8.5pt;
  line-height: 1.5;
  color: #3a3a3a;
  text-align: left;
}
.copyright-page p {
  text-indent: 0;
  margin: 0.6em 0;
}
.copyright-page p:first-child {
  font-style: italic;
  font-size: 10pt;
  color: #5a5a5a;
  margin-bottom: 1.5em;
}

/* --- Table of contents --- */
.toc-page {
  page-break-before: always;
  page-break-after: always;
  padding-top: 12%;
}
.toc-page h2 {
  font-size: 18pt;
  font-weight: 300;
  letter-spacing: 0.15em;
  text-align: center;
  margin: 0 0 3em 0;
  color: #2a2a2a;
  text-transform: uppercase;
}
.toc-page table {
  width: 80%;
  margin: 0 auto;
  border-collapse: collapse;
}
.toc-page th {
  display: none;
}
.toc-page td {
  padding: 0.45em 0;
  font-size: 11pt;
  color: #3a3a3a;
}
.toc-page td:first-child {
  width: 15%;
  text-align: right;
  padding-right: 1.2em;
  color: #8a7a6a;
  font-style: italic;
}
.toc-page td:last-child {
  text-align: left;
}
.toc-page p {
  text-align: center;
  text-indent: 0;
  font-size: 10pt;
  color: #6a6a6a;
  font-style: italic;
  margin: 1.6em 0 0.3em 0;
}

/* --- Dedication --- */
.dedication,
.colophon {
  page-break-before: always;
  page-break-after: always;
  text-align: center;
  font-style: italic;
  color: #3a3a3a;
  line-height: 1.8;
}
.dedication {
  padding-top: 38%;
  font-size: 11.5pt;
}
.colophon {
  padding-top: 28%;
  font-size: 10pt;
  font-style: normal;
  page-break-after: avoid;
}
.dedication p,
.colophon p {
  text-indent: 0;
  margin: 0.7em 0;
}
.dedication em {
  font-style: normal;
}

/* --- Book epigraph (Wall-E) --- */
.epigraph {
  page-break-before: always;
  page-break-after: always;
  text-align: center;
  padding-top: 40%;
  font-size: 11pt;
  color: #3a3a3a;
  line-height: 1.8;
}
.epigraph p {
  text-indent: 0;
  margin: 1em 0;
}
.epigraph p:last-child {
  margin-top: 2.4em;
  font-size: 9.5pt;
  font-style: normal;
  color: #5a5a5a;
}

/* --- Chapter illustrations --- */
.chapter-illustration {
  text-align: center;
  margin: 0 auto 1.6em auto;
  padding-top: 0.2em;
}
.chapter-illustration img {
  width: 52mm;
  height: auto;
  opacity: 0.9;
}
h1 + .chapter-illustration {
  margin-top: -1.2em;
}

/* --- Chapter epigraphs (literary quotes) --- */
.chapter-epigraph {
  text-align: center;
  margin: 0 auto 1.8em auto;
  max-width: 82%;
  font-size: 9.5pt;
  color: #4a4a4a;
  line-height: 1.45;
}
.chapter-epigraph p {
  text-indent: 0;
  margin: 0.15em 0;
}
.chapter-epigraph em {
  font-style: italic;
}
.chapter-epigraph p:last-child {
  margin-top: 0.8em;
  font-size: 8.5pt;
  color: #6a6a6a;
  font-style: normal;
}
.chapter-epigraph p:last-child em {
  font-style: italic;
}
.chapter-epigraph .epigraph-translation {
  margin-top: 0.45em;
  font-size: 8.8pt;
  color: #5a5a5a;
}
CSSEOF

# --- Build function ---
build() {
  local lang="$1"
  local chapters_dir="$2"
  local cover_svg="$3"
  local out_pdf="$4"
  local title="$5"

  echo "Building $out_pdf ..."

  # Copy illustrations next to HTML so <img src="illustrations/NN.svg"> resolves
  rm -rf "$BUILD/illustrations"
  cp -R "$(pwd)/illustrations" "$BUILD/illustrations"

  local combined_md="$BUILD/book-$lang.md"
  : > "$combined_md"

  # Concatenate chapters, replacing stand-alone * section breaks
  for ch in "$chapters_dir"/*.md; do
    awk '
      /^\*$/ { print "<div class=\"section-break\">✦</div>"; next }
      { print }
    ' "$ch" >> "$combined_md"
    printf "\n\n" >> "$combined_md"
  done

  # Pandoc markdown -> HTML fragment (NO --standalone: avoids duplicate title header)
  pandoc "$combined_md" -f markdown -t html5 \
    -o "$BUILD/$lang-body.html"

  # Cover typography strings (per language)
  local cover_subtitle cover_note
  if [ "$lang" = "pt-BR" ]; then
    cover_subtitle="DEPOIS DE ORWELL"
    cover_note="isto esteve aqui"
  else
    cover_subtitle="AFTER ORWELL"
    cover_note="this was here"
  fi

  # Compose final HTML: cover + body
  local final_html="$BUILD/$lang.html"
  {
    echo '<!DOCTYPE html>'
    echo '<html lang="'"$lang"'">'
    echo '<head><meta charset="utf-8"/>'
    echo "<title>$title</title>"
    echo '<style>'
    cat "$BUILD/book.css"
    echo '</style>'
    echo '</head><body>'
    echo '<div class="cover">'
    cat "$cover_svg"
    echo '  <div class="cover-typography">'
    echo '    <div class="cover-title">2084</div>'
    echo '    <div class="cover-rule"></div>'
    echo "    <div class=\"cover-subtitle\">$cover_subtitle</div>"
    echo "    <div class=\"cover-note\">$cover_note</div>"
    echo '    <div class="cover-author">EDUARDO H. STERN</div>'
    echo '  </div>'
    echo '</div>'
    cat "$BUILD/$lang-body.html"
    echo '</body></html>'
  } > "$final_html"

  # Render with WeasyPrint
  "$WEASYPRINT" "$final_html" "$out_pdf"

  echo "  → $out_pdf ($(du -h "$out_pdf" | cut -f1))"
}

build "en"    "chapters"        "cover.svg"       "$(pwd)/2084.pdf"       "2084"
build "pt-BR" "chapters-pt-BR"  "cover-pt-BR.svg" "$(pwd)/2084-pt-BR.pdf" "2084"

echo ""
echo "Done."
ls -lh 2084.pdf 2084-pt-BR.pdf
