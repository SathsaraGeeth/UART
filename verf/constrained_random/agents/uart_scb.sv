import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_scb extends uvm_scoreboard;
    `uvm_component_utils(uart_scb)

    // Separate FIFOs
    uart_tx_txn tx_fifo[$];
    uart_rx_txn rx_fifo[$];
    uart_rst_txn rst_fifo[$]; // placeholder only

    uvm_analysis_export #(uart_txn) mon_export;
    uvm_tlm_analysis_fifo #(uart_txn) mon_fifo;

    uvm_analysis_export #(uart_txn) drv_export;
    uvm_tlm_analysis_fifo #(uart_txn) drv_fifo;

    function new(string name="uart_scb", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_export = new("mon_export", this);
        mon_fifo   = new("mon_fifo", this);
        drv_export = new("drv_export", this);
        drv_fifo   = new("drv_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        mon_export.connect(mon_fifo.analysis_export);
        drv_export.connect(drv_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        fork
            listen_driver();
            listen_monitor();
        join_none
    endtask

    // -------------------------------------------------------------
    task listen_driver();
        uart_txn txn;
        uart_tx_txn tx_t;
        uart_rx_txn rx_t;
        uart_rst_txn rst_t;

        forever begin
            drv_fifo.get(txn);

            if (txn.m_type == UART_MON_TX) begin
                if ($cast(tx_t, txn)) begin
                    tx_fifo.push_back(tx_t);
                end
            end

            else if (txn.m_type == UART_MON_RX) begin
                if ($cast(rx_t, txn)) begin
                    rx_fifo.push_back(rx_t);
                end
            end

            else if (txn.m_type == UART_MON_RST) begin
                if ($cast(rst_t, txn)) begin
                    rst_fifo.push_back(rst_t); // placeholder
                end
            end
        end
    endtask

    // -------------------------------------------------------------
    task listen_monitor();
        uart_txn txn;
        uart_tx_txn tx_got, tx_exp;
        uart_rx_txn rx_got, rx_exp;

        forever begin
            mon_fifo.get(txn);

            // ---------------- TX ----------------
            if (txn.m_type == UART_MON_TX) begin
                if (tx_fifo.size() == 0) begin
                    `uvm_error("UART_SCB", "Unexpected TX received, FIFO empty");
                end
                else begin
                    tx_exp = tx_fifo.pop_front();

                    if ($cast(tx_got, txn)) begin
                        if (tx_exp.data !== tx_got.data) begin
                            `uvm_error("UART_SCB",
                                $sformatf("TX mismatch! exp=0x%0h got=0x%0h",
                                tx_exp.data, tx_got.data));
                        end
                        else begin
                            `uvm_info("UART_SCB",
                                $sformatf("TX match: 0x%0h", tx_got.data),
                                UVM_LOW);
                        end
                    end
                end
            end

            // ---------------- RX ----------------
            else if (txn.m_type == UART_MON_RX) begin
                if (rx_fifo.size() == 0) begin
                    `uvm_error("UART_SCB", "Unexpected RX received, FIFO empty");
                end
                else begin
                    rx_exp = rx_fifo.pop_front();

                    if ($cast(rx_got, txn)) begin
                        if (rx_exp.data !== rx_got.data) begin
                            `uvm_error("UART_SCB",
                                $sformatf("RX mismatch! exp=0x%0h got=0x%0h",
                                rx_exp.data, rx_got.data));
                        end
                        else begin
                            `uvm_info("UART_SCB",
                                $sformatf("RX match: 0x%0h", rx_got.data),
                                UVM_LOW);
                        end
                    end
                end
            end

            // ---------------- RST ----------------
            else if (txn.m_type == UART_MON_RST) begin
                // intentionally ignored for comparison
                // optional: track or clear queues if you want later
            end

        end
    endtask

endclass