import { z } from 'zod';

const NoAuthSchema = z.object({
  type: z.literal('none'),

  required: z.literal(false),
});

const BasicAuthSchema = z.object({
  type: z.literal('basic'),

  required: z.literal(true),

  fields: z.tuple([z.literal('username'), z.literal('password')]),
});

const SessionAuthSchema = z.object({
  type: z.literal('session'),

  required: z.literal(true),

  fields: z.tuple([z.literal('username'), z.literal('password')]),
});

const ApiKeyAuthSchema = z.object({
  type: z.literal('api_key'),

  required: z.literal(true),

  fields: z.tuple([z.literal('apiKey')]),
});

const BearerAuthSchema = z.object({
  type: z.literal('bearer'),

  required: z.literal(true),

  fields: z.tuple([z.literal('token')]),
});

const CookieAuthSchema = z.object({
  type: z.literal('cookie'),

  required: z.literal(true),

  fields: z.tuple([z.literal('cookie')]),
});

export const AuthSchema = z.discriminatedUnion('type', [
  NoAuthSchema,
  BasicAuthSchema,
  SessionAuthSchema,
  ApiKeyAuthSchema,
  BearerAuthSchema,
  CookieAuthSchema,
]);

export type Auth = z.infer<typeof AuthSchema>;
