import path from 'node:path';
import {
  DEFAULT_COUNT,
  DEFAULT_MAX_PAGES,
  DEFAULT_OUTPUT_DIR,
  DEFAULT_SHARE_URL
} from './config.js';
import { getBestThumbnail, shuffle, TeraBoxClient } from './terabox-client.js';

export async function scanRandomImages(input = {}) {
  const options = normalizeDownloadOptions(input);
  const { images, selected } = await selectRandomImages(options);

  return {
    shareUrl: options.url,
    found: images.length,
    scanStats: images.scanStats || null,
    selected: selected.map(toPublicFile)
  };
}

export async function downloadRandomImages(input = {}) {
  const options = normalizeDownloadOptions(input);
  const { client, images, selected } = await selectRandomImages(options);
  const outputDir = resolveOutputDir(options.outputDir, {
    baseDir: options.baseDir,
    safeRoot: options.safeRoot,
    allowAbsolute: options.allowAbsoluteOutput
  });

  const downloads = [];
  for (let index = 0; index < selected.length; index += 1) {
    const result = await client.downloadFile(selected[index], outputDir, index + 1, {
      allowThumbnails: options.allowThumbnails
    });
    downloads.push(toPublicDownload(result));
  }

  return {
    shareUrl: options.url,
    found: images.length,
    scanStats: images.scanStats || null,
    outputDir,
    selected: selected.map(toPublicFile),
    downloads
  };
}

export function normalizeDownloadOptions(input = {}) {
  const count = parsePositiveInt(input.count ?? DEFAULT_COUNT, 'count');
  const maxPages = parsePositiveInt(input.maxPages ?? DEFAULT_MAX_PAGES, 'maxPages');
  const originalOnly = parseBoolean(input.originalOnly, false);

  return {
    url: stringOrDefault(input.url || input.shareUrl, DEFAULT_SHARE_URL),
    count,
    maxPages,
    outputDir: stringOrDefault(input.outputDir || input.out, DEFAULT_OUTPUT_DIR),
    cookie: stringOrDefault(input.cookie, process.env.TERABOX_COOKIE || ''),
    allowThumbnails: input.allowThumbnails === undefined ? !originalOnly : parseBoolean(input.allowThumbnails, true),
    baseDir: input.baseDir || process.cwd(),
    safeRoot: input.safeRoot || input.baseDir || process.cwd(),
    allowAbsoluteOutput: parseBoolean(input.allowAbsoluteOutput, false)
  };
}

async function selectRandomImages(options) {
  const client = new TeraBoxClient({
    shareUrl: options.url,
    cookie: options.cookie,
    maxPages: options.maxPages
  });

  await client.init();
  const images = await client.collectImages();
  if (images.length === 0) {
    const stats = images.scanStats ? ` Scanned ${images.scanStats.scannedEntries} entries, ${images.scanStats.scannedDirs} directories, and ${images.scanStats.scannedFiles} files.` : '';
    throw new Error(`No image files were found in the share.${stats}`);
  }

  return {
    client,
    images,
    selected: shuffle(images).slice(0, Math.min(options.count, images.length))
  };
}

function resolveOutputDir(outputDir, { baseDir, safeRoot, allowAbsolute }) {
  const requested = outputDir || DEFAULT_OUTPUT_DIR;
  const target = path.isAbsolute(requested)
    ? path.resolve(requested)
    : path.resolve(baseDir, requested);

  if (!allowAbsolute && !isPathInside(target, safeRoot)) {
    throw new Error(`Output directory must stay inside ${safeRoot}. Set ALLOW_ABSOLUTE_OUTPUT=1 to allow absolute paths.`);
  }

  return target;
}

function isPathInside(target, root) {
  const relative = path.relative(path.resolve(root), path.resolve(target));
  return relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative));
}

function toPublicFile(file) {
  return {
    fsId: file.fsId,
    name: file.name,
    remotePath: file.path,
    size: file.size,
    hasOriginalDownload: Boolean(file.dlink),
    hasThumbnailFallback: Boolean(getBestThumbnail(file))
  };
}

function toPublicDownload(result) {
  return {
    name: result.file.name,
    remotePath: result.file.path,
    path: result.path,
    source: result.source,
    bytes: result.bytes
  };
}

function parsePositiveInt(value, name) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`${name} must be a positive integer.`);
  }

  return parsed;
}

function parseBoolean(value, fallback) {
  if (value === undefined || value === null || value === '') return fallback;
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;

  const normalized = String(value).trim().toLowerCase();
  if (['1', 'true', 'yes', 'y', 'on'].includes(normalized)) return true;
  if (['0', 'false', 'no', 'n', 'off'].includes(normalized)) return false;
  return fallback;
}

function stringOrDefault(value, fallback) {
  if (value === undefined || value === null || value === '') return fallback;
  return String(value);
}
