#!/usr/bin/env python3
"""Restore the human-readable dashboard source from the versioned gzip/base64 bundle.

Python standard library only. Run: python tools/rebuild_app.py
Option: python tools/rebuild_app.py --replace-app
"""
from pathlib import Path
import argparse
import base64
import gzip
import hashlib

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_SHA256 = "82783b6aba4dc2c384f2266548cfac188b9ad8cffc062e7473f8be014137a9e6"

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--replace-app", action="store_true",
                        help="Replace the prebuilt app.js with the readable source.")
    args = parser.parse_args()
    parts = [ROOT / "src" / f"app.part{i}.b64" for i in range(1, 7)]
    packed = "".join(path.read_text(encoding="ascii").strip() for path in parts)
    data = gzip.decompress(base64.b64decode(packed, validate=True))
    actual = hashlib.sha256(data).hexdigest()
    if actual != EXPECTED_SHA256:
        raise SystemExit(f"Source integrity check failed: {actual}")
    output = ROOT / ("app.js" if args.replace_app else "app.source.js")
    output.write_bytes(data)
    print(f"Restored readable dashboard source to {output} ({len(data)} bytes)")

if __name__ == "__main__":
    main()
