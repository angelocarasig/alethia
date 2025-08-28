import { z } from 'zod';

export const AuthRequestSchema = z
  .record(
    z.string().describe('Field name from source auth.fields'),
    z.string().describe('Field value (e.g., username, password, token)'),
  )
  .describe('Key-value pairs matching the source auth.fields requirements');

export type AuthRequest = z.infer<typeof AuthRequestSchema>;

export const AuthSuccessResponseSchema = z.strictObject({
  success: z.literal(true).describe('Indicates authentication was successful'),

  headers: z
    .record(
      z
        .string()
        .regex(/^[A-Za-z0-9-]+$/)
        .describe('HTTP header name'),
      z.string().max(8192).describe('HTTP header value'),
    )
    .default({})
    .describe('Headers to include in subsequent requests'),

  metadata: z
    .object({
      expiresAt: z.iso
        .datetime()
        .optional()
        .describe('ISO 8601 timestamp when the authentication expires'),

      refreshToken: z
        .string()
        .optional()
        .describe('Token used to refresh authentication when expires'),

      sessionId: z
        .string()
        .optional()
        .describe('Unique identifier for the current session'),

      username: z
        .string()
        .optional()
        .describe('Username of authenticated user'),
    })
    .optional()
    .describe('Additional auth metadata'),
});

export const AuthErrorResponseSchema = z.strictObject({
  success: z.literal(false).describe('Indicates authentication failed'),

  error: z.object({
    code: z
      .enum([
        // Credential errors
        'INVALID_CREDENTIALS',
        'INVALID_API_KEY',
        'INVALID_TOKEN',
        'MISSING_FIELDS',

        // Account errors
        'ACCOUNT_LOCKED',
        'ACCOUNT_NOT_FOUND',

        // Session/token errors
        'SESSION_EXPIRED',
        'TOKEN_EXPIRED',

        // Service errors
        'SERVICE_UNAVAILABLE',
        'RATE_LIMITED',
        'NETWORK_ERROR',

        // Self-hosted errors
        'INVALID_INSTANCE_URL',
        'INSTANCE_UNREACHABLE',

        // General errors
        'UNSUPPORTED_AUTH_TYPE',
        'UNKNOWN_ERROR',
      ])
      .describe('Error code for programmatic handling'),

    message: z.string().describe('Human-readable error message'),

    retryAfter: z.number().optional().describe('Seconds until retry allowed'),
  }),
});

export const AuthResponseSchema = z.discriminatedUnion('success', [
  AuthSuccessResponseSchema,
  AuthErrorResponseSchema,
]);

export type AuthResponse = z.infer<typeof AuthResponseSchema>;
export type AuthSuccessResponse = z.infer<typeof AuthSuccessResponseSchema>;
export type AuthErrorResponse = z.infer<typeof AuthErrorResponseSchema>;
