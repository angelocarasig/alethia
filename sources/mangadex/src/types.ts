import { z } from 'zod';
import { LanguageSchema } from '@repo/schema';

// Base schemas
const SlugSchema = z.uuid();
const LocalizedStringSchema = z
  .record(z.string(), z.string())
  .transform((obj) => {
    // filter out keys that don't match LanguageSchema
    const validEntries = Object.entries(obj).filter(([key]) => {
      const result = LanguageSchema.safeParse(key);
      return result.success;
    });
    return Object.fromEntries(validEntries);
  })
  .pipe(z.record(LanguageSchema, z.string()));

// Relationship schemas
const BaseRelationshipSchema = z.object({
  id: SlugSchema,
  type: z.string(),
});

const TagRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('tag'),
  attributes: z.object({
    name: LocalizedStringSchema,
    description: z.record(z.string(), z.string()).optional(),
    group: z.string(),
    version: z.number(),
  }),
  relationships: z.array(z.unknown()).optional(),
});

const CoverArtRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('cover_art'),
  attributes: z.object({
    description: z.string(),
    volume: z.string().nullable(),
    fileName: z.string(),
    locale: LanguageSchema,
    createdAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
    updatedAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
    version: z.number(),
  }),
});

const AuthorRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('author'),
  attributes: z
    .object({
      name: z.string(),
      imageUrl: z.string().nullable().optional(),
      biography: LocalizedStringSchema.optional(),
      twitter: z.string().nullable().optional(),
      pixiv: z.string().nullable().optional(),
      melonBook: z.string().nullable().optional(),
      fanBox: z.string().nullable().optional(),
      booth: z.string().nullable().optional(),
      nicoVideo: z.string().nullable().optional(),
      skeb: z.string().nullable().optional(),
      fantia: z.string().nullable().optional(),
      tumblr: z.string().nullable().optional(),
      youtube: z.string().nullable().optional(),
      weibo: z.string().nullable().optional(),
      naver: z.string().nullable().optional(),
      website: z.string().nullable().optional(),
      createdAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
      updatedAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
      version: z.number(),
    })
    .optional(),
});

const ArtistRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('artist'),
  attributes: z
    .object({
      name: z.string(),
      imageUrl: z.string().nullable().optional(),
      biography: LocalizedStringSchema.optional(),
      twitter: z.string().nullable().optional(),
      pixiv: z.string().nullable().optional(),
      melonBook: z.string().nullable().optional(),
      fanBox: z.string().nullable().optional(),
      booth: z.string().nullable().optional(),
      nicoVideo: z.string().nullable().optional(),
      skeb: z.string().nullable().optional(),
      fantia: z.string().nullable().optional(),
      tumblr: z.string().nullable().optional(),
      youtube: z.string().nullable().optional(),
      weibo: z.string().nullable().optional(),
      naver: z.string().nullable().optional(),
      website: z.string().nullable().optional(),
      createdAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
      updatedAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
      version: z.number(),
    })
    .optional(),
});

const ScanlationGroupRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('scanlation_group'),
  attributes: z
    .object({
      name: z.string(),
      altNames: z.array(LocalizedStringSchema).optional(),
      website: z.string().nullable().optional(),
      ircServer: z.string().nullable().optional(),
      ircChannel: z.string().nullable().optional(),
      discord: z.string().nullable().optional(),
      contactEmail: z.string().nullable().optional(),
      description: z.string().nullable().optional(),
      twitter: z.string().nullable().optional(),
      mangaUpdates: z.string().nullable().optional(),
      focused: z.array(LanguageSchema).optional(),
      locked: z.boolean().optional(),
      official: z.boolean().optional(),
      verified: z.boolean().optional(),
      inactive: z.boolean().optional(),
      publishDelay: z.string().nullable().optional(),
      createdAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
      updatedAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
      version: z.number(),
    })
    .optional(),
});

const UserRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('user'),
  attributes: z
    .object({
      username: z.string(),
      roles: z.array(z.string()).optional(),
      version: z.number(),
    })
    .optional(),
});

const MangaRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('manga'),
  related: z.string().optional(), // e.g., "spin_off", "prequel", "sequel", etc.
  attributes: z
    .object({
      title: LocalizedStringSchema,
      altTitles: z.array(LocalizedStringSchema),
      description: LocalizedStringSchema.optional(),
      isLocked: z.boolean().optional(),
      links: z.record(z.string(), z.string().nullable()).optional(),
      originalLanguage: LanguageSchema,
      lastVolume: z.string().nullable().optional(),
      lastChapter: z.string().nullable().optional(),
      publicationDemographic: z
        .enum(['shounen', 'shoujo', 'josei', 'seinen'])
        .nullable()
        .optional(),
      status: z.enum(['ongoing', 'completed', 'hiatus', 'cancelled']),
      year: z.number().nullable(),
      contentRating: z.enum(['safe', 'suggestive', 'erotica', 'pornographic']),
      chapterNumbersResetOnNewVolume: z.boolean().optional(),
      availableTranslatedLanguages: z.array(LanguageSchema).optional(),
      latestUploadedChapter: z.string().nullable().optional(),
      createdAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
      updatedAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
      version: z.number(),
    })
    .optional(),
});

// Union of all relationship types with fallback
const RelationshipSchema = z
  .discriminatedUnion('type', [
    TagRelationshipSchema,
    CoverArtRelationshipSchema,
    AuthorRelationshipSchema,
    ArtistRelationshipSchema,
    ScanlationGroupRelationshipSchema,
    UserRelationshipSchema,
    MangaRelationshipSchema,
  ])
  .or(BaseRelationshipSchema); // Fallback for unknown types

// Enum schemas
const PublicationDemographicSchema = z.enum([
  'shounen',
  'shoujo',
  'josei',
  'seinen',
]);

const MangaStatusSchema = z.enum([
  'ongoing',
  'completed',
  'hiatus',
  'cancelled',
]);

const ContentRatingSchema = z.enum([
  'safe',
  'suggestive',
  'erotica',
  'pornographic',
]);

// Main manga attributes schema
const MangadexAttributesSchema = z.object({
  title: LocalizedStringSchema,
  altTitles: z.array(LocalizedStringSchema),
  description: LocalizedStringSchema.optional(),
  isLocked: z.boolean().optional(),
  links: z.record(z.string(), z.string().nullable()).optional(),
  originalLanguage: LanguageSchema,
  lastVolume: z.string().nullable().optional(),
  lastChapter: z.string().nullable().optional(),
  publicationDemographic: PublicationDemographicSchema.nullable(),
  status: MangaStatusSchema,
  year: z.number().nullable(),
  contentRating: ContentRatingSchema,
  tags: z.array(TagRelationshipSchema),
  state: z.string().optional(),
  chapterNumbersResetOnNewVolume: z.boolean().optional(),
  createdAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
  updatedAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
  version: z.number().optional(),
  availableTranslatedLanguages: z.array(LanguageSchema),
  latestUploadedChapter: z.string().nullable().optional(),
});

// Chapter schemas
const ChapterAttributesSchema = z.object({
  title: z.string().nullable(),
  volume: z.string().nullable(),
  chapter: z.string().nullable(),
  pages: z.number(),
  translatedLanguage: LanguageSchema,
  uploader: z.string().optional(),
  externalUrl: z.string().nullable().optional(),
  publishAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
  readableAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
  createdAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
  updatedAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
  version: z.number(),
});

const ChapterEntrySchema = z.object({
  id: SlugSchema,
  type: z.literal('chapter'),
  attributes: ChapterAttributesSchema,
  relationships: z.array(RelationshipSchema).optional(),
});

// Cover entry schema
const CoverEntrySchema = z.object({
  id: SlugSchema,
  type: z.literal('cover_art'),
  attributes: z.object({
    description: z.string(),
    volume: z.string().nullable(),
    fileName: z.string(),
    locale: LanguageSchema,
    createdAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
    updatedAt: z.iso.datetime({ local: false, offset: true, precision: 0 }),
    version: z.number(),
  }),
  relationships: z.array(RelationshipSchema).optional(),
});

// Main entry schemas
const MangadexEntrySchema = z.object({
  id: SlugSchema,
  type: z.literal('manga'),
  attributes: MangadexAttributesSchema,
  relationships: z.array(RelationshipSchema).optional(),
});

// Response schemas
const MangadexCollectionResponseSchema = z.object({
  result: z.enum(['ok', 'error']),
  response: z.literal('collection'),
  data: z.array(MangadexEntrySchema),
  total: z.number(),
  limit: z.number(),
  offset: z.number(),
});

const MangadexEntityResponseSchema = z.object({
  result: z.enum(['ok', 'error']),
  response: z.literal('entity'),
  data: MangadexEntrySchema,
});

const ChapterFeedResponseSchema = z.object({
  result: z.enum(['ok', 'error']),
  response: z.literal('collection'),
  data: z.array(ChapterEntrySchema),
  total: z.number(),
  limit: z.number(),
  offset: z.number(),
});

const CoverCollectionResponseSchema = z.object({
  result: z.enum(['ok', 'error']),
  response: z.literal('collection'),
  data: z.array(CoverEntrySchema),
  total: z.number(),
  limit: z.number(),
  offset: z.number(),
});

const AtHomeServerResponseSchema = z.object({
  result: z.enum(['ok', 'error']),
  baseUrl: z.string(),
  chapter: z.object({
    hash: z.string(),
    data: z.array(z.string()),
    dataSaver: z.array(z.string()).optional(),
  }),
});

const MangadexErrorResponseSchema = z.object({
  result: z.literal('error'),
  errors: z.array(
    z.object({
      id: z.string(),
      status: z.number(),
      title: z.string(),
      detail: z.string().optional(),
      context: z.any().optional(),
    }),
  ),
});

// Type exports
export type Slug = z.infer<typeof SlugSchema>;
export type LocalizedString = z.infer<typeof LocalizedStringSchema>;
export type MangadexEntry = z.infer<typeof MangadexEntrySchema>;
export type MangadexAttributes = z.infer<typeof MangadexAttributesSchema>;
export type ChapterEntry = z.infer<typeof ChapterEntrySchema>;
export type ChapterAttributes = z.infer<typeof ChapterAttributesSchema>;
export type CoverEntry = z.infer<typeof CoverEntrySchema>;
export type CoverArtRelationship = z.infer<typeof CoverArtRelationshipSchema>;
export type AuthorRelationship = z.infer<typeof AuthorRelationshipSchema>;
export type ArtistRelationship = z.infer<typeof ArtistRelationshipSchema>;
export type ScanlationGroupRelationship = z.infer<
  typeof ScanlationGroupRelationshipSchema
>;
export type UserRelationship = z.infer<typeof UserRelationshipSchema>;
export type MangaRelationship = z.infer<typeof MangaRelationshipSchema>;
export type TagRelationship = z.infer<typeof TagRelationshipSchema>;
export type MangadexCollectionResponse = z.infer<
  typeof MangadexCollectionResponseSchema
>;
export type MangadexEntityResponse = z.infer<
  typeof MangadexEntityResponseSchema
>;
export type ChapterFeedResponse = z.infer<typeof ChapterFeedResponseSchema>;
export type CoverCollectionResponse = z.infer<
  typeof CoverCollectionResponseSchema
>;
export type AtHomeServerResponse = z.infer<typeof AtHomeServerResponseSchema>;
export type MangadexErrorResponse = z.infer<typeof MangadexErrorResponseSchema>;
export type PublicationDemographic = z.infer<
  typeof PublicationDemographicSchema
>;
export type MangaStatus = z.infer<typeof MangaStatusSchema>;
export type ContentRating = z.infer<typeof ContentRatingSchema>;
export type Relationship = z.infer<typeof RelationshipSchema>;

// Schema exports for validation
export {
  SlugSchema,
  LocalizedStringSchema,
  MangadexEntrySchema,
  MangadexAttributesSchema,
  MangadexCollectionResponseSchema,
  MangadexEntityResponseSchema,
  ChapterFeedResponseSchema,
  CoverCollectionResponseSchema,
  AtHomeServerResponseSchema,
  MangadexErrorResponseSchema,
  PublicationDemographicSchema,
  MangaStatusSchema,
  ContentRatingSchema,
  TagRelationshipSchema,
  CoverArtRelationshipSchema,
  AuthorRelationshipSchema,
  ArtistRelationshipSchema,
  ScanlationGroupRelationshipSchema,
  UserRelationshipSchema,
  MangaRelationshipSchema,
  ChapterEntrySchema,
  ChapterAttributesSchema,
  CoverEntrySchema,
  RelationshipSchema,
};
