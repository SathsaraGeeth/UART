import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)

    uart_seqr seqr;
    uart_drv  drv;
    uart_mon  mon;

    uvm_analysis_port #(uart_txn) ap;
    uvm_analysis_port #(uart_txn) drv_ap;

    function new(string name="uart_agent", uvm_component parent=null);
        super.new(name,parent);
        ap = new("ap", this);
        drv_ap = new("drv_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        seqr = uart_seqr::type_id::create("seqr", this);
        drv  = uart_drv ::type_id::create("drv",  this);
        mon  = uart_mon ::type_id::create("mon",  this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        drv.seq_item_port.connect(seqr.seq_item_export);
        mon.ap.connect(ap);
        drv.drv_ap.connect(drv_ap);
    endfunction
endclass