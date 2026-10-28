importScripts(
  'https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js'
);

importScripts(
  'https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js'
);

const firebaseConfig = {
  apiKey: "AIzaSyDOIK7llrb7RyuKJ3RYC4iHH40M5SLlC0o",
  authDomain: "mercalishuat.firebaseapp.com",
  projectId: "mercalishuat",
  storageBucket: "mercalishuat.firebasestorage.app",
  messagingSenderId: "632587006690",
  appId: "1:632587006690:web:9ee1a61f6824b472e4a4bb"
};

firebase.initializeApp({
  apiKey: 'TU_API_KEY',

  authDomain:
    'TU_PROYECTO.firebaseapp.com',

  projectId:
    'TU_PROJECT_ID',

  storageBucket:
    'TU_STORAGE_BUCKET',

  messagingSenderId:
    'TU_MESSAGING_SENDER_ID',

  appId:
    'TU_APP_ID',
});


// ============================================================
// FIREBASE MESSAGING
// ============================================================

const messaging =
  firebase.messaging();


// ============================================================
// MENSAJES EN SEGUNDO PLANO
// ============================================================

messaging.onBackgroundMessage(
  (message) => {
    console.log(
      'FCM BACKGROUND:',
      message
    );
  }
);