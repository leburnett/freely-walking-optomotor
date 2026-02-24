"""Entry point for `python -m dashboard`."""
from dashboard.app import app

if __name__ == "__main__":
    app.run(debug=True, port=8050)
