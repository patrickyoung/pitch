---
name: web-house
description: How to build a modern web app as one HTML file that runs from a static server with no build step - ES modules from a CDN, CSS that deletes JavaScript, browser APIs before libraries, WASM by URL. Use when writing or changing a single-file web app, or deciding whether a dependency has earned its place.
---

# Building one file that is a whole app

The deliverable is `index.html`. It opens in a browser straight off a static
server. Nothing compiles it, nothing bundles it, nothing watches it. If a
change to this app would require a build step, the change is wrong.

That constraint is not nostalgia. The platform in 2026 does what a 2018
toolchain was for, and a file with no build has no lockfile to rot, no
`node_modules` to audit, no dev server to differ from production, and it is
still readable in ten years by whoever opens it.

## The skeleton

```html
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Says what this is</title>
<style>
  /* everything */
</style>
<body>
  <!-- the app -->
<script type="module">
  // everything else
</script>
```

In that order, and `<title>` is not optional -- it is the tab, the history
entry, the bookmark and the share.

## No build step

The rule has a sharp edge, and the edge is imports. A bare specifier is the
build step arriving in disguise:

```js
import { z } from 'zod'                    // wrong: needs a resolver
```

An import map makes the browser the resolver. Pin the exact version; never
`@latest`, which turns a working app into a time bomb somebody else winds.

```html
<script type="importmap">
{ "imports": { "zod": "https://esm.sh/zod@3.23.8" } }
</script>
```

The same rule for CSS and fonts: a full URL with a version in it, or a local
file, and nothing that a tool was supposed to have rewritten.

## The platform first

Reach for a library only after the platform has been ruled out, and say in a
comment what ruled it out. These are load-bearing today and want no help:

- `<dialog>` with `showModal()` for modals -- focus trap, `Esc`, backdrop,
  all free. The popover attribute for menus and tooltips.
- `<details>`/`<summary>` for disclosure. `inert` for "not now".
- Constraint validation -- `required`, `pattern`, `setCustomValidity()`,
  `:user-invalid` -- before any validation library.
- `Intl.NumberFormat`, `Intl.DateTimeFormat`, `Intl.RelativeTimeFormat`,
  `Intl.ListFormat`, `Intl.Segmenter`. Formatting dates by hand is a bug
  waiting for somebody else's locale.
- `structuredClone`, `Object.groupBy`, `Promise.withResolvers`,
  `AbortSignal.timeout()`, `AbortSignal.any()`, `toSorted`/`toReversed`.
- `<template>` plus `cloneNode(true)` for repeated markup. A template literal
  built from user text is an injection; `textContent` is not.

If reactivity genuinely earns a dependency, it is one small module from the
import map -- Preact with htm, or Lit -- never a framework whose documented
first step is a CLI.

## CSS that deletes JavaScript

Every one of these replaces code that used to be a listener:

- `@layer` for order you control, nesting for locality, `:has()` for "style
  the parent" -- the selector that removed most one-line class toggles.
- Container queries (`@container`) rather than page-width media queries: a
  component that responds to its own box works anywhere you put it.
- `color-scheme: light dark` and `light-dark()` for both themes with no
  duplicated block and no flash. `oklch()` for colour that stays even as it
  lightens; `color-mix()` for hover and disabled states derived from one hue.
- `@property` for typed custom properties that actually animate.
- `@starting-style` plus `transition-behavior: allow-discrete` to animate
  something in from `display: none` with no JavaScript at all.
- `text-wrap: balance` on headings, `subgrid` for aligned card internals,
  `scroll-snap` for carousels, `accent-color` for controls.

Enhancement, not foundation -- correct without them, better with them: View
Transitions, anchor positioning, scroll-driven animations,
`field-sizing: content`, `text-wrap: pretty`. Wrap in `@supports` or a
capability check and make sure the plain path is the one that works.

## State is the browser's

There is no server, so there are no server bugs.

- `localStorage` for a handful of small values. Synchronous, 5 MB, strings.
- IndexedDB for real data, through a small CDN wrapper if the raw API is
  noise. It survives, it is large, it is transactional.
- The Origin Private File System for files, and `showSaveFilePicker()` when
  the user should own the result.
- The URL for anything worth sharing or reloading into. `URLSearchParams` and
  `history.replaceState` make a view addressable, which is the cheapest
  feature in this whole document.

Write the persistence path first and the render path second. An app that
loses work on refresh is not finished, however good it looks.

## WASM is a URL

```js
const { instance } = await WebAssembly.instantiateStreaming(
  fetch('https://cdn.jsdelivr.net/npm/pkg@1.2.3/thing.wasm'),
  imports)
```

Streaming needs the server to answer `application/wasm`, which `pitch-serve`
does. Threads and `SharedArrayBuffer` additionally need cross-origin
isolation, which is the `.isolate` file -- and which then breaks every CDN
response that omits `Cross-Origin-Resource-Policy`. So: single-threaded from
a CDN by default, `.isolate` only when the payoff is named, and either way
say in a comment which you chose.

Show progress. A 30 MB module on a phone is a blank screen for ten seconds
otherwise, and the user has already left.

## The floor

Not extras. A page that misses these is not done:

- Both colour schemes, and honour `prefers-reduced-motion: reduce`.
- Reachable by keyboard, in a sane order, with a focus ring you can see.
  Never remove the outline without putting a better one back.
- Real semantics -- `<button>` for actions, `<a href>` for places, one `<h1>`,
  labels tied to inputs. ARIA is the patch, not the plan.
- `lang` on `<html>`, a `<title>`, contrast that passes at every size.
- No horizontal scroll at 390px, and usable at 1440px. Both, not one.
- Nothing blocks first paint; a spinner is not a design for a page that could
  have rendered.

## It must do something

A layout is not an app. The check clicks the first control and requires the
DOM to change, because the most convincing failure a model produces is a
beautiful page where nothing is wired up. Build the behaviour first and
decorate afterwards -- the reverse produces a screenshot.

## Where one file ends

Split when the file stops being readable, not when a tool suggests it. The
honest triggers: a service worker for offline, because that has to be its own
file; a `manifest.webmanifest` for installability; a data file large enough
to be data; more than one page's worth of routes.

Splitting means more files next to `index.html`, all still loaded by URL. It
never means a bundler.

## What is enforced, and what is advice

`page-check` fails a build for: a failed request, a console error, an
unhandled rejection, a script on `http:`, horizontal overflow at 390px, a
critical accessibility violation, a page over the byte budget, and a page
whose first control does nothing.

Everything else here is advice with a reason attached. Ignore a piece of it
when you can say why in a comment; that comment is worth more than the rule.
