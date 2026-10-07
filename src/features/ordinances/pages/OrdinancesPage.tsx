import { ChevronRight, FileText, Plus } from 'lucide-react';
import { Link } from 'react-router-dom';
import { ROUTES } from '@/routes/routePaths';
import { useOrdinances } from '../hooks/useOrdinances';
import { useOrdinanceEditor } from '../hooks/useOrdinanceEditor';
import OrdinanceRegistry from '../components/OrdinanceRegistry';
import OrdinanceEditorModal from '../components/OrdinanceEditorModal';
import controls from '../components/OrdinanceControls.module.css';
import styles from './OrdinancesPage.module.css';

export default function OrdinancesPage() {
  const directory = useOrdinances();
  const editor = useOrdinanceEditor();
  return (
    <div className={styles.page}>
      <nav className={styles.breadcrumb} aria-label="Breadcrumb"><Link to={ROUTES.systemConfiguration}>System Configuration</Link><ChevronRight size={12} aria-hidden="true" /><span aria-current="page">Ordinances &amp; Penalties</span></nav>
      <header className={styles.header}>
        <div><h1>Ordinances &amp; Penalties</h1><p>Maintain enforceable rules and offense-based penalty tiers.</p></div>
        <button type="button" className={`${controls.button} ${controls.primary} ${styles.create}`} disabled={!editor.canManage || !directory.hasData || editor.isSaving || editor.open} onClick={() => editor.launch()}><Plus size={15} aria-hidden="true" />New Ordinance</button>
      </header>
      <OrdinanceRegistry directory={directory} disabled={!editor.canManage || editor.isSaving || editor.open} onManage={editor.launch} />
      <aside className={styles.notice}><span className={styles.noticeIcon}><FileText size={19} aria-hidden="true" /></span><div><h2>How penalty tiers work</h2><p>Set one amount and severity for each offense number. Ticket totals are calculated from the applicable tier.</p></div></aside>
      <OrdinanceEditorModal editor={editor} />
    </div>
  );
}
