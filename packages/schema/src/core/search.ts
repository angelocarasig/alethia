import { z } from 'zod';

export const SortOptionSchema = z.enum([
  'relevance',
  'latest',
  'title',
  'popularity',
  'rating',
  'chapters',
  'alphabetical',
  'year',
  'views',
  'follows',
]);

export const FilterOptionSchema = z.enum([
  'genre',
  'status',
  'contentRating',
  'year',
  'language',
  'author',
  'artist',
  'includeTag',
  'excludeTag',
  'demographic',
  'publisher',
]);

export const SearchSchema = z.object({
  sort: z.array(SortOptionSchema).default(['relevance']),

  filters: z.array(FilterOptionSchema).default([]),
});

export type SortOption = z.infer<typeof SortOptionSchema>;
export type FilterOption = z.infer<typeof FilterOptionSchema>;
export type Search = z.infer<typeof SearchSchema>;
