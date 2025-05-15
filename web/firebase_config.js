// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBR2nOiFMWM2hs7PAFSTSMr0cLzEpg7sTI",
  authDomain: "unieventosapp.firebaseapp.com",
  projectId: "unieventosapp",
  storageBucket: "unieventosapp.firebasestorage.app",
  messagingSenderId: "658701940288",
  appId: "1:658701940288:web:85a80ef91d6e375b8c11a5",
  measurementId: "G-8SJ6EPY6Z1"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
