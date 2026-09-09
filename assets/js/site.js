/* ============================================================================
   PowerCorp — site behaviour
   No framework, no dependencies, no build step. Everything here degrades to a
   perfectly usable page if it fails to run.
   ========================================================================== */

(function () {
  'use strict';

  /* --- Lore ticker ---------------------------------------------------------
     The lines are authored in content/05-world.md under "## TICKER" and baked
     into the page by build.ps1 as window.PC_LORE. Edit them there, not here. */

  var LORE = window.PC_LORE || [];

  var el = document.getElementById('ticker');
  var reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  if (el && !reduced && LORE.length > 1) {
    var i = 0;
    setInterval(function () {
      // Don't animate a tab nobody is looking at.
      if (document.hidden) { return; }

      el.style.opacity = '0';
      setTimeout(function () {
        i = (i + 1) % LORE.length;
        el.textContent = LORE[i];
        el.style.opacity = '1';
      }, 420);
    }, 5200);
  }

  /* --- Screenshot lightbox -------------------------------------------------
     Built rather than imported: one dependency-free overlay beats a library
     for three images. Closes on click, on Escape, and returns focus. */

  var opener = null;

  function closeBox() {
    var box = document.getElementById('lightbox');
    if (!box) { return; }
    box.remove();
    document.removeEventListener('keydown', onKey);
    if (opener) { opener.focus(); opener = null; }
  }

  function onKey(e) {
    if (e.key === 'Escape') { closeBox(); }
  }

  function openBox(src, alt) {
    closeBox();

    var box = document.createElement('div');
    box.id = 'lightbox';
    box.setAttribute('role', 'dialog');
    box.setAttribute('aria-modal', 'true');
    box.setAttribute('aria-label', alt || 'Screenshot');
    box.style.cssText =
      'position:fixed;inset:0;z-index:90;display:flex;align-items:center;' +
      'justify-content:center;padding:5vmin;background:rgba(12,13,18,0.94);' +
      'cursor:zoom-out;';

    var img = document.createElement('img');
    img.src = src;
    img.alt = alt || '';
    img.style.cssText =
      'max-width:100%;max-height:100%;border:1px solid rgba(255,179,71,0.18);' +
      'border-radius:3px;';

    box.appendChild(img);
    box.addEventListener('click', closeBox);
    document.body.appendChild(box);
    document.addEventListener('keydown', onKey);
    box.focus();
  }

  var frames = document.querySelectorAll('.media-grid .frame');
  Array.prototype.forEach.call(frames, function (frame) {
    var img = frame.querySelector('img');
    if (!img) { return; }

    frame.style.cursor = 'zoom-in';
    frame.tabIndex = 0;
    frame.setAttribute('role', 'button');
    frame.setAttribute('aria-label', 'Enlarge: ' + (img.alt || 'screenshot'));

    function fire() {
      opener = frame;
      openBox(img.currentSrc || img.src, img.alt);
    }

    frame.addEventListener('click', fire);
    frame.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); fire(); }
    });
  });
}());
