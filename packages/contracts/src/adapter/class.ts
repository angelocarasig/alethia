import { Chapter, Manga } from '@repo/schema';
import {
  AuthRequest,
  AuthResponse,
  SearchRequest,
  SearchRequestSchema,
  SearchResponse,
} from '../api';
import { Source } from './types';
import { HTTPClient } from '@repo/http-client';

/**
 * Abstract adapter class for integrating manga sources.
 *
 * This class provides a unified interface for interacting with different manga sources,
 * handling authentication, searching, and content retrieval. Each source implementation
 * should extend this class and implement the abstract methods.
 *
 * @abstract
 * @class Adapter
 * @example
 * class MySourceAdapter extends Adapter {
 *   async performAuthentication(credentials) {
 *     // Implementation specific to your source
 *   }
 *
 *   async performSearch(params, headers) {
 *     // Implementation specific to your source
 *   }
 *
 *   // ... other abstract method implementations
 * }
 */
export abstract class Adapter {
  /**
   * @protected
   * @type {Source}
   */
  protected source: Source;

  protected httpClient: HTTPClient;

  /**
   * Creates an instance of Adapter.
   * @param {Source} source - The source configuration
   */
  constructor(source: Source) {
    if (
      // tags can't be empty if tag filters are supported
      (source.search.filters.includes('includeTag') ||
        source.search.filters.includes('excludeTag')) &&
      source.search.tags.length === 0
    ) {
      throw new Error(
        `Source '${source.name}' includes tag filters but has no tags defined in the configuration.`,
      );
    }

    this.source = source;
    this.httpClient = new HTTPClient();
  }

  /**
   * Get the metadata of the source.
   *
   * @public
   * @returns {Source} The complete source configuration
   */
  public getMetadata(): Source {
    return this.source;
  }

  /**
   * Authenticate with the source and obtain session headers.
   *
   * Handles authentication based on the source's auth type configuration.
   * If the source requires no authentication (type === 'none'), returns success immediately.
   * Otherwise, validates required fields and delegates to the source-specific implementation.
   *
   * @async
   * @public
   * @param {AuthRequest} credentials - Key-value pairs matching the source's auth.fields requirements
   * @returns {Promise<AuthResponse>} Authentication response with success/error status and headers
   * @see {@link AuthResponse} for possible error codes
   * @example
   * const response = await adapter.authenticate({
   *   username: 'user@example.com',
   *   password: 'securepassword'
   * });
   *
   * if (response.success) {
   *   const manga = await adapter.getManga('slug', response.headers);
   * } else {
   *   console.error(`Auth failed: ${response.error.message}`);
   * }
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
   * Source-specific authentication implementation.
   *
   * Implement this method to handle authentication for your specific source.
   * This method is called after basic validation has been performed.
   *
   * @abstract
   * @protected
   * @async
   * @param {AuthRequest} credentials - Pre-validated credentials containing all required fields
   * @returns {Promise<AuthResponse>} Authentication response
   * @see {@link AuthResponse} for possible error codes
   */
  protected abstract performAuthentication(
    credentials: AuthRequest,
  ): Promise<AuthResponse>;

  /**
   * Maps internal search parameters to source-specific query parameters.
   *
   * @abstract
   * @param {SearchRequest} params - Search parameters to parse
   */
  protected abstract buildParams(params: SearchRequest): URLSearchParams;

  /**
   * Search for manga on the source.
   *
   * Performs a search with the given parameters after validating that all
   * provided filters are supported by the source.
   *
   * @async
   * @public
   * @param {SearchRequest} params - Search parameters
   * @param {Record<string, string>} [headers] - Optional auth headers from authenticate()
   * @returns {Promise<SearchResponse>} Search results with pagination
   * @throws {Error} When unsupported filters are provided
   * @see {@link SearchRequest} for parameter details
   * @see {@link SearchResponse} for response structure
   * @example
   * const results = await adapter.search({
   *   query: 'One Piece',
   *   page: 1,
   *   limit: 20,
   *   filters: { genre: 'action', year: 2024 }
   * }, authHeaders);
   */
  async search(
    params: SearchRequest,
    headers?: Record<string, string>,
  ): Promise<SearchResponse> {
    this.validateFilters(params);
    this.validateHeaders(headers);

    const parsedParams = SearchRequestSchema.parse(params);

    const searchParams = this.buildParams(parsedParams);

    return this.performSearch(searchParams, headers);
  }

  /**
   * Source-specific search implementation.
   *
   * @abstract
   * @protected
   * @async
   * @param {URLSearchParams} params - validated and mapped search parameters
   * @param {Record<string, string>} [headers] - Optional authentication headers
   * @returns {Promise<SearchResponse>} Search results
   * @throws {Error} Implementation-specific errors
   */
  protected abstract performSearch(
    params: URLSearchParams,
    headers?: Record<string, string>,
  ): Promise<SearchResponse>;

  /**
   * Get detailed information about a specific manga.
   *
   * @async
   * @abstract
   * @public
   * @param {string} slug - The unique identifier of the manga
   * @param {Record<string, string>} [headers] - Optional auth headers
   * @returns {Promise<Manga>} Complete manga information
   * @throws {Error} When manga not found or access denied
   * @see {@link Manga}
   */
  abstract getManga(
    slug: string,
    headers?: Record<string, string>,
  ): Promise<Manga>;

  /**
   * Get the metadata details for a manga's chapters.
   *
   * @async
   * @abstract
   * @public
   * @param {string} mangaSlug - The unique identifier of the manga
   * @param {Record<string, string>} [headers] - Optional auth headers
   * @returns {Promise<Chapter[]>} Ordered array of Chapters
   * @throws {Error} When chapter not found or access denied
   */
  abstract getChapters(
    mangaSlug: string,
    headers?: Record<string, string>,
  ): Promise<Chapter[]>;

  /**
   * Get the page URLs for a specific chapter.
   *
   * @async
   * @abstract
   * @public
   * @param {string} mangaSlug - The unique identifier of the manga
   * @param {string} chapterSlug - The unique identifier of the chapter
   * @param {Record<string, string>} [headers] - Optional auth headers
   * @returns {Promise<string[]>} Ordered array of page URLs
   * @throws {Error} When chapter not found or access denied
   */
  abstract getChapter(
    mangaSlug: string,
    chapterSlug: string,
    headers?: Record<string, string>,
  ): Promise<string[]>;

  /**
   * Validate search filters against the source's supported filters.
   *
   * @private
   * @param params - Search parameters
   * @param headers - Optional auth headers
   * @returns - Promise resolving to search results
   */
  private validateFilters(params: SearchRequest): void {
    const providedFilters = params.filters ? Object.keys(params.filters) : [];
    // if no filters in params, return early
    if (providedFilters.length === 0) {
      return;
    }

    const supportedFilters = this.source.search.filters || [];
    // if the source doesn't support any filters, throw error
    if (supportedFilters.length === 0) {
      throw new Error(`Source '${this.source.name}' does not support filters`);
    }

    const supportedSet = new Set<string>(supportedFilters);
    const invalidFilters = providedFilters.filter(
      (key) => !supportedSet.has(key),
    );

    // if there are filters in params that aren't in the defined set of supported filters, throw error
    if (invalidFilters.length > 0) {
      throw new Error(
        `The following filters are not supported by '${this.source.name}': ${invalidFilters.join(', ')}`,
      );
    }
  }

  /**
   * Validates that required authentication headers are present.
   *
   * @private
   * @param {Record<string, string>} [headers] - Optional HTTP headers object
   * @throws {Error} When authentication is required but no headers are provided
   * @see {@link Source} for auth configuration
   */
  private validateHeaders(headers?: Record<string, string>): void {
    // skip validation if source doesn't require auth
    if (this.source.auth.type === 'none') {
      return;
    }

    // check if headers exist and have at least one entry
    const hasHeaders = headers && Object.keys(headers).length > 0;

    if (!hasHeaders) {
      throw new Error(
        `Source '${this.source.name}' requires authentication but no headers were provided in the request.`,
      );
    }
  }
}
