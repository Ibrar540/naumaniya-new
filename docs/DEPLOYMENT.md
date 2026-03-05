# Vercel Deployment Guide - Complete

## ✅ Your Backend is Vercel-Ready!

All necessary files have been created. Your backend is now optimized for Vercel serverless deployment.

---

## 📦 Files Created for Vercel

1. **`vercel.json`** - Vercel configuration
2. **`.vercelignore`** - Files to exclude from deployment
3. **`index.js`** - Serverless entry point (already created)
4. **`VERCEL_DEPLOYMENT_GUIDE.md`** - This file

---

## 🚀 Deploy to Vercel (3 Methods)

### Method 1: Vercel CLI (Fastest - 5 minutes)

#### Step 1: Install Vercel CLI

```powershell
npm install -g vercel
```

#### Step 2: Login to Vercel

```powershell
vercel login
```

This opens your browser for authentication.

#### Step 3: Deploy

```powershell
cd backend
vercel
```

Follow the prompts:
- **Set up and deploy?** Yes
- **Which scope?** Your account
- **Link to existing project?** No
- **Project name?** naumaniya-ai-backend
- **Directory?** ./ (current directory)
- **Override settings?** No

#### Step 4: Add Environment Variables

```powershell
vercel env add DATABASE_URL production
```

Paste your Neon connection string when prompted.

#### Step 5: Deploy to Production

```powershell
vercel --prod
```

#### Step 6: Get Your URL

After deployment, you'll get a URL like:
```
https://naumaniya-ai-backend.vercel.app
```

---

### Method 2: Vercel Dashboard (No CLI - 10 minutes)

#### Step 1: Push to GitHub

```powershell
cd backend
git init
git add .
git commit -m "Vercel deployment"
```

Create a repo on GitHub and push:
```powershell
git remote add origin https://github.com/YOUR_USERNAME/naumaniya-backend.git
git push -u origin main
```

#### Step 2: Import to Vercel

1. Go to: https://vercel.com
2. Click "Add New..." → "Project"
3. Import your GitHub repository
4. Configure:
   - **Framework Preset:** Other
   - **Root Directory:** backend (if you pushed whole project) or ./ (if just backend)
   - **Build Command:** Leave empty
   - **Output Directory:** Leave empty
   - **Install Command:** npm install

#### Step 3: Add Environment Variables

In Vercel dashboard:
1. Go to Project Settings → Environment Variables
2. Add:
   - **Key:** `DATABASE_URL`
   - **Value:** Your Neon connection string
   - **Environment:** Production, Preview, Development

#### Step 4: Deploy

Click "Deploy" - Vercel will build and deploy automatically.

#### Step 5: Get Your URL

After deployment:
```
https://naumaniya-ai-backend.vercel.app
```

---

### Method 3: Vercel GitHub Integration (Automatic)

#### Step 1: Connect GitHub

1. Go to https://vercel.com
2. Sign up/Login with GitHub
3. Grant Vercel access to your repositories

#### Step 2: Import Project

1. Click "Add New..." → "Project"
2. Select your repository
3. Vercel auto-detects settings

#### Step 3: Configure

- Add `DATABASE_URL` environment variable
- Click "Deploy"

#### Step 4: Automatic Deployments

Every push to `main` branch automatically deploys!

---

## ⚙️ Configuration Details

### vercel.json Explained

```json
{
  "version": 2,
  "builds": [
    {
      "src": "index.js",        // Entry point
      "use": "@vercel/node"     // Node.js runtime
    }
  ],
  "routes": [
    {
      "src": "/(.*)",           // All routes
      "dest": "index.js"        // Go to index.js
    }
  ]
}
```

### Environment Variables

Required:
```
DATABASE_URL=postgresql://username:password@host/database?sslmode=require
```

Optional:
```
NODE_ENV=production
```

---

## 🧪 Testing Your Deployment

### Test Health Endpoint

```powershell
curl https://your-app.vercel.app/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-..."
}
```

### Test Database Connection

```powershell
curl https://your-app.vercel.app/test-db
```

Expected response:
```json
{
  "success": true,
  "message": "Database connection successful"
}
```

### Test AI Query

```powershell
curl -X POST https://your-app.vercel.app/ai-query `
  -H "Content-Type: application/json" `
  -d '{\"message\": \"Total income of masjid in 2025\"}'
```

Expected response:
```json
{
  "success": true,
  "intent": "total",
  "result": 450000,
  "message": "💰 Total Income..."
}
```

---

## 📱 Update Flutter App

After deployment, update `lib/services/ai_chat_service.dart`:

```dart
static const String _backendUrl = 'https://your-app.vercel.app/ai-query';
```

Replace `your-app` with your actual Vercel app name.

---

## ⚠️ Vercel Limitations & Solutions

### 1. 10-Second Timeout

**Issue:** Vercel functions timeout after 10 seconds (free tier)

**Impact on Your App:**
- Simple queries: ✅ No problem
- Complex queries: ⚠️ May timeout
- Multiple database calls: ⚠️ May timeout

**Solutions:**
- Optimize queries (already done with parameterized queries)
- Use connection pooling (already implemented)
- Upgrade to Pro plan ($20/month) for 60-second timeout
- Or use Render/Railway (no timeout on free tier)

### 2. Cold Starts

**Issue:** First request after inactivity may be slow (~1-2 seconds)

**Solutions:**
- Acceptable for most use cases
- Pro plan has faster cold starts
- Keep-alive ping (optional)

### 3. Connection Pooling

**Issue:** Serverless functions don't maintain persistent connections

**Solution:** Already handled in `config/db.js` with connection pooling

### 4. Region

**Issue:** Vercel deploys to nearest region by default

**Solution:** 
- Free tier: Automatic region selection
- Pro tier: Choose specific regions

---

## 💡 Optimization Tips

### 1. Reduce Cold Starts

Add this to your Flutter app to keep backend warm:
```dart
// Ping every 5 minutes
Timer.periodic(Duration(minutes: 5), (_) {
  http.get(Uri.parse('https://your-app.vercel.app/health'));
});
```

### 2. Monitor Performance

Check Vercel dashboard for:
- Function execution time
- Error rates
- Bandwidth usage

### 3. Database Connection

Your `config/db.js` already uses connection pooling:
```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 20,
  idleTimeoutMillis: 30000
});
```

This is optimal for Vercel!

---

## 🆚 Vercel vs Other Platforms

| Feature | Vercel | Render | Railway |
|---------|--------|--------|---------|
| **Free Tier** | Unlimited | 750 hrs | 500 hrs |
| **Timeout** | 10s (60s Pro) | None | None |
| **Cold Starts** | Yes (~1-2s) | Yes (~30s) | No |
| **Database** | ⚠️ Serverless | ✅ Persistent | ✅ Persistent |
| **Deployment** | Instant | ~2 min | ~1 min |
| **Best For** | Simple APIs | Complex APIs | All-purpose |

### For Your AI Backend:

**Vercel is good if:**
- ✅ Queries complete in <10 seconds
- ✅ You want instant deployment
- ✅ You want unlimited free tier
- ✅ You're okay with cold starts

**Consider Render/Railway if:**
- ⚠️ Queries take >10 seconds
- ⚠️ You need persistent connections
- ⚠️ You want no timeout limits

---

## 🐛 Troubleshooting

### Deployment Fails

**Check:**
1. `vercel.json` is in backend folder
2. `index.js` exists
3. `package.json` has correct dependencies

**Solution:**
```powershell
vercel --debug
```

### Function Timeout

**Error:** `FUNCTION_INVOCATION_TIMEOUT`

**Solutions:**
1. Optimize database queries
2. Add indexes to database tables
3. Upgrade to Pro plan
4. Or switch to Render/Railway

### Database Connection Fails

**Error:** `Connection refused` or `SSL error`

**Solutions:**
1. Verify DATABASE_URL format
2. Check Neon database is accessible
3. Ensure SSL is configured:
   ```javascript
   ssl: { rejectUnauthorized: false }
   ```

### Environment Variables Not Working

**Solutions:**
1. Add via Vercel dashboard
2. Redeploy after adding variables
3. Check variable names match exactly

### Cold Start Too Slow

**Solutions:**
1. Acceptable for most cases (1-2s)
2. Implement keep-alive ping
3. Upgrade to Pro for faster cold starts

---

## 📊 Monitoring

### Vercel Dashboard

Monitor:
- Function invocations
- Execution time
- Error rates
- Bandwidth usage

### Logs

View logs in Vercel dashboard:
1. Go to your project
2. Click "Deployments"
3. Click on a deployment
4. View "Function Logs"

---

## 🔄 Continuous Deployment

### Automatic Deployments

With GitHub integration:
- Push to `main` → Auto deploy to production
- Push to other branches → Auto deploy to preview

### Manual Deployments

```powershell
vercel --prod
```

---

## 💰 Cost

### Free Tier
- ✅ Unlimited function invocations
- ✅ 100 GB bandwidth/month
- ✅ Automatic HTTPS
- ⚠️ 10-second timeout
- ⚠️ Cold starts

### Pro Tier ($20/month)
- ✅ 60-second timeout
- ✅ Faster cold starts
- ✅ 1 TB bandwidth/month
- ✅ Priority support

**Recommendation:** Start with free tier, upgrade if needed.

---

## ✅ Deployment Checklist

- [ ] Vercel CLI installed
- [ ] Logged in to Vercel
- [ ] Backend deployed
- [ ] DATABASE_URL added
- [ ] Health endpoint tested
- [ ] Database connection tested
- [ ] AI query tested
- [ ] Flutter app URL updated
- [ ] End-to-end test passed

---

## 🚀 Quick Commands Reference

```powershell
# Install CLI
npm install -g vercel

# Login
vercel login

# Deploy
cd backend
vercel

# Add environment variable
vercel env add DATABASE_URL production

# Deploy to production
vercel --prod

# View logs
vercel logs

# Remove deployment
vercel remove
```

---

## 📚 Additional Resources

- Vercel Docs: https://vercel.com/docs
- Node.js on Vercel: https://vercel.com/docs/functions/serverless-functions/runtimes/node-js
- Environment Variables: https://vercel.com/docs/concepts/projects/environment-variables

---

## 🎯 Next Steps

1. ✅ Deploy to Vercel (choose method above)
2. ✅ Test all endpoints
3. ✅ Update Flutter app URL
4. ✅ Test integration
5. ✅ Monitor performance
6. ⏳ Optimize if needed

---

## 💡 Pro Tips

1. **Use Vercel CLI** - Fastest deployment method
2. **Test Locally First** - Run `node index.js` before deploying
3. **Monitor Logs** - Check for timeout issues
4. **Optimize Queries** - Keep execution time <10s
5. **Use Connection Pooling** - Already implemented!

---

## ✅ Status: Ready to Deploy!

Your backend is fully configured for Vercel. Just run:

```powershell
cd backend
vercel
```

And you're live! 🚀

---

**Estimated Deployment Time:** 5 minutes
**Cost:** Free (unlimited)
**Difficulty:** Easy

**Start here:** Run `vercel` command in backend folder!
