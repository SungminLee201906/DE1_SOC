# ---- DE1-SoC helpers: run from a project folder (e.g. C:\DE1_SOC\AXIS_cdc_bridge) ----
$QUARTUS = "C:\intelFPGA_lite\18.1\quartus\bin64"

function _proj { (Get-Item .).Name }                       # default project name = folder name
function _lib  { if (!(Test-Path logs\work)) { vlib logs/work | Out-Null } }

# Lint all RTL
function qlint {
    _lib
    vlog -work logs/work -sv (Get-ChildItem RTL\*.sv).FullName
}

# Run a testbench. Terminal by default; add -gui for ModelSim with waves.
function run_test([string]$tb = "axis_cdc_bridge_tb", [switch]$gui) {
    _lib
    vlog -work logs/work -sv (Get-ChildItem RTL\*.sv).FullName "tb\$tb.sv"
    if ($LASTEXITCODE -ne 0) { return }
    if ($gui) { vsim -lib logs/work -voptargs="+acc" $tb -do "onfinish stop; add wave -r /$tb/*; run -all" }
    else      { vsim -c -lib logs/work $tb -do "run -all; quit -f" }
}

# Create a Quartus project from RTL\ (refuses to overwrite an existing .qsf)
function qnew([string]$proj = (_proj), [string]$top = (_proj)) {
    if (Test-Path "$proj.qsf") { Write-Host "$proj.qsf already exists"; return }
    "PROJECT_REVISION = `"$proj`"" | Set-Content -Encoding ascii "$proj.qpf"
    $qsf = @(
        "set_global_assignment -name FAMILY `"Cyclone V`""
        "set_global_assignment -name DEVICE 5CSEMA5F31C6"
        "set_global_assignment -name TOP_LEVEL_ENTITY $top"
        "set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files"
    )
    Get-ChildItem RTL\*.sv | ForEach-Object { $qsf += "set_global_assignment -name SYSTEMVERILOG_FILE RTL/$($_.Name)" }
    $qsf | Set-Content -Encoding ascii "$proj.qsf"
}

function qcompile([string]$proj = (_proj)) { & "$QUARTUS\quartus_sh.exe" --flow compile $proj }
function qsta([string]$proj = (_proj))     { & "$QUARTUS\quartus_sta.exe" $proj }

# DE1-SoC JTAG chain: device 1 = HPS, device 2 = FPGA
function qprog([string]$proj = (_proj))    { & "$QUARTUS\quartus_pgm.exe" -m jtag -o "p;output_files\$proj.sof@2" }

# Delete Quartus build output in the current folder
function qclean { Remove-Item db, incremental_db, output_files -Recurse -Force -ErrorAction SilentlyContinue }
