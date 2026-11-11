"""Tạo Shared/phrases-widget.json (bản gọn của phrases.json cho widget, nhẹ hơn ~3 lần).

Chạy: python tools/make_widget_json.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KEEP = ("id", "topic", "hanzi", "pinyin", "readingVi", "meaningVi", "hsk")

full = json.loads((ROOT / "Shared" / "phrases.json").read_text(encoding="utf-8"))
slim = [{k: p[k] for k in KEEP if k in p} for p in full]
out = json.dumps(slim, ensure_ascii=False, separators=(",", ":"))
(ROOT / "Shared" / "phrases-widget.json").write_text(out + "\n", encoding="utf-8")
print(f"{len(slim)} từ -> phrases-widget.json ({len(out.encode('utf-8')) // 1024} KB)")
