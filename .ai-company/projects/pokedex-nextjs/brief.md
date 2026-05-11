# Pokedex Next.js Project

Created: 2026-05-05

## Objective

Create an educational Next.js web app that mimics a Pokedex and uses the public Pokemon API.

## Location

`projects/pokedex-nextjs`

## Definition Of Done

- Can open and close the Pokedex like a book/device.
- Can search Pokemon by name or ID.
- Can show Pokemon picture and basic data.

## Implementation Notes

- Next.js app router.
- Client-side calls to `https://pokeapi.co/api/v2/pokemon/{name-or-id}`.
- Pokedex-style responsive UI with closed cover and open book spread states.
- Uses regular `img` for dynamic external Pokemon artwork URLs.

## Verification

- `npm.cmd install` completed.
- `npm.cmd run lint` passed.
- `npm.cmd run build` passed.

## Known Gaps

- `next dev` is blocked in this Codex sandbox with `spawn EPERM`.
- `next start` works in foreground, but this sandbox did not keep the background server alive between tool calls.
- `npm audit` returned an audit endpoint error; npm install initially reported 2 moderate vulnerabilities.

