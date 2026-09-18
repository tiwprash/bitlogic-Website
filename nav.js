document.addEventListener('DOMContentLoaded', function () {
    var toggle = document.querySelector('.nav-toggle');
    var links = document.querySelector('.nav-links');

    if (toggle && links) {
        toggle.addEventListener('click', function () {
            var isOpen = links.classList.toggle('open');
            toggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
        });

        links.querySelectorAll('a:not([href="#"])').forEach(function (link) {
            link.addEventListener('click', function () {
                links.classList.remove('open');
                toggle.setAttribute('aria-expanded', 'false');
            });
        });
    }

    var yearEl = document.getElementById('year');
    if (yearEl) yearEl.textContent = new Date().getFullYear();
});

// Conversion tracking (GA4). Mark `download_click` as a key event in GA4 to
// measure how many visitors go on to install the app.
document.addEventListener('click', function (e) {
    var a = e.target.closest ? e.target.closest('a[href]') : null;
    if (!a || typeof window.gtag !== 'function') return;

    var href = a.getAttribute('href') || '';
    var params = { link_url: a.href, page_path: location.pathname };

    if (href.indexOf('play.google.com') !== -1) {
        params.store = 'google_play';
        window.gtag('event', 'download_click', params);
    } else if (href.indexOf('apps.microsoft.com') !== -1) {
        params.store = 'microsoft_store';
        window.gtag('event', 'download_click', params);
    } else if (/(^|\/)crypto-screener\/?(#.*)?$/.test(href.split('?')[0])) {
        window.gtag('event', 'web_screener_launch', params);
    }
});
