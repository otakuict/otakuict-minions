#!/usr/bin/env node

import express from 'express';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  DEFAULT_COUNT,
  DEFAULT_HOST,
  DEFAULT_MAX_PAGES,
  DEFAULT_OUTPUT_DIR,
  DEFAULT_PORT,
  DEFAULT_SHARE_URL,
  PROJECT_ROOT
} from './config.js';
import { downloadRandomImages, scanRandomImages } from './downloader.js';

export function createApp() {
  const app = express();

  app.use(express.json({ limit: '64kb' }));

  app.get('/', (req, res) => {
    res.json({
      name: 'terabox-random-images',
      defaultShareUrl: DEFAULT_SHARE_URL,
      endpoints: {
        health: 'GET /api/health',
        preview: 'GET /api/images?url=<share-url>&count=5',
        download: 'POST /api/download-random-images'
      },
      postBody: {
        url: DEFAULT_SHARE_URL,
        count: DEFAULT_COUNT,
        outputDir: DEFAULT_OUTPUT_DIR,
        maxPages: DEFAULT_MAX_PAGES,
        originalOnly: false
      }
    });
  });

  app.get('/api/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  app.get('/api/images', asyncHandler(async (req, res) => {
    const result = await scanRandomImages(readRequestOptions(req));
    res.json(result);
  }));

  app.post('/api/download-random-images', asyncHandler(async (req, res) => {
    const result = await downloadRandomImages({
      ...readRequestOptions(req),
      baseDir: PROJECT_ROOT,
      safeRoot: PROJECT_ROOT,
      allowAbsoluteOutput: process.env.ALLOW_ABSOLUTE_OUTPUT === '1'
    });

    res.status(201).json(result);
  }));

  app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
  });

  app.use((error, req, res, next) => {
    if (res.headersSent) {
      next(error);
      return;
    }

    res.status(statusForError(error)).json({
      error: error.message
    });
  });

  return app;
}

export function startServer({
  port = Number(process.env.PORT) || DEFAULT_PORT,
  host = process.env.HOST || DEFAULT_HOST
} = {}) {
  const app = createApp();
  return app.listen(port, host, () => {
    console.log(`TeraBox random images API listening on http://${host}:${port}`);
  });
}

function readRequestOptions(req) {
  const body = req.body && typeof req.body === 'object' ? req.body : {};

  return {
    url: body.url || body.shareUrl || req.query.url || req.query.shareUrl || DEFAULT_SHARE_URL,
    count: body.count ?? req.query.count ?? DEFAULT_COUNT,
    outputDir: body.outputDir || body.out || req.query.outputDir || req.query.out || DEFAULT_OUTPUT_DIR,
    cookie: body.cookie || req.get('x-terabox-cookie') || '',
    maxPages: body.maxPages ?? req.query.maxPages ?? req.query.max_pages ?? DEFAULT_MAX_PAGES,
    originalOnly: body.originalOnly ?? req.query.originalOnly ?? req.query.original_only ?? false
  };
}

function asyncHandler(handler) {
  return (req, res, next) => {
    Promise.resolve(handler(req, res, next)).catch(next);
  };
}

function statusForError(error) {
  const message = error?.message || '';
  if (/must be|requires a value|Could not find|No image files|Output directory/.test(message)) return 400;
  if (/Network request failed|HTTP \d+|TeraBox API|jsToken/.test(message)) return 502;
  return 500;
}

function isMainModule() {
  return process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
}

if (isMainModule()) {
  startServer();
}
