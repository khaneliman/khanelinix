#!/usr/bin/env python3
"""
Closure Size Analyzer for Nix Configurations
Analyzes closure size, identifies large dependencies, and provides optimization insights
"""

import argparse
import json
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple


def format_bytes(bytes_size: int) -> str:
    """Format bytes in human readable format"""
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if bytes_size < 1024.0:
            return f"{bytes_size:.1f} {unit}"
        bytes_size /= 1024.0
    return f"{bytes_size:.1f} PB"


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
    def __init__(
        self,
        target: str,
        size_threshold_gb: float = 1.0,
        cache_dir: Optional[Path] = None,
    ):
        self.target = target
        self.size_threshold_gb = size_threshold_gb
        self.size_threshold = int(size_threshold_gb * 1024 * 1024 * 1024)
        self.cache_dir = cache_dir or Path.home() / ".cache" / "closure-analyzer"
        self.result_path = None  # Will be set after successful build

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
            "Cloud Tools": [
                "kubectl",
                "docker",
                "terraform",
                "aws-cli",
                "azure-cli",
                "gcloud",
                "helm",
            ],
            "Build Tools": [
                "make",
                "ninja",
                "meson",
                "autotools",
                "pkg-config",
                "pkgconf",
            ],
        }

    def build_target(self) -> bool:
        """Build the Nix target"""
        print(f"🔨 Building target: {self.target}")
        try:
            # Check if target contains proper flake reference
            if not (self.target.startswith(".#") or self.target.startswith("/")):
                print("⚠️  Warning: Target should start with '.#' for flake references")

            result = subprocess.run(
                ["nix", "build", self.target, "--no-link", "--print-out-paths"],
                capture_output=True,
                text=True,
                check=True,
                timeout=600,  # 10 minute timeout
            )

            # Store the actual output path
            output_path = result.stdout.strip()
            if output_path and Path(output_path).exists():
                # Store the real path for use in analysis
                self.result_path = output_path
                # Create a result symlink for consistency with --no-build usage
                result_link = Path("./result")
                if result_link.exists() or result_link.is_symlink():
                    result_link.unlink()
                result_link.symlink_to(output_path)
                return True
            else:
                print(f"❌ Build output path not found: {output_path}")
                return False

        except subprocess.TimeoutExpired:
            print("❌ Build timed out after 10 minutes")
            return False
        except subprocess.CalledProcessError as e:
            print(f"❌ Build failed: {e.stderr}")
            if "does not exist" in e.stderr:
                print("💡 Hint: Check that the flake target path is correct")
            return False
        except FileNotFoundError:
            print(
                "❌ 'nix' command not found. Please ensure Nix is installed and in PATH"
            )
            return False

    def get_closure_info(
        self, quiet: bool = False
    ) -> Tuple[List[Tuple[str, int, int]], int]:
        """Get closure paths with both dependency-inclusive and actual disk usage sizes"""
        if not quiet:
            print("📊 Analyzing closure...")

        # Determine which path to use for analysis
        if self.result_path:
            # Use the stored result path from build
            analysis_path = self.result_path
        else:
            # Check if result symlink exists (for --no-build mode)
            result_path = Path("./result")
            if not result_path.exists():
                raise FileNotFoundError(
                    "./result not found. Run without --no-build or ensure build succeeded."
                )
            analysis_path = str(result_path)

        try:
            # Get dependency-inclusive sizes (for dependency analysis)
            size_result = subprocess.run(
                ["nix", "path-info", "-S", "-r", analysis_path],
                capture_output=True,
                text=True,
                check=True,
                timeout=120,
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
                ["nix", "path-info", "-r", analysis_path],
                capture_output=True,
                text=True,
                check=True,
                timeout=60,
            )

            all_paths = paths_result.stdout.strip().split("\n")
            if not all_paths or not all_paths[0]:
                return [], 0

            # Get actual disk usage for all paths at once (much faster)
            # Process in batches to avoid command line length limits
            closure_info = []
            actual_sizes = {}
            batch_size = 1000  # Avoid ARG_MAX limits

            for i in range(0, len(all_paths), batch_size):
                batch_paths = all_paths[i : i + batch_size]
                if not batch_paths or not batch_paths[0]:  # Skip empty batches
                    continue

                du_result = subprocess.run(
                    ["du", "-s"] + batch_paths,
                    capture_output=True,
                    text=True,
                    timeout=300,  # 5 minute timeout for du
                )

                if du_result.returncode == 0:
                    # Parse du output for this batch
                    for line in du_result.stdout.strip().split("\n"):
                        if line.strip():
                            parts = line.strip().split(None, 1)
                            if len(parts) >= 2:
                                try:
                                    size_kb = int(parts[0])
                                    path = parts[1]
                                    actual_size = size_kb * 1024
                                    actual_sizes[path] = actual_size

                                    # Get dependency-inclusive size
                                    dep_inclusive_size = dep_inclusive_sizes.get(
                                        path, actual_size
                                    )
                                    closure_info.append(
                                        (path, dep_inclusive_size, actual_size)
                                    )
                                except (ValueError, IndexError) as e:
                                    if not quiet:
                                        print(
                                            f"⚠️  Warning: Could not parse du line: {line} ({e})"
                                        )
                else:
                    if not quiet:
                        print(
                            f"⚠️  Warning: du failed for batch {i // batch_size + 1}, skipping {len(batch_paths)} paths"
                        )

            # Calculate total closure size
            total_actual_size = sum(actual_sizes.values())

            return closure_info, total_actual_size

        except subprocess.TimeoutExpired:
            print(
                "❌ Timeout while analyzing closure - this may indicate a very large closure"
            )
            return [], 0
        except subprocess.CalledProcessError as e:
            error_msg = e.stderr or "Unknown error"
            print(f"❌ Failed to get closure info: {error_msg}")
            if "does not exist" in error_msg:
                print("💡 Hint: Ensure ./result exists or run without --no-build")
            return [], 0
        except FileNotFoundError as e:
            print(f"❌ Required tool not found: {e}")
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
            # Use the stored result path if available, otherwise fall back to ./result
            analysis_path = self.result_path if self.result_path else "./result"
            result = subprocess.run(
                ["nix", "why-depends", analysis_path, package_path],
                capture_output=True,
                text=True,
                check=True,
                timeout=30,
            )
            lines = result.stdout.strip().split("\n")
            return [line for line in lines[: max_depth + 1] if line.strip()]
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            return []
        except FileNotFoundError:
            # Fall back if nix why-depends not available
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

        # Comparison with previous run (if available)
        comparison = self.compare_with_previous(analysis)
        if comparison:
            report.append(comparison)

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

    def save_analysis_cache(self, analysis: AnalysisResult) -> None:
        """Save analysis results to cache for comparison"""
        try:
            self.cache_dir.mkdir(parents=True, exist_ok=True)

            # Create a hash from target for filename
            import hashlib

            target_hash = hashlib.md5(self.target.encode()).hexdigest()
            cache_file = self.cache_dir / f"{target_hash}.json"

            cache_data = {
                "target": self.target,
                "timestamp": time.time(),
                "total_size_gb": analysis.total_size_gb,
                "total_size": analysis.total_size,
                "package_count": len(analysis.packages),
                "packages": [
                    {
                        "name": p.name,
                        "path": p.path,
                        "actual_gb": p.actual_gb,
                        "dep_inclusive_gb": p.dep_inclusive_gb,
                    }
                    for p in analysis.packages[:100]  # Limit cache size
                ],
            }

            with open(cache_file, "w") as f:
                json.dump(cache_data, f, indent=2)

        except Exception as e:
            # Don't fail the whole analysis if caching fails
            print(f"⚠️  Warning: Could not save cache: {e}")

    def load_analysis_cache(self) -> Optional[dict]:
        """Load previous analysis from cache"""
        try:
            import hashlib

            target_hash = hashlib.md5(self.target.encode()).hexdigest()
            cache_file = self.cache_dir / f"{target_hash}.json"

            if cache_file.exists():
                with open(cache_file) as f:
                    return json.load(f)
        except Exception:
            pass
        return None

    def compare_with_previous(self, current_analysis: AnalysisResult) -> Optional[str]:
        """Compare current analysis with cached previous run"""
        previous = self.load_analysis_cache()
        if not previous:
            return None

        size_diff = current_analysis.total_size_gb - previous["total_size_gb"]
        count_diff = len(current_analysis.packages) - previous["package_count"]

        comparison = []
        comparison.append("📊 COMPARISON WITH PREVIOUS ANALYSIS")
        comparison.append("-" * 50)
        comparison.append(f"Previous size: {previous['total_size_gb']:.2f} GB")
        comparison.append(f"Current size:  {current_analysis.total_size_gb:.2f} GB")

        if abs(size_diff) > 0.01:  # Only show if meaningful difference
            direction = "📈 increased" if size_diff > 0 else "📉 decreased"
            comparison.append(
                f"Change: {direction} by {abs(size_diff):.2f} GB ({abs(size_diff) / previous['total_size_gb'] * 100:.1f}%)"
            )
        else:
            comparison.append("Change: No significant change")

        comparison.append(
            f"Package count: {previous['package_count']} → {len(current_analysis.packages)} ({count_diff:+d})"
        )
        comparison.append("")

        return "\n".join(comparison)

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
    parser.add_argument(
        "--no-cache", action="store_true", help="Disable caching of results"
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Show verbose output during analysis",
    )
    parser.add_argument(
        "--compare-only",
        action="store_true",
        help="Only show comparison with previous run (requires cache)",
    )

    args = parser.parse_args()

    # Set up cache directory if not disabled
    cache_dir = None if args.no_cache else None  # Use default
    analyzer = ClosureAnalyzer(args.target, args.threshold, cache_dir)

    # Build target unless --no-build
    if not args.no_build:
        if not analyzer.build_target():
            sys.exit(1)

    # Handle compare-only mode
    if args.compare_only:
        previous = analyzer.load_analysis_cache()
        if not previous:
            print("❌ No previous analysis found in cache")
            sys.exit(1)
        print("📊 Previous Analysis Summary")
        print(f"Target: {previous['target']}")
        print(f"Size: {previous['total_size_gb']:.2f} GB")
        print(f"Packages: {previous['package_count']}")
        print(f"Analyzed: {time.ctime(previous['timestamp'])}")
        sys.exit(0)

    # Perform analysis
    analysis = analyzer.analyze_closure(quiet=(args.json and not args.verbose))

    if not analysis.packages:
        print("❌ No packages found in closure")
        sys.exit(1)

    # Save to cache (unless disabled)
    if not args.no_cache:
        analyzer.save_analysis_cache(analysis)

    # Output results
    if args.json:
        # Enhanced JSON output for programmatic use
        output = {
            "target": args.target,
            "analysis_timestamp": time.time(),
            "total_size_gb": analysis.total_size_gb,
            "total_size_bytes": analysis.total_size,
            "package_count": len(analysis.packages),
            "large_packages_count": len(analysis.large_packages),
            "size_threshold_gb": args.threshold,
            "large_packages": [
                {
                    "name": p.name,
                    "path": p.path,
                    "dep_inclusive_gb": p.dep_inclusive_gb,
                    "actual_gb": p.actual_gb,
                    "dep_overhead_ratio": p.dep_inclusive_gb / max(p.actual_gb, 0.001),
                }
                for p in analysis.large_packages
            ],
            "top_10_by_size": [
                {
                    "name": p.name,
                    "actual_gb": p.actual_gb,
                    "percentage": (p.actual_size / analysis.total_size) * 100,
                }
                for p in sorted(
                    analysis.packages, key=lambda x: x.actual_size, reverse=True
                )[:10]
            ],
            "categories": {
                category: {
                    "size_gb": sum(p.actual_size for p in packages) / (1024**3),
                    "package_count": len(packages),
                    "percentage": (
                        sum(p.actual_size for p in packages) / analysis.total_size
                    )
                    * 100,
                }
                for category, packages in analysis.categories.items()
                if sum(p.actual_size for p in packages) > 0
            },
        }

        # Add comparison if available
        if not args.no_cache:
            previous = analyzer.load_analysis_cache()
            if previous:
                output["comparison"] = {
                    "previous_size_gb": previous["total_size_gb"],
                    "size_change_gb": analysis.total_size_gb
                    - previous["total_size_gb"],
                    "size_change_percent": (
                        (analysis.total_size_gb - previous["total_size_gb"])
                        / previous["total_size_gb"]
                    )
                    * 100,
                    "package_count_change": len(analysis.packages)
                    - previous["package_count"],
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
