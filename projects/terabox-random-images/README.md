# TeraBox Random Images Express API

Express app that scans a public TeraBox/1024Tera share, picks random image files, and downloads them to the server.

It defaults to this share:

```text
https://www.1024tera.com/thai/sharing/link?surl=2h1Iu-PT8EP-vRpbJ8HMbw
```

## Requirements

- Node.js 20 or newer
- A public TeraBox/1024Tera share link that you have permission to access

## Install

```powershell
npm install
```

## Run The Express Server

```powershell
npm start
```

Default URL:

```text
http://127.0.0.1:3000
```

Change host or port:

```powershell
$env:PORT = "4000"
$env:HOST = "127.0.0.1"
npm start
```

## API

Health check:

```powershell
curl.exe http://127.0.0.1:3000/api/health
```

Preview five random images without downloading:

```powershell
curl.exe "http://127.0.0.1:3000/api/images?count=5"
```

Download five random images:

```powershell
curl.exe -X POST http://127.0.0.1:3000/api/download-random-images `
  -H "Content-Type: application/json" `
  -d "{\"count\":5,\"outputDir\":\"downloads\"}"
```

Download from a different share:

```powershell
curl.exe -X POST http://127.0.0.1:3000/api/download-random-images `
  -H "Content-Type: application/json" `
  -d "{\"url\":\"https://www.1024tera.com/thai/sharing/link?surl=2h1Iu-PT8EP-vRpbJ8HMbw\",\"count\":5}"
```

JSON body fields:

```json
{
  "url": "https://www.1024tera.com/thai/sharing/link?surl=2h1Iu-PT8EP-vRpbJ8HMbw",
  "count": 5,
  "outputDir": "downloads",
  "maxPages": 50,
  "originalOnly": false,
  "cookie": "optional TeraBox Cookie header"
}
```

You can also pass the cookie with an HTTP header:

```text
x-terabox-cookie: ndus=YOUR_VALUE; ...
```

The server writes relative `outputDir` paths inside this project folder by default. To allow absolute output paths, start the server with:

```powershell
$env:ALLOW_ABSOLUTE_OUTPUT = "1"
npm start
```

## CLI

The CLI is still available:

```powershell
npm run cli -- --count 5 --out .\downloads
```

Preview selected files:

```powershell
npm run cli -- --dry-run
```

## Notes

Public share listing usually works without a login cookie, but original full-size downloads can be blocked by TeraBox depending on the share/session. By default, the app falls back to the largest TeraBox thumbnail URL if the public API does not return an original download link. Set `originalOnly` to `true` or use CLI `--original-only` to fail instead of downloading thumbnails.
