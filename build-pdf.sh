#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

BUILD=/tmp/2084-build
mkdir -p "$BUILD"

# --- Shared CSS ---
cat > "$BUILD/book.css" <<'CSS'
@page {
  size: 148mm 210mm;
  margin: 20mm 18mm 22mm 18mm;
}
@page :first {
  margin: 0;
}
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
  -webkit-hyphens: auto;
  widows: 2;
  orphans: 2;
}
.cover {
  page-break-after: always;
  margin: 0;
  padding: 0;
  width: 148mm;
  height: 210mm;
  background: #0a0d1a;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}
.cover svg {
  width: 100%;
  height: 100%;
  display: block;
}
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
pre {
  font-family: "Courier New", "Courier", monospace;
  font-size: 6.8pt;
  line-height: 1.18;
  white-space: pre;
  background: #f6f4ef;
  border-left: 2px solid #c7b89e;
  padding: 7pt 9pt;
  margin: 1em 0 1.6em 0;
  text-align: left;
  hyphens: none;
  -webkit-hyphens: none;
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
CSS

# --- Build function ---
build() {
  local lang="$1"
  local chapters_dir="$2"
  local cover_svg="$3"
  local out_pdf="$4"
  local title="$5"

  echo "Building $out_pdf ..."

  local combined_md="$BUILD/book-$lang.md"
  : > "$combined_md"

  # Concatenate chapters, replacing stand-alone * section breaks
  for ch in "$chapters_dir"/*.md; do
    # Convert a line that is exactly "*" into a section-break div.
    # Also convert a line that is exactly "---" into the same, defensively.
    awk '
      /^\*$/ { print "<div class=\"section-break\">✦</div>"; next }
      { print }
    ' "$ch" >> "$combined_md"
    printf "\n\n" >> "$combined_md"
  done

  # Pandoc markdown -> HTML body
  pandoc "$combined_md" -f markdown -t html5 \
    --standalone \
    --metadata title="$title" \
    -o "$BUILD/$lang-body.html"

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
    echo '</div>'
    # Extract pandoc's body content
    sed -n '/<body>/,/<\/body>/p' "$BUILD/$lang-body.html" \
      | sed '1d;$d'
    echo '</body></html>'
  } > "$final_html"

  # Render with Chrome headless
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --headless=new \
    --disable-gpu \
    --no-pdf-header-footer \
    --print-to-pdf-no-header \
    --print-to-pdf="$out_pdf" \
    --virtual-time-budget=10000 \
    "file://$final_html" 2>/dev/null

  echo "  → $out_pdf ($(du -h "$out_pdf" | cut -f1))"
}

build "en"    "chapters"        "cover.svg"       "$(pwd)/2084.pdf"       "2084"
build "pt-BR" "chapters-pt-BR"  "cover-pt-BR.svg" "$(pwd)/2084-pt-BR.pdf" "2084"

echo ""
echo "Done."
ls -lh 2084.pdf 2084-pt-BR.pdf
