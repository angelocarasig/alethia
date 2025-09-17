import { z } from 'zod';

export const LanguageSchema = z.string().regex(/^[a-z]{2}(-[a-z]{2,4})?$/i, {
  message:
    'Must be ISO 639-1 format (e.g., "en") or with subtag (e.g., "pt-br", "ko-ro")',
});

export type Language = z.infer<typeof LanguageSchema>;
