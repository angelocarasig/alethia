import { Manga, Chapter } from '@repo/schema';
import {
  AuthRequest,
  AuthResponse,
  SearchRequest,
  SearchResponse,
} from '../api';
import { Source } from './types';

export abstract class Adapter {
  protected source: Source;

  constructor(source: Source) {
    this.source = source;
  }

  /**
   * Get the metadata of the source
   * @returns The metadata of the source
   */
  getMetadata(): Source {
    return this.source;
  }

  /**
   * Authenticate with the source
   *
   * POST /auth
   *
   * @param credentials Key-value pairs matching the source's auth.fields
   * @returns Authentication response with headers to use in subsequent requests
   */
  async authenticate(credentials: AuthRequest): Promise<AuthResponse> {
    // return early if no auth
    if (this.source.auth.type === 'none') {
      return {
        success: true,
        headers: {},
      };
    }

    // check for missing fields
    const requiredFields = this.source.auth.fields || [];
    for (const field of requiredFields) {
      if (!credentials[field]) {
        return {
          success: false,
          error: {
            code: 'MISSING_FIELDS',
            message: `Missing required field: ${field}`,
          },
        };
      }
    }

    return this.performAuthentication(credentials);
  }

  /**
   * Source-specific authentication implementation
   */
  protected abstract performAuthentication(
    credentials: AuthRequest,
  ): Promise<AuthResponse>;

  /**
   * Search for manga
   *
   * POST /search
   *
   * @param params Search parameters
   * @param headers Optional auth headers from previous authenticate() call
   * @returns Search results
   * @throws Error if search not supported or invalid parameters
   */
  async search(
    params: SearchRequest,
    headers?: Record<string, string>,
  ): Promise<SearchResponse> {
    if (params.filters) {
      const supportedFilters = this.source.search.filters;
      const invalidFilters = Object.keys(params.filters).filter(
        (key) => !supportedFilters.includes(key as any),
      );

      if (invalidFilters.length > 0) {
        throw new Error(
          `Filters not supported by ${this.source.name}: ${invalidFilters.join(', ')}`,
        );
      }
    }

    return this.performSearch(params, headers);
  }

  /**
   * Source-specific search implementation
   */
  protected abstract performSearch(
    params: SearchRequest,
    headers?: Record<string, string>,
  ): Promise<SearchResponse>;

  /**
   * Get a manga by its slug
   *
   * GET /manga/:slug
   *
   * @param slug The slug of the manga
   * @param headers Optional auth headers from previous authenticate() call
   * @returns The manga with the specified slug
   */
  abstract getManga(
    slug: string,
    headers?: Record<string, string>,
  ): Promise<Manga>;

  /**
   * Get a chapter by the manga's slug and chapter's slug
   *
   * GET /manga/:mangaSlug/chapter/:chapterSlug
   * @param mangaSlug The slug of the manga
   * @param chapterSlug The slug of the chapter
   * @param headers Optional auth headers from previous authenticate() call
   * @returns The chapter with the specified slugs
   */
  abstract getChapter(
    mangaSlug: string,
    chapterSlug: string,
    headers?: Record<string, string>,
  ): Promise<Chapter>;
}
