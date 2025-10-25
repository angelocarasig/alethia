import { Adapter, Host } from '@repo/contracts';
import MangaDexSource from '@source/mangadex';
import WeebCentralSource from '@source/weebcentral';
import MangaParkSource from '@source/mangapark';

export const adapters: Adapter<any, any, any, any>[] = [
  MangaDexSource,
  WeebCentralSource,
  MangaParkSource,
];

export const host: Host = {
  name: 'elysium',
  author: 'alethia',
  repository: 'https://github.com/angelocarasig/alethia',
  sources: adapters.map((adapter) => adapter.getMetadata()),
};
