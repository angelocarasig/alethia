import { z } from 'zod';
import { LanguageSchema } from '@repo/schema';

const SlugSchema = z.string().uuid();
const LocalizedStringSchema = z.record(LanguageSchema, z.string());

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
});

const ArtistRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('artist'),
});

const CreatorRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('creator'),
});

const MangaRelationshipSchema = BaseRelationshipSchema.extend({
  type: z.literal('manga'),
  related: z.string().optional(),
});

// union of all relationship types with fallback
const RelationshipSchema = z.union([
  TagRelationshipSchema,
  CoverArtRelationshipSchema,
  AuthorRelationshipSchema,
  ArtistRelationshipSchema,
  CreatorRelationshipSchema,
  MangaRelationshipSchema,
  BaseRelationshipSchema, // fallback for unknown types
]);

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

const MangadexEntrySchema = z.object({
  id: SlugSchema,
  type: z.literal('manga'),
  attributes: MangadexAttributesSchema,
  relationships: z.array(RelationshipSchema).optional(),
});

const MangadexCollectionResponseSchema = z.object({
  result: z.enum(['ok', 'error']),
  response: z.literal('collection'),
  data: z.array(MangadexEntrySchema),
  total: z.number(),
  limit: z.number(),
  offset: z.number(),
});

const MangadexErrorResponseSchema = z.object({
  result: z.literal('error'),
  errors: z.array(
    z.object({
      id: z.string(),
      status: z.number(),
      title: z.string(),
      detail: z.string().optional(),
    }),
  ),
});

export type Slug = z.infer<typeof SlugSchema>;
export type LocalizedString = z.infer<typeof LocalizedStringSchema>;
export type MangadexEntry = z.infer<typeof MangadexEntrySchema>;
export type MangadexAttributes = z.infer<typeof MangadexAttributesSchema>;
export type CoverArtRelationship = z.infer<typeof CoverArtRelationshipSchema>;
export type TagRelationship = z.infer<typeof TagRelationshipSchema>;
export type MangadexCollectionResponse = z.infer<
  typeof MangadexCollectionResponseSchema
>;
export type MangadexErrorResponse = z.infer<typeof MangadexErrorResponseSchema>;
export type PublicationDemographic = z.infer<
  typeof PublicationDemographicSchema
>;
export type MangaStatus = z.infer<typeof MangaStatusSchema>;
export type ContentRating = z.infer<typeof ContentRatingSchema>;

export {
  SlugSchema,
  LocalizedStringSchema,
  MangadexEntrySchema,
  MangadexAttributesSchema,
  MangadexCollectionResponseSchema,
  MangadexErrorResponseSchema,
  PublicationDemographicSchema,
  MangaStatusSchema,
  ContentRatingSchema,
  TagRelationshipSchema,
  CoverArtRelationshipSchema,
};
