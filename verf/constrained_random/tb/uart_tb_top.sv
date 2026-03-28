// import uvm pkg and macros
`include "uvm_macros.svh"
import uvm_pkg::*;

// import our pkg and macros

module uart_tb_top;
    // interface instance
    uart_if vif();

    // DUT instance
    localparam RX_DEPTH = 8;
    localparam TX_DEPTH = 8;
    uart #(
        .RX_DEPTH(RX_DEPTH),
        .TX_DEPTH(TX_DEPTH),
        .PARITY_EN(0),
        .EN_2STOP_BITS(0)
    ) uart_inst (
        .i_clk(vif.clk),
        .i_rst_n(vif.rst_n),

        .i_baud_div(vif.baud_div),

        .o_deq_rx_data(vif.deq_rx_data),
        .o_deq_rx_ready(vif.deq_rx_ready),
        .i_deq_rx_valid(vif.deq_rx_valid),

        .o_rx_full(vif.rx_full),
        .o_rx_empty(vif.rx_empty),
        .o_rx_level(vif.rx_level),

        .i_enq_tx_data(vif.enq_tx_data),
        .i_enq_tx_valid(vif.enq_tx_valid),
        .o_enq_tx_ready(vif.enq_tx_ready),

        .o_tx_full(vif.tx_full),
        .o_tx_empty(vif.tx_empty),
        .o_tx_level(vif.tx_level),

        .i_rx(vif.rx),
        .o_tx(vif.tx)
    );

    // Initialize interface(bfm) and run test
    initial begin
        uvm_config_db #(virtual uart_if)::set(null, "*", "vif", vif);
        run_test();
    end

    initial begin
        vif.clk     = 1'b0;
        vif.rst_n   = 1'b0;

        vif.enq_tx_valid = 1'b0;
        vif.enq_tx_data  = 8'd0;
        vif.deq_rx_valid <= 1'b0;
        vif.baud_div = 32'd16;


        repeat (5) @(posedge vif.clk);
        vif.rst_n = 1'b1;

        
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb_top);
    end

    always begin
        #10 vif.clk = ~vif.clk;
    end

    always_ff @(posedge vif.clk) begin
        vif.rx <= vif.tx;
    end

endmodule: uart_tb_top
