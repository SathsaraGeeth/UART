import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_drv extends uvm_driver #(uart_txn);
    `uvm_component_utils(uart_drv);

    virtual uart_if vif;

    uvm_analysis_port #(uart_txn) drv_ap;   // to send expected

    function new (string name = "uart_drv", uvm_component parent = null);
        super.new(name, parent);
        drv_ap = new("drv_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_fatal("UART_DRV", "Virtual interface not set");
    endfunction

    task run_phase(uvm_phase phase);
        uart_txn txn;
        @(posedge vif.clk);
        @(posedge vif.clk);
        @(posedge vif.clk);
        @(posedge vif.clk);
        forever begin
            seq_item_port.get_next_item(txn);
            driver(txn);
            seq_item_port.item_done();
        end
    endtask: run_phase

    // task driver(uart_txn txn);
    //     uart_rst_txn rst_t;
    //     uart_tx_txn  tx_t;
    //     uart_rx_txn  rx_t;

    //     if ($cast(rst_t, txn)) begin
            
    //         vif.rst_n <= 0;
    //         repeat(2) @(posedge vif.clk);
    //         vif.rst_n <= 1;
    //         vif.baud_div <= rst_t.baud_div;
    //         repeat(2) @(posedge vif.clk);

    //         rst_t.m_type = UART_MON_RST;
    //         drv_ap.write(rst_t);
    //         return;
    //     end

    //     if ($cast(tx_t, txn)) begin
    //         // 0. wait until enq_tx_ready
    //         wait (vif.enq_tx_ready == 1);
    //         // 1. pull enq_tx_valid high and put vif.data to enq_tx_data
    //         @(posedge vif.clk);
    //         vif.enq_tx_valid <= 1;
    //         // send to scb the expection
    //         tx_t.m_type = UART_MON_TX;
    //         drv_ap.write(tx_t);
            
    //         vif.enq_tx_data  <= tx_t.data;
    //         // 2. in the next cycle pull enq_tx_valid down
    //         @(posedge vif.clk);
    //         vif.enq_tx_valid <= 0;
    //         return;
    //     end

    //     if ($cast(rx_t, txn)) begin
    //         bit [7:0] data = rx_t.data;
    //         // Note: we dont expect to pass every case
    //         // 0. random delay to simulate asynchrounous behavior
    //         #($urandom_range(0,3) * 1ns);
    //         // 1. random number (0,3) of idle into vif.rx
    //         repeat ($urandom_range(0,3)) begin
    //             vif.rx <= 1;
    //             repeat (vif.baud_div) @(posedge vif.clk);
    //         end
    //         // 2. start bit to the vif.rx
    //         vif.rx <= 0;
    //         @(posedge vif.clk);
    //         // 3. txn.data put one by into the vif.rx
    //         for (int i = 0; i < 8; i++) begin
    //             vif.rx <= data[i];
    //             repeat (vif.baud_div) @(posedge vif.clk);
    //         end
    //         // 4. stop bit to the vif.rx
    //         vif.rx <= 1;
    //         repeat (vif.baud_div) @(posedge vif.clk);

    //         rx_t.m_type = UART_MON_RX;
    //         drv_ap.write(rx_t);
    //         return;
    //     end

    //     // if ($cast(rx_t, txn)) begin
    //     //     bit [7:0] data = rx_t.data;

    //     //     // // 0. Idle BEFORE frame
    //     //     repeat ($urandom_range(1,3)) begin
    //     //         vif.rx <= 1;
    //     //         repeat (vif.baud_div) @(posedge vif.clk);
    //     //     end

    //     //     // 1. Start bit
    //     //     vif.rx <= 0;
    //     //     repeat (vif.baud_div) @(posedge vif.clk);

    //     //     // 2. Data bits
    //     //     for (int i = 0; i < 8; i++) begin
    //     //         @(posedge vif.clk);
    //     //         vif.rx <= data[i];
    //     //         repeat (vif.baud_div-1) @(posedge vif.clk);
    //     //     end

    //     //     // 3. Stop bit (🔥 REQUIRED)
    //     //     vif.rx <= 1;
    //     //     repeat (vif.baud_div) @(posedge vif.clk);

    //     //     rx_t.m_type = UART_MON_RX;
    //     //     drv_ap.write(rx_t);
    //     //     return;
    //     // end




    // endtask: driver

    task driver(uart_txn txn);
        uart_rst_txn rst_t;
        uart_tx_txn  tx_t;
        uart_rx_txn  rx_t;

        // --- Handle reset transaction ---
        if ($cast(rst_t, txn)) begin
            vif.rst_n <= 0;
            repeat (2) @(posedge vif.clk);
            vif.rst_n <= 1;
            vif.baud_div <= rst_t.baud_div;
            repeat (2) @(posedge vif.clk);

            rst_t.m_type = UART_MON_RST;
            drv_ap.write(rst_t);
            return;
        end

        // --- Handle TX transaction with loopback ---
        if ($cast(tx_t, txn)) begin
            // Wait until TX FIFO is ready
            wait (vif.enq_tx_ready == 1);

            @(posedge vif.clk);
            vif.enq_tx_valid <= 1;
            vif.enq_tx_data  <= tx_t.data;

            // Send TX expectation to scoreboard
            tx_t.m_type = UART_MON_TX;
            drv_ap.write(tx_t);

            // --- Loopback: send same data as RX ---
            rx_t = uart_rx_txn::type_id::create("rx_txn");
            rx_t.m_type = UART_MON_RX;
            rx_t.data   = tx_t.data;
            drv_ap.write(rx_t);

            @(posedge vif.clk);
            vif.enq_tx_valid <= 0;

            return;
        end
    endtask: driver
endclass: uart_drv
