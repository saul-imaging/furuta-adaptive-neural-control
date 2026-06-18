# Furuta Adaptive Neural Control

MATLAB/Simulink project for evaluating a single-neuron adaptive neural controller (ANC) on a nonlinear Furuta pendulum model and comparing it against an LQR baseline.

## Highlights

- Simulates the nonlinear Furuta pendulum in Simulink.
- Computes tracking and control-effort metrics including RMSE, maximum angular error, ISE, ITSE, RMS torque, and peak torque.
- Includes representative results for two neural learning-rate settings (`alpha = 50` and `alpha = 1000`).

## Repository Structure

```text
.
├── matlab/
│   └── Metricas_CCE.m
├── models/
│   └── Furuta_sim.slx
└── results/
    ├── alpha_50/
    ├── alpha_1000/
    └── comparison/
```

## Requirements

- MATLAB
- Simulink
- Control System Toolbox recommended for LQR workflows

## Usage

1. Open `models/Furuta_sim.slx` in MATLAB/Simulink.
2. Run the simulation so that the output object `out` exists in the MATLAB workspace.
3. Run:

```matlab
run("matlab/Metricas_CCE.m")
```

The script computes tracking and control-effort metrics and writes generated CSV tables under `results/generated_tables`.

## Notes

- Build folders, Simulink cache files, generated binaries, and local Word/PDF drafts are intentionally excluded.
- Results included in this repository are lightweight reference artifacts for portfolio review.

