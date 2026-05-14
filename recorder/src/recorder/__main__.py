import sys


def main():
    if len(sys.argv) < 2:
        print("usage: recorder <run|note|segment>", file=sys.stderr)
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
    else:
        print(f"recorder: unknown command '{cmd}'", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
