import {ENV} from './src/config/env.js';

export default {
  schema: './src/db/schema.js',
  out: './src/db/migrations',
  dialect:'postgresql',
  dbCredentials: {url: ENV.DB_URL},
};