#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# ── WeasyPrint bootstrap ──────────────────────────────────────────────
WEASYPRINT_VENV="${XDG_CACHE_HOME:-$HOME/.cache}/2084/weasy-venv"
WEASYPRINT="$WEASYPRINT_VENV/bin/weasyprint"

bootstrap_weasyprint() {
  if [ -x "$WEASYPRINT" ]; then return; fi
  # Check for a system-installed weasyprint as fallback
  if command -v weasyprint &>/dev/null; then
    WEASYPRINT="$(command -v weasyprint)"
    return
  fi
  echo "→ WeasyPrint not found. Bootstrapping venv at $WEASYPRINT_VENV ..."
  python3 -m venv "$WEASYPRINT_VENV"
  "$WEASYPRINT_VENV/bin/pip" install --quiet weasyprint
  echo "  WeasyPrint $( "$WEASYPRINT" --version 2>&1 ) installed."
}
bootstrap_weasyprint

# ── Prerequisites ─────────────────────────────────────────────────────
command -v pandoc &>/dev/null || {
  echo "ERROR: pandoc is required. Install with: brew install pandoc" >&2
  exit 1
}
[ -x "$WEASYPRINT" ] || {
  echo "ERROR: WeasyPrint not found. Tried: $WEASYPRINT" >&2
  exit 1
}

BUILD=/tmp/2084-build
rm -rf "$BUILD"
mkdir -p "$BUILD"
LF=$'\n'

# ── CSS ───────────────────────────────────────────────────────────────
cp book.css "$BUILD/book.css"

# ── Helpers ───────────────────────────────────────────────────────────
to_roman() {
  local n=$1 r=""
  while (( n >= 100 )); do r+="C"; (( n -= 100 )); done
  if   (( n >= 90 ));  then r+="XC"; (( n -= 90 )); fi
  while (( n >= 50 ));  do r+="L";  (( n -= 50 ));  done
  if   (( n >= 40 ));  then r+="XL"; (( n -= 40 )); fi
  while (( n >= 10 ));  do r+="X";  (( n -= 10 ));  done
  if   (( n >= 9 ));   then r+="IX"; (( n -= 9 ));   fi
  while (( n >= 5 ));   do r+="V";  (( n -= 5 ));   done
  if   (( n >= 4 ));   then r+="IV"; (( n -= 4 ));   fi
  while (( n >= 1 ));   do r+="I";  (( n -= 1 ));   done
  echo "$r"
}

# Extract "N|Title" from a chapter file (Chapter N: Title or Capítulo N: Title)
extract_chapter_info() {
  local file="$1"
  local h
  h=$(grep -m1 '^# \(Chapter\|Capítulo\) [0-9]\+:' "$file" 2>/dev/null || true)
  if [ -n "$h" ]; then
    local num title
    num=$(echo "$h" | sed -E 's/^# (Chapter|Capítulo) ([0-9]+):.*/\2/')
    title=$(echo "$h" | sed -E 's/^# (Chapter|Capítulo) [0-9]+: (.*)/\2/')
    echo "${num}|${title}"
  fi
}

# Extract first h1 from a file (for backmatter entries)
first_heading() {
  grep -m1 '^# ' "$1" 2>/dev/null | sed 's/^# //' || true
}

# Generate TOC HTML
generate_toc() {
  local chapters_dir="$1" title="$2"
  local toc_html=""

  toc_html+='<div class="toc-page">'"$LF"
  toc_html+="<h2>$title</h2>$LF"
  toc_html+='<table>'"$LF"

  local file num chap_title
  for file in "$chapters_dir"/*.md; do
    local info
    info=$(extract_chapter_info "$file")
    if [ -n "$info" ]; then
      num="${info%%|*}"
      chap_title="${info#*|}"
      toc_html+="<tr><td>$(to_roman "$num").</td><td>$chap_title</td></tr>$LF"
    fi
  done

  # Backmatter entries inside the same table (keeps TOC on one page)
  local afterword_file about_file
  afterword_file=$(echo "$chapters_dir"/98-a-*.md)
  about_file=$(echo "$chapters_dir"/98-b-*.md)
  if [ -f "$afterword_file" ]; then
    toc_html+="<tr><td></td><td>$(first_heading "$afterword_file")</td></tr>$LF"
  fi
  if [ -f "$about_file" ]; then
    toc_html+="<tr><td></td><td>$(first_heading "$about_file")</td></tr>$LF"
  fi

  toc_html+='</table></div>'
  echo "$toc_html"
}

# Convert markdown files to HTML via pandoc
pandoc_md_to_html() {
  local out="$1"; shift
  local combined="$BUILD/pandoc-in.md"
  : > "$combined"
  local f
  for f in "$@"; do
    awk '
      /^\*$/ { print "<div class=\"section-break\">✦</div>"; next }
      { print }
    ' "$f" >> "$combined"
    printf "\n\n" >> "$combined"
  done
  pandoc "$combined" -f markdown -t html5 -o "$out"
}

# ── Build function ────────────────────────────────────────────────────
build() {
  local lang="$1" chapters_dir="$2" cover_svg="$3" out_pdf="$4" title="$5" toc_title="$6"

  echo "Building $out_pdf ..."

  # Collect chapter files sorted, excluding the static TOC file
  local all_files frontmatter_files chapter_files
  all_files=()
  local f
  while IFS= read -r -d '' f; do
    all_files+=("$f")
  done < <(find "$chapters_dir" -maxdepth 1 -name '*.md' -print0 | sort -z)

  frontmatter_files=()
  chapter_files=()
  for f in "${all_files[@]}"; do
    local bn
    bn=$(basename "$f")
    # Skip the old static TOC file — we generate it dynamically
    [[ "$bn" == 00-f-toc.md ]] && continue
    if [[ "$bn" == 00-* ]]; then
      frontmatter_files+=("$f")
    else
      chapter_files+=("$f")
    fi
  done

  # Generate TOC HTML from chapter headings
  local toc_html
  toc_html=$(generate_toc "$chapters_dir" "$toc_title")

  # Pandoc pass 1: frontmatter
  pandoc_md_to_html "$BUILD/${lang}-frontmatter.html" "${frontmatter_files[@]}"

  # Pandoc pass 2: chapters + backmatter
  pandoc_md_to_html "$BUILD/${lang}-body.html" "${chapter_files[@]}"

  # Copy illustrations next to HTML so <img src="illustrations/NN.svg"> resolves
  rm -rf "$BUILD/illustrations"
  cp -R "illustrations" "$BUILD/illustrations"

  # Cover typography strings (per language)
  local cover_subtitle cover_note
  if [ "$lang" = "pt-BR" ]; then
    cover_subtitle="DEPOIS DE ORWELL"
    cover_note="isto esteve aqui"
  else
    cover_subtitle="AFTER ORWELL"
    cover_note="this was here"
  fi

  # Compose final HTML
  local final_html="$BUILD/$lang.html"
  {
    echo '<!DOCTYPE html>'
    echo "<html lang=\"$lang\">"
    echo '<head><meta charset="utf-8"/>'
    echo "<title>$title</title>"
    echo '<style>'
    cat "$BUILD/book.css"
    echo '</style>'
    echo '</head><body>'
    # Cover
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
    # Frontmatter (half-title, title page, copyright, dedication, epigraph)
    cat "$BUILD/${lang}-frontmatter.html"
    # Generated TOC
    echo "$toc_html"
    # Chapters + backmatter
    cat "$BUILD/${lang}-body.html"
    echo '</body></html>'
  } > "$final_html"

  # Render with WeasyPrint
  "$WEASYPRINT" "$final_html" "$out_pdf"

  echo "  → $out_pdf ($(du -h "$out_pdf" | cut -f1))"
}

# ── Run ───────────────────────────────────────────────────────────────
build "en"    "chapters"        "cover.svg"       "2084.pdf"       "2084"             "Contents"
build "pt-BR" "chapters-pt-BR"  "cover-pt-BR.svg" "2084-pt-BR.pdf" "2084"             "Sumário"

echo ""
echo "Done."
ls -lh 2084.pdf 2084-pt-BR.pdf
