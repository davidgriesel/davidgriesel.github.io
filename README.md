# davidgriesel.github.io

This repository contains the source files for my personal portfolio website. The site is designed to be hosted on GitHub Pages and showcases my work as a data analyst, including projects, a downloadable portfolio, and contact information.

## Repository Structure

```
index.html          # Homepage with introduction and links
about.html          # "About Me" page
portfolio.html      # Downloadable portfolio PDF and overview
bi.html             # Embedded business intelligence report (Power BI dashboard)
projects.html       # List of project summaries with thumbnails
project_template.html # Template for individual project pages
resume.html         # Link to downloadable resume
contact.html        # Contact form and information
style.css           # Shared stylesheet
images/             # Thumbnails, profile photo, etc.
docs/               # PDF assets (portfolio.pdf, resume.pdf)
```

## Development

Just edit the HTML/CSS files in this directory. The site uses only static assets so no server or build step is required; you can open any `.html` file in a browser to preview changes.

### Adding a Project

1. Duplicate `project_template.html` and modify the contents for your new project.
2. Save the file with a descriptive name like `202501_NewProject.html`.
3. Add an entry in `projects.html` (a list item with thumbnail and link) so the project appears on the Projects page.
4. Place any associated images under `images/` and update the `<img>` tags accordingly.

### Contact Page

A simple contact form is already provided in `contact.html` (for static hosting, you'll need to wire it up to a service like Formspree, Netlify Forms, or similar if you want submissions to be emailed).

## Deploying with GitHub Pages

1. Create a new repository named `davidgriesel.github.io` (replace `davidgriesel` with your GitHub username). Clone it locally or move these files into the repository folder.
2. Commit all the files and push to the `main` (or `gh-pages`) branch:
   ```bash
   git init
   git add .
   git commit -m "Initial portfolio website"
   git remote add origin git@github.com:davidgriesel/davidgriesel.github.io.git
   git push -u origin main
   ```
3. GitHub Pages will automatically serve the `main` branch at `https://davidgriesel.github.io/` within a minute or two.
4. To use a custom domain, add a `CNAME` file at the repository root containing your domain and configure DNS accordingly.

## License

Feel free to reuse or adapt the HTML/CSS for your own portfolio; no formal license is applied here.