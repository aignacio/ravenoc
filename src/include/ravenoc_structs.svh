`ifndef _ravenoc_structs_
  `define _ravenoc_structs_
  // Usage of s_ = struct / _t = typedef

  //typedef enum logic {
    //STATE_1,
    //STATE_2
  //} fsm_state_t;

  typedef struct packed {
    logic [3:0] test;
    logic       ready;
  } s_test_t;

`endif
