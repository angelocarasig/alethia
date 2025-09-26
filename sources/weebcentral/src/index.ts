import { SourceSchema } from '@repo/contracts';

import WeebCentralSource from './source';
import { config } from './config';

const Source = new WeebCentralSource(SourceSchema.parse(config));

export default Source;
