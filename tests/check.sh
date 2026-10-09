#!/usr/bin/env bash
# Build checks. Run from anywhere: tests/check.sh
# Each check builds the site (or a throwaway copy of it) and expects a result.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0

ok()   { echo "  ok   $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL $1"; fail=$((fail+1)); }

copy_site() {
  local dest="$tmp/$1"; mkdir -p "$dest"
  rsync -a --exclude .git --exclude public --exclude resources "$root"/ "$dest"/
  # fixtures: draft entries and case studies that exercise every field; they are not part of the site
  [ -d "$root/tests/fixtures/content" ] && rsync -a "$root/tests/fixtures/content/" "$dest/content/"
  echo "$dest"
}

# expect_fail <name> <dir> <text the error must contain>
expect_fail() {
  local out
  out="$(cd "$2" && hugo --environment "${4:-test}" -D --destination "$2/out" 2>&1)"
  if [ $? -ne 0 ] && echo "$out" | grep -q "$3"; then ok "$1"; else bad "$1"; echo "$out" | tail -5; fi
}

echo "Good site builds with drafts"
d="$(copy_site good)"
# the tools and skills features are switched on for these checks, whatever the site setting is
if (cd "$d" && HUGO_PARAMS_SHOWTOOLSANDSKILLS=true hugo --environment test -D --destination "$d/out" >/dev/null 2>&1); then ok "build succeeds"; else bad "build succeeds"; fi
site="$d/out"

echo "Built pages"
[ -f "$site/projects/sample-entry/index.html" ] && ok "entry page exists" || bad "entry page exists"
[ -f "$site/tools/python/index.html" ] && ok "tool page exists" || bad "tool page exists"
[ -f "$site/skills/dashboard-design/index.html" ] && ok "skill page exists" || bad "skill page exists"
[ -f "$site/david-griesel-cv.pdf" ] && grep -q "david-griesel-cv.pdf" "$site/about/index.html" && ok "resume is linked from the about page and present" || bad "resume is linked from the about page and present"
grep -q "Sample case study" "$site/index.html" && ok "featured case study is on the home page" || bad "featured case study is on the home page"
grep -Eq 'class="?badge' "$site/projects/index.html" && ok "case-study badge is on the card" || bad "case-study badge is on the card"
footer_ok=1
for f in "$site/index.html" "$site/about/index.html" "$site/projects/index.html" "$site/projects/sample-entry/index.html" "$site/tools/python/index.html" "$site/404.html"; do
  if ! { grep -q "/legal-notice/" "$f" && grep -q "/privacy/" "$f"; }; then footer_ok=0; echo "       missing in $f"; fi
done
[ "$footer_ok" -eq 1 ] && ok "legal and privacy links are in the footer of every page type" || bad "legal and privacy links are in the footer of every page type"

echo "PDF files carry no identifying metadata"
pdf_check() {  # prints the fields that still hold a value
  python3 - "$1" <<'PY'
import re, sys
b = open(sys.argv[1], "rb").read()
bad = []
for key in (b"Creator", b"Producer", b"Subject", b"Keywords"):
    m = re.search(rb"/" + key + rb"\s*\(((?:\\.|[^)\\])*)\)", b)
    if m and m.group(1).strip():
        bad.append(key.decode())
if b"/Metadata" in b:
    bad.append("XMP")
print(" ".join(bad))
PY
}
pdf_ok=1
for f in "$root"/static/*.pdf; do
  [ -e "$f" ] || continue
  left="$(pdf_check "$f")"
  if [ -n "$left" ]; then pdf_ok=0; echo "       $f still has: $left"; fi
done
[ "$pdf_ok" -eq 1 ] && ok "every PDF in static/ has blank Creator, Producer, Subject and Keywords" || bad "every PDF in static/ has blank Creator, Producer, Subject and Keywords"
# the check must catch a dirty file: put a creator back into a copy
d="$(copy_site dirty-pdf)"
python3 - "$d" <<'PY'
import sys, re, glob
p = glob.glob(sys.argv[1] + "/static/*.pdf")[0]
b = bytearray(open(p, "rb").read())
m = re.search(rb"/Creator\s*\(", bytes(b))
b[m.end():m.end() + 4] = b"Word"
open(p, "wb").write(bytes(b))
PY
dirty="$(pdf_check "$(ls "$d"/static/*.pdf | head -1)")"
[ "$dirty" = "Creator" ] && ok "the check catches a PDF with a creator set" || bad "the check catches a PDF with a creator set"

echo "Legal notice details come from the environment and are written as entities"
d="$(copy_site details)"
export HUGO_PROVIDER_NAME="Testa Persona" HUGO_PROVIDER_STREET="Teststrasse 12" HUGO_PROVIDER_POSTCODE="12345" HUGO_PROVIDER_CITY="Testburg" HUGO_PROVIDER_EMAIL="test@example.invalid" HUGO_PROVIDER_PHONE="+49 100 0000 0000"
if (cd "$d" && hugo --environment test -D --destination "$d/out" >/dev/null 2>&1); then
  details_ok=1
  for value in "Testa Persona" "Teststrasse" "12345" "test@example.invalid" "+49 100 0000 0000"; do
    if grep -rqF "$value" "$d/out/legal-notice/index.html" "$d/out/index.html"; then details_ok=0; echo "       found as plain text: $value"; fi
  done
  [ "$details_ok" -eq 1 ] && ok "name, street, postcode, email and phone are not in the HTML as plain text" || bad "legal notice details are written as entities"
  grep -q "&#" "$d/out/legal-notice/index.html" && ok "entities are present in the legal notice" || bad "entities are present in the legal notice"
  # decoded, the values must be there: a browser shows them
  python3 - "$d/out/legal-notice/index.html" <<'PY' && ok "the entities decode to the details" || bad "the entities decode to the details"
import html, sys
t = html.unescape(open(sys.argv[1]).read())
sys.exit(0 if all(v in t for v in ("Testa Persona", "Teststrasse 12", "12345 Testburg", "test@example.invalid", "+49 100 0000 0000")) else 1)
PY
else bad "build with the details from the environment succeeds"; fi
unset HUGO_PROVIDER_NAME HUGO_PROVIDER_STREET HUGO_PROVIDER_POSTCODE HUGO_PROVIDER_CITY HUGO_PROVIDER_EMAIL HUGO_PROVIDER_PHONE
grep -qE "Johan|Hartwig|Hesse|contact@davidgriesel|[0-9]{5} Hamburg" "$root/content/legal-notice.md" && bad "no personal details are stored in content/legal-notice.md" || ok "no personal details are stored in content/legal-notice.md"

echo "Only tools and skills with a project behind them are listed"
if grep -q "Machine learning" "$site/about/index.html" "$site/tools-and-skills/index.html" "$site/projects/index.html"; then bad "a skill without a project is not listed"; else ok "a skill without a project is not listed"; fi
grep -q "Skills and tools" "$site/about/index.html" && ok "the about page lists the tools and skills in use" || bad "the about page lists the tools and skills in use"
d="$(copy_site no-drafts)"
rm -rf "$d"/content/projects/project-* "$d"/content/case-studies/case-study-*
if (cd "$d" && hugo --environment test --destination "$d/out" >/dev/null 2>&1); then
  grep -q "Skills and tools" "$d/out/about/index.html" && bad "no list appears when no project is published" || ok "no list appears when no project is published"
else bad "build without drafts succeeds"; fi

echo "Navigation and tag links"
nav_ok=1
check_nav() {  # file, expected href, expected aria-current value
  grep -Eq "<a href=\"?$2\"? aria-current=\"?$3\"?" "$1" || { nav_ok=0; echo "       $1: $2 is not marked $3"; }
}
check_nav "$site/projects/index.html" "/projects/" page
check_nav "$site/projects/sample-entry/index.html" "/projects/" true
check_nav "$site/case-studies/index.html" "/case-studies/" page
check_nav "$site/case-studies/sample-entry/index.html" "/case-studies/" true
check_nav "$site/tools-and-skills/index.html" "/tools-and-skills/" page
check_nav "$site/tools/python/index.html" "/tools-and-skills/" true
check_nav "$site/about/index.html" "/about/" page
[ "$(grep -c aria-current "$site/index.html")" -eq 0 ] && true || { nav_ok=0; echo "       the home page marks a nav item"; }
[ "$nav_ok" -eq 1 ] && ok "the current page or section is marked in the header (aria-current)" || bad "the current page or section is marked in the header (aria-current)"
grep -q "data-filters" "$site/projects/index.html" && grep -q "data-filters" "$site/case-studies/index.html" && ok "filters appear on the projects and case studies lists" || bad "filters appear on the projects and case studies lists"
grep -q 'data-tools="Python"' "$site/case-studies/index.html" && ok "case study cards carry the tags of their project" || bad "case study cards carry the tags of their project"
grep -q "Case studies with this tag" "$site/tools/python/index.html" && bad "a tag page lists projects only" || ok "a tag page lists projects only"
grep -q 'href="/case-studies/?tool=Python"' "$site/case-studies/index.html" && ok "case study chips filter the case studies list" || bad "case study chips filter the case studies list"
grep -q 'href="https://example.com/github"' "$site/case-studies/sample-entry/index.html" && ok "a case study shows its project's links in the header" || bad "a case study shows its project's links in the header"
grep -q "Browse by" "$site/index.html" && bad "the home page has no browse lists" || ok "the home page has no browse lists"

echo "The tools and skills switch"
d="$(copy_site tags-off)"
if (cd "$d" && HUGO_PARAMS_SHOWTOOLSANDSKILLS=false hugo --environment test -D --destination "$d/out" >/dev/null 2>&1); then
  o="$d/out"
  if grep -q 'href="/tools-and-skills/"' "$o/index.html"; then bad "the header link disappears when switched off"; else ok "the header link disappears when switched off"; fi
  if grep -q "data-filters" "$o/projects/index.html" "$o/case-studies/index.html"; then bad "the filters disappear when switched off"; else ok "the filters disappear when switched off"; fi
  grep -q 'http-equiv="\?refresh' "$o/tools-and-skills/index.html" && grep -q 'http-equiv="\?refresh' "$o/tools/index.html" && grep -q 'http-equiv="\?refresh' "$o/skills/index.html" \
    && ok "the Tools & Skills page and the index pages send a visitor to Projects" || bad "the Tools & Skills page and the index pages send a visitor to Projects"
  if grep -q 'href="/case-studies/?tool=' "$o/case-studies/index.html"; then bad "case study chips are plain labels when switched off"; else ok "case study chips are plain labels when switched off"; fi
  grep -q 'href="/tools/python/"' "$o/projects/index.html" && ok "project chips still link to their tag page" || bad "project chips still link to their tag page"
else bad "build with the switch off succeeds"; fi
grep -q 'href="/tools-and-skills/"' "$site/index.html" && ok "the header link appears when switched on" || bad "the header link appears when switched on"
grep -q 'http-equiv="\?refresh' "$site/tools-and-skills/index.html" && bad "the Tools & Skills page does not redirect when switched on" || ok "the Tools & Skills page does not redirect when switched on"

echo "Drafts stay out of a production build"
d="$(copy_site prod)"
if (cd "$d" && HUGO_PROVIDER_NAME="Testa Persona" HUGO_PROVIDER_STREET="Teststrasse 12" HUGO_PROVIDER_POSTCODE="12345" HUGO_PROVIDER_CITY="Testburg" HUGO_PROVIDER_EMAIL="test@example.invalid" HUGO_PROVIDER_PHONE="+49 100 0000 0000" hugo --environment production --destination "$d/out" >/dev/null 2>&1); then
  [ ! -d "$d/out/projects/sample-entry" ] && ok "draft entries are not built" || bad "draft entries are not built"
  [ -d "$d/out/projects/project-1" ] && ok "published samples are built" || bad "published samples are built"
else bad "production build with the details set succeeds"; fi
d="$(copy_site no-details)"
expect_fail "a production build stops while the legal notice details are missing" "$d" 'still a placeholder' production

echo "Sample content"
grep -q 'badge sample' "$site/projects/index.html" && ok "sample cards are labelled" || bad "sample cards are labelled"
grep -q 'name="robots" content="noindex"' "$site/projects/project-1/index.html" && ok "sample pages are kept out of search engines" || bad "sample pages are kept out of search engines"
grep -q "project-1" "$site/sitemap.xml" && bad "sample pages are left out of the sitemap" || ok "sample pages are left out of the sitemap"
d="$(copy_site no-samples)"
sed -i.bak 's/allowSamples = true/allowSamples = false/' "$d/hugo.toml"
expect_fail "the build stops when samples are not allowed" "$d" 'Sample content is still present'

echo "Rules that must stop the build"
d="$(copy_site unknown-tool)"
sed -i.bak 's/  - Python/  - Pyhton/' "$d/content/projects/sample-entry/index.md"
expect_fail "unknown tool" "$d" 'unknown tool "Pyhton"'

d="$(copy_site unknown-skill)"
sed -i.bak 's/  - Dashboard design/  - dashboard design/' "$d/content/projects/sample-entry/index.md"
expect_fail "unknown skill (case differs)" "$d" 'unknown skill "dashboard design"'

d="$(copy_site no-tags)"
python3 - "$d" <<'PY'
import sys, re
p = sys.argv[1] + "/content/projects/sample-entry/index.md"
t = open(p).read()
t = re.sub(r"tools:\n(  - .*\n)+", "", t)
t = re.sub(r"skills:\n(  - .*\n)+", "", t)
open(p, "w").write(t)
PY
expect_fail "entry with no tool or skill" "$d" "needs at least one tool or one skill"

d="$(copy_site bad-project)"
sed -i.bak 's/^project: sample-entry/project: no-such-entry/' "$d/content/case-studies/sample-entry/index.md"
expect_fail "case study naming a missing project" "$d" 'which does not exist'

d="$(copy_site bad-accent)"
sed -i.bak 's/^accent: orange/accent: purple/' "$d/content/projects/sample-entry/index.md"
expect_fail "unknown accent colour" "$d" 'unknown accent "purple"'

d="$(copy_site bad-link)"
sed -i.bak 's#github: "https://example.com/github"#github: "http://example.com/github"#' "$d/content/projects/sample-entry/index.md"
expect_fail "link without https" "$d" 'must start with https'

d="$(copy_site placeholder)"
echo "[TO WRITE: a test marker]" >> "$d/content/about.md"
expect_fail "unfinished marker stops a production build" "$d" 'unfinished marker' production

echo "No requests to other servers, no cookies, no storage"
bad_ext="$(grep -rEho '<(script|link|img|iframe|source)[^>]+(src|href)=["'"'"']?(https?:)?//[^ >]+' "$site" | grep -Ev 'rel="?canonical' | head -3)"
[ -z "$bad_ext" ] && ok "no external script, stylesheet, image or frame" || { bad "external resource found"; echo "$bad_ext"; }
if grep -rEq 'document\.cookie|localStorage|sessionStorage' "$site" --include='*.js' --include='*.html'; then bad "script uses cookies or storage"; else ok "no cookies or storage in scripts"; fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
