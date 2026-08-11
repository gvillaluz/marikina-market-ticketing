import { Link } from 'react-router-dom';

/* ------------------------------------------------------------------ */
/* Shared building blocks                                              */
/* ------------------------------------------------------------------ */

interface EyebrowProps {
  text: string;
  light?: boolean;
}

function Eyebrow({ text, light = false }: EyebrowProps) {
  return (
    <p
      className={`text-center text-xs font-bold tracking-[0.25em] uppercase ${
        light ? 'text-accent' : 'text-accent'
      }`}
    >
      {text}
    </p>
  );
}

interface SectionHeadingProps {
  eyebrow: string;
  title: string;
  subtext?: string;
  light?: boolean;
  className?: string;
}

function SectionHeading({ eyebrow, title, subtext, light = false, className = '' }: SectionHeadingProps) {
  return (
    <div className={`max-w-2xl mx-auto text-center ${className}`}>
      <Eyebrow text={eyebrow} light={light} />
      <h2
        className={`mt-3 font-mono text-3xl md:text-4xl font-bold leading-tight ${
          light ? 'text-white' : 'text-primary'
        }`}
      >
        {title}
      </h2>
      {subtext && (
        <p className={`mt-4 text-base md:text-lg ${light ? 'text-gray-200' : 'text-bodygray'}`}>
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
    <header className="sticky top-0 z-50 bg-white border-b border-gray-200">
      <div className="max-w-[1200px] mx-auto px-4 md:px-8 h-16 flex items-center justify-between">
        <button
          className="text-left font-mono font-bold text-primary text-sm md:text-base leading-tight"
          onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
        >
          Marikina Public Market
          <span className="block">Inspection System</span>
        </button>

        <nav className="hidden md:flex items-center gap-8">
          <a href="#top" className="text-primary font-medium border-b-2 border-primary pb-0.5">
            Home
          </a>
          <a href="#features" className="text-bodygray hover:text-primary transition-colors">
            About
          </a>
          <a href="#contact" className="text-bodygray hover:text-primary transition-colors">
            Contact
          </a>
        </nav>

        <div className="flex items-center gap-3">
          <Link
            to="/login"
            className="px-4 py-2 rounded-md border border-primary text-primary font-medium text-sm hover:bg-primary/5 transition-colors"
          >
Login
          </Link>
          <Link
            to="/register"
            className="px-4 py-2 rounded-md bg-primary text-white font-medium text-sm hover:bg-primary/90 transition-colors"
          >
            Vendor Registration
          </Link>
        </div>
      </div>
    </header>
  );
}

/* ------------------------------------------------------------------ */
/* Section 2 — Hero                                                    */
/* ------------------------------------------------------------------ */

function Hero() {
  return (
    <section className="relative" id="top">
      {/* Scene background (market building with palms) */}
      <div
        className="absolute inset-0"
        style={{
          backgroundImage: `linear-gradient(180deg, #0B2D5B 0%, #3a6aa5 45%, #7fb3d5 70%, #c9b98a 100%)`,
        }}
      >
        {/* arched colonial facade */}
        <div
          className="absolute inset-0"
          style={{
            backgroundImage:
              'radial-gradient(circle at 50% 40%, rgba(255,255,255,0.18) 0%, transparent 55%), repeating-linear-gradient(90deg, rgba(255,255,255,0.10) 0 2px, transparent 2px 90px)',
          }}
        />
        {/* palm silhouettes */}
        <div
          className="absolute inset-0"
          style={{
            backgroundImage:
              'radial-gradient(ellipse at 12% 78%, rgba(11,45,91,0.28) 0%, transparent 30%), radial-gradient(ellipse at 88% 78%, rgba(11,45,91,0.28) 0%, transparent 30%)',
          }}
        />
      </div>

      {/* white overlay ~70% */}
      <div className="absolute inset-0 bg-white/70" />

      <div className="relative max-w-[1200px] mx-auto px-4 md:px-8 py-24 md:py-28 min-h-[400px] flex items-center">
        <div className="max-w-2xl">
          <h1 className="font-mono text-4xl md:text-5xl lg:text-6xl font-bold text-primary leading-[1.05]">
            A Smarter Public Market for a Better Marikina.
          </h1>
          <p className="mt-6 text-lg md:text-xl text-bodygray max-w-xl">
            Empowering Marikina with smart technology by analyzing ticketing patterns to
            automatically optimize inspection allocations.
          </p>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/* Section 3 — System Features                                         */
/* ------------------------------------------------------------------ */

const featureCards = [
  {
    title: 'Time-Series Analysis',
    desc: 'Market officers can log violations during daily rounds, capturing every incident with photo evidence and timestamps for a complete record.',
  },
  {
    title: 'Frequency Distribution',
    desc: 'Trend lines, peak periods, and recurring violation types are surfaced across market sections, turning raw tickets into clear pattern.',
  },
  {
    title: 'AI Decision Support',
    desc: 'A weighted scoring model ranks vendor risk and auto-suggests inspection actions, reviewed by the Administrator through natural language.',
  },
];

function Features() {
  return (
    <section id="features" className="bg-white py-20 md:py-24">
      <div className="max-w-[1200px] mx-auto px-4 md:px-8">
        <SectionHeading
          eyebrow="System Features"
          title="Key implementing technologies of the system"
        />
        <div className="mt-14 grid grid-cols-1 md:grid-cols-3 gap-6">
          {featureCards.map((c) => (
            <div
              key={c.title}
              className="bg-bglight-card rounded-xl p-8 hover:shadow-lg transition-shadow"
            >
              <h3 className="font-mono text-xl font-bold text-primary">{c.title}</h3>
              <p className="mt-4 text-bodygray leading-relaxed">{c.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/* Section 4 — Process                                                 */
/* ------------------------------------------------------------------ */

const processSteps = [
  {
    num: '01',
    title: 'Tickets Logged',
    desc: 'Market officers issue tickets for violations during daily round inspections.',
  },
  {
    num: '02',
    title: 'Patterns aggregated',
    desc: 'Time-series analysis and frequency distribution surface trend lines, peak periods, and recurring violation types across market sections.',
  },
  {
    num: '03',
    title: 'Sections and vendors ranked',
    desc: 'Aggregation and ranking builds a market-section hotspot ranking, while a weighted scoring model ranks vendor risk.',
  },
  {
    num: '04',
    title: 'AI inspection recommendations',
    desc: 'The Administrator reviews the AI suggested actions in NLP.',
  },
];

function ProcessStep({ num, title, desc, arrow }: { num: string; title: string; desc: string; arrow: boolean }) {
  return (
    <div className="flex flex-col md:flex-row items-center gap-4 md:gap-6">
      <div className="flex-1 text-center md:text-left">
        <p className="font-mono text-2xl font-bold text-accent">{num}</p>
        <h3 className="mt-2 font-mono text-lg font-bold text-primary">{title}</h3>
        <p className="mt-2 text-bodygray text-sm leading-relaxed">{desc}</p>
      </div>
      {arrow && (
        <span className="text-accent text-2xl font-bold flex-shrink-0 hidden md:block">→</span>
      )}
      {arrow && <span className="text-accent text-xl font-bold md:hidden">↓</span>}
    </div>
  );
}

function Process() {
  return (
    <section className="bg-bglight py-20 md:py-24">
      <div className="max-w-[1200px] mx-auto px-4 md:px-8">
        <SectionHeading eyebrow="PROCESS" title="From ticket to inspection, automatically" />
        <div className="mt-14 grid grid-cols-1 md:grid-cols-4 gap-8">
          {processSteps.map((s, i) => (
            <ProcessStep key={s.num} {...s} arrow={i < processSteps.length - 1} />
          ))}
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/* Section 5 — Analytics Dashboard preview                             */
/* ------------------------------------------------------------------ */

const bars = [
  { label: 'Sanitation', width: '100%' },
  { label: 'Weight', width: '82%' },
  { label: 'Obstruction', width: '64%' },
  { label: 'Licensing', width: '47%' },
  { label: 'Noise', width: '30%' },
];

const hotspots = [
  { label: 'Dry Goods Section A', level: 'High' },
  { label: 'Dry Goods Section B', level: 'Medium' },
  { label: 'Wet Section A', level: 'Medium' },
  { label: 'Wet Section B', level: 'Low' },
];

const levelStyles: Record<string, string> = {
  High: 'bg-accent text-white',
  Medium: 'bg-bglight text-primary',
  Low: 'bg-bglight text-bodygray',
};

function AnalyticsPreview() {
  return (
    <section className="bg-white py-20 md:py-24">
      <div className="max-w-[1200px] mx-auto px-4 md:px-8">
        <SectionHeading
          eyebrow="ANALYTICS DASHBOARD"
          title="What the Administrator dashboard shows"
          subtext="Violation type distribution and market-section hotspot ranking, two of the five analytics modules, translated into a helpful analytics."
        />

        {/* Mock dashboard card */}
        <div className="mt-14 max-w-4xl mx-auto rounded-xl overflow-hidden shadow-lg border border-gray-200">
          {/* header bar */}
          <div className="bg-primary px-5 py-3 flex items-center gap-3">
            <span className="w-2.5 h-2.5 rounded-full bg-white" />
            <span className="text-white/90 text-sm font-medium">
              Administrator / Analytics — Violation Type Distribution
            </span>
          </div>

          {/* body */}
          <div className="bg-white p-6 md:p-8 grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* left: bar chart */}
            <div>
              <h3 className="font-mono text-sm font-bold text-primary mb-4">
                Violation Type Distribution
              </h3>
              <div className="space-y-4">
                {bars.map((b) => (
                  <div key={b.label}>
                    <div className="flex justify-between text-sm mb-1">
                      <span className="font-semibold text-primary">{b.label}</span>
                    </div>
                    <div className="h-3 w-full bg-bglight rounded-full overflow-hidden">
                      <div
                        className="h-full bg-accent rounded-full"
                        style={{ width: b.width }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* right: hotspot ranking */}
            <div className="bg-bglight-card rounded-xl p-5">
              <h3 className="font-mono text-sm font-bold text-primary mb-4">
                Market Section Hotspot Ranking
              </h3>
              <div>
                {hotspots.map((h, i) => (
                  <div
                    key={h.label}
                    className={`py-3 flex items-center justify-between ${
                      i > 0 ? 'border-t border-gray-200' : ''
                    }`}
                  >
                    <span className="text-sm font-medium text-primary">{h.label}</span>
                    <span
                      className={`text-xs font-semibold px-2.5 py-1 rounded-full ${levelStyles[h.level]}`}
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

/* ------------------------------------------------------------------ */
/* Section 6 — Who it's for                                            */
/* ------------------------------------------------------------------ */

const roles = [
  {
    name: 'Market Enforcer',
    platform: 'Mobile',
    bullets: [
      "Scan a vendor's QR code or search the registry mid-inspection",
      'Issue a Warning or Violation ticket with photo evidence',
      'Real-time notification when a submitted ticket is reviewed',
    ],
  },
  {
    name: 'Market Vendor',
    platform: 'Portal',
    bullets: [
      'View every ticket issued against your stall, with evidence',
      'Track your compliance score and unpaid penalties',
      'Upload a payment receipt for Administrator review',
      'Download tickets and your QR code',
    ],
  },
  {
    name: 'Administrator',
    platform: 'Web',
    bullets: [
      'Review submitted tickets and update vendor status',
      'Manage the vendor registry and enforcer accounts',
      'View pattern analytics and export compliance reports',
      'Full audit trail of every action taken on a record',
    ],
  },
];

function WhoItsFor() {
  return (
    <section className="bg-bglight py-20 md:py-24">
      <div className="max-w-[1200px] mx-auto px-4 md:px-8">
        <SectionHeading
          eyebrow="WHO IT'S FOR"
          title="Three roles, one centralized system"
          subtext="Every account is role-based — each user only sees the functions relevant to their responsibilities."
        />
        <div className="mt-14 grid grid-cols-1 md:grid-cols-3 gap-6">
          {roles.map((r) => (
            <div key={r.name} className="bg-white rounded-xl p-8 shadow-sm">
              <div className="flex items-center justify-between gap-3">
                <h3 className="font-mono text-lg font-bold text-primary">{r.name}</h3>
                <span className="text-xs font-semibold px-3 py-1 rounded-full bg-bglight text-primary">
                  {r.platform}
                </span>
              </div>
              <ul className="mt-5 space-y-3">
                {r.bullets.map((b) => (
                  <li key={b} className="text-bodygray text-sm leading-relaxed flex gap-2">
                    <span className="text-accent flex-shrink-0">—</span>
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

/* ------------------------------------------------------------------ */
/* Section 7 — Closing CTA                                             */
/* ------------------------------------------------------------------ */

function ClosingCta() {
  return (
    <section id="contact" className="bg-primary py-20 md:py-24">
      <div className="max-w-[1200px] mx-auto px-4 md:px-8 text-center">
<h2 className="font-mono text-3xl md:text-4xl font-bold text-white">
          Register your stall today.
        </h2>
        <p className="mt-5 text-gray-200 max-w-xl mx-auto text-lg">
          Submit a valid ID and business registration document — the Administrator reviews
          and approves your account against the existing vendor registry.
        </p>
        <Link
          to="/register"
          className="inline-block mt-8 px-8 py-3.5 rounded-md bg-accent text-white font-bold text-base hover:bg-accent/90 transition-colors"
        >
          Vendor Registration
        </Link>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/* Page                                                                */
/* ------------------------------------------------------------------ */

export default function LandingPage() {
  return (
    <div className="font-sans bg-white">
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
