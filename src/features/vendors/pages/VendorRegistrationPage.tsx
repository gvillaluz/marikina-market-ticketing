import VendorRegistrationWizard from "@/features/vendors/components/registration/VendorRegistrationWizard";
import { useVendorRegistration } from "@/features/vendors/hooks/useVendorRegistration";
import { useLocation, useNavigate } from "react-router-dom";
import styles from "./VendorRegistrationPage.module.css";

export default function VendorRegistrationPage() {
  const registration = useVendorRegistration();
  const location = useLocation();
  const navigate = useNavigate();
  const returnTo =
    (location.state as { returnTo?: string } | null)?.returnTo ?? "/";

  const handleCancel = () => {
    registration.cancel();
    navigate(returnTo);
  };

  return (
    <main className={styles.page}>
      <VendorRegistrationWizard {...registration} cancel={handleCancel} />
    </main>
  );
}
