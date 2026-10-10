import { Mail, MapPin, UserRound } from "lucide-react";
import PageHeader from "@/components/ui/PageHeader/PageHeader";
import Button from "@/components/ui/Button/Button";
import ProfileSummary from "../components/ProfileSummary";
import ProfileActions from "../components/ProfileActions";
import ProfileInformationSection from "../components/ProfileInformationSection";
import { useProfile } from "../hooks/useProfile";
import { useProfileActions } from "../hooks/useProfileActions";
import ChangePasswordModal from "../components/ChangePasswordModal";
import EditProfileModal from "../components/EditProfileModal";
import { displayProfileValue, formatProfileDate } from "../profile.utils";
import styles from "./ProfilePage.module.css";

export default function ProfilePage() {
  const { profile, isLoading, isRetrying, error, retry } = useProfile();
  const actions = useProfileActions();

  return (
    <div className={styles.page}>
      <p className={styles.context}>My account</p>
      <PageHeader
        title="Profiles"
        subtitle="Manage your personal information and account security."
        actions={
          <ProfileActions
            disabled={!profile || isLoading || Boolean(error)}
            onChangePassword={actions.openPassword}
            onEditProfile={actions.openProfile}
          />
        }
      />
      {isLoading ? (
        <div className={styles.state} role="status">
          Loading your profile…
        </div>
      ) : error ? (
        <div className={styles.state} role="alert">
          <p>{error}</p>
          <Button variant="outline" onClick={retry} loading={isRetrying}>
            Try again
          </Button>
        </div>
      ) : !profile ? (
        <div className={styles.state} role="status">
          <p>No profile information is available.</p>
          <Button variant="outline" onClick={retry} loading={isRetrying}>
            Try again
          </Button>
        </div>
      ) : (
        <div className={styles.layout}>
          <ProfileSummary profile={profile} />
          <div className={styles.information}>
            <ProfileInformationSection
              title="Personal information"
              description="Your name and date of birth on record."
              icon={UserRound}
              fields={[
                {
                  label: "First name",
                  value: displayProfileValue(profile.firstName),
                },
                {
                  label: "Middle name",
                  value: displayProfileValue(profile.middleName),
                },
                {
                  label: "Last name",
                  value: displayProfileValue(profile.lastName),
                },
                {
                  label: "Date of birth",
                  value: formatProfileDate(profile.dateOfBirth, true),
                },
                {
                  label: "Account status",
                  value: profile.status,
                  readOnly: true,
                },
              ]}
            />
            <ProfileInformationSection
              title="Contact information"
              description="Contact details associated with your portal account."
              icon={Mail}
              fields={[
                {
                  label: "Email address",
                  value: displayProfileValue(profile.email),
                },
                {
                  label: "Phone number",
                  value: displayProfileValue(profile.phoneNumber),
                },
              ]}
            />
            <ProfileInformationSection
              title="Residential address"
              icon={MapPin}
              fields={[
                {
                  label: "House number",
                  value: displayProfileValue(profile.houseNumber),
                },
                { label: "Street", value: displayProfileValue(profile.street) },
                {
                  label: "Barangay",
                  value: displayProfileValue(profile.barangay),
                },
                { label: "City", value: displayProfileValue(profile.city) },
              ]}
            />
          </div>
        </div>
      )}
      {actions.activeModal === "password" && (
        <ChangePasswordModal onClose={actions.close} />
      )}
      {actions.activeModal === "profile" && profile && (
        <EditProfileModal profile={profile} onClose={actions.close} />
      )}
    </div>
  );
}
