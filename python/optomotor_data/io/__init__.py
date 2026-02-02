"""
I/O module for loading and saving optomotor data.

Provides:
- MATLoader: Load MATLAB .mat files into Python data structures
"""

from .mat_loader import MATLoader

__all__ = ['MATLoader']
