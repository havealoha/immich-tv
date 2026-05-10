import bannerImage from '../../assets/png/banner.png';
import launcherImage from '../../assets/png/playstore.png';
import { useEffect, useState } from 'react';

const coreFeatures = [
  {
    title: 'Designed for TV from the start',
    body:
      'Remote navigation, clear focus states, and readable spacing make the app feel native on Android TV and Google TV.',
  },
  {
    title: 'Built around your Immich server',
    body:
      'Sign in with your existing Immich account and browse timeline photos, albums, favorites, videos, and slideshows on the biggest screen in your home.',
  },
  {
    title: 'Calm, read-focused experience',
    body:
      'Immich TV is optimized for viewing and playback, keeping the living-room experience simple, safe, and comfortable.',
  },
];

const productDetails = [
  'Timeline browsing grouped by day with fast year jumps',
  'Fullscreen photo and video playback with smooth navigation',
  'Albums, favorites, and slideshow playback in one TV-first flow',
  'Saved local profiles with secure storage for returning sessions',
];

const demoCredentials = {
  url: 'https://demo.immichtv.local',
  email: 'demo@immich.tv',
  password: 'demo1234',
};

const faqs = [
  {
    question: 'What is Immich TV?',
    answer:
      'Immich TV is an open source television client for browsing a self-hosted Immich library on Android TV and Google TV.',
  },
  {
    question: 'Do I need my own Immich server?',
    answer:
      'Yes for normal use. There is also a dedicated demo mode so testers can preview the experience without connecting a real library.',
  },
  {
    question: 'Can I contribute to the project?',
    answer:
      'Yes. The repository is public on GitHub, so you can open issues, star the project, and contribute improvements.',
  },
];

const repoUrl = 'https://github.com/WorkWithAfridi/immich-tv';
const issuesUrl = 'https://github.com/WorkWithAfridi/immich-tv/issues';
const releasesUrl = 'https://github.com/WorkWithAfridi/immich-tv/releases';
const themeStorageKey = 'immich-tv-marketing-theme';
const releaseApiUrl = 'https://api.github.com/repos/WorkWithAfridi/immich-tv/releases/tags/master-latest';

function GithubIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="icon glyph-icon">
      <path
        fill="currentColor"
        d="M12 2C6.48 2 2 6.59 2 12.24c0 4.51 2.87 8.34 6.84 9.69.5.1.68-.22.68-.49 0-.24-.01-1.05-.01-1.91-2.78.62-3.37-1.21-3.37-1.21-.46-1.2-1.11-1.52-1.11-1.52-.91-.64.07-.63.07-.63 1 .08 1.53 1.06 1.53 1.06.9 1.58 2.35 1.12 2.92.86.09-.67.35-1.12.63-1.38-2.22-.26-4.56-1.14-4.56-5.08 0-1.12.39-2.04 1.03-2.76-.1-.26-.45-1.31.1-2.73 0 0 .84-.28 2.75 1.05A9.3 9.3 0 0 1 12 6.83c.85 0 1.71.12 2.51.37 1.91-1.33 2.75-1.05 2.75-1.05.55 1.42.2 2.47.1 2.73.64.72 1.03 1.64 1.03 2.76 0 3.95-2.34 4.81-4.57 5.07.36.32.68.95.68 1.92 0 1.39-.01 2.5-.01 2.84 0 .27.18.6.69.49A10.27 10.27 0 0 0 22 12.24C22 6.59 17.52 2 12 2Z"
      />
    </svg>
  );
}

function TvIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="icon">
      <path
        fill="currentColor"
        d="M5 7.5A2.5 2.5 0 0 1 7.5 5h9A2.5 2.5 0 0 1 19 7.5v7A2.5 2.5 0 0 1 16.5 17H13v1.5h3v1.5H8v-1.5h3V17H7.5A2.5 2.5 0 0 1 5 14.5v-7Zm2.5-1A1 1 0 0 0 6.5 7.5v7a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1v-7a1 1 0 0 0-1-1h-9Z"
      />
    </svg>
  );
}

function ImageIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="icon">
      <path
        fill="currentColor"
        d="M5 5.5A2.5 2.5 0 0 1 7.5 3h9A2.5 2.5 0 0 1 19 5.5v13a2.5 2.5 0 0 1-2.5 2.5h-9A2.5 2.5 0 0 1 5 18.5v-13Zm2.5-1a1 1 0 0 0-1 1v13a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1v-13a1 1 0 0 0-1-1h-9Zm1.75 3a1.25 1.25 0 1 1 0 2.5 1.25 1.25 0 0 1 0-2.5Zm7.25 8.75H7.5v-.82l2.46-2.42a.75.75 0 0 1 1.07.02l1.39 1.44 2.34-2.95a.75.75 0 0 1 1.18.02l.56.72v3.99Z"
      />
    </svg>
  );
}

function SlideshowIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="icon">
      <path
        fill="currentColor"
        d="M5.5 4A2.5 2.5 0 0 0 3 6.5v11A2.5 2.5 0 0 0 5.5 20h13a2.5 2.5 0 0 0 2.5-2.5v-11A2.5 2.5 0 0 0 18.5 4h-13Zm0 1.5h13a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1h-13a1 1 0 0 1-1-1v-11a1 1 0 0 1 1-1Zm4.2 2.8v7.4l5.8-3.7-5.8-3.7Z"
      />
    </svg>
  );
}

function ThemeIcon({ theme }: { theme: 'light' | 'dark' }) {
  if (theme === 'dark') {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true" className="icon glyph-icon">
        <path
          fill="currentColor"
          d="M12 5.75a.75.75 0 0 1 .75.75v1.5a.75.75 0 0 1-1.5 0V6.5a.75.75 0 0 1 .75-.75Zm0 10.25a.75.75 0 0 1 .75.75v1.5a.75.75 0 0 1-1.5 0v-1.5A.75.75 0 0 1 12 16Zm6.25-4.75a.75.75 0 0 1 0 1.5h-1.5a.75.75 0 0 1 0-1.5h1.5ZM8 12a.75.75 0 0 1-.75.75h-1.5a.75.75 0 0 1 0-1.5h1.5A.75.75 0 0 1 8 12Zm6.03-4.97a.75.75 0 0 1 1.06 0l1.06 1.06a.75.75 0 1 1-1.06 1.06l-1.06-1.06a.75.75 0 0 1 0-1.06Zm-6.12 6.12a.75.75 0 0 1 1.06 0l1.06 1.06a.75.75 0 0 1-1.06 1.06l-1.06-1.06a.75.75 0 0 1 0-1.06Zm7.18 1.06a.75.75 0 0 1 1.06-1.06l1.06 1.06a.75.75 0 0 1-1.06 1.06l-1.06-1.06ZM8.97 7.03a.75.75 0 0 1 0 1.06L7.91 9.15A.75.75 0 0 1 6.85 8.1l1.06-1.07a.75.75 0 0 1 1.06 0ZM12 9.25A2.75 2.75 0 1 0 12 14.75 2.75 2.75 0 0 0 12 9.25Z"
        />
      </svg>
    );
  }

  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="icon glyph-icon">
      <path
        fill="currentColor"
        d="M14.7 3.3a.75.75 0 0 1 .88.98 7.25 7.25 0 0 0 8.14 9.22.75.75 0 0 1 .7 1.2A9 9 0 1 1 14.5 2.6a.75.75 0 0 1 .2.7Z"
        transform="translate(-2)"
      />
    </svg>
  );
}

export default function App() {
  const featureIcons = [<TvIcon key="tv" />, <ImageIcon key="image" />, <SlideshowIcon key="slideshow" />];
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [downloadUrl, setDownloadUrl] = useState(releasesUrl);
  const [downloadLabel, setDownloadLabel] = useState('Latest release on GitHub');

  useEffect(() => {
    const savedTheme = window.localStorage.getItem(themeStorageKey);
    if (savedTheme === 'light' || savedTheme === 'dark') {
      setTheme(savedTheme);
      return;
    }

    const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches
      ? 'dark'
      : 'light';
    setTheme(systemTheme);
  }, []);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    window.localStorage.setItem(themeStorageKey, theme);
  }, [theme]);

  useEffect(() => {
    let isMounted = true;

    const loadReleaseAsset = async () => {
      try {
        const response = await fetch(releaseApiUrl, {
          headers: {
            Accept: 'application/vnd.github+json',
          },
        });

        if (!response.ok) {
          return;
        }

        const release = await response.json();
        const versionedAsset = release.assets?.find(
          (asset: { name?: string; browser_download_url?: string }) =>
            typeof asset.name === 'string' &&
            /^ImmichTV-\d+\.\d+\.\d+-\d+\.apk$/.test(asset.name) &&
            typeof asset.browser_download_url === 'string',
        );

        if (!isMounted || !versionedAsset) {
          return;
        }

        setDownloadUrl(versionedAsset.browser_download_url);
        setDownloadLabel(versionedAsset.name);
      } catch {
        // Fall back to the releases page when release metadata cannot be loaded.
      }
    };

    void loadReleaseAsset();

    return () => {
      isMounted = false;
    };
  }, []);

  const toggleTheme = () => {
    setTheme((currentTheme) => (currentTheme === 'light' ? 'dark' : 'light'));
  };

  return (
    <div className="site-shell">
      <div className="background-orb orb-a" />
      <div className="background-orb orb-b" />
      <div className="background-grid" />

      <header className="hero" id="top">
        <nav className="topbar" aria-label="Primary">
          <a className="brand-lockup" href="#top">
            <img src={launcherImage} alt="Immich TV app icon" className="brand-icon" />
            <div>
              <p className="brand-kicker">Open source TV client</p>
              <h1>Immich TV</h1>
            </div>
          </a>

          <div className="topbar-links">
            <a href="#features">Features</a>
            <a href="#download">Download</a>
            <a href="#demo">Demo</a>
            <a href="#github">GitHub</a>
            <a href="#faq">FAQ</a>
            <button className="theme-toggle" type="button" onClick={toggleTheme} aria-label="Toggle color theme">
              <ThemeIcon theme={theme} />
            </button>
          </div>
        </nav>

        <section className="hero-grid">
          <div className="hero-copy">
            <p className="eyebrow">Immich for Android TV and Google TV</p>
            <h2>A minimal, TV-first way to enjoy your self-hosted photo library.</h2>
            <p className="hero-body">
              Immich TV brings timeline browsing, albums, favorites, video playback,
              and slideshows into a clean large-screen interface built for the
              couch instead of a touch screen.
            </p>

            <div className="hero-actions">
              <a className="primary-cta" href={downloadUrl} target="_blank" rel="noreferrer">
                Download APK
              </a>
              <a className="secondary-cta" href={repoUrl} target="_blank" rel="noreferrer">
                <GithubIcon />
                View on GitHub
              </a>
            </div>

            <div className="hero-inline-points" aria-label="Product highlights">
              <span>Remote-first navigation</span>
              <span>Self-hosted Immich support</span>
              <span>Fullscreen playback and slideshow</span>
            </div>
          </div>

          <div className="hero-visual">
            <div className="hero-frame">
              <img src={bannerImage} alt="Immich TV large-screen preview" />
            </div>
          </div>
        </section>
      </header>

      <main>
        <section className="feature-section" id="features">
          <div className="section-heading">
            <p className="eyebrow">Why it feels right on TV</p>
            <h2>Focused on clarity, playback, and comfortable browsing from a distance.</h2>
            <p>
              Most gallery apps arrive on television as stretched touch UIs.
              Immich TV is different. It is shaped around how people actually
              browse media in a living room.
            </p>
          </div>

          <div className="feature-grid">
            {coreFeatures.map((feature, index) => (
              <article className="feature-card" key={feature.title}>
                <div className="feature-icon">{featureIcons[index]}</div>
                <h3>{feature.title}</h3>
                <p>{feature.body}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="experience-section">
          <div className="experience-copy">
            <p className="eyebrow">Core experience</p>
            <h2>Everything you need for relaxed large-screen browsing, without clutter.</h2>
          </div>

          <ul className="detail-grid">
            {productDetails.map((detail) => (
              <li key={detail}>{detail}</li>
            ))}
          </ul>
        </section>

        <section className="download-section" id="download">
          <div className="section-heading">
            <p className="eyebrow">Download APK</p>
            <h2>Install the latest signed Android TV build directly from GitHub Releases.</h2>
            <p>
              Each push to the `master` branch builds a signed release APK and
              updates the public download asset. Use the direct download button
              for the newest build or open releases to browse specific versions.
            </p>
          </div>

          <div className="download-panel">
            <div className="download-copy">
              <p className="repo-label">Latest public file</p>
              <a className="repo-link" href={downloadUrl} target="_blank" rel="noreferrer">
                {downloadLabel}
              </a>
            </div>

            <div className="github-actions">
              <a className="primary-cta" href={downloadUrl} target="_blank" rel="noreferrer">
                Download latest APK
              </a>
              <a className="secondary-cta" href={releasesUrl} target="_blank" rel="noreferrer">
                Browse releases
              </a>
            </div>
          </div>
        </section>

        <section className="demo-section" id="demo">
          <div className="demo-copy">
            <p className="eyebrow">Demo access</p>
            <h2>Use the exact demo URL to unlock sample media and test the flow.</h2>
            <p>
              Demo mode only appears when the tester enters the exact server URL
              below, keeping the production sign-in path separate from the sample
              experience.
            </p>
          </div>

          <div className="credentials-card">
            <div>
              <span>Demo URL</span>
              <strong>{demoCredentials.url}</strong>
            </div>
            <div>
              <span>Email</span>
              <strong>{demoCredentials.email}</strong>
            </div>
            <div>
              <span>Password</span>
              <strong>{demoCredentials.password}</strong>
            </div>
          </div>
        </section>

        <section className="github-section" id="github">
          <div className="section-heading">
            <p className="eyebrow">Open source</p>
            <h2>Explore the repository, star the project, or contribute improvements.</h2>
            <p>
              The app and the Firebase-hosted marketing site live together in a
              public GitHub repository, making it easy to follow progress and
              participate.
            </p>
          </div>

          <div className="github-panel">
            <div className="github-copy">
              <p className="repo-label">Repository</p>
              <a className="repo-link" href={repoUrl} target="_blank" rel="noreferrer">
                github.com/WorkWithAfridi/immich-tv
              </a>
            </div>

            <div className="github-actions">
              <a className="primary-cta" href={repoUrl} target="_blank" rel="noreferrer">
                <GithubIcon />
                Open repo
              </a>
              <a className="secondary-cta" href={repoUrl} target="_blank" rel="noreferrer">
                <GithubIcon />
                Star on GitHub
              </a>
              <a className="secondary-cta" href={issuesUrl} target="_blank" rel="noreferrer">
                <GithubIcon />
                Contribute
              </a>
            </div>
          </div>
        </section>

        <section className="faq-section" id="faq">
          <div className="section-heading">
            <p className="eyebrow">FAQ</p>
            <h2>Key questions before installation.</h2>
          </div>

          <div className="faq-list">
            {faqs.map((item) => (
              <article className="faq-card" key={item.question}>
                <h3>{item.question}</h3>
                <p>{item.answer}</p>
              </article>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}
