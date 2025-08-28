import z from 'zod';

export const LanguageSchema = z
  .string()
  .refine((val) => val.length === 2, { error: 'Must be in ISO 639-1 format' });
