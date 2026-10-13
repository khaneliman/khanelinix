#!/usr/bin/env node
// Reads and searches the signed-in Microsoft Teams web client over the Chrome
// DevTools Protocol (CDP). Requires Node 22 or newer for global fetch and
// WebSocket. PAGE_LIB and the page*/frame* functions are serialized and run
// inside Teams, so they must not reference anything outside PAGE_LIB.
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

const USAGE = `Usage: node teams_cdp.mjs <command> [options]

Commands:
  status                          Report the CDP endpoint, Teams page, open view, and frames.
  cache-list [--kind KIND] [--name TEXT] [--team TEXT]
                                  List conversations in Teams' local cache (chat, channel,
                                  meeting, community, other) without touching the UI.
  cache-read <name-or-id> [--team TEXT] [--from self|NAME] [--thread ID]
             [--since ISO] [--until ISO] [--limit N] [--all-types] [--body] [--max-chars N]
                                  Read one conversation's cached messages, oldest first.
  search <query> [--in NAME [--team TEAM]] [--max-pages N]
                                  Run Teams message search, optionally scoped to one chat or
                                  channel, and print the result cards it loads (default 10 pages).
  sidebar                         List sidebar groups and conversation names.
  read [--all] [--max-chars N]    Read messages in the open chat, channel, or thread view.
                                  --all scrolls a channel or thread toward its start first.
  sp-list <site-path>             List document-library files through the signed-in
                                  SharePoint frame, e.g. /teams/ExampleSite.
  sp-download [--force] <outdir> <server-relative-path>...
                                  Download SharePoint files into <outdir>.
  eval [--target REGEX] <js | @file | ->
                                  Evaluate JavaScript in the Teams page, or in the first page or
                                  iframe whose URL matches REGEX, and print the result.

Environment: CDP_PORT (default 9222).
Exit codes: 0 success, 1 page or protocol failure, 2 usage error,
3 no CDP endpoint or target, 4 a name matched nothing or several things,
5 a Teams call is in progress (wait; do not restart Teams),
6 the Teams window is or went off screen (ask the user to show it).`;

const EXIT = {
	page: 1,
	usage: 2,
	unavailable: 3,
	scope: 4,
	call: 5,
	hidden: 6,
};
const TEAMS_URL = /^https:\/\/teams\.(cloud\.microsoft|microsoft\.com)\//;
const SHAREPOINT_FRAME_URL =
	/^https:\/\/[^/]+\.sharepoint\.com\/\?.*\bisInTeams=true/;
// Page code prefixes errors with these tags so Node can map them to exit codes.
const PAGE_ERROR_CODES = { "hidden:": EXIT.hidden, "scope:": EXIT.scope };
const port = process.env.CDP_PORT ?? "9222";

class CliError extends Error {
	constructor(code, message) {
		super(message);
		this.code = code;
	}
}

// ---- page helpers (serialized into every page call) ----

function sleep(ms) {
	return new Promise((r) => setTimeout(r, ms));
}

function clean(e) {
	return (e?.innerText ?? "")
		.replace(/[ \t]+/g, " ")
		.replace(/\n{3,}/g, "\n\n")
		.trim();
}

function oneLine(s) {
	return (s ?? "").replace(/\s+/g, " ").trim();
}

function firstLine(e) {
	return (
		(e?.innerText ?? "")
			.split("\n")
			.map((s) => s.trim())
			.find(Boolean) ?? ""
	);
}

function isVisible(e) {
	return !!e?.offsetParent;
}

async function waitFor(fn, ms) {
	const end = Date.now() + ms;
	while (Date.now() < end) {
		const v = fn();
		if (v) return v;
		await sleep(250);
	}
	return fn();
}

function clip(s, max) {
	// Slice by code point; slicing UTF-16 units can split an emoji and emit
	// JSON with a lone surrogate that jq rejects.
	const chars = Array.from(s);
	return chars.length > max
		? { text: chars.slice(0, max).join(""), truncated: true }
		: { text: s };
}

async function cacheStore(manager, store, range) {
	// Teams names its databases "Teams:<manager>:react-web-client:<ids>:<locale>";
	// several matches mean several signed-in accounts, so refuse to guess.
	const dbs = (await indexedDB.databases()).filter((d) =>
		d.name.startsWith(`Teams:${manager}:`),
	);
	if (dbs.length !== 1)
		throw new Error(
			`scope: expected one Teams ${manager} cache, found ${dbs.length}`,
		);
	const db = await new Promise((res, rej) => {
		// Opening at the current version never upgrades; abort if Teams has a
		// newer schema than the one we saw instead of creating anything.
		const r = indexedDB.open(dbs[0].name, dbs[0].version);
		r.onupgradeneeded = () => {
			r.transaction.abort();
			rej(new Error(`the ${manager} cache schema changed`));
		};
		r.onsuccess = () => res(r.result);
		r.onerror = () => rej(new Error(`could not open the ${manager} cache`));
	});
	try {
		return await new Promise((res, rej) => {
			const r = db
				.transaction(store, "readonly")
				.objectStore(store)
				.getAll(range);
			r.onsuccess = () => res(r.result);
			r.onerror = () => rej(new Error(`could not read ${manager}/${store}`));
		});
	} finally {
		// Close promptly: an open connection would block a Teams schema upgrade.
		db.close();
	}
}

function conversationInfo(c, byId) {
	const tp = c.threadProperties ?? {};
	const teamName = (id) =>
		byId.get(id)?.threadProperties?.spaceThreadTopic ?? null;
	let kind = "other";
	let name = tp.topic || c.chatTitle?.longTitle || null;
	let team = null;
	if (c.type === "Chat" || c.type === "StreamOfNotes") kind = "chat";
	else if (c.type === "Meeting") kind = "meeting";
	else if (c.type === "EngageCommunity") kind = "community";
	else if (c.type === "Topic") {
		// Standard channel; its team is the Space record named by teamId.
		kind = "channel";
		name = tp.topicThreadTopic || tp.topic || null;
		team = teamName(c.teamId);
	} else if (c.type === "Space" && c.parentId) {
		// Shared or private channel nested under its team's Space record.
		kind = "channel";
		name = tp.spaceThreadTopic || tp.topic || null;
		team = teamName(c.parentId);
	} else if (c.type === "Space") {
		// A team's own Space record is also its General channel.
		kind = "channel";
		name = tp.topicThreadTopic || tp.topic || "General";
		team = tp.spaceThreadTopic ?? null;
	}
	const deleted = String(c.isDeleted ?? tp.isdeleted) === "true";
	return {
		id: c.id,
		kind,
		type: c.type,
		name,
		team,
		...(deleted && { deleted }),
	};
}

function resolveConversation(infos, query, team) {
	const byId = infos.find((c) => c.id === query);
	if (byId) return { pick: byId };
	const want = query.toLowerCase();
	const inTeam = (c) =>
		!team || (c.team ?? "").toLowerCase().includes(team.toLowerCase());
	const live = infos.filter((c) => !c.deleted && inTeam(c));
	const exact = live.filter((c) => c.name?.toLowerCase() === want);
	const partial = live.filter((c) => c.name?.toLowerCase().includes(want));
	const pick =
		exact.length === 1
			? exact[0]
			: !exact.length && partial.length === 1
				? partial[0]
				: null;
	if (pick) return { pick };
	const candidates = exact.length ? exact : partial;
	return {
		error: candidates.length
			? "ambiguous conversation"
			: "missing conversation",
		candidates: candidates.slice(0, 25),
	};
}

function messageText(m) {
	const content = m.content ?? "";
	if (!/Html/i.test(m.messageType)) return content;
	// Teams enforces Trusted Types, so DOMParser and innerHTML reject plain
	// strings. Stripping tags and decoding entities is enough for readable
	// text; it does not preserve tables or other layout.
	const named = { amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " " };
	const decode = (all, e) => {
		if (e[0] !== "#") return named[e.toLowerCase()] ?? all;
		const cp =
			e[1].toLowerCase() === "x"
				? Number.parseInt(e.slice(2), 16)
				: Number.parseInt(e.slice(1), 10);
		return cp > 0 && cp <= 0x10ffff ? String.fromCodePoint(cp) : all;
	};
	return content
		.replace(/\r\n?/g, "\n")
		.replace(/<(script|style)\b[\s\S]*?<\/\1>/gi, "")
		.replace(/<br\s*\/?>/gi, "\n")
		.replace(/<\/(p|div|li|h[1-6]|tr|blockquote)>/gi, "\n")
		.replace(/<[^>]+>/g, "")
		.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, decode)
		.replace(/[ \t]+\n/g, "\n")
		.replace(/\n{3,}/g, "\n\n")
		.trim();
}

function messageFiles(m) {
	let files;
	try {
		files = JSON.parse(m.properties?.files || "[]");
	} catch {
		return [];
	}
	if (!Array.isArray(files)) return [];
	return files.map((f) => {
		const info = f.fileInfo ?? {};
		let path =
			typeof info.serverRelativeUrl === "string" &&
			info.serverRelativeUrl.startsWith("/")
				? info.serverRelativeUrl
				: null;
		if (!path && typeof info.fileUrl === "string") {
			try {
				const u = new URL(info.fileUrl);
				if (u.hostname.endsWith(".sharepoint.com"))
					path = decodeURIComponent(u.pathname);
			} catch {}
		}
		return {
			name: f.fileName ?? f.title ?? null,
			type: f.fileType ?? null,
			path,
		};
	});
}

function pageInCall() {
	return !!document.querySelector("[data-tid=call-duration]");
}

function pageRendering() {
	// A window on a hidden workspace or minimized produces no frames, and Teams
	// loads more results and history from rendering callbacks, so lists would
	// stop short without any error.
	return new Promise((res) => {
		requestAnimationFrame(() => res(true));
		setTimeout(() => res(false), 1500);
	});
}

async function assertRendering() {
	// Checked inside every loading loop: a window that leaves the screen mid-run
	// stalls loading, which would otherwise look like a finished list.
	if (!(await pageRendering()))
		throw new Error(
			"hidden: the Teams window stopped rendering; results would be partial",
		);
}

function attachments(root) {
	const files = new Map();
	// File cards label themselves "name" and "name\nurl"; buttons such as Share
	// also carry labels, so keep only labels that look like file names.
	for (const e of root.querySelectorAll(
		"[data-tid=file-attachment-grid] [aria-label], [data-tid=file-attachment-grid] [title]",
	)) {
		const [name, url] = (
			e.getAttribute("aria-label") ?? e.getAttribute("title")
		)
			.split("\n")
			.map((s) => s.trim());
		if (/\.[a-z0-9]{2,5}$/i.test(name))
			files.set(name, url ?? files.get(name) ?? null);
	}
	for (const a of root.querySelectorAll("[data-tid=message-body] a[href]"))
		files.set(clean(a) || a.href, a.href);
	return [...files].map(([name, url]) => ({ name, url }));
}

function readChannelMessage(m, maxChars) {
	const own = (sel) => (m.matches(sel) ? m : m.querySelector(sel));
	const t = m.querySelector("time");
	const body = clip(
		clean(m.querySelector("[data-tid=message-body]")),
		maxChars,
	);
	return {
		mid: own("[data-mid]")?.dataset.mid ?? null,
		replyChainId: own("[data-reply-chain-id]")?.dataset.replyChainId ?? null,
		subject: clean(m.querySelector("[data-tid=subject-line]")) || null,
		author: clean(m.querySelector("[id^=author-]")) || null,
		time: t?.getAttribute("aria-label") ?? (clean(t) || null),
		body: body.text,
		...(body.truncated && { truncated: true }),
		replySummary:
			clean(m.querySelector("[data-tid=response-summary-button]")) || null,
		attachments: attachments(m),
	};
}

async function settleTop(tid) {
	// Older items load only after a real scroll toward the top, so nudge down,
	// return to the top with a wheel event, and repeat until the height holds
	// for three rounds. That is a heuristic: it shows loading stopped, not that
	// the first message was reached. Returns false when the round cap hits.
	let last = -1;
	let stable = 0;
	for (let i = 0; i < 60; i++) {
		await assertRendering();
		const v = document.querySelector(`[data-tid=${tid}]`);
		if (!v) return false;
		stable = v.scrollHeight === last ? stable + 1 : 0;
		if (stable >= 3) return true;
		last = v.scrollHeight;
		v.scrollTop = 400;
		v.dispatchEvent(new Event("scroll"));
		await sleep(250);
		v.scrollTop = 0;
		v.dispatchEvent(new Event("scroll"));
		v.dispatchEvent(new WheelEvent("wheel", { deltaY: -800, bubbles: true }));
		await sleep(1200);
	}
	return false;
}

async function sweep(tid, selector, read) {
	// The list is virtualized and redraws while scrolling, so one pass can miss
	// items; scan twice in half-viewport steps and keep items by message id.
	const seen = new Map();
	let idlessSightings = 0;
	for (let pass = 0; pass < 2; pass++) {
		for (let y = 0; ; ) {
			await assertRendering();
			const v = document.querySelector(`[data-tid=${tid}]`);
			if (!v) throw new Error(`${tid} disappeared while scrolling`);
			v.scrollTop = y;
			v.dispatchEvent(new Event("scroll"));
			await sleep(700);
			for (const e of v.querySelectorAll(selector)) {
				const r = read(e);
				if (!r.mid) idlessSightings++;
				else if (!seen.has(r.mid)) seen.set(r.mid, r);
			}
			if (y >= v.scrollHeight - v.clientHeight) break;
			y += Math.floor(v.clientHeight * 0.5);
		}
	}
	// Message ids are creation times in epoch milliseconds, so they sort by time.
	const messages = [...seen.values()].sort(
		(a, b) => Number(a.mid) - Number(b.mid),
	);
	return { messages, idlessSightings };
}

async function pageAwaitFreshCards(what) {
	// Cards from the previous view stay on screen until new results render, so
	// wait for a card pageMarkCards did not mark. No cards at all means no
	// results; only marked cards means the results never refreshed.
	const fresh = () =>
		document.querySelector("[data-tid=search-card]:not([data-teams-cdp-seen])");
	if (await waitFor(fresh, 15000)) {
		await sleep(1500);
		return;
	}
	if (document.querySelector("[data-tid=search-card][data-teams-cdp-seen]"))
		throw new Error(`${what} did not refresh; rerun the search`);
}

function pageSetInput(selector, text, submit) {
	// Set the value and send Enter on the element itself instead of through
	// focus-routed CDP input, so text can never land in a compose box and a
	// stray Enter can never send a draft. If Teams ignores these synthetic
	// events, the search simply does not run and a later wait fails.
	const e = document.querySelector(selector);
	if (!e?.matches("input")) throw new Error(`${selector} is not an input`);
	e.focus();
	Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set.call(
		e,
		text,
	);
	e.dispatchEvent(new Event("input", { bubbles: true }));
	if (submit) {
		const key = {
			key: "Enter",
			code: "Enter",
			keyCode: 13,
			which: 13,
			bubbles: true,
			cancelable: true,
		};
		for (const type of ["keydown", "keypress", "keyup"])
			e.dispatchEvent(new KeyboardEvent(type, key));
	}
	return e.value === text;
}

const PAGE_LIB = [
	sleep,
	clean,
	oneLine,
	firstLine,
	isVisible,
	waitFor,
	clip,
	pageInCall,
	pageRendering,
	assertRendering,
	attachments,
	readChannelMessage,
	settleTop,
	sweep,
	pageAwaitFreshCards,
	pageSetInput,
	cacheStore,
	conversationInfo,
	resolveConversation,
	messageText,
	messageFiles,
]
	.map(String)
	.join("\n");

const pageCall = (fn, ...args) =>
	`(async () => {\n${PAGE_LIB}\nreturn (${fn})(...${JSON.stringify(args)});\n})()`;

// ---- page commands ----

async function pageStatus() {
	const view = document.querySelector("[data-tid=channel-replies-viewport]")
		? "thread"
		: document.querySelector("[data-tid=channel-pane-viewport]")
			? "channel"
			: document.querySelector("[data-tid=chat-pane-item]")
				? "chat"
				: document.querySelector(
							"[data-tid=search-card], [data-tid=messages-tab]",
						)
					? "search"
					: "other";
	return {
		title: document.title,
		view,
		searchFilters:
			oneLine(document.querySelector("[data-tid=search-filters]")?.innerText) ||
			null,
		sidebar:
			document.querySelectorAll('[role=treeitem][aria-level="1"]').length > 0,
		inCall: pageInCall(),
		rendering: await pageRendering(),
	};
}

async function pageCacheList(kind, name, team) {
	const rows = await cacheStore("conversation-manager", "conversations");
	const byId = new Map(rows.map((c) => [c.id, c]));
	const has = (value, text) =>
		!text || (value ?? "").toLowerCase().includes(text.toLowerCase());
	return rows
		.map((c) => conversationInfo(c, byId))
		.filter(
			(c) =>
				!c.deleted &&
				(!kind || c.kind === kind) &&
				has(c.name, name) &&
				has(c.team, team),
		)
		.sort((a, b) =>
			[a.kind, a.team ?? "", a.name ?? ""]
				.join("\u0000")
				.localeCompare([b.kind, b.team ?? "", b.name ?? ""].join("\u0000")),
		);
}

async function pageCacheRead(q) {
	const convs = await cacheStore("conversation-manager", "conversations");
	const byId = new Map(convs.map((c) => [c.id, c]));
	const found = resolveConversation(
		convs.map((c) => conversationInfo(c, byId)),
		q.conversation,
		q.team,
	);
	if (!found.pick) return found;
	const profiles = await cacheStore("profiles", "profiles");
	const names = new Map(
		profiles.filter((p) => p.mri).map((p) => [p.mri, p.displayName ?? null]),
	);
	let sender = null;
	if (q.from && q.from !== "self") {
		const ids = [
			...new Set(
				profiles
					.filter((p) => p.displayName?.toLowerCase() === q.from.toLowerCase())
					.map((p) => p.mri)
					.filter(Boolean),
			),
		];
		if (ids.length !== 1)
			return {
				error: ids.length ? "ambiguous sender" : "missing sender",
				candidates: ids,
			};
		sender = ids[0];
	}
	const target = found.pick;
	// The replychains key is [conversationId, replyChainId]; an array upper
	// bound sorts after every string thread id.
	const chains = await cacheStore(
		"replychain-manager",
		"replychains",
		IDBKeyRange.bound([target.id], [target.id, []]),
	);
	const seen = new Set();
	const skipped = { deleted: 0, otherTypes: 0 };
	const matched = [];
	for (const chain of chains) {
		if (q.thread && chain.replyChainId !== q.thread) continue;
		for (const m of Object.values(chain.messageMap ?? {})) {
			if (seen.has(m.id)) continue;
			seen.add(m.id);
			if (m.properties?.deletetime) {
				skipped.deleted++;
				continue;
			}
			if (
				!q.allTypes &&
				!/^(RichText\/Html|RichText|Text)$/.test(m.messageType)
			) {
				skipped.otherTypes++;
				continue;
			}
			if (
				q.from === "self"
					? m.isSentByCurrentUser !== true
					: sender && m.creator !== sender
			)
				continue;
			const t = m.originalArrivalTime;
			if ((q.since && t < q.since) || (q.until && t > q.until)) continue;
			matched.push({ m, threadId: chain.replyChainId });
		}
	}
	matched.sort((a, b) => a.m.originalArrivalTime - b.m.originalArrivalTime);
	const kept = matched.slice(-q.limit);
	const messages = kept.map(({ m, threadId }) => {
		const body = q.body ? clip(messageText(m), q.maxChars) : null;
		const files = messageFiles(m);
		return {
			id: m.id,
			threadId,
			isRoot: m.id === threadId,
			time: new Date(m.originalArrivalTime).toISOString(),
			author: names.get(m.creator) ?? m.imDisplayName ?? null,
			authorId: m.creator ?? null,
			fromMe: m.isSentByCurrentUser === true,
			type: m.messageType,
			...(m.properties?.subject && { subject: m.properties.subject }),
			...(files.length && { attachments: files }),
			...(body && { body: body.text }),
			...(body?.truncated && { truncated: true }),
		};
	});
	return {
		source: "teams-indexeddb-cache",
		completeness: "unknown",
		...(!chains.length && {
			hint: "no cached messages; Teams may not have synced this conversation, so try search",
		}),
		conversation: target,
		scanned: { threads: chains.length, messages: seen.size },
		skipped,
		matched: matched.length,
		returned: messages.length,
		truncated: matched.length > messages.length,
		messages,
	};
}

function pageSidebar() {
	const groups = [
		...document.querySelectorAll('[role=treeitem][aria-level="1"]'),
	];
	if (!groups.length)
		throw new Error(
			"no sidebar tree is shown; open Chat or Teams from the app bar first",
		);
	return groups.map((g) => ({
		group: firstLine(g),
		items: [...g.querySelectorAll('[role=treeitem][aria-level="2"]')]
			.map(firstLine)
			.filter(Boolean),
	}));
}

async function pageRead(all, maxChars) {
	const views = [
		[
			"thread",
			"channel-replies-viewport",
			"[data-tid=channel-replies-pane-message]",
		],
		["channel", "channel-pane-viewport", "[data-tid=channel-pane-message]"],
	];
	for (const [view, tid, selector] of views) {
		const v = document.querySelector(`[data-tid=${tid}]`);
		if (!v) continue;
		const read = (m) => readChannelMessage(m, maxChars);
		if (!all)
			return {
				view,
				title: document.title,
				messages: [...v.querySelectorAll(selector)].map(read),
			};
		const settledAtTop = await settleTop(tid);
		return {
			view,
			title: document.title,
			settledAtTop,
			...(await sweep(tid, selector, read)),
		};
	}
	const items = document.querySelectorAll("[data-tid=chat-pane-item]");
	if (!items.length) throw new Error("no chat, channel, or thread is open");
	if (all)
		throw new Error(
			"--all supports channel and thread views; in a chat, scroll up to load older messages and read again",
		);
	const messages = [];
	let author = null;
	for (const item of items) {
		// Teams shows the author only on the first message of each run.
		const a = item.querySelector("[data-tid=message-author-name]");
		if (a) author = a.innerText.trim();
		const m = item.querySelector("[data-tid=chat-pane-message]");
		if (!m) continue;
		const body = clip(
			clean(
				m.querySelector("[id^=content-], [data-tid=message-body-content]") ?? m,
			),
			maxChars,
		);
		messages.push({
			author,
			time: item.querySelector("time")?.getAttribute("datetime") ?? null,
			body: body.text,
			...(body.truncated && { truncated: true }),
		});
	}
	return { view: "chat", title: document.title, messages };
}

function pageMarkCards() {
	for (const c of document.querySelectorAll("[data-tid=search-card]"))
		c.dataset.teamsCdpSeen = "1";
}

async function pageSearch(query) {
	if (!pageSetInput("[data-tid=AUTOSUGGEST_INPUT]", query, true))
		throw new Error("the search box did not take the query");
	const tab = await waitFor(
		() => document.querySelector("[data-tid=messages-tab]"),
		15000,
	);
	if (!tab) throw new Error("search results did not open");
	tab.click();
	await pageAwaitFreshCards("search results");
}

async function pageOpenScope() {
	const f = document.querySelector("[data-tid=search-team-and-channel-filter]");
	if (!f) throw new Error('the search "In" filter is missing');
	(f.querySelector("button") ?? f).click();
	if (
		!(await waitFor(
			() =>
				isVisible(document.querySelector("[data-tid=people-picker-search]")),
			5000,
		))
	) {
		throw new Error('the "In" filter picker did not open');
	}
	if (!pageSetInput("[data-tid=people-picker-search]", "", false))
		throw new Error('the "In" filter picker did not take input');
}

async function pagePickScope(name, team) {
	if (!pageSetInput("[data-tid=people-picker-search]", name, false))
		throw new Error('the "In" filter picker did not take the name');
	const want = name.toLowerCase();
	// Option labels read "<chat or channel><team>", so --team narrows
	// same-named channels such as General.
	const inTeam = (o) =>
		!team || oneLine(o.innerText).toLowerCase().includes(team.toLowerCase());
	// The picker shows a "Loading..." option first, so wait for a match.
	await waitFor(
		() =>
			[...document.querySelectorAll("[role=option]")].some(
				(o) =>
					isVisible(o) && oneLine(o.innerText).toLowerCase().includes(want),
			),
		10000,
	);
	const options = [...document.querySelectorAll("[role=option]")].filter(
		isVisible,
	);
	const labels = options.map((o) => oneLine(o.innerText));
	const exact = options.filter(
		(o) => firstLine(o).toLowerCase() === want && inTeam(o),
	);
	const partial = options.filter(
		(o) => oneLine(o.innerText).toLowerCase().includes(want) && inTeam(o),
	);
	const pick =
		exact.length === 1 ? exact[0] : partial.length === 1 ? partial[0] : null;
	if (!pick)
		return {
			error: exact.length > 1 || partial.length > 1 ? "ambiguous" : "missing",
			options: labels,
		};
	const chosen = firstLine(pick);
	const label = oneLine(pick.innerText);
	pick.click();
	const applied = await waitFor(
		() =>
			document
				.querySelector("[data-tid=search-filters]")
				?.innerText.includes(chosen),
		8000,
	);
	if (!applied) return { error: "not-applied", options: labels };
	await pageAwaitFreshCards("scoped results");
	return { scope: label };
}

async function pageCollect(maxPages) {
	const layout = document.querySelector("[data-tid=search-layout]");
	if (!layout) throw new Error("the search results layout is missing");
	const cards = () => [...layout.querySelectorAll("[data-tid=search-card]")];
	const scroller = () => {
		let e = cards()[0];
		while (
			e &&
			e !== layout &&
			!(
				/(auto|scroll)/.test(getComputedStyle(e).overflowY) &&
				e.scrollHeight > e.clientHeight
			)
		)
			e = e.parentElement;
		return e === layout ? null : e;
	};
	// Only the pager inside the results layout counts, so another surface's Next
	// button is never clicked.
	const nextButton = () =>
		[...layout.querySelectorAll("button")].find(
			(b) =>
				b.innerText.trim() === "Next" &&
				isVisible(b) &&
				!b.disabled &&
				b.getAttribute("aria-disabled") !== "true",
		);
	// A page renders a few cards and loads the rest as the list scrolls.
	const loadPage = async () => {
		for (let i = 0, last = -1, stable = 0; i < 40 && stable < 3; i++) {
			await assertRendering();
			const e = scroller();
			if (!e) return;
			e.scrollTop = e.scrollHeight;
			e.dispatchEvent(new Event("scroll"));
			await sleep(1200);
			const n = cards().length;
			stable = n === last ? stable + 1 : 0;
			last = n;
		}
	};
	const results = [];
	let page = 1;
	let more = false;
	for (;;) {
		await loadPage();
		if (layout.querySelector("[data-tid=search-card][data-teams-cdp-seen]"))
			throw new Error("stale results from an earlier search are still shown");
		for (const c of cards()) results.push({ page, text: oneLine(c.innerText) });
		const next = nextButton();
		if (!next) break;
		if (page >= maxPages) {
			more = true;
			break;
		}
		const first = cards()[0]?.innerText;
		next.click();
		// The list empties while the next page loads, so wait for a new first
		// card rather than any change.
		const advanced = await waitFor(() => {
			const t = cards()[0]?.innerText;
			return t && t !== first;
		}, 15000);
		if (!advanced) throw new Error(`results page ${page + 1} did not load`);
		await sleep(1500);
		page++;
	}
	await assertRendering();
	return {
		filters:
			oneLine(document.querySelector("[data-tid=search-filters]")?.innerText) ||
			null,
		pages: page,
		more,
		count: results.length,
		results,
	};
}

async function frameListFiles(site, pageSize) {
	const headers = { accept: "application/json;odata=nometadata" };
	const get = async (url) => {
		const r = await fetch(url, { headers });
		if (!r.ok) throw new Error(`HTTP ${r.status} for ${url}`);
		return r.json();
	};
	const lists = await get(
		`${site}/_api/web/lists?$filter=BaseTemplate eq 101 and Hidden eq false&$select=Id,Title`,
	);
	const files = [];
	for (const list of lists.value) {
		let url = `${site}/_api/web/lists(guid'${list.Id}')/items?$select=FileRef,FSObjType,Created,Modified,Author/Title,Editor/Title&$expand=Author,Editor&$top=${pageSize}`;
		while (url) {
			const r = await get(url);
			for (const i of r.value) {
				if (i.FSObjType !== 0) continue;
				files.push({
					library: list.Title,
					path: i.FileRef,
					relativePath: i.FileRef.startsWith(`${site}/`)
						? i.FileRef.slice(site.length + 1)
						: i.FileRef,
					created: i.Created,
					modified: i.Modified,
					author: i.Author?.Title ?? null,
					editor: i.Editor?.Title ?? null,
				});
			}
			url = r["odata.nextLink"] ?? null;
		}
	}
	return files.sort((a, b) => a.path.localeCompare(b.path));
}

async function frameDownload(path) {
	// Encode each segment; encodeURI leaves "#" alone and SharePoint allows it
	// in file names, which would truncate the request path.
	const url = path.split("/").map(encodeURIComponent).join("/");
	try {
		const r = await fetch(url);
		if (!r.ok) return { status: r.status };
		const b = new Uint8Array(await r.arrayBuffer());
		let s = "";
		for (let i = 0; i < b.length; i += 0x8000)
			s += String.fromCharCode(...b.subarray(i, i + 0x8000));
		return { status: r.status, data: btoa(s) };
	} catch (err) {
		return { status: 0, error: String(err) };
	}
}

// ---- CDP client ----

async function listTargets() {
	let res;
	try {
		res = await fetch(`http://127.0.0.1:${port}/json/list`);
	} catch {
		throw new CliError(
			EXIT.unavailable,
			`no CDP endpoint on 127.0.0.1:${port}; start Teams with --remote-debugging-port=${port}`,
		);
	}
	if (!res.ok)
		throw new CliError(
			EXIT.unavailable,
			`CDP endpoint returned HTTP ${res.status}`,
		);
	return res.json();
}

async function connect(pattern, types) {
	const target = (await listTargets()).find(
		(t) => types.includes(t.type) && pattern.test(t.url),
	);
	if (!target)
		throw new CliError(
			EXIT.unavailable,
			`no ${types.join(" or ")} target matches ${pattern}`,
		);
	const ws = new WebSocket(target.webSocketDebuggerUrl);
	await new Promise((res, rej) => {
		ws.onopen = res;
		ws.onerror = () =>
			rej(new CliError(EXIT.unavailable, "could not open the CDP WebSocket"));
	});
	let id = 0;
	const pending = new Map();
	ws.onmessage = ({ data }) => {
		const m = JSON.parse(data);
		const p = pending.get(m.id);
		if (!p) return;
		pending.delete(m.id);
		if (m.error)
			p.reject(new CliError(EXIT.page, `${m.error.message} (${m.error.code})`));
		else p.resolve(m.result);
	};
	ws.onclose = () => {
		for (const p of pending.values())
			p.reject(new CliError(EXIT.page, "CDP connection closed"));
		pending.clear();
	};
	const send = (method, params = {}) =>
		new Promise((resolve, reject) => {
			pending.set(++id, { resolve, reject });
			ws.send(JSON.stringify({ id, method, params }));
		});
	const evaluate = async (expression, { stack = false } = {}) => {
		const r = await send("Runtime.evaluate", {
			expression,
			awaitPromise: true,
			returnByValue: true,
		});
		if (r.exceptionDetails) {
			const full =
				r.exceptionDetails.exception?.description ?? r.exceptionDetails.text;
			const message = full.split("\n")[0].replace(/^Error: /, "");
			const tag = Object.keys(PAGE_ERROR_CODES).find((t) =>
				message.startsWith(t),
			);
			throw new CliError(
				tag ? PAGE_ERROR_CODES[tag] : EXIT.page,
				stack ? full : message,
			);
		}
		return r.result?.value;
	};
	return { send, evaluate, close: () => ws.close() };
}

async function withTarget(pattern, types, fn) {
	const page = await connect(pattern, types);
	try {
		return await fn(page);
	} finally {
		page.close();
	}
}

const withTeams = (fn) => withTarget(TEAMS_URL, ["page"], fn);
const withSharePoint = (fn) => withTarget(SHAREPOINT_FRAME_URL, ["iframe"], fn);

async function refuseUnlessDrivable(page) {
	if (await page.evaluate(pageCall(pageInCall))) {
		throw new CliError(
			EXIT.call,
			"a Teams call is in progress; driving the window would pull the user out of the meeting view, so retry after the call ends",
		);
	}
	if (!(await page.evaluate(pageCall(pageRendering)))) {
		throw new CliError(
			EXIT.hidden,
			"the Teams window is not rendering (hidden workspace or minimized), so results would load only partly; ask the user to show it on screen and retry",
		);
	}
}

// ---- commands ----

function parseOptions(args, spec) {
	const opts = {};
	const rest = [];
	for (let i = 0; i < args.length; i++) {
		const a = args[i];
		if (!a.startsWith("--") || a === "--") {
			rest.push(a);
			continue;
		}
		const name = a.slice(2);
		if (!(name in spec)) throw new CliError(EXIT.usage, `unknown option ${a}`);
		if (spec[name] === "flag") opts[name] = true;
		else if (i + 1 >= args.length)
			throw new CliError(EXIT.usage, `${a} needs a value`);
		else opts[name] = args[++i];
	}
	return { opts, rest };
}

function positiveInt(value, name, fallback) {
	if (value === undefined) return fallback;
	const n = Number(value);
	if (!Number.isInteger(n) || n < 1)
		throw new CliError(EXIT.usage, `--${name} must be a positive integer`);
	return n;
}

function safeUrl(url) {
	// Drop query strings and fragments, which can carry auth codes or tokens.
	try {
		const u = new URL(url);
		return `${u.protocol}//${u.host}${u.pathname}`;
	} catch {
		return null;
	}
}

async function status() {
	const targets = await listTargets();
	const teams = targets.find((t) => t.type === "page" && TEAMS_URL.test(t.url));
	const sharePoint = targets.find(
		(t) => t.type === "iframe" && SHAREPOINT_FRAME_URL.test(t.url),
	);
	const report = {
		endpoint: `127.0.0.1:${port}`,
		teamsPage: teams ? safeUrl(teams.url) : null,
		sharePointFrame: sharePoint ? safeUrl(sharePoint.url) : null,
		frames: targets
			.filter((t) => t.type === "page" || t.type === "iframe")
			.map((t) => ({ type: t.type, url: safeUrl(t.url) })),
	};
	if (teams)
		report.page = await withTeams((page) =>
			page.evaluate(pageCall(pageStatus)),
		);
	print(report);
	if (!teams) throw new CliError(EXIT.unavailable, "Teams page not loaded yet");
}

async function search(args) {
	const { opts, rest } = parseOptions(args, {
		in: "value",
		team: "value",
		"max-pages": "value",
	});
	if (rest.length !== 1 || !rest[0].trim())
		throw new CliError(EXIT.usage, "search needs exactly one query argument");
	if (opts.team && !opts.in)
		throw new CliError(EXIT.usage, "--team only narrows --in");
	const maxPages = positiveInt(opts["max-pages"], "max-pages", 10);
	const out = await withTeams(async (page) => {
		await refuseUnlessDrivable(page);
		await page.evaluate(pageCall(pageMarkCards));
		await page.evaluate(pageCall(pageSearch, rest[0]));
		let scope = null;
		if (opts.in) {
			await page.evaluate(pageCall(pageOpenScope));
			await page.evaluate(pageCall(pageMarkCards));
			const picked = await page.evaluate(
				pageCall(pagePickScope, opts.in, opts.team ?? null),
			);
			if (picked.error) {
				print({ error: picked.error, in: opts.in, options: picked.options });
				const hint =
					picked.error === "not-applied"
						? "the filter did not take effect; rerun the search"
						: "retry with an exact name from the listed options, adding --team for same-named channels";
				throw new CliError(
					EXIT.scope,
					`--in "${opts.in}" is ${picked.error}; ${hint}`,
				);
			}
			scope = picked.scope;
		}
		return {
			query: rest[0],
			scope,
			...(await page.evaluate(pageCall(pageCollect, maxPages))),
		};
	});
	print(out);
}

const CACHE_KINDS = ["chat", "channel", "meeting", "community", "other"];

async function cacheList(args) {
	const { opts, rest } = parseOptions(args, {
		kind: "value",
		name: "value",
		team: "value",
	});
	if (rest.length)
		throw new CliError(EXIT.usage, "cache-list takes no positional arguments");
	if (opts.kind && !CACHE_KINDS.includes(opts.kind))
		throw new CliError(
			EXIT.usage,
			`--kind must be one of ${CACHE_KINDS.join(", ")}`,
		);
	print(
		await withTeams((page) =>
			page.evaluate(
				pageCall(
					pageCacheList,
					opts.kind ?? null,
					opts.name ?? null,
					opts.team ?? null,
				),
			),
		),
	);
}

function isoTime(value, name) {
	if (value === undefined) return null;
	const t = Date.parse(value);
	if (Number.isNaN(t))
		throw new CliError(EXIT.usage, `--${name} must be an ISO date or time`);
	return t;
}

async function cacheRead(args) {
	const { opts, rest } = parseOptions(args, {
		team: "value",
		from: "value",
		thread: "value",
		since: "value",
		until: "value",
		limit: "value",
		"all-types": "flag",
		body: "flag",
		"max-chars": "value",
	});
	if (rest.length !== 1 || !rest[0].trim())
		throw new CliError(
			EXIT.usage,
			"cache-read needs one conversation name or id",
		);
	const limit = positiveInt(opts.limit, "limit", 500);
	if (limit > 5000)
		throw new CliError(EXIT.usage, "--limit must be 5000 or less");
	const query = {
		conversation: rest[0],
		team: opts.team ?? null,
		from: opts.from ?? null,
		thread: opts.thread ?? null,
		since: isoTime(opts.since, "since"),
		until: isoTime(opts.until, "until"),
		limit,
		allTypes: !!opts["all-types"],
		body: !!opts.body,
		maxChars: positiveInt(opts["max-chars"], "max-chars", 4000),
	};
	const out = await withTeams((page) =>
		page.evaluate(pageCall(pageCacheRead, query)),
	);
	print(out);
	if (out.error)
		throw new CliError(
			EXIT.scope,
			`${out.error}; retry with an id or exact name from the candidates`,
		);
}

async function readCommand(args) {
	const { opts, rest } = parseOptions(args, {
		all: "flag",
		"max-chars": "value",
	});
	if (rest.length)
		throw new CliError(EXIT.usage, "read takes no positional arguments");
	const maxChars = positiveInt(opts["max-chars"], "max-chars", 4000);
	print(
		await withTeams(async (page) => {
			if (opts.all) await refuseUnlessDrivable(page);
			return page.evaluate(pageCall(pageRead, !!opts.all, maxChars));
		}),
	);
}

async function spList(args) {
	if (args.length !== 1 || !args[0].startsWith("/")) {
		throw new CliError(
			EXIT.usage,
			"sp-list needs one server-relative site path such as /teams/ExampleSite",
		);
	}
	const site = args[0].replace(/\/+$/, "");
	print(
		await withSharePoint((frame) =>
			frame.evaluate(pageCall(frameListFiles, site, 500)),
		),
	);
}

async function spDownload(args) {
	const { opts, rest } = parseOptions(args, { force: "flag" });
	const [outdir, ...paths] = rest;
	if (!outdir || !paths.length)
		throw new CliError(
			EXIT.usage,
			"sp-download needs <outdir> and at least one path",
		);
	for (const p of paths) {
		if (!p.startsWith("/") || p.split("/").includes("..")) {
			throw new CliError(
				EXIT.usage,
				`path must be server-relative without "..": ${p}`,
			);
		}
	}
	const root = resolve(outdir);
	const plan = paths.map((p) => ({ path: p, file: join(root, p.slice(1)) }));
	const existing = plan.filter((x) => existsSync(x.file));
	if (existing.length && !opts.force) {
		throw new CliError(
			EXIT.usage,
			`refusing to overwrite without --force: ${existing.map((x) => x.file).join(", ")}`,
		);
	}
	// Exports hold work data, so keep new directories and files private.
	mkdirSync(root, { recursive: true, mode: 0o700 });
	let failed = 0;
	const results = await withSharePoint(async (frame) => {
		const out = [];
		for (const { path, file } of plan) {
			const r = await frame.evaluate(pageCall(frameDownload, path));
			if (typeof r.data !== "string") {
				failed++;
				out.push({
					path,
					status: r.status,
					...(r.error && { error: r.error }),
				});
				continue;
			}
			try {
				const bytes = Buffer.from(r.data, "base64");
				mkdirSync(dirname(file), { recursive: true, mode: 0o700 });
				// "wx" fails if the file appeared after the upfront check.
				writeFileSync(file, bytes, {
					mode: 0o600,
					flag: opts.force ? "w" : "wx",
				});
				out.push({ path, status: r.status, file, bytes: bytes.length });
			} catch (err) {
				failed++;
				out.push({ path, status: r.status, error: err.message });
			}
		}
		return out;
	});
	print(results);
	if (failed)
		throw new CliError(
			EXIT.page,
			`${failed} of ${plan.length} downloads failed`,
		);
}

async function evalCommand(args) {
	const { opts, rest } = parseOptions(args, { target: "value" });
	if (rest.length !== 1)
		throw new CliError(EXIT.usage, "eval needs one expression, @file, or -");
	const [src] = rest;
	const expression =
		src === "-"
			? readFileSync(0, "utf8")
			: src.startsWith("@")
				? readFileSync(src.slice(1), "utf8")
				: src;
	const run = (page) => page.evaluate(expression, { stack: true });
	const value = opts.target
		? await withTarget(new RegExp(opts.target), ["page", "iframe"], run)
		: await withTeams(run);
	if (typeof value === "string") console.log(value);
	else print(value ?? null);
}

function print(value) {
	console.log(JSON.stringify(value, null, 2));
}

const COMMANDS = {
	status,
	"cache-list": cacheList,
	"cache-read": cacheRead,
	search,
	sidebar: async (args) => {
		if (args.length)
			throw new CliError(EXIT.usage, "sidebar takes no arguments");
		print(await withTeams((page) => page.evaluate(pageCall(pageSidebar))));
	},
	read: readCommand,
	"sp-list": spList,
	"sp-download": spDownload,
	eval: evalCommand,
};

async function main() {
	const [command, ...args] = process.argv.slice(2);
	if (!command || command === "--help" || command === "-h") {
		console.error(USAGE);
		process.exit(command ? 0 : EXIT.usage);
	}
	if (!(command in COMMANDS))
		throw new CliError(EXIT.usage, `unknown command ${command}\n\n${USAGE}`);
	if (typeof WebSocket !== "function")
		throw new CliError(EXIT.page, "Node 22 or newer is required");
	await COMMANDS[command](args);
}

main().catch((err) => {
	console.error(`teams_cdp: ${err.message}`);
	process.exit(err instanceof CliError ? err.code : EXIT.page);
});
