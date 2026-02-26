#!/usr/bin/env python3
"""
Generate Quarto documentation pages for LED arena patterns.

Usage:
    python generate_pattern_docs.py                              # Process all patterns
    python generate_pattern_docs.py Pattern_09_*.mat             # Process single pattern
    python generate_pattern_docs.py --list                       # List all patterns
"""
import argparse
import json
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

from config import PATTERNS_DIR, QUARTO_ASSETS, QUARTO_FREELY_WALKING, TEMPLATES_DIR
from pattern_visualizer import process_pattern, extract_pattern_id


def get_pattern_description(pattern_type: str, name: str) -> str:
    """Generate a description for the pattern based on its type and name."""
    descriptions = {
        'Optomotor Grating': 'Moving vertical stripe pattern used to elicit optomotor responses. The pattern rotates around the arena to test motion detection.',
        'Flicker': 'Temporal contrast pattern that alternates between light and dark states without spatial motion. Used to test flicker sensitivity.',
        'ON Curtain': 'Progressive edge stimulus where a bright region expands across the arena. Tests responses to expanding bright edges.',
        'OFF Curtain': 'Progressive edge stimulus where a dark region expands across the arena. Tests responses to expanding dark edges.',
        'Curtain': 'Progressive edge stimulus that expands across the arena.',
        'Reverse Phi': 'Apparent motion stimulus with contrast reversal. Creates motion perception in the opposite direction to physical displacement.',
        'Bar Fixation (ON)': 'Stationary bright bar pattern used for phototaxis and fixation experiments.',
        'Bar Fixation (OFF)': 'Stationary dark bar pattern used for fixation experiments.',
        'Bar Fixation': 'Stationary bar pattern used for fixation experiments.',
        'Focus of Expansion': 'Radial expansion pattern simulating approach or looming stimuli.',
        'Background': 'Uniform background pattern used as interval stimulus between trials.',
        'Full Field Flash': 'Full-field luminance change used for calibration or arousal.',
        'Shifted Center': 'Optomotor pattern with shifted center of rotation to test turning responses.',
        'Other': 'Visual stimulus pattern for behavioral experiments.',
    }

    base_desc = descriptions.get(pattern_type, descriptions['Other'])

    # Add specific details from name
    if 'binary' in name.lower():
        base_desc += ' Binary (2-level) contrast.'
    if '4pixel' in name.lower() or '4px' in name.lower():
        base_desc += ' 4-pixel stripe width.'
    elif '8pixel' in name.lower() or '8px' in name.lower():
        base_desc += ' 8-pixel stripe width.'
    elif '16pixel' in name.lower() or '16px' in name.lower():
        base_desc += ' 16-pixel stripe width.'
    elif '32px' in name.lower():
        base_desc += ' 32-pixel stripe width.'

    return base_desc


def generate_pattern_page(pattern_metadata: dict, template_env: Environment,
                          output_dir: Path, all_protocols: dict = None) -> Path:
    """
    Generate a Quarto page for a single pattern.

    Args:
        pattern_metadata: Metadata dict from process_pattern()
        template_env: Jinja2 environment
        output_dir: Directory to write .qmd files
        all_protocols: Dict mapping pattern IDs to protocols that use them

    Returns:
        Path to the generated .qmd file
    """
    template = template_env.get_template('pattern.qmd.jinja2')

    # Enrich metadata
    pattern_metadata['description'] = get_pattern_description(
        pattern_metadata['type'],
        pattern_metadata['name']
    )
    pattern_metadata['num_frames_shown'] = min(8, pattern_metadata['x_num'])

    # Add protocols that use this pattern
    if all_protocols and pattern_metadata['id'] in all_protocols:
        pattern_metadata['used_in_protocols'] = all_protocols[pattern_metadata['id']]
    else:
        pattern_metadata['used_in_protocols'] = []

    # Render template
    content = template.render(pattern=pattern_metadata)

    # Write file
    output_file = output_dir / f"freely_walking_pattern_{pattern_metadata['id']:02d}.qmd"
    output_file.write_text(content)

    return output_file


def process_all_patterns(patterns_dir: Path, assets_dir: Path,
                         quarto_dir: Path, specific_pattern: str = None) -> list:
    """
    Process all patterns (or a specific one) and generate documentation.

    Args:
        patterns_dir: Directory containing .mat pattern files
        assets_dir: Directory for output images
        quarto_dir: Directory for output .qmd files
        specific_pattern: Optional specific pattern filename to process

    Returns:
        List of processed pattern metadata dicts
    """
    # Set up Jinja2 environment
    template_env = Environment(loader=FileSystemLoader(TEMPLATES_DIR))

    # Find pattern files
    if specific_pattern:
        pattern_files = list(patterns_dir.glob(specific_pattern))
    else:
        pattern_files = sorted(patterns_dir.glob('Pattern_*.mat'))

    if not pattern_files:
        print(f"No pattern files found in {patterns_dir}")
        return []

    print(f"Processing {len(pattern_files)} pattern(s)...")

    all_metadata = []
    for mat_file in pattern_files:
        print(f"  Processing: {mat_file.name}")

        # Generate images
        metadata = process_pattern(mat_file, assets_dir)
        all_metadata.append(metadata)

        # Generate documentation page
        page_path = generate_pattern_page(metadata, template_env, quarto_dir)
        print(f"    -> {page_path.name}")

    # Save metadata for cross-referencing
    metadata_file = assets_dir / 'patterns_metadata.json'
    with open(metadata_file, 'w') as f:
        json.dump(all_metadata, f, indent=2)
    print(f"\nMetadata saved to: {metadata_file}")

    return all_metadata


def list_patterns(patterns_dir: Path) -> None:
    """List all available patterns."""
    pattern_files = sorted(patterns_dir.glob('Pattern_*.mat'))
    print(f"Found {len(pattern_files)} patterns:\n")
    for pf in pattern_files:
        pattern_id = extract_pattern_id(pf.stem)
        print(f"  {pattern_id:2d}: {pf.name}")


def main():
    parser = argparse.ArgumentParser(
        description='Generate Quarto documentation for LED arena patterns'
    )
    parser.add_argument(
        'pattern',
        nargs='?',
        help='Specific pattern filename to process (e.g., Pattern_09_*.mat)'
    )
    parser.add_argument(
        '--list',
        action='store_true',
        help='List all available patterns'
    )
    parser.add_argument(
        '--patterns-dir',
        type=Path,
        default=PATTERNS_DIR,
        help='Directory containing pattern .mat files'
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=QUARTO_ASSETS,
        help='Directory for output images'
    )
    parser.add_argument(
        '--quarto-dir',
        type=Path,
        default=QUARTO_FREELY_WALKING,
        help='Directory for output .qmd files'
    )

    args = parser.parse_args()

    if args.list:
        list_patterns(args.patterns_dir)
        return

    # Create output directories
    args.output_dir.mkdir(parents=True, exist_ok=True)
    args.quarto_dir.mkdir(parents=True, exist_ok=True)

    # Process patterns
    metadata = process_all_patterns(
        args.patterns_dir,
        args.output_dir,
        args.quarto_dir,
        args.pattern
    )

    print(f"\nProcessed {len(metadata)} pattern(s)")
    print("\nNext steps:")
    print("1. Review the generated images in:")
    print(f"   {args.output_dir}")
    print("2. Add the new pages to _quarto.yml in reiser-documentation")
    print("3. Run 'quarto preview' to view the documentation")


if __name__ == '__main__':
    main()
