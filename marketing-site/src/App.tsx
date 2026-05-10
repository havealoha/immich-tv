import bannerImage from '../../assets/png/banner.png';
import launcherImage from '../../assets/png/playstore.png';
import tvBannerIcon from '../../assets/png/tv-banner-icon.png';

const featureGroups = [
  {
    eyebrow: 'TV-first',
    title: 'Built for remote control, not stretched phone UI',
    body:
      'Large targets, strong focus states, and a browsing flow designed around living-room navigation instead of touch-first compromises.',
  },
  {
    eyebrow: 'Read-only',
    title: 'Safe access to your self-hosted Immich library',
    body:
      'Sign in to an existing Immich server and browse timeline photos, albums, favorites, videos, and slideshows without exposing destructive actions.',
  },
  {
    eyebrow: 'Demo-ready',
    title: 'Instant tester mode without standing up a server',
    body:
      'A dedicated demo endpoint unlocks curated public sample media so people can evaluate the experience before connecting their own library.',
  },
];

const experienceBullets = [
  'Timeline browsing grouped by day with year-jump shortcuts',
  'Fullscreen photo and video viewing with slideshow handoff',
  'Saved local profiles with PIN-based reopening on TV devices',
  'Adaptive layouts for Android TV, desktop, tablet, and mobile preview',
];

const demoCredentials = {
  url: 'https://demo.immichtv.local',
  email: 'demo@immich.tv',
  password: 'demo1234',
};

const buildTargets = [
  'Android TV and Google TV launchers',
  'Firebase-hosted marketing site',
  'Desktop and web builds from the same Flutter codebase',
];

export default function App() {
  return (
    <div className="site-shell">
      <header className="hero">
        <nav className="topbar">
          <div className="brand-lockup">
            <img src={launcherImage} alt="Immich TV app icon" className="brand-icon" />
            <div>
              <p className="brand-kicker">WorkWithAfridi</p>
              <h1>Immich TV</h1>
            </div>
          </div>
          <div className="topbar-links">
            <a href="#features">Features</a>
            <a href="#demo">Demo</a>
            <a href="#deploy">Firebase</a>
          </div>
        </nav>

        <section className="hero-grid">
          <div className="hero-copy">
            <p className="eyebrow">Self-hosted gallery for the biggest screen in the house</p>
            <h2>
              Browse your Immich library from the couch with a TV interface that
              actually feels native.
            </h2>
            <p className="hero-body">
              Immich TV turns your photo archive into a calm, remote-friendly
              large-screen experience with timeline browsing, favorites,
              fullscreen playback, and ambient slideshows.
            </p>
            <div className="hero-actions">
              <a className="primary-cta" href="#demo">
                Try demo access
              </a>
              <a
                className="secondary-cta"
                href="https://github.com/WorkWithAfridi"
                target="_blank"
                rel="noreferrer"
              >
                View developer repos
              </a>
            </div>
            <ul className="hero-metrics">
              <li>
                <strong>TV-native</strong>
                <span>Android TV and Google TV focused</span>
              </li>
              <li>
                <strong>Read-safe</strong>
                <span>No destructive library actions</span>
              </li>
              <li>
                <strong>Demo-ready</strong>
                <span>Public sample media without setup</span>
              </li>
            </ul>
          </div>

          <div className="hero-visual">
            <div className="television-frame">
              <img src={bannerImage} alt="Immich TV banner preview" />
            </div>
            <div className="floating-card floating-card-left">
              <span>Focus-first</span>
              <strong>Remote choreography</strong>
            </div>
            <div className="floating-card floating-card-right">
              <span>Fullscreen</span>
              <strong>Photo and video playback</strong>
            </div>
          </div>
        </section>
      </header>

      <main>
        <section className="feature-strip" id="features">
          {featureGroups.map((item) => (
            <article className="feature-panel" key={item.title}>
              <p className="panel-eyebrow">{item.eyebrow}</p>
              <h3>{item.title}</h3>
              <p>{item.body}</p>
            </article>
          ))}
        </section>

        <section className="experience-grid">
          <div className="experience-copy">
            <p className="eyebrow">Why it lands differently on TV</p>
            <h2>Comfortable at ten feet away, sharp enough for 4K displays.</h2>
            <p>
              This project is not a tablet app taped onto a television. The
              information hierarchy, grid density, and playback flows are tuned
              for the reality of sitting back with a remote.
            </p>
            <ul className="bullet-list">
              {experienceBullets.map((bullet) => (
                <li key={bullet}>{bullet}</li>
              ))}
            </ul>
          </div>

          <div className="device-stack">
            <div className="device-card tall-card">
              <img src={tvBannerIcon} alt="Immich TV visual identity" />
            </div>
            <div className="device-card stats-card">
              <p className="panel-eyebrow">Build targets</p>
              <ul className="bullet-list compact">
                {buildTargets.map((target) => (
                  <li key={target}>{target}</li>
                ))}
              </ul>
            </div>
          </div>
        </section>

        <section className="demo-section" id="demo">
          <div className="demo-copy">
            <p className="eyebrow">Demo access</p>
            <h2>Hand testers a simple URL and let the app do the rest.</h2>
            <p>
              Enter the exact demo endpoint in onboarding to unlock public demo
              media. The mock content only appears for that dedicated URL, so
              production server flow stays untouched.
            </p>
          </div>
          <div className="credentials-card">
            <div>
              <span>URL</span>
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

        <section className="deploy-section" id="deploy">
          <div className="deploy-panel">
            <p className="eyebrow">Firebase hosting</p>
            <h2>Shipped as a standalone marketing app in this same repository.</h2>
            <p>
              The marketing site lives under <code>marketing-site/</code> with
              its own Vite build, Firebase config, and deploy scripts. That
              keeps release marketing independent from the Flutter runtime.
            </p>
          </div>
          <div className="deploy-code">
            <pre>
              <code>{`cd marketing-site
npm install
npm run build
npm run firebase:deploy`}</code>
            </pre>
          </div>
        </section>
      </main>
    </div>
  );
}
