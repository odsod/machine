import sys


def main():
    if len(sys.argv) < 2:
        print("usage: recorder <run|note|segment|meet-dom>", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "run":
        from recorder.app import main as run_main

        run_main()
    elif cmd == "note":
        from recorder.note import main as note_main

        note_main()
    elif cmd == "segment":
        from recorder.segment_cli import main as segment_main

        sys.argv = sys.argv[1:]  # shift so argparse sees "segment <path> ..."
        segment_main()
    elif cmd == "meet-dom":
        import argparse

        parser = argparse.ArgumentParser(prog="recorder meet-dom")
        parser.add_argument(
            "--interval",
            type=float,
            default=5.0,
            metavar="SECS",
            help="seconds between snapshots (default: 5)",
        )
        parser.add_argument(
            "--output-dir",
            default="~/Tmp/meet-dom",
            metavar="DIR",
            help="directory for snapshot files (default: ~/Tmp/meet-dom)",
        )
        parser.add_argument(
            "--port",
            type=int,
            default=9224,
            help="CDP port (default: 9224)",
        )
        args = parser.parse_args(sys.argv[2:])
        from recorder.meet_dom import dump_dom

        dump_dom(interval_secs=args.interval, output_dir=args.output_dir, port=args.port)
    else:
        print(f"recorder: unknown command '{cmd}'", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
