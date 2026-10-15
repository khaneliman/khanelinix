import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

executable = Path(sys.argv[1]).resolve()
request = {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {"protocolVersion": 1, "clientCapabilities": {}},
}

with tempfile.TemporaryDirectory(prefix="antigravity-acp-check-") as home:
    result = subprocess.run(
        [str(executable), *(["--uid="] if sys.platform == "linux" else [])],
        input=json.dumps(request) + "\n",
        capture_output=True,
        text=True,
        timeout=60,
        check=False,
        cwd=home,
        env={
            "PATH": os.environ["PATH"],
            "HOME": home,
            "GEMINI_HOME": str(Path(home) / "profile"),
            "TMPDIR": home,
            "ANTIGRAVITY_HARNESS_PATH": str(
                executable.with_name("localharness_external")
            ),
        },
    )

assert result.returncode == 0, result.stderr
responses = [json.loads(line) for line in result.stdout.splitlines() if line.strip()]
response = next(item for item in responses if item.get("id") == 1)
assert "error" not in response, response
assert response["result"]["protocolVersion"] == 1, response
assert response["result"]["agentInfo"]["name"] == "antigravity-acp", response
assert any(
    method["id"] == "oauth-personal" for method in response["result"]["authMethods"]
)
print("Antigravity ACP initialization passed without authentication")
