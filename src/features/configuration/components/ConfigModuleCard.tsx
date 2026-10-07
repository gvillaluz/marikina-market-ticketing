import { FC } from "react";
import { Link } from "react-router-dom";
import { ChevronRight, LucideIcon } from "lucide-react";
import styles from "./ConfigModuleCard.module.css";

interface ConfigModuleCardProps {
  icon: LucideIcon;
  iconColor: string;
  iconBg: string;
  title: string;
  description: string;
  href: string;
}

const ConfigModuleCard: FC<ConfigModuleCardProps> = ({
  icon: Icon,
  iconColor,
  iconBg,
  title,
  description,
  href,
}) => {
  return (
    <Link to={href} className={styles.card}>
      <div
        className={styles.iconWrap}
        style={{ background: iconBg, color: iconColor }}
      >
        <Icon size={18} strokeWidth={2} />
      </div>
      <div className={styles.text}>
        <span className={styles.title}>{title}</span>
        <span className={styles.description}>{description}</span>
      </div>
      <ChevronRight size={16} className={styles.chevron} />
    </Link>
  );
};

export default ConfigModuleCard;
