import os
import plistlib
from plistlib import UID


def load(path):
    with open(path, "rb") as handle:
        return plistlib.load(handle)


def dump(path, value):
    with open(path, "wb") as handle:
        plistlib.dump(value, handle, fmt=plistlib.FMT_BINARY, sort_keys=False)


def class_name(objects, value):
    if not isinstance(value, UID):
        return None

    candidate = objects[value.data]
    if not isinstance(candidate, dict):
        return None

    name = candidate.get("$classname")
    return name if isinstance(name, str) else None


def resolve(objects, value):
    if isinstance(value, UID):
        return objects[value.data]
    return value


def find_stale_rule_indices(main_plist):
    objects = main_plist["$objects"]
    stale_rules = []

    for index, obj in enumerate(objects):
        if not isinstance(obj, dict):
            continue
        if class_name(objects, obj.get("$class")) != "NEPathRule":
            continue

        path = resolve(objects, obj.get("Path"))
        signing_identifier = resolve(objects, obj.get("SigningIdentifier"))
        if not isinstance(path, str):
            continue
        if not path.startswith("/nix/store/"):
            continue
        if os.path.exists(path):
            continue

        stale_rules.append((index, signing_identifier))

    return stale_rules


def rewrite_value(value, removed_indices):
    if isinstance(value, UID):
        return UID(0) if value.data in removed_indices else value

    if isinstance(value, list):
        rewritten = []
        for item in value:
            if isinstance(item, UID) and item.data in removed_indices:
                continue
            rewritten.append(rewrite_value(item, removed_indices))
        return rewritten

    if isinstance(value, dict):
        return {
            key: rewrite_value(item, removed_indices) for key, item in value.items()
        }

    return value


def reachable_indices(main_plist):
    objects = main_plist["$objects"]
    reachable = {0}
    stack = []

    def enqueue(value):
        if isinstance(value, UID):
            stack.append(value.data)
            return
        if isinstance(value, list):
            for item in value:
                enqueue(item)
            return
        if isinstance(value, dict):
            for item in value.values():
                enqueue(item)

    enqueue(main_plist["$top"])

    while stack:
        index = stack.pop()
        if index in reachable:
            continue
        reachable.add(index)
        enqueue(objects[index])

    return reachable


def remap_value(value, index_map):
    if isinstance(value, UID):
        return UID(index_map[value.data])

    if isinstance(value, list):
        return [remap_value(item, index_map) for item in value]

    if isinstance(value, dict):
        return {key: remap_value(item, index_map) for key, item in value.items()}

    return value


def compact_main_plist(main_plist):
    reachable = sorted(reachable_indices(main_plist))
    index_map = {old: new for new, old in enumerate(reachable)}

    return {
        "$archiver": main_plist["$archiver"],
        "$version": main_plist["$version"],
        "$top": remap_value(main_plist["$top"], index_map),
        "$objects": [
            remap_value(main_plist["$objects"][old], index_map) for old in reachable
        ],
    }


def surviving_signing_identifiers(main_plist):
    objects = main_plist["$objects"]
    identifiers = set()

    for obj in objects:
        if not isinstance(obj, dict):
            continue
        if class_name(objects, obj.get("$class")) != "NEPathRule":
            continue

        signing_identifier = resolve(objects, obj.get("SigningIdentifier"))
        path = resolve(objects, obj.get("Path"))
        if isinstance(signing_identifier, str) and isinstance(path, str):
            identifiers.add(signing_identifier)

    return identifiers


def prune_uuid_cache(uuid_cache_plist, removed_identifiers, surviving_identifiers):
    updated = dict(uuid_cache_plist)

    for key in ("uuid-mappings", "synthesized-uuid-mappings"):
        mappings = dict(updated.get(key, {}))
        for identifier in removed_identifiers:
            if identifier in surviving_identifiers:
                continue
            mappings.pop(identifier, None)
        updated[key] = mappings

    return updated


def write_summary(message):
    with open(
        os.environ["KHANELINIX_NETWORK_EXTENSION_SUMMARY"],
        "w",
        encoding="utf-8",
    ) as handle:
        handle.write(message)


def main():
    main_plist = load(os.environ["KHANELINIX_NETWORK_EXTENSION_PLIST"])
    uuid_cache_plist = load(os.environ["KHANELINIX_NETWORK_EXTENSION_UUID_CACHE"])

    stale_rules = find_stale_rule_indices(main_plist)
    removed_indices = {index for index, _ in stale_rules}
    removed_identifiers = {
        identifier for _, identifier in stale_rules if isinstance(identifier, str)
    }

    with open(
        os.environ["KHANELINIX_NETWORK_EXTENSION_CHANGED"],
        "w",
        encoding="utf-8",
    ) as handle:
        if not removed_indices:
            handle.write("0")
            write_summary("No stale Local Network permission entries found.")
            return

        rewritten_main = dict(main_plist)
        rewritten_main["$objects"] = [
            rewrite_value(obj, removed_indices) for obj in main_plist["$objects"]
        ]
        rewritten_main["$top"] = rewrite_value(main_plist["$top"], removed_indices)

        compacted_main = compact_main_plist(rewritten_main)
        surviving_identifiers = surviving_signing_identifiers(compacted_main)
        cleaned_uuid_cache = prune_uuid_cache(
            uuid_cache_plist,
            removed_identifiers,
            surviving_identifiers,
        )

        dump(os.environ["KHANELINIX_NETWORK_EXTENSION_PLIST_OUT"], compacted_main)
        dump(
            os.environ["KHANELINIX_NETWORK_EXTENSION_UUID_CACHE_OUT"],
            cleaned_uuid_cache,
        )

        load(os.environ["KHANELINIX_NETWORK_EXTENSION_PLIST_OUT"])
        load(os.environ["KHANELINIX_NETWORK_EXTENSION_UUID_CACHE_OUT"])

        handle.write("1")
        write_summary(
            "Pruned "
            + str(len(removed_indices))
            + " stale Local Network path rules for "
            + (", ".join(sorted(removed_identifiers)) or "unknown identifiers")
        )


if __name__ == "__main__":
    main()
