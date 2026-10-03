import VendorRegistrationWizard from "@/features/vendors/components/registration/VendorRegistrationWizard";
import { useVendorRegistration } from "@/features/vendors/hooks/useVendorRegistration";
import styles from "./VendorRegistrationPage.module.css";

export default function VendorRegistrationPage() {
  const registration = useVendorRegistration();

  return (
    <main className={styles.page}>
      <VendorRegistrationWizard {...registration} />
    </main>
  );
}
