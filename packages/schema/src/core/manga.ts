import { z } from 'zod';
import { ClassificationSchema, PublicationSchema } from '../common';

export const MangaSchema = z.strictObject({
  slug: z
    .string()
    .min(1, 'Slug must be at least 1 character long')
    .describe(
      'The unique identifier for the manga, typically a URL-friendly string',
    ),

  title: z
    .string()
    .trim()
    .default('Unknown Title')
    .describe('The default display title of the manga'),

  authors: z
    .array(z.string())
    .default([])
    .describe('List of authors of the manga'),

  alternativeTitles: z
    .array(z.string())
    .default([])
    .describe('List of alternative titles for the manga'),

  synopsis: z
    .string()
    .trim()
    .default('No Description.')
    .describe('A brief summary or description of the manga'),

  createdAt: z.iso
    .datetime({ local: false, offset: false, precision: 0 })
    .describe('The date and time when the manga was created'),

  updatedAt: z.iso
    .datetime({ local: false, offset: false, precision: 0 })
    .describe('The last time the manga was updated'),

  classification: ClassificationSchema,

  publication: PublicationSchema,

  tags: z
    .array(z.string().trim())
    .describe(
      'List of tags for the manga (alias for categories, genres, demographic, etc.)',
    ),

  covers: z
    .array(z.url())
    .default([])
    .describe('List of cover image URLs for the manga'),

  url: z.url().describe('The URL of the manga'),
});

export type Manga = z.infer<typeof MangaSchema>;
