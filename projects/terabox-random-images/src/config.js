import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const DEFAULT_SHARE_URL = 'https://www.1024tera.com/thai/sharing/link?surl=2h1Iu-PT8EP-vRpbJ8HMbw';
export const DEFAULT_COUNT = 5;
export const DEFAULT_OUTPUT_DIR = 'downloads';
export const DEFAULT_MAX_PAGES = 50;
export const DEFAULT_PORT = 3000;
export const DEFAULT_HOST = '127.0.0.1';
export const PAGE_SIZE = 20000;
export const APP_ID = '250528';
export const PROJECT_ROOT = path.resolve(fileURLToPath(new URL('..', import.meta.url)));
export const IMAGE_EXTENSIONS = new Set([
  '.avif',
  '.bmp',
  '.gif',
  '.heic',
  '.heif',
  '.jfif',
  '.jpeg',
  '.jpg',
  '.png',
  '.svg',
  '.tif',
  '.tiff',
  '.webp'
]);
export const USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
