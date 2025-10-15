import { SearchPreset } from '@repo/contracts';

export const PRESETS: SearchPreset[] = [
  {
    name: 'Top Rated',
    description:
      'Highest quality manga based on community ratings. Discover critically acclaimed series with proven excellence.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'rating',
      direction: 'desc',
    },
  },
  {
    name: 'Most Popular',
    description:
      'Trending titles with the highest readership. See what everyone is talking about right now.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
    },
  },
  {
    name: 'Most Followed',
    description:
      'Series with the most subscribers. Join the community following these fan favorites.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'chapters',
      direction: 'desc',
    },
  },
  {
    name: 'Recently Updated',
    description:
      'Latest chapter releases across all series. Stay current with fresh content updates.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'updatedAt',
      direction: 'desc',
    },
  },
  {
    name: 'Recently Added',
    description:
      'Newly uploaded series to the platform. Discover fresh titles before they gain traction.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'createdAt',
      direction: 'desc',
    },
  },
  {
    name: 'Alphabetical Browse',
    description:
      'Complete catalog sorted A to Z. Perfect for systematic browsing or finding specific titles.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'title',
      direction: 'asc',
    },
  },
  {
    name: 'Ongoing Series',
    description:
      'Active manga with regular updates. Jump into stories still being written.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'updatedAt',
      direction: 'desc',
      filters: {
        status: ['Ongoing'],
      },
    },
  },
  {
    name: 'Completed Series',
    description:
      'Fully finished manga ready for binge reading. No cliffhangers or indefinite waits.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'rating',
      direction: 'desc',
      filters: {
        status: ['Completed'],
      },
    },
  },
  {
    name: 'Korean Manhwa',
    description:
      'Full-color Korean webtoons. Known for stunning artwork and vertical scrolling format.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        originalLanguage: ['ko'],
      },
    },
  },
  {
    name: 'Chinese Manhua',
    description:
      'Chinese comics featuring cultivation, martial arts, and fantasy themes.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        originalLanguage: ['zh'],
      },
    },
  },
  {
    name: 'Japanese Manga',
    description:
      'Traditional Japanese manga with classic storytelling and art styles.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'rating',
      direction: 'desc',
      filters: {
        originalLanguage: ['ja'],
      },
    },
  },
  {
    name: 'Action Adventures',
    description:
      'High-energy battles and thrilling combat. From martial arts to superpowered showdowns.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['action'],
      },
    },
  },
  {
    name: 'Romance Stories',
    description:
      'Love stories ranging from sweet romance to dramatic relationship tales.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['romance'],
      },
    },
  },
  {
    name: 'Isekai World',
    description:
      'Reincarnation and transportation to fantasy worlds. Level-ups, magic, and new beginnings.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['isekai'],
      },
    },
  },
  {
    name: 'Fantasy Realms',
    description:
      'Magic, mythical creatures, and epic quests. Escape to worlds beyond imagination.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'rating',
      direction: 'desc',
      filters: {
        includeTag: ['fantasy'],
      },
    },
  },
  {
    name: 'Horror & Thriller',
    description:
      'Spine-chilling psychological horror and suspense. Not for the faint of heart.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'rating',
      direction: 'desc',
      filters: {
        includeTag: ['horror', 'thriller'],
      },
    },
  },
  {
    name: 'Comedy Gold',
    description:
      'Laugh-out-loud humor and comedic situations. Perfect mood lifters and stress relievers.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['comedy'],
      },
    },
  },
  {
    name: 'Martial Arts Masters',
    description:
      'Traditional and modern martial arts epics. Cultivation, tournaments, and fighting techniques.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['martial_arts'],
      },
    },
  },
  {
    name: 'Slice of Life',
    description:
      'Peaceful everyday stories without heavy drama. Comfort reading for relaxation.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'rating',
      direction: 'desc',
      filters: {
        includeTag: ['slice_of_life'],
      },
    },
  },
  {
    name: 'Mature Content',
    description:
      'Adult-oriented manga with mature themes. Reader discretion advised.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['adult', 'mature'],
      },
    },
  },
];
