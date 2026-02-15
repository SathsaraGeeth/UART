# MIT License

# Copyright (c) 2026 Geeth Sathsara

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
from pathlib import Path
import os
import random

async def gen_clk(dut, period_ns=10):
    while True:
        dut.i_clk.value = 0
        await Timer(period_ns/2, unit="ns")
        dut.i_clk.value = 1
        await Timer(period_ns/2, unit="ns")

async def reset(dut, cycles=2):
        dut.i_rst_n.value = 0
        for _ in range(cycles):
            await RisingEdge(dut.i_clk)
        dut.i_rst_n.value = 1
        dut.i_baud_div.value = 512
        await RisingEdge(dut.i_clk)

async def cycle(dut, cycle_ctr):
     cycle_ctr += 1
     print("------------ Cycle:", cycle_ctr, "--------------")
     await RisingEdge(dut.i_clk)

def probe_tx (dut):
    print("o_tx:", int(dut.o_tx.value))

def probe_tx_state (dut):
    states = [  "TX_IDLE",
                "TX_START",
                "TX_D0",
                "TX_D1",
                "TX_D2",
                "TX_D3",
                "TX_D4",
                "TX_D5",
                "TX_D6",
                "TX_D7",
                "TX_PARITY",
                "TX_STOP0",
                "TX_STOP1"]
    print("shfreg:", format(int(dut.r_tx_shft_reg.r_shft_reg.value), "08b"))
    print(f"TX level: {int(dut.o_tx_level.value)}, TX full: {bool(dut.o_tx_full.value)}, TX empty: {bool(dut.o_tx_empty.value)} ")
    print("tx_state:", states[int(dut.s_tx_state.value)], "next state:", states[int(dut.s_tx_next.value)])

async def log_tick(dut):
    baud = 0
    samp = 0
    while True:
        await RisingEdge(dut.i_clk)
        baud_tick = int(dut.w_baud_tick.value)
        samp_tick = int(dut.w_samp_tick.value)

        if baud_tick and not baud:
            print(f"[{cocotb.utils.get_sim_time('ns')}] Baud tick")
        if samp_tick and not samp:
            print(f"[{cocotb.utils.get_sim_time('ns')}] Sample tick")

        baud = baud_tick
        samp = samp_tick
        

async def enq_tx(dut, data=0b11101011):
    dut.i_enq_tx_data.value = data
    while not int(dut.o_enq_tx_ready.value):
        await RisingEdge(dut.i_clk)
    dut.i_enq_tx_valid.value = 1
    print(f"Enqueuing TX data: {data:08b}")
    await RisingEdge(dut.i_clk)
    dut.i_enq_tx_valid.value = 0


def inject_rx(dut, rx_bit = 0):
    print("rx:", rx_bit)
    dut.i_rx.value = rx_bit

def inject_random(dut):
    rx_bit = random.choices([0, 1], weights=[1, 10])[0]
    print("rx:", rx_bit)
    dut.i_rx.value = rx_bit

def loopback(dut):
    print("tx/rx:", int(dut.i_rx.value))
    dut.i_rx.value = dut.o_tx.value

def probe_rx_state (dut):
    states = [  "RX_IDLE",
                "RX_START_DETECT",
                "RX_D0",
                "RX_D1",
                "RX_D2",
                "RX_D3",
                "RX_D4",
                "RX_D5",
                "RX_D6",
                "RX_D7",
                "RX_PARITY",
                "RX_STOP0",
                "RX_STOP1"]
    print("shfreg:", format(int(dut.r_rx_shft_reg.r_shft_reg.value), "08b"))
    print(f"RX level: {int(dut.o_rx_level.value)}, RX full: {bool(dut.o_rx_full.value)}, RX empty: {bool(dut.o_rx_empty.value)}")
    print("RX_state:", states[int(dut.s_rx_state.value)])


@cocotb.test()
async def test(dut):    
    cocotb.start_soon(gen_clk(dut, 10))
    cocotb.start_soon(log_tick(dut))
    await reset(dut)
    cycles = 0

    # loopback test ON
    while (cycles < 100):
        inject_rx(dut, 1)
        cycles += 1
        await cycle(dut, cycles)
    # loopback test OFF


    await enq_tx(dut, 0b11001011)
    
    while (cycles < 10000):
        #  TX test ON
        #  probe_tx_state(dut)
        #  print("#########")
        #  probe_tx(dut)
        #  TX test OFF


        # loopback test ON
        loopback(dut)
        probe_rx_state(dut)
        print("#########")
        probe_tx_state(dut)
        # loopback test OFF


        await cycle(dut, cycles)
        cycles += 1
    
    # print(dut.rx_buffer.mem_buff.value)
    # print(dut.tx_buffer.mem_buff.value)





def run():
    sim = os.getenv("SIM", "verilator")
    project_dir = Path(__file__).parent.parent.parent/"rtl"
    sources = [
        project_dir / "uart.sv"
    ]
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart",
        always=True,
    )
    runner.test(
        hdl_toplevel="uart",
        test_module="tb_uart",
    )
if __name__ == "__main__":
    run()
