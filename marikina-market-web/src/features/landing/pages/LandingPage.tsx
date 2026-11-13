import { Link } from "react-router-dom";
import citySeal from "@/assets/icons/Marikina_City_Seal.svg (1).webp";
import styles from "./LandingPage.module.css";
import { useLandingMotion } from "../hooks/useLandingMotion";

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
          <a href="#features">Features</a>
          <a href="#how-it-works">How it works</a>
          <a href="#faq">Questions</a>
          <a href="#contact">Contact</a>
        </nav>

        <div className={styles.navActions}>
          <Link to="/admin/login" className={styles.loginLink}>
            Login
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
            Bringing market enforcers and administrators together through
            clearer inspections, accessible records, and accountable service.
          </p>
          <div className={styles.heroActions}>
            <Link to="/admin/login" className={styles.heroSecondary}>
              Administrator login <span aria-hidden>→</span>
            </Link>
          </div>
          <div className={styles.heroTrust}>
            <span aria-hidden>✓</span> Every inspection recorded with photo
            evidence
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
          </div>
          <div className={styles.heroPanelBody}>
            <span className={styles.panelCaption}>
              BUILT FOR EVERY MARKET ROLE
            </span>
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
    title: "Field inspections",
    desc: "Enforcers record each inspection on their phone, with photos as evidence and a timestamp.",
  },
  {
    title: "Warnings and tickets",
    desc: "Issue a warning or a violation ticket during the round. Administrators review each submitted ticket.",
  },
  {
    title: "Business and person records",
    desc: "One searchable record of every business and person, and what has been recorded against them.",
  },
  {
    title: "Analytics",
    desc: "See which violation types and market sections need attention, and how that changes over time.",
  },
  {
    title: "Recommended actions",
    desc: "Suggested inspection actions are ranked for the administrator to review and decide on.",
  },
  {
    title: "Reports and audit trail",
    desc: "Export compliance reports. Every action taken on a record is logged.",
  },
];

function Features() {
  return (
    <section id="features" className={styles.lightSection}>
      <div className={styles.container}>
        <SectionHeading
          eyebrow="Features"
          title="What the system does"
          subtext="Everything the market office needs, from the daily round to the compliance report."
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
    title: "Ticket logged",
    desc: "Market enforcers issue tickets for violations during daily round inspections.",
  },
  {
    num: "02",
    title: "Patterns found",
    desc: "Tickets are grouped over time to show trends, peak periods, and repeat violations across market sections.",
  },
  {
    num: "03",
    title: "Sections and businesses ranked",
    desc: "Market sections are ranked by how many problems they have, and businesses are ranked by risk.",
  },
  {
    num: "04",
    title: "Actions suggested",
    desc: "The administrator reviews the AI-suggested inspection actions and decides what to do.",
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
    <section id="how-it-works" className={styles.tintedSection}>
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
          subtext="Violation type distribution and market-section hotspot ranking, two of the five analytics modules, shown here with example figures."
        />

        {/* Mock dashboard card */}
        <div className={styles.analyticsCard} data-landing-chart>
          {/* header bar */}
          <div className={styles.analyticsHeader}>
            <span className={styles.analyticsDot} />
            <span className={styles.analyticsHeaderText}>
              Administrator / Analytics — Violation Type Distribution
            </span>
            <span className={styles.sampleBadge}>Sample data</span>
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
                        data-landing-bar
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
    name: "Market Enforcers",
    who: "Field staff using the mobile app",
    platform: "Mobile",
    bullets: [
      "Search the business records mid-inspection",
      "Issue a Warning or Violation ticket with photo evidence",
      "Real-time notification when a submitted ticket is reviewed",
    ],
  },
  {
    name: "Administrators",
    who: "Head Admin and Admin Officer",
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
          title="Two roles, one centralized system"
          subtext="Every account is role-based — each user only sees the functions relevant to their responsibilities."
        />
        <div className={`${styles.cardGrid} ${styles.twoColumns}`}>
          {roles.map((r) => (
            <div
              key={r.name}
              className={`${styles.roleCard} ${styles.whiteCard}`}
            >
              <div className={styles.roleHeader}>
                <h3 className={styles.roleTitle}>{r.name}</h3>
                <span className={styles.platform}>{r.platform}</span>
              </div>
              <p className={styles.roleWho}>{r.who}</p>
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

const faqItems = [
  {
    question: "Who can sign in?",
    answer:
      "Administrators (Head Admin and Admin Officer) and Market Enforcers. Each account only sees the functions for its role.",
  },
  {
    question: "How do I register my business?",
    answer:
      "Contact the market office. Staff add and update business records in the system for you.",
  },
  {
    question: "What is recorded in an inspection?",
    answer:
      "The inspection is recorded with photo evidence and a timestamp, and any warning or violation ticket is added to the business's record.",
  },
  {
    question: "How are records kept safe?",
    answer:
      "Access is role-based, and every action taken on a record is written to an audit trail.",
  },
];

function Faq() {
  return (
    <section id="faq" className={styles.lightSection}>
      <div className={styles.container}>
        <SectionHeading eyebrow="QUESTIONS" title="Common questions" />
        <div className={styles.faqList}>
          {faqItems.map((item) => (
            <details key={item.question} className={styles.faqItem}>
              <summary className={styles.faqQuestion}>{item.question}</summary>
              <p className={styles.faqAnswer}>{item.answer}</p>
            </details>
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
        <h2 className={styles.ctaTitle}>For business owners</h2>
        <p className={styles.ctaCopy}>
          Businesses and their owners do not have system login accounts. Contact
          the market office to register or update your business details.
        </p>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className={styles.footer}>
      <div className={`${styles.container} ${styles.footerInner}`}>
        <div className={styles.footerBrand}>
          <img src={citySeal} alt="" />
          <span>
            <strong>Marikina Public Market Inspection System</strong>
            <small>Marikina City</small>
          </span>
        </div>
        <nav className={styles.footerLinks} aria-label="Footer navigation">
          <a href="#features">Features</a>
          <a href="#how-it-works">How it works</a>
          <a href="#faq">Questions</a>
          <Link to="/admin/login">Administrator login</Link>
        </nav>
      </div>
    </footer>
  );
}

export default function LandingPage() {
  const landingRef = useLandingMotion();
  return (
    <div className={`route-motion ${styles.landing}`} ref={landingRef}>
      <Navbar />
      <Hero />
      <Features />
      <Process />
      <AnalyticsPreview />
      <WhoItsFor />
      <Faq />
      <ClosingCta />
      <Footer />
    </div>
  );
}
