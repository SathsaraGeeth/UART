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

    logic  [7:0]                    enq_tx_data;
    logic                           enq_tx_valid;
    logic                           enq_tx_ready;

    logic                           rx;
    logic                           tx;

endinterface: uart_if
