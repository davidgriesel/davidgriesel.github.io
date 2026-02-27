# Data Analyst Portfolio (Jekyll + GitHub Pages)

A clean, responsive portfolio site built with Jekyll and plain HTML/CSS for GitHub Pages.

## Local development

1. Install Ruby and Bundler.
2. Install dependencies:

```bash
bundle install
```

3. Run locally:

```bash
bundle exec jekyll serve
```

4. Open `http://127.0.0.1:4000`.

## Deploy to GitHub Pages

1. Push this repository to GitHub.
2. In GitHub, open `Settings` -> `Pages`.
3. Under `Build and deployment`, choose `Deploy from a branch`.
4. Select `main` branch and `/ (root)` folder.
5. Save. Your site will publish at `https://<username>.github.io/<repo>/` (or your custom domain if configured).

## Edit content

- Homepage hero and section copy: [`index.html`](index.html)
- Project data source for cards: [`_data/projects.yml`](_data/projects.yml)
- Projects list template: [`projects/index.md`](projects/index.md)
- Individual project pages: files in [`projects/`](projects/)
- Skills page: [`skills/index.md`](skills/index.md)
- Resume page: [`resume/index.md`](resume/index.md)
- Global styles: [`assets/css/main.css`](assets/css/main.css)
- Navigation/footer layout: [`_includes/header.html`](_includes/header.html), [`_includes/footer.html`](_includes/footer.html)
- Site-wide settings: [`_config.yml`](_config.yml)

## Replace me checklist

- `your-github-username`
  - Files: `_config.yml`, `_data/projects.yml`, footer GitHub links
- `your.email@example.com`
  - File: `_config.yml` (used for contact mailto link)
- `https://www.linkedin.com/in/your-linkedin-handle`
  - File: `_config.yml`
- Hero image
  - File path currently used: `assets/images/hero-data.svg`
  - Update in: `_config.yml` (`hero_image`) and `assets/css/main.css` (`.hero` background URL)
- Project card images
  - File paths in `_data/projects.yml` under `image`
- Resume PDF placeholder
  - Add your PDF to `assets/resume/your-name-resume.pdf`
  - Update link in `resume/index.md` as needed

## Notes

- No backend is required.
- No external CSS framework is used.
- Minimal JavaScript is used (none by default).
