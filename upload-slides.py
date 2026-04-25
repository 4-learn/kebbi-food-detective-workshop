#!/usr/bin/env python3
"""Upload group's slide markdown to HackMD + append link to 簡報大集合.

Usage: python3 upload-slides.py <group-name> <slides-file>
Env:   HACKMD_API_TOKEN required
"""
import json
import os
import sys
import urllib.request

COLLECTION_INTERNAL_ID = "V3gOWDGXQpKPYEmLYsZ7Ng"
COLLECTION_ALIAS = "Hy-okxqT-l"
END_MARKER = "<!-- STUDENT_SLIDES_END -->"


def _api(method, path, token, body=None):
    req = urllib.request.Request(
        f"https://api.hackmd.io{path}",
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        if r.status >= 200 and r.status < 300:
            data = r.read().decode()
            return json.loads(data) if data else None
    return None


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <group> <slides-file>", file=sys.stderr)
        sys.exit(1)
    group, slides_file = sys.argv[1], sys.argv[2]

    token = os.environ.get("HACKMD_API_TOKEN")
    if not token:
        print("ERROR: HACKMD_API_TOKEN not set in env", file=sys.stderr)
        sys.exit(1)

    if not os.path.isfile(slides_file):
        print(f"ERROR: file not found: {slides_file}", file=sys.stderr)
        sys.exit(1)

    with open(slides_file, encoding="utf-8") as f:
        content = f.read()

    # 1. POST new slide note
    title = f"{group} 簡報 — Vibe Coding"
    new_note = _api("POST", "/v1/notes", token, {
        "title": title,
        "content": content,
        "readPermission": "guest",
        "writePermission": "owner",
        "commentPermission": "disabled",
    })
    short_id = new_note["shortId"]
    note_url = f"https://hackmd.io/@yillkid/{short_id}"
    print(f"✓ 簡報已上傳：{note_url}")

    # 2. PATCH collection note to append link
    coll = _api("GET", f"/v1/notes/{COLLECTION_INTERNAL_ID}", token)
    coll_content = coll["content"]

    new_link = f"- 🎤 **{group}**: [{title}]({note_url})"

    if note_url in coll_content:
        print("⚠ 已在大集合內，沒重覆 append")
    else:
        if END_MARKER not in coll_content:
            print(f"ERROR: 大集合 note 找不到 marker: {END_MARKER}", file=sys.stderr)
            sys.exit(2)
        coll_content = coll_content.replace(END_MARKER, f"{new_link}\n{END_MARKER}")
        _api("PATCH", f"/v1/notes/{COLLECTION_INTERNAL_ID}", token,
             {"content": coll_content})
        print(f"✓ 已加進「簡報大集合」: https://hackmd.io/@yillkid/{COLLECTION_ALIAS}")


if __name__ == "__main__":
    main()
