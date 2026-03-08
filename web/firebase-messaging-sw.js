// This file is required by Firebase Cloud Messaging on the Web.
// Even if it is empty, its presence prevents the "unsupported MIME type ('text/html')" error 
// because Flutter will serve it as a valid Javascript file instead of falling back to index.html.

self.addEventListener("install", (event) => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});
