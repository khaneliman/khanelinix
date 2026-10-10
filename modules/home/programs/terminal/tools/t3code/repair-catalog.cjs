const fs = require("node:fs");
const crypto = require("node:crypto");

function findBearerProfile(catalog, environmentId) {
	if (
		catalog.schemaVersion !== 1 ||
		!Array.isArray(catalog.targets) ||
		!Array.isArray(catalog.profiles) ||
		!Array.isArray(catalog.credentials) ||
		!Array.isArray(catalog.disabledEnvironmentIds)
	) {
		throw new Error("Unsupported connection catalog format.");
	}
	const targets = catalog.targets.filter(
		(t) => t.environmentId === environmentId,
	);
	if (targets.length !== 1 || targets[0]._tag !== "BearerConnectionTarget") {
		throw new Error(
			"The remote environment must already have a saved bearer connection.",
		);
	}
	const target = targets[0];
	const profiles = catalog.profiles.filter(
		(p) => p.connectionId === target.connectionId,
	);
	if (
		profiles.length !== 1 ||
		profiles[0]._tag !== "BearerConnectionProfile" ||
		profiles[0].environmentId !== environmentId
	) {
		throw new Error("The saved connection profile is inconsistent.");
	}
	if (catalog.disabledEnvironmentIds.includes(environmentId)) {
		throw new Error("The saved environment is disabled.");
	}
	const url = new URL(profiles[0].httpBaseUrl);
	if (url.protocol !== "https:" || url.username || url.password) {
		throw new Error("Remote credential repair requires an HTTPS connection.");
	}
	return profiles[0];
}

function replaceBearerCredential(catalog, environmentId, token) {
	if (typeof token !== "string" || !token.trim() || /[\r\n]/.test(token)) {
		throw new Error("Invalid bearer credential.");
	}
	const profile = findBearerProfile(catalog, environmentId);
	const entries = catalog.credentials.filter(
		(c) => c.connectionId === profile.connectionId,
	);
	if (entries.length > 1)
		throw new Error("The connection has duplicate credentials.");
	const next = structuredClone(catalog);
	const credential = {
		connectionId: profile.connectionId,
		credential: { _tag: "BearerConnectionCredential", token },
	};
	const index = next.credentials.findIndex(
		(c) => c.connectionId === profile.connectionId,
	);
	if (index === -1) next.credentials.push(credential);
	else next.credentials[index] = credential;
	return next;
}

function readCatalog(catalogPath, safeStorage) {
	if (
		!safeStorage.isEncryptionAvailable() ||
		safeStorage.getSelectedStorageBackend() === "basic_text"
	) {
		throw new Error(
			"The desktop keyring is unavailable; credentials were not changed.",
		);
	}
	const original = fs.readFileSync(catalogPath);
	const document = JSON.parse(original);
	if (document.version !== 1 || typeof document.encryptedCatalog !== "string") {
		throw new Error("Unsupported encrypted catalog format.");
	}
	const catalog = JSON.parse(
		safeStorage.decryptString(Buffer.from(document.encryptedCatalog, "base64")),
	);
	return {
		original,
		catalog,
		digest: crypto.createHash("sha256").update(original).digest("hex"),
	};
}

function writeCatalog(catalogPath, environmentId, input, safeStorage) {
	const { original, catalog, digest } = readCatalog(catalogPath, safeStorage);
	if (input.digest !== digest)
		throw new Error("The catalog changed; run the repair again.");
	const next = replaceBearerCredential(catalog, environmentId, input.token);
	const encryptedCatalog = safeStorage
		.encryptString(JSON.stringify(next))
		.toString("base64");
	const replacement = `${JSON.stringify({ version: 1, encryptedCatalog })}\n`;
	const tempPath = `${catalogPath}.${process.pid}.tmp`;
	try {
		fs.writeFileSync(tempPath, replacement, { mode: 0o600, flag: "wx" });
		fs.writeFileSync(`${catalogPath}.t3-repair-backup`, original, {
			mode: 0o600,
		});
		if (!fs.readFileSync(catalogPath).equals(original)) {
			throw new Error(
				"The catalog changed before replacement; run the repair again.",
			);
		}
		fs.renameSync(tempPath, catalogPath);
	} finally {
		fs.rmSync(tempPath, { force: true });
	}
}

async function main() {
	const { app, safeStorage } = require("electron");
	// Electron retains its own switches before the entrypoint in process.argv.
	const [appName, userData, catalogPath, environmentId, mode] = catalogArgs(
		process.argv,
		__filename,
	);
	app.setName(appName);
	app.setPath("userData", userData);
	// Replacement owns the same singleton lock as the stopped desktop. A user
	// reopening the app must not create a second writer during this operation.
	if (mode === "replace" && !app.requestSingleInstanceLock()) {
		app.exit(1);
		return;
	}
	app.commandLine.appendSwitch("password-store", "gnome-libsecret");
	if (process.env.WAYLAND_DISPLAY)
		app.commandLine.appendSwitch("ozone-platform", "wayland");
	await app.whenReady();
	try {
		if (mode === "inspect") {
			const { catalog, digest } = readCatalog(catalogPath, safeStorage);
			const profile = findBearerProfile(catalog, environmentId);
			console.log(
				JSON.stringify({
					digest,
					httpBaseUrl: profile.httpBaseUrl,
					label: profile.label,
				}),
			);
		} else if (mode === "replace") {
			const input = JSON.parse(fs.readFileSync(0, "utf8"));
			writeCatalog(catalogPath, environmentId, input, safeStorage);
			console.log(JSON.stringify({ replaced: true }));
		} else if (mode === "contains") {
			const input = JSON.parse(fs.readFileSync(0, "utf8"));
			const { catalog } = readCatalog(catalogPath, safeStorage);
			const profile = findBearerProfile(catalog, environmentId);
			const installed = catalog.credentials.some(
				(entry) =>
					entry.connectionId === profile.connectionId &&
					entry.credential?.token === input.token,
			);
			console.log(JSON.stringify({ installed }));
		} else {
			throw new Error("Unknown catalog operation.");
		}
		app.exit(0);
	} catch (error) {
		// Parsing failures can include decrypted data in the message.
		console.error(
			"t3-repair: Native catalog operation failed; credentials were not printed.",
		);
		app.exit(1);
	}
}

function catalogArgs(argv, entrypoint) {
	const index = argv.indexOf(entrypoint);
	if (index === -1 || argv.length !== index + 6) {
		throw new Error("Invalid native catalog arguments.");
	}
	return argv.slice(index + 1);
}

module.exports = {
	findBearerProfile,
	replaceBearerCredential,
	readCatalog,
	writeCatalog,
	catalogArgs,
};
// Electron loads its entrypoint as a module, so require.main is not this file.
if (process.type === "browser" && process.argv.includes(__filename)) {
	main().catch(() => process.exit(1));
}
