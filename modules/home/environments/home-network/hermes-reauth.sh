# Runs as root on the home server. Signs Hermes into OpenAI Codex again, drops
# the logins the new one replaces, and checks that Hermes answers.
set -eu

container=HermesAgent

# Hermes owns its state as uid 99, so every command runs as that user.
as_gateway() {
    docker exec -u 99:100 -e HERMES_HOME=/opt/data -e HOME=/opt/data "$@"
}

pool_python() {
    as_gateway -i -w /opt/hermes "$@" "$container" /opt/hermes/.venv/bin/python3 -
}

old_ids=$(
    pool_python <<'PY'
from agent.credential_pool import load_pool

print(" ".join(entry.id for entry in load_pool("openai-codex").entries()))
PY
)

echo "Approve the code from a private browser window so the sign-in is new."
as_gateway -it "$container" hermes auth add openai-codex --type oauth --priority 0 --no-browser

# `hermes auth remove` would also suppress the new login's source, so remove
# pool rows directly. Every row that predates this login goes: the pool holds
# one account, and a new login of an account revokes its older ones. Match rows
# by account first if a second account is ever pooled.
pool_python -e OLD_IDS="$old_ids" <<'PY'
import os

from agent.credential_pool import load_pool

for old_id in os.environ["OLD_IDS"].split():
    pool = load_pool("openai-codex")
    index, matched, _error = pool.resolve_target(old_id)
    if matched is not None:
        pool.remove_index(index)
        print(f"Removed old login {old_id}")
PY

docker restart "$container" >/dev/null
tries=0
until [ "$(docker inspect -f '{{.State.Health.Status}}' "$container")" = healthy ]; do
    tries=$((tries + 1))
    if [ "$tries" -gt 30 ]; then
        echo "$container did not become healthy after the restart." >&2
        exit 1
    fi
    sleep 2
done

if as_gateway "$container" hermes chat -q 'Reply with exactly: auth ok' --oneshot -Q | grep -qi '^auth ok'; then
    echo "Hermes answered through the new login."
else
    echo "The new login is saved, but the test chat did not answer." >&2
    exit 1
fi
