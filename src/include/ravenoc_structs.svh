`ifndef _ravenoc_structs_
  `define _ravenoc_structs_
  // Usage of s_ = struct / _t = typedef

  //typedef enum logic {
    //STATE_1,
    //STATE_2
  //} fsm_state_t;

  typedef struct packed {
    logic [FLIT_WIDTH-1:0]          fdata;
    logic [$clog2(N_VIRT_CHN)-1:0]  vc_id;
    logic                           valid;
  } s_flit_req_t;

  typedef struct packed {
    logic                   ready;
  } s_flit_resp_t;

`endif
