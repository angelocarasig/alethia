import z from 'zod';

export const TagSchema = z.object({
  slug: z
    .string()
    .min(1, 'Slug must be at least 1 character long')
    .describe(
      'The unique identifier for the tag, typically a URL-friendly string',
    ),

  name: z
    .string()
    .trim()
    .min(1)
    .max(50)
    .describe('The display name of the tag'),

  nsfw: z
    .boolean()
    .default(false)
    .describe('Whether the tag is marked as NSFW'),
});

export type Tag = z.infer<typeof TagSchema>;
