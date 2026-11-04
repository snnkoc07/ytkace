#!/usr/bin/env python3

import pathlib
import plistlib
import sys


def enable_file_access(root: dict) -> None:
    root["MinimumOSVersion"] = "17.0"
    root["UIFileSharingEnabled"] = True
    root["LSSupportsOpeningDocumentsInPlace"] = True
    modes = root.get("UIBackgroundModes")
    if not isinstance(modes, list):
        modes = []
    if "audio" not in modes:
        modes.append("audio")
    root["UIBackgroundModes"] = modes


def main() -> int:
    if len(sys.argv) != 2:
        return 2
    path = pathlib.Path(sys.argv[1])
    with path.open("rb") as handle:
        root = plistlib.load(handle)
    enable_file_access(root)
    with path.open("wb") as handle:
        plistlib.dump(root, handle, fmt=plistlib.FMT_BINARY, sort_keys=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
