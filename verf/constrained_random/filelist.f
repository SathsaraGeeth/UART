# --------------------------
# Include directories
# --------------------------
+incdir+/home/geeth/AltairDSim/2026/uvm/1.2/src
+incdir+../rtl/interfaces
+incdir+./agents
+incdir+./sequences
+incdir+./coverage
+incdir+./tests
+incdir+./tb
+incdir+../rtl

# --------------------------
# Interface
# --------------------------
../../rtl/interfaces/uart_if.sv

# --------------------------
# Sequences / Transactions
# --------------------------
sequences/uart_txn.sv
sequences/uart_seq.sv
sequences/uart_seqr.sv

# --------------------------
# Agents
# --------------------------
agents/uart_drv.sv
agents/uart_mon.sv
agents/uart_scb.sv
agents/uart_agent.sv
agents/uart_env.sv

# --------------------------
# Coverage
# --------------------------
// coverage/uart_coverage.sv


# --------------------------
# RTL (DUT)
# --------------------------
../../rtl/core/uart.sv
../../rtl/core/uart_mmio.sv

# --------------------------
# Testbench Top
# --------------------------
tb/uart_tb_top.sv

# --------------------------
# Tests
# --------------------------
tests/uart_test.sv