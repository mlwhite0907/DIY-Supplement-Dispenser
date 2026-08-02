"""DIY Supplement Dispenser – Phase 1 control software.

Runs on Raspberry Pi OS (Python 3.11+) with real GPIO/HX711 hardware, or in
simulation mode on any machine (Mac/Linux) when ``DISPENSER_SIM=1`` or
``hardware.mode: sim`` is set in config.
"""

from __future__ import annotations

__version__ = "0.2.0"
__all__ = ["__version__"]
