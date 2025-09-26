import {
  Adapter,
  Host,
  HostSchema,
  SearchRequestSchema,
} from '@repo/contracts';
import MangaDexSource from '@source/mangadex';
import { Hono } from 'hono';

const app = new Hono();

const adapters: Adapter[] = [MangaDexSource];

const host: Host = {
  name: 'elysium',
  author: 'alethia',
  repository: 'https://github.com/angelocarasig/alethia',
  sources: adapters.map((adapter) => adapter.getMetadata()),
};

app.get('/', (c) => {
  return c.json(HostSchema.parse(host));
});

for (const source of adapters) {
  const config = source.getMetadata();

  app.get(`/${config.slug}`, (c) => {
    return c.json(source.getMetadata());
  });

  app.post(`/${config.slug}/search`, async (c) => {
    const body = await c.req.json();

    const parsed = SearchRequestSchema.parse(body);
    const results = await source.search(parsed);

    return c.json(results);
  });

  app.get(`/${config.slug}/:mangaSlug`, async (c) => {
    const { mangaSlug } = c.req.param();

    const results = await source.getManga(mangaSlug);

    return c.json(results);
  });

  app.get(`/${config.slug}/:mangaSlug/chapters`, async (c) => {
    const { mangaSlug } = c.req.param();

    const results = await source.getChapters(mangaSlug);

    return c.json(results);
  });

  app.get(`/${config.slug}/:mangaSlug/chapters/:chapterSlug`, async (c) => {
    const { mangaSlug, chapterSlug } = c.req.param();

    const result = await source.getChapter(mangaSlug, chapterSlug);
    return c.json(result);
  });
}

export default app;
