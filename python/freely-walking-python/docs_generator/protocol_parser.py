"""
Protocol parser module for extracting metadata from MATLAB protocol scripts.
"""
import re
from pathlib import Path
from typing import Optional


def parse_protocol(m_file_path: Path) -> dict:
    """
    Extract metadata from a MATLAB protocol file.

    Args:
        m_file_path: Path to the .m protocol file

    Returns:
        Dictionary with protocol metadata including:
        - name: protocol name
        - description: header comments
        - timing: timing parameters dict
        - conditions: list of condition dicts
        - patterns_used: list of pattern IDs (stimulus patterns only)
        - interval_pattern: the interval/background pattern ID (if any)
    """
    content = m_file_path.read_text()
    lines = content.split('\n')

    # Extract protocol name
    name = m_file_path.stem

    # Extract header comments (description)
    description = extract_header_comments(lines)

    # Extract timing parameters
    timing = extract_timing_parameters(content)

    # Extract conditions from all_conditions matrix
    conditions = extract_conditions(content)

    # Get all pattern IDs used (stimulus patterns and interval pattern separately)
    patterns_used, interval_pattern = extract_all_pattern_ids(content, conditions)

    return {
        'name': name,
        'description': description,
        'timing': timing,
        'conditions': conditions,
        'patterns_used': sorted(list(patterns_used)),
        'interval_pattern': interval_pattern
    }


def extract_header_comments(lines: list) -> str:
    """
    Extract header comments from the beginning of the file.

    Args:
        lines: List of lines from the file

    Returns:
        Concatenated header comments as a string
    """
    comments = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('%'):
            # Remove the % and leading space
            comment = stripped[1:].strip()
            if comment:
                comments.append(comment)
        elif stripped and not stripped.startswith('%'):
            # Stop at first non-comment, non-empty line
            break

    return '\n'.join(comments)


def extract_timing_parameters(content: str) -> dict:
    """
    Extract timing parameters from the protocol.

    Args:
        content: Full file content

    Returns:
        Dictionary of timing parameters
    """
    timing = {}

    # Common timing parameters to look for
    patterns = {
        't_acclim_start': r't_acclim_start\s*=\s*(\d+)',
        't_acclim_end': r't_acclim_end\s*=\s*(\d+)',
        't_acclim': r't_acclim\s*=\s*(\d+)',
        't_interval': r't_interval\s*=\s*(\d+)',
        't_flash': r't_flash\s*=\s*(\d+)',
        't_pause': r't_pause\s*=\s*([\d.]+)',
        'trial_len': r'trial_len\s*=\s*(\d+)',
        'trial_dur': r'trial_dur\s*=\s*(\d+)',
    }

    for param_name, pattern in patterns.items():
        match = re.search(pattern, content)
        if match:
            value = match.group(1)
            # Convert to int or float as appropriate
            if '.' in value:
                timing[param_name] = float(value)
            else:
                timing[param_name] = int(value)

    return timing


def extract_conditions(content: str) -> list:
    """
    Extract conditions from the all_conditions matrix.

    Args:
        content: Full file content

    Returns:
        List of condition dictionaries
    """
    conditions = []

    # Find the all_conditions matrix
    # Match pattern: all_conditions = [ ... ];
    matrix_match = re.search(
        r'all_conditions\s*=\s*\[(.*?)\];',
        content,
        re.DOTALL
    )

    if not matrix_match:
        return conditions

    matrix_content = matrix_match.group(1)

    # Split by newlines first to preserve inline comments
    # Each row in MATLAB matrix can span a line and ends with semicolon
    lines = matrix_content.split('\n')

    # Combine lines that don't end with semicolon or comment
    rows = []
    current_row = ''
    for line in lines:
        line = line.strip()
        if not line:
            continue
        current_row += ' ' + line
        # If line ends with semicolon (possibly followed by comment), it's a complete row
        if ';' in line or line.startswith('%'):
            rows.append(current_row.strip())
            current_row = ''
    if current_row.strip():
        rows.append(current_row.strip())

    for row in rows:
        row = row.strip()
        if not row:
            continue

        # Skip lines that are only comments
        if row.startswith('%'):
            continue

        # Extract inline comment if present
        comment = ''
        if '%' in row:
            parts = row.split('%', 1)
            row = parts[0].strip()
            comment = parts[1].strip()

        # Parse the values
        # Remove any trailing comma or semicolon
        row = row.rstrip(',;').strip()
        if not row:
            continue

        # Split by comma and parse values
        values = []
        for val in row.split(','):
            val = val.strip()
            if not val:
                continue
            # Handle t_interval variable reference
            if val == 't_interval':
                values.append('t_interval')
            else:
                try:
                    values.append(int(val))
                except ValueError:
                    try:
                        values.append(float(val))
                    except ValueError:
                        values.append(val)

        if len(values) >= 7:
            # Format: [pattern_id, interval_id, speed_patt, speed_int, trial_dur, int_dur, condition_n]
            conditions.append({
                'pattern_id': values[0],
                'interval_id': values[1],
                'speed': values[2],
                'speed_int': values[3],
                'trial_dur': values[4],
                'int_dur': values[5],
                'condition_n': values[6],
                'description': comment
            })
        elif len(values) >= 1:
            # Simpler format - just pattern ID and maybe speed
            conditions.append({
                'pattern_id': values[0],
                'interval_id': None,
                'speed': values[1] if len(values) > 1 else None,
                'speed_int': None,
                'trial_dur': None,
                'int_dur': None,
                'condition_n': len(conditions) + 1,
                'description': comment
            })

    return conditions


def extract_all_pattern_ids(content: str, conditions: list) -> tuple:
    """
    Extract all pattern IDs referenced in the protocol.

    Separates stimulus patterns from interval/background patterns.
    Excludes flash_pattern (used only for calibration flashes).

    Args:
        content: Full file content
        conditions: Already-parsed conditions list

    Returns:
        Tuple of (stimulus_patterns set, interval_pattern int or None)
    """
    stimulus_patterns = set()
    interval_pattern = None

    # Add stimulus pattern IDs from conditions (not interval_id)
    for cond in conditions:
        if isinstance(cond['pattern_id'], int):
            stimulus_patterns.add(cond['pattern_id'])

    # Get the interval pattern from conditions (they should all be the same)
    for cond in conditions:
        if isinstance(cond.get('interval_id'), int):
            interval_pattern = cond['interval_id']
            break

    # Look for direct stimulus pattern assignments
    stimulus_pattern_names = [
        r'optomotor_pattern\s*=\s*(\d+)',
        r'flicker_pattern\s*=\s*(\d+)',
    ]

    for pattern in stimulus_pattern_names:
        for match in re.finditer(pattern, content):
            stimulus_patterns.add(int(match.group(1)))

    # Look for interval/background pattern assignments (separate from stimuli)
    interval_pattern_names = [
        r'interval_pattern\s*=\s*(\d+)',
        r'bkg_pattern\s*=\s*(\d+)',
    ]

    for pattern in interval_pattern_names:
        match = re.search(pattern, content)
        if match:
            interval_pattern = int(match.group(1))

    # Note: flash_pattern is intentionally excluded - it's only for calibration flashes,
    # not an experimental stimulus pattern

    # Look for Panel_com('set_pattern_id', N) calls - these are stimulus patterns
    panel_com_pattern = r"Panel_com\s*\(\s*'set_pattern_id'\s*,\s*(\d+)\s*\)"
    for match in re.finditer(panel_com_pattern, content):
        stimulus_patterns.add(int(match.group(1)))

    # Add interval pattern to stimulus patterns for previews (if it exists)
    if interval_pattern is not None:
        stimulus_patterns.add(interval_pattern)

    return stimulus_patterns, interval_pattern


def get_protocol_summary(protocol: dict) -> str:
    """
    Generate a short summary of the protocol.

    Args:
        protocol: Parsed protocol dictionary

    Returns:
        Short summary string
    """
    num_conditions = len(protocol['conditions'])
    num_patterns = len(protocol['patterns_used'])

    return f"{num_conditions} conditions using {num_patterns} patterns"


if __name__ == '__main__':
    # Test with a protocol
    from config import PROTOCOLS_DIR

    test_protocol = PROTOCOLS_DIR / "protocol_27.m"
    if test_protocol.exists():
        protocol = parse_protocol(test_protocol)
        print(f"Protocol: {protocol['name']}")
        print(f"Description:\n{protocol['description'][:200]}...")
        print(f"\nTiming: {protocol['timing']}")
        print(f"\nConditions ({len(protocol['conditions'])}):")
        for cond in protocol['conditions'][:3]:
            print(f"  {cond['condition_n']}: Pattern {cond['pattern_id']} - {cond['description']}")
        print(f"\nPatterns used: {protocol['patterns_used']}")
    else:
        print(f"Test protocol not found: {test_protocol}")
