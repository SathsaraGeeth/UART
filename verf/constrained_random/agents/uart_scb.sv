// import uvm_pkg::*;
// `include "uvm_macros.svh"

// class uart_scb extends uvm_scoreboard;
//     `uvm_component_utils(uart_scb)

//     uvm_analysis_export #(uart_txn) before_export;
//     uvm_tlm_analysis_fifo #(uart_txn) before_fifo;

//     uvm_analysis_export #(uart_txn) after_export;
//     uvm_tlm_analysis_fifo #(uart_txn) after_fifo;

//     uart_tx_txn before_list[$];

//     function new(string name="uart_scb", uvm_component parent=null);
//         super.new(name,parent);
//     endfunction

//     function void build_phase(uvm_phase phase);
//         super.build_phase(phase);
//         before_export = new("before_export", this);
//         after_export  = new("after_export",  this);
//         before_fifo   = new("before_fifo", this);
//         after_fifo    = new("after_fifo",  this);
//     endfunction

//     function void connect_phase(uvm_phase phase);
//         before_export.connect(before_fifo.analysis_export);
//         after_export.connect(after_fifo.analysis_export);
//     endfunction

//     task run_phase(uvm_phase phase);
//         fork
//             consume_before();
//             compare();
//         join_none
//     endtask

//     task consume_before();
//         uart_txn txn;
//         uart_tx_txn tx_t;

//         forever begin
//             before_fifo.get(txn);
//             if ($cast(tx_t, txn)) begin
//                 before_list.push_back(tx_t);
//                 `uvm_info("SCB_BEFORE", $sformatf("TX seq=%0d data=0x%0h", tx_t.seq_number, tx_t.data), UVM_LOW)
//             end
//         end
//     endtask

//     task compare();
//         uart_txn txn;
//         uart_rst_txn rst_t;
//         uart_rx_txn  rx_t;
//         uart_tx_txn  tx_t;
//         bit matched;
//         int i;

//         forever begin
//             after_fifo.get(txn);

//             if ($cast(rst_t, txn)) begin
//                 `uvm_info("SCB_AFTER", "RESET observed", UVM_LOW)
//             end
//             else if ($cast(rx_t, txn)) begin
//                 matched = 0;

//                 for (i = 0; i < before_list.size(); i++) begin
//                     tx_t = before_list[i];
//                     if (tx_t.seq_number == rx_t.seq_number) begin
//                         matched = 1;
//                         if (tx_t.data == rx_t.data)
//                             `uvm_info("UART_SCB", $sformatf("TX[%0d] matches RX[%0d]=0x%0h", tx_t.seq_number, rx_t.seq_number, rx_t.data), UVM_LOW)
//                         else
//                             `uvm_error("UART_SCB", $sformatf("Mismatch TX[%0d]=0x%0h vs RX[%0d]=0x%0h", tx_t.seq_number, tx_t.data, rx_t.seq_number, rx_t.data));
//                         before_list.delete(i);
//                         break;
//                     end
//                 end

//                 if (!matched)
//                     `uvm_info("UART_SCB", $sformatf("RX[%0d]=0x%0h unmatched", rx_t.seq_number, rx_t.data), UVM_LOW)
//             end
//         end
//     endtask
// endclass


import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_scb extends uvm_scoreboard;
    `uvm_component_utils(uart_scb)

    // Analysis ports
    uvm_analysis_export #(uart_txn) before_export;
    uvm_tlm_analysis_fifo #(uart_txn) before_fifo;

    uvm_analysis_export #(uart_txn) after_export;
    uvm_tlm_analysis_fifo #(uart_txn) after_fifo;

    // TX queue (BEFORE)
    uart_tx_txn before_list[$];

    // window size for sliding match
    int WINDOW = 6;

    // Constructor
    function new(string name="uart_scb", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        before_export = new("before_export", this);
        after_export  = new("after_export",  this);
        before_fifo   = new("before_fifo", this);
        after_fifo    = new("after_fifo",  this);
    endfunction

    // Connect phase
    function void connect_phase(uvm_phase phase);
        before_export.connect(before_fifo.analysis_export);
        after_export.connect(after_fifo.analysis_export);
    endfunction

    // Run phase: spawn BEFORE consumer and AFTER comparator
    task run_phase(uvm_phase phase);
        fork
            consume_before();
            compare_after();
        join_none
    endtask

    //----------------------------------------
    // BEFORE stream consumer
    //----------------------------------------
    task consume_before();
        uart_txn txn;
        uart_tx_txn tx_t;
        uart_tx_txn tx_clone;

        forever begin
            before_fifo.get(txn);

            if ($cast(tx_t, txn)) begin
                // clone to preserve object (type-safe)
                if (!$cast(tx_clone, tx_t.clone()))
                    `uvm_fatal("UART_SCB", "Failed to clone TX txn")

                before_list.push_back(tx_clone);

                `uvm_info("SCB_BEFORE",
                    $sformatf("TX seq=%0d data=0x%0h",
                    tx_clone.seq_number, tx_clone.data), UVM_LOW)
            end
        end
    endtask

    //----------------------------------------
    // Core matching function (sliding window)
    //----------------------------------------
    function int find_best_match(uart_rx_txn rx_t);
        int best_idx = -1;
        int best_score = -1;

        int limit = (before_list.size() < WINDOW) ? before_list.size() : WINDOW;

        for (int i = 0; i < limit; i++) begin
            uart_tx_txn tx = before_list[i];
            int score = 0;

            // primary: data match
            if (tx.data == rx_t.data)
                score += 2;

            // secondary: seq_number proximity
            if (tx.seq_number == rx_t.seq_number)
                score += 1;

            if (score > best_score) begin
                best_score = score;
                best_idx   = i;
            end
        end

        // require at least data match
        if (best_score >= 2)
            return best_idx;
        else
            return -1;
    endfunction

    //----------------------------------------
    // AFTER stream comparison
    //----------------------------------------
    task compare_after();
        uart_txn txn;
        uart_rx_txn rx_t;
        uart_rst_txn rst_t;
        uart_tx_txn matched_tx;
        int idx;

        forever begin
            after_fifo.get(txn);

            if ($cast(rst_t, txn)) begin
                `uvm_info("SCB_AFTER", "RESET observed", UVM_LOW)
                // optionally clear BEFORE list or keep it for offset logic
            end
            else if ($cast(rx_t, txn)) begin
                `uvm_info("SCB_AFTER",
                    $sformatf("RX seq=%0d data=0x%0h",
                    rx_t.seq_number, rx_t.data), UVM_LOW)

                if (before_list.size() == 0) begin
                    `uvm_warning("UART_SCB", "BEFORE queue empty, cannot match")
                    continue;
                end

                idx = find_best_match(rx_t);

                if (idx != -1) begin
                    matched_tx = before_list[idx];

                    `uvm_info("UART_SCB",
                        $sformatf("MATCH TX(seq=%0d,data=0x%0h) <-> RX(seq=%0d,data=0x%0h)",
                        matched_tx.seq_number, matched_tx.data,
                        rx_t.seq_number, rx_t.data), UVM_LOW)

                    // delete all elements up to the matched one (monotonic)
                    repeat (idx + 1)
                        void'(before_list.pop_front());

                end
                else begin
                    `uvm_warning("UART_SCB",
                        $sformatf("No good match for RX(seq=%0d,data=0x%0h)",
                        rx_t.seq_number, rx_t.data))
                end
            end
        end
    endtask

endclass