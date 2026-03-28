import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_scb extends uvm_scoreboard;
    `uvm_component_utils(uart_scb)

    uvm_analysis_export #(uart_txn) before_export;
    uvm_tlm_analysis_fifo #(uart_txn) before_fifo;

    uvm_analysis_export #(uart_txn) after_export;
    uvm_tlm_analysis_fifo #(uart_txn) after_fifo;

    uart_tx_txn before_list[$];

    function new(string name="uart_scb", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        before_export = new("before_export", this);
        after_export  = new("after_export",  this);
        before_fifo   = new("before_fifo", this);
        after_fifo    = new("after_fifo",  this);
    endfunction

    function void connect_phase(uvm_phase phase);
        before_export.connect(before_fifo.analysis_export);
        after_export.connect(after_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        fork
            consume_before();
            compare();
        join_none
    endtask

    // Log every BEFORE transaction
    task consume_before();
        uart_txn txn;
        uart_tx_txn tx_t;
        uart_rx_txn rx_t;
        uart_rst_txn rst_t;

        forever begin
            before_fifo.get(txn);

            if ($cast(tx_t, txn)) begin
                before_list.push_back(tx_t);
                `uvm_info("SCB_BEFORE", $sformatf("Type: TX, seq=%0d, data=0x%0h", tx_t.seq_number, tx_t.data), UVM_LOW)
            end
            else if ($cast(rx_t, txn)) begin
                `uvm_info("SCB_BEFORE", $sformatf("Type: RX, seq=%0d, data=0x%0h", rx_t.seq_number, rx_t.data), UVM_LOW)
            end
            else if ($cast(rst_t, txn)) begin
                `uvm_info("SCB_BEFORE", "Type: RESET", UVM_LOW)
            end
            else begin
                `uvm_info("SCB_BEFORE", $sformatf("Unknown type: %s", txn.get_type_name()), UVM_LOW)
            end
        end
    endtask

    // Compare AFTER transactions against BEFORE list
    task compare();
        uart_txn txn;
        uart_rst_txn rst_t;
        uart_rx_txn  rx_t;
        uart_tx_txn  tx_t;
        bit matched;
        int i;

        forever begin
            after_fifo.get(txn);

            if ($cast(rst_t, txn)) begin
                `uvm_info("SCB_AFTER", "Type: RESET", UVM_LOW)
            end
            else if ($cast(rx_t, txn)) begin
                `uvm_info("SCB_AFTER", $sformatf("Type: RX, seq=%0d, data=0x%0h", rx_t.seq_number, rx_t.data), UVM_LOW)
                matched = 0;

                for (i = 0; i < before_list.size(); i++) begin
                    tx_t = before_list[i];
                    if (tx_t.seq_number == rx_t.seq_number) begin
                        matched = 1;
                        if (tx_t.data == rx_t.data)
                            `uvm_info("UART_SCB", $sformatf("TX[%0d] matches RX[%0d]=0x%0h", tx_t.seq_number, rx_t.seq_number, rx_t.data), UVM_LOW)
                        else
                            `uvm_error("UART_SCB", $sformatf("Mismatch TX[%0d]=0x%0h vs RX[%0d]=0x%0h", tx_t.seq_number, tx_t.data, rx_t.seq_number, rx_t.data));
                        before_list.delete(i);
                        break;
                    end
                end

                if (!matched)
                    `uvm_info("UART_SCB", $sformatf("RX[%0d]=0x%0h unmatched", rx_t.seq_number, rx_t.data), UVM_LOW)
            end
            else if ($cast(tx_t, txn)) begin
                `uvm_info("SCB_AFTER", $sformatf("Type: TX, seq=%0d, data=0x%0h", tx_t.seq_number, tx_t.data), UVM_LOW)
            end
            else begin
                `uvm_info("SCB_AFTER", $sformatf("Unknown type: %s", txn.get_type_name()), UVM_LOW)
            end
        end
    endtask

endclass