module testbench();
  logic clk, rst;
  logic wr_en, rd_en;
  logic [33:0] data_in;

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
    data_in = '0;
    wr_en = 0;
    rd_en = 0;

    reset_task(10);

    data_in = $urandom();
    wr_en = 1;

    for(int i=0;i<8;i++) begin
      data_in = $urandom();
      @(posedge clk);
    end

    // FIFO Full
    wr_en = 0;
    rd_en = 1;

    for(int i=0;i<8;i++) begin
      data_in = $urandom();
      @(posedge clk);
    end

    //FIFO empty
    wr_en = 1;
    rd_en = 1;
    @(posedge clk);

    for(int i=0;i<50;i++)
      @(posedge clk);
    $finish;
  end

  fifo #(
    .SLOTS(8),
    .WIDTH(34)
  ) u_fifo (
    .clk(clk),
    .arst(rst),
    .write_i(wr_en),
    .read_i(rd_en),
    .data_i(data_in),
    .data_o(),
    .error_o(),
    .full_o(),
    .empty_o()
  );
endmodule
