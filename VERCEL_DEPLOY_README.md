# AI Assistant Backend - Vercel Deployment

## 🚀 Quick Deploy

### Option 1: Automated Script (Easiest)
```
Double-click: backend\deploy-vercel.bat
```

### Option 2: Manual CLI
```powershell
cd backend
npm install -g vercel
vercel login
vercel
vercel env add DATABASE_URL production
vercel --prod
```

## 📦 Backend Structure

```
backend/
├── config/
│   └── db.js              # Database connection
├── utils/
│   ├── aiEngine.js        # NLP engine
│   ├── queryBuilder.js    # SQL builder
│   └── responseFormatter.js
├── index.js               # Entry point
├── vercel.json            # Vercel config
├── package.json
└── deploy-vercel.bat      # Auto deploy script
```

## 📱 After Deployment

Update Flutter app (`lib/services/ai_chat_service.dart`):
```dart
static const String _backendUrl = 'https://your-app.vercel.app/ai-query';
```

## 📚 Documentation

- **backend/VERCEL_DEPLOYMENT_GUIDE.md** - Complete guide
- **backend/README.md** - Backend documentation
- **VERCEL_DEPLOYMENT_COMPLETE.md** - Summary

## ⚠️ Important

- **Timeout:** 10 seconds (free tier)
- **Cost:** FREE (unlimited)
- **Your queries:** Should work fine ✅

## 🧪 Test After Deploy

```
https://your-app.vercel.app/health
https://your-app.vercel.app/test-db
```

---

**Ready to deploy!** Run: `backend\deploy-vercel.bat`
