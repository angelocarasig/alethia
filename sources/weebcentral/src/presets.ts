import { SearchPreset } from '@repo/contracts';

export const PRESETS: SearchPreset[] = [
  {
    name: 'Latest Updates',
    description:
      'Fresh chapter releases across all series. Stay current with your favorite ongoing manga and manhwa.',
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
      'New series just uploaded to the platform. Discover fresh content before it gains traction.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'createdAt',
      direction: 'desc',
    },
  },
  {
    name: 'Most Popular',
    description:
      'Top series by readership and engagement. The crowd favorites everyone is reading right now.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
    },
  },
  {
    name: 'Most Subscribed',
    description:
      'Series with the highest follower counts. Proven titles with dedicated fanbases.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'follows',
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
    name: 'Completed Series',
    description:
      'Fully finished stories ready for binge reading. No cliffhangers or indefinite waits.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        status: ['Complete'],
      },
    },
  },
  {
    name: 'Ongoing Series',
    description:
      'Active series with regular updates. Jump into stories still being written.',
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
    name: 'Korean Manhwa',
    description:
      'Full-color Korean webtoons. Known for stunning art and modern storytelling styles.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['Manhwa'],
      },
    },
  },
  {
    name: 'Chinese Manhua',
    description:
      'Chinese comics featuring cultivation, martial arts, and historical fantasy themes.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['Manhua'],
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
        includeTag: ['Action'],
      },
    },
  },
  {
    name: 'Romance Stories',
    description:
      'Love stories ranging from sweet school romance to dramatic relationship tales.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['Romance'],
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
        includeTag: ['Isekai'],
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
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['Fantasy'],
      },
    },
  },
  {
    name: 'School Life',
    description:
      'Campus dramas and classroom comedies. Relive or experience school days through manga.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'follows',
      direction: 'desc',
      filters: {
        includeTag: ['School+Life'],
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
        includeTag: ['Comedy'],
      },
    },
  },
  {
    name: 'Psychological Thrillers',
    description:
      'Mind-bending plots and complex characters. Stories that challenge your perceptions.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'follows',
      direction: 'desc',
      filters: {
        includeTag: ['Psychological'],
      },
    },
  },
  {
    name: 'Horror Collection',
    description:
      'Terrifying tales and supernatural scares. Not recommended for late-night reading.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['Horror'],
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
        includeTag: ['Martial+Arts'],
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
      sort: 'follows',
      direction: 'desc',
      filters: {
        includeTag: ['Slice+of+Life'],
      },
    },
  },
  {
    name: 'Drama Intense',
    description:
      'Emotional rollercoasters and compelling character conflicts. Stories that hit deep.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['Drama'],
      },
    },
  },
];
