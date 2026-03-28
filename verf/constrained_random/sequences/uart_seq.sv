import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_seq extends uvm_sequence #(uart_txn);
    `uvm_object_utils(uart_seq)

    function new(string name = "uart_seq");
        super.new(name);
    endfunction

    virtual task body();
        uart_txn     txn;
        uart_rst_txn rst;
        uart_tx_txn  tx;

        integer i;
        for (i = 0; i < 100; i++) begin
            if ($urandom_range(0, 99) < 100) begin      /* ignore rst for a while */
                tx = uart_tx_txn::type_id::create("tx");
                assert(tx.randomize()) else
                    `uvm_error("TX_SEQ", "Randomization failed");
                txn = tx;
            end else begin
                rst = uart_rst_txn::type_id::create("rst");
                txn = rst;
            end
            start_item(txn);
            finish_item(txn);
        end
    endtask: body
endclass: uart_seq

