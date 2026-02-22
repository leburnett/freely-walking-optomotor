"""Generate schematic diagrams for the freely-walking optomotor training guide.

Creates 7 annotated PNG diagrams used in the training_guide.qmd document.
All diagrams use a consistent visual style: greyscale base with monochrome
blue intensity ramp accents.  Font: Helvetica throughout.

Usage:
    python docs/training_guide/generate_diagrams.py
"""

import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Arc
from matplotlib.lines import Line2D
from pathlib import Path

# ── Global matplotlib config ────────────────────────────────────────────────
plt.rcParams.update({
    "font.family": "Helvetica",
    "font.sans-serif": ["Helvetica", "Helvetica Neue", "Arial"],
})

# ── Style constants ──────────────────────────────────────────────────────────
DPI = 300
MAX_WIDTH = 6.5  # inches, for letter paper with 1-inch margins

# Greyscale base
C_BLACK = "#1a1a1a"
C_DARK_GRAY = "#2d2d2d"
C_MED_DARK_GRAY = "#555555"
C_MED_GRAY = "#777777"
C_MED_LIGHT_GRAY = "#999999"
C_LIGHT_GRAY = "#cccccc"
C_VERY_LIGHT_GRAY = "#e8e8e8"
C_NEAR_WHITE = "#f5f5f5"

# Monochrome blue accent ramp (dark → light)
C_NAVY = "#1a3a5c"
C_MED_DARK_BLUE = "#2c5f8a"
C_MED_BLUE = "#4a7fb5"
C_LIGHT_BLUE = "#85b1d9"
C_VERY_LIGHT_BLUE = "#b8d4ed"
C_LIGHTEST_BLUE = "#d9edf7"

# Font dicts
FONT_TITLE = {"fontsize": 11, "fontweight": "bold"}
FONT_LABEL = {"fontsize": 8}
FONT_SMALL = {"fontsize": 6.5}
FONT_MONO = {"fontsize": 7, "fontfamily": "monospace"}
FONT_MONO_SM = {"fontsize": 6, "fontfamily": "monospace"}

OUTPUT_DIR = Path(__file__).parent / "diagrams"


def _save(fig, filename):
    """Save figure with tight layout."""
    fig.savefig(OUTPUT_DIR / filename, dpi=DPI, bbox_inches="tight",
                facecolor="white", edgecolor="none")
    plt.close(fig)
    print(f"  Saved {filename}")


# ═══════════════════════════════════════════════════════════════════════════════
# Diagram 1: Experiment Timeline
# FIX: smaller font to fit boxes, time arrow lower, zoom arrow starts below it
# ═══════════════════════════════════════════════════════════════════════════════

def make_experiment_timeline():
    fig, ax = plt.subplots(figsize=(MAX_WIDTH, 4.0))
    ax.set_xlim(-30, 1120)
    ax.set_ylim(-4.0, 4.5)
    ax.axis("off")

    y_bar = 1.5
    bar_h = 0.8

    # Phases — widths scaled to be visually distinguishable
    phases = [
        ("Acclim OFF 1\n(darkness)", 0, 280, C_MED_LIGHT_GRAY, C_BLACK),
        ("Flashes\n+ interval", 280, 60, C_LIGHTEST_BLUE, C_BLACK),
        ("Rep 1: Cond 1..N\n(random order)", 340, 280, C_MED_BLUE, "white"),
        ("Rep 2: Cond 1..N\n(random order)", 620, 280, C_MED_BLUE, "white"),
        ("Acclim\nOFF 2", 900, 50, C_MED_LIGHT_GRAY, C_BLACK),
    ]

    for label, x0, w, color, tc in phases:
        rect = FancyBboxPatch((x0, y_bar - bar_h / 2), w, bar_h,
                              boxstyle="round,pad=0.03", facecolor=color,
                              edgecolor=C_DARK_GRAY, linewidth=0.8)
        ax.add_patch(rect)
        fs = 5.0 if w < 60 else 5.5
        ax.text(x0 + w / 2, y_bar, label, ha="center", va="center",
                fontsize=fs, fontweight="bold", color=tc)

    # Duration annotations below
    durations = [
        (140, "300 s"), (310, "~25 s"), (480, "~600 s"), (760, "~600 s"), (925, "30 s")
    ]
    for x, txt in durations:
        ax.text(x, y_bar - bar_h / 2 - 0.15, txt,
                ha="center", va="top", fontsize=5.5, color=C_MED_GRAY)

    # Camera ON / OFF markers above the bar
    cam_y = y_bar + bar_h / 2 + 0.6
    ax.annotate("Camera ON", xy=(0, y_bar + bar_h / 2 + 0.05),
                xytext=(0, cam_y + 0.1),
                ha="left", va="bottom", fontsize=6, color=C_DARK_GRAY,
                fontweight="bold",
                arrowprops=dict(arrowstyle="->", color=C_DARK_GRAY, lw=0.8))

    ax.annotate("Camera OFF", xy=(950, y_bar + bar_h / 2 + 0.05),
                xytext=(950, cam_y + 0.1),
                ha="right", va="bottom", fontsize=6, color=C_DARK_GRAY,
                fontweight="bold",
                arrowprops=dict(arrowstyle="->", color=C_DARK_GRAY, lw=0.8))

    # Time axis arrow — moved further down to clear space
    time_y = y_bar - bar_h / 2 - 0.9
    ax.annotate("", xy=(1050, time_y),
                xytext=(0, time_y),
                arrowprops=dict(arrowstyle="->", color=C_MED_GRAY, lw=0.5))
    ax.text(525, time_y - 0.15, "time", ha="center", fontsize=5.5,
            color=C_MED_GRAY, fontstyle="italic")

    # Zoom arrow — starts BELOW the time axis arrow, points to mini detail
    zoom_start_y = time_y - 0.15
    ax.annotate("", xy=(480, -1.1),
                xytext=(480, zoom_start_y),
                arrowprops=dict(arrowstyle="->", color=C_MED_GRAY, lw=0.8,
                                linestyle="dashed"))

    # Mini condition block — placed well below
    y_mini = -1.8
    mini_h = 0.55
    ax.text(280, y_mini + 0.6, "Each condition:", fontsize=6,
            fontstyle="italic", color=C_DARK_GRAY)

    mini_items = [
        ("CW (dir=+1)", 320, 120, C_LIGHT_BLUE, C_BLACK),
        ("CCW (dir=-1)", 445, 120, C_VERY_LIGHT_BLUE, C_BLACK),
        ("Interval", 570, 90, C_VERY_LIGHT_GRAY, C_DARK_GRAY),
    ]
    for label, x0, w, color, tc in mini_items:
        rect = FancyBboxPatch((x0, y_mini - mini_h / 2), w, mini_h,
                              boxstyle="round,pad=0.03", facecolor=color,
                              edgecolor=C_DARK_GRAY, linewidth=0.5)
        ax.add_patch(rect)
        ax.text(x0 + w / 2, y_mini, label, ha="center", va="center",
                fontsize=5.5, color=tc)

    # Mini durations
    ax.text(380, y_mini - mini_h / 2 - 0.12, "15 s", ha="center", va="top",
            fontsize=5, color=C_MED_GRAY)
    ax.text(505, y_mini - mini_h / 2 - 0.12, "15 s", ha="center", va="top",
            fontsize=5, color=C_MED_GRAY)
    ax.text(615, y_mini - mini_h / 2 - 0.12, "20 s", ha="center", va="top",
            fontsize=5, color=C_MED_GRAY)

    # Title
    ax.text(500, 4.0, "Experiment Timeline (e.g., protocol_27)",
            ha="center", va="top", **FONT_TITLE)

    _save(fig, "01_experiment_timeline.png")


# ═══════════════════════════════════════════════════════════════════════════════
# Diagram 2: LOG Structure
# FIX: adjust border bar positions downward to align with text
# ═══════════════════════════════════════════════════════════════════════════════

def make_log_structure():
    fig, ax = plt.subplots(figsize=(MAX_WIDTH, 7.5))
    ax.axis("off")
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 10.8)

    tree_text = """LOG
 \u251c\u2500\u2500 meta
 \u2502    \u251c\u2500\u2500 date, time, func_name
 \u2502    \u251c\u2500\u2500 fly_strain, fly_age, fly_sex
 \u2502    \u251c\u2500\u2500 light_cycle, experimenter, n_flies
 \u2502    \u251c\u2500\u2500 t_acclim_start, t_flash, t_acclim_end
 \u2502    \u251c\u2500\u2500 start_temp_outside, start_temp_ring
 \u2502    \u251c\u2500\u2500 end_temp_outside, end_temp_ring
 \u2502    \u251c\u2500\u2500 cond_array          [num_cond x 7 matrix]
 \u2502    \u2514\u2500\u2500 random_order        [1 x num_cond vector]
 \u2502
 \u251c\u2500\u2500 acclim_off1
 \u2502    \u251c\u2500\u2500 condition (=0), dir (=0)
 \u2502    \u251c\u2500\u2500 start_t, start_f    [camera timestamp & frame]
 \u2502    \u251c\u2500\u2500 stop_t, stop_f      [camera timestamp & frame]
 \u2502    \u2514\u2500\u2500 t_outside_start, t_ring_start, t_outside_end, t_ring_end
 \u2502
 \u251c\u2500\u2500 acclim_patt
 \u2502    \u251c\u2500\u2500 flash_pattern (=48), flash_speed, flash_dur, dir (=0)
 \u2502    \u251c\u2500\u2500 start_t, start_f, stop_t, stop_f    [flash period]
 \u2502    \u2514\u2500\u2500 start_t_int, start_f_int, stop_t_int, stop_f_int  [interval]
 \u2502
 \u251c\u2500\u2500 log_1 ... log_N     (N = 2 x num_conditions)
 \u2502    \u251c\u2500\u2500 trial[]             [1, 2, 3]  (trial index per entry)
 \u2502    \u251c\u2500\u2500 dir[]               [+1, -1, 0]  (CW, CCW, interval)
 \u2502    \u251c\u2500\u2500 start_t[], start_f[] [timestamps & frames at onset]
 \u2502    \u251c\u2500\u2500 stop_t[], stop_f[]   [timestamps & frames at offset]
 \u2502    \u251c\u2500\u2500 trial_len, interval_dur, num_trials
 \u2502    \u251c\u2500\u2500 optomotor_pattern, interval_pattern
 \u2502    \u251c\u2500\u2500 optomotor_speed, interval_speed
 \u2502    \u251c\u2500\u2500 which_condition     [condition number from all_conditions]
 \u2502    \u2514\u2500\u2500 t_outside_start, t_ring_start, t_outside_end, t_ring_end
 \u2502
 \u2514\u2500\u2500 acclim_off2
      \u2514\u2500\u2500 (same fields as acclim_off1)"""

    # Left-border color bars — shifted down 0.3 and made taller to align with text
    border_bars = [
        (0.25, 8.45, 2.35, C_VERY_LIGHT_BLUE),    # meta (lines 2-10)
        (0.25, 6.20, 1.50, C_VERY_LIGHT_GRAY),     # acclim_off1 (lines 12-16)
        (0.25, 4.85, 1.10, C_LIGHTEST_BLUE),        # acclim_patt (lines 18-20)
        (0.25, 1.95, 2.65, C_LIGHT_BLUE),           # log_1..N (lines 22-31)
        (0.25, 1.25, 0.65, C_VERY_LIGHT_GRAY),      # acclim_off2 (lines 33-34)
    ]
    for x, y, h, color in border_bars:
        rect = plt.Rectangle((x, y), 0.12, h, facecolor=color, edgecolor="none")
        ax.add_patch(rect)

    ax.text(0.5, 10.5, tree_text, fontsize=7, fontfamily="monospace",
            verticalalignment="top", linespacing=1.35, color=C_DARK_GRAY)

    # Section labels on the right
    labels = [
        (9.8, 9.5, "Experiment\nmetadata", C_MED_BLUE),
        (9.8, 6.85, "Dark\nacclimation", C_MED_DARK_GRAY),
        (9.8, 5.35, "Calibration\nflashes", C_MED_DARK_BLUE),
        (9.8, 3.15, "Stimulus\nconditions", C_NAVY),
        (9.8, 1.55, "Post-stimulus\nacclimation", C_MED_DARK_GRAY),
    ]
    for x, y, txt, color in labels:
        ax.text(x, y, txt, fontsize=5.5, ha="center", va="center",
                color=color, fontweight="bold", fontstyle="italic")

    ax.set_title("LOG Data Structure", fontsize=11, fontweight="bold", pad=5)

    _save(fig, "02_log_structure.png")


# ═══════════════════════════════════════════════════════════════════════════════
# Diagram 3: Data Flow Pipeline
# FIX: L-shaped LOG arrow routing around boxes, annotations on left
# ═══════════════════════════════════════════════════════════════════════════════

def make_data_flow_pipeline():
    fig, ax = plt.subplots(figsize=(MAX_WIDTH, 8))
    ax.axis("off")
    ax.set_xlim(-0.5, 10.5)
    ax.set_ylim(0, 12)

    def draw_box(x, y, w, h, text, color, text_color="white", fontsize=7):
        rect = FancyBboxPatch((x - w / 2, y - h / 2), w, h,
                              boxstyle="round,pad=0.15", facecolor=color,
                              edgecolor=C_DARK_GRAY, linewidth=0.8)
        ax.add_patch(rect)
        ax.text(x, y, text, ha="center", va="center", fontsize=fontsize,
                fontweight="bold", color=text_color)

    def draw_file(x, y, w, h, text, color, text_color=C_DARK_GRAY):
        rect = FancyBboxPatch((x - w / 2, y - h / 2), w, h,
                              boxstyle="round,pad=0.1", facecolor=color,
                              edgecolor=C_DARK_GRAY, linewidth=0.8,
                              linestyle="--")
        ax.add_patch(rect)
        ax.text(x, y, text, ha="center", va="center", fontsize=6,
                color=text_color)

    def arrow(x1, y1, x2, y2, **kwargs):
        props = dict(arrowstyle="-|>", color=C_DARK_GRAY, lw=1.2,
                     mutation_scale=12)
        props.update(kwargs)
        ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                    arrowprops=props)

    # Step 1: Run experiment
    draw_box(5, 11.2, 4, 0.6, "Run Experiment (protocol_27.m)", C_MED_BLUE)

    # Arrows to outputs
    arrow(3.5, 10.9, 2.5, 10.3)
    arrow(6.5, 10.9, 7.5, 10.3)

    # Outputs
    draw_file(2.5, 10.0, 3.2, 0.5,
              "UFMF Video (.ufmf)\n30 fps overhead camera", C_VERY_LIGHT_GRAY)
    draw_file(7.5, 10.0, 3.2, 0.5,
              "LOG.mat\nStimulus timing + metadata", C_VERY_LIGHT_GRAY)

    # Step 2: FlyTracker
    arrow(2.5, 9.7, 3.5, 9.1)
    draw_box(5, 8.8, 4.5, 0.6, "FlyTracker (offline tracking)", C_MED_BLUE)

    # Arrows to FlyTracker outputs
    arrow(3.5, 8.5, 2.5, 7.9)
    arrow(6.5, 8.5, 7.5, 7.9)

    draw_file(2.5, 7.6, 3.2, 0.5,
              "feat.mat\nVelocity, d_wall, etc.", C_VERY_LIGHT_GRAY)
    draw_file(7.5, 7.6, 3.2, 0.5,
              "trx.mat\nx, y, theta per fly", C_VERY_LIGHT_GRAY)

    # Step 3: combine_data_one_cohort
    arrow(2.5, 7.3, 4, 6.7)
    arrow(7.5, 7.3, 6, 6.7)
    draw_box(5, 6.4, 5.5, 0.6,
             "combine_data_one_cohort(feat, trx)", C_MED_BLUE)

    # Annotations on LEFT side (moved from right to make room for LOG arrow)
    ax.text(0.0, 6.4,
            "Remove bad tracking\nFilter > 50 mm/s\nInterpolate gaps\nCompute 12 metrics",
            fontsize=5, color=C_MED_GRAY, va="center", fontstyle="italic",
            ha="left")

    # Output: comb_data
    arrow(5, 6.1, 5, 5.5)
    draw_file(5, 5.2, 4.5, 0.5,
              "comb_data struct\nfv, av, curv, dist, heading, x, y, ...",
              C_LIGHTEST_BLUE, text_color=C_NAVY)

    # Step 4: comb_data_one_cohort_cond
    arrow(5, 4.9, 5, 4.3)

    # LOG arrow — L-shaped route: right from LOG.mat, down along right edge,
    # then left into the comb_data_one_cohort_cond box
    log_path_x = 9.5  # x-coordinate for the right-side vertical path
    ax.plot([9.1, log_path_x], [10.0, 10.0], color=C_MED_GRAY, lw=0.8,
            linestyle="dashed")  # horizontal from LOG.mat right edge
    ax.plot([log_path_x, log_path_x], [10.0, 4.0], color=C_MED_GRAY, lw=0.8,
            linestyle="dashed")  # vertical down
    ax.annotate("", xy=(7.75, 4.0), xytext=(log_path_x, 4.0),
                arrowprops=dict(arrowstyle="-|>", color=C_MED_GRAY,
                                lw=0.8, linestyle="dashed", mutation_scale=10))
    ax.text(9.7, 7.0, "LOG", fontsize=5.5, color=C_MED_GRAY,
            fontstyle="italic", ha="left")

    draw_box(5, 4.0, 5.5, 0.6,
             "comb_data_one_cohort_cond(LOG, comb_data)", C_MED_BLUE)

    ax.text(0.0, 4.0,
            "Split by condition\nusing LOG frame indices\n(+300 frame pre-buffer)",
            fontsize=5, color=C_MED_GRAY, va="center", fontstyle="italic",
            ha="left")

    # Output: DATA single cohort
    arrow(5, 3.7, 5, 3.1)
    draw_file(5, 2.8, 4.5, 0.5,
              "DATA struct (single cohort)\nPer-condition behavioral data",
              C_LIGHTEST_BLUE, text_color=C_NAVY)

    # Step 5: comb_data_across_cohorts_cond
    arrow(5, 2.5, 5, 1.9)
    draw_box(5, 1.6, 5.5, 0.6,
             "comb_data_across_cohorts_cond(protocol_dir)", C_MED_BLUE)

    ax.text(0.0, 1.6,
            "Merge all experiments\nfor one protocol",
            fontsize=5, color=C_MED_GRAY, va="center", fontstyle="italic",
            ha="left")

    # Final output
    arrow(5, 1.3, 5, 0.7)
    draw_file(5, 0.4, 5.5, 0.5,
              "DATA.(strain).(sex)(cohort_idx).(condition).(metric)",
              C_VERY_LIGHT_BLUE, text_color=C_NAVY)

    ax.set_title("Data Processing Pipeline", fontsize=11,
                 fontweight="bold", pad=10)

    _save(fig, "03_data_flow_pipeline.png")


# ═══════════════════════════════════════════════════════════════════════════════
# Diagram 4: Frame Synchronization
# FIX: move text in blocks above the horizontal centre line
# ═══════════════════════════════════════════════════════════════════════════════

def make_frame_synchronization():
    fig, ax = plt.subplots(figsize=(MAX_WIDTH, 3.5))
    ax.axis("off")
    ax.set_xlim(0, 100)
    ax.set_ylim(-3, 6)

    # Video frame timeline (top)
    ax.plot([5, 95], [4, 4], color=C_DARK_GRAY, lw=1.5)
    ax.text(2, 4, "Video\nFrames", ha="right", va="center", fontsize=6,
            fontweight="bold", color=C_DARK_GRAY)

    # Frame tick marks
    frame_ticks = [10, 20, 35, 50, 65, 80, 90]
    frame_labels = ["f=0", "start_f(1)", "stop_f(1)\nstart_f(2)",
                    "stop_f(2)\nstart_f(3)", "stop_f(3)", "", "f=N"]
    for x, label in zip(frame_ticks, frame_labels):
        ax.plot([x, x], [3.7, 4.3], color=C_DARK_GRAY, lw=0.8)
        if label:
            ax.text(x, 3.3, label, ha="center", va="top", fontsize=5)

    # Stimulus event timeline (bottom)
    ax.plot([5, 95], [1, 1], color=C_DARK_GRAY, lw=1.5)
    ax.text(2, 1, "Stimulus\nEvents", ha="right", va="center", fontsize=6,
            fontweight="bold", color=C_DARK_GRAY)

    # Coloured blocks for stimulus phases — text positioned ABOVE centre
    stim_blocks = [
        (20, 15, "Trial 1\n(CW, dir=+1)", C_LIGHT_BLUE, C_BLACK),
        (35, 15, "Trial 2\n(CCW, dir=-1)", C_VERY_LIGHT_BLUE, C_BLACK),
        (50, 15, "Interval\n(dir=0)", C_VERY_LIGHT_GRAY, C_DARK_GRAY),
    ]
    for x0, w, label, color, tc in stim_blocks:
        rect = FancyBboxPatch((x0, 0.4), w, 1.2, boxstyle="round,pad=0.5",
                              facecolor=color, edgecolor=C_DARK_GRAY,
                              linewidth=0.6)
        ax.add_patch(rect)
        ax.text(x0 + w / 2, 1.25, label, ha="center", va="center",
                fontsize=5.5, color=tc)

    # Dashed lines connecting frames to events
    for x in [20, 35, 50, 65]:
        ax.plot([x, x], [1.6, 3.7], color=C_LIGHT_GRAY, lw=0.5, linestyle=":")

    # Pre-buffer annotation (blue accent)
    ax.annotate("", xy=(10, 0.2), xytext=(20, 0.2),
                arrowprops=dict(arrowstyle="<->", color=C_MED_BLUE, lw=1))
    ax.text(15, -0.1, "300 frames\n(10 s pre-buffer)", ha="center", va="top",
            fontsize=5, color=C_MED_BLUE)

    # DATA slice annotation (dark navy)
    ax.annotate("", xy=(10, -1.0), xytext=(65, -1.0),
                arrowprops=dict(arrowstyle="<->", color=C_NAVY, lw=1.2))
    ax.text(37.5, -1.3, "DATA slice: start_f(1) \u2212 300  to  stop_f(end)",
            ha="center", va="top", fontsize=5.5, color=C_NAVY, fontweight="bold")

    # Title
    ax.text(50, 5.5,
            "Frame Synchronization: How LOG maps video frames to stimulus events",
            ha="center", va="center", **FONT_TITLE)

    # getFrameCount note
    ax.text(78, 3.0, "vidobj.getFrameCount()\ncalled at each start/stop",
            fontsize=5, color=C_MED_GRAY, fontstyle="italic",
            ha="center", va="center",
            bbox=dict(boxstyle="round,pad=0.3", facecolor=C_NEAR_WHITE,
                      edgecolor=C_LIGHT_GRAY, lw=0.5))

    _save(fig, "04_frame_synchronization.png")


# ═══════════════════════════════════════════════════════════════════════════════
# Diagram 5: Behavioral Metrics
# FIX: centre label left, IFD leader line angle, fly labels, arrowheads
# ═══════════════════════════════════════════════════════════════════════════════

def make_behavioral_metrics():
    fig, ax = plt.subplots(figsize=(MAX_WIDTH, 5.5))
    ax.set_aspect("equal")
    ax.axis("off")

    # Arena
    arena_radius = 120  # mm
    arena = plt.Circle((0, 0), arena_radius, fill=False, edgecolor=C_DARK_GRAY,
                        linewidth=2.5, linestyle="-")
    ax.add_patch(arena)
    ax.set_xlim(-185, 230)
    ax.set_ylim(-175, 175)

    # Center mark
    ax.plot(0, 0, "+", color=C_MED_LIGHT_GRAY, markersize=8, markeredgewidth=1)

    # "center (0,0)" label — TO THE LEFT of the cross
    ax.text(-8, -5, "center\n(0,0)", fontsize=5, color=C_MED_LIGHT_GRAY,
            ha="right", va="center")

    # Fly 1 position
    fly_x, fly_y = 50, -25
    fly_heading = np.radians(35)

    # Fly 1 body (triangle) — blue accent
    fly_size = 8
    dx = fly_size * np.cos(fly_heading)
    dy = fly_size * np.sin(fly_heading)
    perp_x = fly_size * 0.4 * np.cos(fly_heading + np.pi / 2)
    perp_y = fly_size * 0.4 * np.sin(fly_heading + np.pi / 2)

    fly_tri = plt.Polygon([
        (fly_x + dx, fly_y + dy),
        (fly_x - dx / 2 + perp_x, fly_y - dy / 2 + perp_y),
        (fly_x - dx / 2 - perp_x, fly_y - dy / 2 - perp_y),
    ], facecolor=C_MED_BLUE, edgecolor=C_DARK_GRAY, linewidth=0.8, zorder=5)
    ax.add_patch(fly_tri)
    # "Fly 1" label
    ax.text(fly_x + 12, fly_y - 18, "Fly 1", fontsize=5, color=C_MED_BLUE,
            fontweight="bold")

    # Fly 2 for IFD
    fly2_x, fly2_y = -35, 55
    fly2_tri = plt.Polygon([
        (fly2_x + 5, fly2_y + 3),
        (fly2_x - 3, fly2_y + 5),
        (fly2_x - 3, fly2_y - 2),
    ], facecolor=C_LIGHT_BLUE, edgecolor=C_DARK_GRAY, linewidth=0.5, zorder=5)
    ax.add_patch(fly2_tri)
    # "Fly 2" label
    ax.text(fly2_x + 10, fly2_y + 10, "Fly 2", fontsize=5, color=C_LIGHT_BLUE,
            fontweight="bold")

    # ── Metric 1: Forward Velocity (solid line) ──
    fv_len = 50
    fv_end_x = fly_x + fv_len * np.cos(fly_heading)
    fv_end_y = fly_y + fv_len * np.sin(fly_heading)
    ax.annotate("", xy=(fv_end_x, fv_end_y), xytext=(fly_x, fly_y),
                arrowprops=dict(arrowstyle="-|>", color=C_BLACK, lw=2,
                                mutation_scale=15), zorder=4)
    # Leader line to label in top-right
    label_fv_x, label_fv_y = 155, 115
    ax.plot([fv_end_x, label_fv_x - 5], [fv_end_y, label_fv_y - 5],
            color=C_MED_LIGHT_GRAY, lw=0.5, linestyle="-")
    ax.text(label_fv_x, label_fv_y,
            "Forward Velocity (fv)\nmm/s, along heading",
            fontsize=5.5, color=C_BLACK, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.3", facecolor=C_NEAR_WHITE,
                      edgecolor=C_LIGHT_GRAY, lw=0.5))

    # ── Metric 2: Angular Velocity (arc) ──
    arc_radius = 25
    arc = Arc((fly_x, fly_y), arc_radius * 2, arc_radius * 2,
              angle=0, theta1=np.degrees(fly_heading) - 5,
              theta2=np.degrees(fly_heading) + 40,
              color=C_MED_DARK_GRAY, lw=1.5, linestyle="-")
    ax.add_patch(arc)
    # Arrowhead at the END of the arc (CCW direction = tip points along the arc)
    arc_end_angle = fly_heading + np.radians(40)
    # xytext = base of arrow (slightly behind the tip along the arc)
    # xy = tip of arrow (at the arc end)
    arc_tip_offset = 0.25  # radians back from the tip to place the arrow base
    ax.annotate("",
                xy=(fly_x + arc_radius * np.cos(arc_end_angle),
                    fly_y + arc_radius * np.sin(arc_end_angle)),
                xytext=(fly_x + arc_radius * np.cos(arc_end_angle - arc_tip_offset),
                        fly_y + arc_radius * np.sin(arc_end_angle - arc_tip_offset)),
                arrowprops=dict(arrowstyle="-|>", color=C_MED_DARK_GRAY, lw=1.5,
                                mutation_scale=12))
    # Leader line to label at top
    arc_tip_x = fly_x + arc_radius * np.cos(arc_end_angle)
    arc_tip_y = fly_y + arc_radius * np.sin(arc_end_angle)
    label_av_x, label_av_y = 120, 155
    ax.plot([arc_tip_x, label_av_x - 5], [arc_tip_y, label_av_y - 5],
            color=C_MED_LIGHT_GRAY, lw=0.5, linestyle="-")
    ax.text(label_av_x, label_av_y,
            "Angular Velocity (av)\ndeg/s, rotation rate",
            fontsize=5.5, color=C_BLACK, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.3", facecolor=C_NEAR_WHITE,
                      edgecolor=C_LIGHT_GRAY, lw=0.5))

    # ── Metric 3: Distance from center (dashed line) ──
    ax.plot([0, fly_x], [0, fly_y], color=C_BLACK, lw=1.2,
            linestyle="--", zorder=2)
    mid_x, mid_y = fly_x / 2, fly_y / 2
    label_dc_x, label_dc_y = -150, -100
    ax.plot([mid_x, label_dc_x + 50], [mid_y, label_dc_y + 10],
            color=C_MED_LIGHT_GRAY, lw=0.5, linestyle="-")
    ax.text(label_dc_x, label_dc_y,
            "Distance from center\n(dist), mm",
            fontsize=5.5, color=C_BLACK, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.3", facecolor=C_NEAR_WHITE,
                      edgecolor=C_LIGHT_GRAY, lw=0.5))

    # ── Metric 4: Viewing Distance (dash-dot line) ──
    cos_h, sin_h = np.cos(fly_heading), np.sin(fly_heading)
    A = 1
    B = 2 * (fly_x * cos_h + fly_y * sin_h)
    C_val = fly_x ** 2 + fly_y ** 2 - arena_radius ** 2
    D = B ** 2 - 4 * A * C_val
    t = (-B + np.sqrt(D)) / (2 * A)
    wall_x = fly_x + t * cos_h
    wall_y = fly_y + t * sin_h

    ax.plot([fly_x, wall_x], [fly_y, wall_y], color=C_BLACK, lw=1.2,
            linestyle="-.", zorder=2)
    ax.plot(wall_x, wall_y, "o", color=C_MED_BLUE, markersize=4, zorder=5)

    # Leader line to label on right
    label_vd_x, label_vd_y = 155, 10
    ax.plot([wall_x, label_vd_x - 5], [wall_y, label_vd_y],
            color=C_MED_LIGHT_GRAY, lw=0.5, linestyle="-")
    ax.text(label_vd_x, label_vd_y,
            "Viewing Distance\n(view_dist), mm",
            fontsize=5.5, color=C_BLACK, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.3", facecolor=C_NEAR_WHITE,
                      edgecolor=C_LIGHT_GRAY, lw=0.5))

    # ── Metric 5: Inter-fly distance (dotted line) ──
    ax.plot([fly_x, fly2_x], [fly_y, fly2_y], color=C_BLACK, lw=1,
            linestyle=":")
    # Leader line from midpoint of dotted line to label LEFT of the circle
    ifd_mid_x = (fly_x + fly2_x) / 2
    ifd_mid_y = (fly_y + fly2_y) / 2
    label_ifd_x, label_ifd_y = -170, 30
    ax.plot([ifd_mid_x, label_ifd_x + 55], [ifd_mid_y, label_ifd_y],
            color=C_MED_LIGHT_GRAY, lw=0.5, linestyle="-")
    ax.text(label_ifd_x, label_ifd_y,
            "Inter-fly Distance\n(IFD), mm",
            fontsize=5.5, color=C_BLACK, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.3", facecolor=C_NEAR_WHITE,
                      edgecolor=C_LIGHT_GRAY, lw=0.5))

    # ── Position annotation box — bottom-right ──
    ax.text(155, -80,
            f"(x, y) = ({fly_x}, {fly_y}) mm\nheading = 35\u00b0",
            fontsize=5, color=C_DARK_GRAY, fontstyle="italic",
            bbox=dict(boxstyle="round,pad=0.3", facecolor="white",
                      edgecolor=C_LIGHT_GRAY, lw=0.5))

    # Arena label
    ax.text(0, -140, "Arena wall (R = 120 mm)", ha="center", fontsize=6,
            color=C_DARK_GRAY)

    # Title
    ax.text(20, 165, "Behavioral Metrics Overview",
            ha="center", va="center", **FONT_TITLE)

    # Legend box
    legend_lines = [
        (Line2D([0], [0], color=C_BLACK, lw=2, linestyle="-"), "Forward Velocity (fv)"),
        (Line2D([0], [0], color=C_BLACK, lw=1.2, linestyle="--"), "Distance from center"),
        (Line2D([0], [0], color=C_BLACK, lw=1.2, linestyle="-."), "Viewing Distance"),
        (Line2D([0], [0], color=C_BLACK, lw=1, linestyle=":"), "Inter-fly Distance"),
        (Line2D([0], [0], color=C_MED_DARK_GRAY, lw=1.5, linestyle="-",
                marker="$\\curvearrowright$", markersize=6), "Angular Velocity (av)"),
    ]
    handles, labels = zip(*legend_lines)
    ax.legend(handles, labels, loc="lower right", fontsize=5,
              frameon=True, fancybox=False, edgecolor=C_LIGHT_GRAY,
              framealpha=0.95, title="Line styles", title_fontsize=5.5,
              bbox_to_anchor=(1.15, -0.05))

    _save(fig, "05_behavioral_metrics.png")


# ═══════════════════════════════════════════════════════════════════════════════
# Diagram 6: Folder Structure
# FIX: adjust background box positions to better encompass text
# ═══════════════════════════════════════════════════════════════════════════════

def make_folder_structure():
    fig, ax = plt.subplots(figsize=(MAX_WIDTH, 5.5))
    ax.axis("off")
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 10)

    raw_tree = """Raw Data (during experiment):
\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
C:\\MatlabRoot\\FreeWalkOptomotor\\data\\
  \u2514\u2500\u2500 2024_09_24\\                          \u2190 date
       \u2514\u2500\u2500 protocol_27\\                     \u2190 protocol
            \u2514\u2500\u2500 jfrc100_es_shibire_kir\\      \u2190 strain
                 \u2514\u2500\u2500 F\\                       \u2190 sex
                      \u2514\u2500\u2500 11_06_44\\            \u2190 time (HH_MM_SS)
                           \u251c\u2500\u2500 LOG_2024_09_24_11_06_44.mat
                           \u2514\u2500\u2500 REC_\\
                                \u2514\u2500\u2500 movie\\
                                     \u251c\u2500\u2500 movie.ufmf   (video)
                                     \u2514\u2500\u2500 movie_JAABA\\
                                          \u2514\u2500\u2500 trx.mat"""

    tracked_tree = """After FlyTracker processing:
\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
REC_\\movie\\ also contains:
  \u251c\u2500\u2500 movie-feat.mat                       \u2190 FlyTracker features
  \u2514\u2500\u2500 movie_JAABA\\trx.mat                  \u2190 Trajectory data"""

    results_tree = """Processed Results:
\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
results\\
  \u2514\u2500\u2500 protocol_27\\
       \u2514\u2500\u2500 jfrc100_es_shibire_kir\\
            \u2514\u2500\u2500 F\\
                 \u2514\u2500\u2500 2024-09-24_11-06-44_..._data.mat"""

    # Background boxes — adjusted positions to better encompass text
    rect1 = FancyBboxPatch((0.15, 4.2), 9.6, 5.5, boxstyle="round,pad=0.1",
                           facecolor=C_NEAR_WHITE, edgecolor=C_MED_GRAY,
                           linewidth=0.8)
    ax.add_patch(rect1)

    rect2 = FancyBboxPatch((0.15, 2.6), 9.6, 1.5, boxstyle="round,pad=0.1",
                           facecolor=C_LIGHTEST_BLUE, edgecolor=C_MED_GRAY,
                           linewidth=0.8)
    ax.add_patch(rect2)

    rect3 = FancyBboxPatch((0.15, 0.2), 9.6, 2.3, boxstyle="round,pad=0.1",
                           facecolor=C_VERY_LIGHT_GRAY, edgecolor=C_MED_GRAY,
                           linewidth=0.8)
    ax.add_patch(rect3)

    ax.text(0.35, 9.5, raw_tree, fontsize=5.8, fontfamily="monospace",
            verticalalignment="top", linespacing=1.3, color=C_DARK_GRAY)
    ax.text(0.35, 3.9, tracked_tree, fontsize=5.8, fontfamily="monospace",
            verticalalignment="top", linespacing=1.3, color=C_DARK_GRAY)
    ax.text(0.35, 2.4, results_tree, fontsize=5.8, fontfamily="monospace",
            verticalalignment="top", linespacing=1.3, color=C_DARK_GRAY)

    ax.set_title("Data Folder Structure", fontsize=11, fontweight="bold", pad=8)

    _save(fig, "06_folder_structure.png")


# ═══════════════════════════════════════════════════════════════════════════════
# Diagram 7: DATA Struct Hierarchy
# ═══════════════════════════════════════════════════════════════════════════════

def make_data_struct_hierarchy():
    fig, ax = plt.subplots(figsize=(MAX_WIDTH, 7.0))
    ax.axis("off")
    ax.set_xlim(0, 10)
    ax.set_ylim(-0.2, 10.8)

    tree_text = """DATA
 \u251c\u2500\u2500 jfrc100_es_shibire_kir                    (strain name)
 \u2502    \u251c\u2500\u2500 F                                      (sex)
 \u2502    \u2502    \u251c\u2500\u2500 (1)                                (cohort index = experiment 1)
 \u2502    \u2502    \u2502    \u251c\u2500\u2500 meta
 \u2502    \u2502    \u2502    \u2502    \u251c\u2500\u2500 date, time, func_name, fly_strain, ...
 \u2502    \u2502    \u2502    \u2502    \u2514\u2500\u2500 n_flies_arena, n_flies, n_flies_rm
 \u2502    \u2502    \u2502    \u251c\u2500\u2500 acclim_off1
 \u2502    \u2502    \u2502    \u2502    \u2514\u2500\u2500 fv_data, av_data, dist_data, ...  [n_flies x n_frames]
 \u2502    \u2502    \u2502    \u251c\u2500\u2500 acclim_patt
 \u2502    \u2502    \u2502    \u2502    \u2514\u2500\u2500 fv_data, av_data, dist_data, ...  [n_flies x n_frames]
 \u2502    \u2502    \u2502    \u251c\u2500\u2500 R1_condition_1                     (Rep 1, Condition 1)
 \u2502    \u2502    \u2502    \u2502    \u251c\u2500\u2500 trial_len, optomotor_pattern, optomotor_speed
 \u2502    \u2502    \u2502    \u2502    \u251c\u2500\u2500 interval_dur, interval_pattern, interval_speed
 \u2502    \u2502    \u2502    \u2502    \u251c\u2500\u2500 start_flicker_f
 \u2502    \u2502    \u2502    \u2502    \u2514\u2500\u2500 fv_data, av_data, curv_data, dist_data,
 \u2502    \u2502    \u2502    \u2502       vel_data, heading_data, heading_wrap,
 \u2502    \u2502    \u2502    \u2502       x_data, y_data, view_dist, IFD_data, IFA_data
 \u2502    \u2502    \u2502    \u251c\u2500\u2500 R1_condition_2  ...  R1_condition_N
 \u2502    \u2502    \u2502    \u251c\u2500\u2500 R2_condition_1  ...  R2_condition_N    (Rep 2)
 \u2502    \u2502    \u2502    \u2514\u2500\u2500 acclim_off2
 \u2502    \u2502    \u2502         \u2514\u2500\u2500 fv_data, av_data, dist_data, ...
 \u2502    \u2502    \u251c\u2500\u2500 (2)                                (cohort index = experiment 2)
 \u2502    \u2502    \u2502    \u2514\u2500\u2500 ...
 \u2502    \u2502    \u2514\u2500\u2500 (3) ...
 \u2502    \u2514\u2500\u2500 M                                      (sex)
 \u2502         \u2514\u2500\u2500 ...
 \u2514\u2500\u2500 csw1118                                    (another strain)
      \u2514\u2500\u2500 ..."""

    # Left-margin color bars — adjusted positions
    bars = [
        (0.25, 7.85, 1.25, C_VERY_LIGHT_BLUE),    # meta
        (0.25, 6.45, 1.35, C_VERY_LIGHT_GRAY),     # acclim sections
        (0.25, 3.30, 3.00, C_LIGHTEST_BLUE),        # conditions
        (0.25, 2.60, 0.65, C_VERY_LIGHT_GRAY),      # acclim_off2
    ]
    for x, y, h, color in bars:
        rect = plt.Rectangle((x, y), 0.12, h, facecolor=color, edgecolor="none")
        ax.add_patch(rect)

    ax.text(0.5, 10.3, tree_text, fontsize=6.5, fontfamily="monospace",
            verticalalignment="top", linespacing=1.25, color=C_DARK_GRAY)

    # Access example — lightest blue background
    example_box = FancyBboxPatch((0.3, 0.0), 9.3, 1.2,
                                 boxstyle="round,pad=0.1",
                                 facecolor=C_LIGHTEST_BLUE, edgecolor=C_MED_GRAY,
                                 linewidth=0.8)
    ax.add_patch(example_box)
    ax.text(0.5, 1.0,
            "Example: Access forward velocity for strain, sex F, "
            "cohort 1, Rep 1 condition 1:",
            fontsize=6, fontweight="bold", color=C_DARK_GRAY)
    ax.text(0.5, 0.5,
            "fv = DATA.jfrc100_es_shibire_kir.F(1).R1_condition_1.fv_data;"
            "  % [n_flies x n_frames]",
            fontsize=6, fontfamily="monospace", color=C_NAVY)

    ax.set_title("DATA Struct Hierarchy", fontsize=11, fontweight="bold", pad=8)

    _save(fig, "07_data_struct_hierarchy.png")


# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print("Generating training guide diagrams...")

    make_experiment_timeline()
    make_log_structure()
    make_data_flow_pipeline()
    make_frame_synchronization()
    make_behavioral_metrics()
    make_folder_structure()
    make_data_struct_hierarchy()

    print(f"\nAll 7 diagrams saved to {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
