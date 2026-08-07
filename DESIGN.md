# pitch

    pitch new clock "a wall clock with a seconds sweep, dark, no libraries"
    https://mac.tailnet.ts.net/clock/

A description goes in. A working HTTPS URL comes out, and the page behind it
has been opened by a browser and judged by a program before anybody is told
it exists.

## What it is

The bench builds things and has nowhere to put them. `hail` gave it a phone,
`shop` gave it an operating system, and this is the last mile: say what you
want, get a URL, then keep the conversation going in that app's own chat
group until the app is right.

Three parts, and they are one system. A doctrine for **2026 single-file web
apps** -- HTML, CSS, ES modules from a CDN, WASM, browser APIs, and no build
step, ever. A **host**, which is Tailscale, because `tailscale serve` is TLS
and a hostname and an access boundary in one command and there is no
certificate to renew. And a **per-app agent**: one Telegram group per site,
where every message is either a question about that app or a change to it.

## The one sentence

`hail`'s design turned on *the matterbridge gateway name is the handler
program's name*. This adds one clause to it:

> **The site name is the gateway name is the handler name is the URL path.**

One name, four roles, so adding a site is a directory and two symlinks and
nothing in `heed` changes, ever.

    Telegram group "pomodoro"
      <-> gateway pomodoro
      -> handlers/pomodoro   (a symlink; argv[0] is the site)
      -> sites/pomodoro/
      -> https://mac.tailnet.ts.net/pomodoro/

## The shape

    shop container                        Mac host
      heed -> handlers/<site>               pitch-serve      127.0.0.1:8787
        -> ply -C build/<site>              tailscale serve   :443  -> tailnet
        -> page-check (chromium, CDP)       tailscale funnel  :8443 -> internet
        -> sites/<site>, and a commit
                     \                    /
                      sites/ -- one tree --

Work happens in `build/<site>`, served on a port nobody chose, and lands in
`sites/<site>` only after the check has passed against it. So the page a
visitor is looking at is never the page being edited.

**The file system is the only interface between the two halves.** The
container writes files; the Mac reads them and reconciles Tailscale to match.
No socket, no RPC, no API, no message: a site becomes reachable because a
directory appeared. The container is the boundary for model-authored code --
it exists already and already passes hail's 47 cases on Linux -- and the Mac
keeps the tailnet identity, because a second `tailscaled` would be a second
node, a second identity, and state that must survive a rebuild.

**Public and private are two ports, and the port is in the URL.**
`AllowFunnel` in Tailscale's serve configuration is keyed by host *and port*,
not by path, so one funnelled port would make every path on it public.
Private sites are 443 and tailnet-only; a published site is additionally
exposed on 8443. They cannot be confused, because they do not look alike:

    private   https://mac.tailnet.ts.net/pomodoro/
    public    https://mac.tailnet.ts.net:8443/pomodoro/

Both are TLS from Tailscale's own `*.ts.net` certificate. Default is private.

## Requirements

- [ ] `pitch new <name> "<what you want>"` writes `sites/<name>/index.html`,
      proves it with a program, commits it, and prints a URL that loads.
- [ ] Nothing is committed or served unless `page-check` exited 0. A failed
      build says what failed, and the last good page is still up afterwards.
- [ ] No JavaScript build step anywhere -- not in the apps, not in the
      checker, not in the server. No `package.json`, no `node_modules`, no
      bundler, no transpiler, on either side of the mount.
- [ ] Visibility is one word. `pitch open` and `pitch shut`, private by
      default, and `pitch ls` says which every site is without asking me to
      read a URL carefully.
- [ ] An app grows past one file without anything changing:
      `sites/<name>/` is a directory and `index.html` is only its first file.
- [ ] Every accepted change is a commit whose message is the chat message
      that caused it, so undo is `git revert` and there is no version table.
- [ ] A message in a site's group reaches a model that already knows that
      app: its `SPEC.md`, its source, its thread, and the domain skill that
      fits it.
- [ ] A build takes minutes and the chat answers in seconds, then again with
      the URL when it is real.
- [ ] The site name is hostile input -- it is a path, a URL, a git
      repository, a gateway and a program name -- and it is validated in one
      function that every program calls.
- [ ] The whole thing is checkable offline: no tailnet, no chat network, no
      model provider, no network at all.

## Not doing

- **No framework, bundler, transpiler or dev server in the output.** That is
  the entire premise. An app that needs a build step is the wrong app, and
  the first `npm install` is the end of this project.
- **No cloud host.** The tailnet is the host, so a site is up while the Mac
  is up. That is the honest cost of owning the machine and it is said out
  loud in the reply rather than engineered around.
- **No accounts, sessions or per-site auth.** Tailscale is the authentication
  for private and public means public. An auth layer is a second system with
  a user model, and `hail` already refused multi-user for the same reason.
- **No database and nothing server-side.** Apps are static files; state is
  `localStorage`, IndexedDB or OPFS, in the browser. A server with no state
  has no state to lose.
- **No second Tailscale identity.** No `tailscaled` in the container.
  `shop`'s DESIGN.md settled the network-namespace argument once and this
  does not reopen it.
- **No RPC between container and host.** A file appearing is the event. A
  socket here would be a protocol, a version, and a thing to be down.
- **No capability that is a program.** The builder writes these, and a
  model-written script behind a URL is a different risk class from a
  model-written page: builds run in a container precisely so model-authored
  code is boxed, and a serving endpoint is not. So a capability is a
  *manifest* -- a skill, a model, a budget, a list of keys the answer must
  carry, a prompt -- and one hand-written interpreter reads it. A capability
  can cause exactly one thing: an `ask` call. The blast radius is a prompt.
- **No public capability, and it is not a promise.** `AllowFunnel` is keyed by
  port, so the agent path is added to the 443 handler and to nothing else, and
  `pitch open` refuses a site that has an `agent/` directory. An
  unauthenticated model endpoint on the public internet is somebody else
  spending your tokens; pitch has refused accounts and refuses to grow them,
  so a site with capabilities stays on the tailnet.
- **No exec in `pitch-serve`.** The interpreter is a second program on a
  second port, one origin behind tailscale. The static server is eighty lines
  and provably cannot be walked out of *because* it only reads files, and
  giving it exec would trade a checkable property for a promise.
- **No button on the dashboard, and no endpoint in the server.** `ward`
  reports and cannot act: no restart, no deploy, no retry. A dashboard with a
  button is a remote shell with a nicer font, reachable by anything on the
  tailnet, and observing and acting are different systems. For the same reason
  `pitch-serve` gains no computed endpoint -- it is eighty lines and provably
  cannot be walked out of *because* it only reads files, and a static server
  that shells out to `docker` is not a static server. The cost is that the
  page can be stale, so it says how stale it is, which is the honest trade.
- **No socket for the dashboard, and no metrics store.** The fastest thing
  worth seeing is a build starting; nobody perceives better than two seconds,
  so a WebSocket buys a property no human can detect and costs a live
  connection to defend. The logs are the history and the page is a view of
  them -- there is nothing to retain that is not already retained.
- **No preview or staging URL.** The check is the preview. A page that passes
  is deployed and a page that fails never existed.
- **No visibility or deploy verbs in the workshop group.** New things are
  made there and nowhere else; an app's own group owns its own life.
- **No `hone`.** Nothing has failed and then passed yet, so there is nothing
  to learn from. The trigger is named under *Later, if earned*.
- **No fork of hail, heed, matterbridge or shop.** Configuration, symlinks,
  and one new handler program. If something here needs a patch to those, this
  design is wrong.

## The split

The default is a script. Two stages earn a model and one of those earns a
loop.

| stage | tool | why |
| --- | --- | --- |
| names, directories, symlinks, git, reconciling `tailscale serve`, printing a URL | none -- a script | there is no judgment in any of it, and a model here would be slower and nondeterministic in exchange for nothing |
| serving bytes with the right `content-type` and headers | none -- a script | `pitch-serve`. See *Why there is a server* |
| the verdict on a built page: it loads, no console errors, no failed requests, no overflow, no critical a11y violation, and it does something | none -- a script | this is the check. **A model must never grade its own homework** |
| a description -> `SPEC.md`: a slug, a summary, and the acceptance list | ask -n, one call | judgment, one shot, one JSON object. Batched, not six calls |
| a chat message -> `ask` \| `change` \| `open` \| `shut` \| `back` \| `url` | ask, cheap model | one classification, one call, and it saves a whole `ply` loop on "what colour is the button" |
| `SPEC.md` -> `index.html`, the first time | ply -check | the answer must satisfy a program the model cannot fake, which is the only reason `ply` exists |
| `.change` + the existing `index.html` -> the smallest edit that satisfies it | ply -check | the same loop and a **different goal**. Building and editing are not one job, and giving them one goal is why five requests produced five different apps |
| answering a question about the app | ask -f, threaded | there is no check a program could apply to conversation, so `ply` would buy only latency |
| learning from builds that failed and then passed | hone | not yet. See *Later, if earned* |
| what a page cannot compute for itself: a judgment about an image or a phrase | ask, one call | `pitch-agent` reading a manifest. Everything computable -- dominant colours, contrast, harmony, a type scale -- is arithmetic the browser does instantly and offline; the model only chooses and names |
| showing what is running, and what is only *up* | none -- a script | `ward`. Every component already writes its state down; this is a rendering problem, not an observation one, and a model in it would be guessing at facts that are on disk |

## Why there is a server

`tailscale serve <directory>` exists, serves static files, and would have
meant **zero server code**. That was the first design and it does not survive
one requirement.

Cross-origin isolation. `SharedArrayBuffer` -- and so threaded WASM,
`ffmpeg.wasm`, `duckdb-wasm` and everything like them -- needs
`Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` on the
response, and a static file target has nowhere to put a header. The same
gap makes `.wasm` arriving as `application/octet-stream` unfixable, and
`WebAssembly.instantiateStreaming` refuses it.

So there is one small static server, and it earns its keep twice: the checker
serves the site through it too, so **what is checked is byte for byte what is
served**. Isolation is per site and opt-in -- a file called `.isolate` --
because COEP breaks every CDN import whose response omits CORP, which is most
of them, and turning it on by default would break the common case to enable
the rare one.

`edm-serve` reached the same conclusion for the same kind of reason, and its
comment says so: *python3 -m http.server was here first and was fine.*

## Data

    raw:
      sites/<name>/SPEC.md         what was asked for, and the acceptance
                                   list. Appended to, never rewritten
      sites/<name>/.git            every accepted state of the app, with the
                                   chat message that caused it as the message
      log/<name>/YYYY-MM-DD.jsonl  every build attempted and the verdict
                                   reached, one JSON object per line
      log/<name>/build-*.jsonl     the transcript of one build, written by
                                   ply -f. Raw: it cannot be recomputed, and
                                   `ask replay -check` on it proves that run.
                                   Before this it went to ~/.ply/sessions
                                   *inside the container*, which nothing
                                   mounts -- so every build transcript was
                                   thrown away when the container was
                                   recreated, and what the builds cost was
                                   unknowable
      .ask/                        provenance; ASK_DIR points into the project

    derived:
      sites/<name>/index.html      the app -- derived from SPEC.md and a
                                   model, but *in git*, so a hand edit
                                   survives and a bad change is one revert
      sites/<name>/.public         visibility. A capability is a file
      sites/<name>/.isolate        cross-origin isolation. Also a file
      threads/<name>.jsonl         hail's, unchanged: the app's conversation

The app is source code, so the honest store for it is git, which already does
rollback, blame, diff and branch, and which no table here could do better.
`index.html` is listed as derived because it is rebuildable from `SPEC.md`;
it is kept in git anyway because the rebuild is not deterministic and a hand
edit is a legitimate way to change an app.

The log path is computed **per line**, not once at startup: a daemon that
lives for weeks and opens today's file once writes Tuesday into Monday
forever.

## Check

```sh
sh bin/check
```

Offline -- no tailnet, no chat network, no model provider, no credentials. A
`tailscale` stub on `$PATH` records exact argv; fixture pages stand in for
built apps; `bin/check` exits zero only when all of the following hold.

1. **Lint.** `sh -n` on every script, `node --check` on every module,
   `brief lint -strict skills/web-house`, every program and every handler
   executable, and the example gateway TOML parses. *The mode is part of the
   contract: a handler that is not executable is not a handler, and `heed`
   reports it as an unknown gateway, which is a useless answer to "I made
   the group and nothing happens".*
2. **The name is hostile.** `../../etc/passwd`, `a;rm -rf ~`, `.`, the empty
   string, `Pomodoro`, a 200-character name and a leading `-` each resolve to
   no path, no URL, no repository and no command -- refused identically by
   `pitch`, `pitch-serve` and `pitch-chat`, from one function. *Validating in
   two of the three is how this becomes a remote shell.*
3. **`pitch-serve` serves the app and not pitch's own files inside it.**
   `SPEC.md`, `.public`, `.isolate` and `.domain` are 404. *On a public site
   the spec is what somebody asked for, and that is nobody else's business.*
4. **`pitch-serve` cannot be walked out of.** `..`, `%2e%2e`, an absolute
   path, and a symlink pointing outside the site all get 403.
5. **Content types.** `.wasm` is `application/wasm`, `.js` is
   `text/javascript`, `.html` carries `charset=utf-8`, unknown is
   `application/octet-stream`. *Without this the WASM half of the doctrine
   silently does not work, and the failure surfaces in the app, not here.*
6. **Isolation is opt-in.** With `.isolate` the COOP and COEP headers are on
   the response; without it they are absent, not empty.
7. **`page-check` fails what it should, and names it:** a console error; an
   unhandled rejection; a subresource that 404s; horizontal overflow at
   390px; a script tag on `http:`; an unpinned `@latest` import; a page over
   the byte budget; text that does not meet its contrast threshold.
8. **`page-check` fails an inert page** -- one that renders and does nothing
   -- **and passes a clock**, which has no controls at all and is correct.
   *`edm` shipped a track that satisfied every structural assertion and was
   musically dead. The same failure here is a page that looks like an app;
   the same over-correction is a check that only knows pages with buttons.*
9. **`page-check` bounds a page that never settles.** Killed at the timeout,
   reported as a timeout -- not a hang, not a pass -- and sixty-eight
   identical 404s arrive folded with a count rather than burying the one
   line that matters.
10. **First run on an empty tree.** No `sites/`, `log/`, `build/` or `.ask/`
   -- all are created, the first site builds, is committed, and the staging
   tree is gone afterwards. *`hn` lost 190 MB to exactly this class of bug:
   the empty store is where the defaults get decided, and a fixture store is
   never empty.*
11. **An existing name is refused**, never overwritten.
12. **A failed check publishes nothing.** No commit, no change to the serve
    configuration, no staging tree left behind, and the previously good page
    is byte for byte still being served.
13. **A change is an edit, not a rebuild.** The goal handed over is the edit
    one; the request is in `.change` and `.change` is not published; `ply` gets
    `-compact`; the commit carries the message that asked for it; `pitch back`
    reverts it; and the reply says how much of the file moved. *The stub runs
    the check before its first turn exactly as `ply` does, so this case also
    fails if `-B` is ever dropped -- see the traps.*
14. **`pitch ls` on an empty tree** prints nothing and exits 0.
15. **Reconcile is idempotent.** Run twice it issues no second `tailscale`
    command; `open` produces exactly one funnel invocation on 8443 and a URL
    carrying that port; `shut` removes it.
16. **The URL printed is the URL served** -- path prefix, trailing slash, the
    301 for a path without one, and the published page still passes the check
    it was published for.
17. **`pitch group` refuses while matterbridge is running** and prints the
    order that works -- stop the bridge, then send, then read the id --
    rather than an empty `getUpdates` and a confident wrong answer.
18. **The handler knows itself.** Invoked as `handlers/counter`, `pitch-chat`
    resolves site `counter`; invoked by its own name it refuses and says how
    to install it; invoked as `Pomodoro` it refuses the name.
19. **Untrusted text never becomes a shell word.** The message reaches `ply`
    through `SPEC.md`, never argv; the goal handed over is the constant one;
    and a message that is `-B -sh; touch ...` creates no file. *A message
    beginning with `-` must not become a flag, and nothing re-parses the text.*
20. **The toolbox is exactly what `etc/toolbox` lists**, and `sh` is not in
    it -- which would make `-t` meaningless rather than merely honest.
21. **Invoked through a symlink** from an unrelated directory, every program
    still finds its own `lib/`, `sites/` and log. *`hail`'s suite ran
    `bin/hail` by its true path forty-three times and never once the way a
    person would, so the first real install died on line 14.*

Cases 3, 5, 8, 9, 10, 13, 15, 19 and 21 are the ones that would not exist if the
check had been written to pass. Three of them found a shipped bug on their
first run, and all three are in Traps.

## Layout

    pitch/
      DESIGN.md
      README.md
      justfile               check | link | up | doctor | group
      bin/
        pitch                new | edit | ls | open | shut | back | up | group
        pitch-serve          static: MIME, path prefix, .isolate, no escape
        page-check           the verdict -- chromium over CDP, no dependencies
        pitch-chat           handlers/<site> points here; argv[0] is the site
        check                the offline suite
      lib/
        common.sh            name validation, config, logging
      build/<name>/          the staging tree; a site nobody can reach yet
      build/.tools/          the ply toolbox, derived per build from
                             etc/toolbox and never committed
      skills/
        web-house/SKILL.md   the doctrine this whole thing exists to serve
      launchd/
        com.bench.pitch.plist
      etc/
        gateway.toml.example
      tests/
        pages/               ten fixture apps: good, alive, inert, noisy,
                             broken, slow, wide, nameless, dim, insecure
        suite                the twenty cases
        ply-stub             a ply that passes or fails on demand -- and that
                             runs the check before its first turn, as ply does
        ask-stub             an ask that answers without a provider
        tailscale-stub       a tailscale that keeps state, so reconcile can be
                             run twice and asked whether it did anything
      sites/  log/  threads/  .ask/

## Traps

The first two were found by using the thing. The next five came out of running
the check, and each is a bug this design would otherwise have shipped.

- **One goal for two jobs, and the second job was a rewrite.** `Build the app
  SPEC.md describes` is right for a new site and catastrophic for a change:
  every request appends an `Asked for on` section, so by the fifth message the
  model is handed a changelog and told to build what it describes -- and it
  does, from scratch, losing every earlier decision. The clock's own history
  measured it: `add the date` moved 81 lines of 308; four requests later `fix
  all the hands` moved 346 of 371. One of the requests in between was the
  owner *saying the design kept changing*, which the agent read as a feature
  and rebuilt the page again. There are two goals now, the request for a change
  arrives alone in `.change`, and `SPEC.md` is named as background rather than
  a brief. **And a number is printed after every change** -- `12 of 214 lines
  changed` -- because no program here can tell a good rewrite from a bad one,
  but a person reading `346 of 371` knows in one glance. That gauge would have
  caught this in one message rather than five.
- **Nothing compacted, anywhere.** A build that filled its window was exit 2 --
  *not done* -- at the point it was closest to finished, which is the most
  expensive moment available; `ply -compact` fixes that and was simply missing.
  A chat thread grew forever until `ask` returned exit 2 permanently. There is
  no fill percentage to read, so the proxy is the size of the session on disk:
  over `PITCH_THREAD_MAX` it is compacted before asking, and exit 2 compacts
  and retries once. Compaction loses the attached source, so the stamp that
  tracks it is deleted with the thread.
- **The source was attached once and then never again.** `handlers/hn`'s rule
  is attach-at-the-start, which is right for a report that does not change and
  wrong for an app that is edited between turns: three changes in, the agent
  was answering questions about a version it had never seen. It is attached
  when the conversation starts *and* whenever `index.html` has changed since
  the last time it was sent.

- **A range inside a bracket expression is collation, not codepoints.**
  `case $name in *[!a-z0-9-]*) return 1` is the obvious way to write the name
  guard and it is wrong: macOS `/bin/sh` is bash 3.2, whose `en_US` collation
  interleaves case, so `Pomodoro` does not match and is accepted. The same
  line rejects it under `LC_ALL=C`, and `bin/pitch-serve`'s JavaScript regexp
  -- where `[a-z]` is codepoints and always was -- rejected it all along. A
  validator that is right on the machine you tested and wrong on the machine
  that matters is the worst property a validator can have, so the character
  sets are written out longhand. *`hail`'s `valid_gateway` is the same
  construct and has the same behaviour.*
- **`new URL('//counter/', base)` reads the leading `//` as an authority.**
  `GET //counter/` is a legal request, and parsing it that way makes the path
  `/` -- so the root listing is served for a request that plainly named a
  site. Nothing in a static server needs a URL object; it needs the bytes
  between the method and the query, and splitting them by hand is both
  shorter and correct.
- **`ply` runs the check before the first turn, and that is wrong for an
  edit.** The pre-check is what makes a goal already met cost nothing, which
  is exactly right for "make the tests pass" and exactly wrong here: a live
  page already passes, so every request to change it is answered with
  `nothing to do` and the URL, forever. `-B` is not optional. The deeper fact
  is that the check can say a page is well made and cannot say it is the page
  that was asked for, and no flag closes that.
- **A comment cannot come between a command prefix and its command.**
  `BRIEF_PATH=... \` followed by a comment line turns two exported settings
  into two plain shell variables and runs the command without them. The
  symptom was `brief: no skill "web-house"` -- a message about a skill path,
  from a program three steps away from the backslash that caused it.
- **A redirect is not a create; it is an open, and open follows symlinks.**
  `handlers/<name>` was a symlink to `bin/pitch-chat`. Rewriting it as a
  wrapper with `cat > handlers/<name>` wrote **through** the link and replaced
  `bin/pitch-chat` with the four-line wrapper -- which then `exec`'d itself,
  forever, until the suite was killed. The handler is now written to a sibling
  temporary, the destination is unlinked, and the temporary is renamed over it.
  `draft prove` reached the identical rule from `sed > file` truncating a
  source to zero bytes. *The case that pins it puts a decoy behind a symlink
  and checks the decoy survives.*
- **A symlink cannot span two filesystem layouts.** `ln -s $BIN/pitch-chat
  handlers/pitch` writes `/Users/patrick/projects/pitch/...`, and heed runs in
  a container where that path does not exist -- so the link dangles, the file
  is not executable, and heed correctly reports an unknown gateway. Which is a
  useless answer to "I made the group and nothing happens". The handler is a
  wrapper script naming `$HOME/projects/pitch`, the one path that means the
  same thing on both sides because that is the mount `shop` already makes; and
  the site name comes from `HAIL_GATEWAY`, because a wrapper has no argv[0]
  worth reading.
- **A check must not read the machine's configuration.** Adding `PITCH_HOST`
  to `~/.config/pitch/env` turned two cases red on a tree that had not changed
  -- and they were *correct*, which is what makes it the worst kind of false
  negative: the suite was reporting a fact about the developer. It sets its own
  `PITCH_CONFIG` and unsets the rest, so `sh bin/check` gives the same verdict
  on any machine. hail reached the same conclusion by the same route.
- **The Mac cannot watch a mount another machine writes.** The first design
  said the tailscale configuration is not a daemon, because the tree only
  changes when `pitch` changes it. That stopped being true the moment the
  builder moved into the container: a site described in a chat is written by
  another machine, and the Mac holds the only tailnet identity, so nothing
  would ever notice it appeared. Hence a second launchd job that reconciles
  once a minute -- affordable only because reconcile is idempotent by
  construction, which is the property that turns a poll from a smell into an
  answer. **And `PITCH_HOST` must be set in the config**, or the container --
  which has no `tailscaled` to ask -- replies to a phone with
  `http://127.0.0.1:8787/...`.
- **`-cycles` bounds the loop, `-timeout` bounds a command, and neither
  bounds the run.** A `ply` worked a directory that no longer existed for 23
  hours 47 minutes, calling a model the whole time, and nothing anywhere
  noticed: no log line, no reply, no verdict. A build that never finishes is
  silence, and silence looks exactly like not-started-yet. `PITCH_BUILD_MAX`
  is a wall clock, and the run gets its own **process group** -- killing the
  shell leaves the interpreter running, which `draft prove` records paying for,
  and a build's children are a server, a browser and a model client. `doctor`
  and `ward` both name a lock that has outlived any build.
- **Job control is bash-only, and the builder runs dash.** `set -m` puts a
  background job in its own process group in bash and does not in Debian's
  `/bin/sh`, so the wall clock bounded nothing in the container -- which is
  the only place builds actually run. The group comes from
  `perl -e 'setpgrp(0,0); exec ...'` instead, which survives exec and works on
  both. hail already reaches for perl to get `alarm(2)` without installing
  anything; this is the same trade, and it was caught by running the suite on
  Linux rather than by reading it.
- **`pkill -x <full path>` never matches.** `-x` compares the process *name*,
  so the suite's fake matterbridge outlived the case that started it. It
  passed on macOS anyway, because the browser cases are slow enough that its
  `sleep 30` expired first, and failed on Linux where they are not. Killed by
  pid now, and the case fails if the fake is still alive when it ends. *A
  suite whose verdict depends on which machine is faster is not a suite* --
  and hail's own note about a double answering to the name in the runbook is
  the same lesson from the other direction.
- **`set -e` inside a function is global.** `set +e; wait; st=$?; set -e`
  restores it for the *caller* too, so a function that tidied up after itself
  clobbered a `set +e` two frames up and the script exited on a status it was
  deliberately ignoring. `wait "$pid" || st=$?` needs no toggle at all. Third
  variant of this trap in this file, after the AND-list and the comment
  between a command prefix and its command.
- **A server that is up and running last week's rules looks exactly like a
  working one.** `SPEC.md` answered 404 through `pitch-serve` and 200 through
  the real tailnet URL, and the difference was a process started before the
  rule that hides it was written. The suite never sees this, because it starts
  a fresh server for every case; only the long-lived one drifts. `pitch up`
  now records which `pitch-serve` it started and `doctor` says when the file
  has moved on and the process has not. *A missing stamp means launchd started
  it, which is not the same as stale -- a doctor that cries wolf on the
  ordinary install is a doctor nobody reads.*
- **An instruction is not a guard, and the model will follow the instruction.**
  The goal says to leave nothing in the site that is not part of the app. The
  next real build deleted `SPEC.md` -- a correct reading of a rule that was
  wrong, and the loss of the one file here that no rerun can reconstruct. The
  goal now names the exception, and, because a prompt is advice, a copy is
  kept outside the staging tree and restored before anything is published.
  *Raw data is never left in the model's hands. The suite's `ply` stub deletes
  `SPEC.md` on every passing build so this can never quietly come back.*
- **`git` will not commit without an identity, and a fresh container has
  none.** `unable to auto-detect email address (got 'root@2de3dc04d088')`.
  Every commit here therefore falls back to an explicit committer when the
  host has no global config -- found the first time the suite ran on Linux,
  which is what running it there is for.
- **One tree, two operating systems, and symlinks are not portable.** The
  toolbox was first built by `just link` into `tools/`. That directory is a
  bind mount shared with the container, where `node` is `/usr/local/bin/node`
  and not `/opt/homebrew/bin/node` -- so a toolbox built on the Mac is a
  toolbox of dangling links in the container, and `ply -t` reports that as a
  model with no programs at all. The list is checked in; the links are derived
  per build against whatever `PATH` is real at the time.
- **The build directory is the site, so anything left in it is published.**
  The first real edit ended with `clock.png` and `check.txt` served to the
  internet, because the model took a screenshot and had nowhere to put it.
  The goal says so now and `TMPDIR` points at a scratch directory outside the
  tree. There is no mechanical guard, deliberately: the only one available is
  "every published file was fetched when the page loaded", and that would
  delete a lazily-imported module or an offline data file. An honest wart
  beats a rule that eats correct work.

- **`heed` kills a handler at 120 seconds and a build takes minutes.** So a
  build handler answers twice, exactly as `handlers/edm` does: the background
  job closes stdin and stdout, because `heed` reads the handler's stdout
  until end of file and an open descriptor in a forked child holds the first
  reply hostage until the timeout; and it deliberately outlives the alarm,
  which reaches the handler and not a grandchild that has already detached.
- **`ply` takes its goal in argv.** A chat message beginning with `-` becomes
  a flag. The message rides on stdin and the goal is a constant string.
- **`-t tools` aims the model, it does not sandbox it.** `sh` has builtins
  and a redirect opens a file with no program involved. This is why the
  builder runs in the container; claiming otherwise would be the exact lie
  `ply`'s SECURITY.md exists to prevent.
- **Chromium in a container needs `--no-sandbox`,** which is acceptable
  precisely because the container is the sandbox. That sentence belongs next
  to the flag in the code, or somebody will copy the line onto a laptop.
- **`AllowFunnel` is keyed by port, not by path.** A design that assumes
  per-path Funnel makes every private site public the first time anyone
  publishes one. Hence two ports.
- **Funnel needs the attribute enabled on the tailnet,** so the first
  `pitch open` prints Tailscale's own instructions instead of a URL. Once.
- **A bind mount outside `$HOME` silently mounts an empty directory** inside
  the VM -- `shop`'s DESIGN.md cost two runs to this and the container starts
  perfectly either way. The tree lives under `$HOME` and `pitch doctor` says
  so before anything else is believed.
- **A scripted `ask` must pass `-n` or `-f`.** Without it a message from a
  phone continues whatever conversation was last open in a terminal, and
  eventually every reply is exit 2. This is the sharpest edge in the family.
- **`env -i` strips `ASK_MODEL`** and `ask` refuses to guess, so the model is
  configuration and travels with the handler -- which also puts the family's
  rule where it can be acted on: cheap for the classification, strong for the
  build.
- **The Mac sleeps.** Every URL this prints is up only while the Mac is, and
  the reply says so once, when a site is first published.
- **`brief lint` checks the skill, not the app.** A doctrine that drifts from
  what `page-check` enforces is worse than no doctrine, so a rule in
  `web-house` that no case tests is marked as advice rather than as a rule.
- **Idempotency is the deploy story.** Reconcile computes the whole desired
  serve configuration from the tree and applies only the difference, so a
  crash costs one tick and a re-run costs nothing.

## Later, if earned

`hone` over the `ply` sessions where `page-check` failed and then passed,
writing the recurring failures back into `web-house`. The trigger is twenty
real builds, or one failure mode seen three times. Putting it in now would be
decoration, because the doctrine has nothing yet to learn from.
