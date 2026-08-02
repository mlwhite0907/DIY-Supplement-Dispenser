"""Hardware backends: abstract interfaces, simulation, and Pi drivers."""

from __future__ import annotations

from typing import Any

from dispenser.config import is_sim_mode
from dispenser.hardware.base import (
    DigitalSensor,
    Pump,
    Scale,
    StepperMotor,
    VibrationMotor,
)


def create_hardware(cfg: dict[str, Any]) -> dict[str, Any]:
    """Instantiate hardware objects from config.

    Returns a dict with keys: ``scale``, ``stepper``, ``vibration``, ``pump``,
    ``cup``, ``level``, ``flow``, ``mode``.
    """
    if is_sim_mode(cfg):
        from dispenser.hardware.sim import (
            SimDigitalSensor,
            SimPump,
            SimScale,
            SimStepper,
            SimVibration,
        )

        hw = cfg.get("hardware", {})
        dosing = cfg.get("dosing", {})
        scale_cfg = hw.get("scale", {})
        pump_cfg = hw.get("pump", {})
        powder_cfg = dosing.get("powder", {})
        water_cfg = dosing.get("water", {})

        scale = SimScale(
            noise_g=float(scale_cfg.get("sim_noise_g", 0.02)),
            grams_per_second=float(powder_cfg.get("sim_grams_per_second", 2.5)),
        )
        stepper = SimStepper(scale=scale)
        vibration = SimVibration(scale=scale)
        pump = SimPump(
            ml_per_second=float(
                water_cfg.get("sim_ml_per_second", pump_cfg.get("ml_per_second", 25.0))
            )
        )
        sensors = hw.get("sensors", {})
        cup = SimDigitalSensor(name="cup", initial=True)
        level = SimDigitalSensor(name="level", initial=True)  # water present
        flow = SimDigitalSensor(name="flow", initial=False)
        # store refs for tests
        _ = sensors
        return {
            "scale": scale,
            "stepper": stepper,
            "vibration": vibration,
            "pump": pump,
            "cup": cup,
            "level": level,
            "flow": flow,
            "mode": "sim",
        }

    # Real Pi hardware
    from dispenser.hardware.pump import GpioPump
    from dispenser.hardware.scale_hx711 import HX711Scale
    from dispenser.hardware.sensors import GpioDigitalSensor
    from dispenser.hardware.stepper_tmc import TmcStepper
    from dispenser.hardware.vibration import GpioVibration

    hw = cfg.get("hardware", {})
    scale_cfg = hw.get("scale", {})
    step_cfg = hw.get("stepper", {})
    vibe_cfg = hw.get("vibration", {})
    pump_cfg = hw.get("pump", {})
    sens_cfg = hw.get("sensors", {})

    scale = HX711Scale(
        dt_pin=int(scale_cfg.get("dt_pin", 5)),
        sck_pin=int(scale_cfg.get("sck_pin", 6)),
        scale_factor=float(scale_cfg.get("scale_factor", 1.0)),
        samples=int(scale_cfg.get("samples", 5)),
    )
    stepper = TmcStepper(
        step_pin=int(step_cfg.get("step_pin", 12)),
        dir_pin=int(step_cfg.get("dir_pin", 13)),
        en_pin=int(step_cfg.get("en_pin", 16)),
        steps_per_sec=float(step_cfg.get("steps_per_sec", 800)),
        reverse=bool(step_cfg.get("reverse", False)),
        enable_active_low=bool(step_cfg.get("enable_active_low", True)),
    )
    vibration = GpioVibration(
        pin=int(vibe_cfg.get("pin", 17)),
        duty_percent=float(vibe_cfg.get("duty_percent", 80)),
    )
    pump = GpioPump(
        pin=int(pump_cfg.get("pin", 27)),
        ml_per_second=float(pump_cfg.get("ml_per_second", 25.0)),
    )
    cup = GpioDigitalSensor(
        pin=int(sens_cfg.get("cup_pin", 24)),
        active_high=bool(sens_cfg.get("cup_active_high", True)),
        name="cup",
    )
    level = GpioDigitalSensor(
        pin=int(sens_cfg.get("level_pin", 23)),
        active_high=bool(sens_cfg.get("level_active_high", False)),
        name="level",
    )
    flow = GpioDigitalSensor(
        pin=int(sens_cfg.get("flow_pin", 22)),
        active_high=True,
        name="flow",
    )
    return {
        "scale": scale,
        "stepper": stepper,
        "vibration": vibration,
        "pump": pump,
        "cup": cup,
        "level": level,
        "flow": flow,
        "mode": "pi",
    }


__all__ = [
    "Scale",
    "StepperMotor",
    "VibrationMotor",
    "Pump",
    "DigitalSensor",
    "create_hardware",
]
