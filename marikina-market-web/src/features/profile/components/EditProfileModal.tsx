import { Mail, MapPin, UserRound } from "lucide-react";
import type { ProfileResponse } from "@/api/endpoints/profile.api";
import { useProfileEditor } from "../hooks/useProfileEditor";
import { todayDate, type ProfileField } from "../profile.validation";
import ProfileFormModal from "./ProfileFormModal";
import ProfileFormSection from "./ProfileFormSection";
import ProfileFormField from "./ProfileFormField";
import styles from "./EditProfileModal.module.css";

interface EditProfileModalProps {
  profile: ProfileResponse;
  onClose: () => void;
}
interface Field {
  name: ProfileField | "username";
  label: string;
  type?: "text" | "email" | "tel" | "date";
  autoComplete?: string;
}

const sections = [
  {
    title: "Personal information",
    description: "Update your name and date of birth.",
    icon: UserRound,
    fields: [
      { name: "firstName", label: "First name", autoComplete: "given-name" },
      {
        name: "middleName",
        label: "Middle name",
        autoComplete: "additional-name",
      },
      { name: "lastName", label: "Last name", autoComplete: "family-name" },
      {
        name: "dateOfBirth",
        label: "Date of birth",
        type: "date",
        autoComplete: "bday",
      },
      { name: "username", label: "Username", autoComplete: "username" },
    ],
  },
  {
    title: "Contact information",
    icon: Mail,
    fields: [
      {
        name: "email",
        label: "Email address",
        type: "email",
        autoComplete: "email",
      },
      {
        name: "phoneNumber",
        label: "Phone number",
        type: "tel",
        autoComplete: "tel",
      },
    ],
  },
  {
    title: "Residential address",
    icon: MapPin,
    fields: [
      { name: "houseNumber", label: "House number" },
      { name: "street", label: "Street" },
      { name: "barangay", label: "Barangay", autoComplete: "address-level3" },
      { name: "city", label: "City", autoComplete: "address-level2" },
    ],
  },
] satisfies {
  title: string;
  description?: string;
  icon: typeof UserRound;
  fields: Field[];
}[];

export default function EditProfileModal({
  profile,
  onClose,
}: EditProfileModalProps) {
  const editor = useProfileEditor(profile, onClose);
  return (
    <ProfileFormModal
      title="Edit profile"
      description="Update your personal information, contact details, and address."
      size="lg"
      formId="edit-profile-form"
      submitLabel="Save changes"
      isSaving={editor.isSaving}
      canSubmit={editor.canSubmit}
      error={editor.error}
      onClose={editor.close}
      onSubmit={editor.submit}
    >
      <div className={styles.sections}>
        {sections.map((section) => (
          <ProfileFormSection
            key={section.title}
            title={section.title}
            description={
              "description" in section ? section.description : undefined
            }
            icon={section.icon}
            personal={section.title === "Personal information"}
          >
            {section.fields.map((field: Field) => (
              <ProfileFormField
                key={field.name}
                id={`profile-${field.name}`}
                label={field.label}
                type={field.type}
                value={
                  field.name === "username"
                    ? profile.username
                    : editor.values[field.name]
                }
                required={field.name !== "middleName"}
                onChange={(value) => {
                  if (field.name !== "username")
                    editor.change(field.name, value);
                }}
                onBlur={() => {
                  if (field.name !== "username") editor.blur(field.name);
                }}
                error={
                  field.name !== "username" && editor.touched[field.name]
                    ? editor.errors[field.name]
                    : undefined
                }
                disabled={field.name === "username" || editor.isSaving}
                autoComplete={field.autoComplete}
                max={field.type === "date" ? todayDate() : undefined}
              />
            ))}
          </ProfileFormSection>
        ))}
      </div>
    </ProfileFormModal>
  );
}
