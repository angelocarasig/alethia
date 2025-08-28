import z from 'zod';
import { MangaSchema } from './manga';

export const EntrySchema = MangaSchema.pick({
  slug: true,
  title: true,
}).extend({
  cover: z.url().describe('The URL of the cover image for the manga'),
});

export type Entry = z.infer<typeof EntrySchema>;
