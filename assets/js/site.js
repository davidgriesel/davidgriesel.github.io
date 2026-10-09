(function () {
  'use strict';

  // Filter the project list with chips. The full list is already in the page; nothing is stored.
  var box = document.querySelector('[data-filters]');
  if (box) {
    var cards = Array.prototype.slice.call(document.querySelectorAll('[data-card]'));
    var groups = [{ key: 'tools', title: 'Tools', param: 'tool', cls: 'tool' }, { key: 'skills', title: 'Skills', param: 'skill', cls: 'skill' }];
    var showChips = box.getAttribute('data-chips') !== 'false';
    var query = new URLSearchParams(window.location.search);
    var state = { tools: query.get('tool') || '', skills: query.get('skill') || '' };
    var status = document.createElement('div');
    status.className = 'note filter-status';
    var count = document.createElement('span');
    count.setAttribute('aria-live', 'polite');
    var clear = document.createElement('button');
    clear.type = 'button';
    clear.className = 'filter-clear';
    clear.textContent = box.getAttribute('data-clear') || 'Clear filters';
    clear.addEventListener('click', function () { state.tools = ''; state.skills = ''; apply(); });
    status.appendChild(count);
    status.appendChild(clear);

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
      var chosen = [state.tools, state.skills].filter(Boolean);
      var noun = shown === 1 ? (box.getAttribute('data-noun-one') || '') : (box.getAttribute('data-noun') || '');
      count.textContent = (box.getAttribute('data-showing') || 'Showing') + ' ' + shown + ' ' + noun +
        (chosen.length ? ' ' + (box.getAttribute('data-using') || 'using') + ' ' + chosen.join(' ' + (box.getAttribute('data-and') || 'and') + ' ') : '');
      clear.hidden = chosen.length === 0;
      status.hidden = !showChips && chosen.length === 0;
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
      if (!showChips || !opts.length) return;
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
    box.appendChild(status);
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
    var lockUntil = 0;
    var mark = function (id) {
      if (current === id) return;
      current = id;
      Object.keys(links).forEach(function (k) { if (k === id) links[k].setAttribute('aria-current', 'true'); else links[k].removeAttribute('aria-current'); });
    };
    var observer = new IntersectionObserver(function (entries) {
      if (Date.now() < lockUntil) return;
      entries.forEach(function (e) { if (e.isIntersecting) mark(e.target.id); });
    }, { rootMargin: '0px 0px -70% 0px' });
    heads.forEach(function (h) { observer.observe(h); });
    if (heads.length) mark(heads[0].id);
    // a click marks its section at once, and the end of the page marks the last one
    Object.keys(links).forEach(function (id) { links[id].addEventListener('click', function () { lockUntil = Date.now() + 1000; mark(id); }); });
    window.addEventListener('scroll', function () {
      if (Date.now() < lockUntil) return;
      if (heads.length && window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 4) mark(heads[heads.length - 1].id);
    }, { passive: true });
  }

  // A compact bar (name and navigation) slides in once the full header has scrolled away.
  // On a narrow screen it shows only while the visitor scrolls up.
  var bar = document.querySelector('[data-compact-bar]');
  var header = document.querySelector('.masthead');
  if (bar && header) {
    var lastY = window.scrollY;
    var update = function () {
      var y = window.scrollY;
      var past = y > header.offsetHeight + 40;
      var narrow = window.matchMedia('(max-width: 40rem)').matches;
      var up = y < lastY;
      bar.classList.toggle('show', past && (!narrow || up));
      lastY = y;
    };
    window.addEventListener('scroll', update, { passive: true });
    update();
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
