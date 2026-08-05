# pitch

    pitch new clock "a wall clock with a sweeping seconds hand, dark, no libraries"
    https://mac.tailnet.ts.net/clock/

A description goes in. A working HTTPS URL comes out — and the page behind it
has been opened by a browser and judged by a program before anybody is told it
exists.

    pitch say clock "add the date under the hands, small and quiet"
    pitch open clock            # reachable from the internet, over Funnel
    pitch shut clock            # tailnet only again
    pitch back clock            # undo the last change
    pitch ls

Then give an app its own chat group, and talk to it from a phone:

    pitch group clock

## The one sentence

`hail`'s design turned on *the matterbridge gateway name is the handler
program's name*. This adds one clause:

> **The site name is the gateway name is the handler name is the URL path.**

One name, four roles. Adding a site is a directory and two symlinks, and
nothing in `heed` changes, ever.

    Telegram group "clock"
      ↔ gateway clock  →  handlers/clock  →  sites/clock/  →  /clock/

## What is new here, and what is not

Almost none of this is new. Tailscale is already TLS, a hostname and an access
boundary in one command, so there is no certificate to renew and no reverse
proxy. `git` is already rollback. `ply` is already the loop. `heed` is already
the router. The file system is already the interface between the container that
builds and the Mac that serves.

Two things had to be built. One is `page-check`, which opens the page in a real
browser and decides: no failed requests, no console errors, no sideways scroll
at 390px, contrast that passes, an accessible name on every control — and
**something has to happen when you click**, because the most convincing failure
a model produces is a beautiful page wired to nothing. It drives Chrome over the
DevTools protocol through node's own `WebSocket`, so it has no `package.json`
and no `node_modules` — which is the rule it exists to enforce.

The other is `skills/web-house`, the doctrine: one file, no build step, ES
modules pinned in an import map, CSS that deletes JavaScript, the platform
before any library, WASM by URL, and a floor of both colour schemes, keyboard
reach and 390px that is not optional.

## Public and private

`AllowFunnel` is keyed by port, not by path, so one funnelled port would make
every path on it public. Private sites are 443 and tailnet-only; a published
site is additionally on 8443. The visibility is therefore in the URL, on
purpose — these cannot be mistaken for one another:

    private   https://mac.tailnet.ts.net/clock/
    public    https://mac.tailnet.ts.net:8443/clock/

Both are TLS from Tailscale's own certificate. Default is private. Both are up
only while the machine is: the tailnet is the host.

## Getting it running

    just link                  # pitch onto ~/.local/bin
    pitch doctor               # mounts, tools, chromium, tailnet, the port
    tailscale up               # until this, every URL is loopback
    just check                 # 21 cases, offline
    pitch up

Then, for the phone, `hail`'s setup applies unchanged — the BotFather token,
privacy mode off, one group per app. Make a group called `pitch`, add the bot,
and describe an app in it. It answers twice: once now, once with the URL.

## Reading order

`DESIGN.md`. It is the requirements, the procedure and the definition of done,
in that order, and its *Not doing* and *Traps* sections are the parts worth
your time.
