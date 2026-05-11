#!/usr/bin/env node

import { DEFAULT_COUNT, DEFAULT_MAX_PAGES, DEFAULT_OUTPUT_DIR, DEFAULT_SHARE_URL } from './config.js';
import { downloadRandomImages, scanRandomImages } from './downloader.js';

async function main() {
  const options = parseArgs(process.argv.slice(2));

  if (options.help) {
    printHelp();
    return;
  }

  if (options.dryRun) {
    console.log(`Reading share metadata: ${options.url}`);
    const result = await scanRandomImages(options);
    printSelection(result);
    return;
  }

  console.log(`Reading share metadata: ${options.url}`);
  const result = await downloadRandomImages({
    ...options,
    baseDir: process.cwd(),
    safeRoot: process.cwd(),
    allowAbsoluteOutput: true
  });

  printSelection(result);
  for (const download of result.downloads) {
    console.log(`Saved ${download.path}${download.source === 'thumbnail' ? ' (thumbnail fallback)' : ''}`);
  }
  console.log(`Done. Downloaded ${result.downloads.length} image(s).`);
}

function parseArgs(args) {
  const options = {
    url: DEFAULT_SHARE_URL,
    count: DEFAULT_COUNT,
    outputDir: DEFAULT_OUTPUT_DIR,
    cookie: process.env.TERABOX_COOKIE || '',
    maxPages: DEFAULT_MAX_PAGES,
    originalOnly: false,
    dryRun: false,
    help: false
  };

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else if (arg === '--url' || arg === '-u') {
      options.url = readValue(args, ++index, arg);
    } else if (arg === '--count' || arg === '-c') {
      options.count = readValue(args, ++index, arg);
    } else if (arg === '--out' || arg === '-o') {
      options.outputDir = readValue(args, ++index, arg);
    } else if (arg === '--cookie') {
      options.cookie = readValue(args, ++index, arg);
    } else if (arg === '--max-pages') {
      options.maxPages = readValue(args, ++index, arg);
    } else if (arg === '--original-only') {
      options.originalOnly = true;
    } else if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (!arg.startsWith('-') && options.url === DEFAULT_SHARE_URL) {
      options.url = arg;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return options;
}

function printSelection(result) {
  console.log(`Found ${result.found} image(s). Selected ${result.selected.length}:`);
  result.selected.forEach((file, index) => {
    console.log(`${index + 1}. ${file.remotePath || file.name}`);
  });
}

function printHelp() {
  console.log(`
Download random images from a public TeraBox/1024Tera share.

Usage:
  node src/cli.js [share-url] [options]

Options:
  -u, --url <url>        Share URL. Defaults to the URL from this workspace request.
  -c, --count <number>   Number of random images to download. Default: ${DEFAULT_COUNT}
  -o, --out <dir>        Output directory. Default: ${DEFAULT_OUTPUT_DIR}
      --cookie <cookie>  Optional TeraBox Cookie header. Can also use TERABOX_COOKIE.
      --max-pages <n>    Max pages to scan per folder. Default: ${DEFAULT_MAX_PAGES}
      --original-only    Do not fall back to TeraBox thumbnail URLs when original dlinks are absent.
      --dry-run          List the selected files without downloading.
  -h, --help             Show this help.
`.trim());
}

function readValue(args, index, flag) {
  const value = args[index];
  if (!value || value.startsWith('-')) throw new Error(`${flag} requires a value.`);
  return value;
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
