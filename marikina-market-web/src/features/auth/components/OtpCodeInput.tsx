import type { OtpCodeModel } from "../hooks/useOtpInput";
import styles from "./OtpCodeInput.module.css";

interface OtpCodeInputProps {
  model: OtpCodeModel;
  disabled: boolean;
  invalid: boolean;
  descriptionId: string;
}

export default function OtpCodeInput({
  model,
  disabled,
  invalid,
  descriptionId,
}: OtpCodeInputProps) {
  return (
    <div className={styles.inputs}>
      {model.code.map((digit, index) => (
        <input
          key={index}
          ref={(element) => model.setInputRef(index, element)}
          className={styles.input}
          aria-label={`Verification digit ${index + 1}`}
          aria-invalid={invalid}
          aria-describedby={descriptionId}
          autoComplete={index === 0 ? "one-time-code" : "off"}
          inputMode="numeric"
          maxLength={6}
          disabled={disabled}
          value={digit}
          onChange={(event) => model.changeCode(index, event.target.value)}
          onPaste={(event) => model.pasteCode(index, event)}
          onKeyDown={(event) => model.keyDown(index, event)}
          onFocus={(event) => event.target.select()}
        />
      ))}
    </div>
  );
}
