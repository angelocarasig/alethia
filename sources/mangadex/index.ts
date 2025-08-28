import {
  Source,
  Adapter,
  AuthRequest,
  AuthResponse,
  SearchRequest,
  SearchResponse,
} from '@repo/contracts';
import { Manga, Chapter } from '@repo/schema';

export default class MangaDexSource extends Adapter {
  constructor(source: Source) {
    super(source);
  }

  protected async performAuthentication(
    credentials: AuthRequest,
  ): Promise<AuthResponse> {
    return {
      success: true,
      headers: {},
    };
  }

  protected async performSearch(
    params: SearchRequest,
    headers?: Record<string, string>,
  ): Promise<SearchResponse> {
    // TODO: Implement MangaDex search
    // 1. Map params to MangaDex API format
    // 2. Make request to https://api.mangadex.org/manga
    // 3. Transform response to SearchResponse format
    throw new Error('MangaDex search not implemented');
  }

  async getManga(
    slug: string,
    headers?: Record<string, string>,
  ): Promise<Manga> {
    // TODO: Implement MangaDex manga fetching
    // 1. GET https://api.mangadex.org/manga/{slug}
    // 2. Transform MangaDex response to Manga schema
    throw new Error('MangaDex getManga not implemented');
  }

  async getChapter(
    mangaSlug: string,
    chapterSlug: string,
    headers?: Record<string, string>,
  ): Promise<Chapter> {
    // TODO: Implement MangaDex chapter fetching
    // 1. GET https://api.mangadex.org/chapter/{chapterSlug}
    // 2. Or GET https://api.mangadex.org/manga/{mangaSlug}/feed to find chapter
    // 3. Transform to Chapter schema
    throw new Error('MangaDex getChapter not implemented');
  }
}
