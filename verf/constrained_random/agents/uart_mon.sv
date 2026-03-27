import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_mon extends uvm_monitor;
    `uvm_component_utils(uart_mon)

    virtual uart_if vif;
    uvm_analysis_port #(uart_txn) ap;

    function new(string name = "uart_mon", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_fatal("UART_MON", "Virtual interface not set");
    endfunction

    task run_phase(uvm_phase phase);
        fork
            monitor_rx_parallel();
            monitor_tx_serial();
        join_none
    endtask

    task monitor_rx_parallel();
        uart_rst_txn rst;
        uart_rx_txn rx_t;

        forever begin
            @(posedge vif.clk);

            if (!vif.rst_n) begin
                rst = uart_rst_txn::type_id::create("rst_txn");
                rst.m_type = UART_MON_RST;
                ap.write(rst);
            end

            else if (vif.deq_rx_ready) begin
                vif.deq_rx_valid <= 1;

                @(posedge vif.clk);
                rx_t = uart_rx_txn::type_id::create("rx_txn");
                rx_t.m_type = UART_MON_RX;
                rx_t.data   = vif.deq_rx_data;
                ap.write(rx_t);

                vif.deq_rx_valid <= 0;
            end
        end
    endtask

    task monitor_tx_serial();
        uart_tx_txn tx_t;
        bit [7:0] data;

        forever begin
            @(negedge vif.tx);               // detect start bit
            data = 8'b0;
            // wait until middle of start bit
            repeat (vif.baud_div/2) @(posedge vif.clk);
            // sample 8 data bits
            for (int i = 0; i < 8; i++) begin
                repeat (vif.baud_div) @(posedge vif.clk);
                data[i] = vif.tx;
            end
            // wait for stop bit
            repeat (vif.baud_div) @(posedge vif.clk);
            // send to scoreboard
            tx_t = uart_tx_txn::type_id::create("tx_txn");
            tx_t.m_type = UART_MON_TX;
            tx_t.data   = data;
            ap.write(tx_t);
        end
    endtask
endclass
