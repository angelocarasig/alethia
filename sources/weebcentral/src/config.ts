import { Source } from '@repo/contracts';
import { Tag } from '@repo/schema';

import { PRESETS } from './presets';

const SERIES_TYPES: Tag[] = [
  {
    slug: 'Manga',
    name: 'Manga',
    nsfw: false,
  },
  {
    slug: 'Manhwa',
    name: 'Manhwa',
    nsfw: false,
  },
  {
    slug: 'Manhua',
    name: 'Manhua',
    nsfw: false,
  },
  {
    slug: 'OEL',
    name: 'OEL',
    nsfw: false,
  },
];

export const TAGS: Tag[] = [
  {
    slug: 'Action',
    name: 'Action',
    nsfw: false,
  },
  {
    slug: 'Adult',
    name: 'Adult',
    nsfw: true,
  },
  {
    slug: 'Adventure',
    name: 'Adventure',
    nsfw: false,
  },
  {
    slug: 'Comedy',
    name: 'Comedy',
    nsfw: false,
  },
  {
    slug: 'Doujinshi',
    name: 'Doujinshi',
    nsfw: false,
  },
  {
    slug: 'Drama',
    name: 'Drama',
    nsfw: false,
  },
  {
    slug: 'Ecchi',
    name: 'Ecchi',
    nsfw: true,
  },
  {
    slug: 'Fantasy',
    name: 'Fantasy',
    nsfw: false,
  },
  {
    slug: 'Gender+Bender',
    name: 'Gender Bender',
    nsfw: false,
  },
  {
    slug: 'Harem',
    name: 'Harem',
    nsfw: false,
  },
  {
    slug: 'Hentai',
    name: 'Hentai',
    nsfw: true,
  },
  {
    slug: 'Historical',
    name: 'Historical',
    nsfw: false,
  },
  {
    slug: 'Horror',
    name: 'Horror',
    nsfw: false,
  },
  {
    slug: 'Isekai',
    name: 'Isekai',
    nsfw: false,
  },
  {
    slug: 'Josei',
    name: 'Josei',
    nsfw: false,
  },
  {
    slug: 'Lolicon',
    name: 'Lolicon',
    nsfw: true,
  },
  {
    slug: 'Martial+Arts',
    name: 'Martial Arts',
    nsfw: false,
  },
  {
    slug: 'Mature',
    name: 'Mature',
    nsfw: true,
  },
  {
    slug: 'Mecha',
    name: 'Mecha',
    nsfw: false,
  },
  {
    slug: 'Mystery',
    name: 'Mystery',
    nsfw: false,
  },
  {
    slug: 'Psychological',
    name: 'Psychological',
    nsfw: false,
  },
  {
    slug: 'Romance',
    name: 'Romance',
    nsfw: false,
  },
  {
    slug: 'School+Life',
    name: 'School Life',
    nsfw: false,
  },
  {
    slug: 'Sci-fi',
    name: 'Sci-fi',
    nsfw: false,
  },
  {
    slug: 'Seinen',
    name: 'Seinen',
    nsfw: false,
  },
  {
    slug: 'Shotacon',
    name: 'Shotacon',
    nsfw: true,
  },
  {
    slug: 'Shoujo',
    name: 'Shoujo',
    nsfw: false,
  },
  {
    slug: 'Shoujo+Ai',
    name: 'Shoujo Ai',
    nsfw: false,
  },
  {
    slug: 'Shounen',
    name: 'Shounen',
    nsfw: false,
  },
  {
    slug: 'Shounen+Ai',
    name: 'Shounen Ai',
    nsfw: false,
  },
  {
    slug: 'Slice+of+Life',
    name: 'Slice of Life',
    nsfw: false,
  },
  {
    slug: 'Smut',
    name: 'Smut',
    nsfw: true,
  },
  {
    slug: 'Sports',
    name: 'Sports',
    nsfw: false,
  },
  {
    slug: 'Supernatural',
    name: 'Supernatural',
    nsfw: false,
  },
  {
    slug: 'Tragedy',
    name: 'Tragedy',
    nsfw: false,
  },
  {
    slug: 'Yaoi',
    name: 'Yaoi',
    nsfw: true,
  },
  {
    slug: 'Yuri',
    name: 'Yuri',
    nsfw: false,
  },
  {
    slug: 'Other',
    name: 'Other',
    nsfw: false,
  },
];

export const SUPPORTED_SORTS = [
  'title',
  'popularity',
  'follows',
  'createdAt',
  'updatedAt',
  'relevance',
] as const;

export const SUPPORTED_FILTERS = ['includeTag', 'status'] as const;

export const config: Source = {
  name: 'WeebCentral',
  slug: 'weebcentral',
  icon: 'https://raw.githubusercontent.com/angelocarasig/alethia/refs/heads/main/sources/weebcentral/public/icon.png',
  languages: ['en'],
  nsfw: false,
  url: 'https://weebcentral.com',
  referer: 'https://weebcentral.com',
  auth: {
    type: 'none',
    required: false,
  },
  search: {
    // must update any fields inside of the source mappings if changed here
    sort: [...SUPPORTED_SORTS],
    filters: [...SUPPORTED_FILTERS],
    tags: [...SERIES_TYPES, ...TAGS],
  },
  presets: [...PRESETS],
} as const;
