# Scholatransit Backoffice - Render Deployment Guide

This guide will help you deploy the Scholatransit Backoffice React application to Render.

## Prerequisites

- A Render account (sign up at [render.com](https://render.com))
- Your code pushed to a Git repository (GitHub, GitLab, or Bitbucket)
- Node.js 18+ (Render will automatically detect and use the appropriate version)

## Deployment Steps

### 1. Prepare Your Repository

The following files have been created/updated for Render deployment:

- `render.yaml` - Render configuration file
- `package.json` - Updated with production scripts
- `public/_redirects` - For React Router support
- `env.example` - Environment variables template

### 2. Deploy to Render

#### Option A: Using render.yaml (Recommended)

1. **Connect your repository to Render:**
   - Go to [render.com](https://render.com) and sign in
   - Click "New +" → "Static Site"
   - Connect your Git repository
   - Render will automatically detect the `render.yaml` configuration

2. **Configure the deployment:**
   - Render will use the settings from `render.yaml`
   - The build command is: `npm install && npm run build`
   - The publish directory is: `./dist`
   - Environment variables are pre-configured

#### Option B: Manual Configuration

If you prefer manual setup:

1. **Create a new Static Site:**
   - Go to Render Dashboard
   - Click "New +" → "Static Site"
   - Connect your Git repository

2. **Configure build settings:**
   - **Build Command:** `npm install && npm run build`
   - **Publish Directory:** `dist`
   - **Node Version:** 18 (or latest)

3. **Set Environment Variables:**
   ```
   NODE_ENV=production
   VITE_API_BASE_URL=https://schooltransit-backend-staging.onrender.com
   VITE_MAPBOX_API_KEY=pk.eyJ1Ijoid2VzbGV5MjU0IiwiYSI6ImNsMzY2dnA0MDAzem0zZG8wZTFzc3B3eG8ifQ.EVg7Sg3_wpa_QO6EJjj9-g
   ```

### 3. Custom Domain (Optional)

1. **Add a custom domain:**
   - In your Render dashboard, go to your service
   - Click "Settings" → "Custom Domains"
   - Add your domain and follow the DNS configuration instructions

### 4. Environment Variables

The following environment variables are configured:

| Variable | Value | Description |
|----------|-------|-------------|
| `NODE_ENV` | `production` | Node environment |
| `VITE_API_BASE_URL` | `https://schooltransit-backend-staging.onrender.com` | Backend API URL |
| `VITE_MAPBOX_API_KEY` | `pk.eyJ1Ijoid2VzbGV5MjU0IiwiYSI6ImNsMzY2dnA0MDAzem0zZG8wZTFzc3B3eG8ifQ.EVg7Sg3_wpa_QO6EJjj9-g` | Mapbox API key for maps |

### 5. Security Headers

The following security headers are configured in `render.yaml`:

- `X-Frame-Options: DENY` - Prevents clickjacking
- `X-Content-Type-Options: nosniff` - Prevents MIME type sniffing
- `Referrer-Policy: strict-origin-when-cross-origin` - Controls referrer information
- `Permissions-Policy: camera=(), microphone=(), geolocation=()` - Restricts permissions

### 6. React Router Support

The application uses React Router for client-side routing. The `public/_redirects` file ensures all routes are properly handled:

```
/*    /index.html   200
```

This configuration redirects all routes to `index.html` with a 200 status code, allowing React Router to handle the routing.

## Build Process

1. **Install Dependencies:** `npm install`
2. **Build Application:** `npm run build`
3. **Output Directory:** `dist/`

## Local Development

To run the application locally:

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Troubleshooting

### Common Issues

1. **Build Failures:**
   - Check that all dependencies are in `package.json`
   - Ensure Node.js version compatibility
   - Check for TypeScript errors

2. **Routing Issues:**
   - Verify `public/_redirects` file exists
   - Check that React Router is properly configured

3. **Environment Variables:**
   - Ensure all required environment variables are set
   - Check that API URLs are accessible

4. **API Connection Issues:**
   - Verify the backend API is running and accessible
   - Check CORS configuration on the backend
   - Ensure API endpoints are correct

### Debugging

1. **Check Render Logs:**
   - Go to your service dashboard
   - Click "Logs" to view build and runtime logs

2. **Test Locally:**
   ```bash
   npm run build
   npm run preview
   ```

3. **Check Network Tab:**
   - Open browser developer tools
   - Check for failed API requests
   - Verify environment variables are loaded

## Performance Optimization

The application is optimized for production with:

- Vite build optimization
- Code splitting
- Asset optimization
- Security headers
- Proper caching headers

## Support

For issues with:
- **Render Platform:** Check [Render Documentation](https://render.com/docs)
- **Application Code:** Check the application logs and error messages
- **API Issues:** Verify backend service is running and accessible

## Next Steps

After successful deployment:

1. Test all application features
2. Verify API connectivity
3. Test user authentication flows
4. Check all routes work correctly
5. Monitor application performance
6. Set up monitoring and alerts (optional)

Your Scholatransit Backoffice application should now be successfully deployed on Render!
