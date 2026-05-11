---

## DUT Overview

| Parameter | Value |
|---|---|
| Module | `ALU` |
| Parameter W (Width) | 4-bit (configurable) |
| Parameter CMDWD | 4-bit (16 commands) |
| Modes | Arithmetic (MODE=1), Logical (MODE=0) |
| Total Operations | 27 |
| Output Width | 2×W (8-bit) |
| Design Style | Synchronous, Registered, Pipelined |

### Inputs

| Port | Width | Description |
|---|---|---|
| `CLK` | 1 | System clock |
| `RST` | 1 | Async active-high reset |
| `CE` | 1 | Chip enable |
| `MODE` | 1 | 1=Arithmetic, 0=Logical |
| `OPA` | W | Operand A |
| `OPB` | W | Operand B |
| `CIN` | 1 | Carry input |
| `CMD` | CMDWD | Operation select |
| `INP_VALID` | 2 | Operand validity |

### Outputs

| Port | Width | Description |
|---|---|---|
| `RES` | 2×W | Result |
| `COUT` | 1 | Carry out |
| `OFLOW` | 1 | Overflow flag |
| `G` | 1 | Greater-than flag |
| `L` | 1 | Less-than flag |
| `E` | 1 | Equal flag |
| `ERR` | 1 | Error flag |

---

## Operation Set

### Arithmetic Mode (MODE = 1)

| CMD | Operation | INP_VALID Required |
|---|---|---|
| 0 | ADD | 2'b11 |
| 1 | SUB | 2'b11 |
| 2 | ADD with Carry (CIN) | 2'b11 |
| 3 | SUB with Borrow (CIN) | 2'b11 |
| 4 | INC A | INP_VALID[0] |
| 5 | DEC A | INP_VALID[0] |
| 6 | INC B | INP_VALID[1] |
| 7 | DEC B | INP_VALID[1] |
| 8 | Compare (G, L, E) | 2'b11 |
| 9 | MULTI_INCRE — (A+1)×(B+1) | 2'b11 |
| 10 | MULTI_SHIFT — (A<<1)×B | 2'b11 |
| 11 | Signed ADD | 2'b11 |
| 12 | Signed SUB | 2'b11 |

### Logical Mode (MODE = 0)

| CMD | Operation | INP_VALID Required |
|---|---|---|
| 0 | AND | 2'b11 |
| 1 | NAND | 2'b11 |
| 2 | OR | 2'b11 |
| 3 | NOR | 2'b11 |
| 4 | XOR | 2'b11 |
| 5 | XNOR | 2'b11 |
| 6 | NOT A | INP_VALID[0] |
| 7 | NOT B | INP_VALID[1] |
| 8 | Shift Right A | INP_VALID[0] |
| 9 | Shift Left A | INP_VALID[0] |
| 10 | Shift Right B | INP_VALID[1] |
| 11 | Shift Left B | INP_VALID[1] |
| 12 | Rotate Left A by B | 2'b11 |
| 13 | Rotate Right A by B | 2'b11 |

---
### Testbench Components

| Component | Role |
|---|---|
| `test_arithmetic()` | Drives all 13 arithmetic operations |
| `test_logical()` | Drives all 14 logical operations |
| `test_multi()` | Multi-cycle multiply FSM testing |
| `apply_test()` | Core stimulus driver task |
| `compare_output()` | Scoreboard — compares all 7 outputs |
| `display_mismatch()` | Prints DUT vs REF on failure |
| Clock generator | 10ns period free-running clock |
| VCD dump | Full signal capture for waveform debug |

### Timing

- Standard operations: **1 clock cycle latency**
- Multiply operations (CMD=9,10): **2 clock cycle latency**
- Testbench wait: **3 clock cycles** after input drive
- Reset duration: **2 clock cycles** at simulation start

---

## Simulation Results

| Metric | Value |
|---|---|
| Total Test Cases | 118 |
| Passed | 90 |
| Failed | 28 |
| Pass Rate | 76.27% |

### Results by Category

| Category | Tests | Pass | Fail |
|---|---|---|---|
| Arithmetic (MODE=1) | 54 | 28 | 26 |
| CE=0 Hold State | 1 | 0 | 1 |
| Multi-cycle Multiply | 3 | 1 | 2 |
| Logical (MODE=0) | 60 | 61 | 1 |

### Known DUT Bugs

| # | Operation | Bug Description |
|---|---|---|
| 1 | ADD / ADD_CIN | Carry truncated — upper byte of RES always 0 on overflow |
| 2 | SUB / SUB_CIN | OFLOW flag not correctly derived for subtraction |
| 3 | DEC_A (OPA=0) | Result not extended into upper byte correctly |
| 4 | S_ADD / S_SUB | Sign extension missing in upper byte of RES |
| 5 | S_ADD / S_SUB (invalid IV) | ERR incorrectly asserted; comparison flags wrong |
| 6 | MULTI_INCRE / MULTI_SHIFT | Some operand combinations produce wrong result |
| 7 | Invalid CMD (14,15) | ERR not asserted for undefined commands |
| 8 | CE=0 Hold | Reference model mismatch on hold state ERR expectation |

---

**DUT Overall Coverage: 91.15%**
**Top-Level Overall Coverage: 88.41%**

## Tools Used

| Tool | Version | Purpose |
|---|---|---|
| Vivado | 2025.2 | RTL development, synthesis, initial simulation |
| Questa SIM | — | Primary functional verification, coverage collection |
| GTKWave | — | VCD waveform viewing (optional) |

---

## How to Run

### Questa SIM

```bash
# Compile
vlog ALU.v alu_reference_model.v alu_testbench.v

# Simulate with coverage
vsim -coverage work.alu_testbench

# Run and log
run -all

# Generate coverage report
coverage report -detail
```

### Vivado (Tcl Console)

```tcl
# Launch behavioural simulation
launch_simulation

# Run all
run all
```

---

## INP_VALID Encoding

| INP_VALID | Meaning |
|---|---|
| 2'b11 | Both OPA and OPB valid |
| 2'b10 | OPB only valid |
| 2'b01 | OPA only valid |
| 2'b00 | Neither valid — ERR asserted |

---

## Author Notes

- Design parameterised with `W=4` for this verification run
- Reference model used as golden model throughout —
  all pass/fail decisions based on reference output
- VCD file can be opened in GTKWave or Questa waveform
  viewer for signal-level debug of failing cases
- Coverage collected via Questa built-in coverage engine;
  screenshots saved under `/coverage`

