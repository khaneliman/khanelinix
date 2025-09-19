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
    size: int
    size_gb: float


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
            "Development Tools": [
                "clang",
                "rust",
                "cargo",
                "gcc",
                "llvm",
                "go-",
                "nodejs",
            ],
            "Language Servers": [
                "language-server",
                "-ls",
                "lsp-",
                "rust-analyzer",
                "typescript-language-server",
            ],
            "Editors": ["vim", "neovim", "vscode", "emacs", "helix"],
            "GUI Applications": [
                "qtcreator",
                "bruno",
                "postman",
                "firefox",
                "chromium",
            ],
            "Formatters/Linters": [
                "prettier",
                "eslint",
                "black",
                "rustfmt",
                "clang-format",
                "clippy",
            ],
            "System Libraries": ["glibc", "systemd", "mesa", "qt-", "gtk"],
            "Fonts": ["font-", "-font", "fonts-", "fontconfig"],
            "Media/Graphics": ["ffmpeg", "imagemagick", "mesa", "vulkan", "graphics"],
            "Container/VM": ["docker", "podman", "qemu", "virtualbox"],
            "Gaming": ["steam", "wine", "lutris", "vinegar", "gaming"],
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

    def get_closure_info(self, quiet: bool = False) -> List[Tuple[str, int]]:
        """Get closure paths and sizes"""
        if not quiet:
            print("📊 Analyzing closure...")
        try:
            # Get closure paths with sizes
            result = subprocess.run(
                ["nix", "path-info", "-S", "-r", "./result"],
                capture_output=True,
                text=True,
                check=True,
            )

            closure_info = []
            for line in result.stdout.strip().split("\n"):
                if line.strip():
                    parts = line.strip().split()
                    if len(parts) >= 2:
                        path = parts[0]
                        size = int(parts[1])
                        closure_info.append((path, size))

            return closure_info
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to get closure info: {e.stderr}")
            return []

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
        closure_info = self.get_closure_info(quiet)
        if not closure_info:
            return AnalysisResult(0, 0.0, [], [], {})

        packages = []
        total_size = 0

        for path, size in closure_info:
            name = self.extract_package_name(path)
            size_gb = size / (1024 * 1024 * 1024)
            packages.append(Package(path, name, size, size_gb))
            total_size += size

        # Sort by size descending
        packages.sort(key=lambda p: p.size, reverse=True)

        # Find large packages
        large_packages = [p for p in packages if p.size >= self.size_threshold]

        # Categorize packages
        categories = {}
        for package in packages:
            category = self.categorize_package(package.name)
            if category not in categories:
                categories[category] = []
            categories[category].append(package)

        total_size_gb = total_size / (1024 * 1024 * 1024)

        return AnalysisResult(
            total_size=total_size,
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

        # Large packages section
        if analysis.large_packages:
            report.append("🎯 LARGE PACKAGES (Optimization Targets)")
            report.append("-" * 50)
            for i, pkg in enumerate(analysis.large_packages[:20], 1):
                report.append(f"{i:2d}. {pkg.name:<40} {pkg.size_gb:>6.2f} GB")

                # Show dependency chain for very large packages
                if pkg.size_gb > 2.0:
                    deps = self.find_dependencies(pkg.path, max_depth=2)
                    if len(deps) > 1:
                        report.append(f"    └─ Via: {' → '.join(deps[1:])}")
            report.append("")

        # Top 20 packages
        report.append("📊 TOP 20 LARGEST PACKAGES")
        report.append("-" * 50)
        for i, pkg in enumerate(analysis.packages[:20], 1):
            percentage = (pkg.size / analysis.total_size) * 100
            report.append(
                f"{i:2d}. {pkg.name:<40} {pkg.size_gb:>6.2f} GB ({percentage:4.1f}%)"
            )
        report.append("")

        # Category breakdown
        report.append("📂 PACKAGE CATEGORIES")
        report.append("-" * 50)
        category_totals = []
        for category, packages in analysis.categories.items():
            total_size = sum(p.size for p in packages)
            total_gb = total_size / (1024 * 1024 * 1024)
            percentage = (total_size / analysis.total_size) * 100
            category_totals.append((category, total_gb, percentage, len(packages)))

        category_totals.sort(key=lambda x: x[1], reverse=True)
        for category, size_gb, percentage, count in category_totals:
            if size_gb > 0.1:  # Only show categories > 100MB
                report.append(
                    f"{category:<20} {size_gb:>6.2f} GB ({percentage:4.1f}%) - {count} packages"
                )
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
        """Generate optimization suggestions based on analysis"""
        suggestions = []

        # Look for common optimization targets
        gui_packages = [
            p
            for p in analysis.large_packages
            if any(
                keyword in p.name.lower()
                for keyword in ["qt", "gtk", "gui", "desktop", "browser", "editor"]
            )
        ]

        if gui_packages:
            suggestions.append(
                f"Consider excluding GUI applications: {', '.join([p.name for p in gui_packages[:3]])}"
            )

        dev_tools = [
            p
            for p in analysis.large_packages
            if any(
                keyword in p.name.lower()
                for keyword in ["clang", "rust", "gcc", "llvm", "compiler"]
            )
        ]

        if dev_tools:
            suggestions.append(
                f"Evaluate development toolchains: {', '.join([p.name for p in dev_tools[:3]])}"
            )

        # Look for duplicate or similar packages
        similar_packages = {}
        for pkg in analysis.packages[:50]:  # Only check top 50
            base_name = pkg.name.split("-")[0]
            if base_name not in similar_packages:
                similar_packages[base_name] = []
            similar_packages[base_name].append(pkg)

        for base_name, packages in similar_packages.items():
            if len(packages) > 2:
                total_size = sum(p.size_gb for p in packages)
                if total_size > 1.0:
                    suggestions.append(
                        f"Multiple {base_name} packages detected ({len(packages)} packages, {total_size:.1f}GB total)"
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

        for exclude_name, reason in wsl_excludes.items():
            matching_packages = [
                p
                for p in analysis.large_packages
                if exclude_name.lower() in p.name.lower()
            ]
            if matching_packages:
                total_size = sum(p.size_gb for p in matching_packages)
                suggestions.append(
                    f"Exclude {exclude_name} ({total_size:.1f}GB): {reason}"
                )

        # Language-specific suggestions
        rust_packages = [p for p in analysis.packages if "rust" in p.name.lower()]
        if rust_packages:
            total_rust_size = sum(p.size_gb for p in rust_packages)
            if total_rust_size > 2.0:
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
