import { Link } from "react-router-dom";
import citySeal from "@/assets/icons/Marikina_City_Seal.svg (1).webp";
import styles from "./LandingPage.module.css";

/* ------------------------------------------------------------------ */
/* Shared building blocks                                              */
/* ------------------------------------------------------------------ */

interface EyebrowProps {
  text: string;
  light?: boolean;
}

function Eyebrow({ text, light = false }: EyebrowProps) {
  return <p className={styles.eyebrow}>{text}</p>;
}

interface SectionHeadingProps {
  eyebrow: string;
  title: string;
  subtext?: string;
  light?: boolean;
  className?: string;
}

function SectionHeading({
  eyebrow,
  title,
  subtext,
  light = false,
  className = "",
}: SectionHeadingProps) {
  return (
    <div className={`${styles.sectionHeading} ${className}`}>
      <Eyebrow text={eyebrow} light={light} />
      <h2 className={`${styles.sectionTitle} ${light ? styles.lightText : ""}`}>
        {title}
      </h2>
      {subtext && (
        <p
          className={`${styles.sectionSubtext} ${light ? styles.lightSubtext : ""}`}
        >
          {subtext}
        </p>
      )}
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Section 1 — Navbar                                                  */
/* ------------------------------------------------------------------ */

function Navbar() {
  return (
    <header className={styles.navbar}>
      <div className={styles.navContainer}>
        <Link to="/" className={styles.brand}>
          <img src={citySeal} alt="" />
          <span>
            <strong>Marikina Public Market</strong>
            <small>Inspection System</small>
          </span>
        </Link>

        <nav className={styles.navLinks} aria-label="Main navigation">
          <a href="#top" className={styles.activeNavLink}>
            Home
          </a>
          <a href="#features">About</a>
          <a href="#contact">Contact</a>
        </nav>

        <div className={styles.navActions}>
          <Link to="/login" className={styles.loginLink}>
            Login
          </Link>
          <Link
            to="/register"
            state={{ returnTo: "/" }}
            className={styles.registerLink}
          >
            Vendor Registration
          </Link>
        </div>
      </div>
    </header>
  );
}

function Hero() {
  return (
    <section className={styles.hero} id="top">
      <div className={styles.heroBackdrop} aria-hidden="true" />
      <div className={styles.heroContainer}>
        <div className={styles.heroContent}>
          <span className={styles.heroEyebrow}>
            MARIKINA CITY · PUBLIC MARKET
          </span>
          <h1 className={styles.heroTitle}>
            A Smarter Public Market for a Better Marikina.
          </h1>
          <p className={styles.heroCopy}>
            Bringing vendors, market enforcers, and administrators together
            through clearer inspections, accessible records, and accountable
            service.
          </p>
          <div className={styles.heroActions}>
            <Link
              to="/register"
              state={{ returnTo: "/" }}
              className={styles.heroPrimary}
            >
              Register as a vendor
            </Link>
            <Link to="/admin/login" className={styles.heroSecondary}>
              Administrator login <span aria-hidden>→</span>
            </Link>
          </div>
          <div className={styles.heroTrust}>
            <span aria-hidden>✓</span> A more connected market community
          </div>
        </div>
        <div className={styles.heroPanel} aria-label="Market system overview">
          <div className={styles.heroPanelTop}>
            <div className={styles.heroPanelBrand}>
              <img src={citySeal} alt="" />
              <span>
                <strong>Market operations</strong>
                <small>One connected system</small>
              </span>
            </div>
            <span className={styles.liveBadge}>
              <i /> Online
            </span>
          </div>
          <div className={styles.heroPanelBody}>
            <span className={styles.panelCaption}>
              BUILT FOR EVERY MARKET ROLE
            </span>
            <div className={styles.roleRow}>
              <span className={styles.roleIcon}>V</span>
              <span>
                <strong>Vendors</strong>
                <small>Track tickets and compliance</small>
              </span>
              <span className={styles.roleArrow}>↗</span>
            </div>
            <div className={styles.roleRow}>
              <span className={styles.roleIcon}>E</span>
              <span>
                <strong>Enforcers</strong>
                <small>Record inspections on the go</small>
              </span>
              <span className={styles.roleArrow}>↗</span>
            </div>
            <div className={styles.roleRow}>
              <span className={styles.roleIcon}>A</span>
              <span>
                <strong>Administrators</strong>
                <small>Manage records and operations</small>
              </span>
              <span className={styles.roleArrow}>↗</span>
            </div>
          </div>
          <div className={styles.heroPanelFoot}>
            <span /> Secure, role-based access
          </div>
        </div>
      </div>
    </section>
  );
}

const featureCards = [
  {
    title: "Time-Series Analysis",
    desc: "Market officers can log violations during daily rounds, capturing every incident with photo evidence and timestamps for a complete record.",
  },
  {
    title: "Frequency Distribution",
    desc: "Trend lines, peak periods, and recurring violation types are surfaced across market sections, turning raw tickets into clear pattern.",
  },
  {
    title: "AI Decision Support",
    desc: "A weighted scoring model ranks vendor risk and auto-suggests inspection actions, reviewed by the Administrator through natural language.",
  },
];

function Features() {
  return (
    <section id="features" className={styles.lightSection}>
      <div className={styles.container}>
        <SectionHeading
          eyebrow="System Features"
          title="Key implementing technologies of the system"
        />
        <div className={`${styles.cardGrid} ${styles.threeColumns}`}>
          {featureCards.map((c) => (
            <div
              key={c.title}
              className={`${styles.featureCard} ${styles.softCard}`}
            >
              <h3 className={styles.cardTitle}>{c.title}</h3>
              <p className={styles.cardCopy}>{c.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

const processSteps = [
  {
    num: "01",
    title: "Tickets Logged",
    desc: "Market officers issue tickets for violations during daily round inspections.",
  },
  {
    num: "02",
    title: "Patterns aggregated",
    desc: "Time-series analysis and frequency distribution surface trend lines, peak periods, and recurring violation types across market sections.",
  },
  {
    num: "03",
    title: "Sections and vendors ranked",
    desc: "Aggregation and ranking builds a market-section hotspot ranking, while a weighted scoring model ranks vendor risk.",
  },
  {
    num: "04",
    title: "AI inspection recommendations",
    desc: "The Administrator reviews the AI suggested actions in NLP.",
  },
];

function ProcessStep({
  num,
  title,
  desc,
  arrow,
}: {
  num: string;
  title: string;
  desc: string;
  arrow: boolean;
}) {
  return (
    <div className={styles.processStep}>
      <div className={styles.processContent}>
        <p className={styles.processNumber}>{num}</p>
        <h3 className={styles.processTitle}>{title}</h3>
        <p className={styles.processCopy}>{desc}</p>
      </div>
      {arrow && <span className={styles.processArrow}>→</span>}
      {arrow && <span className={styles.processDown}>↓</span>}
    </div>
  );
}

function Process() {
  return (
    <section className={styles.tintedSection}>
      <div className={styles.container}>
        <SectionHeading
          eyebrow="PROCESS"
          title="From ticket to inspection, automatically"
        />
        <div className={`${styles.cardGrid} ${styles.fourColumns}`}>
          {processSteps.map((s, i) => (
            <ProcessStep
              key={s.num}
              {...s}
              arrow={i < processSteps.length - 1}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

const bars = [
  { label: "Sanitation", width: "100%" },
  { label: "Weight", width: "82%" },
  { label: "Obstruction", width: "64%" },
  { label: "Licensing", width: "47%" },
  { label: "Noise", width: "30%" },
];

const hotspots = [
  { label: "Dry Goods Section A", level: "High" },
  { label: "Dry Goods Section B", level: "Medium" },
  { label: "Wet Section A", level: "Medium" },
  { label: "Wet Section B", level: "Low" },
];

function AnalyticsPreview() {
  return (
    <section className={styles.lightSection}>
      <div className={styles.container}>
        <SectionHeading
          eyebrow="ANALYTICS DASHBOARD"
          title="What the Administrator dashboard shows"
          subtext="Violation type distribution and market-section hotspot ranking, two of the five analytics modules, translated into a helpful analytics."
        />

        {/* Mock dashboard card */}
        <div className={styles.analyticsCard}>
          {/* header bar */}
          <div className={styles.analyticsHeader}>
            <span className={styles.analyticsDot} />
            <span className={styles.analyticsHeaderText}>
              Administrator / Analytics — Violation Type Distribution
            </span>
          </div>

          {/* body */}
          <div className={styles.analyticsBody}>
            {/* left: bar chart */}
            <div>
              <h3 className={styles.smallTitle}>Violation Type Distribution</h3>
              <div className={styles.barList}>
                {bars.map((b) => (
                  <div key={b.label}>
                    <div className={styles.barLabel}>
                      <span>{b.label}</span>
                    </div>
                    <div className={styles.barTrack}>
                      <div
                        className={styles.barFill}
                        style={{ width: b.width }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* right: hotspot ranking */}
            <div className={styles.hotspotCard}>
              <h3 className={styles.smallTitle}>
                Market Section Hotspot Ranking
              </h3>
              <div>
                {hotspots.map((h, i) => (
                  <div
                    key={h.label}
                    className={`${styles.hotspotRow} ${i > 0 ? styles.hotspotBorder : ""}`}
                  >
                    <span className={styles.hotspotLabel}>{h.label}</span>
                    <span
                      className={`${styles.level} ${styles[`level${h.level}`]}`}
                    >
                      {h.level}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

const roles = [
  {
    name: "Market Enforcer",
    platform: "Mobile",
    bullets: [
      "Scan a vendor's QR code or search the registry mid-inspection",
      "Issue a Warning or Violation ticket with photo evidence",
      "Real-time notification when a submitted ticket is reviewed",
    ],
  },
  {
    name: "Market Vendor",
    platform: "Portal",
    bullets: [
      "View every ticket issued against your stall, with evidence",
      "Track your compliance score and unpaid penalties",
      "Upload a payment receipt for Administrator review",
      "Download tickets and your QR code",
    ],
  },
  {
    name: "Administrator",
    platform: "Web",
    bullets: [
      "Review submitted tickets and update vendor status",
      "Manage the vendor registry and enforcer accounts",
      "View pattern analytics and export compliance reports",
      "Full audit trail of every action taken on a record",
    ],
  },
];

function WhoItsFor() {
  return (
    <section className={styles.tintedSection}>
      <div className={styles.container}>
        <SectionHeading
          eyebrow="WHO IT'S FOR"
          title="Three roles, one centralized system"
          subtext="Every account is role-based — each user only sees the functions relevant to their responsibilities."
        />
        <div className={`${styles.cardGrid} ${styles.threeColumns}`}>
          {roles.map((r) => (
            <div
              key={r.name}
              className={`${styles.roleCard} ${styles.whiteCard}`}
            >
              <div className={styles.roleHeader}>
                <h3 className={styles.roleTitle}>{r.name}</h3>
                <span className={styles.platform}>{r.platform}</span>
              </div>
              <ul className={styles.bulletList}>
                {r.bullets.map((b) => (
                  <li key={b} className={styles.bulletItem}>
                    <span className={styles.bulletMark}>—</span>
                    <span>{b}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function ClosingCta() {
  return (
    <section id="contact" className={styles.ctaSection}>
      <div className={`${styles.container} ${styles.centered}`}>
        <h2 className={styles.ctaTitle}>Register your stall today.</h2>
        <p className={styles.ctaCopy}>
          Submit a valid ID and business registration document — the
          Administrator reviews and approves your account against the existing
          vendor registry.
        </p>
        <Link to="/register" className={styles.ctaButton}>
          Vendor Registration
        </Link>
      </div>
    </section>
  );
}

export default function LandingPage() {
  return (
    <div className={`route-motion ${styles.landing}`}>
      <Navbar />
      <Hero />
      <Features />
      <Process />
      <AnalyticsPreview />
      <WhoItsFor />
      <ClosingCta />
    </div>
  );
}
