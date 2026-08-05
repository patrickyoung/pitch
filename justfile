# pitch -- what a human types.

_default:
    @just --list

# the offline suite: no tailnet, no chat network, no model provider
check:
    sh bin/check

# pitch onto ~/.local/bin. The toolbox is not linked here: it is derived at
# build time from etc/toolbox, because this tree is a bind mount and one set
# of symlinks cannot be right on the Mac and in the container at once.
link:
    #!/bin/sh
    set -eu
    mkdir -p "$HOME/.local/bin"
    for p in pitch pitch-serve page-check; do
        ln -sf "$PWD/bin/$p" "$HOME/.local/bin/$p"
        printf 'linked %s\n' "$HOME/.local/bin/$p"
    done

# ~/.config/pitch/env, from the example. heed runs handlers with `env -i`, so
# this file is where the settings actually come from -- not the shell you
# tested in. Make it before `shop up`: a bind mount whose source does not exist
# becomes an empty directory, and then the model is unset inside the container.
config:
    #!/bin/sh
    set -eu
    mkdir -p "$HOME/.config/pitch"
    if [ -f "$HOME/.config/pitch/env" ]; then
        printf '%s already exists, leaving it alone\n' "$HOME/.config/pitch/env"
    else
        cp etc/env.example "$HOME/.config/pitch/env"
        chmod 600 "$HOME/.config/pitch/env"
        printf 'wrote %s -- set PITCH_MODEL in it (ask auth says what you have)\n' "$HOME/.config/pitch/env"
    fi

# the static server and the tailscale configuration
up:
    ./bin/pitch up

down:
    ./bin/pitch down

# what is wrong, before it is wrong
doctor:
    ./bin/pitch doctor

ls:
    ./bin/pitch ls

# give a site its own chat group. Stop matterbridge first; it says so if not
group name:
    ./bin/pitch group {{name}}

# two launchd jobs: the server, and the reconcile that notices a site the
# container built. Both are needed once the phone is in the loop -- the Mac
# cannot watch the mount, so it asks the tree instead, once a minute.
install:
    #!/bin/sh
    set -eu
    mkdir -p "$HOME/Library/LaunchAgents" log
    for j in com.bench.pitch com.bench.pitch-reconcile; do
        sed "s|@ROOT@|$PWD|g; s|@HOME@|$HOME|g" "launchd/$j.plist" \
            >"$HOME/Library/LaunchAgents/$j.plist"
        launchctl unload "$HOME/Library/LaunchAgents/$j.plist" 2>/dev/null || true
        launchctl load "$HOME/Library/LaunchAgents/$j.plist"
        printf 'loaded %s\n' "$j"
    done

tail:
    tail -f log/serve.log
