import { z } from 'zod';
import { EntrySchema, SortOptionSchema } from '@repo/schema';

export const SearchRequestSchema = z.object({
  query: z.string().trim().default('').describe('Search query text'),

  page: z
    .number()
    .min(1, 'Page must be at least 1')
    .default(1)
    .describe('Page number for pagination'),

  limit: z
    .number()
    .min(1, 'Limit can not be less than 1')
    .max(100, 'Limit can only be defined up to 100')
    .default(20)
    .describe('Number of results per page'),

  sort: SortOptionSchema.default('relevance').describe('Sort option'),

  direction: z.enum(['asc', 'desc']).default('desc').describe('Sort direction'),

  filters: z
    .record(
      z.string(),
      z.union([
        // string filter i.e. author, artist
        z.string(),

        // array filter i.e. includeTag, excludeTag
        z.array(z.string()),

        // number filter i.e. minRating, year
        z.number(),

        // boolean filter i.e. nsfw
        z.boolean(),
      ]),
    )
    .optional()
    .describe('Filter key-value pairs (keys must be supported by source)'),
});

export type SearchRequest = z.infer<typeof SearchRequestSchema>;

export const SearchResponseSchema = z.object({
  results: z.array(EntrySchema).describe('Array of manga matching the search'),

  page: z.number().describe('Current page number'),

  more: z.boolean().describe('Whether more results are available'),
});

export type SearchResponse = z.infer<typeof SearchResponseSchema>;
