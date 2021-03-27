module tb_top();
  logic clk, arst;
  s_axi_mosi_t [NOC_SIZE-1:0] axi_mosi_if;
  s_axi_miso_t [NOC_SIZE-1:0] axi_miso_if;

  always #5 clk <= ~clk;

  initial
    clk <= '0;

  tb u_tb(
    .clk(clk),
    .arst(arst),
    .axi_mosi_if(axi_mosi_if),
    .axi_miso_if(axi_miso_if)
  );

  ravenoc u_noc(
    .clk(clk),
    .arst(arst),
    .axi_mosi_if(axi_mosi_if),
    .axi_miso_if(axi_miso_if)
  );
endmodule

program tb(
  input                               clk,
  output                              arst,
  output  s_axi_mosi_t [NOC_SIZE-1:0] axi_mosi_if,
  input   s_axi_miso_t [NOC_SIZE-1:0] axi_miso_if
);
  logic clk, arst;
  s_axi_mosi_t [NOC_SIZE-1:0] master_axi;

  initial begin
    //$display("NoC Size: %d",noc_config.noc_size);
    axi_mosi_if <= s_axi_mosi_t'('0);

    reset_task(10);
    send("DEADBEEF");

    for (int i=0;i<300;i++)
      @(posedge clk);
    $finish;
  end

  task send(logic [`AXI_DATA_WIDTH-1:0] data);
    logic [`AXI_ALEN_WIDTH-1:0] alen;
    s_flit_head_data_t head_flit;
    axi_mosi_if <= s_axi_mosi_t'('0);
    for (int i=0;i<2;i++)
      @(posedge clk);
    alen <= $urandom_range(0,256);
    @(posedge clk);
    head_flit <= s_flit_head_data_t'('0);
    head_flit.x_dest <= $urandom_range(0,NOC_CFG_SZ_X);
    head_flit.y_dest <= $urandom_range(0,NOC_CFG_SZ_Y);
    head_flit.pkt_size <= alen+'d1;
    head_flit.data <= "HEAD";
    @(posedge clk);

    // Addr Phase
    axi_mosi_if[0].awaddr  <= 'h1000;
    axi_mosi_if[0].awlen   <= alen;
    axi_mosi_if[0].awsize  <= 'h2;
    axi_mosi_if[0].awsize  <= 'h2;
    axi_mosi_if[0].awvalid <= 'h1;
    @(posedge clk);
    axi_mosi_if <= s_axi_mosi_t'('0);
    @(posedge clk);
    // Data phase
    for (int i=0;i<alen;i++) begin
      axi_mosi_if[0].wdata  <= (i==0) ? {2'h0,2'h2,28'h0} : $urandom();
      axi_mosi_if[0].wstrb  <= '1;
      axi_mosi_if[0].wvalid <= '1;
      @(posedge clk);
    end
    axi_mosi_if[0].wdata  <= $urandom();
    axi_mosi_if[0].wstrb  <= '1;
    axi_mosi_if[0].wvalid <= '1;
    axi_mosi_if[0].wlast  <= '1;
    @(posedge clk);
    axi_mosi_if[0] <= s_axi_mosi_t'('0);
    axi_mosi_if[0].bready <= '1;
    @(posedge clk);

  endtask

  task reset_task(logic [7:0] cycles);
      $display("\nReset task initiated!");
      arst = '0;
      for(int i=0;i<cycles;i++) begin
          arst = 1;
          @(posedge clk);
      end
      arst = 0;
      @(posedge clk);
  endtask
endprogram
