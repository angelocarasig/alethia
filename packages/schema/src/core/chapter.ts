import z from 'zod';
import { LanguageSchema } from '../common';

export const ChapterSchema = z.strictObject({
  slug: z
    .string()
    .min(1, 'Slug must be at least 1 character long')
    .describe(
      'The unique identifier for the manga, typically a URL-friendly string',
    ),

  title: z
    .string()
    .trim()
    .default('No Title')
    .describe('The title of the manga'),

  number: z
    .number()
    .min(0, 'Chapter number can not be negative.')
    .default(0)
    .describe('The chapter number'),

  scanlator: z
    .string()
    .default('Unknown Scanlator')
    .describe('The scanlator of the chapter'),

  language: LanguageSchema.describe('The language of the chapter'),

  url: z.url().describe('The URL of the chapter'),

  date: z.iso
    .datetime({ local: false, offset: true, precision: 0 })
    .describe('The date when the chapter was published'),
});

export type Chapter = z.infer<typeof ChapterSchema>;
