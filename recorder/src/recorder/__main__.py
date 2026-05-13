import sys


def main():
    if len(sys.argv) < 2:
        print("usage: recorder <run|note>", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "run":
        from recorder.app import main as run_main

        run_main()
    elif cmd == "note":
        from recorder.note import main as note_main

        note_main()
    else:
        print(f"recorder: unknown command '{cmd}'", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
