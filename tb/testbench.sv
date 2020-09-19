module testbench();
  logic clk, rst;

  initial begin : clk_gen
      clk = 0;
      forever clk = #5 ~clk;
  end

  task reset_task(logic [7:0] cycles);
      rst = '0;
      for(int i=0;i<cycles;i++) begin
          rst = 1;
          @(posedge clk);
      end
      rst = 0;
      @(posedge clk);
  endtask

  s_flit_head_data_t head_f;
  s_flit_req_t flit_m;

  initial begin
    head_f = '0;
    flit_m = '0;

    reset_task(10);
    flit_m.vc_id = 0;
    flit_m.valid = 1;

    head_f.type_f = HEAD_FLIT;
    head_f.x_dest = 2;
    head_f.y_dest = 3;
    head_f.pkt_size = MIN_SIZE_FLIT;
    head_f.data = 'hBEEF_BEEF;
    flit_m.fdata = head_f;
    @(posedge clk);

    head_f.type_f = HEAD_FLIT;
    head_f.x_dest = 0;
    head_f.y_dest = 3;
    head_f.pkt_size = MIN_SIZE_FLIT;
    head_f.data = 'hDEAD_CAFE;
    flit_m.fdata = head_f;
    @(posedge clk);

    flit_m.valid = 0;
    for(int i=0;i<1000;i++) begin
      @(posedge clk);
    end

    $finish;
  end

  ravenoc u_noc(
    .clk(clk),
    .arst(rst),
    .flit_data_i(flit_m.fdata),
    .valid_i(flit_m.valid),
    .vc_id_i(flit_m.vc_id),
    .ready_o()
  );

  test u_test (
    .clk(clk),
    .arst(arst),
    .q('0),
    .d()
  );
endmodule

module test (
  input   clk,
  input   arst,
  input   q,
  output  d
);
  logic d_ff;

  assign d = d_ff;

  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      d_ff <= '0;
    end
    else begin
      d_ff <= q;
    end
  end
endmodule
