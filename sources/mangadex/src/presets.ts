import { SearchPreset } from '@repo/contracts';

export const PRESETS: SearchPreset[] = [
  {
    name: 'Recently Updated',
    description:
      'Catch up on the latest chapter releases across all genres. Perfect for following ongoing series.',
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
      'Discover brand new manga just added to the platform. Great for finding hidden gems before they trend.',
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
      'All-time favorites based on follow count. These are the must-read classics and viral hits everyone talks about.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
    },
  },
  {
    name: 'Top Rated',
    description:
      'Highest quality manga based on user ratings. Curated excellence for readers seeking proven storytelling.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'rating',
      direction: 'desc',
    },
  },
  {
    name: 'Popular in 2024',
    description:
      'Trending titles from this year. See what new series are capturing readers attention in 2024.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        year: 2024,
      },
    },
  },
  {
    name: 'Updated Manhwa',
    description:
      'Korean webtoons with fresh chapters. Full-color vertical scrolling format popular for romance and action.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'updatedAt',
      direction: 'desc',
      filters: {
        originalLanguage: ['ko'],
      },
    },
  },
  {
    name: 'Completed Series',
    description:
      'Fully finished manga ready to binge. No more waiting for updates or worrying about cancellations.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        status: ['completed'],
      },
    },
  },
  {
    name: 'Safe Content Only',
    description:
      'Family-friendly manga with no mature themes. Suitable for younger readers or workplace browsing.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        contentRating: ['safe'],
      },
    },
  },
  {
    name: 'Isekai Adventures',
    description:
      'Transport to another world stories. From overpowered heroes to strategic kingdom building.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['ace04997-f6bd-436e-b261-779182193d3d'], // isekai tag
      },
    },
  },
  {
    name: 'Romance Collection',
    description:
      'Love stories and relationship drama. Features everything from school crushes to mature relationships.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['423e2eae-a7a2-4a8b-ac03-a8351462d71d'], // romance tag
      },
    },
  },
  {
    name: 'Action Packed',
    description:
      'High-octane battles and intense fight scenes. Shonen classics and modern battle manga.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'popularity',
      direction: 'desc',
      filters: {
        includeTag: ['391b0423-d847-456f-aff0-8b0cfc03066b'], // action tag
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
        includeTag: [
          'cdad7e68-1419-41dd-bdce-27753074a640', // horror
          '07251805-a27e-4d59-b488-f0bfbec15168', // thriller
        ],
      },
    },
  },
  {
    name: 'Award Winners',
    description:
      'Critically acclaimed manga that have won major industry awards. Premium storytelling and artistry.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'rating',
      direction: 'desc',
      filters: {
        includeTag: ['0a39b5a1-b235-4886-a747-1d05d216532d'], // award winning tag
      },
    },
  },
  {
    name: 'Slice of Life',
    description:
      'Relaxing everyday stories without intense drama. Perfect for unwinding after a long day.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'rating',
      direction: 'desc',
      filters: {
        includeTag: ['e5301a23-ebd9-49dd-a0cb-2add944c7fe9'], // slice of life tag
      },
    },
  },
  {
    name: 'Long Running Epics',
    description:
      'Established series with 100+ chapters. Deep world-building and character development guaranteed.',
    request: {
      query: '',
      page: 1,
      limit: 20,
      sort: 'chapters',
      direction: 'desc',
      filters: {
        status: ['ongoing'],
      },
    },
  },
];
