# BunkBite Website - Deployment Guide

This guide will help you deploy the BunkBite support website to satisfy App Store Guideline 1.5.

## Quick Start

The fastest way to deploy is using Vercel (free):

```bash
cd bunkbite-website
npm run build
npx vercel --prod
```

## Deployment Options

### Option 1: Vercel (Recommended - Easiest)

**Why Vercel?**
- Free hosting
- Automatic HTTPS
- Custom domain support
- Instant deployments
- Zero configuration needed

**Steps:**

1. Create a Vercel account at https://vercel.com

2. Install Vercel CLI:
```bash
npm install -g vercel
```

3. Build and deploy:
```bash
cd bunkbite-website
npm run build
vercel --prod
```

4. Follow prompts:
   - Login to your Vercel account
   - Name your project: `bunkbite-support`
   - Deploy!

5. Vercel will give you a URL like: `https://bunkbite-support.vercel.app`

6. **(Optional) Add custom domain:**
   - Go to Vercel dashboard → your project → Settings → Domains
   - Add: `support.bunkbite.me` or `bunkbite.me`
   - Follow DNS configuration instructions

---

### Option 2: Netlify (Also Free & Easy)

**Steps:**

1. Build the website:
```bash
cd bunkbite-website
npm run build
```

2. Go to https://app.netlify.com/drop

3. Drag and drop the `dist` folder

4. Netlify will give you a URL like: `https://random-name-123.netlify.app`

5. **(Optional) Change site name:**
   - Site settings → Change site name → `bunkbite-support`
   - New URL: `https://bunkbite-support.netlify.app`

6. **(Optional) Add custom domain:**
   - Domain settings → Add custom domain
   - Follow DNS instructions

---

### Option 3: GitHub Pages (Free)

**Steps:**

1. Install gh-pages:
```bash
cd bunkbite-website
npm install --save-dev gh-pages
```

2. Add to `package.json`:
```json
{
  "homepage": "https://YOUR_GITHUB_USERNAME.github.io/bunkbite-website",
  "scripts": {
    "predeploy": "npm run build",
    "deploy": "gh-pages -d dist"
  }
}
```

3. Update `vite.config.js`:
```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/bunkbite-website/'
})
```

4. Deploy:
```bash
npm run deploy
```

5. Enable GitHub Pages:
   - Go to GitHub repo → Settings → Pages
   - Source: Deploy from branch `gh-pages`
   - Save

6. Your site will be at: `https://YOUR_USERNAME.github.io/bunkbite-website/`

---

### Option 4: Custom Domain/Server (Self-Hosted)

If you have your own domain (e.g., `bunkbite.me`):

**Steps:**

1. Build the website:
```bash
cd bunkbite-website
npm run build
```

2. The `dist` folder contains all static files

3. Upload `dist` contents to your web server

4. Configure your web server:

**For Nginx:**
```nginx
server {
    listen 80;
    server_name support.bunkbite.me;

    root /var/www/bunkbite-website;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**For Apache (.htaccess):**
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

---

## After Deployment

### 1. Test Your Website

Visit your deployed URL and verify:
- ✅ Home page loads
- ✅ All sections scroll smoothly (Features, Support, FAQ, Contact)
- ✅ Privacy Policy page works (`/privacy`)
- ✅ Terms of Service page works (`/terms`)
- ✅ All links work
- ✅ Mobile responsive
- ✅ Contact emails are clickable

### 2. Update App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Navigate to your BunkBite app
3. Click "App Information"
4. Under "Support URL", enter your deployed website URL:
   - Example: `https://bunkbite-support.vercel.app`
   - Or: `https://support.bunkbite.me`
5. Click "Save"

### 3. Resubmit Your App

1. Go to your app's version
2. If already rejected, click "Submit for Review" again
3. In the notes, mention:
   > "We have now added a functional support website at [YOUR_URL]. The website includes comprehensive support information, privacy policy, terms of service, and multiple contact methods as required by Guideline 1.5."

---

## Updating the Website

### For Vercel:
```bash
cd bunkbite-website
# Make your changes
npm run build
vercel --prod
```

### For Netlify:
```bash
cd bunkbite-website
# Make your changes
npm run build
# Drag and drop new dist folder to Netlify
```

### For GitHub Pages:
```bash
cd bunkbite-website
# Make your changes
npm run deploy
```

---

## Troubleshooting

### Issue: "404 on page refresh"
**Solution:** This is a routing issue. Make sure your hosting platform supports SPA routing:
- **Vercel:** Works automatically
- **Netlify:** Add `_redirects` file in `public` folder:
  ```
  /*    /index.html   200
  ```

### Issue: "CSS not loading"
**Solution:** Check the `base` setting in `vite.config.js` matches your deployment path.

### Issue: "Build fails"
**Solution:**
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
npm run build
```

---

## Custom Domain Setup (Optional)

If you want `support.bunkbite.me` instead of `something.vercel.app`:

### For Vercel:
1. Go to your project → Settings → Domains
2. Add custom domain: `support.bunkbite.me`
3. Add these DNS records to your domain:
   ```
   Type: CNAME
   Name: support
   Value: cname.vercel-dns.com
   ```

### For Netlify:
1. Go to Domain settings → Add custom domain
2. Add these DNS records:
   ```
   Type: CNAME
   Name: support
   Value: [your-site].netlify.app
   ```

---

## Cost

All recommended options are **100% FREE**:
- ✅ Vercel: Free forever
- ✅ Netlify: Free forever
- ✅ GitHub Pages: Free forever

No credit card required!

---

## Need Help?

If you encounter issues deploying:
1. Check the [Vercel Deployment Docs](https://vercel.com/docs)
2. Check the [Netlify Deployment Docs](https://docs.netlify.com)
3. Email: support@bunkbite.me

---

## Quick Commands Reference

```bash
# Development
npm run dev              # Start dev server

# Build
npm run build           # Create production build

# Preview build locally
npm run preview         # Preview production build

# Deploy (after setup)
vercel --prod          # Deploy to Vercel
npm run deploy         # Deploy to GitHub Pages
```

---

**Next Step:** Choose a deployment method above and deploy now! It takes less than 5 minutes. ⚡
