import { Link } from "react-router-dom";
import PageHeader from "@/components/ui/PageHeader";
import { ROUTES } from "@/routes/routePaths";
import styles from "./AdminVendorRegistrationsPage.module.css";

export default function AdminVendorRegistrationsPage() {
  return <div className={styles.page}>
    <PageHeader title="Business records" subtitle="Businesses and their owners do not have system login accounts." />
    <p>Create and update business licenses and owner details from the business registry.</p>
    <Link to={ROUTES.adminVendors}>Open Businesses</Link>
  </div>;
}
