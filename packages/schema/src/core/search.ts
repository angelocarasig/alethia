import { z } from 'zod';
import { TagSchema } from './tag';

export const SortOptionSchema = z.enum([
  'relevance',
  'latest',
  'title',
  'popularity',
  'rating',
  'chapters',
  'year',
  'views',
  'follows',
  'createdAt',
  'updatedAt',
]);

export const FilterOptionSchema = z.enum([
  'genre',
  'status',
  'contentRating',
  'year',
  'originalLanguage',
  'translatedLanguage',
  'author',
  'artist',
  'includeTag',
  'excludeTag',
  'demographic',
  'publisher',
  'minChapters',
]);

export const SearchSchema = z.object({
  sort: z.array(SortOptionSchema).default(['relevance']),

  filters: z.array(FilterOptionSchema).default([]),

  tags: z.array(TagSchema).default([]),
});

export type SortOption = z.infer<typeof SortOptionSchema>;
export type FilterOption = z.infer<typeof FilterOptionSchema>;
export type Search = z.infer<typeof SearchSchema>;
