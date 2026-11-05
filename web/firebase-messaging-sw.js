importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCho3CbRGc_1s2CrR7DZDOjQRJ09uv86bg',
  appId: '1:299440315883:web:832736ba727c17fb044dae',
  messagingSenderId: '299440315883',
  projectId: 'sirafleet',
  authDomain: 'sirafleet.firebaseapp.com',
  storageBucket: 'sirafleet.firebasestorage.app',
});

const messaging = firebase.messaging();

// Gère les notifs reçues quand l'onglet Chrome est en arrière-plan
// (le navigateur doit rester ouvert, voir la limitation évoquée plus tôt).
messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification || {};
  self.registration.showNotification(title || 'SiraFleet', {
    body: body || '',
    icon: '/icons/Icon-192.png', // adapte si ton icône a un autre chemin
    data: payload.data,
  });
});

// Tap sur la notif → ouvre/reprend l'onglet SiraFleet
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((windowClients) => {
      for (const client of windowClients) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    })
  );
});