"""Allow ``python -m dispenser`` to invoke the CLI."""

from dispenser.cli import app

if __name__ == "__main__":
    app()
