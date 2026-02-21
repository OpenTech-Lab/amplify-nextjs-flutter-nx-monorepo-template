# deploy-on-amplify

Here are the **step-by-step instructions** to deploy your Nx monorepo setup to production on **AWS Amplify Hosting** using **Amplify Gen 2**:

- **One shared backend** (Cognito + Data/AppSync + S3 Storage from `packages/backend/amplify/`)
- **Two separate frontend apps** (Next.js `web` and `admin` from `apps/web` and `apps/admin`)

This follows the official **Amplify Gen 2 monorepo pattern** (deploy **3 separate Amplify apps** from the same repository → shared backend + independent frontends pulling from the backend).

### Important Principles (2025–2026 best practice)
- Backend changes → only deployed from **one** Amplify app (the backend one).
- Frontend changes → trigger builds only for the affected frontend app.
- Frontends fetch backend config (amplify_outputs) during build using `ampx generate outputs`.
- No manual `amplify pull` needed in CI/CD.

### Step 1: Prepare Your Repository
1. Make sure everything builds locally:
   ```bash
   npx nx build web
   npx nx build admin
   cd packages/backend && npx ampx sandbox   # just to verify
   ```

2. Commit & push your monorepo to GitHub / GitLab / Bitbucket (main branch).

3. **Do not commit** generated files:
   - Add to `.gitignore` (if not already):
     ```
     amplify_outputs.json
     */amplify_outputs.json
     .amplify-hosting/
     ```

### Step 2: Create the Backend Amplify App (Shared)
1. Go to **AWS Amplify Console** → https://console.aws.amazon.com/amplify/home
2. Click **New app** → **Host web app**
3. **Connect your repository** (GitHub / etc.)
4. **Select branch** → main (or your production branch)
5. **Configure build settings**:
   - **Monorepo root directory**: `packages/backend`  
     (This is crucial — Amplify detects Gen 2 only when pointing here)
   - App name: e.g. `myapp-backend` or `myapp-shared-backend`
   - Framework: Should auto-detect **Amplify Gen 2** (if not, something's wrong with folder structure)
6. **Save and deploy**
   - First deploy takes ~3–8 minutes.
   - After success → note the **App ID** (visible in URL or App settings → e.g. `d123456789`)

This app is now the **source of truth** for backend deploys. Only push backend changes (`amplify/` folder) to trigger it.

### Step 3: Create the Web Frontend Amplify App
1. Back in Amplify Console → **New app** → **Host web app** (again, same repo)
2. Connect the **same repository & branch**
3. **Configure build settings**:
   - **Monorepo root directory**: leave empty or `.` (root)
   - **App root directory**: `apps/web`
   - App name: e.g. `myapp-web`
   - Framework: Should detect **Next.js – SSR/SSG**
4. **Edit build settings** (very important – add preBuild step to fetch backend outputs):
   - Click **Edit** next to Build settings
   - Replace or add to `amplify.yml` (Amplify auto-generates one; override it):

```yaml
version: 1
applications:
  - frontend:
      phases:
        preBuild:
          commands:
            - npx ampx generate outputs --branch $AWS_BRANCH --app-id YOUR_BACKEND_APP_ID
              # ↑ Replace YOUR_BACKEND_APP_ID with the real ID from Step 2 (e.g. d1abc2345)
        build:
          commands:
            - npx nx build web --configuration=production
      artifacts:
        baseDirectory: dist/apps/web
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
          - .nx/cache/**/*
```

   - Or if Amplify shows UI fields, set:
     - Build command: `npx nx build web --configuration=production`
     - Output directory: `dist/apps/web`

5. **Save and deploy**

### Step 4: Create the Admin Frontend Amplify App
Repeat **Step 3** exactly, but with these differences:
- App name: e.g. `myapp-admin`
- **App root directory**: `apps/admin`
- Build command: `npx nx build admin --configuration=production`
- Output directory: `dist/apps/admin`
- Same `preBuild` command with the **same backend App ID**

### Step 5: Post-Deployment Configuration
1. **Custom domains** (optional):
   - In each frontend app (web & admin) → App settings → Domain management → Add domain.
   - Example: `www.example.com` → web app, `admin.example.com` → admin app.

2. **Environment variables** (if needed):
   - In frontend apps → App settings → Environment variables
   - Add any custom ones (e.g. `NEXT_PUBLIC_API_URL`).
   - **Do not** put secrets here for Gen 2 — use backend secrets via `ampx secret`.

3. **Branching / Previews**:
   - Enable **feature branch deployments** in each app for PR previews.
   - Backend app usually doesn't need previews (disable auto-build on branches if desired).

4. **Connect frontends to backend in code** (already done locally):
   - In Next.js apps: Use `Amplify.configure` with generated outputs.
   - During CI/CD, `ampx generate outputs` puts `amplify_outputs.json` in the build workspace → your code should import it from there (or adjust paths).

### Step 6: Workflow After Setup
- Change **backend code** (`amplify/` folder) → push → only **backend app** builds & deploys → frontends auto-get new config on next frontend build.
- Change **web** code → push → only **web app** builds.
- Same for admin.

### Troubleshooting Tips
- **Backend not detected as Gen 2?** → Double-check monorepo root = `packages/backend` and `amplify/` folder exists there.
- **Outputs not generated?** → Verify backend App ID is correct in `ampx generate outputs` line.
- **Nx not found?** → Add `npm ci` or `npm install` before build command if needed.
- **Costs** → Backend sandbox is free-ish, but production has usage-based pricing (Cognito, AppSync, S3).

This setup is production-recommended for Nx + Amplify Gen 2 (separate backend ownership, independent frontend scaling).
