/*
SPDX-License-Identifier: Apache-2.0

Copyright 2026 Geeth Sathsara

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/


// Memory Map
// BASE = 0x3000_0000
// OFFSET      NAME        ATTR        STRUCTURE
// 0x00        TXDATA      RO,RW       [31] full  [7:0] data        #
// 0x04        RXDATA      RO,RO       [31] empty [7:0] data        #
// 0x08        TXCTRL      RW          [31:1]watermark [0] en
// 0x0c        RXCTRL      RW          [31:1]watermark [0] en
// 0x10        IE          RW          [1] rx_ie [0] tx_ie
// 0x14        IP          RO          [1] rx_ip [0] tx_ip
// 0x18        DIV         RW          [31:0]  div                  #

/* verilator lint_off MULTIDRIVEN */
/* verilator lint_off WIDTHTRUNC */
module uart_mmio #(
    parameter BASE_ADDR = 32'h3000_0000,
    parameter RX_DEPTH  = 8,
    parameter TX_DEPTH  = 8
)(
    input  logic         i_clk,
    input  logic         i_rst_n,

    input  logic         i_req_valid,
    output logic         o_req_ready,
    input  logic [31:0]  i_req_addr,
    input  logic [31:0]  i_req_wdata,
    input  logic [3:0]   i_req_wmask,
    output logic         o_resp_valid,
    output logic [31:0]  o_resp_rdata,
    input  logic         i_resp_ready,

    input  logic         i_rx,
    output logic         o_tx
);
    /* UART begin */
    logic [7:0]  w_tx_data, w_rx_data;
    logic        w_tx_valid, w_tx_ready;
    logic        w_rx_valid, w_rx_ready;
    logic        w_tx_full, w_rx_empty;
    logic [31:0] w_div;
    logic [$clog2(TX_DEPTH+1)-1:0] w_tx_level;
    logic [$clog2(RX_DEPTH+1)-1:0] w_rx_level;

    uart #(
        .RX_DEPTH(RX_DEPTH),
        .TX_DEPTH(TX_DEPTH),
        .PARITY_EN(0),
        .EN_2STOP_BITS(0)
    ) uart_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_baud_div(w_div),

        .o_deq_rx_data(w_rx_data),
        .o_deq_rx_ready(w_rx_ready),
        .i_deq_rx_valid(w_rx_valid),

        .o_rx_full(),
        .o_rx_empty(w_rx_empty),
        .o_rx_level(w_rx_level),

        .i_enq_tx_data(w_tx_data),
        .i_enq_tx_valid(w_tx_valid),
        .o_enq_tx_ready(w_tx_ready),

        .o_tx_full(w_tx_full),
        .o_tx_empty(),
        .o_tx_level(w_tx_level),


        .i_rx(i_rx),
        .o_tx(o_tx)
    );
    /* UART end */

    /* MMIO registers begin */
    logic [31:0] r_txdata, r_rxdata;
    logic [31:0] r_txctrl, r_rxctrl;
    logic [31:0] r_ie, r_ip;
    logic [31:0] r_div;
    /* MMIO registers end */

    /* handshaking begin */
    logic resp_pending;
    assign o_req_ready  = !resp_pending;
    assign o_resp_valid = resp_pending;
    /* handshaking end */


    /* reg read from cpu begin */
    assign o_resp_rdata =
        (i_req_addr[4:0] == 5'h00) ? r_txdata :
        (i_req_addr[4:0] == 5'h04) ? r_rxdata :
        (i_req_addr[4:0] == 5'h08) ? r_txctrl :
        (i_req_addr[4:0] == 5'h0c) ? r_rxctrl :
        (i_req_addr[4:0] == 5'h10) ? r_ie:
        (i_req_addr[4:0] == 5'h14) ? r_ip :
        (i_req_addr[4:0] == 5'h18) ? r_div :
                                      32'b0;

    assign w_rx_valid = i_req_valid && o_req_ready && r_rxctrl[0] && i_req_addr[4:0] == 5'h04; // let uart know you consume/deq one rx
    /* reg read from cpu end */



    /* reg read from uart begin */
    assign w_div = r_div;
    assign w_tx_data = r_txdata[7:0];
    /* reg read from uart end */



    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_txdata     <= 0;
            r_rxdata     <= 0;
            r_txctrl     <= 0;
            r_rxctrl     <= 0;
            r_ie         <= 0;
            r_ip         <= 0;
            r_div        <= 32'd1085;

            w_tx_valid       <= 0;
        /* handshaking begin */
            resp_pending <= 1'b0;
        end else begin
            w_tx_valid       <= 0;
            resp_pending     <= resp_pending && !i_resp_ready;

            /* reg write from uart begin */
            r_rxdata        <= {w_rx_empty, 23'b0, w_rx_data};
            r_txdata[31]    <= w_tx_full;

            r_ip[0]         <= r_ie[0] && (r_txctrl[31:0] <= w_tx_level);
            r_ip[1]         <= r_ie[1] && (r_rxctrl[31:0] <= w_rx_level);
            /* reg write from uart end */

            if (i_req_valid && o_req_ready) begin
        /* handshaking end */
                /* reg write from cpu begin */
                case (i_req_addr[4:0])
                    5'h00: begin
                        r_txdata[7:0]    <= i_req_wdata[7:0];
                        w_tx_valid       <= ((i_req_wmask != 0) && r_txctrl[0]) ? 1'b1: 1'b0;
                    end
                    5'h04:;
                    5'h08: begin
                        r_txctrl         <= i_req_wdata;
                    end
                    5'h0c: begin
                        r_rxctrl         <= i_req_wdata;
                    end
                    5'h10: begin
                        r_ie             <= i_req_wdata[1:0];
                    end
                    5'h14:;
                    5'h18: begin      
                        r_div    <= i_req_wdata;
                    end
                    default:;
                endcase
                resp_pending <= 1'b1;
            end
        end
    end
                /* reg write from cpu end */
endmodule : uart_mmio
