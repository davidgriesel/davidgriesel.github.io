---
layout: default
title: Projects
description: Data projects spanning dashboards, forecasting, and cohort analysis.
---

<section class="section-band band-projects">
  <div class="container">
    <h1 class="section-heading">Projects</h1>
    <p class="section-lead">Selected analysis work with methods, outcomes, and practical implementation detail.</p>

    <div class="grid cards-3">
      {% for project in site.data.projects %}
        <article class="card">
          <img src="{{ project.image | default: site.project_defaults_image | relative_url }}" alt="Screenshot for {{ project.title }}">
          <div class="card-content">
            <h2>{{ project.title }}</h2>
            <p>{{ project.description }}</p>
            <div class="tag-list" aria-label="Project tags">
              {% for tag in project.tags %}
                <span class="tag">{{ tag }}</span>
              {% endfor %}
            </div>
            {% if project.links.detail or project.links.repository %}
              <div class="inline-links">
                {% if project.links.detail %}
                  <a href="{% if project.links.detail contains '://' %}{{ project.links.detail }}{% else %}{{ project.links.detail | relative_url }}{% endif %}">Project Page</a>
                {% endif %}
                {% if project.links.repository %}
                  <a href="{{ project.links.repository }}">Repository</a>
                {% endif %}
              </div>
            {% endif %}
          </div>
        </article>
      {% endfor %}
    </div>
  </div>
</section>
