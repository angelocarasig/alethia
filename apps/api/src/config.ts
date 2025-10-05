import { Adapter, Host } from '@repo/contracts';
import MangaDexSource from '@source/mangadex';
import WeebCentralSource from '@source/weebcentral';

export const adapters: Adapter[] = [MangaDexSource, WeebCentralSource];

export const host: Host = {
  name: 'elysium',
  author: 'alethia',
  repository: 'https://github.com/angelocarasig/alethia',
  sources: adapters.map((adapter) => adapter.getMetadata()),
};
