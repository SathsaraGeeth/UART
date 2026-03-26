import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)

    uart_agent u_agent;
    uart_scb    u_scb;

    function new(string name="uart_env", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        u_agent = uart_agent::type_id::create("u_agent", this, UVM_PASSIVE);
        u_scb   = uart_scb   ::type_id::create("u_scb",   this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        u_agent.ap.connect(u_scb.mon_export);
        u_agent.drv_ap.connect(u_scb.drv_export);
    endfunction
endclass
