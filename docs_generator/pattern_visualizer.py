"""
Pattern visualization module for converting .mat pattern files to images and GIFs.
"""
import numpy as np
from pathlib import Path
from scipy.io import loadmat
from PIL import Image
import imageio.v3 as iio


def load_pattern(mat_path: Path) -> dict:
    """
    Load pattern data from a .mat file.

    Args:
        mat_path: Path to the .mat file

    Returns:
        Dictionary with pattern data including:
        - pats: numpy array (3, 192, x_num) or (3, 192, x_num, y_num)
        - gs_val: greyscale value (1-4)
        - x_num: number of x frames
        - y_num: number of y frames
        - name: pattern name from filename
    """
    data = loadmat(str(mat_path))
    pattern = data['pattern']

    # Extract fields from MATLAB struct
    pats = pattern['Pats'][0, 0]
    gs_val = int(pattern['gs_val'][0, 0][0, 0])
    x_num = int(pattern['x_num'][0, 0][0, 0])
    y_num = int(pattern['y_num'][0, 0][0, 0])

    # Handle various array dimensions:
    # - 4D (3, 192, x_num, y_num) - standard format
    # - 3D (3, 192, x_num) - no y_num dimension
    # - 2D (3, 192) - single frame pattern
    if pats.ndim == 2:
        pats = pats[:, :, np.newaxis, np.newaxis]
        x_num = 1  # Override x_num for single frame
    elif pats.ndim == 3:
        pats = pats[:, :, :, np.newaxis]

    # Get pattern name from filename
    name = mat_path.stem  # e.g., "Pattern_06_optomotor_8pixel_binary"

    return {
        'pats': pats,
        'gs_val': gs_val,
        'x_num': x_num,
        'y_num': y_num,
        'name': name,
        'path': mat_path
    }


def normalize_to_image(frame_2d: np.ndarray, gs_val: int) -> np.ndarray:
    """
    Convert greyscale values to RGB image with green/black colors (like LED arena).

    Args:
        frame_2d: 2D array of pixel values (3 x 192)
        gs_val: greyscale level (1=binary, 2=4-level, 3=8-level, 4=16-level)

    Returns:
        uint8 RGB array (H, W, 3) with green for ON pixels and black for OFF
    """
    max_val = (2 ** gs_val) - 1  # e.g., gs_val=1 -> max=1, gs_val=4 -> max=15
    if max_val == 0:
        max_val = 1
    normalized = (frame_2d / max_val * 255).astype(np.uint8)

    # Create RGB image with green channel only (LED arena style)
    # Black (0,0,0) for OFF, Green (0,255,0) for full ON
    rgb = np.zeros((*normalized.shape, 3), dtype=np.uint8)
    rgb[:, :, 1] = normalized  # Green channel only
    return rgb


def scale_image(img: np.ndarray, scale_y: int = 10, scale_x: int = 4) -> np.ndarray:
    """
    Scale up image using nearest-neighbor interpolation.

    The LED arena is 3 rows x 192 columns, which is very thin.
    We scale it up for better visibility while preserving pixel boundaries.

    Args:
        img: Input image array
        scale_y: Vertical scale factor (default 10)
        scale_x: Horizontal scale factor (default 4)

    Returns:
        Scaled image array
    """
    return np.repeat(np.repeat(img, scale_y, axis=0), scale_x, axis=1)


def generate_frame_image(pats: np.ndarray, frame_idx: int, gs_val: int,
                         output_path: Path, scale_y: int = 10, scale_x: int = 4) -> None:
    """
    Generate a scaled PNG image of a single frame.

    Args:
        pats: 4D pattern array (3, 192, x_num, y_num)
        frame_idx: Frame index to render
        gs_val: Greyscale value for normalization
        output_path: Path to save the PNG
        scale_y: Vertical scale factor
        scale_x: Horizontal scale factor
    """
    # Extract frame (use y_num=0 for first contrast level)
    frame = pats[:, :, frame_idx, 0]

    # Normalize and scale
    img = normalize_to_image(frame, gs_val)
    scaled = scale_image(img, scale_y, scale_x)

    # Save as PNG (RGB for green/black colors)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(scaled, mode='RGB').save(output_path)


def generate_animation(pats: np.ndarray, gs_val: int, x_num: int,
                       output_path: Path, fps: int = 10,
                       scale_y: int = 10, scale_x: int = 4) -> None:
    """
    Generate an animated GIF showing pattern motion.

    Args:
        pats: 4D pattern array (3, 192, x_num, y_num)
        gs_val: Greyscale value for normalization
        x_num: Number of frames
        output_path: Path to save the GIF
        fps: Frames per second for animation
        scale_y: Vertical scale factor
        scale_x: Horizontal scale factor
    """
    frames = []

    # For patterns with many frames, sample evenly to keep GIF reasonable
    if x_num > 64:
        frame_indices = np.linspace(0, x_num - 1, 64, dtype=int)
    else:
        frame_indices = range(x_num)

    for i in frame_indices:
        frame = pats[:, :, i, 0]
        img = normalize_to_image(frame, gs_val)
        scaled = scale_image(img, scale_y, scale_x)
        frames.append(scaled)

    # Save as GIF
    output_path.parent.mkdir(parents=True, exist_ok=True)
    iio.imwrite(output_path, frames, extension='.gif', duration=1000//fps, loop=0)


def process_pattern(mat_path: Path, output_dir: Path,
                    num_frames_to_save: int = 8) -> dict:
    """
    Process a single pattern file: generate images and return metadata.

    Args:
        mat_path: Path to the .mat pattern file
        output_dir: Base directory for output images
        num_frames_to_save: Number of individual frame PNGs to save

    Returns:
        Dictionary with pattern metadata for documentation
    """
    # Load pattern
    pattern = load_pattern(mat_path)

    # Create output directory for this pattern
    pattern_dir = output_dir / pattern['name']
    pattern_dir.mkdir(parents=True, exist_ok=True)

    # Generate individual frame images
    frames_to_save = min(num_frames_to_save, pattern['x_num'])
    for i in range(frames_to_save):
        frame_path = pattern_dir / f"frame_{i:04d}.png"
        generate_frame_image(pattern['pats'], i, pattern['gs_val'], frame_path)

    # Generate animation GIF (only if more than 2 frames)
    if pattern['x_num'] > 2:
        animation_path = pattern_dir / "animation.gif"
        generate_animation(
            pattern['pats'],
            pattern['gs_val'],
            pattern['x_num'],
            animation_path
        )

    # Return metadata
    return {
        'name': pattern['name'],
        'id': extract_pattern_id(pattern['name']),
        'gs_val': pattern['gs_val'],
        'x_num': pattern['x_num'],
        'y_num': pattern['y_num'],
        'type': infer_pattern_type(pattern['name']),
        'folder': pattern['name'],
        'has_animation': pattern['x_num'] > 2,
        'source_path': str(mat_path)
    }


def extract_pattern_id(name: str) -> int:
    """Extract the numeric pattern ID from the pattern name."""
    # Pattern names are like "Pattern_06_optomotor_8pixel_binary"
    parts = name.split('_')
    if len(parts) >= 2:
        try:
            return int(parts[1])
        except ValueError:
            pass
    return 0


def infer_pattern_type(name: str) -> str:
    """Infer the pattern type from the pattern name."""
    name_lower = name.lower()

    if 'optomotor' in name_lower:
        return 'Optomotor Grating'
    elif 'flicker' in name_lower:
        return 'Flicker'
    elif 'curtain' in name_lower:
        if 'on_curtain' in name_lower or 'on_r_curtain' in name_lower:
            return 'ON Curtain'
        elif 'off_curtain' in name_lower or 'off_r_curtain' in name_lower:
            return 'OFF Curtain'
        return 'Curtain'
    elif 'revphi' in name_lower or 'reverse_phi' in name_lower:
        return 'Reverse Phi'
    elif 'fixation' in name_lower or 'bar_fixation' in name_lower:
        if '_on' in name_lower:
            return 'Bar Fixation (ON)'
        elif '_off' in name_lower:
            return 'Bar Fixation (OFF)'
        return 'Bar Fixation'
    elif 'foe' in name_lower:
        return 'Focus of Expansion'
    elif 'bkg' in name_lower or 'background' in name_lower:
        return 'Background'
    elif 'flash' in name_lower:
        return 'Full Field Flash'
    elif 'shift' in name_lower:
        return 'Shifted Center'
    else:
        return 'Other'


if __name__ == '__main__':
    # Test with a single pattern
    from config import PATTERNS_DIR, QUARTO_ASSETS

    test_pattern = PATTERNS_DIR / "Pattern_06_optomotor_8pixel_binary.mat"
    if test_pattern.exists():
        metadata = process_pattern(test_pattern, QUARTO_ASSETS)
        print(f"Processed: {metadata['name']}")
        print(f"  Type: {metadata['type']}")
        print(f"  Frames: {metadata['x_num']}")
        print(f"  GS Value: {metadata['gs_val']}")
    else:
        print(f"Test pattern not found: {test_pattern}")
