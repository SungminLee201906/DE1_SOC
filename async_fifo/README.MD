# Asynchronous FIFO (DE1-SoC)

A dual-clock FIFO in SystemVerilog: data is written in one clock domain and read in another, with the two clocks unrelated. Target board: Terasic DE1-SoC (Cyclone V `5CSEMA5F31C6`). Tools: Quartus Prime Lite 18.1, ModelSim.

## Specs

| Item | Value |
|---|---|
| Data width | 8 bits |
| Depth | 16 words |
| Pointer width | 5 bits (4 address bits + 1 wrap bit) |
| Clocks | independent `wr_clk` and `rd_clk` |
| Reset | active high, asynchronous, one per domain |

## How it works

Data sits in a small memory. A write pointer (write clock domain) and a read pointer (read clock domain) track where the next word goes and where the next word comes from.

- **Gray-coded pointers.** Each pointer is converted to Gray code before it crosses to the other domain. Only one bit changes per step, so a pointer sampled mid-change is never badly wrong.
- **2-flop synchronizers.** Each Gray pointer passes through two flip-flops in the receiving domain to settle any metastability.
- **Empty flag (read side).** Asserted when the next Gray read pointer equals the synchronized Gray write pointer.
- **Full flag (write side).** Asserted when the next Gray write pointer equals the synchronized Gray read pointer with its top two bits inverted.
- **Wrap bit.** The extra pointer bit lets full and empty be told apart when the addresses are equal.

Because the pointers are synchronized, the flags can lag by a cycle or two. They can be late, but they are never wrong in the unsafe direction: full is never missed, and empty is never missed.

## Modules (`RTL/`)

| File | Module | Purpose |
|---|---|---|
| `async_FIFO.sv` | `async_FIFO` | Top level, wires everything together |
| `write_pointer.sv` | `write_pointer` | Binary and Gray write pointer, `wr_full` |
| `read_pointer.sv` | `read_pointer` | Binary and Gray read pointer, `rd_empty` |
| `synchronizer.sv` | `synchronizer` | Parameterized 2-flop synchronizer |
| `asynch_FIFO_mem.sv` | `async_FIFO_mem` | 16 x 8 memory |

## Ports (`async_FIFO`)

| Port | Dir | Description |
|---|---|---|
| `wr_clk`, `rd_clk` | in | Write and read clocks |
| `wr_rst`, `rd_rst` | in | Active-high resets |
| `wr_inc` | in | Write request (ignored when full) |
| `wr_data[7:0]` | in | Data to write |
| `rd_inc` | in | Read request (ignored when empty) |
| `rd_data[7:0]` | out | Data at the head of the FIFO |
| `wr_full` | out | FIFO is full (write domain) |
| `rd_empty` | out | FIFO is empty (read domain) |

`rd_data` shows the oldest word whenever `rd_empty` is low. Assert `rd_inc` for one read clock to consume it.

## Usage

Commands assume the PowerShell helpers from the project setup (`qlint`, `qcompile`, `qsta`).

```powershell
qlint    async_FIFO     # syntax check with ModelSim
qcompile async_FIFO     # full Quartus compile; reports in logs\
```

Simulation (from the project folder):

```
vlib work
vlog -sv RTL/*.sv tb_async_FIFO.sv
vsim -c tb_async_FIFO -do "run -all; quit"
```

The testbench uses unrelated clocks (50 MHz and about 37 MHz) and checks reset state, full, empty, ordering, and 200 random concurrent reads and writes against a scoreboard.

## Timing

Constraints are in `async_FIFO.sdc`: a clock for each domain, and the two domains declared asynchronous. Crossing safety comes from the Gray code and synchronizers, not from the timing report.

## Status and known issues

- [x] Pointer, synchronizer, memory and top-level modules written
- [x] Quartus compile passes
- [ ] Testbench run and passing
- [ ] Pin assignments for the DE1-SoC
- [ ] Memory read is asynchronous. Quartus infers a block RAM with the read address registered on `wr_clk`, which does not match simulation. Fix by forcing logic cells (`ramstyle = "logic"`) or by making the read synchronous.

## Repository layout

```
async_fifo/
  RTL/          SystemVerilog sources
  logs/         compile reports (generated, not tracked)
```
