# Amplify + Nx Monorepo Starter  
**Next.js (web + admin) + Flutter (mobile) + AWS Amplify Gen 2 (shared backend)**

Full-stack monorepo with:
- Two Next.js apps: `web` (main site) + `admin` (dashboard)
- Flutter mobile app
- Shared AWS Amplify Gen 2 backend (Cognito Auth + AppSync/Data + S3 Storage)

## Project Structure

```
.
├── apps/
│   ├── web/          # Next.js main web app (App Router, TypeScript)
│   ├── admin/        # Next.js admin dashboard (App Router, TypeScript)
│   └── mobile/       # Flutter mobile app
├── packages/
│   └── backend/      # Shared Amplify Gen 2 backend (amplify/ folder here)
├── nx.json
├── package.json
└── tsconfig.base.json
```

## Prerequisites

- Node.js ≥ 20
- npm ≥ 10
- Flutter SDK (with Android/iOS setup if targeting native)
- AWS CLI configured (`aws configure`) with permissions for Amplify, CloudFormation, IAM, Cognito, AppSync, S3
- (Linux only) Increased file watcher limit (see Troubleshooting)

## Quick Start – Create from Scratch

```bash
# 1. Create Nx workspace
npx create-nx-workspace@latest my-amplify-monorepo --preset=ts
cd my-amplify-monorepo

# 2. Install plugins
npm install -D @nx/next @nx/js
npm install -D @nxrocks/nx-flutter

# 3. Create Next.js apps (with fixes applied later)
npx nx g @nx/next:app web \
  --directory=apps/web \
  --appRouter=true \
  --typescript=true \
  --style=css \
  --linter=eslint \
  --unitTestRunner=jest \
  --e2eTestRunner=playwright \
  --src=true \
  --yes

npx nx g @nx/next:app admin \
  --directory=apps/admin \
  --appRouter=true \
  --typescript=true \
  --style=css \
  --linter=eslint \
  --unitTestRunner=jest \
  --e2eTestRunner=playwright \
  --src=true \
  --yes

# 4. Create Flutter app
npx nx g @nxrocks/nx-flutter:project mobile \
  --directory=apps/mobile \
  --org=com.example \
  --android \
  --ios \
  --yes

# 5. Create shared Amplify Gen 2 backend
npx nx g @nx/js:lib shared-backend --directory=packages/backend --typescript --no-buildable
cd packages/backend
npm create amplify@latest    # Accept defaults or customize (auth + data + storage)
cd ../../
npm install
```

## Important One-time Fixes (Linux / WSL users)

Turbopack in Next.js 16 can hit OS file watcher limits in monorepos → increase limit:

```bash
sudo sysctl fs.inotify.max_user_watches=1048576
sudo sysctl fs.inotify.max_user_instances=1024
sudo sysctl -p

# Make permanent
echo 'fs.inotify.max_user_watches=1048576' | sudo tee -a /etc/sysctl.conf
echo 'fs.inotify.max_user_instances=1024' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

To avoid Turbopack issues, force **Webpack** in both apps:

Edit `apps/web/project.json` and `apps/admin/project.json` → add `"webpack": true` under `serve.options`:

```json
"serve": {
  "executor": "@nx/next:server",
  "options": {
    "buildTarget": "<app>:build",
    "dev": true,
    "port": 3000,          // 3000 for web, 3001 for admin
    "webpack": true        // ← Add this
  },
  ...
}
```

## Development – Run Everything

Open **four terminals** from project root:

```bash
# Terminal 1: Amplify Sandbox (personal cloud backend)
cd packages/backend
npx ampx sandbox
# → Deploys isolated backend → generates amplify_outputs.json
# Keep running
cd ../..
```

```bash
# Terminal 2: Web app (http://localhost:3000)
npx nx serve web
# or if port not respected: npx nx serve web --port=3000
```

```bash
# Terminal 3: Admin app (http://localhost:3001)
npx nx serve admin --port=3001
# or npx nx serve admin
```

```bash
# Terminal 4: Mobile (Flutter)
# Quick web preview (hot reload in browser)
npx nx run mobile:run --platform=web

# Or on emulator/device
npx nx run mobile:run
# List devices: flutter devices
# Specific device: npx nx run mobile:run -d <device-id>
```

## Connecting Frontends to Amplify

After sandbox starts:

1. `amplify_outputs.json` appears (usually in `packages/backend/` or root).
2. **Next.js (web & admin)**:  
   Install deps (from root):  
   ```bash
   npm install aws-amplify @aws-amplify/adapter-nextjs
   ```
   Configure in root layout or client components:
   ```ts
   import { Amplify } from 'aws-amplify';
   import outputs from '../../packages/backend/amplify_outputs.json';
   Amplify.configure(outputs);
   ```

3. **Flutter**:  
   ```bash
   cd apps/mobile
   flutter pub add amplify_flutter amplify_auth_cognito amplify_api amplify_storage_s3
   ```
   Convert `amplify_outputs.json` → Dart or place in assets and load.

## Deployment to AWS Amplify Gen 2 (Production)

1. Push repo to GitHub.
2. Create **3 separate Amplify apps** in Amplify Console:

   - **Backend** (shared):  
     App root: `packages/backend`  
     → Auto-detects Gen 2

   - **Web frontend**:  
     App root: `.` (root)  
     Project directory: `apps/web`  
     Build command: `npx nx build web`

   - **Admin frontend**:  
     Same as web, but `apps/admin`

3. In frontend build settings → add preBuild to fetch backend outputs:
   ```yaml
   preBuild:
     commands:
       - npx ampx generate outputs --branch $AWS_BRANCH --app-id $BACKEND_APP_ID
   ```

- **IMPORTANT**
MUST run this command when build backend
```
aws amplify update-app --app-id YOUR_APP_ID --platform WEB
```
After changing the platform to "Web" (static), your current amplify.yml should work fine.

## Troubleshooting

- **Turbopack panic / file watch limit** → Run the sysctl commands above
- **Port 4200 instead of 3000** → Ensure `"webpack": true` in `project.json` or use `-- --webpack`
- **Flutter no serve target** → Use `npx nx run mobile:run` (not `serve`)
- Sandbox not deploying → Check AWS credentials & region
