import { FC, ReactNode } from 'react';
import { Link } from 'react-router-dom';
import citySeal from '@/assets/icons/Marikina_City_Seal.svg (1).webp';

interface AuthLayoutProps {

  subtext: string;

  showBackHome?: boolean;
  children: ReactNode;
}


const AuthLayout: FC<AuthLayoutProps> = ({ subtext, showBackHome = true, children }) => {
  return (
    <div className="min-h-screen bg-page flex flex-col">
      {showBackHome && (
        <div className="px-6 md:px-10 pt-6">
          <Link
            to="/"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-md bg-primary text-on-primary font-semibold text-sm hover:bg-primary-hover transition-colors"
          >
            <span aria-hidden>←</span> Back Home
          </Link>
        </div>
      )}

      {/* Centered card */}
      <div className="flex-1 flex items-center justify-center px-4 py-10">
        <div className="w-full max-w-4xl rounded-xl shadow-lg overflow-hidden flex flex-col md:flex-row bg-surface">
          {/* Left — navy panel */}
          <div className="bg-primary md:w-[45%] px-8 md:px-10 py-10 md:py-14 flex flex-col items-center justify-center text-center">
            <div className="w-20 h-20 rounded-full bg-white/10 border-2 border-white/40 flex items-center justify-center">
              <img className="w-full h-full rounded-full object-contain" src={citySeal} alt="Marikina City seal" />
            </div>
            <h1 className="mt-6 font-mono font-bold text-on-primary text-2xl md:text-3xl leading-tight">
              Marikina Public Market Inspection System
            </h1>
            <p className="mt-3 text-on-primary/90 text-sm">{subtext}</p>
          </div>

          {/* Right — form panel */}
          <div className="bg-surface flex-1 px-8 md:px-12 py-10 md:py-14">{children}</div>
        </div>
      </div>
    </div>
  );
};

export default AuthLayout;
