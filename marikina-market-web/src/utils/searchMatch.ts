export interface SearchPart {
  text: string;
  match: boolean;
}

const LETTER_OR_DIGIT = "[\\p{L}\\p{N}]";

function escapePattern(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// Splits text into the parts that match the search (any capital letters) and the parts between.
export function searchParts(text: string, search: string): SearchPart[] {
  const term = search.trim();
  if (!term) return [{ text, match: false }];
  return text
    .split(new RegExp(`(${escapePattern(term)})`, "iu"))
    .map((part, index) => ({ text: part, match: index % 2 === 1 }))
    .filter((part) => part.text);
}

// Rows where the search appears as a whole word in any value come first; both groups keep their order.
export function exactMatchesFirst<T>(
  items: T[],
  search: string,
  values: (item: T) => string[],
): T[] {
  const term = search.trim();
  if (!term) return items;
  const wholeWord = new RegExp(
    `(?<!${LETTER_OR_DIGIT})${escapePattern(term)}(?!${LETTER_OR_DIGIT})`,
    "iu",
  );
  const exact: T[] = [];
  const rest: T[] = [];
  for (const item of items)
    (values(item).some((value) => wholeWord.test(value)) ? exact : rest).push(
      item,
    );
  return [...exact, ...rest];
}
