#!/usr/bin/env python3
"""Build the tested frame geometry, then apply the inspected paper-source finish."""
import argparse
from pathlib import Path
from base_frames import main as build
from refine_paper import finish
if __name__ == '__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--root',type=Path,required=True)
    args=parser.parse_args()
    build()
    finish(args.root)
