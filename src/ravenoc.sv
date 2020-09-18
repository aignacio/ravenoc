/**
 * File: ravenoc.sv
 * Description: RaveNoC top module
 * Author: Anderson Ignacio da Silva <aignacio@aignacio.com>
 *
 * MIT License
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module ravenoc import ravenoc_pkg::*; (
  input                                           clk /*verilator clocker*/,
  input                                           arst,
  // Input interface - from external input module
  input   [FLIT_WIDTH-1:0]                        flit_data_i,
  input                                           valid_i,
  output  logic                                   ready_o,
  input   [$clog2(N_VIRT_CHN>1?N_VIRT_CHN:2)-1:0] vc_id_i
);
  router_if local_port_send [NOC_CFG_SZ_X*NOC_CFG_SZ_Y]       ();
  router_if local_port_recv [NOC_CFG_SZ_X*NOC_CFG_SZ_Y]       ();
  router_if ns_con          [NOC_CFG_SZ_X*(NOC_CFG_SZ_Y+1)+1] ();
  router_if sn_con          [NOC_CFG_SZ_X*(NOC_CFG_SZ_Y+1)+1] ();
  router_if we_con          [(NOC_CFG_SZ_X+1)*NOC_CFG_SZ_Y]   ();
  router_if ew_con          [(NOC_CFG_SZ_X+1)*NOC_CFG_SZ_Y]   ();

  genvar x,y;
  generate
    for(x=0;x<NOC_CFG_SZ_X;x++) begin : noc_lines
      for(y=0;y<NOC_CFG_SZ_Y;y++) begin : noc_collumns
        localparam s_router_ports_t router = router_ports(x,y);
        localparam local_idx = y+x*(NOC_CFG_SZ_Y);
        localparam int north_idx = y+(x*(NOC_CFG_SZ_Y));
        localparam int south_idx = y+((x+1)*NOC_CFG_SZ_Y);
        localparam int west_idx = y+(x*(NOC_CFG_SZ_Y+1));
        localparam int east_idx = (y+1)+(x*(NOC_CFG_SZ_Y+1));

        router_ravenoc#(
          .ROUTER_X_ID(x),
          .ROUTER_Y_ID(y)
        ) u_router (
          .clk       (clk),
          .arst      (arst),
          .north_send(ns_con[north_idx]),
          .north_recv(sn_con[north_idx]),
          .south_send(sn_con[south_idx]),
          .south_recv(ns_con[south_idx]),
          .west_send (we_con[west_idx]),
          .west_recv (ew_con[west_idx]),
          .east_send (ew_con[east_idx]),
          .east_recv (we_con[east_idx]),
          .local_send(local_port_send[local_idx]),
          .local_recv(local_port_recv[local_idx])
        );

        if (~router.north_req) begin : u_north_dummy
          ravenoc_dummy u_north_dummy (
            .recv(ns_con[north_idx].send_flit),
            .send(sn_con[north_idx].recv_flit)
          );
        end

        if (~router.south_req) begin : u_south_dummy
          ravenoc_dummy u_south_dummy (
            .recv(sn_con[south_idx].send_flit),
            .send(ns_con[south_idx].recv_flit)
          );
        end

        if (~router.west_req) begin : u_west_dummy
          ravenoc_dummy u_west_dummy (
            .recv(we_con[west_idx].send_flit),
            .send(ew_con[west_idx].recv_flit)
          );
        end

        if (~router.east_req) begin : u_east_dummy
          ravenoc_dummy u_east_dummy (
            .recv(ew_con[east_idx].send_flit),
            .send(we_con[east_idx].recv_flit)
          );
        end

        if (~(x == 0 && y == 0)) begin
          ravenoc_dummy u_local_dummy (
            .recv(local_port_send[local_idx]),
            .send(local_port_recv[local_idx])
          );
        end
        else begin
          assign  local_port_recv[local_idx].recv_flit.req.fdata = flit_data_i;
          assign  local_port_recv[local_idx].recv_flit.req.vc_id = vc_id_i;
          assign  local_port_recv[local_idx].recv_flit.req.valid = valid_i;
          assign  ready_o = local_port_recv[local_idx].recv_flit.resp.ready;
          assign  local_port_send[local_idx].send_flit.resp = '0;
        end
      end
    end
  endgenerate

  function automatic s_router_ports_t router_ports(int x, int y);
    s_router_ports_t connected_ports;
    connected_ports.north_req = (x > 0)                 ? 1 : 0; // First row
    connected_ports.south_req = (x < (NOC_CFG_SZ_X-1))  ? 1 : 0; // Last row
    connected_ports.west_req  = (y > 0)                 ? 1 : 0; // First collumn
    connected_ports.east_req  = (y < (NOC_CFG_SZ_Y-1))  ? 1 : 0; // Last collumn
    connected_ports.local_req = 0;
    return connected_ports;
  endfunction
endmodule

module ravenoc_dummy (
  router_if   recv,
  router_if   send
);
  always_comb begin
    recv.recv_flit.resp = '0;
    send.send_flit.req  = '0;
  end
endmodule
