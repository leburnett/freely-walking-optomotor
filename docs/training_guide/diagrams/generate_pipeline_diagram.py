"""Generate the data processing pipeline diagram (03_data_flow_pipeline.png).

Corrected version: both per-cohort DATA and hierarchical DATA are derived
from LOG + comb_data (saved in *_data.mat files), NOT from each other.
"""

import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

# ── Colours ──────────────────────────────────────────────────────────────
BLUE_DARK  = "#3B6FA0"
BLUE_MED   = "#5A8EBE"
BLUE_LIGHT = "#7BADD4"
GREY_BG    = "#F0F0F0"
GREY_BORDER = "#AAAAAA"
GREY_TEXT  = "#555555"
WHITE      = "#FFFFFF"
ARROW_COL  = "#3B6FA0"

# ── Canvas ───────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(12, 17))
ax.set_xlim(0, 12)
ax.set_ylim(0, 17)
ax.set_aspect("equal")
ax.axis("off")
fig.patch.set_facecolor(WHITE)

# ── Helper functions ─────────────────────────────────────────────────────

def draw_box(cx, cy, w, h, text, color=BLUE_DARK, fontsize=10, bold=True,
             text_color="white", rounding=0.15, zorder=3):
    box = FancyBboxPatch(
        (cx - w/2, cy - h/2), w, h,
        boxstyle=f"round,pad={rounding}",
        facecolor=color, edgecolor="none", zorder=zorder,
    )
    ax.add_patch(box)
    weight = "bold" if bold else "normal"
    ax.text(cx, cy, text, ha="center", va="center",
            fontsize=fontsize, color=text_color, weight=weight, zorder=zorder+1)


def draw_diamond(cx, cy, w, h, text, color=GREY_BG, fontsize=8,
                 text_color=GREY_TEXT):
    dx, dy = w/2, h/2
    verts = [(cx, cy+dy), (cx+dx, cy), (cx, cy-dy), (cx-dx, cy), (cx, cy+dy)]
    poly = plt.Polygon(verts, facecolor=color, edgecolor=GREY_BORDER,
                       linewidth=1.2, zorder=2)
    ax.add_patch(poly)
    ax.text(cx, cy, text, ha="center", va="center",
            fontsize=fontsize, color=text_color, style="italic", zorder=3)


def arrow(x1, y1, x2, y2, color=ARROW_COL, lw=1.8):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle="-|>", color=color, lw=lw),
                zorder=2)


def arrow_curved(x1, y1, x2, y2, color=ARROW_COL, lw=1.8,
                 connectionstyle="arc3,rad=0.2"):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle="-|>", color=color, lw=lw,
                                connectionstyle=connectionstyle),
                zorder=2)


def annotation_box(cx, cy, w, h, text, fontsize=7.5):
    box = FancyBboxPatch(
        (cx - w/2, cy - h/2), w, h,
        boxstyle="round,pad=0.1",
        facecolor=WHITE, edgecolor=GREY_BORDER,
        linewidth=1, linestyle="--", zorder=1,
    )
    ax.add_patch(box)
    ax.text(cx, cy, text, ha="center", va="center",
            fontsize=fontsize, color=GREY_TEXT, zorder=2)


# ── Title ────────────────────────────────────────────────────────────────
ax.text(6.0, 16.5, "Data Processing Pipeline", ha="center", va="center",
        fontsize=18, weight="bold", color="#222222")

# ── Row 1: Run Experiment ────────────────────────────────────────────────
y1 = 15.5
draw_box(6.0, y1, 4.5, 0.6, "Run Experiment (protocol_XX.m)", BLUE_DARK, 11)

# ── Row 2: Outputs of experiment ─────────────────────────────────────────
y2 = 14.5
draw_diamond(4.0, y2, 2.8, 0.7, "UFMF Video (.ufmf)\n30 fps overhead camera")
draw_diamond(8.0, y2, 2.8, 0.7, "LOG.mat\nStimulus timing + metadata")
arrow(6.0, y1 - 0.3, 4.0, y2 + 0.35)
arrow(6.0, y1 - 0.3, 8.0, y2 + 0.35)

# ── Row 3: FlyTracker ───────────────────────────────────────────────────
y3 = 13.4
draw_box(4.0, y3, 4.0, 0.55, "FlyTracker (offline tracking)", BLUE_MED, 10)
arrow(4.0, y2 - 0.35, 4.0, y3 + 0.275)

# LOG arrow going down the right side
ax.annotate("", xy=(10.0, 10.1), xytext=(10.0, y2 - 0.35),
            arrowprops=dict(arrowstyle="-|>", color=ARROW_COL, lw=1.5,
                            linestyle="--"),
            zorder=2)
ax.text(10.35, 12.0, "LOG", ha="left", va="center",
        fontsize=9, color=GREY_TEXT, style="italic")

# ── Row 4: FlyTracker outputs ───────────────────────────────────────────
y4 = 12.4
draw_diamond(2.8, y4, 2.4, 0.65, "feat.mat\nVelocity, d_wall, etc.")
draw_diamond(5.2, y4, 2.0, 0.65, "trx.mat\nx, y, theta per fly")
arrow(4.0, y3 - 0.275, 2.8, y4 + 0.325)
arrow(4.0, y3 - 0.275, 5.2, y4 + 0.325)

# ── Row 5: combine_data_one_cohort ──────────────────────────────────────
y5 = 11.3
draw_box(4.0, y5, 5.0, 0.55, "combine_data_one_cohort(feat, trx)", BLUE_LIGHT, 10)
arrow(2.8, y4 - 0.325, 4.0, y5 + 0.275)
arrow(5.2, y4 - 0.325, 4.0, y5 + 0.275)

annotation_box(1.0, 11.3, 1.6, 0.9,
               "Remove bad tracking\nFilter > 50 mm/s\nInterpolate gaps\nCompute 12 metrics",
               fontsize=7)

# ── Row 6: comb_data output ─────────────────────────────────────────────
y6 = 10.3
draw_diamond(4.0, y6, 3.5, 0.65,
             "comb_data struct\nfv, av, curv, dist, heading, x, y, ...")
arrow(4.0, y5 - 0.275, 4.0, y6 + 0.325)

# ── Row 7: Save *_data.mat ──────────────────────────────────────────────
y7 = 9.2
draw_box(6.0, y7, 5.5, 0.55,
         "Save *_data.mat  (LOG + comb_data + n_fly_data)", BLUE_DARK, 9.5)
arrow(4.0, y6 - 0.325, 6.0, y7 + 0.275)
# LOG arrow joins here
ax.annotate("", xy=(8.75, y7), xytext=(10.0, y7 + 0.88),
            arrowprops=dict(arrowstyle="-|>", color=ARROW_COL, lw=1.5,
                            linestyle="--"),
            zorder=2)

# ── BRANCH POINT ─────────────────────────────────────────────────────────
y_branch = 8.2
ax.text(6.0, y_branch + 0.15, "loads saved .mat files",
        ha="center", va="center", fontsize=7.5, color=GREY_TEXT, style="italic")

# Left branch: per-cohort DATA
y_left = 7.2
draw_box(3.5, y_left, 5.0, 0.55,
         "comb_data_one_cohort_cond(LOG, comb_data)", BLUE_MED, 9.5)
arrow_curved(4.8, y7 - 0.275, 3.5, y_left + 0.275,
             connectionstyle="arc3,rad=0.15")

annotation_box(1.0, 7.2, 1.6, 0.75,
               "Split by condition\nusing LOG frame indices\n(+300 frame pre buffer)",
               fontsize=7)

y_left2 = 6.2
draw_diamond(3.5, y_left2, 3.8, 0.65,
             "DATA struct (single cohort)\nPer-condition behavioral data")
arrow(3.5, y_left - 0.275, 3.5, y_left2 + 0.325)

ax.text(3.5, 5.6, "Per-experiment overview figures",
        ha="center", va="center", fontsize=8, color=GREY_TEXT, style="italic")

# Right branch: hierarchical DATA
y_right = 7.2
draw_box(9.0, y_right, 4.5, 0.55,
         "comb_data_across_cohorts_cond(protocol_dir)", BLUE_MED, 9)
arrow_curved(7.2, y7 - 0.275, 9.0, y_right + 0.275,
             connectionstyle="arc3,rad=-0.15")

annotation_box(9.0, 6.4, 3.2, 0.5,
               "Merge all experiments for one protocol",
               fontsize=7)

y_right2 = 5.5
draw_box(9.0, y_right2, 4.8, 0.55,
         "DATA.(strain).(sex)(cohort_idx).(condition).(metric)",
         BLUE_DARK, 8.5)
arrow(9.0, y_right - 0.275, 9.0, y_right2 + 0.275)

# ── Downstream from hierarchical DATA ───────────────────────────────────
y_down_label = 4.5
ax.text(9.0, y_down_label, "Downstream outputs", ha="center", va="center",
        fontsize=10, weight="bold", color="#444444")

y_d = 3.5
# Analysis scripts
draw_box(5.0, y_d, 3.0, 0.5, "Analysis scripts\n(MATLAB)", BLUE_LIGHT, 8.5)
arrow_curved(7.6, y_right2 - 0.275, 5.0, y_d + 0.25,
             connectionstyle="arc3,rad=0.25")

# Parquet / Dashboard
draw_box(8.5, y_d, 2.8, 0.5, "preprocess.py\n(Python)", BLUE_LIGHT, 8.5)
arrow(8.5, y_right2 - 0.275, 8.5, y_d + 0.25)

# JSON / Trajectory viewer
draw_box(11.5, y_d, 2.4, 0.5, "export_trajectory\n_data.m (MATLAB)", BLUE_LIGHT, 8)
arrow_curved(10.4, y_right2 - 0.275, 11.5, y_d + 0.25,
             connectionstyle="arc3,rad=-0.25")

# Final outputs
y_f = 2.3
draw_diamond(5.0, y_f, 2.6, 0.6, "Publication\nfigures")
arrow(5.0, y_d - 0.25, 5.0, y_f + 0.3)

draw_diamond(8.5, y_f, 2.6, 0.6, "Parquet files\nDash dashboard")
arrow(8.5, y_d - 0.25, 8.5, y_f + 0.3)

draw_diamond(11.5, y_f, 2.4, 0.6, ".json.gz files\nTrajectory viewer")
arrow(11.5, y_d - 0.25, 11.5, y_f + 0.3)

# ── Save ─────────────────────────────────────────────────────────────────
plt.tight_layout(pad=0.5)
out_path = "03_data_flow_pipeline.png"
fig.savefig(out_path, dpi=200, bbox_inches="tight", facecolor=WHITE)
print(f"Saved: {out_path}")
plt.close()
