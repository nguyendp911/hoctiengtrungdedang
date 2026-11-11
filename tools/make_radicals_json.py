"""Tạo App/Resources/radicals.json: chữ Hán -> số bộ thủ Khang Hy (1-214).

Nguồn: trường kRSUnicode trong Unihan_IRGSources.txt (Unicode, giấy phép Unicode).
Tải https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip, giải nén rồi chạy:

    python tools/make_radicals_json.py path/to/Unihan_IRGSources.txt
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
src = Path(sys.argv[1])

radical = {}
for line in src.read_text(encoding="utf-8").splitlines():
    if not line.startswith("U+"):
        continue
    code, field, value = line.split("\t", 2)
    if field != "kRSUnicode":
        continue
    first = value.split()[0]            # ví dụ "149'.7" (dấu ' = dạng giản thể của bộ)
    no = int(first.split(".")[0].rstrip("'"))
    radical[chr(int(code[2:], 16))] = no

phrases = json.loads((ROOT / "Shared" / "phrases.json").read_text(encoding="utf-8"))
chars = sorted({c for p in phrases for c in p["hanzi"] if "\u4e00" <= c <= "\u9fff"})
out = {c: radical[c] for c in chars if c in radical}
missing = [c for c in chars if c not in radical]
target = ROOT / "App" / "Resources" / "radicals.json"
target.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
print(f"{len(out)} chữ -> {target.name}; thiếu {len(missing)}: {''.join(missing[:20])}")
