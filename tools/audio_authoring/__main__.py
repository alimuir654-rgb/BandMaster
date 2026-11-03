"""Offline planning/inspection and an explicit, isolated local SFZ renderer."""
import argparse
import json
import sys
from .core import AuthoringError, audit_bundle, inspect_wav, load_catalog, load_json, plan_request, validate_request


def main(argv=None):
    parser = argparse.ArgumentParser(description="Offline audio-study planning, inspection and explicit local SFZ rendering")
    parser.add_argument("--catalog", help="Local JSON style/backend/study registry; no executable plugins")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("check-request", "plan", "inspect", "audit"):
        sub.add_parser(name).add_argument("path")
    render = sub.add_parser("render-local", help="Explicit reviewed local SFZ score; needs isolated optional audio dependencies")
    render.add_argument("path")
    render.add_argument("--output-dir", required=True)
    args = parser.parse_args(argv)
    try:
        catalog = load_catalog(args.catalog)
        if args.command == "render-local":
            from .sample_renderer import render_score
            result = render_score(args.path, args.output_dir)
        elif args.command == "inspect": result = inspect_wav(args.path)
        elif args.command == "check-request": result = {"valid": True, "request": validate_request(load_json(args.path), catalog)}
        elif args.command == "plan": result = plan_request(load_json(args.path), catalog)
        else: result = audit_bundle(load_json(args.path), catalog)
        print(json.dumps(result, indent=2, allow_nan=False))
        return 0  # a valid plan may intentionally report HOLD; inspect its explicit status/holds
    except AuthoringError as exc:
        print(json.dumps({"error": str(exc)}), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
