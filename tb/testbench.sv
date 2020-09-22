module tb_top();
  logic clk, arst;
  router_if local_port_send [NOC_CFG_SZ_X*NOC_CFG_SZ_Y] ();
  router_if local_port_recv [NOC_CFG_SZ_X*NOC_CFG_SZ_Y] ();

  tb u_tb(
    .clk(clk),
    .arst(arst),
    .local_port_send(local_port_recv),
    .local_port_recv(local_port_send)
  );

  ravenoc u_noc(
    .clk(clk),
    .arst(arst),
    .local_port_send(local_port_send),
    .local_port_recv(local_port_recv)
  );
endmodule

program tb(
  output              clk,
  output              arst,
  router_if.recv_flit local_port_recv [NOC_CFG_SZ_X*NOC_CFG_SZ_Y],
  router_if.send_flit local_port_send [NOC_CFG_SZ_X*NOC_CFG_SZ_Y]
);
  logic clk, arst;
  s_flit_head_data_t head;

  initial begin
    local_port_send[0].req = '0;
    local_port_send[1].req = '0;
    local_port_send[2].req = '0;
    local_port_send[3].req = '0;
    local_port_send[4].req = '0;
    local_port_send[5].req = '0;
    local_port_send[6].req = '0;
    local_port_send[7].req = '0;
    local_port_send[8].req = '0;
    local_port_send[9].req = '0;
    local_port_send[10].req = '0;
    local_port_send[11].req = '0;
    local_port_recv[0].resp = '1;
    local_port_recv[1].resp = '1;
    local_port_recv[2].resp = '1;
    local_port_recv[3].resp = '1;
    local_port_recv[4].resp = '1;
    local_port_recv[5].resp = '1;
    local_port_recv[6].resp = '1;
    local_port_recv[7].resp = '1;
    local_port_recv[8].resp = '1;
    local_port_recv[9].resp = '1;
    local_port_recv[10].resp = '1;
    local_port_recv[11].resp = '1;

    reset_task(10);
    single_flit_all();
    long_flit();

    local_port_send[0].req.valid = '0;
    for (int i=0;i<1000;i++)
      @(posedge clk);
    $finish;
  end

  initial begin : clk_gen
      clk = 0;
      forever clk = #5 ~clk;
  end

  task long_flit();
    for (int x=0;x<NOC_CFG_SZ_X;x++) begin
      for (int y=0;y<NOC_CFG_SZ_Y;y++) begin
        if (x == '0 && y == '0) begin
          $display(".");
        end
        else begin
          head.type_f = HEAD_FLIT;
          head.x_dest = x;
          head.y_dest = y;
          head.pkt_size = MIN_SIZE_FLIT;
          head.data = {x[3:0],y[3:0]};
          local_port_send[0].req.fdata = head;
          local_port_send[0].req.valid = '1;
        end
        @(posedge clk);
      end
    end
  endtask

  task single_flit_all();
    for (int x=0;x<NOC_CFG_SZ_X;x++) begin
      for (int y=0;y<NOC_CFG_SZ_Y;y++) begin
        if (x == '0 && y == '0) begin
          $display(".");
        end
        else begin
          head.type_f = HEAD_FLIT;
          head.x_dest = x;
          head.y_dest = y;
          head.pkt_size = MIN_SIZE_FLIT;
          head.data = {x[3:0],y[3:0]};
          local_port_send[0].req.fdata = head;
          local_port_send[0].req.valid = '1;
        end
        @(posedge clk);
      end
    end
  endtask

  task reset_task(logic [7:0] cycles);
      arst = '0;
      for(int i=0;i<cycles;i++) begin
          arst = 1;
          @(posedge clk);
      end
      arst = 0;
      @(posedge clk);
  endtask
endprogram
