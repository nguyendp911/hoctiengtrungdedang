"""Thêm từ mới vào Shared/phrases.json từ file văn bản (mỗi dòng một từ, 8 trường cách nhau bởi dấu |):

    hanzi|pinyin|readingVi|hanViet|meaningVi|ví dụ (Hán)|ví dụ (pinyin)|ví dụ (nghĩa Việt)

    python tools/add_words.py <cấp HSK 1-7> words.txt           # xem trước
    python tools/add_words.py <cấp HSK 1-7> words.txt --write   # ghi vào phrases.json

Từ trùng chữ Hán với từ đã có thì bị bỏ qua. `id` tiếp theo id lớn nhất hiện có. Từ mới được
gom vào các bài ~40 từ, đánh số tiếp sau các bài sẵn có của cấp đó.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PHRASES = ROOT / "Shared" / "phrases.json"
CHUNK = 40


def main():
    level, src = int(sys.argv[1]), Path(sys.argv[2])
    write = "--write" in sys.argv
    topic = "HSK 7-9" if level == 7 else f"HSK {level}"
    data = json.loads(PHRASES.read_text(encoding="utf-8"))
    known = {p["hanzi"] for p in data}
    next_id = max(p["id"] for p in data) + 1
    unit_no = max((p.get("unitNo") or 0 for p in data if p["topic"] == topic), default=0)

    rows, skipped = [], []
    for line in src.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        f = line.split("|")
        if len(f) != 8:
            sys.exit(f"Dòng sai định dạng ({len(f)} trường): {line[:50]}")
        if f[0] in known:
            skipped.append(f[0])
            continue
        known.add(f[0])
        rows.append(f)

    for i, f in enumerate(rows):
        if i % CHUNK == 0:
            unit_no += 1
        unit = f"Bổ sung theo chuẩn HSK 3.0 ({i // CHUNK + 1})"
        hanzi, pinyin, reading, han_viet, meaning, zh, zh_py, zh_vi = f
        data.append({
            "id": next_id + i, "topic": topic, "hanzi": hanzi, "pinyin": pinyin, "readingVi": reading,
            "hanViet": han_viet, "meaningVi": meaning, "unitNo": unit_no, "unit": unit,
            "example": {"zh": zh, "pinyin": zh_py, "vi": zh_vi},
        })

    print(f"{topic}: thêm {len(rows)} từ, bỏ qua {len(skipped)} từ đã có {skipped[:10]}")
    if write:
        out = [json.dumps(p, ensure_ascii=False, separators=(", ", ": ")) for p in data]
        PHRASES.write_text("[\n  " + ",\n  ".join(out) + "\n]\n", encoding="utf-8")
        print("đã ghi", PHRASES.name)


if __name__ == "__main__":
    main()
