#!/usr/bin/env python3

import argparse
import subprocess


def run(cmd, capture_output=True):
    """Runs a command and returns its stdout."""
    return subprocess.run(
        cmd, check=True, text=True, capture_output=capture_output
    ).stdout.strip()


def get_drv_path(flake_output):
    """Gets the .drv path of a flake output without building it."""
    print(f"🔎 Getting derivation path for: {flake_output}")
    return run(["nix", "eval", "--raw", f"{flake_output}.drvPath"])


def generate_dot(drv_path, output_path="graph.dot"):
    """Generates a DOT graph from a derivation path."""
    print(f"🧬 Generating DOT graph from: {drv_path}")
    with open(output_path, "w") as f:
        subprocess.run(
            ["nix-store", "--query", "--graph", drv_path], stdout=f, check=True
        )
    print(f"✅ DOT graph written to: {output_path}")


def convert_to_svg(dot_path="graph.dot", svg_path="graph.svg"):
    """Converts a DOT file to an SVG file using graphviz."""
    try:
        print(f"🎨 Converting {dot_path} to {svg_path}...")
        subprocess.run(["sfdp", "-Tsvg", "-x", "-o", svg_path, dot_path], check=True)
        print(f"✅ SVG written to: {svg_path}")
    except FileNotFoundError:
        print("⚠️ 'sfdp' (graphviz) not found. Skipping SVG generation.")
        print("   You can install it by adding `graphviz` to your packages.")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error during SVG conversion: {e}")


def main():
    parser = argparse.ArgumentParser(
        prog="nix-dep-graph",
        description="Generate DOT and SVG dependency graphs for a Nix flake output.",
        epilog="Example: nix-dep-graph .#closure-analyzer",
    )
    parser.add_argument("flake_output", metavar="flake-output")
    args = parser.parse_args()

    drv_path = get_drv_path(args.flake_output)

    generate_dot(drv_path)
    convert_to_svg()


if __name__ == "__main__":
    main()
