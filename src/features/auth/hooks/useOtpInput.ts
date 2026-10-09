import {
  useEffect,
  useRef,
  useState,
  type ClipboardEvent,
  type KeyboardEvent,
} from "react";

export function useOtpInput(disabled: boolean, focusKey?: number) {
  const [code, setCode] = useState<string[]>(Array(6).fill(""));
  const refs = useRef<Array<HTMLInputElement | null>>([]);
  useEffect(() => {
    if (!disabled) refs.current[0]?.focus();
  }, [disabled, focusKey]);
  function changeCode(index: number, value: string) {
    if (disabled) return;
    const digits = value.replace(/\D/g, "").slice(0, 6 - index);
    setCode((previous) => {
      const next = [...previous];
      if (!digits) next[index] = "";
      else
        digits.split("").forEach((digit, offset) => {
          next[index + offset] = digit;
        });
      return next;
    });
    if (digits) refs.current[Math.min(index + digits.length, 5)]?.focus();
  }
  return {
    code,
    changeCode,
    reset: () => setCode(Array(6).fill("")),
    focusFirst: () => refs.current[0]?.focus(),
    setInputRef(index: number, element: HTMLInputElement | null) {
      refs.current[index] = element;
    },
    pasteCode(index: number, event: ClipboardEvent<HTMLInputElement>) {
      event.preventDefault();
      changeCode(index, event.clipboardData.getData("text"));
    },
    keyDown(index: number, event: KeyboardEvent<HTMLInputElement>) {
      if (
        (event.key === "ArrowLeft" ||
          (event.key === "Backspace" && !code[index])) &&
        index > 0
      ) {
        event.preventDefault();
        refs.current[index - 1]?.focus();
      }
      if (event.key === "ArrowRight" && index < 5) {
        event.preventDefault();
        refs.current[index + 1]?.focus();
      }
    },
  };
}

export type OtpCodeModel = Pick<
  ReturnType<typeof useOtpInput>,
  "code" | "changeCode" | "setInputRef" | "pasteCode" | "keyDown"
>;
