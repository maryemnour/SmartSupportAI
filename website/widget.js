(function () {
  'use strict';

  var script  = document.currentScript || (function () {
    var scripts = document.getElementsByTagName('script');
    return scripts[scripts.length - 1];
  })();

  var API_KEY     = script.getAttribute('data-key')     || '';
  var POSITION    = script.getAttribute('data-position') || 'right';
  var COLOR       = script.getAttribute('data-color')    || '#6366F1';
  var CHAT_ORIGIN = script.getAttribute('data-origin')   || 'https://smartsupport-website.vercel.app';

  if (!API_KEY) {
    console.warn('[SmartSupport] No data-key provided. Widget not loaded.');
    return;
  }

  var isOpen = false, hasOpened = false;

  function css(el, styles) { Object.assign(el.style, styles); }

  function darken(hex, amount) {
    var num = parseInt(hex.replace('#', ''), 16);
    var r = Math.max(0, (num >> 16) - amount);
    var g = Math.max(0, ((num >> 8) & 0xff) - amount);
    var b = Math.max(0, (num & 0xff) - amount);
    return '#' + ((r << 16) | (g << 8) | b).toString(16).padStart(6, '0');
  }

  var darkColor = darken(COLOR, 30);
  var side      = POSITION === 'left' ? 'left' : 'right';

  var styleTag = document.createElement('style');
  styleTag.textContent = [
    '#ss-btn{position:fixed;' + side + ':24px;bottom:24px;z-index:999998;',
    'width:56px;height:56px;border-radius:50%;border:none;cursor:pointer;',
    'display:flex;align-items:center;justify-content:center;',
    'box-shadow:0 4px 20px rgba(0,0,0,.25);transition:transform .2s,box-shadow .2s;}',
    '#ss-btn:hover{transform:scale(1.08);box-shadow:0 6px 28px rgba(0,0,0,.3);}',
    '#ss-btn svg{position:absolute;transition:opacity .2s,transform .2s;}',
    '#ss-btn .ss-close{opacity:0;transform:rotate(-90deg);}',
    '#ss-btn.open .ss-chat{opacity:0;transform:rotate(90deg);}',
    '#ss-btn.open .ss-close{opacity:1;transform:rotate(0);}',
    '#ss-badge{position:absolute;top:-3px;right:-3px;background:#EF4444;color:#fff;',
    'border-radius:50%;width:18px;height:18px;font-size:11px;font-weight:700;',
    'display:flex;align-items:center;justify-content:center;',
    'font-family:system-ui,sans-serif;border:2px solid #fff;}',
    '#ss-panel{position:fixed;' + side + ':16px;bottom:92px;z-index:999997;',
    'width:380px;height:600px;max-height:calc(100vh - 110px);',
    'border-radius:16px;overflow:hidden;',
    'box-shadow:0 8px 40px rgba(0,0,0,.22);',
    'transition:opacity .25s,transform .25s;',
    'opacity:0;pointer-events:none;transform:translateY(16px) scale(.97);}',
    '#ss-panel.open{opacity:1;pointer-events:all;transform:translateY(0) scale(1);}',
    '#ss-panel iframe{width:100%;height:100%;border:none;display:block;}',
    '@media(max-width:440px){',
    '#ss-panel{width:calc(100vw - 16px);' + side + ':8px;bottom:80px;height:calc(100vh - 100px);border-radius:12px;}}',
  ].join('');
  document.head.appendChild(styleTag);

  var btn = document.createElement('button');
  btn.id  = 'ss-btn';
  css(btn, { background: COLOR });

  var iconChat = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  iconChat.setAttribute('class', 'ss-chat');
  iconChat.setAttribute('viewBox', '0 0 24 24');
  iconChat.setAttribute('width', '26');
  iconChat.setAttribute('height', '26');
  iconChat.setAttribute('fill', 'none');
  iconChat.setAttribute('stroke', 'white');
  iconChat.setAttribute('stroke-width', '2');
  iconChat.setAttribute('stroke-linecap', 'round');
  iconChat.setAttribute('stroke-linejoin', 'round');
  iconChat.innerHTML = '<path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/>';

  var iconClose = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  iconClose.setAttribute('class', 'ss-close');
  iconClose.setAttribute('viewBox', '0 0 24 24');
  iconClose.setAttribute('width', '24');
  iconClose.setAttribute('height', '24');
  iconClose.setAttribute('fill', 'none');
  iconClose.setAttribute('stroke', 'white');
  iconClose.setAttribute('stroke-width', '2.5');
  iconClose.setAttribute('stroke-linecap', 'round');
  iconClose.innerHTML = '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>';

  var badge = document.createElement('span');
  badge.id  = 'ss-badge';
  badge.textContent = '1';
  badge.style.display = 'none';

  btn.appendChild(iconChat);
  btn.appendChild(iconClose);
  btn.appendChild(badge);

  var panel = document.createElement('div');
  panel.id  = 'ss-panel';

  function toggle() {
    isOpen = !isOpen;
    if (isOpen) {
      badge.style.display = 'none';
      if (!hasOpened) {
        hasOpened = true;
        var iframe = document.createElement('iframe');
        iframe.src = CHAT_ORIGIN + '/chat?key=' + encodeURIComponent(API_KEY);
        iframe.setAttribute('allow', 'microphone');
        iframe.setAttribute('title', 'Smart Support Chat');
        panel.appendChild(iframe);
      }
      panel.classList.add('open');
      btn.classList.add('open');
    } else {
      panel.classList.remove('open');
      btn.classList.remove('open');
    }
  }

  btn.addEventListener('click', toggle);

  document.addEventListener('click', function (e) {
    if (isOpen && !panel.contains(e.target) && e.target !== btn && !btn.contains(e.target)) toggle();
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && isOpen) toggle();
  });

  document.body.appendChild(btn);
  document.body.appendChild(panel);

  setTimeout(function () {
    if (!hasOpened && !isOpen) badge.style.display = 'flex';
  }, 8000);

  window.SmartSupport = {
    open:   function () { if (!isOpen) toggle(); },
    close:  function () { if (isOpen)  toggle(); },
    toggle: toggle,
  };

})();
