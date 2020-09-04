module testbench();
  logic clk, rst;

  logic [3:0] req;
  logic update;

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

  initial begin
    req = '0;
    update = '0;

    reset_task(10);

    // Individual
    for(int i=0;i<5;i++) begin
      req = 1<<i;
      for (int j=0;j<10;j++)
        @(posedge clk);
      update = 1;
      @(posedge clk);
      update = 0;
    end

    // Two
    for(int i=0;i<2;i++) begin
      req = 'b1010;
      for (int j=0;j<10;j++)
        @(posedge clk);
      update = 1;
      @(posedge clk);
      update = 0;
    end

    // Three
    for(int i=0;i<6;i++) begin
      req = 'b1011;
      for (int j=0;j<10;j++)
        @(posedge clk);
      update = 1;
      @(posedge clk);
      update = 0;
    end

    // four
    for(int i=0;i<20;i++) begin
      req = 'b1111;
      for (int j=0;j<10;j++)
        @(posedge clk);
      update = 1;
      @(posedge clk);
      update = 0;
    end

    $finish;
  end

  rr_arbiter #(
    .N_OF_INPUTS(4)
  ) u_rr (
    .clk(clk),
    .arst(rst),
    .update_i(update),
    .req_i(req),
    .grant_o()
  );
endmodule
