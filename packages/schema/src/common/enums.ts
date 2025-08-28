import z from 'zod';

export const ClassificationSchema = z
  .enum(['Unknown', 'Safe', 'Suggestive', 'Erotica', 'Pornographic'])
  .describe('The classification of the manga');

export type Classification = z.infer<typeof ClassificationSchema>;

export const PublicationSchema = z
  .enum(['Unknown', 'Ongoing', 'Completed', 'Cancelled', 'Hiatus'])
  .describe('The publication status of the manga');

export type Publication = z.infer<typeof PublicationSchema>;
