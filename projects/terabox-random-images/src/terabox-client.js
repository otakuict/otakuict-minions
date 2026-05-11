import { createWriteStream } from 'node:fs';
import { access, mkdir, rename, unlink } from 'node:fs/promises';
import path from 'node:path';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import {
  APP_ID,
  DEFAULT_MAX_PAGES,
  IMAGE_EXTENSIONS,
  PAGE_SIZE,
  USER_AGENT
} from './config.js';

export class CookieJar {
  constructor(initialCookie = '') {
    this.cookies = new Map();
    this.addCookieHeader(initialCookie);
  }

  addCookieHeader(cookieHeader) {
    if (!cookieHeader) return;

    for (const part of cookieHeader.split(';')) {
      const trimmed = part.trim();
      if (!trimmed || !trimmed.includes('=')) continue;

      const [name, ...valueParts] = trimmed.split('=');
      if (!name) continue;
      this.cookies.set(name, valueParts.join('='));
    }
  }

  addSetCookieHeaders(headers) {
    for (const header of headers) {
      const [cookiePair] = header.split(';');
      const separator = cookiePair.indexOf('=');
      if (separator <= 0) continue;

      const name = cookiePair.slice(0, separator).trim();
      const value = cookiePair.slice(separator + 1).trim();
      if (name) this.cookies.set(name, value);
    }
  }

  header() {
    return [...this.cookies.entries()].map(([name, value]) => `${name}=${value}`).join('; ');
  }
}

export class TeraBoxClient {
  constructor({ shareUrl, cookie = '', maxPages = DEFAULT_MAX_PAGES }) {
    const parsedShare = parseShareUrl(shareUrl);

    this.shareUrl = parsedShare.shareUrl;
    this.shortUrl = parsedShare.shortUrl;
    this.origin = parsedShare.origin;
    this.maxPages = maxPages;
    this.jar = new CookieJar(cookie);
    this.jsToken = '';
    this.logId = '';
  }

  async init() {
    const { response, url } = await this.fetchWithCookies(this.shareUrl, {
      headers: this.baseHeaders(),
      redirect: 'manual'
    });

    this.origin = new URL(url).origin;
    this.logId = response.headers.get('logid') || this.logId;

    const html = await response.text();
    this.jsToken = extractJsToken(html);

    if (!this.jsToken) {
      throw new Error('Could not extract jsToken from the share page. The share may require login, verification, or the page format changed.');
    }
  }

  async getShortInfo() {
    const url = new URL('/api/shorturlinfo', this.origin);
    url.search = new URLSearchParams({
      shorturl: `1${this.shortUrl}`,
      root: '1'
    }).toString();

    return this.requestJson(url);
  }

  async listShareDir(remoteDir = '', page = 1) {
    if (!this.jsToken) await this.init();

    const url = new URL('/share/list', this.origin);
    url.search = new URLSearchParams({
      app_id: APP_ID,
      web: '1',
      channel: 'dubox',
      clienttype: '0',
      jsToken: this.jsToken,
      shorturl: this.shortUrl,
      by: 'name',
      order: 'asc',
      num: String(PAGE_SIZE),
      dir: remoteDir,
      page: String(page)
    }).toString();

    if (!remoteDir) url.searchParams.set('root', '1');

    const data = await this.requestJson(url);
    if (data.errno === 4000020) {
      await this.init();
      return this.listShareDir(remoteDir, page);
    }

    return data;
  }

  async collectImages() {
    const images = [];
    const queuedDirs = [''];
    const seenDirs = new Set();
    let scannedFiles = 0;
    let scannedDirs = 0;
    let scannedEntries = 0;

    while (queuedDirs.length > 0) {
      const currentDir = queuedDirs.shift();
      if (seenDirs.has(currentDir)) continue;
      seenDirs.add(currentDir);

      for (let page = 1; page <= this.maxPages; page += 1) {
        const data = await this.listShareDir(currentDir, page);
        assertApiSuccess(data, `list ${currentDir || '/'}`);

        const entries = getEntries(data);
        scannedEntries += entries.length;
        for (const entry of entries) {
          if (isDirectory(entry)) {
            scannedDirs += 1;
            const dirPath = entry.path || joinRemotePath(currentDir, entry.server_filename || entry.filename || entry.name);
            if (dirPath && !seenDirs.has(dirPath)) queuedDirs.push(dirPath);
            continue;
          }

          scannedFiles += 1;
          if (isImageEntry(entry)) images.push(normalizeEntry(entry));
        }

        if (!hasMore(data, entries)) break;
      }
    }

    if (images.length === 0) {
      const info = await this.getShortInfo().catch(() => null);
      const infoEntries = info ? getEntries(info) : [];
      scannedEntries += infoEntries.length;
      for (const entry of infoEntries) {
        if (!isDirectory(entry) && isImageEntry(entry)) images.push(normalizeEntry(entry));
      }
    }

    const dedupedImages = dedupeImages(images);
    Object.defineProperty(dedupedImages, 'scanStats', {
      enumerable: false,
      value: {
        scannedEntries,
        scannedFiles,
        scannedDirs,
        scannedFolders: seenDirs.size
      }
    });

    return dedupedImages;
  }

  async downloadFile(file, outputDir, index, options = {}) {
    const attempts = getDownloadAttempts(file, options);
    if (attempts.length === 0) {
      throw new Error(`No downloadable URL was returned for ${file.name}`);
    }

    await mkdir(outputDir, { recursive: true });

    const filename = await uniqueFilename(outputDir, sanitizeFilename(file.name || `image-${index}`));
    const targetPath = path.join(outputDir, filename);
    const tempPath = `${targetPath}.part`;

    let lastError;
    for (const attempt of attempts) {
      try {
        const { response } = await this.fetchWithCookies(attempt.url, {
          headers: this.baseHeaders({
            Accept: 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            Referer: this.shareUrl
          }),
          redirect: 'manual'
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status} ${response.statusText}`);
        }

        const contentType = response.headers.get('content-type') || '';
        if (looksLikeErrorResponse(contentType)) {
          const message = await response.text();
          throw new Error(`Download returned ${contentType}: ${message.slice(0, 180)}`);
        }

        await pipeline(Readable.fromWeb(response.body), createWriteStream(tempPath));
        await rename(tempPath, targetPath);

        return {
          file,
          path: targetPath,
          source: attempt.source,
          bytes: Number(response.headers.get('content-length')) || null
        };
      } catch (error) {
        lastError = error;
        await unlink(tempPath).catch(() => {});
      }
    }

    throw new Error(`Failed to download ${file.name}: ${lastError.message}`);
  }

  async requestJson(url) {
    const { response } = await this.fetchWithCookies(url, {
      headers: this.baseHeaders(),
      redirect: 'manual'
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status} ${response.statusText} for ${url}`);
    }

    const body = await response.text();
    try {
      return JSON.parse(body);
    } catch {
      throw new Error(`Expected JSON from ${url}, got: ${body.slice(0, 180)}`);
    }
  }

  async fetchWithCookies(input, init = {}, redirectCount = 0) {
    if (redirectCount > 10) throw new Error(`Too many redirects while fetching ${input}`);

    const url = new URL(input);
    const headers = new Headers(init.headers || {});
    const cookie = this.jar.header();
    if (cookie) headers.set('Cookie', cookie);

    let response;
    try {
      response = await fetch(url, {
        ...init,
        headers,
        redirect: 'manual'
      });
    } catch (error) {
      throw new Error(`Network request failed for ${url}: ${describeCause(error)}`);
    }

    this.jar.addSetCookieHeaders(getSetCookieHeaders(response.headers));

    if (isRedirect(response.status)) {
      const location = response.headers.get('location');
      if (!location) return { response, url: url.toString() };

      const nextUrl = new URL(location, url);
      const nextInit = { ...init, headers };
      if ([301, 302, 303].includes(response.status)) {
        nextInit.method = 'GET';
        delete nextInit.body;
      }

      return this.fetchWithCookies(nextUrl, nextInit, redirectCount + 1);
    }

    return { response, url: url.toString() };
  }

  baseHeaders(extra = {}) {
    return {
      Accept: 'application/json,text/plain,*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'User-Agent': USER_AGENT,
      ...extra
    };
  }
}

export function shuffle(values) {
  const shuffled = [...values];
  for (let index = shuffled.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(Math.random() * (index + 1));
    [shuffled[index], shuffled[swapIndex]] = [shuffled[swapIndex], shuffled[index]];
  }

  return shuffled;
}

export function getBestThumbnail(file) {
  if (!file.thumbs || typeof file.thumbs !== 'object') return '';

  const urls = Object.entries(file.thumbs)
    .filter(([, value]) => typeof value === 'string' && value.startsWith('http'))
    .sort(([leftKey], [rightKey]) => thumbRank(rightKey) - thumbRank(leftKey));

  return urls[0]?.[1] || '';
}

function parseShareUrl(value) {
  const shareUrl = new URL(value);
  const querySurl = shareUrl.searchParams.get('surl');
  let shortUrl = querySurl;

  if (!shortUrl) {
    const match = shareUrl.pathname.match(/\/s\/([^/?#]+)/);
    if (match) shortUrl = decodeURIComponent(match[1]);
  }

  if (!shortUrl) {
    throw new Error('Could not find a TeraBox surl in the share URL.');
  }

  if (shortUrl.startsWith('1') && !querySurl) shortUrl = shortUrl.slice(1);

  return {
    shareUrl: shareUrl.toString(),
    origin: shareUrl.origin,
    shortUrl
  };
}

function extractJsToken(html) {
  const templateMatch = html.match(/<script>\s*var templateData = (.*?);\s*<\/script>/s);
  if (templateMatch) {
    try {
      const templateData = JSON.parse(templateMatch[1]);
      const token = normalizeTemplateToken(templateData.jsToken);
      if (token) return token;
    } catch {
      // Continue with regex fallbacks below.
    }
  }

  const encodedMatch = html.match(/window\.jsToken%20%3D%20a%7D%3Bfn%28%22([^"]+)%22%29/);
  if (encodedMatch) return encodedMatch[1];

  const plainMatch = html.match(/jsToken["']?\s*[:=]\s*["']([^"']+)["']/);
  if (plainMatch) return normalizeTemplateToken(plainMatch[1]);

  const urlEncodedMatch = html.match(/jsToken["']?\s*%3A\s*["']?([^"',&%]+)["']?/);
  if (urlEncodedMatch) return normalizeTemplateToken(decodeURIComponent(urlEncodedMatch[1]));

  return '';
}

function normalizeTemplateToken(value) {
  if (!value || typeof value !== 'string') return '';

  const encodedFunctionCall = value.match(/%28%22([^"]+)%22%29/);
  if (encodedFunctionCall) return encodedFunctionCall[1];

  const functionCall = value.match(/\("([^"]+)"\)/);
  if (functionCall) return functionCall[1];

  return value;
}

function getEntries(data) {
  if (Array.isArray(data?.list)) return data.list;
  if (Array.isArray(data?.data?.list)) return data.data.list;
  if (Array.isArray(data?.records)) return data.records;
  if (Array.isArray(data?.entries)) return data.entries;
  if (Array.isArray(data?.file_list)) return data.file_list;
  if (Array.isArray(data?.data?.file_list)) return data.data.file_list;
  return [];
}

function assertApiSuccess(data, label) {
  if (data.errno === undefined || data.errno === 0) return;

  const message = data.show_msg || data.errmsg || data.error_msg || data.message || JSON.stringify(data).slice(0, 240);
  throw new Error(`TeraBox API failed while trying to ${label}: errno ${data.errno} ${message}`);
}

function isDirectory(entry) {
  return isTruthyDirectoryValue(entry.isdir) ||
    isTruthyDirectoryValue(entry.is_dir) ||
    isTruthyDirectoryValue(entry.isDir) ||
    entry.type === 'directory';
}

function isImageEntry(entry) {
  if (entry.category === 3 || entry.category === '3') return true;

  const name = entry.server_filename || entry.filename || entry.name || entry.path || '';
  return IMAGE_EXTENSIONS.has(path.extname(name).toLowerCase());
}

function normalizeEntry(entry) {
  const name = entry.server_filename || entry.filename || entry.name || path.basename(entry.path || '') || String(entry.fs_id || 'image');

  return {
    fsId: entry.fs_id || entry.fsid || entry.id,
    name,
    path: entry.path || '',
    size: Number(entry.size) || null,
    dlink: entry.dlink || entry.download_url || entry.downloadLink || entry.url || '',
    thumbs: entry.thumbs || entry.thumbnails || {}
  };
}

function dedupeImages(images) {
  const seen = new Set();
  const result = [];

  for (const image of images) {
    const key = String(image.fsId || image.path || image.name);
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(image);
  }

  return result;
}

function getDownloadAttempts(file, options) {
  const attempts = [];
  if (file.dlink) attempts.push({ source: 'original', url: file.dlink });

  const thumbnail = options.allowThumbnails ? getBestThumbnail(file) : '';
  if (thumbnail) attempts.push({ source: 'thumbnail', url: thumbnail });

  return attempts;
}

function thumbRank(key) {
  const match = key.match(/\d+/);
  return match ? Number(match[0]) : 0;
}

function hasMore(data, entries) {
  if (data.has_more === 1 || data.has_more === true) return true;
  if (data.hasMore === true) return true;
  if (Number(data.total) > 0 && Number(data.page) > 0) {
    return Number(data.page) * PAGE_SIZE < Number(data.total);
  }

  return entries.length >= PAGE_SIZE;
}

function joinRemotePath(dir, name) {
  if (!name) return dir;
  if (!dir) return `/${name}`;
  return `${dir.replace(/\/$/, '')}/${name}`;
}

function getSetCookieHeaders(headers) {
  if (typeof headers.getSetCookie === 'function') {
    return headers.getSetCookie();
  }

  const header = headers.get('set-cookie');
  if (!header) return [];
  return splitCombinedSetCookie(header);
}

function splitCombinedSetCookie(header) {
  return header.split(/,(?=\s*[^;,=\s]+=[^;,]+)/g).map((value) => value.trim()).filter(Boolean);
}

function isRedirect(status) {
  return [301, 302, 303, 307, 308].includes(status);
}

function looksLikeErrorResponse(contentType) {
  return contentType.includes('text/html') || contentType.includes('application/json') || contentType.includes('text/plain');
}

async function uniqueFilename(outputDir, filename) {
  const parsed = path.parse(filename || 'image');
  const base = parsed.name || 'image';
  const ext = parsed.ext || '.jpg';

  let candidate = `${base}${ext}`;
  for (let index = 1; index < 10000; index += 1) {
    const target = path.join(outputDir, candidate);
    const exists = await fileExists(target);
    const partExists = await fileExists(`${target}.part`);
    if (!exists && !partExists) return candidate;
    candidate = `${base}-${index}${ext}`;
  }

  throw new Error(`Could not create a unique filename for ${filename}`);
}

async function fileExists(target) {
  try {
    await access(target);
    return true;
  } catch {
    return false;
  }
}

function sanitizeFilename(filename) {
  const sanitized = filename
    .replace(/[<>:"/\\|?*\u0000-\u001F]/g, '_')
    .replace(/\s+/g, ' ')
    .trim();

  return sanitized || 'image.jpg';
}

function describeCause(error) {
  const cause = error?.cause;
  if (cause?.code) return `${error.message} (${cause.code})`;
  if (cause?.message) return `${error.message}: ${cause.message}`;
  return error?.message || String(error);
}

function isTruthyDirectoryValue(value) {
  return value === 1 || value === true || value === '1' || value === 'true';
}
