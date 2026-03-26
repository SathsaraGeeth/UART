import uvm_pkg::*;
`include "uvm_macros.svh"

typedef enum {UART_MON_RST, UART_MON_RX, UART_MON_TX} uart_mon_type_e;

class uart_txn extends uvm_sequence_item;
  uart_mon_type_e m_type;
  
  `uvm_object_utils_begin(uart_txn)
  `uvm_object_utils_end
  
  function new(string name = "uart_txn");
    super.new(name);
  endfunction
endclass: uart_txn

// class uart_rst_txn extends uart_txn;
//   rand bit [31:0] baud_div;
//   constraint c_baud_div {
//     baud_div inside {[1:10000000]};
//   }

//   `uvm_object_utils_begin(uart_rst_txn)
//     `uvm_field_int(baud_div, UVM_ALL_ON)
//   `uvm_object_utils_end

//   function new(string name = "uart_rst_txn");
//     super.new(name);
//   endfunction
// endclass: uart_rst_txn

class uart_rst_txn extends uart_txn;
  bit [31:0] baud_div;

  `uvm_object_utils_begin(uart_rst_txn)
    `uvm_field_int(baud_div, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_rst_txn");
    super.new(name);
    // fixed baud_div
    baud_div = 434;
  endfunction
endclass: uart_rst_txn

class uart_tx_txn extends uart_txn;
  rand bit [7:0] data;

  `uvm_object_utils_begin(uart_tx_txn)
    `uvm_field_int(data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_tx_txn");
    super.new(name);
  endfunction
endclass: uart_tx_txn


class uart_rx_txn extends uart_txn;
  bit [7:0] data;

  `uvm_object_utils_begin(uart_rx_txn)
    `uvm_field_int(data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_rx_txn");
    super.new(name);
  endfunction
endclass: uart_rx_txn
