import PageHeader from "@/components/ui/PageHeader";
import PersonRegistry from "../components/PersonRegistry";
import PersonFormModal from "../components/PersonFormModal";
import { usePersonsPage } from "../hooks/usePersonsPage";
import styles from "./AdminPersonsPage.module.css";

export default function AdminPersonsPage() {
  const state = usePersonsPage();
  return <div className={styles.page}>
    <PageHeader title="Persons" subtitle="Maintain individual names, addresses and contact details separately from businesses." />
    <PersonRegistry {...state} />
    <PersonFormModal open={state.open} personId={state.personId} onClose={state.close} onSaved={state.onSaved} />
  </div>;
}
