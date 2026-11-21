## Workflow (DE1-SoC)

### Board and tools

| Item | Value |
|------|-------|
| Board | Terasic DE1-SoC |
| FPGA | Cyclone V SoC, 5CSEMA5F31C6 |
| Synthesis | Quartus Prime Lite 18.1 (`C:\intelFPGA_lite\18.1\quartus\bin64`) |
| Simulation | ModelSim – Intel FPGA Edition 10.5b (on PATH) |
| Shell | Windows PowerShell |
| Helper commands | `tools.ps1` in the repo root |

### First-time setup

The short commands below (`qlint`, `run_test`, `qcompile`, ...) are PowerShell functions defined in `tools.ps1`. Each new PC needs to load that file once through the PowerShell profile.

1. **Install the tools:** Quartus Prime Lite 18.1 with ModelSim – Intel FPGA Edition. If Quartus is installed somewhere else, change the `$QUARTUS` line at the top of `tools.ps1`.
2. **Allow local scripts** (once per user):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
3. **Create the profile** if it does not exist, and open it:
   ```powershell
   if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
   notepad $PROFILE
   ```
4. **Add this line** to the profile and save (change the path if the repo is cloned elsewhere):
   ```powershell
   . C:\DE1_SOC\tools.ps1
   ```
5. **Load it** by opening a new terminal, or run `. $PROFILE`.
6. **Check:** from a project folder, `qlint` should end with `Errors: 0`.

The leading `. ` (dot-source) matters: it loads the functions into the terminal. Running `tools.ps1` without it does nothing lasting.

### Project layout

```
<project>/
├── RTL/            SystemVerilog sources
├── tb/             testbenches, named *_tb.sv
├── logs/           generated simulation files (ModelSim library in logs/work), gitignored
├── <project>.qpf   Quartus project
├── <project>.qsf   Quartus settings (device, top module, files, pins)
└── <project>.sdc   timing constraints
```

### Commands

Run every command from the project folder (for example `C:\DE1_SOC\AXIS_cdc_bridge`). Commands that take a project name default to the folder name.

| Command | What it does |
|---------|--------------|
| `qlint` | Compile all RTL in ModelSim to check for errors |
| `run_test <tb>` | Compile RTL + testbench and run in the terminal; prints PASS / FAIL and quits |
| `run_test <tb> -gui` | Same, but opens the ModelSim GUI with waves |
| `qnew [project] [top]` | Create the Quartus `.qpf` / `.qsf` from `RTL/` (refuses to overwrite an existing `.qsf`) |
| `qcompile [project]` | Full Quartus compile (synthesis, fit, assemble, timing) |
| `qsta [project]` | Run timing analysis again on the last compile |
| `qprog [project]` | Program the FPGA over JTAG (USB-Blaster II; the FPGA is device 2 on the chain) |
| `qclean` | Delete Quartus build output (`db/`, `incremental_db/`, `output_files/`) in the current folder |

`run_test` defaults to `axis_cdc_bridge_tb` when no testbench is given.

### Typical flow

1. Edit RTL in `RTL/`.
2. `qlint`: fix any compile errors.
3. `run_test <module>_tb`: confirm PASS. Add `-gui` to open waves when debugging.
4. `qcompile`: check the compile report and timing (`output_files/<project>.sta.rpt`).
5. `qprog`: load the bitstream onto the board.
6. Commit the sources only (see below).

### Troubleshooting

| Problem | Fix |
|---------|-----|
| `qlint` is not recognized | The profile isn't loaded: check that `Get-Content $PROFILE` shows the `tools.ps1` line, then run `. $PROFILE` |
| "running scripts is disabled" | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| `vlog-66: Execution of vlib.exe failed` | Use the helpers (they create `logs/work`), or pass `-work logs/work` to `vlog` |
| VS Code terminal can't find the commands | VS Code may use a different PowerShell; check `$PROFILE` in that terminal and add the same line there |

### What not to commit

Generated output is listed in `.gitignore` and must not be committed:
`db/`, `incremental_db/`, `output_files/`, `logs/`, `work/`, `transcript`, `vsim.wlf`.
