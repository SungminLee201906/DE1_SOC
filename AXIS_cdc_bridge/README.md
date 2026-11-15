# AXI4-Stream CDC Bridge (DE1-SoC)

## 1. Overview

This project moves an AXI4-Stream data stream safely from one clock domain (`wr_clk`) to another (`rd_clk`) on the DE1-SoC's Cyclone V FPGA, and checks itself while doing it. An LFSR generator produces a pseudo-random 8-bit stream, which passes through a skid buffer into an asynchronous FIFO that does the clock crossing using Gray-coded pointers and 2-flop synchronizers. On the read side, a second skid buffer feeds an LFSR checker that runs the same LFSR from the same seed, predicts every word, and counts any mismatches. Both ends can randomly throttle their side of the handshake, so the bridge is tested under backpressure, a FIFO that fills up, and a FIFO that runs empty. Lost, duplicated or corrupted data shows up as a non-zero error count. The ARM processor (HPS) starts, configures and monitors the bridge through two register blocks, one in each clock domain.

![AXI4-Stream CDC bridge block diagram](axis_cdc_bridge.png)

## 2. Features

## 3. Implementation

## 4. Registers

The ARM accesses two register blocks through the lightweight HPS-to-FPGA bridge (base `0xFF200000`). Each block is an Avalon-MM slave clocked by the domain it controls. Platform Designer inserts the clock crossing between the bus and each block, so no control or status signal crosses between `wr_clk` and `rd_clk` inside the design. The only crossing in the datapath is the async FIFO.

| Block   | Clock    | Base (proposed) | Controls                                  |
|---------|----------|-----------------|-------------------------------------------|
| WR_REGS | `wr_clk` | `0xFF200000`    | Generator, skid buffer A, FIFO write side |
| RD_REGS | `rd_clk` | `0xFF200100`    | Checker, skid buffer B, FIFO read side    |

Final base addresses are assigned in Platform Designer. Offsets below are in bytes from each block's base.

Access codes: RW = read/write, RO = read-only, W = write-only, SC = self-clearing (write 1 gives a one-cycle pulse, reads as 0), sticky = set by hardware and held until cleared.

### Reset levels

| Level | Source | Resets | Keeps |
|-------|--------|--------|-------|
| Hard reset | `h2f_rst_n` through the Platform Designer reset controller (one synchronizer per clock domain) | Everything, including both register blocks | Nothing |
| Soft reset | `CTRL.soft_reset` in each block | That block's side of the datapath: FIFO side, skid buffer, LFSR, counters, flags | Register values |
| Counter clear | `CTRL.counter_clear` in each block | That block's counters and flags only | LFSR, data in flight, register values |

`soft_reset` is a level, not a pulse, because both FIFO pointers must be in reset at the same time. Set it in both blocks, then clear it in both blocks. Disable both enables first; see Operational sequence for the exact order.

### WR_REGS (wr_clk)

| Offset | Name       | Access | Description                                        |
|--------|------------|--------|----------------------------------------------------|
| 0x00   | CTRL       | RW     | Enable, soft reset, error injection, counter clear |
| 0x04   | SEED       | RW     | Generator LFSR seed                                |
| 0x08   | THROTTLE   | RW     | Generator pause rate                               |
| 0x0C   | SENT_COUNT | RO     | Words sent by the generator                        |

#### WR CTRL (offset 0x00)

| Bits | Field         | Access | Reset | Description |
|------|---------------|--------|-------|-------------|
| 0    | enable        | RW     | 0     | 1 = generator sends words. 0 = generator pauses and keeps its state. |
| 1    | soft_reset    | RW     | 0     | 1 = hold the write side of the datapath in reset. The LFSR reloads from SEED. Registers keep their values. |
| 2    | inject_error  | W, SC  | 0     | Write 1 to corrupt exactly one word (XOR on the generator's output `tdata`; the LFSR sequence is not changed). After N writes, RD `ERR_COUNT` should equal N. |
| 3    | counter_clear | W, SC  | 0     | Write 1 to zero SENT_COUNT. |
| 31:4 | reserved      | RO     | 0     | Reads as 0. |

#### WR SEED (offset 0x04)

| Bits | Field    | Access | Reset | Description |
|------|----------|--------|-------|-------------|
| 7:0  | seed     | RW     | 0x01  | Generator LFSR start value. Loaded on reset or soft reset. Must be non-zero and must equal RD SEED. |
| 31:8 | reserved | RO     | 0     | Reads as 0. |

#### WR THROTTLE (offset 0x08)

| Bits | Field    | Access | Reset | Description |
|------|----------|--------|-------|-------------|
| 7:0  | throttle | RW     | 0     | Generator pause rate. Sends a word in a cycle when its random value ≥ throttle. 0 = full speed, 128 ≈ half speed, 255 ≈ almost stopped. |
| 31:8 | reserved | RO     | 0     | Reads as 0. |

#### WR SENT_COUNT (offset 0x0C)

| Bits | Field      | Access | Reset | Description |
|------|------------|--------|-------|-------------|
| 31:0 | sent_count | RO     | 0     | Words accepted from the generator (tvalid && tready). Cleared by reset, soft reset or counter clear. Wraps at 2³². |

### RD_REGS (rd_clk)

| Offset | Name       | Access | Description                              |
|--------|------------|--------|------------------------------------------|
| 0x00   | CTRL       | RW     | Enable, soft reset, counter clear        |
| 0x04   | SEED       | RW     | Checker LFSR seed                        |
| 0x08   | THROTTLE   | RW     | Checker backpressure rate                |
| 0x0C   | STATUS     | RO     | Error status                             |
| 0x10   | WORD_COUNT | RO     | Words received by the checker            |
| 0x14   | ERR_COUNT  | RO     | Mismatched words seen by the checker     |

#### RD CTRL (offset 0x00)

| Bits | Field         | Access | Reset | Description |
|------|---------------|--------|-------|-------------|
| 0    | enable        | RW     | 0     | 1 = checker accepts words. 0 = checker holds `tready` low and keeps its state. |
| 1    | soft_reset    | RW     | 0     | 1 = hold the read side of the datapath in reset. The LFSR reloads from SEED. Registers keep their values. |
| 2    | reserved      | RO     | 0     | Kept free so bit positions match WR CTRL. |
| 3    | counter_clear | W, SC  | 0     | Write 1 to zero WORD_COUNT, ERR_COUNT and STATUS.error_seen. |
| 31:4 | reserved      | RO     | 0     | Reads as 0. |

#### RD SEED (offset 0x04)

| Bits | Field    | Access | Reset | Description |
|------|----------|--------|-------|-------------|
| 7:0  | seed     | RW     | 0x01  | Checker LFSR start value. Loaded on reset or soft reset. Must be non-zero and must equal WR SEED. |
| 31:8 | reserved | RO     | 0     | Reads as 0. |

#### RD THROTTLE (offset 0x08)

| Bits | Field    | Access | Reset | Description |
|------|----------|--------|-------|-------------|
| 7:0  | throttle | RW     | 0     | Checker backpressure rate. Accepts a word in a cycle when its random value ≥ throttle. 0 = always ready, higher = drops `tready` more often. |
| 31:8 | reserved | RO     | 0     | Reads as 0. |

#### RD STATUS (offset 0x0C)

| Bits | Field      | Access     | Reset | Description |
|------|------------|------------|-------|-------------|
| 0    | error_seen | RO, sticky | 0     | Set on the first mismatched word. Cleared by reset, soft reset or counter clear. |
| 31:1 | reserved   | RO         | 0     | Reads as 0. |

#### RD WORD_COUNT (offset 0x10)

| Bits | Field      | Access | Reset | Description |
|------|------------|--------|-------|-------------|
| 31:0 | word_count | RO     | 0     | Words accepted by the checker. Cleared by reset, soft reset or counter clear. Wraps at 2³². When it equals WR SENT_COUNT, every sent word has reached the checker. |

#### RD ERR_COUNT (offset 0x14)

| Bits | Field     | Access | Reset | Description |
|------|-----------|--------|-------|-------------|
| 31:0 | err_count | RO     | 0     | Accepted words that did not match the checker's prediction. Cleared by reset, soft reset or counter clear. |

## 5. Interface

| Signal         | Dir | Width | Clock    | Description |
|----------------|-----|-------|----------|-------------|
| `wr_clk`       | in  | 1     |          | Write-side clock |
| `wr_rst`       | in  | 1     | `wr_clk` | Write-side reset, active high |
| `gen_enable`   | in  | 1     | `wr_clk` | Enables LFSR Generator |
| `gen_clear`    | in  | 1     | `wr_clk` | Clear `sent_count` |
| `gen_inject`   | in  | 1     | `wr_clk` |  One-cycle pulse: XOR the next accepted word's `tdata` to create exactly one error (LFSR sequence unchanged; |
| `gen_seed`     | in  | 8     | `wr_clk` | LFSR Generator seed value |
| `gen_throttle` | in  | 8     | `wr_clk` | LFSR Generator pause rate |
| `sent_count`   | out | 32    | `wr_clk` | Counter increments after every word sent |
| `rd_clk`       | in  | 1     |          | Read-side clock |
| `rd_rst`       | in  | 1     | `rd_clk` | Read-side reset, active high |
| `chk_enable`   | in  | 1     | `rd_clk` | Enables the LFSR checker |
| `chk_clear`    | in  | 1     | `rd_clk` | Clears `word_count`, `err_count`, `error_seen` |
| `chk_seed`     | in  | 8     | `rd_clk` | LFSR Checker seed value |
| `chk_throttle` | in  | 8     | `rd_clk` | LFSR Checker backpressure rate |
| `word_count`   | out | 32    | `rd_clk` | Counts number of words recieved on the LFSR checker side |
| `err_count`    | out | 32    | `rd_clk` | Counter increments after every mismatched words is detected |
| `error_seen`   | out | 1     | `rd_clk` | Error flag. Level held after first error detected |