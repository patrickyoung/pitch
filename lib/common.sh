# lib/common.sh -- sourced by pitch and pitch-chat. Nothing here runs alone.
#
# What lives here is what every program has to agree about: where the tree is,
# what a usable site name is, and what URL a site has. A name validated in one
# program and not another is how this becomes a remote shell, so there is
# exactly one function that decides -- and bin/pitch-serve carries the same
# rule as a regexp, with case 2 of the suite running both against one list.

die() {
	printf '%s: %s\n' "${0##*/}" "$*" >&2
	exit 1
}

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# GNU first, BSD second, and the order is the whole point. `stat -c` on macOS
# is an illegal option and exits nonzero, so the fallback fires. `stat -f` on
# GNU is not an error at all -- it means *filesystem* status, so it reads the
# format as a filename, prints something anyway, and exits 0. Written the
# other way round the fallback never runs on Linux and the answer is a
# paragraph. hail lost a container's first run to exactly this line.
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }

# Symlink resolution lives inline at the top of each program rather than here:
# it has to run before this file can be found at all.

# No token lives in this file, unlike hail's, so there is no mode to refuse.
# It exists because launchd inherits almost no environment and a container
# inherits a different one, and neither is the shell you tested in.
load_config() {
	conf=${PITCH_CONFIG:-$HOME/.config/pitch/env}
	if [ -f "$conf" ]; then
		set -a
		. "$conf"
		set +a
	fi
	: "${PITCH_PORT:=8787}"          # the static server, loopback only
	: "${PITCH_HTTPS_PORT:=443}"     # tailnet-only, the default
	: "${PITCH_FUNNEL_PORT:=8443}"   # reachable from the internet, opt-in
	# Match the model to the job. A slug and a classification are cheap
	# questions; writing a whole app is not, and -m is per call.
	: "${PITCH_MODEL:=}"             # writes the app
	: "${PITCH_SMALL_MODEL:=${PITCH_MODEL}}"  # slugs, specs, classification
	: "${PITCH_CYCLES:=6}"           # failed checks before ply gives up
	: "${PITCH_CMD_TIMEOUT:=120s}"   # per command ply runs
	# A wall clock on the whole build. -cycles bounds the loop and
	# -timeout bounds one command, and neither bounds the run: one ply
	# worked a deleted directory for 23 hours 47 minutes, calling a model,
	# and nothing noticed. Generous against a three-minute build.
	: "${PITCH_BUILD_MAX:=1800}"
	: "${PITCH_PAGE_TIMEOUT:=45}"    # seconds page-check gives one page
	: "${PITCH_BUDGET:=512000}"      # bytes over the wire, same origin
	: "${PITCH_TAILSCALE:=}"
	export PITCH_PORT PITCH_HTTPS_PORT PITCH_FUNNEL_PORT PITCH_MODEL
	export PITCH_SMALL_MODEL PITCH_CYCLES PITCH_CMD_TIMEOUT PITCH_PAGE_TIMEOUT
	export PITCH_BUDGET PITCH_BUILD_MAX
}

# A site name becomes a path component, a URL path, a git repository, a
# matterbridge gateway and a program name. This is the only place that decides
# whether a string may become any of them. bin/pitch-serve holds the same rule
# as a regexp because it must answer without sourcing shell, and the suite
# checks that the two never disagree.
#
# The character sets are written out longhand, and that is not style. A range
# inside a bracket expression is resolved by the *collating sequence*, not by
# the codepoints, and macOS /bin/sh is bash 3.2, whose en_US collation
# interleaves case -- so `case Pomodoro in *[!a-z0-9-]*)` does not match, and
# the guard silently accepts it. The same line rejects it under LC_ALL=C and
# under other shells, which is the worst possible property for a validator:
# right on the machine you tested, wrong on the machine that matters.
# bin/pitch-serve holds the same rule as a JavaScript regexp, where [a-z] is
# codepoints and always was, and case 2 of the suite runs both against one list.
valid_name() {
	case ${1:-} in
	'' | *[!abcdefghijklmnopqrstuvwxyz0123456789-]*) return 1 ;;
	[!abcdefghijklmnopqrstuvwxyz]*) return 1 ;;
	*-) return 1 ;;
	esac
	[ "${#1}" -le 32 ]
}

# The one tool that is not on PATH by its own name on a Mac, because Tailscale
# ships as an app bundle. $PITCH_TAILSCALE wins for a machine that has neither.
tailscale_bin() {
	if [ -n "${PITCH_TAILSCALE:-}" ]; then printf '%s\n' "$PITCH_TAILSCALE"; return 0; fi
	if command -v tailscale >/dev/null 2>&1; then printf 'tailscale\n'; return 0; fi
	for t in /Applications/Tailscale.app/Contents/MacOS/Tailscale /usr/bin/tailscale; do
		[ -x "$t" ] && { printf '%s\n' "$t"; return 0; }
	done
	return 1
}

# The node's own name in the tailnet, or nothing when there is no tailnet yet.
# Empty is an answer: every URL then falls back to loopback, which is true.
tailnet_host() {
	ts=$(tailscale_bin) || return 1
	"$ts" status --json 2>/dev/null | jq -r '.Self.DNSName // ""' 2>/dev/null | sed 's/\.$//'
}

# Private is 443 and public is 8443, because AllowFunnel is keyed by port and
# not by path -- one funnelled port would make every path on it public. The
# visibility is therefore in the URL, on purpose: these cannot be confused.
site_url() {
	name=$1
	host=${PITCH_HOST:-$(tailnet_host 2>/dev/null || true)}
	if [ -z "$host" ]; then
		printf 'http://127.0.0.1:%s/%s/\n' "$PITCH_PORT" "$name"
	elif [ -f "$ROOT/sites/$name/.public" ]; then
		printf 'https://%s:%s/%s/\n' "$host" "$PITCH_FUNNEL_PORT" "$name"
	else
		printf 'https://%s/%s/\n' "$host" "$name"
	fi
}

# One JSON object on stdin becomes one line in today's log for one site. The
# path is computed per call and never cached: a daemon that lives for weeks
# and opens today's file once writes Tuesday into Monday's file forever.
logappend() {
	p=$ROOT/log/$1/$(date -u +%F).jsonl
	mkdir -p "${p%/*}"
	# A single printf is a single write(2), so two appenders cannot interleave.
	printf '%s\n' "$(cat)" >>"$p"
}
