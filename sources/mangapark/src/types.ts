export type MangaParkStatus = 'Ongoing' | 'Completed' | 'Hiatus' | 'Cancelled';

export type MangaParkLanguage = 'English' | 'Japanese' | 'Korean' | 'Chinese';

export const LANGUAGE_MAP: Record<string, string> = {
  English: 'en',
  Japanese: 'ja',
  Korean: 'ko',
  Chinese: 'zh',
} as const;
