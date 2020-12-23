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
  s_flit_head_data_t head, head2;
  logic [33:0] buffer;

  initial begin
    //$display("NoC Size: %d",noc_config.noc_size);
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
    for (int i=0;i<100;i++)
      @(posedge clk);
    ends_flit();
    for (int i=0;i<100;i++)
      @(posedge clk);
    conc_flit();

    for (int i=0;i<300;i++)
      @(posedge clk);
    $finish;
  end

  initial begin : clk_gen
      clk = 0;
      forever clk = #5 ~clk;
  end

  task conc_flit();
    head.type_f = HEAD_FLIT;
    head.x_dest = 0;
    head.y_dest = 0;
    head.pkt_size = 8;
    head.data = 'h1010_1010;
    local_port_send[7].req.fdata = head;
    local_port_send[7].req.vc_id = 0;
    local_port_send[7].req.valid = '1;

    head2.type_f = HEAD_FLIT;
    head2.x_dest = 0;
    head2.y_dest = 0;
    head2.pkt_size = 4;
    head2.data = 'h2020_202020;
    local_port_send[11].req.fdata = head2;
    local_port_send[11].req.vc_id = 2;
    local_port_send[11].req.valid = '1;
    @(posedge clk);

    for (int i=0;i<20;i++) begin
      if (i<2) begin
        local_port_send[7].req.fdata = {BODY_FLIT,$urandom()};
        local_port_send[11].req.fdata = {BODY_FLIT,$urandom()};
      end
      else if (i == 2) begin
        head2.type_f = TAIL_FLIT;
        local_port_send[7].req.fdata = {BODY_FLIT,$urandom()};
        local_port_send[11].req.fdata = {TAIL_FLIT,$urandom()};
      end
      else begin
        if (local_port_send[7].resp.ready) begin
          buffer = {BODY_FLIT,$urandom()};
        end
        local_port_send[7].req.fdata = buffer;
        local_port_send[11].req.valid = '0;
      end
      @(posedge clk);
    end

    head.type_f = TAIL_FLIT;
    local_port_send[7].req.fdata = head;
    @(posedge clk);
    local_port_send[7].req.valid = '0;
  endtask

  task ends_flit();
    head.type_f = HEAD_FLIT;
    head.x_dest = 2;
    head.y_dest = 3;
    head.pkt_size = 20;
    head.data = 'hDEAD_BEEF;
    local_port_send[0].req.fdata = head;
    local_port_send[0].req.valid = '1;

    head2.type_f = HEAD_FLIT;
    head2.x_dest = 0;
    head2.y_dest = 0;
    head2.pkt_size = 20;
    head2.data = 'hCAFE_CAFE;
    local_port_send[11].req.fdata = head2;
    local_port_send[11].req.valid = '1;

    @(posedge clk);

    for (int i=0;i<19;i++) begin
      local_port_send[0].req.fdata = {BODY_FLIT,32'hAAAA_AAAA};
      local_port_send[11].req.fdata = {BODY_FLIT,32'hBBBB_BBBB};
      @(posedge clk);
    end

    head.type_f = TAIL_FLIT;
    head2.type_f = TAIL_FLIT;
    local_port_send[0].req.fdata = head;
    local_port_send[11].req.fdata = head2;
    @(posedge clk);
    local_port_send[0].req.valid = '0;
    local_port_send[11].req.valid = '0;
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
    @(posedge clk);
    local_port_send[0].req.valid = '0;
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
