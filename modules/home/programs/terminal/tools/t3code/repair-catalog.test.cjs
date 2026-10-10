const assert = require("node:assert/strict");
const { test } = require("node:test");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const {
	findBearerProfile,
	replaceBearerCredential,
	readCatalog,
	writeCatalog,
	catalogArgs,
} = require("./repair-catalog.cjs");

test("Electron launch switches do not shift the catalog arguments", () => {
	const args = ["T3 Code (Alpha)", "/profile", "/catalog", "mac", "inspect"];
	for (const switches of [
		[],
		["--disable-gpu"],
		["--disable-gpu", "--ozone-platform=wayland"],
	]) {
		assert.deepEqual(
			catalogArgs(
				["electron", ...switches, "/helper.cjs", ...args],
				"/helper.cjs",
			),
			args,
		);
	}
	assert.throws(() =>
		catalogArgs(["electron", "/other.cjs", ...args], "/helper.cjs"),
	);
});

function catalog() {
	return {
		schemaVersion: 1,
		targets: [
			{
				_tag: "BearerConnectionTarget",
				environmentId: "mac",
				connectionId: "bearer:mac",
			},
			{
				_tag: "BearerConnectionTarget",
				environmentId: "other",
				connectionId: "bearer:other",
			},
		],
		profiles: [
			{
				_tag: "BearerConnectionProfile",
				environmentId: "mac",
				connectionId: "bearer:mac",
				httpBaseUrl: "https://mac.example/",
			},
			{
				_tag: "BearerConnectionProfile",
				environmentId: "other",
				connectionId: "bearer:other",
				httpBaseUrl: "https://other.example/",
			},
		],
		credentials: [
			{
				connectionId: "bearer:mac",
				credential: { _tag: "BearerConnectionCredential", token: "expired" },
			},
			{
				connectionId: "bearer:other",
				credential: { _tag: "BearerConnectionCredential", token: "keep" },
			},
		],
		remoteDpopTokens: [{ environmentId: "other", token: "keep-dpop" }],
		disabledEnvironmentIds: [],
	};
}

test("repair replaces only the matching credential and does not mutate the original", () => {
	const original = catalog();
	const expected = structuredClone(original);
	expected.credentials[0].credential.token = "fresh";
	assert.deepEqual(replaceBearerCredential(original, "mac", "fresh"), expected);
	assert.equal(original.credentials[0].credential.token, "expired");
});

test("repair restores a missing credential without duplicating the saved environment", () => {
	const original = catalog();
	original.credentials.shift();
	const repaired = replaceBearerCredential(original, "mac", "fresh");
	assert.deepEqual(repaired.targets, original.targets);
	assert.deepEqual(repaired.credentials[0], original.credentials[0]);
	assert.equal(repaired.credentials.length, 2);
});

test("unsupported, ambiguous, disabled and insecure connections fail closed", () => {
	assert.throws(() =>
		findBearerProfile({ ...catalog(), schemaVersion: 2 }, "mac"),
	);
	assert.throws(() => findBearerProfile(catalog(), "unknown"));
	const duplicate = catalog();
	duplicate.targets.push(duplicate.targets[0]);
	assert.throws(() => findBearerProfile(duplicate, "mac"));
	const disabled = catalog();
	disabled.disabledEnvironmentIds.push("mac");
	assert.throws(() => findBearerProfile(disabled, "mac"));
	const insecure = catalog();
	insecure.profiles[0].httpBaseUrl = "http://mac.example/";
	assert.throws(() => findBearerProfile(insecure, "mac"));
});

test("malformed or duplicate credentials cannot be written", () => {
	for (const token of [null, "", " ", "header\ninjection"]) {
		assert.throws(() => replaceBearerCredential(catalog(), "mac", token));
	}
	const duplicate = catalog();
	duplicate.credentials.push(duplicate.credentials[0]);
	assert.throws(() => replaceBearerCredential(duplicate, "mac", "fresh"));
});

test("native replacement rejects unavailable encryption and stale catalogs, and keeps an encrypted backup", () => {
	const cache = process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache");
	fs.mkdirSync(cache, { recursive: true });
	const directory = fs.mkdtempSync(path.join(cache, "t3-repair-test-"));
	const file = path.join(directory, "catalog.json");
	// This test double represents opaque native ciphertext, not an alternative cipher.
	const ciphertext = new Map();
	let serial = 0;
	const storage = {
		isEncryptionAvailable: () => true,
		getSelectedStorageBackend: () => "gnome_libsecret",
		encryptString: (text) => {
			const id = `encrypted-${serial++}`;
			ciphertext.set(id, text);
			return Buffer.from(id);
		},
		decryptString: (buffer) => ciphertext.get(buffer.toString()),
	};
	try {
		const initial = JSON.stringify({
			version: 1,
			encryptedCatalog: storage
				.encryptString(JSON.stringify(catalog()))
				.toString("base64"),
		});
		fs.writeFileSync(file, initial);
		const { digest } = readCatalog(file, storage);
		for (const unavailable of [
			{ ...storage, isEncryptionAvailable: () => false },
			{ ...storage, getSelectedStorageBackend: () => "basic_text" },
		]) {
			assert.throws(() =>
				writeCatalog(file, "mac", { digest, token: "fresh" }, unavailable),
			);
			assert.equal(fs.readFileSync(file, "utf8"), initial);
		}
		fs.appendFileSync(file, "\n");
		assert.throws(
			() => writeCatalog(file, "mac", { digest, token: "fresh" }, storage),
			/changed/,
		);
		assert.equal(fs.readFileSync(file, "utf8"), `${initial}\n`);
		fs.writeFileSync(file, initial);
		writeCatalog(file, "mac", { digest, token: "fresh" }, storage);
		assert.equal(
			readCatalog(file, storage).catalog.credentials[0].credential.token,
			"fresh",
		);
		assert.equal(fs.readFileSync(`${file}.t3-repair-backup`, "utf8"), initial);
		assert.equal(fs.statSync(file).mode & 0o777, 0o600);
		assert.equal(fs.readFileSync(file, "utf8").includes("fresh"), false);
		assert.deepEqual(fs.readdirSync(directory).sort(), [
			"catalog.json",
			"catalog.json.t3-repair-backup",
		]);
	} finally {
		fs.rmSync(directory, { recursive: true });
	}
});
