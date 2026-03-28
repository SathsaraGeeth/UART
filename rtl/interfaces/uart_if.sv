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

interface uart_if #(
    parameter RX_DEPTH          = 8,
    parameter TX_DEPTH          = 8,
    parameter PARITY_EN         = 0,
    parameter EN_2STOP_BITS     = 0
);
    logic                           clk;
    logic                           rst_n;

    logic  [31:0]                   baud_div;
    logic  [7:0]                    deq_rx_data;
    logic                           deq_rx_ready;
    logic                           deq_rx_valid;

    logic                           rx_full;
    logic                           rx_empty;
    logic [$clog2(RX_DEPTH+1)-1:0]  rx_level;

    logic  [7:0]                    enq_tx_data;
    logic                           enq_tx_valid;
    logic                           enq_tx_ready;

    logic                           tx_full;
    logic                           tx_empty;
    logic [$clog2(TX_DEPTH+1)-1:0]  tx_level;

    logic                           rx;
    logic                           tx;

endinterface: uart_if
