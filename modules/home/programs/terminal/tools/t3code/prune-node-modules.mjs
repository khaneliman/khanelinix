import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const workspaceRoot = path.resolve(process.argv[2] ?? ".");
const rootNodeModules = path.join(workspaceRoot, "node_modules");
const virtualStore = path.join(rootNodeModules, ".pnpm");
const runtimePackages = ["apps/server", "apps/desktop"];
const selectedEntries = new Set();
const pendingEntries = [];
const currentLibc =
	process.platform === "linux"
		? process.report.getReport().header.glibcVersionRuntime
			? "glibc"
			: "musl"
		: null;

function supportsPlatform(values, currentValue) {
	if (!Array.isArray(values)) return true;
	if (values.includes(`!${currentValue}`)) return false;

	const allowedValues = values.filter((value) => !value.startsWith("!"));
	return allowedValues.length === 0 || allowedValues.includes(currentValue);
}

function packageSupportsCurrentPlatform(packagePath) {
	const manifestPath = path.join(packagePath, "package.json");
	if (!fs.existsSync(manifestPath)) return true;

	const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
	return (
		supportsPlatform(manifest.os, process.platform) &&
		supportsPlatform(manifest.cpu, process.arch) &&
		(currentLibc === null || supportsPlatform(manifest.libc, currentLibc))
	);
}

function resolveSymlink(linkPath) {
	let targetPath = path.resolve(
		path.dirname(linkPath),
		fs.readlinkSync(linkPath),
	);

	for (let depth = 0; depth < 16; depth += 1) {
		let stat;
		try {
			stat = fs.lstatSync(targetPath);
		} catch {
			return targetPath;
		}

		if (!stat.isSymbolicLink()) return targetPath;
		targetPath = path.resolve(
			path.dirname(targetPath),
			fs.readlinkSync(targetPath),
		);
	}

	throw new Error(`Symlink chain is too deep: ${linkPath}`);
}

function selectVirtualStoreTarget(targetPath) {
	const relativePath = path.relative(virtualStore, targetPath);
	if (relativePath.startsWith(`..${path.sep}`) || path.isAbsolute(relativePath))
		return false;
	if (!packageSupportsCurrentPlatform(targetPath)) return false;

	const [entry] = relativePath.split(path.sep);
	if (entry === "" || entry === "node_modules") return false;

	if (!selectedEntries.has(entry)) {
		selectedEntries.add(entry);
		pendingEntries.push(entry);
	}

	return true;
}

function walkSymlinks(directory, visit) {
	for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
		const entryPath = path.join(directory, entry.name);
		if (entry.isSymbolicLink()) {
			visit(entryPath);
		} else if (entry.isDirectory()) {
			walkSymlinks(entryPath, visit);
		}
	}
}

const directRuntimeLinks = new Map();

for (const packagePath of runtimePackages) {
	const packageRoot = path.join(workspaceRoot, packagePath);
	const manifest = JSON.parse(
		fs.readFileSync(path.join(packageRoot, "package.json"), "utf8"),
	);
	const packageLinks = [];

	for (const dependencyName of Object.keys(manifest.dependencies ?? {})) {
		const linkPath = path.join(
			packageRoot,
			"node_modules",
			...dependencyName.split("/"),
		);
		let stat;
		try {
			stat = fs.lstatSync(linkPath);
		} catch {
			continue;
		}

		if (!stat.isSymbolicLink()) continue;
		if (!selectVirtualStoreTarget(resolveSymlink(linkPath))) continue;

		packageLinks.push({
			dependencyName,
			target: fs.readlinkSync(linkPath),
		});
	}

	directRuntimeLinks.set(packagePath, packageLinks);
}

for (let index = 0; index < pendingEntries.length; index += 1) {
	const entryPath = path.join(virtualStore, pendingEntries[index]);
	walkSymlinks(entryPath, (linkPath) => {
		selectVirtualStoreTarget(resolveSymlink(linkPath));
	});
}

for (const [packagePath, packageLinks] of directRuntimeLinks) {
	const nodeModules = path.join(workspaceRoot, packagePath, "node_modules");
	fs.rmSync(nodeModules, { recursive: true, force: true });
	fs.mkdirSync(nodeModules, { recursive: true });

	for (const { dependencyName, target } of packageLinks) {
		const linkPath = path.join(nodeModules, ...dependencyName.split("/"));
		fs.mkdirSync(path.dirname(linkPath), { recursive: true });
		fs.symlinkSync(target, linkPath);
	}
}

for (const entry of fs.readdirSync(virtualStore)) {
	if (!selectedEntries.has(entry)) {
		fs.rmSync(path.join(virtualStore, entry), { recursive: true, force: true });
	}
}

for (const entry of fs.readdirSync(rootNodeModules)) {
	if (entry !== ".pnpm") {
		fs.rmSync(path.join(rootNodeModules, entry), {
			recursive: true,
			force: true,
		});
	}
}

console.log(`Kept ${selectedEntries.size} production dependency entries`);
