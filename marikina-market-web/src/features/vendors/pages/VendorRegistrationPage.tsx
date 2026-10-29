import { Link } from "react-router-dom";
import styles from "./VendorRegistrationPage.module.css";

export default function VendorRegistrationPage() {
  return <main className={styles.page}>
    <section>
      <h1>Business records</h1>
      <p>Businesses and their owners do not have system login accounts. Contact the market office to register or update your business details.</p>
      <Link to="/">Return to home</Link>
    </section>
  </main>;
}
