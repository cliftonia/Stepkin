#!/usr/bin/env python3
"""Checks the Swift sources against docs/DOCUMENTATION.md.

Rules, each reported as `path:line: rule: detail`:
  header     every struct/class/enum/actor/protocol has a `///` header
  member     every non-private func/init has a `///` summary
  property   every non-private stored property of a type has a `///` line
  summary    a `///` block's first sentence ends with a period
  width      a comment line is at most 100 columns
  sentence   a `//` comment block ends with a period (or `)`, `?`, `!`)
  history    no dated or historical framing in a comment
  block      no `/** */` doc comments
Exits non-zero when anything is reported.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCES = [ROOT / "imon Watch App", ROOT / "SkykinComplication", ROOT / "Packages/StepkinKit/Sources"]
SKIP = ("Sprites/Pets/", "Sprites/Catalog/")
TYPE = re.compile(
    r"^(\s*)(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:nonisolated|final|private|fileprivate|public|internal|indirect)\s+)*"
    r"(struct|class|enum|actor|protocol)\s+(\w+)"
)
FUNC = re.compile(
    r"^(\s+)(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:static|class|nonisolated|mutating|override|final|isolated|public|internal)\s+)*"
    r"(func\s+\w+|init[?(<])"
)
PRIVATE = re.compile(r"\b(private|fileprivate)\b(?!\(set\))")
PROPERTY = re.compile(
    r"^(\s+)(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:static|nonisolated|weak|lazy|private\(set\)|public|internal)\s+)*"
    r"(let|var)\s+(\w+)\s*(?::|=)[^{]*$"
)
OPENER = re.compile(r"^\s{4}\S.*\{\s*$")
HISTORY = re.compile(r"\b(no longer|previously|recently|used to be|as of 20\d\d|AUDIT \d|TODO|FIXME|HACK)\b", re.I)
LINE_END = (".", ")", "?", "!", ":")

def has_doc(lines, i):
    j = i - 1
    while j >= 0 and (
        lines[j].strip().startswith(("@", "// swiftlint")) or lines[j].strip() == ""
    ):
        j -= 1
    return j >= 0 and lines[j].strip().startswith("///")

def check(path):
    lines = path.read_text().splitlines()
    rel = path.relative_to(ROOT)
    out = []
    nested_type = False
    i = 0
    while i < len(lines):
        line = lines[i]
        s = line.strip()
        if "/**" in s:
            out.append(f"{rel}:{i+1}: block: use ///")
        m = TYPE.match(line)
        if m and not has_doc(lines, i):
            out.append(f"{rel}:{i+1}: header: {m.group(2)} {m.group(3)} has no /// header")
        m = FUNC.match(line)
        if m and not PRIVATE.search(line) and not has_doc(lines, i):
            out.append(f"{rel}:{i+1}: member: {m.group(2).strip()} has no /// summary")
        if TYPE.match(line) and len(TYPE.match(line).group(1)) == 4:
            nested_type = not PRIVATE.search(line)
        elif OPENER.match(line) and not TYPE.match(line):
            nested_type = False
        m = PROPERTY.match(line)
        if m and not PRIVATE.search(line) and not has_doc(lines, i):
            indent = len(m.group(1))
            if indent == 4 or (indent == 8 and nested_type):
                out.append(f"{rel}:{i+1}: property: {m.group(3)} has no /// line")
        if s.startswith("///"):
            k = i
            while k + 1 < len(lines) and lines[k + 1].strip().startswith("///"):
                k += 1
            block = " ".join(x.strip()[3:].strip() for x in lines[i:k + 1])
            first = re.split(r"(?<=[.!?])\s", block)[0]
            if first and not first.endswith((".", "!", "?", ":")):
                out.append(f"{rel}:{i+1}: summary: first sentence lacks a period")
            for n in range(i, k + 1):
                if len(lines[n]) > 100:
                    out.append(f"{rel}:{n+1}: width: {len(lines[n])} columns")
                if HISTORY.search(lines[n]):
                    out.append(f"{rel}:{n+1}: history: dated or historical framing")
            i = k + 1
            continue
        if s.startswith("//") and not s.startswith("// MARK") and not s.startswith("// swiftlint"):
            k = i
            while k + 1 < len(lines) and lines[k + 1].strip().startswith("//") \
                    and not lines[k + 1].strip().startswith(("///", "// MARK", "// swiftlint")):
                k += 1
            block = " ".join(x.strip()[2:].strip() for x in lines[i:k + 1])
            if not block.endswith(LINE_END):
                out.append(f"{rel}:{i+1}: sentence: line comment does not end with a period")
            for n in range(i, k + 1):
                if len(lines[n]) > 100:
                    out.append(f"{rel}:{n+1}: width: {len(lines[n])} columns")
                if HISTORY.search(lines[n]):
                    out.append(f"{rel}:{n+1}: history: dated or historical framing")
            i = k + 1
            continue
        i += 1
    return out

def main():
    subtree = sys.argv[1] if len(sys.argv) > 1 else ""
    files = sorted(
        p for root in SOURCES for p in root.rglob("*.swift")
        if not any(x in str(p) for x in SKIP) and subtree in str(p)
    )
    findings = [f for p in files for f in check(p)]
    for f in findings:
        print(f)
    print(f"{len(findings)} findings in {len(files)} files")
    sys.exit(1 if findings else 0)

if __name__ == "__main__":
    main()
