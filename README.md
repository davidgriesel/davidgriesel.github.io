# davidgriesel.github.io

A static portfolio site built with [Hugo](https://gohugo.io/) (extended edition), served by GitHub Pages. Every project is one content file, tagged by the tools and skills it shows. All text is English; the configuration declares the language and the interface text is in `i18n/en.toml`, so a second language can be added later without changing the templates.

Nothing on the site loads from another server, and the site sets no cookies and stores nothing in the browser.

## Preview and build

```bash
./preview.sh            # preview at http://localhost:1313, including drafts, with the legal notice details from .env
hugo server -D          # the same preview without the details: the legal notice shows placeholders
hugo                    # production build into public/ (no drafts)
tests/check.sh          # build checks
```

A production build stops while a page still holds `[TO WRITE` or `[ENTER`, while a legal notice detail is still a placeholder, or while sample content exists and `allowSamples` is false. A preview does not.

## Add a project

1. Make a folder `content/projects/<short-name>/` with an `index.md` and any images.
2. Fill in the front matter and write the longer explanation below it:

```yaml
---
title: "Customer segmentation with k-means"
hook: "One line saying what it is and why it matters."
topic: "Customer analytics"        # optional small label above the title
accent: teal                       # optional colour; names in data/allowed/accents.yaml, default is ink
date: 2026-10-01
tools: [Python, PostgreSQL]        # names from data/allowed/tools.yaml
skills: [Segmentation]             # names from data/allowed/skills.yaml
links:                             # all optional, each must start with https://
  github: "https://github.com/davidgriesel/<repository>"
  tableau: "https://public.tableau.com/..."
  powerbi: "https://app.powerbi.com/..."
  demo: "https://..."
images:                            # optional; the first is the card image
  - file: overview.png
    alt: "Description of the image for screen readers."
embed: tableau                     # optional; adds a button that loads the Tableau view
draft: true                        # remove to publish
---
```

An entry needs at least one tool or one skill. Colours: ink, orange, teal, blue, plum, olive, rose. The build stops, naming the entry and the name, if a tool or skill is not in the allowed lists, if a link is not `https://`, if an image has no `alt`, or if required fields are missing. To add a new tool or skill, add it to the list in `data/allowed/` first.

## Add a case study

Add a folder `content/case-studies/<short-name>/` with an `index.md` and any images, with `project:` set to the folder name of its project:

```yaml
---
title: "How the problem was approached"
hook: "One line."
project: customer-segmentation-kmeans
date: 2026-10-01
featured: true                     # show on the home page
images:                            # optional, as for a project
  - file: figure.png
    alt: "Description for screen readers."
---
```

The build stops if the project does not exist. The project's card gets a "Case study" badge.

## The tools and skills switch

`showToolsAndSkills` in `hugo.toml` (under `[params]`) is one switch for the tools and skills features. On, the header has a "Tools & Skills" link to `/tools-and-skills/`, the Projects and Case studies lists have filter chips, and `/tools/` and `/skills/` list the names. Off, none of those are shown: the three list pages send a visitor to Projects, and the cards keep only their chips. Project chips still link to the page for that tag, and case-study chips are plain labels. Every tag has its own page either way. A case study takes its tools and skills from its project.

The filter chips on the Projects and Case studies lists are always on. A case study takes its tools and skills from its project.

## Leak check

A pre-commit hook runs `gitleaks` on every commit. Hooks are not committed, so set it up again in any new clone:

```bash
printf '#!/usr/bin/env bash\nexec gitleaks git --pre-commit --staged --redact --verbose\n' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

A pre-push hook runs `tests/check.sh` and refuses the push if any check fails, for example a PDF with leftover metadata or an entry with an unknown tool. Set it up again in any new clone:

```bash
printf '#!/usr/bin/env bash\nroot="$(git rev-parse --show-toplevel)"\n"$root/tests/check.sh" > /tmp/pre-push-check.log 2>&1 || { tail -25 /tmp/pre-push-check.log; echo "checks failed, nothing pushed"; exit 1; }\n' > .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

## Layout

| Path | Holds |
| --- | --- |
| `hugo.toml` | Site settings, the two tag groups, profile links |
| `content/` | Fixed pages, `projects/`, `case-studies/` |
| `data/allowed/` | Allowed tool and skill names |
| `layouts/` | Page templates; `_partials/validate-entry.html` holds the content rules |
| `i18n/en.toml` | Interface text |
| `assets/` | Stylesheet and one small script (filter chips, the section marker on long pages, and the click-to-load Tableau view) |
| `static/` | The resume PDF and the self-hosted fonts, with their licences in `static/fonts/` |
| `tests/check.sh` | Build checks |

## The legal notice details

The provider's name, address, email and telephone number are not stored in the repository. They are read at build time from environment variables, `HUGO_PROVIDER_NAME`, `_STREET`, `_POSTCODE`, `_CITY`, `_EMAIL` and `_PHONE`, and written into the pages as HTML entities.

- **Locally:** copy `.env.example` to `.env` (git ignores it), fill it in and start the preview with `./preview.sh`. Without a `.env` the legal notice shows `ENTER:` placeholders.
- **On GitHub:** the workflow reads repository secrets named `PROVIDER_NAME`, `PROVIDER_STREET`, `PROVIDER_POSTCODE`, `PROVIDER_CITY`, `PROVIDER_EMAIL` and `PROVIDER_PHONE` (Settings, Secrets and variables, Actions). A production build stops while any is missing.

## Sample content and the tests

`content/projects/project-*` and `content/case-studies/case-study-*` are samples for testing the navigation and the pages. They are labelled "Sample", kept out of search engines and the sitemap, and marked `sample: true`. Before launch, delete them and set `allowSamples = false` in `hugo.toml`; the build then stops if any sample remains.

`tests/fixtures/content/` holds draft entries and case studies that exercise every field. The tests copy them into a throwaway copy of the site, so they are not part of the site and survive the removal of the samples.
