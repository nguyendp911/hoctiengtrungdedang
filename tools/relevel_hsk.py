"""Xếp lại cấp HSK của Shared/phrases.json theo danh sách HSK 3.0 chính thức.

Dữ liệu chuẩn: hsk30.csv của https://github.com/ivankra/hsk30 (tải về một thư mục riêng).

    python tools/relevel_hsk.py hsk30.csv            # xem thống kê, không ghi file
    python tools/relevel_hsk.py hsk30.csv --write    # ghi lại phrases.json

Quy tắc (giữ nguyên `id`, nên tiến độ học của người dùng không mất):
- Từ có trong danh sách chính thức: chuyển về đúng cấp. Từ đổi cấp được gom vào bài mới
  ở cấp đích (mỗi bài khoảng 40 từ, tên theo chủ đề cũ phổ biến nhất), đánh số tiếp sau các bài sẵn có.
- Từ HSK không có trong danh sách chính thức: chuyển sang chủ đề "Ngoài HSK 3.0".
- Từ thuộc chủ đề thường (Giao tiếp, Ăn uống...) có trường `hsk`: cập nhật theo chuẩn, không có thì bỏ `hsk`.
"""
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PHRASES = ROOT / "Shared" / "phrases.json"
LEVEL_NUM = {"1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7-9": 7}
EXTRA_TOPIC = "Ngoài HSK 3.0"
CHUNK = 40


def forms(cell):
    """Các dạng viết của một mục: 'A|B' và 'A（B）' đều tách ra để khớp."""
    out = set()
    for w in cell.split("|"):
        w = w.strip()
        out.add(w)
        m = re.match(r"^(.*?)（(.*)）(.*)$", w)
        if m:
            out.add(m.group(1) + m.group(3))
            out.add(m.group(2))
    return {x for x in out if x}


def official_levels(csv_path):
    levels = {}
    for row in csv.DictReader(open(csv_path, encoding="utf-8")):
        lv = LEVEL_NUM[row["Level"]]
        for f in forms(row["Simplified"]):
            if f not in levels or lv < levels[f]:  # từ xuất hiện nhiều cấp: lấy cấp thấp nhất
                levels[f] = lv
    return levels


def level_of(p):
    if p.get("hsk"):
        return p["hsk"]
    t = p["topic"]
    if t == "HSK 7-9":
        return 7
    if t.startswith("HSK ") and t[4:].isdigit():
        return int(t[4:])
    return None


def topic_of(level):
    return "HSK 7-9" if level == 7 else f"HSK {level}"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    off = official_levels(sys.argv[1])
    write = "--write" in sys.argv
    lines = PHRASES.read_text(encoding="utf-8").splitlines()
    data = json.loads(PHRASES.read_text(encoding="utf-8"))

    max_unit = defaultdict(int)  # số bài lớn nhất hiện có ở mỗi cấp
    for p in data:
        lv = level_of(p)
        if lv and p["topic"].startswith("HSK") and p.get("unitNo"):
            max_unit[lv] = max(max_unit[lv], p["unitNo"])

    stats = defaultdict(int)
    moved = defaultdict(list)  # (cấp đích, tên bài cũ) -> các từ
    for p in data:
        lv = level_of(p)
        if lv is None:
            continue
        target = off.get(p["hanzi"])
        in_hsk_topic = p["topic"].startswith("HSK")
        if target is None:
            stats["ngoài chuẩn"] += 1
            if in_hsk_topic:
                p["topic"] = EXTRA_TOPIC
                p.pop("unitNo", None)
                p.pop("unit", None)
            p.pop("hsk", None)
        elif not in_hsk_topic:
            stats["chủ đề thường"] += 1
            p["hsk"] = target
        elif target == lv:
            stats["giữ nguyên"] += 1
        else:
            stats["đổi cấp"] += 1
            moved[(target, p.get("unit") or "Từ bổ sung")].append(p)

    # Gom theo cấp đích, giữ thứ tự theo bài cũ để chủ đề gần nhau nằm cạnh nhau,
    # rồi cắt thành bài ~CHUNK từ; tên bài lấy theo chủ đề cũ phổ biến nhất trong bài.
    by_target = defaultdict(list)
    for (target, unit_name), words in sorted(moved.items(), key=lambda kv: (kv[0][0], kv[0][1])):
        by_target[target].extend((unit_name, w) for w in words)
    for target, items in sorted(by_target.items()):
        for i in range(0, len(items), CHUNK):
            chunk = items[i:i + CHUNK]
            max_unit[target] += 1
            names = defaultdict(int)
            for unit_name, _ in chunk:
                names[unit_name] += 1
            name = max(names.items(), key=lambda kv: kv[1])[0]
            for _, p in chunk:
                p["topic"] = topic_of(target)
                p["unitNo"] = max_unit[target]
                p["unit"] = name
                p.pop("hsk", None)

    per_level = defaultdict(int)
    for p in data:
        if p["topic"].startswith("HSK"):
            per_level[p["topic"]] += 1
    print(dict(stats))
    print("số từ mỗi cấp sau khi xếp:", dict(sorted(per_level.items())))
    print("chủ đề mới 'Ngoài HSK 3.0':", sum(1 for p in data if p["topic"] == EXTRA_TOPIC))
    if write:
        out = [json.dumps(p, ensure_ascii=False, separators=(", ", ": ")) for p in data]
        text = "[\n  " + ",\n  ".join(out) + "\n]\n"
        PHRASES.write_text(text, encoding="utf-8")
        print("đã ghi", PHRASES)
    else:
        print("(chưa ghi file; thêm --write để ghi)")
        _ = lines


if __name__ == "__main__":
    main()
