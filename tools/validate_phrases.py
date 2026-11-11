"""Kiểm tra phrases.json: id trùng, thiếu trường,  tiếng Việt.

Chạy: python tools/validate_phrases.py   (thoát mã 1 nếu có lỗi nghiêm trọng)
"""
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
data = json.loads((ROOT / "Shared" / "phrases.json").read_text(encoding="utf-8"))
errors, warnings = [], []

for i, p in enumerate(data):
    for key in ("id", "hanzi", "pinyin", "readingVi", "meaningVi"):
        if not p.get(key):
            errors.append(f"dòng {i}: thiếu '{key}' (id={p.get('id')})")
    chars = sum(1 for c in p.get("hanzi", "") if "一" <= c <= "鿿")
    syllables = len(p.get("readingVi", "").replace("-", " ").split())
    if chars and chars != syllables:
        warnings.append(f"id {p.get('id')} {p.get('hanzi')}: {chars} chữ Hán nhưng cách đọc có {syllables} âm tiết")

for pid, n in Counter(p["id"] for p in data if "id" in p).items():
    if n > 1:
        errors.append(f"id {pid} bị trùng {n} lần")

topics = Counter(p.get("topic", "Khác") for p in data)
print(f"{len(data)} từ, {len(topics)} chủ đề, {len(errors)} lỗi, {len(warnings)} cảnh báo")
for w in warnings[:20]:
    print("  cảnh báo:", w)
for e in errors[:50]:
    print("  LỖI:", e)
sys.exit(1 if errors else 0)
