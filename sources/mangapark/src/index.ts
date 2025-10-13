import { SourceSchema } from '@repo/contracts';

import MangaParkSource from './source';
import { config } from './config';

const Source = new MangaParkSource(SourceSchema.parse(config));

export default Source;
