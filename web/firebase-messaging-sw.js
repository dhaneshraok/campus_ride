importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyDcIDYfuVZhfDejakXMu0YacHXWjBBMvkk",
    authDomain: "campusride-965c9.firebaseapp.com",
    projectId: "campusride-965c9",
    storageBucket: "campusride-965c9.firebasestorage.app",
    messagingSenderId: "178371494392",
    appId: "1:178371494392:web:c009bae540730a0f53560d",
    measurementId: "G-NJEM902CRV"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle,
        notificationOptions);
});