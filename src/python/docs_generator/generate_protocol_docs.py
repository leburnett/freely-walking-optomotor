#!/usr/bin/env python3
"""
Generate Quarto documentation pages for experiment protocols.

Usage:
    python generate_protocol_docs.py                       # Process all protocols
    python generate_protocol_docs.py protocol_27.m         # Process single protocol
    python generate_protocol_docs.py --list                # List all protocols
"""
import argparse
import json
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

from config import PROTOCOLS_DIR, QUARTO_FREELY_WALKING, TEMPLATES_DIR, QUARTO_ASSETS
from protocol_parser import parse_protocol, get_protocol_summary


def generate_protocol_page(protocol: dict, template_env: Environment,
                           output_dir: Path, pattern_metadata: dict = None) -> Path:
    """
    Generate a Quarto page for a single protocol.

    Args:
        protocol: Parsed protocol dictionary
        template_env: Jinja2 environment
        output_dir: Directory to write .qmd files
        pattern_metadata: Dict mapping pattern IDs to their metadata

    Returns:
        Path to the generated .qmd file
    """
    template = template_env.get_template('protocol.qmd.jinja2')

    # Add pattern metadata for previews
    protocol['pattern_metadata'] = pattern_metadata or {}

    # Render template
    content = template.render(protocol=protocol)

    # Write file
    output_file = output_dir / f"freely_walking_{protocol['name']}.qmd"
    output_file.write_text(content)

    return output_file


def load_pattern_metadata(assets_dir: Path) -> dict:
    """Load pattern metadata from JSON file."""
    metadata_file = assets_dir / 'patterns_metadata.json'
    if metadata_file.exists():
        with open(metadata_file) as f:
            metadata_list = json.load(f)
            return {m['id']: m for m in metadata_list}
    return {}


def process_all_protocols(protocols_dir: Path, quarto_dir: Path,
                          assets_dir: Path, specific_protocol: str = None) -> list:
    """
    Process all protocols (or a specific one) and generate documentation.

    Args:
        protocols_dir: Directory containing .m protocol files
        quarto_dir: Directory for output .qmd files
        assets_dir: Directory containing pattern metadata
        specific_protocol: Optional specific protocol filename to process

    Returns:
        List of processed protocol dicts
    """
    # Set up Jinja2 environment
    template_env = Environment(loader=FileSystemLoader(TEMPLATES_DIR))

    # Load pattern metadata for cross-referencing
    pattern_metadata = load_pattern_metadata(assets_dir)

    # Find protocol files
    if specific_protocol:
        protocol_files = list(protocols_dir.glob(specific_protocol))
    else:
        # Get all protocol files (both Protocol_*.m and protocol_*.m)
        protocol_files = sorted(
            list(protocols_dir.glob('Protocol_*.m')) +
            list(protocols_dir.glob('protocol_*.m'))
        )

    if not protocol_files:
        print(f"No protocol files found in {protocols_dir}")
        return []

    print(f"Processing {len(protocol_files)} protocol(s)...")

    all_protocols = []
    pattern_to_protocols = {}  # Track which protocols use each pattern

    for m_file in protocol_files:
        print(f"  Processing: {m_file.name}")

        # Parse protocol
        protocol = parse_protocol(m_file)
        all_protocols.append(protocol)

        # Track pattern usage
        for pattern_id in protocol['patterns_used']:
            if pattern_id not in pattern_to_protocols:
                pattern_to_protocols[pattern_id] = []
            pattern_to_protocols[pattern_id].append(protocol['name'])

        # Generate documentation page
        page_path = generate_protocol_page(
            protocol, template_env, quarto_dir, pattern_metadata
        )
        print(f"    -> {page_path.name}")
        print(f"       {get_protocol_summary(protocol)}")

    # Save protocol metadata
    protocols_metadata_file = quarto_dir / 'protocols_metadata.json'
    with open(protocols_metadata_file, 'w') as f:
        # Convert to serializable format
        protocols_for_json = []
        for p in all_protocols:
            protocols_for_json.append({
                'name': p['name'],
                'description': p['description'][:200] + '...' if len(p['description']) > 200 else p['description'],
                'num_conditions': len(p['conditions']),
                'patterns_used': p['patterns_used'],
                'timing': p['timing']
            })
        json.dump(protocols_for_json, f, indent=2)
    print(f"\nProtocol metadata saved to: {protocols_metadata_file}")

    # Save pattern-to-protocol mapping
    mapping_file = quarto_dir / 'pattern_protocol_mapping.json'
    with open(mapping_file, 'w') as f:
        json.dump(pattern_to_protocols, f, indent=2)
    print(f"Pattern mapping saved to: {mapping_file}")

    return all_protocols


def list_protocols(protocols_dir: Path) -> None:
    """List all available protocols."""
    protocol_files = sorted(
        list(protocols_dir.glob('Protocol_*.m')) +
        list(protocols_dir.glob('protocol_*.m'))
    )
    print(f"Found {len(protocol_files)} protocols:\n")
    for pf in protocol_files:
        print(f"  {pf.name}")


def main():
    parser = argparse.ArgumentParser(
        description='Generate Quarto documentation for experiment protocols'
    )
    parser.add_argument(
        'protocol',
        nargs='?',
        help='Specific protocol filename to process (e.g., protocol_27.m)'
    )
    parser.add_argument(
        '--list',
        action='store_true',
        help='List all available protocols'
    )
    parser.add_argument(
        '--protocols-dir',
        type=Path,
        default=PROTOCOLS_DIR,
        help='Directory containing protocol .m files'
    )
    parser.add_argument(
        '--quarto-dir',
        type=Path,
        default=QUARTO_FREELY_WALKING,
        help='Directory for output .qmd files'
    )
    parser.add_argument(
        '--assets-dir',
        type=Path,
        default=QUARTO_ASSETS,
        help='Directory containing pattern metadata'
    )

    args = parser.parse_args()

    if args.list:
        list_protocols(args.protocols_dir)
        return

    # Create output directory
    args.quarto_dir.mkdir(parents=True, exist_ok=True)

    # Process protocols
    protocols = process_all_protocols(
        args.protocols_dir,
        args.quarto_dir,
        args.assets_dir,
        args.protocol
    )

    print(f"\nProcessed {len(protocols)} protocol(s)")
    print("\nNext steps:")
    print("1. Add the new pages to _quarto.yml in reiser-documentation")
    print("2. Run 'quarto preview' to view the documentation")


if __name__ == '__main__':
    main()
