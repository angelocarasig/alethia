import { Adapter, SearchRequest, SearchRequestSchema } from '@repo/contracts';
import MangaDexSource from '@source/mangadex';
import { Hono } from 'hono';

const app = new Hono();

app.get('/', (c) => {
  return c.text('Hello Hono!');
});

const sources: Adapter[] = [MangaDexSource];

for (const source of sources) {
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

  app.get(`/${config.slug}/:slug`, async (c) => {
    const { slug } = c.req.param();

    const results = await source.getManga(slug);

    return c.json(results);
  });

  app.get(`/${config.slug}/:slug/chapters`, async (c) => {
    const { slug } = c.req.param();

    const results = await source.getChapters(slug);

    return c.json(results);
  });

  app.get(`/${config.slug}/:slug/chapters/:chapterSlug`, async (c) => {
    const { slug, chapterSlug } = c.req.param();

    const result = await source.getChapter(slug, chapterSlug);
    return c.json(result);
  });
}

export default app;
