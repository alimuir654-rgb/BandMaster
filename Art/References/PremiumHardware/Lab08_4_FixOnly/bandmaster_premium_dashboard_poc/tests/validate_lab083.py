"""Compatibility entry point. Current precision-lighting checks are in validate_lab084.py."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name("validate_lab084.py")), run_name="__main__")
