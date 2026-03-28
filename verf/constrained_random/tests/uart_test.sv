// import uvm pkg and macros
`include "uvm_macros.svh"
import uvm_pkg::*;
// import our pkg and macros


// calss(es) for UVM_TESTS passed by +UVM_TESTNAME parameter, in uvm factory without recompiling everytime
class uart_test extends uvm_test; // uvm_components <- uvm_test
    // register this calss in the factory
    `uvm_component_utils(uart_test)

    uart_env u_env;

    // constructor
    function new(string name="uart_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_env = uart_env::type_id::create("u_env", this);
    endfunction

    // uvm calls run_phase after it creates our object
    task run_phase(uvm_phase phase);
        uart_seq seq;

        // uvm objects can raises an objection finishing the test - test run as long as one object has an objection to stop it
        phase.raise_objection(this);    // pass ourselves using this

        seq = uart_seq::type_id::create("seq");
        seq.start(u_env.u_agent.seqr);

        phase.drop_objection(this); 
    endtask
endclass : uart_test
