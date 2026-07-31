import fs from "node:fs";
import process from "node:process";
import { DatabaseSync } from "node:sqlite";

// Upstream renumbers inline sqlite migrations between revisions, but the
// Effect migrator tracks applied migrations by numeric id only. A database
// migrated under an older numbering then silently skips new migrations that
// reuse an already-recorded id, crashing the server on missing columns.
// Reconcile the recorded history by migration *name* against the installed
// server bundle before launch: renumber rows whose name moved, drop rows for
// migrations upstream removed, and leave genuinely-new names for the migrator.

const [bundlePath, databasePath] = process.argv.slice(2);

if (!bundlePath || !databasePath) {
	console.error(
		"usage: reconcile-migrations.mjs <server-bin.mjs> <state.sqlite>",
	);
	process.exit(64);
}

if (!fs.existsSync(databasePath)) {
	console.log("No existing database; nothing to reconcile");
	process.exit(0);
}

const bundleSource = fs.readFileSync(bundlePath, "utf8");
const entryPattern = /\[\s*(\d+)\s*,\s*"(\w+)"\s*,\s*_\d+_\w+_default\s*\]/g;
const bundleIdByName = new Map();

for (const match of bundleSource.matchAll(entryPattern)) {
	bundleIdByName.set(match[2], Number(match[1]));
}

if (bundleIdByName.size === 0) {
	console.warn(
		"Could not locate migration entries in server bundle; leaving database untouched",
	);
	process.exit(0);
}

const database = new DatabaseSync(databasePath);

try {
	const hasMigrationsTable = database
		.prepare(
			"SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'effect_sql_migrations'",
		)
		.get();

	if (!hasMigrationsTable) {
		console.log("No migration history; nothing to reconcile");
		process.exit(0);
	}

	const appliedRows = database
		.prepare("SELECT migration_id, name, created_at FROM effect_sql_migrations")
		.all();

	const removedRows = appliedRows.filter(
		(row) => !bundleIdByName.has(row.name),
	);
	const movedRows = appliedRows.filter(
		(row) =>
			bundleIdByName.has(row.name) &&
			bundleIdByName.get(row.name) !== row.migration_id,
	);

	if (removedRows.length === 0 && movedRows.length === 0) {
		console.log("Migration history matches installed server");
		process.exit(0);
	}

	fs.copyFileSync(databasePath, `${databasePath}.pre-reconcile.bak`);

	database.exec("BEGIN IMMEDIATE");
	// Delete-then-reinsert avoids transient primary-key collisions while
	// several rows swap ids.
	const deleteRow = database.prepare(
		"DELETE FROM effect_sql_migrations WHERE migration_id = ?",
	);
	const insertRow = database.prepare(
		"INSERT INTO effect_sql_migrations (migration_id, name, created_at) VALUES (?, ?, ?)",
	);

	for (const row of [...removedRows, ...movedRows]) {
		deleteRow.run(row.migration_id);
	}
	for (const row of movedRows) {
		insertRow.run(bundleIdByName.get(row.name), row.name, row.created_at);
	}
	database.exec("COMMIT");

	for (const row of removedRows) {
		console.log(`Dropped removed migration ${row.migration_id} ${row.name}`);
	}
	for (const row of movedRows) {
		console.log(
			`Renumbered ${row.name}: ${row.migration_id} -> ${bundleIdByName.get(row.name)}`,
		);
	}
} catch (error) {
	// Never block launch on reconcile problems (for example a locked
	// database); the migrator itself is the authority of last resort.
	console.warn(`Migration reconcile skipped: ${error.message}`);
} finally {
	database.close();
}
