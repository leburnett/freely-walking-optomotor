#!/usr/bin/env python3
"""Render a pipeline schematic from a YAML layout file.

Usage:
    python render_schematic.py pipeline_layout.yaml
    python render_schematic.py pipeline_layout.yaml --open

Produces: data_flow_schematic.html (same directory as the YAML file).
"""

import sys
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML required.  Install with:  pip install pyyaml")


# ═══════════════════════════════════════════════════════════════════════
# Constants
# ═══════════════════════════════════════════════════════════════════════

COLORS = {
    "major":  "#3B6FA0",
    "script": "#5A8EBE",
    "output": "#7BADD4",
    "data":   "#f0f0f0",
}
TEXT_COLORS = {
    "major": "#fff", "script": "#fff", "output": "#fff", "data": "#555",
}
BADGE_COLORS = {"left": "#e8983e", "right": "#4caf50"}

# Layout grid
ROW_HEIGHT   = 40          # vertical spacing per row unit
COL_LEFT_X   = 25          # x origin for "left" nodes
COL_RIGHT_X  = 310         # x origin for "right" nodes
COL_CENTER_X = 140         # x origin for "center" / "full" nodes
NODE_W       = 210          # default node width
NODE_H       = 28           # default node height
NODE_W_WIDE  = 260          # wider for center/full nodes
NODE_W_NARROW = 140         # narrow width for downstream 3-across rows
PADDING_TOP  = 30           # top padding before row 0
SVG_WIDTH    = 580          # total SVG width
ANNOTATION_Y_OFFSET = -6   # annotation text offset above node

# Rows that use narrow 3-across layout (left/center/right all visible)
# Nodes on these rows get NODE_W_NARROW and repositioned to fit 3 columns
NARROW_ROWS = set()         # populated from YAML at runtime


# ═══════════════════════════════════════════════════════════════════════
# Geometry helpers
# ═══════════════════════════════════════════════════════════════════════

def node_rect(node):
    """Return (x, y, w, h) for a node dict."""
    side = node.get("side", "left")
    row  = node["row"]
    y = PADDING_TOP + row * ROW_HEIGHT

    if row in NARROW_ROWS:
        # 3-across layout: evenly space narrow nodes
        w = NODE_W_NARROW
        gap = (SVG_WIDTH - 3 * w) / 4   # equal gaps
        x_map = {
            "left":   gap,
            "center": 2 * gap + w,
            "right":  3 * gap + 2 * w,
        }
        x = x_map.get(side, gap)
    else:
        w = NODE_W_WIDE if side in ("center", "full") else NODE_W
        x_map = {"left": COL_LEFT_X, "right": COL_RIGHT_X,
                 "center": COL_CENTER_X, "full": COL_LEFT_X}
        x = x_map.get(side, COL_LEFT_X)

    return x, y, w, NODE_H


def center_of(node):
    x, y, w, h = node_rect(node)
    return x + w / 2, y + h / 2


def bottom_center(node):
    x, y, w, h = node_rect(node)
    return x + w / 2, y + h


def top_center(node):
    x, y, w, h = node_rect(node)
    return x + w / 2, y


def right_center(node):
    x, y, w, h = node_rect(node)
    return x + w, y + h / 2


def left_center(node):
    x, y, w, h = node_rect(node)
    return x, y + h / 2


def route_connection(from_node, to_node, dashed=False, all_nodes=None):
    """Build an orthogonal (right-angle only) SVG path between two nodes.

    Routing rules:
    1. Same column (side) → bottom of source, straight down to top of target.
    2. Left → Right (or Right → Left) on adjacent rows:
       exit RIGHT edge of source → horizontal → enter LEFT edge of target.
    3. Left → Right (or Right → Left) with gap:
       exit RIGHT edge of source → horizontal to a gutter x → down → horizontal
       to LEFT edge of target.
    4. Right → Left mirror of the above.
    5. Center ↔ Left/Right: exit bottom of source → down to a gap row → horizontal
       to target column → down to top of target.
    6. Long dashed "side channel" connections (e.g. LOG line): route along
       far-right gutter (SVG_WIDTH - 10) to avoid crossing other nodes.
    """
    f_side = from_node.get("side", "left")
    t_side = to_node.get("side", "left")
    f_row  = from_node["row"]
    t_row  = to_node["row"]

    fx, fy, fw, fh = node_rect(from_node)
    tx, ty, tw, th = node_rect(to_node)

    # Gap between rows where we can safely run a horizontal segment
    # (halfway between bottom of source row and top of target row)
    gap_y = fy + fh + (ty - fy - fh) / 2 if ty > fy + fh else (fy + fh + ty) / 2

    # ── Same column: straight vertical ──
    if f_side == t_side:
        sx, sy = fx + fw / 2, fy + fh   # bottom center
        ex, ey = tx + tw / 2, ty          # top center
        if abs(sx - ex) < 5:
            return f"M{sx},{sy} L{ex},{ey}"
        else:
            # Same side but different width (e.g. one is 'center')
            return f"M{sx},{sy} L{sx},{gap_y} L{ex},{gap_y} L{ex},{ey}"

    # ── Same row: horizontal ──
    if f_row == t_row:
        if fx < tx:
            sx, sy = fx + fw, fy + fh / 2  # right edge
            ex, ey = tx, ty + th / 2        # left edge
        else:
            sx, sy = fx, fy + fh / 2        # left edge
            ex, ey = tx + tw, ty + th / 2   # right edge
        return f"M{sx},{sy} L{ex},{ey}"

    # ── Cross-column with row gap ──
    # Determine if going left→right or right→left
    going_right = fx < tx  # source is to the left of target

    # For dashed long connections (like LOG side-channel), route along far edge
    row_gap = abs(t_row - f_row)
    if dashed and row_gap > 3:
        # Route along the far-right gutter
        gutter_x = SVG_WIDTH - 15
        sx, sy = fx + fw, fy + fh / 2      # right edge of source
        ex, ey = tx + tw / 2, ty             # top center of target
        return (f"M{sx},{sy} L{gutter_x},{sy} L{gutter_x},{ey - 8} "
                f"L{ex},{ey - 8} L{ex},{ey}")

    if going_right:
        # Source is left, target is right
        if t_row in NARROW_ROWS:
            # Target is on a 3-across row: go horizontal to above target center,
            # then drop straight down into the top of the target
            sx, sy = fx + fw, fy + fh / 2
            ex = tx + tw / 2
            ey = ty
            return f"M{sx},{sy} L{ex},{sy} L{ex},{ey}"
        else:
            sx, sy = fx + fw, fy + fh / 2   # exit right edge of source
            ex, ey = tx, ty + th / 2         # enter left edge of target
            if abs(sy - ey) < 5:
                return f"M{sx},{sy} L{ex},{ey}"
            else:
                mid_x = (sx + ex) / 2
                return f"M{sx},{sy} L{mid_x},{sy} L{mid_x},{ey} L{ex},{ey}"
    else:
        # Source is right, target is left
        if t_row in NARROW_ROWS:
            # Target is on a 3-across row: go horizontal to above target center,
            # then drop straight down into the top of the target
            sx, sy = fx, fy + fh / 2
            ex = tx + tw / 2
            ey = ty
            return f"M{sx},{sy} L{ex},{sy} L{ex},{ey}"
        else:
            sx, sy = fx, fy + fh / 2         # exit left edge of source
            ex, ey = tx + tw, ty + th / 2    # enter right edge of target
            if abs(sy - ey) < 5:
                return f"M{sx},{sy} L{ex},{ey}"
            else:
                mid_x = (sx + ex) / 2
                return f"M{sx},{sy} L{mid_x},{sy} L{mid_x},{ey} L{ex},{ey}"

    # Fallback (shouldn't reach here)
    return f"M{fx + fw/2},{fy + fh} L{tx + tw/2},{ty}"


def route_center_branch(from_node, to_node):
    """Route from a center/full-width node to a left or right branch node.

    Goes: bottom of source → down to gap → horizontal to target column →
          down to top of target.
    """
    fx, fy, fw, fh = node_rect(from_node)
    tx, ty, tw, th = node_rect(to_node)

    t_side = to_node.get("side", "left")

    # Exit from the left or right portion of the center node
    if t_side == "left":
        sx = fx + fw * 0.3   # left third
    elif t_side == "right":
        sx = fx + fw * 0.7   # right third
    else:
        sx = fx + fw / 2

    sy = fy + fh              # bottom edge
    ex = tx + tw / 2          # target center x
    ey = ty                    # target top edge
    gap_y = sy + (ey - sy) / 2  # midpoint for horizontal run

    if abs(sx - ex) < 5:
        return f"M{sx},{sy} L{ex},{ey}"
    else:
        return f"M{sx},{sy} L{sx},{gap_y} L{ex},{gap_y} L{ex},{ey}"


# ═══════════════════════════════════════════════════════════════════════
# SVG rendering
# ═══════════════════════════════════════════════════════════════════════

def render_node_svg(node):
    """Render a single node as SVG elements."""
    x, y, w, h = node_rect(node)
    ntype = node.get("type", "data")
    fill = COLORS.get(ntype, COLORS["data"])
    text_col = TEXT_COLORS.get(ntype, "#555")
    stroke = ' stroke="#ccc" stroke-width="1"' if ntype == "data" else ""
    parts = []

    # Box
    parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" '
                 f'rx="7" fill="{fill}"{stroke}/>')

    # Label (handle \n for two-line labels)
    label = node.get("label", "")
    lines = label.split("\\n") if "\\n" in label else label.split("\n")
    if len(lines) == 1:
        fs = min(9.5, max(7, 200 / max(len(lines[0]), 1)))
        parts.append(f'<text x="{x + w/2}" y="{y + h/2 + 4}" text-anchor="middle" '
                     f'fill="{text_col}" font-size="{fs:.1f}" font-weight="bold">'
                     f'{_esc(lines[0])}</text>')
    else:
        fs = min(8.5, max(7, 180 / max(len(lines[0]), 1)))
        parts.append(f'<text x="{x + w/2}" y="{y + h/2 - 1}" text-anchor="middle" '
                     f'fill="{text_col}" font-size="{fs:.1f}" font-weight="bold">'
                     f'{_esc(lines[0])}</text>')
        fs2 = fs - 0.5
        sub_col = "#dde8f3" if ntype != "data" else "#888"
        parts.append(f'<text x="{x + w/2}" y="{y + h/2 + 11}" text-anchor="middle" '
                     f'fill="{sub_col}" font-size="{fs2:.1f}">'
                     f'{_esc(lines[1])}</text>')

    # Badges — white circle with black text and thin border
    badges = node.get("badge", "")
    if badges:
        badge_list = [b.strip() for b in str(badges).split(",")]
        bx = x + w + 6
        by_start = y + 2
        for i, b in enumerate(badge_list):
            by = by_start + i * 16
            parts.append(f'<circle cx="{bx}" cy="{by + 7}" r="8" fill="#fff" '
                         f'stroke="#999" stroke-width="1"/>')
            parts.append(f'<text x="{bx}" y="{by + 11}" text-anchor="middle" '
                         f'fill="#333" font-size="7.5" font-weight="bold">{b}</text>')

    # Annotation — placed below the node, wrapped to node width
    ann = node.get("annotation", "")
    if ann:
        ann_fs = 7.0
        # Approximate characters per line: ~1 char per 4.2px at font-size 7
        chars_per_line = max(10, int(w / 4.2))
        ann_lines = _wrap_text(ann, chars_per_line)
        ann_line_height = 10
        ann_y_start = y + h + 10   # 10px below the node box
        for i, line in enumerate(ann_lines):
            ann_y = ann_y_start + i * ann_line_height
            parts.append(f'<text x="{x}" y="{ann_y}" fill="#aaa" '
                         f'font-size="{ann_fs}" font-style="italic">'
                         f'{_esc(line)}</text>')

    return "\n    ".join(parts)


def render_connection_svg(conn_str, node_map):
    """Render a connection line as orthogonal SVG path."""
    # Parse "from_id -> to_id [dashed]"
    dashed = "dashed" in conn_str
    clean = conn_str.replace("dashed", "").strip()
    match = re.match(r"(\S+)\s*->\s*(\S+)", clean)
    if not match:
        return f"<!-- bad connection: {conn_str} -->"
    from_id, to_id = match.group(1), match.group(2)
    if from_id not in node_map or to_id not in node_map:
        return f"<!-- missing node: {from_id} or {to_id} -->"

    from_node = node_map[from_id]
    to_node = node_map[to_id]
    f_side = from_node.get("side", "left")
    t_side = to_node.get("side", "left")

    # Use branch router when going from center/full to left/right
    if f_side in ("center", "full") and t_side in ("left", "right"):
        path_d = route_center_branch(from_node, to_node)
    elif t_side in ("center", "full") and f_side in ("left", "right"):
        # Reverse: left/right → center (e.g. comb_data → save_mat)
        fx, fy, fw, fh = node_rect(from_node)
        tx, ty, tw, th = node_rect(to_node)
        row_gap = abs(to_node["row"] - from_node["row"])

        if dashed and row_gap > 3:
            # Long dashed line (e.g. LOG side-channel): route along far-right gutter
            gutter_x = SVG_WIDTH - 15
            sx, sy = fx + fw, fy + fh / 2       # right edge of source
            ex = tx + tw * 0.85                   # right portion of center target
            ey = ty                               # top of target
            path_d = (f"M{sx},{sy} L{gutter_x},{sy} L{gutter_x},{ey - 8} "
                      f"L{ex},{ey - 8} L{ex},{ey}")
        else:
            t_row = to_node["row"]
            if t_row in NARROW_ROWS:
                # Target is on a 3-across row: horizontal from source edge,
                # then straight down to target top center
                sx, sy = fx, fy + fh / 2       # left edge of right-side source
                if f_side == "left":
                    sx = fx + fw               # right edge of left-side source
                ex = tx + tw / 2
                ey = ty
                path_d = f"M{sx},{sy} L{ex},{sy} L{ex},{ey}"
            else:
                sx, sy = fx + fw / 2, fy + fh
                # Enter the left or right portion of the center node
                if f_side == "left":
                    ex = tx + tw * 0.3
                elif f_side == "right":
                    ex = tx + tw * 0.7
                else:
                    ex = tx + tw / 2
                ey = ty
                gap_y = sy + (ey - sy) / 2
                if abs(sx - ex) < 5:
                    path_d = f"M{sx},{sy} L{ex},{ey}"
                else:
                    path_d = f"M{sx},{sy} L{sx},{gap_y} L{ex},{gap_y} L{ex},{ey}"
    else:
        path_d = route_connection(from_node, to_node, dashed=dashed)

    dash = ' stroke-dasharray="5,4"' if dashed else ""
    return (f'<path d="{path_d}" fill="none" stroke="#3B6FA0" '
            f'stroke-width="1.2"{dash}/>')


def _esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _wrap_text(text, max_chars):
    """Word-wrap text to lines of approximately max_chars width."""
    words = text.split()
    lines = []
    current = ""
    for word in words:
        test = (current + " " + word).strip() if current else word
        if len(test) <= max_chars:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines if lines else [text]


# ═══════════════════════════════════════════════════════════════════════
# HTML template
# ═══════════════════════════════════════════════════════════════════════

def render_image_card(img):
    badge = img.get("badge", "?")
    title = img.get("title", "")      # short header text
    caption = img.get("caption", "")   # longer description below image
    # Fall back: if no title, use caption truncated; if no caption, use title
    header_text = title or caption[:50]
    caption_text = caption or title
    src = img.get("src", "")
    wide = img.get("wide", False)
    wide_cls = " wide" if wide else ""
    img_tag = f'<img src="{src}" alt="">' if src else '<div style="min-height:50px;background:#f5f5f5;display:flex;align-items:center;justify-content:center;color:#ccc;font-size:11px;border-top:1px solid #eee">No image</div>'
    return f"""    <div class="img-card{wide_cls}">
      <div class="card-header"><span class="badge">{badge}</span> {_esc(header_text)}</div>
      {img_tag}
      <div class="caption">{_esc(caption_text)}</div>
    </div>"""


def build_html(cfg, svg_body, svg_height):
    title = cfg.get("title", "Pipeline")
    subtitle = cfg.get("subtitle", "")
    images = cfg.get("images", [])

    # Sort all images alphabetically by badge letter
    all_imgs = sorted(images, key=lambda i: i.get("badge", "Z"))
    all_cards = "\n".join(render_image_card(i) for i in all_imgs)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{_esc(title)}</title>
<style>
  *,*::before,*::after {{ box-sizing:border-box;margin:0;padding:0 }}
  html {{ font-size:14px }}
  body {{ font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;background:#fff;color:#333;line-height:1.4 }}
  .page-header {{ text-align:center;padding:10px 16px 6px;border-bottom:2px solid #3B6FA0;margin-bottom:4px }}
  .page-header h1 {{ font-size:1.3rem;color:#222;font-weight:700;margin:0 }}
  .page-header .subtitle {{ font-size:.78rem;color:#777;margin-top:2px }}
  .container {{ max-width:900px;margin:0 auto;padding:4px 12px 16px }}
  /* Flowchart section */
  .flowchart-section {{ margin-bottom:12px }}
  .flowchart-section h2 {{ font-size:.85rem;text-transform:uppercase;letter-spacing:.06em;color:#3B6FA0;border-bottom:2px solid #3B6FA0;padding-bottom:4px;margin-bottom:6px;text-align:center }}
  .flowchart-wrap {{ width:100%;max-width:700px;margin:0 auto;overflow:visible }}
  .flowchart-wrap svg {{ width:100%;height:auto;display:block }}
  /* Images section */
  .images-section {{ margin-top:16px }}
  .images-section h2 {{ font-size:.9rem;text-transform:uppercase;letter-spacing:.06em;color:#555;border-bottom:2px solid #999;padding-bottom:5px;margin-bottom:8px;text-align:center }}
  .images-grid {{ display:grid;grid-template-columns:1fr 1fr;gap:8px }}
  .img-card {{ border:1px solid #ddd;border-radius:6px;overflow:hidden;background:#fafafa;break-inside:avoid }}
  .img-card.wide {{ grid-column:1/-1 }}
  .img-card .card-header {{ display:flex;align-items:center;gap:6px;padding:4px 8px;font-size:.75rem;font-weight:600;color:#444 }}
  .img-card img {{ width:100%;display:block;border-top:1px solid #eee;background:#f5f5f5;min-height:50px;object-fit:contain }}
  .img-card .caption {{ padding:3px 8px;font-size:.7rem;color:#888;border-top:1px solid #eee }}
  .badge {{ display:inline-flex;align-items:center;justify-content:center;width:20px;height:20px;border-radius:50%;font-size:.7rem;font-weight:700;color:#333;flex-shrink:0;background:#fff;border:1px solid #999 }}
  .note-box {{ border:1px dashed #bbb;border-radius:4px;padding:4px 6px;font-size:.68rem;color:#888;min-height:24px;line-height:1.3;background:#fefefe;width:100% }}
  .note-box:focus {{ outline:2px solid #5A8EBE;border-color:#5A8EBE;color:#333 }}
  .note-box:empty::before {{ content:attr(data-placeholder);color:#ccc }}
  @media print {{
    @page {{ margin:8mm }}
    body {{ -webkit-print-color-adjust:exact;print-color-adjust:exact }}
    .page-header {{ padding:6px 8px 4px;margin-bottom:2px }}
    .container {{ padding:2px 6px 8px;max-width:100% }}
    .flowchart-section {{ break-inside:avoid;margin-bottom:8px }}
    .flowchart-wrap {{ max-width:100% }}
    .img-card {{ break-inside:avoid }}
    .images-section h2 {{ break-after:avoid }}
    .note-box {{ display:none }}
  }}
</style>
</head>
<body>
<div class="page-header">
  <h1>{_esc(title)}</h1>
  <div class="subtitle">{_esc(subtitle)}</div>
</div>
<div class="container">
  <div class="flowchart-section">
    <h2>Processing Pipeline</h2>
    <div class="flowchart-wrap">
      <svg viewBox="0 0 {SVG_WIDTH} {svg_height}" xmlns="http://www.w3.org/2000/svg"
           font-family="-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif">
{svg_body}
      </svg>
    </div>
    <div class="note-box" contenteditable="true" data-placeholder="General notes..." style="margin-top:6px"></div>
  </div>
  <div class="images-section">
    <h2>Reference Images</h2>
    <div class="images-grid">
{all_cards}
    </div>
    <div class="note-box" contenteditable="true" data-placeholder="Notes..." style="margin-top:8px"></div>
  </div>
</div>
</body>
</html>"""


# ═══════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════

def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python render_schematic.py <layout.yaml> [--open]")

    yaml_path = Path(sys.argv[1])
    do_open = "--open" in sys.argv

    with open(yaml_path) as f:
        cfg = yaml.safe_load(f)

    nodes = cfg.get("nodes", [])
    connections = cfg.get("connections", [])

    # Detect rows that have all 3 columns (left + center + right) → use narrow width
    from collections import defaultdict
    row_sides = defaultdict(set)
    for n in nodes:
        row_sides[n["row"]].add(n.get("side", "left"))
    NARROW_ROWS.clear()
    for row, sides in row_sides.items():
        if {"left", "center", "right"}.issubset(sides):
            NARROW_ROWS.add(row)

    # Build node map
    node_map = {n["id"]: n for n in nodes}

    # Compute SVG height
    max_row = max((n.get("row", 0) for n in nodes), default=0)
    svg_height = PADDING_TOP + (max_row + 1) * ROW_HEIGHT + 60

    # Render connections first (behind nodes)
    conn_lines = []
    for c in connections:
        conn_lines.append("    " + render_connection_svg(c, node_map))

    # Render dividers (horizontal separator lines with text)
    divider_elems = []
    for d in cfg.get("dividers", []):
        d_row = float(d.get("row", 0))
        d_y = PADDING_TOP + d_row * ROW_HEIGHT + NODE_H / 2
        d_text = d.get("text", "")
        # Light grey horizontal line spanning the SVG
        divider_elems.append(
            f'    <line x1="10" y1="{d_y}" x2="{SVG_WIDTH - 10}" y2="{d_y}" '
            f'stroke="#ccc" stroke-width="1" stroke-dasharray="6,4"/>')
        if d_text:
            # Text above the line
            divider_elems.append(
                f'    <text x="{SVG_WIDTH / 2}" y="{d_y - 6}" text-anchor="middle" '
                f'fill="#aaa" font-size="8" font-style="italic">{_esc(d_text)}</text>')

    # Render nodes
    node_elems = []
    for n in nodes:
        node_elems.append("    " + render_node_svg(n))

    # Legend
    legend_y = svg_height - 40
    legend = f"""    <rect x="10" y="{legend_y}" width="{SVG_WIDTH - 20}" height="30" rx="4" fill="#fafafa" stroke="#ddd" stroke-width="1"/>
    <text x="22" y="{legend_y+18}" fill="#666" font-size="7.5" font-weight="bold">Legend:</text>
    <rect x="70" y="{legend_y+8}" width="28" height="14" rx="4" fill="#3B6FA0"/>
    <text x="105" y="{legend_y+19}" fill="#666" font-size="7">Major step</text>
    <rect x="155" y="{legend_y+8}" width="28" height="14" rx="4" fill="#5A8EBE"/>
    <text x="190" y="{legend_y+19}" fill="#666" font-size="7">Processing fn</text>
    <rect x="245" y="{legend_y+8}" width="28" height="14" rx="4" fill="#7BADD4"/>
    <text x="280" y="{legend_y+19}" fill="#666" font-size="7">Output script</text>
    <rect x="335" y="{legend_y+8}" width="28" height="14" rx="6" fill="#f0f0f0" stroke="#ccc" stroke-width="1"/>
    <text x="370" y="{legend_y+19}" fill="#666" font-size="7">Data / file</text>
    <circle cx="415" cy="{legend_y+15}" r="7" fill="#e8983e"/>
    <text x="425" y="{legend_y+19}" fill="#666" font-size="7">Data ref</text>
    <circle cx="470" cy="{legend_y+15}" r="7" fill="#4caf50"/>
    <text x="480" y="{legend_y+19}" fill="#666" font-size="7">Output ref</text>"""

    svg_body = "\n".join(conn_lines + divider_elems + node_elems) + "\n" + legend

    html = build_html(cfg, svg_body, svg_height)

    out_path = yaml_path.parent / "data_flow_schematic.html"
    out_path.write_text(html)
    print(f"Written: {out_path}")

    # ── PNG export: flowchart only ──
    if "--png" in sys.argv:
        svg_str = (f'<?xml version="1.0" encoding="UTF-8"?>\n'
                   f'<svg viewBox="0 0 {SVG_WIDTH} {svg_height}" '
                   f'width="{SVG_WIDTH}" height="{svg_height}" '
                   f'xmlns="http://www.w3.org/2000/svg" '
                   f'font-family="-apple-system,BlinkMacSystemFont,\'Segoe UI\','
                   f'Roboto,sans-serif" '
                   f'style="background:#fff">\n'
                   f'{svg_body}\n</svg>')
        svg_path = yaml_path.parent / "03_data_flow_pipeline.svg"
        svg_path.write_text(svg_str)
        print(f"Written: {svg_path}")

        png_path = yaml_path.parent / "03_data_flow_pipeline.png"
        import subprocess
        try:
            subprocess.run(["rsvg-convert", "-o", str(png_path), "-w", "1450",
                           str(svg_path)], check=True, capture_output=True)
            print(f"Written: {png_path}")
        except (FileNotFoundError, subprocess.CalledProcessError):
            print(f"SVG written at {svg_path}")
            print(f"To convert to PNG, install librsvg: brew install librsvg")
            print(f"Then run: rsvg-convert -o {png_path} -w 1450 {svg_path}")

    if do_open:
        import subprocess
        subprocess.run(["open", str(out_path)])


if __name__ == "__main__":
    main()
