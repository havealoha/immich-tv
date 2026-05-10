# Immich TV Marketing Site

This folder contains the standalone marketing website for Immich TV.

It is intentionally separated from the Flutter application so the public launch
site can be developed, built, and deployed independently of the app runtime.

## Purpose

The marketing site is designed to:

- present Immich TV as a TV-first Immich client
- provide launch-ready product messaging and SEO content
- share demo access details for testers
- be deployable to Firebase Hosting as a standalone static site

## Stack

- Vite
- React
- TypeScript
- Firebase Hosting

## Project Structure

```text
marketing-site/
  src/
    App.tsx
    main.tsx
    styles.css
    vite-env.d.ts
  index.html
  firebase.json
  .firebaserc.example
  package.json
  tsconfig.json
  tsconfig.app.json
  vite.config.ts
```

## Assets

The site currently reuses image assets from the root Flutter app:

- `../assets/png/banner.png`
- `../assets/png/playstore.png`
- `../assets/png/tv-banner-icon.png`

Because these are imported directly from the main project, branding stays
consistent between the app and the marketing site.

## Requirements

Before running the site locally, make sure you have:

- Node.js installed
- npm installed

## Install Dependencies

From this folder:

```bash
npm install
```

## Run Locally

For normal development:

```bash
npm run dev
```

Vite will print a local URL, usually:

```text
http://localhost:5173
```

Open that URL in your browser.

## Production Build

To create the production-ready static build:

```bash
npm run build
```

The compiled site will be written to:

```text
dist/
```

## Preview the Production Build

To preview the built output locally:

```bash
npm run preview
```

## Firebase Hosting Setup

This site uses its own Firebase Hosting config inside this folder.

Files involved:

- `firebase.json`
- `.firebaserc`

### Step 1. Create `.firebaserc`

Copy the example file:

```bash
copy .firebaserc.example .firebaserc
```

Then replace the placeholder project id with your real Firebase project id.

Example:

```json
{
  "projects": {
    "default": "your-firebase-project-id"
  }
}
```

### Step 2. Log in to Firebase CLI

```bash
firebase login
```

## Run Firebase Hosting Locally

To test the built site through the Firebase Hosting emulator:

```bash
npm run build
npm run firebase:serve
```

## Deploy to Firebase Hosting

From this folder:

```bash
npm run build
npm run firebase:deploy
```

That deploys the contents of `dist/` using the local `firebase.json`
configuration in this folder.

## Available Scripts

- `npm run dev`  
  Starts the Vite development server.

- `npm run build`  
  Runs TypeScript checks and creates a production build.

- `npm run preview`  
  Serves the production build locally using Vite preview.

- `npm run firebase:serve`  
  Starts the Firebase Hosting emulator using this folder's config.

- `npm run firebase:deploy`  
  Deploys the site to Firebase Hosting using this folder's config.

## Notes

- Deploy commands should be run from `marketing-site/`, not the repo root.
- This site is independent from Flutter web output in the root `web/` folder.
- For better production performance, you may want to create optimized web-sized
  versions of the large PNG assets currently reused from the app.
