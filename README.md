## Workflow (DE1-SoC)

### Board and tools

| Item | Value |
|------|-------|
| Board | Terasic DE1-SoC |
| FPGA | Cyclone V SoC, 5CSEMA5F31C6 |
| Synthesis | Quartus Prime Lite 18.1 (`C:\intelFPGA_lite\18.1\quartus\bin64`) |
| Simulation | ModelSim – Intel FPGA Edition 10.5b (on PATH) |
| Build tool | `mingw32-make` (`C:\MinGW\bin`) |
| Shell | PowerShell |

### Project layout

    <project>/
    ├── RTL/            SystemVerilog sources
    ├── tb/             testbenches, named *_tb.sv
    ├── logs/           generated simulation files (ModelSim library in logs/work) — gitignored
    ├── Makefile        lint, simulation and Quartus targets
    ├── <project>.qpf   Quartus project
    ├── <project>.qsf   Quartus settings (device, top module, files, pins)
    └── <project>.sdc   timing constraints

### Commands

Run every command from the project folder (for example `C:\DE1_SOC\AXIS_cdc_bridge`).
The real commands live in the `Makefile`; the short names are PowerShell profile functions that call it.

| Short command | Make target | What it does |
|---------------|-------------|--------------|
| `qlint` | `mingw32-make lint` | Compile all RTL in ModelSim to check for errors |
| `run_test <tb>` | `mingw32-make sim TB=<tb>` | Compile RTL + testbench, run in the ModelSim GUI with waves |
| `run_testc <tb>` | `mingw32-make simc TB=<tb>` | Same, terminal only; prints PASS / FAIL and quits |
| `qnew` | `mingw32-make project` | Create the Quartus project from `RTL/` (refuses to overwrite an existing `.qsf`) |
| `qcompile` | `mingw32-make compile` | Full Quartus compile (synthesis, fit, assemble, timing) |
| `qsta` | `mingw32-make sta` | Run timing analysis again on the last compile |
| `qprog` | `mingw32-make prog` | Program the FPGA over JTAG (USB-Blaster II, FPGA is device 2 on the chain) |
| `qclean` | `mingw32-make clean` | Delete Quartus build output (`db/`, `incremental_db/`, `output_files/`) |

`run_test` and `run_testc` default to `axis_cdc_bridge_tb` when no testbench is given.

### Typical flow

1. Edit RTL in `RTL/`.
2. `qlint`: fix any compile errors.
3. `run_testc <module>_tb`: confirm PASS. Use `run_test` to open waves when debugging.
4. `qcompile`: check the compile report and timing (`output_files/<project>.sta.rpt`).
5. `qprog`: load the bitstream onto the board.
6. Commit the sources only (see below).

### What not to commit

Generated output is listed in `.gitignore` and must not be committed:
`db/`, `incremental_db/`, `output_files/`, `logs/`, `work/`, `transcript`, `vsim.wlf`.

