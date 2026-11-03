"""Run with python3 -m tools.audio_authoring. There is deliberately no render command."""
import argparse
import json
import sys
from .core import AuthoringError, audit_bundle, inspect_wav, load_catalog, load_json, plan_request, validate_request


def main(argv=None):
    parser = argparse.ArgumentParser(description="Offline audio-study requests, budgets and WAV inspection; no generation")
    parser.add_argument("--catalog", help="Local JSON style/backend/study registry; no executable plugins")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("check-request", "plan", "inspect", "audit"):
        sub.add_parser(name).add_argument("path")
    args = parser.parse_args(argv)
    try:
        catalog = load_catalog(args.catalog)
        if args.command == "inspect": result = inspect_wav(args.path)
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
