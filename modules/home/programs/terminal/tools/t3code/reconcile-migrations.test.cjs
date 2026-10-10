const assert = require("node:assert/strict");
const { test } = require("node:test");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { DatabaseSync } = require("node:sqlite");

function fixture(run) {
	const cache = process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache");
	fs.mkdirSync(cache, { recursive: true });
	const dir = fs.mkdtempSync(path.join(cache, "t3-reconcile-test-"));
	const file = path.join(dir, "state.sqlite");
	const bundle = path.join(dir, "bin.mjs");
	const db = new DatabaseSync(file);
	try {
		db.exec(`PRAGMA journal_mode=WAL; PRAGMA wal_autocheckpoint=0;
			CREATE TABLE effect_sql_migrations (migration_id INTEGER PRIMARY KEY, name TEXT, created_at TEXT);
			INSERT INTO effect_sql_migrations VALUES (1, 'first', 'original'), (2, 'second', 'original'), (3, 'removed', 'original');
			CREATE TABLE messages (text TEXT); INSERT INTO messages VALUES ('committed');`);
		fs.writeFileSync(
			bundle,
			'[2, "first", _2_first_default], [1, "second", _1_second_default], [4, "new", _4_new_default]',
		);
		const invoke = (umask) => {
			const result = spawnSync(
				process.execPath,
				[
					...(umask === undefined
						? []
						: ["--import", `data:text/javascript,process.umask(${umask})`]),
					path.join(__dirname, "reconcile-migrations.mjs"),
					bundle,
					file,
				],
				{ encoding: "utf8", timeout: 10000 },
			);
			assert.equal(result.status, 0, result.stderr);
			return result;
		};
		run({ db, file, bundle, invoke });
	} finally {
		db.close();
		fs.rmSync(dir, { recursive: true });
	}
}

function rows(db) {
	return db
		.prepare(
			"SELECT migration_id, name, created_at FROM effect_sql_migrations ORDER BY migration_id",
		)
		.all()
		.map((row) => ({ ...row }));
}

test("backup includes committed WAL rows before renumbering, dropping and preserving new migrations", () =>
	fixture(({ db, file, invoke }) => {
		const original = rows(db);
		assert.ok(fs.statSync(`${file}-wal`).size > 0);
		// A bare main-file copy lacks the schema still committed only in the WAL.
		fs.copyFileSync(file, `${file}.raw-copy`);
		const raw = new DatabaseSync(`${file}.raw-copy`);
		try {
			assert.throws(() => rows(raw), /no such table/);
		} finally {
			raw.close();
		}
		invoke();
		const snapshot = new DatabaseSync(`${file}.pre-reconcile.bak`);
		try {
			assert.deepEqual(rows(snapshot), original);
			assert.equal(
				snapshot.prepare("SELECT text FROM messages").get().text,
				"committed",
			);
			assert.equal(
				snapshot.prepare("PRAGMA integrity_check").get().integrity_check,
				"ok",
			);
		} finally {
			snapshot.close();
		}
		assert.deepEqual(rows(db), [
			{ migration_id: 1, name: "second", created_at: "original" },
			{ migration_id: 2, name: "first", created_at: "original" },
		]);
		assert.equal(
			db.prepare("SELECT text FROM messages").get().text,
			"committed",
		);
		const saved = fs.readFileSync(`${file}.pre-reconcile.bak`);
		assert.match(invoke().stdout, /matches installed server/);
		assert.deepEqual(fs.readFileSync(`${file}.pre-reconcile.bak`), saved);
	}));

test("a failed backup leaves migration history untouched and launch nonblocking", () =>
	fixture(({ db, file, invoke }) => {
		const original = rows(db);
		fs.mkdirSync(`${file}.pre-reconcile.bak`);
		assert.match(invoke().stderr, /Migration reconcile skipped/);
		assert.deepEqual(rows(db), original);
		assert.deepEqual(
			fs.readdirSync(path.dirname(file)).filter((name) => name.startsWith("state.sqlite.pre-reconcile-")),
			[],
		);
	}));

test("recovery snapshots preserve source permissions with permissive umasks", () => {
	for (const mode of [0o600, 0o640, 0o644]) {
		for (const umask of [0o022, 0o000]) {
			fixture(({ db, file, invoke }) => {
				const original = rows(db);
				fs.chmodSync(file, mode);
				invoke(umask);
				assert.equal(fs.statSync(`${file}.pre-reconcile.bak`).mode & 0o777, mode);
				const snapshot = new DatabaseSync(`${file}.pre-reconcile.bak`);
				try {
					assert.deepEqual(rows(snapshot), original);
				} finally {
					snapshot.close();
				}
			});
		}
	}
});

test("missing history and unrecognized bundles remain no-ops", () =>
	fixture(({ db, file, bundle, invoke }) => {
		fs.writeFileSync(bundle, "no inline migration entries");
		const original = rows(db);
		assert.match(invoke().stderr, /leaving database untouched/);
		assert.deepEqual(rows(db), original);
		fs.writeFileSync(bundle, '[1, "first", _1_first_default]');
		db.exec("DROP TABLE effect_sql_migrations");
		assert.match(invoke().stdout, /No migration history/);
		assert.equal(fs.existsSync(`${file}.pre-reconcile.bak`), false);
	}));
