"""Constants for the freely-walking optomotor dashboard.

Condition names, colors, metric labels, and axis ranges ported from
the MATLAB plotting code (plot_xcond_per_strain.m, get_ylb_from_data_type.m).
"""

# Protocol 27 condition names (from plot_xcond_per_strain.m lines 41-53)
CONDITION_NAMES = {
    1: "60deg-gratings-4Hz",
    2: "60deg-gratings-8Hz",
    3: "narrow-ON-bars-4Hz",
    4: "narrow-OFF-bars-4Hz",
    5: "ON-curtains-8Hz",
    6: "OFF-curtains-8Hz",
    7: "reverse-phi-2Hz",
    8: "reverse-phi-4Hz",
    9: "60deg-flicker-4Hz",
    10: "60deg-gratings-static",
    11: "60deg-gratings-0-8-offset",
    12: "32px-ON-single-bar",
}

# Paired ColorBrewer palette (from col_12 in plot_xcond_per_strain.m lines 56-68)
# Each tuple is (R, G, B) in 0-255 range
CONDITION_COLORS_RGB = [
    (166, 206, 227),
    (31, 120, 180),
    (178, 223, 138),
    (47, 141, 41),
    (251, 154, 153),
    (227, 26, 28),
    (253, 191, 111),
    (255, 127, 0),
    (202, 178, 214),
    (106, 61, 154),
    (255, 224, 41),
    (187, 75, 12),
]

# Plotly-formatted color strings
CONDITION_COLORS = [
    f"rgb({r},{g},{b})" for r, g, b in CONDITION_COLORS_RGB
]

# Metric labels (from get_ylb_from_data_type.m)
METRIC_LABELS = {
    "fv_data": "Forward velocity (mm/s)",
    "av_data": "Angular velocity (deg/s)",
    "dist_data": "Distance from centre (mm)",
    "curv_data": "Turning rate (deg/mm)",
    "move_to_centre": "Movement towards centre (mm)",
}

# Metrics to store during preprocessing (move_to_centre is derived on-the-fly from dist_data)
METRICS = ["fv_data", "av_data", "curv_data", "dist_data"]

# Derived metrics computed on-the-fly (not stored in Parquet)
DERIVED_METRICS = ["move_to_centre"]

# All metrics available in the UI (stored + derived)
ALL_METRICS = METRICS + DERIVED_METRICS

# Strain name overrides (applied during preprocessing to correct folder name mismatches)
STRAIN_NAME_OVERRIDES = {
    "2575_LPC1_shibire_kir": "ss2575_LPC1_shibire_kir",
}

# Frame rate
FPS = 30

# Pre-stimulus baseline frames (10 seconds at 30fps)
BASELINE_FRAMES = 300

# Stimulus timing markers (frame numbers, from plot_xcond_per_strain.m lines 163-166)
STIM_ONSET_FRAME = 300
DIRECTION_CHANGE_FRAME = 750
STIM_OFFSET_FRAME = 1200

# Downsampling factor for Parquet storage (30fps -> 10fps)
DOWNSAMPLE_FACTOR = 3

# Acclimation period pseudo-condition ID (stored in per-fly Parquet)
ACCLIM_CONDITION_ID = 0

# Acclimation downsampling factor (acclim is ~9000 frames; 30fps -> ~3.3fps)
ACCLIM_DOWNSAMPLE_FACTOR = 9

# QC thresholds (from check_and_average_across_reps.m lines 43, 50)
QC_MIN_MEAN_FV = 3.0       # mm/s - exclude flies walking slower than this
QC_MAX_MIN_DIST = 110.0    # mm - exclude flies never closer than this to center

# Default data directory
DEFAULT_DATA_DIR = "/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_27"

# Strain colors for cross-strain comparison (distinct palette)
STRAIN_COLORS = [
    "rgb(55,126,184)",    # blue
    "rgb(228,26,28)",     # red
    "rgb(77,175,74)",     # green
    "rgb(152,78,163)",    # purple
    "rgb(255,127,0)",     # orange
    "rgb(166,86,40)",     # brown
    "rgb(247,129,191)",   # pink
    "rgb(153,153,153)",   # grey
    "rgb(0,0,0)",         # black
    "rgb(255,255,51)",    # yellow
    "rgb(0,191,196)",     # teal
    "rgb(128,0,0)",       # maroon
    "rgb(0,128,128)",     # dark teal
    "rgb(128,0,128)",     # dark purple
    "rgb(0,0,128)",       # navy
    "rgb(128,128,0)",     # olive
    "rgb(255,99,71)",     # tomato
    "rgb(70,130,180)",    # steel blue
    "rgb(34,139,34)",     # forest green
]
