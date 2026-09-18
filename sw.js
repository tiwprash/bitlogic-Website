// Legacy service worker left over from a removed third-party ad integration.
// It no longer loads any third-party code; it simply unregisters itself so that
// browsers which registered the old worker are cleaned up on their next visit.
self.addEventListener('install', function () {
    self.skipWaiting();
});

self.addEventListener('activate', function (event) {
    event.waitUntil(self.registration.unregister());
});
