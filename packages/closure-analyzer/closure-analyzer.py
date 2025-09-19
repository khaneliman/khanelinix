#!/usr/bin/env python3
"""
Closure Size Analyzer for Nix Configurations
Analyzes closure size, identifies large dependencies, and provides optimization insights
"""

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple


@dataclass
class Package:
    path: str
    name: str
    dep_inclusive_size: int
    actual_size: int
    dep_inclusive_gb: float
    actual_gb: float


@dataclass
class AnalysisResult:
    total_size: int
    total_size_gb: float
    packages: List[Package]
    large_packages: List[Package]
    categories: Dict[str, List[Package]]


class ClosureAnalyzer:
    def __init__(self, target: str, size_threshold_gb: float = 1.0):
        self.target = target
        self.size_threshold_gb = size_threshold_gb
        self.size_threshold = int(size_threshold_gb * 1024 * 1024 * 1024)

        # Define package categories for better analysis
        self.categories = {
            "Runtimes & SDKs": [
                "openjdk",
                "jdk",
                "jre",
                "dotnet",
                ".net",
                "nodejs",
                "node-",
                "-source",
                "python3",
                "python-",
                "ruby",
                "perl",
                "ghc",
                "haskell",
            ],
            "Language Servers": [
                "language-server",
                "-ls",
                "lsp-",
                "rust-analyzer",
                "typescript-language-server",
                "pyright",
                "jdt-language-server",
                "fish-lsp",
                "tailwindcss-language-server",
                "vscode-langservers",
                "fsautocomplete",
                "copilot-language-server",
                "helm-ls",
                "roslyn-ls",
            ],
            "Shells & Terminal Tools": [
                "nushell",
                "zsh",
                "fish",
                "bash",
                "zellij",
                "tmux",
                "screen",
                "carapace",
                "starship",
            ],
            "Git & VCS Tools": [
                "gh-",
                "glab-",
                "git-",
                "mergiraf",
                "difftastic",
                "gitui",
                "lazygit",
            ],
            "AI & Automation Tools": [
                "gemini-cli",
                "claude-code",
                "opencode",
                "copilot",
                "ai-",
                "chatgpt",
            ],
            "Code Quality Tools": [
                "biome",
                "ruff",
                "golangci-lint",
                "harper",
                "clippy",
            ],
            "Documentation & Publishing": [
                "pandoc",
                "tex",
                "latex",
                "markdown",
                "sphinx",
                "hugo",
                "jekyll",
            ],
            "Databases & Data Tools": [
                "duckdb",
                "sqlite",
                "postgresql",
                "redis",
                "mongodb",
                "mysql",
            ],
            "Audio & Media Libraries": [
                "flite",
                "espeak",
                "alsa",
                "pulseaudio",
                "pipewire",
                "gstreamer",
                "ffmpeg",
                "imagemagick",
                "vulkan",
            ],
            "Development Tools": [
                "clang",
                "rust",
                "cargo",
                "gcc",
                "llvm",
                "cmake",
                "boost",
                "go-",
            ],
            "Editors & Extensions": [
                "vim",
                "neovim",
                "vscode",
                "emacs",
                "helix",
                "nixvim",
                "markdown-preview",
                "opencode",
                "claude-code",
            ],
            "System Libraries": [
                "glibc",
                "systemd",
                "mesa",
                "qtbase",
                "qtdeclarative",
                "qt5",
                "qt6",
                "gtk+3",
                "gtk4",
                "glib",
                "qt-",
                "gtk",
                "ghostscript",
                "cairo",
                "pango",
            ],
            "Fonts": [
                "font-",
                "-font",
                "fonts-",
                "fontconfig",
                "monaspace",
                "nerd-fonts",
            ],
            "Formatters/Linters": [
                "prettier",
                "eslint",
                "black",
                "rustfmt",
                "clang-format",
                "csharpier",
            ],
            "Package Managers & Indexes": ["npm-deps", "index-", "nix-index"],
            "GUI Applications": [
                "qtcreator",
                "bruno",
                "postman",
                "firefox",
                "chromium",
            ],
            "Media/Graphics": ["ffmpeg", "imagemagick", "mesa", "vulkan", "graphics"],
            "Container/VM": ["docker", "podman", "qemu", "virtualbox"],
            "Gaming": ["steam", "wine", "lutris", "vinegar", "gaming"],
            "Network Tools": [
                "curl",
                "wget",
                "ssh",
                "rsync",
                "netcat",
                "nmap",
                "wireshark",
            ],
        }

    def build_target(self) -> bool:
        """Build the Nix target"""
        print(f"🔨 Building target: {self.target}")
        try:
            subprocess.run(
                ["nix", "build", self.target],
                capture_output=True,
                text=True,
                check=True,
            )
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Build failed: {e.stderr}")
            return False

    def get_closure_info(
        self, quiet: bool = False
    ) -> Tuple[List[Tuple[str, int, int]], int]:
        """Get closure paths with both dependency-inclusive and actual disk usage sizes"""
        if not quiet:
            print("📊 Analyzing closure...")
        try:
            # Get dependency-inclusive sizes (for dependency analysis)
            size_result = subprocess.run(
                ["nix", "path-info", "-S", "-r", "./result"],
                capture_output=True,
                text=True,
                check=True,
            )

            # Parse dependency-inclusive sizes
            dep_inclusive_sizes = {}
            for line in size_result.stdout.strip().split("\n"):
                if line.strip():
                    parts = line.strip().split()
                    if len(parts) >= 2:
                        path = parts[0]
                        size = int(parts[1])
                        dep_inclusive_sizes[path] = size

            # Get actual disk usage for each package
            paths_result = subprocess.run(
                ["nix", "path-info", "-r", "./result"],
                capture_output=True,
                text=True,
                check=True,
            )

            all_paths = paths_result.stdout.strip().split("\n")
            if not all_paths or not all_paths[0]:
                return [], 0

            # Get actual disk usage for all paths at once (much faster)
            du_result = subprocess.run(
                ["du", "-s"] + all_paths,
                capture_output=True,
                text=True,
            )

            closure_info = []
            actual_sizes = {}

            if du_result.returncode == 0:
                # Parse du output
                for line in du_result.stdout.strip().split("\n"):
                    if line.strip():
                        parts = line.strip().split(None, 1)
                        if len(parts) >= 2:
                            size_kb = int(parts[0])
                            path = parts[1]
                            actual_size = size_kb * 1024
                            actual_sizes[path] = actual_size

                            # Get dependency-inclusive size
                            dep_inclusive_size = dep_inclusive_sizes.get(
                                path, actual_size
                            )
                            closure_info.append((path, dep_inclusive_size, actual_size))

            # Calculate total closure size
            total_actual_size = sum(actual_sizes.values())

            return closure_info, total_actual_size

        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to get closure info: {e.stderr}")
            return [], 0

    def extract_package_name(self, path: str) -> str:
        """Extract clean package name from Nix store path"""
        # Remove /nix/store/hash- prefix
        name = Path(path).name
        # Remove hash prefix (32 hex chars + dash)
        if "-" in name:
            parts = name.split("-", 1)
            if len(parts[0]) == 32 and all(c in "0123456789abcdef" for c in parts[0]):
                name = parts[1]
        return name

    def categorize_package(self, name: str) -> str:
        """Categorize package by name"""
        name_lower = name.lower()
        for category, keywords in self.categories.items():
            for keyword in keywords:
                if keyword.lower() in name_lower:
                    return category
        return "Other"

    def analyze_closure(self, quiet: bool = False) -> AnalysisResult:
        """Perform full closure analysis"""
        closure_info, actual_total_size = self.get_closure_info(quiet)
        if not closure_info:
            return AnalysisResult(0, 0.0, [], [], {})

        packages = []
        sum_dep_inclusive_sizes = 0

        for path, dep_inclusive_size, actual_size in closure_info:
            name = self.extract_package_name(path)
            dep_inclusive_gb = dep_inclusive_size / (1024 * 1024 * 1024)
            actual_gb = actual_size / (1024 * 1024 * 1024)
            packages.append(
                Package(
                    path,
                    name,
                    dep_inclusive_size,
                    actual_size,
                    dep_inclusive_gb,
                    actual_gb,
                )
            )
            sum_dep_inclusive_sizes += dep_inclusive_size

        # Sort by dependency-inclusive size descending for dependency analysis
        packages.sort(key=lambda p: p.dep_inclusive_size, reverse=True)

        # Find large packages (using dependency-inclusive sizes)
        large_packages = [
            p for p in packages if p.dep_inclusive_size >= self.size_threshold
        ]

        # Categorize packages using actual sizes for meaningful percentages
        categories = {}
        for package in packages:
            category = self.categorize_package(package.name)
            if category not in categories:
                categories[category] = []
            categories[category].append(package)

        total_size_gb = actual_total_size / (1024 * 1024 * 1024)

        if not quiet and actual_total_size > 0:
            sum_gb = sum_dep_inclusive_sizes / (1024 * 1024 * 1024)
            print(
                f"📈 Dependency-inclusive sizes sum to {sum_gb:.2f}GB, actual closure size: {total_size_gb:.2f}GB"
            )
            print(f"💡 Space saved through sharing: {sum_gb - total_size_gb:.2f}GB")

        return AnalysisResult(
            total_size=actual_total_size,
            total_size_gb=total_size_gb,
            packages=packages,
            large_packages=large_packages,
            categories=categories,
        )

    def find_dependencies(self, package_path: str, max_depth: int = 3) -> List[str]:
        """Find what depends on a specific package"""
        try:
            result = subprocess.run(
                ["nix", "why-depends", "./result", package_path],
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout.strip().split("\n")[: max_depth + 1]
        except subprocess.CalledProcessError:
            return []

    def generate_report(self, analysis: AnalysisResult) -> str:
        """Generate comprehensive analysis report"""
        report = []

        # Header
        report.append("=" * 80)
        report.append("🔍 NIX CLOSURE SIZE ANALYSIS REPORT")
        report.append("=" * 80)
        report.append(f"Target: {self.target}")
        report.append(
            f"Total Closure Size: {analysis.total_size_gb:.2f} GB ({analysis.total_size:,} bytes)"
        )
        report.append(f"Total Packages: {len(analysis.packages)}")
        report.append(
            f"Large Packages (>{self.size_threshold_gb}GB): {len(analysis.large_packages)}"
        )
        report.append("")

        # Show packages with disproportionately heavy dependency trees
        heavy_dep_packages = []
        for pkg in analysis.packages:
            # Only consider packages with meaningful actual size (> 10MB)
            if pkg.actual_gb > 0.01 and pkg.dep_inclusive_gb > 0.1:
                ratio = pkg.dep_inclusive_gb / pkg.actual_gb
                # Only include if dependency overhead is significant (>3x) and total deps > 200MB
                if ratio > 3.0 and pkg.dep_inclusive_gb > 0.2:
                    heavy_dep_packages.append((pkg, ratio))

        if heavy_dep_packages:
            # Sort by dependency ratio (heaviest dependency burden first)
            heavy_dep_packages.sort(key=lambda x: x[1], reverse=True)

            report.append("🎯 PACKAGES WITH HEAVIEST DEPENDENCY BURDEN")
            report.append("-" * 80)
            report.append(
                "These packages bring in disproportionately large dependencies:"
            )
            report.append("")

            for i, (pkg, ratio) in enumerate(heavy_dep_packages[:15], 1):
                savings = pkg.dep_inclusive_gb - pkg.actual_gb
                report.append(f"{i:2d}. {pkg.name:<50}")
                report.append(
                    f"    Actual: {pkg.actual_gb:>5.2f}GB → With deps: {pkg.dep_inclusive_gb:>5.2f}GB ({ratio:>4.1f}x overhead, {savings:>5.2f}GB from deps)"
                )

                # Show what this package depends on that's heavy
                if pkg.dep_inclusive_gb > 1.0:
                    deps = self.find_dependencies(pkg.path, max_depth=3)
                    if len(deps) > 1:
                        report.append(
                            f"    └─ Heavy deps likely from: {' → '.join(deps[1:4])}"
                        )
                report.append("")
        else:
            report.append("🎯 DEPENDENCY ANALYSIS")
            report.append("-" * 80)
            report.append("No packages found with unusually heavy dependency burdens.")
            report.append("")

        # Top 20 packages by actual disk usage
        packages_by_actual = sorted(
            analysis.packages, key=lambda p: p.actual_size, reverse=True
        )
        report.append("📊 TOP 20 PACKAGES BY ACTUAL DISK USAGE")
        report.append("-" * 80)
        for i, pkg in enumerate(packages_by_actual[:20], 1):
            percentage = (pkg.actual_size / analysis.total_size) * 100
            report.append(
                f"{i:2d}. {pkg.name:<50} {pkg.actual_gb:>6.2f} GB ({percentage:4.1f}%)"
            )
        report.append("")

        # Category breakdown by actual disk usage
        report.append("📂 PACKAGE CATEGORIES (Actual Disk Usage)")
        report.append("-" * 80)
        category_totals = []
        for category, packages in analysis.categories.items():
            total_actual_size = sum(p.actual_size for p in packages)
            total_gb = total_actual_size / (1024 * 1024 * 1024)
            percentage = (total_actual_size / analysis.total_size) * 100
            category_totals.append((category, total_gb, percentage, len(packages)))

        category_totals.sort(key=lambda x: x[1], reverse=True)
        for category, size_gb, percentage, count in category_totals:
            if size_gb > 0.05:  # Only show categories > 50MB
                report.append(
                    f"{category:<20} {size_gb:>6.2f} GB ({percentage:4.1f}%) - {count} packages"
                )

        # Show packages that bring in the heaviest dependency trees
        report.append("")
        report.append("🔍 PACKAGES WITH HEAVIEST DEPENDENCY TREES")
        report.append("-" * 80)
        heavy_dep_packages = [
            p
            for p in analysis.packages
            if p.dep_inclusive_gb > 1.0 and p.actual_gb > 0.01
        ]
        heavy_dep_packages.sort(key=lambda p: p.dep_inclusive_gb, reverse=True)

        if heavy_dep_packages:
            report.append(
                "These packages bring in large dependency trees (may indicate heavy features):"
            )
            report.append("")
            for pkg in heavy_dep_packages[:15]:
                ratio = pkg.dep_inclusive_gb / max(pkg.actual_gb, 0.001)
                report.append(
                    f"{pkg.name:<50} {pkg.actual_gb:>5.2f}GB → {pkg.dep_inclusive_gb:>6.2f}GB ({ratio:>4.0f}x deps)"
                )
        else:
            report.append("No packages with unusually heavy dependency trees found.")
        report.append("")

        # Optimization suggestions
        report.append("💡 OPTIMIZATION SUGGESTIONS")
        report.append("-" * 50)
        suggestions = self.generate_suggestions(analysis)
        for suggestion in suggestions:
            report.append(f"• {suggestion}")
        report.append("")

        # WSL-specific suggestions
        if "wsl" in self.target.lower() or "WSL" in self.target:
            report.append("🖥️  WSL-SPECIFIC OPTIMIZATIONS")
            report.append("-" * 50)
            wsl_suggestions = self.generate_wsl_suggestions(analysis)
            for suggestion in wsl_suggestions:
                report.append(f"• {suggestion}")
            report.append("")

        return "\n".join(report)

    def generate_suggestions(self, analysis: AnalysisResult) -> List[str]:
        """Generate dynamic optimization suggestions based on actual analysis"""
        suggestions = []

        # Get packages sorted by actual size
        packages_by_actual = sorted(
            analysis.packages, key=lambda p: p.actual_size, reverse=True
        )

        # Analyze categories for suggestions
        category_sizes = {}
        for category, packages in analysis.categories.items():
            total_size = sum(p.actual_size for p in packages)
            if total_size > 0:
                category_sizes[category] = (total_size / (1024**3), packages)

        # Sort categories by size
        sorted_categories = sorted(
            category_sizes.items(), key=lambda x: x[1][0], reverse=True
        )

        # Generate suggestions based on largest categories
        for category, (size_gb, packages) in sorted_categories[:5]:
            if size_gb < 0.2:  # Skip categories smaller than 200MB
                continue

            if category == "Runtimes & SDKs" and size_gb > 2.0:
                # Look for multiple versions of same runtime
                java_versions = [p for p in packages if "openjdk" in p.name.lower()]
                dotnet_versions = [p for p in packages if "dotnet" in p.name.lower()]
                node_versions = [p for p in packages if "nodejs" in p.name.lower()]

                if len(java_versions) > 1:
                    java_size = sum(p.actual_gb for p in java_versions)
                    suggestions.append(
                        f"Multiple Java versions detected ({java_size:.1f}GB): Consider consolidating to one JDK version"
                    )

                if len(dotnet_versions) > 1:
                    dotnet_size = sum(p.actual_gb for p in dotnet_versions)
                    suggestions.append(
                        f"Multiple .NET versions detected ({dotnet_size:.1f}GB): Consider using only the latest version"
                    )

                if len(node_versions) > 1:
                    node_size = sum(p.actual_gb for p in node_versions)
                    suggestions.append(
                        f"Multiple Node.js versions detected ({node_size:.1f}GB): Consider consolidating versions"
                    )

            elif category == "Language Servers" and size_gb > 0.5:
                # Check for redundant language servers
                by_language = {}
                for pkg in packages:
                    name_lower = pkg.name.lower()
                    if "typescript" in name_lower or "js" in name_lower:
                        by_language.setdefault("JavaScript/TypeScript", []).append(pkg)
                    elif "python" in name_lower or "pyright" in name_lower:
                        by_language.setdefault("Python", []).append(pkg)
                    elif "java" in name_lower or "jdt" in name_lower:
                        by_language.setdefault("Java", []).append(pkg)

                for lang, lang_servers in by_language.items():
                    if len(lang_servers) > 1:
                        lang_size = sum(p.actual_gb for p in lang_servers)
                        suggestions.append(
                            f"Multiple {lang} language servers ({lang_size:.1f}GB): Consider using just one"
                        )

            elif category == "AI & Automation Tools" and size_gb > 0.3:
                ai_tools = sorted(packages, key=lambda p: p.actual_size, reverse=True)[
                    :3
                ]
                ai_size = sum(p.actual_gb for p in ai_tools)
                tool_names = [p.name.split("-")[0] for p in ai_tools]
                suggestions.append(
                    f"Multiple AI tools detected ({ai_size:.1f}GB): Review if all are needed ({', '.join(tool_names)})"
                )

            elif category == "Fonts" and size_gb > 0.3:
                suggestions.append(
                    f"Large font collection ({size_gb:.1f}GB): Consider reducing to essential fonts only"
                )

            elif category == "System Libraries" and size_gb > 0.3:
                # Look for GUI libraries that might not be needed
                gui_libs = [
                    p
                    for p in packages
                    if any(x in p.name.lower() for x in ["qt", "gtk", "desktop"])
                ]
                if gui_libs:
                    gui_size = sum(p.actual_gb for p in gui_libs)
                    if gui_size > 0.2:
                        suggestions.append(
                            f"GUI libraries detected ({gui_size:.1f}GB): Consider if desktop environment is needed"
                        )

        # Look for packages with heavy dependency burdens (from earlier analysis)
        heavy_burden_packages = []
        for pkg in packages_by_actual[:20]:
            if (
                pkg.actual_gb > 0.01 and pkg.dep_inclusive_gb > pkg.actual_gb * 10
            ):  # 10x overhead
                heavy_burden_packages.append(pkg)

        if heavy_burden_packages:
            top_burden = heavy_burden_packages[0]
            overhead_gb = top_burden.dep_inclusive_gb - top_burden.actual_gb
            suggestions.append(
                f"'{top_burden.name}' brings {overhead_gb:.1f}GB of dependencies for {top_burden.actual_gb:.2f}GB package - consider alternatives"
            )

        # If no specific suggestions, give general guidance
        if not suggestions:
            if analysis.total_size_gb > 15:
                suggestions.append(
                    "System size is quite large - consider reviewing installed packages and removing unused tools"
                )
            elif analysis.total_size_gb < 5:
                suggestions.append("System size is well optimized!")
            else:
                suggestions.append(
                    "System size is reasonable - focus on removing unused development tools if needed"
                )

        return suggestions

    def generate_wsl_suggestions(self, analysis: AnalysisResult) -> List[str]:
        """Generate WSL-specific optimization suggestions"""
        suggestions = []

        # Common WSL optimization targets
        wsl_excludes = {
            "font-manager": "GUI font management not needed in WSL",
            "qtcreator": "IDE not typically used in WSL",
            "postman": "Use VS Code REST client instead",
            "bruno": "API client not needed in WSL",
            "vinegar": "Gaming platform not needed in WSL",
            "firefox": "Browser not needed in WSL",
            "mesa": "GPU drivers less critical in WSL",
        }

        packages_by_actual = sorted(
            analysis.packages, key=lambda p: p.actual_size, reverse=True
        )
        for exclude_name, reason in wsl_excludes.items():
            matching_packages = [
                p
                for p in packages_by_actual
                if exclude_name.lower() in p.name.lower() and p.actual_gb > 0.1
            ]
            if matching_packages:
                total_size = sum(p.actual_gb for p in matching_packages)
                suggestions.append(
                    f"Exclude {exclude_name} ({total_size:.1f}GB): {reason}"
                )

        # Language-specific suggestions
        rust_packages = [p for p in packages_by_actual if "rust" in p.name.lower()]
        if rust_packages:
            total_rust_size = sum(p.actual_gb for p in rust_packages)
            if total_rust_size > 0.5:
                suggestions.append(
                    f"Consider disabling Rust toolchain ({total_rust_size:.1f}GB) if not developing in Rust"
                )

        return suggestions


def main():
    parser = argparse.ArgumentParser(
        description="Analyze Nix closure size and dependencies"
    )
    parser.add_argument(
        "target",
        help="Nix flake target to analyze (e.g., .#nixosConfigurations.myhost.config.system.build.toplevel)",
    )
    parser.add_argument(
        "--threshold",
        "-t",
        type=float,
        default=1.0,
        help='Size threshold in GB for "large" packages (default: 1.0)',
    )
    parser.add_argument(
        "--output", "-o", type=str, help="Output report to file instead of stdout"
    )
    parser.add_argument(
        "--no-build",
        action="store_true",
        help="Skip building, analyze existing ./result",
    )
    parser.add_argument(
        "--json", action="store_true", help="Output raw analysis data as JSON"
    )

    args = parser.parse_args()

    analyzer = ClosureAnalyzer(args.target, args.threshold)

    # Build target unless --no-build
    if not args.no_build:
        if not analyzer.build_target():
            sys.exit(1)

    # Perform analysis
    analysis = analyzer.analyze_closure(quiet=args.json)

    if not analysis.packages:
        print("❌ No packages found in closure")
        sys.exit(1)

    # Output results
    if args.json:
        # JSON output for programmatic use
        output = {
            "target": args.target,
            "total_size_gb": analysis.total_size_gb,
            "package_count": len(analysis.packages),
            "large_packages": [
                {"name": p.name, "size_gb": p.size_gb} for p in analysis.large_packages
            ],
        }
        json_str = json.dumps(output, indent=2)

        if args.output:
            Path(args.output).write_text(json_str)
        else:
            print(json_str)
    else:
        # Human-readable report
        report = analyzer.generate_report(analysis)

        if args.output:
            Path(args.output).write_text(report)
            print(f"📄 Report saved to: {args.output}")
        else:
            print(report)


if __name__ == "__main__":
    main()
