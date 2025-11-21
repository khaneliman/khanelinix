#!/usr/bin/env python3

import os
import shutil
import subprocess
import threading
from pathlib import Path
from typing import Any, Dict

from rich.console import Console
from rich.live import Live
from rich.table import Table
from rich.text import Text

# --- Constants ---

TASKS = {
    "vim": {
        "command": "nix run nixpkgs#vimPluginsUpdater -- --github-token=${GITHUB_TOKEN}",
        "self_committing": False,
        "worktree": "vim",
        "depends_on": None,
    },
    "treesitter": {
        "command": "nix-shell -p python3Packages.requests --run 'python3 ./pkgs/applications/editors/vim/plugins/utils/nvim-treesitter/update.py && git add ./pkgs/applications/editors/vim/plugins/nvim-treesitter/generated.nix && git commit -m \"vimPlugins.nvim-treesitter: update grammars\"'",
        "self_committing": True,
        "worktree": "vim",
        "depends_on": "vim",
    },
    "lua": {
        "command": "nix run nixpkgs#luarocks-packages-updater -- --github-token=${GITHUB_TOKEN}",
        "self_committing": False,
        "worktree": "lua",
        "depends_on": None,
    },
    "yazi": {
        "command": "nix-shell -p python3Packages.requests -p python3Packages.packaging --run 'python3 ./pkgs/by-name/ya/yazi/plugins/update.py --all --commit'",
        "self_committing": True,
        "worktree": "yazi",
        "depends_on": None,
    },
}

BRANCH_PREFIX = "updates"
BASE_DIR = Path(os.getcwd())

# Shared state for tracking task progress
task_state: Dict[str, Dict[str, Any]] = {}
state_lock = threading.Lock()
console = Console()


def update_task_state(
    task_name: str, status: str = None, output: str = None, error: bool = False
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
        for task_name in TASKS.keys():
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
    try:
        env = os.environ.copy()
        if capture_output:
            result = subprocess.run(
                command,
                shell=True,
                cwd=cwd,
                env=env,
                capture_output=True,
                text=True,
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
            )
            return None
    except subprocess.CalledProcessError:
        raise


def setup_full_worktree(worktree_name: str):
    """Prepares a full worktree for a task."""
    branch_name = f"{BRANCH_PREFIX}/{worktree_name}"
    worktree_dir = Path(f"/tmp/{worktree_name}-worktree")

    run_command(f"git branch -D {branch_name}")
    if worktree_dir.exists():
        shutil.rmtree(worktree_dir)
    run_command("git worktree prune")
    run_command(f"git worktree add {worktree_dir} -B {branch_name}")


def run_update_in_worktree(task_name: str, task_details: dict, task_events: dict):
    """Runs the update script within its prepared worktree and commits the result."""
    worktree_name = task_details["worktree"]
    worktree_dir = Path(f"/tmp/{worktree_name}-worktree")
    command = task_details["command"]
    self_committing = task_details["self_committing"]
    depends_on = task_details["depends_on"]

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

    try:
        # Run the update command and capture output
        process = subprocess.Popen(
            command,
            shell=True,
            cwd=worktree_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            env=os.environ.copy(),
        )

        # Read output line by line
        for line in process.stdout:
            line = line.strip()
            if line:
                update_task_state(task_name, output=line)

        process.wait()

        if process.returncode != 0:
            update_task_state(
                task_name,
                status="ERROR",
                output=f"Command failed with code {process.returncode}",
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

    except Exception as e:
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
        exit(1)

    # Get original branch
    result = subprocess.run(
        "git rev-parse --abbrev-ref HEAD",
        shell=True,
        capture_output=True,
        text=True,
    )
    original_branch = result.stdout.strip()

    # Initialize task state
    for task_name in TASKS.keys():
        update_task_state(task_name, status="PENDING")

    try:
        # Setup unique worktrees (tasks can share worktrees)
        unique_worktrees = set(task["worktree"] for task in TASKS.values())
        for worktree_name in unique_worktrees:
            setup_full_worktree(worktree_name)

        # Create events for task synchronization
        task_events = {task_name: threading.Event() for task_name in TASKS.keys()}

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
            branch_name = f"{BRANCH_PREFIX}/{worktree_name}"
            worktree_dir = Path(f"/tmp/{worktree_name}-worktree")

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
