import { Hono } from 'hono';
import { HostSchema } from '@repo/contracts';
import { host } from '../config';
import type { Bindings } from '../types';

const app = new Hono<{ Bindings: Bindings }>();

app.get('/', (c) => {
  return c.json(HostSchema.parse(host));
});

export default app;
