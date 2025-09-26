import { SourceSchema } from '@repo/contracts';

import MangadexSource from './source';
import { config } from './config';

const Source = new MangadexSource(SourceSchema.parse(config));

export default Source;
