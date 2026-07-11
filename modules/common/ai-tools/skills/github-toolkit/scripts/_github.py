"""Shared deterministic GitHub CLI transport and target resolution."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

REPOSITORY_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
URL_PREFIX_PATTERN = re.compile(r"^https?://", re.IGNORECASE)
PULL_REQUEST_URL_PATTERN = re.compile(
    r"^https://github\.com/([^/]+)/([^/]+)/pull/(\d+)(?:/.*)?$",
    re.IGNORECASE,
)


class ToolkitError(RuntimeError):
    """Base error for deterministic user-facing failures."""


class InputError(ToolkitError):
    """Raised when caller input violates a script contract."""


class GitHubError(ToolkitError):
    """Raised when gh or GitHub returns a failure."""


@dataclass(frozen=True)
class Target:
    repository: str
    pull_request: int

    @property
    def owner(self) -> str:
        return self.repository.split("/", 1)[0]

    @property
    def name(self) -> str:
        return self.repository.split("/", 1)[1]

    def as_json(self) -> dict[str, Any]:
        return {
            "pull_request": self.pull_request,
            "repository": self.repository,
        }


class GhClient:
    """Run gh without a shell and exchange structured data through stdin/stdout."""

    def __init__(self, cwd: Path | None = None):
        self.cwd = cwd

    def run(
        self,
        args: Sequence[str],
        *,
        stdin: str | None = None,
        cwd: Path | None = None,
    ) -> str:
        process = subprocess.run(
            ["gh", *args],
            cwd=cwd or self.cwd,
            input=stdin,
            text=True,
            capture_output=True,
            check=False,
        )
        if process.returncode != 0:
            detail = (process.stderr or process.stdout).strip()
            if not detail:
                detail = "gh returned no diagnostic output"
            raise GitHubError(f"gh failed with exit {process.returncode}: {detail}")
        return process.stdout

    def run_json(
        self,
        args: Sequence[str],
        *,
        input_value: Mapping[str, Any] | Sequence[Any] | None = None,
        cwd: Path | None = None,
    ) -> Any:
        stdin = None
        if input_value is not None:
            stdin = json.dumps(input_value, separators=(",", ":"))
        output = self.run(args, stdin=stdin, cwd=cwd)
        try:
            return json.loads(output)
        except json.JSONDecodeError as error:
            raise GitHubError(
                f"gh returned invalid JSON at line {error.lineno} column {error.colno}"
            ) from error

    def graphql(self, query: str, variables: Mapping[str, Any]) -> dict[str, Any]:
        payload = self.run_json(
            ["api", "graphql", "--input", "-"],
            input_value={"query": query, "variables": dict(variables)},
        )
        if not isinstance(payload, dict):
            raise GitHubError("GitHub GraphQL response was not an object")
        errors = payload.get("errors")
        if errors:
            raise GitHubError(
                "GitHub GraphQL returned errors: "
                + json.dumps(errors, sort_keys=True, separators=(",", ":"))
            )
        return payload


def parse_pull_request_url(value: str) -> Target | None:
    match = PULL_REQUEST_URL_PATTERN.fullmatch(value.strip())
    if match is None:
        return None
    owner, repository, number = match.groups()
    return Target(f"{owner}/{repository}", int(number))


def repository_cwd(repository: str | None) -> Path | None:
    if repository is None or REPOSITORY_PATTERN.fullmatch(repository):
        return None
    path = Path(repository).expanduser()
    if not path.exists():
        raise InputError(
            f"--repo must be OWNER/REPO or an existing checkout path: {repository}"
        )
    if not path.is_dir():
        raise InputError(f"--repo checkout path is not a directory: {repository}")
    return path.resolve()


def resolve_repository(client: GhClient, repository: str | None) -> str:
    if repository and REPOSITORY_PATTERN.fullmatch(repository):
        return repository

    cwd = repository_cwd(repository)
    payload = client.run_json(
        ["repo", "view", "--json", "nameWithOwner"],
        cwd=cwd,
    )
    if not isinstance(payload, dict):
        raise GitHubError("gh repo view returned an unexpected JSON shape")
    name_with_owner = payload.get("nameWithOwner")
    if not isinstance(name_with_owner, str) or not REPOSITORY_PATTERN.fullmatch(
        name_with_owner
    ):
        raise GitHubError("gh repo view did not return a valid nameWithOwner")
    return name_with_owner


def resolve_target(
    client: GhClient,
    repository: str | None,
    pull_request: str | int | None,
) -> Target:
    """Resolve the base repository and PR number, including fork PR URLs."""

    if isinstance(pull_request, int):
        if pull_request <= 0:
            raise InputError("--pr must be a positive integer or pull request URL")
        return Target(resolve_repository(client, repository), pull_request)

    if pull_request is not None:
        value = str(pull_request).strip()
        url_target = parse_pull_request_url(value)
        if url_target is not None:
            if repository is not None:
                resolved_repository = resolve_repository(client, repository)
                if resolved_repository.lower() != url_target.repository.lower():
                    raise InputError(
                        "--repo conflicts with pull request URL base repository: "
                        f"{resolved_repository} != {url_target.repository}"
                    )
            return url_target
        if URL_PREFIX_PATTERN.match(value):
            raise InputError(
                "--pr URL must use https://github.com/OWNER/REPO/pull/NUMBER"
            )
        try:
            number = int(value)
        except ValueError as error:
            raise InputError(
                "--pr must be a positive integer or pull request URL"
            ) from error
        if number <= 0:
            raise InputError("--pr must be a positive integer or pull request URL")
        return Target(resolve_repository(client, repository), number)

    if repository and REPOSITORY_PATTERN.fullmatch(repository):
        raise InputError(
            "--pr is required when --repo is OWNER/REPO; current-branch "
            "resolution requires the current checkout or a checkout path"
        )

    cwd = repository_cwd(repository)
    args = ["pr", "view", "--json", "number,url"]
    payload = client.run_json(args, cwd=cwd)
    if not isinstance(payload, dict):
        raise GitHubError("gh pr view returned an unexpected JSON shape")
    url = payload.get("url")
    number = payload.get("number")
    if not isinstance(url, str) or not isinstance(number, int):
        raise GitHubError("gh pr view did not return number and url")
    target = parse_pull_request_url(url)
    if target is None or target.pull_request != number:
        raise GitHubError("gh pr view returned an invalid pull request URL")
    if repository is not None:
        resolved_repository = resolve_repository(client, repository)
        if resolved_repository.lower() != target.repository.lower():
            raise InputError(
                "--repo conflicts with current branch pull request base repository: "
                f"{resolved_repository} != {target.repository}"
            )
    return target


def current_actor(client: GhClient) -> str:
    payload = client.run_json(["api", "user"])
    if not isinstance(payload, dict) or not isinstance(payload.get("login"), str):
        raise GitHubError("GitHub user response did not include login")
    return payload["login"]


def pull_request_oids(client: GhClient, target: Target) -> dict[str, str]:
    """Fetch current base/head OIDs without loading PR collections."""

    payload = client.run_json(
        [
            "pr",
            "view",
            str(target.pull_request),
            "--repo",
            target.repository,
            "--json",
            "baseRefOid,headRefOid",
        ]
    )
    if not isinstance(payload, dict):
        raise GitHubError("gh pr view returned an unexpected OID response")
    base_sha = payload.get("baseRefOid")
    head_sha = payload.get("headRefOid")
    if not isinstance(base_sha, str) or not isinstance(head_sha, str):
        raise GitHubError("gh pr view did not return base and head OIDs")
    return {"base_sha": base_sha, "head_sha": head_sha}


def read_json_input(path: str) -> dict[str, Any]:
    try:
        raw = sys.stdin.read() if path == "-" else Path(path).read_text()
    except OSError as error:
        raise InputError(f"cannot read JSON input {path}: {error}") from error
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as error:
        raise InputError(
            f"invalid JSON input at line {error.lineno} column {error.colno}"
        ) from error
    if not isinstance(value, dict):
        raise InputError("JSON input must be an object")
    return value


def read_text_input(value: str | None, path: str | None) -> str:
    if (value is None) == (path is None):
        raise InputError("provide exactly one of --body or --body-file")
    if value is not None:
        body = value
    else:
        assert path is not None
        try:
            body = sys.stdin.read() if path == "-" else Path(path).read_text()
        except OSError as error:
            raise InputError(f"cannot read body input {path}: {error}") from error
    if not body.strip():
        raise InputError("body must not be empty")
    return body


def emit_json(value: Any) -> None:
    json.dump(value, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")


def fail(error: Exception) -> int:
    print(f"error: {error}", file=sys.stderr)
    return 2 if isinstance(error, InputError) else 1
