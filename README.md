# UART Module

This project implements a configurable, asynchronous UART (Universal Asynchronous Receiver Transmitter) in System Verilog. It supports 8N1 or 8N2 formats, and includes FIFO buffers for both RX (reciever) and TX (transmitter) paths.

Designed for ASIC/FPGA SoC designs.

---

## Features

### 1. Configurable frame format
- **8N1** – 1 start bit, 8 data bits, no parity, 1 stop bit
- **8N2** – 1 start bit, 8 data bits, no parity, 2 stop bits
- **Optional parity (template only)**
  - Not implemented, as it is rare in practice
  - Structural template provided for extension


### 2. Configurable baud rate
- Configured using `i_baud_div`
- Divider calculation:
```
baud_div = i_clk_freq / baud_rate
```
- **No `+1` is required**
- Internal counters run from `0` to `baud_div-1`

### 3. Configurable FIFO depth
- Independent RX and TX FIFOs
- Default depth: **8 entries** and is recommended for most designs

### 4. Robust RX sampling
- **16× oversampling**
- **3 sample majority voting** around mid-bit
- Tolerant to clock mismatch and jitter


### 5. Start-bit detection
- Uses the standard **mid-bit start detection**
- Prevents false start detection due to noise

### 6. MMIO interface
- A reference MMIO interface with basic control and interrupt support is provided.
- It is highly encouraged to use a custom wrapper that matches your SoC’s MMIO and interconnect specifications. This keeps the UART core portable and reusable.

---

## Usage

### 1. Instantiate the UART

```systemverilog
uart #(
    .RX_DEPTH(8),
    .TX_DEPTH(8),
    .PARITY_EN(0),
    .EN_2STOP_BITS(0)
) uart0 (
    .i_clk(clk),
    .i_rst_n(rst_n),
    .i_baud_div(baud_div),

    .i_enq_tx_data(tx_data),
    .i_enq_tx_valid(tx_valid),
    .o_enq_tx_ready(tx_ready),

    .o_tx(tx),
    .i_rx(rx),

    .o_deq_rx_data(rx_data),
    .o_deq_rx_ready(rx_ready),
    .i_deq_rx_valid(rx_valid)
);
```

### 2. Configure baud rate

```c
baud_div = i_clk_freq / baud_rate;
```

Example:
- `i_clk = 125 MHz`
- `baud = 115200`
- `baud_div = 1085`


## 3. Port Definition

| Name | Direction | Width | Description |
|-----|-----------|-------|-------------|
| i_clk | input | 1 | System clock |
| i_rst_n | input | 1 | Active-low reset |
| i_baud_div | input | 32 | Baud divider |
| i_enq_tx_data | input | 8 | TX data |
| i_enq_tx_valid | input | 1 | TX enqueue valid |
| o_enq_tx_ready | output | 1 | TX ready |
| o_tx_full | output | 1 | TX FIFO full |
| o_tx_empty | output | 1 | TX FIFO empty |
| o_tx_level | output | log2(TX_DEPTH+1) | TX FIFO occupancy |
| o_deq_rx_data | output | 8 | RX data |
| o_deq_rx_ready | output | 1 | RX dequeue ready |
| i_deq_rx_valid | input | 1 | RX dequeue valid |
| o_rx_full | output | 1 | RX FIFO full |
| o_rx_empty | output | 1 | RX FIFO empty |
| o_rx_level | output | log2(RX_DEPTH+1) | RX FIFO occupancy |
| i_rx | input | 1 | Serial RX line |
| o_tx | output | 1 | Serial TX line |

---

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| RX_DEPTH | 8 | RX FIFO depth |
| TX_DEPTH | 8 | TX FIFO depth |
| PARITY_EN | 0 | Enable parity (not implemented) |
| EN_2STOP_BITS | 0 | Enable 2 stop bits |

---

## Notes

1. **Hardware testing**
   - Tested on Zynq-7020 with a custom SoC
   - Resource usage depends on FIFO depth and configuration.
   - For default configuration on Zynq-7020:
        - LUTs:                     204
        - FFs:                      128
        - LUTRAM:                   12
        - Max Clock Speed:          212 MHz

2. **Simulation**
   - cocotb + Verilator based testbench included
   - May be useful during development and refactoring

3. **Verification**
   - UVM-based constrained random verification not included in this repository
