# Firebase Configuration Template

## Copy your Firebase configuration here:

After creating your Firebase project and adding a web app, you'll get a configuration object like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyB1234567890abcdefghijklmnopqrstuvwxyz",
  authDomain: "your-project-name.firebaseapp.com",
  projectId: "your-project-name",
  storageBucket: "your-project-name.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef1234567890"
};
```

## Copy these values to `lib/firebase_options.dart`:

Replace the placeholder values in the `web` section:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'PASTE_YOUR_API_KEY_HERE',
  appId: 'PASTE_YOUR_APP_ID_HERE',
  messagingSenderId: 'PASTE_YOUR_SENDER_ID_HERE',
  projectId: 'PASTE_YOUR_PROJECT_ID_HERE',
  authDomain: 'PASTE_YOUR_AUTH_DOMAIN_HERE',
  storageBucket: 'PASTE_YOUR_STORAGE_BUCKET_HERE',
);
```

## Quick Setup Steps:

1. **Create Firebase Project**: https://console.firebase.google.com/
2. **Add Web App**: Click the web icon (</>) in your project
3. **Copy Config**: Copy the configuration object above
4. **Update firebase_options.dart**: Replace the placeholder values
5. **Enable Authentication**: Go to Authentication → Sign-in method → Enable Email/Password
6. **Create Firestore**: Go to Firestore Database → Create database → Start in test mode
7. **Test**: Run your app and try creating an account

## Your Firebase Values (fill these in):

- **API Key**: `_________________`
- **App ID**: `_________________`
- **Messaging Sender ID**: `_________________`
- **Project ID**: `_________________`
- **Auth Domain**: `_________________`
- **Storage Bucket**: `_________________`

Once you fill these in and update `lib/firebase_options.dart`, your app will be connected to Firebase and your data will be stored in the cloud! 