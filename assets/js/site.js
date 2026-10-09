(function () {
  'use strict';

  // Filter the project list with chips. The full list is already in the page; nothing is stored.
  var box = document.querySelector('[data-filters]');
  if (box) {
    var cards = Array.prototype.slice.call(document.querySelectorAll('[data-card]'));
    var groups = [{ key: 'tools', title: 'Tools', param: 'tool', cls: 'tool' }, { key: 'skills', title: 'Skills', param: 'skill', cls: 'skill' }];
    var query = new URLSearchParams(window.location.search);
    var state = { tools: query.get('tool') || '', skills: query.get('skill') || '' };
    var count = document.createElement('p');
    count.className = 'note';
    count.setAttribute('aria-live', 'polite');

    var values = function (key) {
      var seen = {};
      cards.forEach(function (c) {
        (c.getAttribute('data-' + key) || '').split('|').forEach(function (v) { if (v) seen[v] = true; });
      });
      return Object.keys(seen).sort(function (a, b) { return a.localeCompare(b); });
    };

    var apply = function () {
      var shown = 0;
      cards.forEach(function (c) {
        var ok = groups.every(function (g) {
          return !state[g.key] || (c.getAttribute('data-' + g.key) || '').split('|').indexOf(state[g.key]) !== -1;
        });
        c.hidden = !ok;
        if (ok) shown++;
      });
      count.textContent = shown + ' shown';
      var next = new URLSearchParams();
      groups.forEach(function (g) { if (state[g.key]) next.set(g.param, state[g.key]); });
      var qs = next.toString();
      if (window.history && history.replaceState) history.replaceState(null, '', window.location.pathname + (qs ? '?' + qs : ''));
      Array.prototype.forEach.call(box.querySelectorAll('.chip'), function (b) {
        b.setAttribute('aria-pressed', String(state[b.getAttribute('data-key')] === b.getAttribute('data-value')));
      });
    };

    groups.forEach(function (g) {
      var opts = values(g.key);
      if (!opts.length) return;
      var row = document.createElement('div');
      row.className = 'filter-group';
      row.setAttribute('role', 'group');
      row.setAttribute('aria-label', g.title);
      var make = function (value, text) {
        var b = document.createElement('button');
        b.type = 'button';
        b.className = 'chip ' + g.cls;
        b.textContent = text;
        b.setAttribute('data-key', g.key);
        b.setAttribute('data-value', value);
        b.setAttribute('aria-pressed', 'false');
        b.addEventListener('click', function () { state[g.key] = value; apply(); });
        row.appendChild(b);
      };
      make('', 'All');
      opts.forEach(function (v) { make(v, v); });
      box.appendChild(row);
    });
    box.appendChild(count);
    box.hidden = false;
    apply();
  }

  // Mark the section being read in the table of contents on long pages.
  var toc = document.querySelector('.toc nav');
  if (toc && 'IntersectionObserver' in window) {
    var links = {};
    Array.prototype.forEach.call(toc.querySelectorAll('a[href^="#"]'), function (a) { links[a.getAttribute('href').slice(1)] = a; });
    var heads = Object.keys(links).map(function (id) { return document.getElementById(id); }).filter(Boolean);
    var current = null;
    var mark = function (id) {
      if (current === id) return;
      current = id;
      Object.keys(links).forEach(function (k) { if (k === id) links[k].setAttribute('aria-current', 'true'); else links[k].removeAttribute('aria-current'); });
    };
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { if (e.isIntersecting) mark(e.target.id); });
    }, { rootMargin: '0px 0px -70% 0px' });
    heads.forEach(function (h) { observer.observe(h); });
    if (heads.length) mark(heads[0].id);
  }

  // Load an embedded Tableau Public view only when the visitor asks for it.
  Array.prototype.forEach.call(document.querySelectorAll('[data-embed-src]'), function (el) {
    var btn = el.querySelector('[data-embed-load]');
    if (!btn) return;
    btn.addEventListener('click', function () {
      var frame = document.createElement('iframe');
      frame.src = el.getAttribute('data-embed-src');
      frame.title = document.title;
      frame.loading = 'lazy';
      el.innerHTML = '';
      el.appendChild(frame);
    });
  });
})();
