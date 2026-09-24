#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import tempfile
import threading
import time
import uuid
from pathlib import Path
from typing import Any

from rich.console import Console
from rich.live import Live
from rich.table import Table
from rich.text import Text

# --- Constants ---

TASKS = {
    "vim": {
        "command": "nix run .#vimPluginsUpdater",
        "self_committing": False,
        "worktree": "vim",
        "depends_on": None,
    },
    "lua": {
        "command": "nix run .#luarocks-packages-updater",
        "self_committing": False,
        "worktree": "lua",
        "depends_on": None,
    },
    "yazi": {
        "command": "./pkgs/by-name/ya/yazi/plugins/update.py --all --commit",
        "self_committing": True,
        "worktree": "yazi",
        "depends_on": None,
    },
}

BRANCH_PREFIX = "updates"
BASE_DIR = Path(os.getcwd())

# Shared state for tracking task progress
task_state: dict[str, dict[str, Any]] = {}
state_lock = threading.Lock()
console = Console()


def update_task_state(
    task_name: str,
    status: str | None = None,
    output: str | None = None,
    error: bool = False,
):
    """Thread-safe update of task state."""
    with state_lock:
        if task_name not in task_state:
            task_state[task_name] = {
                "status": "PENDING",
                "output_lines": [],
                "error": False,
            }
        if status is not None:
            task_state[task_name]["status"] = status
        if output is not None:
            # Keep last 3 lines of output
            task_state[task_name]["output_lines"].append(output)
            if len(task_state[task_name]["output_lines"]) > 10:
                task_state[task_name]["output_lines"].pop(0)
        if error:
            task_state[task_name]["error"] = True


def generate_table() -> Table:
    """Generate a Rich table from current task state."""
    table = Table(
        title="Updating Nixpkgs Plugins", show_header=True, header_style="bold magenta"
    )
    table.add_column("Task", style="cyan", no_wrap=True)
    table.add_column("Status", style="green")
    table.add_column("Recent Output (last 10 lines)", style="white")

    status_icons = {
        "PENDING": "🕒",
        "SETUP": "⚙️",
        "RUNNING": "🏃",
        "COMPLETE": "✅",
        "ERROR": "❌",
    }

    with state_lock:
        for task_name in TASKS:
            state = task_state.get(
                task_name, {"status": "PENDING", "output_lines": [], "error": False}
            )
            status = state["status"]
            output_lines = state["output_lines"]
            error = state["error"]

            icon = status_icons.get(status, "❓")
            status_text = Text(f"{status} {icon}")

            if error:
                status_text.stylize("bold red")
            elif status == "COMPLETE":
                status_text.stylize("bold green")
            elif status == "RUNNING":
                status_text.stylize("bold yellow")

            # Display all output lines without truncation
            display_output = "\n".join(output_lines) if output_lines else ""

            table.add_row(task_name, status_text, display_output)

    return table


def run_command(command, cwd=BASE_DIR, capture_output=False):
    """Runs a shell command, optionally capturing output."""
    env = os.environ.copy()
    if capture_output:
        result = subprocess.run(
            command,
            shell=True,
            cwd=cwd,
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        return result
    else:
        subprocess.run(
            command,
            shell=True,
            cwd=cwd,
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return None


worktrees: dict[str, dict[str, str]] = {}


def setup_full_worktree(worktree_name: str):
    """Create a fresh worktree without replacing existing branches or files."""
    refs = subprocess.check_output(
        ["git", "for-each-ref", "--format=%(refname:strip=2)", "refs/heads/"],
        cwd=BASE_DIR,
        text=True,
    ).splitlines()

    def conflicts(candidate):
        return any(
            candidate == ref
            or candidate.startswith(ref + "/")
            or ref.startswith(candidate + "/")
            for ref in refs
        )

    branch_name = f"{BRANCH_PREFIX}/{worktree_name}"
    while conflicts(branch_name):
        branch_name = f"{BRANCH_PREFIX}-{worktree_name}-{uuid.uuid4().hex[:12]}"

    root = Path(os.environ.get("NIXPKGS_UPDATE_WORKTREE_ROOT", "/tmp"))
    root.mkdir(parents=True, exist_ok=True)
    worktree_dir = root / f"{worktree_name}-worktree"
    if worktree_dir.exists():
        worktree_dir = Path(
            tempfile.mkdtemp(prefix=f"{worktree_name}-worktree-", dir=root)
        )
    subprocess.run(
        ["git", "worktree", "add", "-b", branch_name, str(worktree_dir), "HEAD"],
        cwd=BASE_DIR,
        check=True,
    )
    worktrees[worktree_name] = {"branch": branch_name, "path": str(worktree_dir)}
    manifest = os.environ.get("NIXPKGS_UPDATE_WORKTREE_MANIFEST")
    if manifest:
        Path(manifest).write_text(json.dumps(worktrees, indent=2) + "\n")


def run_update_in_worktree(task_name: str, task_details: dict, task_events: dict):
    """Runs the update script within its prepared worktree and commits the result."""
    worktree_name = task_details["worktree"]
    worktree_dir = Path(worktrees[worktree_name]["path"])
    command = task_details["command"]
    self_committing = task_details["self_committing"]
    depends_on = task_details["depends_on"]
    log_file = Path(f"/tmp/{task_name}-update.log")

    # Wait for dependency if specified
    if depends_on:
        update_task_state(
            task_name, status="PENDING", output=f"Waiting for {depends_on}..."
        )
        task_events[depends_on].wait()
        update_task_state(
            task_name, status="SETUP", output="Dependency complete, starting..."
        )

    update_task_state(task_name, status="RUNNING", output="Starting update...")
    update_task_state(task_name, output=f"Full log: {log_file}")

    try:
        with open(log_file, "w") as log:
            process = subprocess.Popen(
                command,
                shell=True,
                cwd=worktree_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                env=os.environ.copy(),
            )

            for line in process.stdout:
                line = line.strip()
                if line:
                    log.write(line + "\n")
                    log.flush()
                    update_task_state(task_name, output=line)

            process.wait()

        if process.returncode != 0:
            update_task_state(
                task_name,
                status="ERROR",
                output=f"Command failed with code {process.returncode}. See {log_file}",
                error=True,
            )
            return

        # Only commit if the task command doesn't do it itself
        if not self_committing:
            update_task_state(task_name, output="Committing changes...")
            run_command("git add -A", cwd=worktree_dir)
            commit_result = run_command(
                f'git commit -m "feat({task_name}): update {task_name}"',
                cwd=worktree_dir,
                capture_output=True,
            )

            if commit_result and commit_result.returncode == 0:
                update_task_state(task_name, output="Changes committed")
            else:
                update_task_state(task_name, output="No changes to commit")

        update_task_state(task_name, status="COMPLETE", output="Update complete!")

    except Exception as e:  # noqa: BLE001 - thread boundary must mark task failures
        update_task_state(task_name, status="ERROR", output=str(e), error=True)
    finally:
        # Signal completion so dependent tasks can proceed
        task_events[task_name].set()


def main():
    """Main function to run the update process."""
    if "GITHUB_TOKEN" not in os.environ:
        console.print(
            "[bold red]Error:[/bold red] GITHUB_TOKEN environment variable is not set."
        )
        sys.exit(1)

    # Get original branch
    result = subprocess.run(
        "git rev-parse --abbrev-ref HEAD",
        shell=True,
        capture_output=True,
        text=True,
        check=False,
    )
    original_branch = result.stdout.strip()

    # Initialize task state
    for task_name in TASKS:
        update_task_state(task_name, status="PENDING")

    try:
        # Setup unique worktrees (tasks can share worktrees)
        unique_worktrees = {task["worktree"] for task in TASKS.values()}
        for worktree_name in unique_worktrees:
            setup_full_worktree(worktree_name)

        # Create events for task synchronization
        task_events = {task_name: threading.Event() for task_name in TASKS}

        # Start all update tasks in threads
        threads = []
        for task_name, task_details in TASKS.items():
            thread = threading.Thread(
                target=run_update_in_worktree,
                args=(task_name, task_details, task_events),
            )
            threads.append(thread)
            thread.start()

        # Display live-updating table
        with Live(generate_table(), console=console, refresh_per_second=4) as live:
            while any(t.is_alive() for t in threads):
                live.update(generate_table())
                time.sleep(0.25)
            # Final update after all threads complete
            live.update(generate_table())

        # Summary
        console.print(
            "\n[bold green]✅ All updates are complete and ready for individual PRs.[/bold green]"
        )
        console.print("[bold]Branches and worktrees:[/bold]")

        # Group tasks by worktree
        worktree_tasks = {}
        for task_name, task_details in TASKS.items():
            worktree_name = task_details["worktree"]
            if worktree_name not in worktree_tasks:
                worktree_tasks[worktree_name] = []
            worktree_tasks[worktree_name].append(task_name)

        # Display each worktree with its tasks
        for worktree_name, task_names in worktree_tasks.items():
            branch_name = worktrees[worktree_name]["branch"]
            worktree_dir = Path(worktrees[worktree_name]["path"])

            # Check if any task had an error
            has_error = any(
                task_state.get(t, {}).get("error", False) for t in task_names
            )
            tasks_list = ", ".join(task_names)

            if has_error:
                console.print(
                    f"  [red]❌ {worktree_name}:[/red] [{tasks_list}] Branch: {branch_name}, Path: {worktree_dir}"
                )
            else:
                console.print(
                    f"  [green]✅ {worktree_name}:[/green] [{tasks_list}] Branch: {branch_name}, Path: {worktree_dir}"
                )

    finally:
        console.print(
            f"\n[bold]--- Returning you to your original branch: {original_branch} ---[/bold]"
        )
        run_command(f"git checkout {original_branch}")


if __name__ == "__main__":
    main()
