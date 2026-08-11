import { FC } from 'react';
import { Link } from 'react-router-dom';
import VendorRegistrationWizard from '@/features/vendors/components/registration/VendorRegistrationWizard';

const VendorRegistrationPage: FC = () => {
  return (
    <div className="min-h-screen bg-page flex flex-col">
      {/* Back Home */}
      <div className="px-6 md:px-10 pt-6">
        <Link
          to="/"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-md bg-primary text-on-primary font-semibold text-sm hover:bg-primary-hover transition-colors"
        >
          <span aria-hidden>←</span> Back Home
        </Link>
      </div>

      {/* Centered wizard */}
      <div className="flex-1 flex items-center justify-center px-4 py-10">
        <VendorRegistrationWizard />
      </div>
    </div>
  );
};

export default VendorRegistrationPage;
