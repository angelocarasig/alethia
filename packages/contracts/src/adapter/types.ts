import { AuthSchema, LanguageSchema, SearchSchema } from '@repo/schema';
import { z } from 'zod';
import { SearchRequestSchema } from '../api';

export const SearchPresetSchema = z.strictObject({
  name: z.string().trim().max(50).meta({
    description: 'The name of the search preset',
    example: 'Latest Manga',
  }),
  description: z.string().trim().max(200).optional().meta({
    description: 'A brief description of the search preset',
    example: 'Shows the latest manga updates',
  }),
  request: SearchRequestSchema.meta({
    description: 'The search request details',
    examples: [
      {
        // a preset for latest manga example
        query: '',
        page: 1,
        limit: 20,
        sort: 'latest',
      },
      {
        // brainrot academy manhwa for example
        query: '',
        page: 1,
        limit: 20,
        sort: 'popularity',
        direction: 'desc',
        filters: [
          {
            includeTag: ['some-slug-for-academy', 'some-slug-for-manhwa'],
          },
        ],
      },
    ],
  }),
});

export type SearchPreset = z.infer<typeof SearchPresetSchema>;

export const SourceSchema = z.strictObject({
  name: z.string().trim().min(2).max(50).meta({
    description: 'The name of the source',
    example: 'MangaDex',
  }),

  slug: z
    .string()
    .lowercase()
    .trim()
    .min(2)
    .max(50)
    .regex(/^[a-z]+$/, 'Only lowercase alphabet characters are allowed')
    .meta({
      description: 'The unique identifier for the source',
      example: 'mangadex',
    }),

  icon: z.url().meta({
    description: 'The icon of the source',
    example: 'https://example.com/icon.png',
  }),

  languages: z
    .array(LanguageSchema)
    .min(1)
    .describe('The languages supported by the source'),

  nsfw: z
    .boolean()
    .default(false)
    .describe(
      'Whether the source is by default an NSFW (Not Safe For Work) source',
    ),

  url: z.url().describe('The URL of the source'),

  referer: z.string().default('').describe('The referer URL of the source'),

  auth: AuthSchema,

  search: SearchSchema,

  presets: z
    .array(SearchPresetSchema)
    .default([])
    .meta({
      description:
        'Predefined search requests that can be used to quickly access popular or common searches',
      examples: [
        {
          query: 'One Piece',
          page: 1,
        },
        {
          query: '',
          page: 1,
          limit: 5,
          sort: 'latest',
          direction: 'desc',
        },
      ],
    }),
});

export type Source = z.infer<typeof SourceSchema>;

export const HostSchema = z.object({
  name: z
    .string()
    .trim()
    .min(2)
    .max(50)
    .regex(/^[a-z]+$/, 'Only lowercase alphabet characters are allowed')
    .meta({
      description: 'The name of the host',
      example: 'elysium',
    }),

  author: z
    .string()
    .trim()
    .min(2)
    .max(50)
    .regex(/^[a-z]+$/, 'Only lowercase alphabet characters are allowed')
    .meta({
      description: 'The author of the host',
      example: 'alethia',
    }),

  repository: z.url().meta({
    description: 'The repository URL of the host',
    example: 'https://github.com/angelocarasig/alethia',
  }),

  sources: z.array(SourceSchema).meta({
    description: 'The sources available for the host',
    example: [
      {
        name: 'MangaDex',
        slug: 'mangadex',
        icon: 'https://example.com/icon.png',
        languages: ['en', 'es'],
        nsfw: false,
        url: 'https://mangadex.org',
        referer: 'https://mangadex.org',
        auth: AuthSchema,
        search: SearchSchema,
        presets: [],
      },
    ],
  }),
});

export type Host = z.infer<typeof HostSchema>;

/**
 * Helper type to define a mapping object whose keys must exactly match
 * the elements of a readonly tuple of strings (e.g., supported sorts/filters).
 */
export type MappingFor<Keys extends readonly string[], V> = {
  [K in Keys[number]]: V;
};
