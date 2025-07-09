# Firebase Setup Guide for Naumaniya App

## 🚨 **IMPORTANT: You need to set up Firebase for authentication to work**

The current Firebase configuration contains demo values that won't work for real authentication. Follow these steps to set up your own Firebase project.

## 📋 **Step-by-Step Setup**

### **Step 1: Create Firebase Project**

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Click "Create a project"** or "Add project"
3. **Enter project name**: `naumaniya-app` (or your preferred name)
4. **Enable Google Analytics** (optional but recommended)
5. **Click "Create project"**

### **Step 2: Enable Authentication**

1. **In your Firebase project**, click "Authentication" in the left sidebar
2. **Click "Get started"**
3. **Go to "Sign-in method"** tab
4. **Enable "Email/Password"** authentication:
   - Click on "Email/Password"
   - Toggle "Enable"
   - Click "Save"

### **Step 3: Create Web App**

1. **Go to Project Settings** (gear icon in top left)
2. **Scroll down to "Your apps"** section
3. **Click "Add app"** and select the web icon (</>)
4. **Enter app nickname**: `naumaniya-web`
5. **Click "Register app"**
6. **Copy the configuration** (you'll need this for the next step)

### **Step 4: Update Your Code**

Replace the values in `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY_HERE',
  appId: 'YOUR_ACTUAL_APP_ID_HERE',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID_HERE',
  projectId: 'YOUR_ACTUAL_PROJECT_ID_HERE',
  authDomain: 'YOUR_ACTUAL_AUTH_DOMAIN_HERE',
  storageBucket: 'YOUR_ACTUAL_STORAGE_BUCKET_HERE',
);
```

### **Step 5: Enable Firestore Database**

1. **In Firebase Console**, click "Firestore Database"
2. **Click "Create database"**
3. **Choose "Start in test mode"** (for development)
4. **Select a location** (choose closest to your users)
5. **Click "Done"**

### **Step 6: Set Firestore Rules**

Go to Firestore Database > Rules and update with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read/write requests
    match /users/{userId}/requests/{requestId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write students, teachers, income, expenditure
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🔧 **Alternative: Quick Setup with Firebase CLI**

If you have Node.js installed:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init

# This will automatically generate the correct firebase_options.dart
```

## 📱 **For Mobile Apps**

### **Android Setup**
1. **In Firebase Console**, go to Project Settings
2. **Add Android app** (click Android icon)
3. **Enter package name**: `com.example.naumaniya_new`
4. **Download google-services.json** and place it in `android/app/`
5. **Update android/build.gradle** and `android/app/build.gradle`

### **iOS Setup**
1. **In Firebase Console**, go to Project Settings
2. **Add iOS app** (click iOS icon)
3. **Enter bundle ID**: `com.example.naumaniyaNew`
4. **Download GoogleService-Info.plist** and add to iOS project

## 🧪 **Testing**

After setup:
1. **Run the app**: `flutter run`
2. **Try creating an account** - it should work without API key errors
3. **Test authentication** - login/logout should work properly

## 🚨 **Security Notes**

- **Never commit real API keys** to public repositories
- **Use environment variables** for production
- **Set up proper Firestore rules** before going live
- **Enable authentication methods** you want to use

## 📞 **Need Help?**

If you encounter issues:
1. **Check Firebase Console** for error messages
2. **Verify API key** is correct
3. **Ensure Authentication is enabled**
4. **Check Firestore rules** are properly set

## 🎯 **Next Steps**

Once Firebase is set up:
1. **Test account creation** and login
2. **Add more authentication methods** (Google, Facebook, etc.)
3. **Set up proper security rules**
4. **Configure Cloudinary** for image uploads
5. **Deploy to production**

---

**Remember**: The demo configuration in `firebase_options.dart` will NOT work for real authentication. You must replace it with your actual Firebase project credentials. 