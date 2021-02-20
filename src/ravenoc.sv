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
  input                               clk_axi,
  input                               clk_noc,
  input                               arst_axi,
  input                               arst_noc,
  // NI interfaces
  input   s_axi_mosi_t [NOC_SIZE-1:0] axi_mosi_if,
  output  s_axi_miso_t [NOC_SIZE-1:0] axi_miso_if
);
  router_if ns_con  [(NOC_CFG_SZ_X+1)*NOC_CFG_SZ_Y] ();
  router_if sn_con  [(NOC_CFG_SZ_X+1)*NOC_CFG_SZ_Y] ();
  router_if we_con  [NOC_CFG_SZ_X*(NOC_CFG_SZ_Y+1)] ();
  router_if ew_con  [NOC_CFG_SZ_X*(NOC_CFG_SZ_Y+1)] ();

  genvar x,y;
  generate
    for(x=0;x<NOC_CFG_SZ_X;x++) begin : noc_lines
      for(y=0;y<NOC_CFG_SZ_Y;y++) begin : noc_collumns
        localparam s_router_ports_t router = router_ports(x,y);
        localparam local_idx = y+x*(NOC_CFG_SZ_Y);
        localparam int north_idx = y+x*(NOC_CFG_SZ_Y);
        localparam int south_idx = y+((x+1)*NOC_CFG_SZ_Y);
        localparam int west_idx = y+(x*(NOC_CFG_SZ_Y+1));
        localparam int east_idx = (y+1)+(x*(NOC_CFG_SZ_Y+1));

        router_wrapper#(
          .ROUTER_X_ID(x),
          .ROUTER_Y_ID(y)
        ) u_router_wrapper (
          .clk_axi    (clk_axi),
          .clk_noc    (clk_noc),
          .arst_axi   (arst_axi),
          .arst_noc   (arst_noc),
          .north_send (ns_con[north_idx]),
          .north_recv (sn_con[north_idx]),
          .south_send (sn_con[south_idx]),
          .south_recv (ns_con[south_idx]),
          .west_send  (we_con[west_idx]),
          .west_recv  (ew_con[west_idx]),
          .east_send  (ew_con[east_idx]),
          .east_recv  (we_con[east_idx]),
          .axi_mosi_if(axi_mosi_if[local_idx]),
          .axi_miso_if(axi_miso_if[local_idx])
        );

        if (~router.north_req) begin : u_north_dummy
          ravenoc_dummy u_north_dummy (
            .local_port('0),
            .recv(ns_con[north_idx]),
            .send(sn_con[north_idx])
          );
        end

        if (~router.south_req) begin : u_south_dummy
          ravenoc_dummy u_south_dummy (
            .local_port('0),
            .recv(sn_con[south_idx]),
            .send(ns_con[south_idx])
          );
        end

        if (~router.west_req) begin : u_west_dummy
          ravenoc_dummy u_west_dummy (
            .local_port('0),
            .recv(we_con[west_idx]),
            .send(ew_con[west_idx])
          );
        end

        if (~router.east_req) begin : u_east_dummy
          ravenoc_dummy u_east_dummy (
            .local_port('0),
            .recv(ew_con[east_idx]),
            .send(we_con[east_idx])
          );
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
  input                 local_port,
  router_if.send_flit   send,
  router_if.recv_flit   recv
);
  always_comb begin
    if (local_port == 0) begin
      recv.resp = '0;
      send.req  = '0;
    end
    else begin
      recv.resp = '1;
      send.req  = '0;
    end
  end
endmodule

//Check python NoC size - run.py
//for x in range(noc_lines):
    //for y in range(noc_collumns):
        //if (y>0 and y<(noc_collumns-1)):
            //print("-R-",end='');
        //elif (y == 0):
            //print("R-",end='');
        //else:
            //print("-R");
//for x in range(noc_lines):
    //for y in range(noc_collumns):
        //if (y==0):
            //print("##########");
        //index_val["north_idx"] = y+(x*noc_collumns);
        //index_val["south_idx"] = y+((x+1)*noc_collumns);
        //index_val["west_idx"] = y+(x*(noc_collumns+1));
        //index_val["east_idx"] = (y+1)+(x*(noc_collumns+1));
        //print("Router ("+str(x)+","+str(y)+") ---> "+str(index_val));

