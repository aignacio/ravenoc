/**
 * File: router_ravenoc.sv
 * Description: RaveNoC router datapath
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
module router_ravenoc import ravenoc_pkg::*; # (
  parameter ROUTER_X_ID = 0,
  parameter ROUTER_Y_ID = 0
) (
  input                 clk,
  input                 arst,
  router_if.send_flit   north_send,
  router_if.recv_flit   north_recv,
  router_if.send_flit   south_send,
  router_if.recv_flit   south_recv,
  router_if.send_flit   west_send,
  router_if.recv_flit   west_recv,
  router_if.send_flit   east_send,
  router_if.recv_flit   east_recv,
  router_if.send_flit   local_send,
  router_if.recv_flit   local_recv
);
  // Mapping input modules
  s_flit_req_t        [4:0] int_req_v;
  s_flit_resp_t       [4:0] int_resp_v;
  s_router_ports_t    [4:0] int_route_v;

  // Mapping output modules
  s_flit_req_t  [4:0] [3:0] int_map_req_v;
  s_flit_resp_t [4:0] [3:0] int_map_resp_v;

  // External connections
  s_flit_req_t        [4:0] ext_req_v_i;
  s_flit_resp_t       [4:0] ext_resp_v_o;

  s_flit_req_t        [4:0] ext_req_v_o;
  s_flit_resp_t       [4:0] ext_resp_v_i;

  // Code commented works but bc of generate it's hard to know
  // which module is the direction, that's why it's manually
  // instantiated again
  //genvar in_mod;
  //generate
    //for(in_mod=0;in_mod<5;in_mod++) begin : input_modules
      //input_module # (
        //.ROUTER_X_ID(ROUTER_X_ID),
        //.ROUTER_Y_ID(ROUTER_Y_ID)
      //) u_input_module (
        //.clk          (clk),
        //.arst         (arst),
        //.fin_req_i    (ext_req_v_i[in_mod]),
        //.fin_resp_o   (ext_resp_v_o[in_mod]),
        //.fout_req_o   (int_req_v[in_mod]),
        //.fout_resp_i  (int_resp_v[in_mod]),
        //.router_port_o(int_route_v[in_mod])
      //);
    //end
  //endgenerate

  //genvar out_mod;
  //generate
    //for(out_mod=0;out_mod<5;out_mod++) begin : output_modules
      //output_module u_output_module (
        //.clk(clk),
        //.arst(arst),
        //.fin_req_i(int_map_req_v[out_mod]),
        //.fin_resp_o(int_map_resp_v[out_mod]),
        //.fout_req_o(ext_req_v_o[out_mod]),
        //.fout_resp_i(ext_resp_v_i[out_mod])
      //);
    //end
  //endgenerate

  input_module # (
    .ROUTER_X_ID(ROUTER_X_ID),
    .ROUTER_Y_ID(ROUTER_Y_ID)
  ) u_input_north (
    .clk          (clk),
    .arst         (arst),
    .fin_req_i    (ext_req_v_i[NORTH_PORT]),
    .fin_resp_o   (ext_resp_v_o[NORTH_PORT]),
    .fout_req_o   (int_req_v[NORTH_PORT]),
    .fout_resp_i  (int_resp_v[NORTH_PORT]),
    .router_port_o(int_route_v[NORTH_PORT])
  );

  input_module # (
    .ROUTER_X_ID(ROUTER_X_ID),
    .ROUTER_Y_ID(ROUTER_Y_ID)
  ) u_input_south (
    .clk          (clk),
    .arst         (arst),
    .fin_req_i    (ext_req_v_i[SOUTH_PORT]),
    .fin_resp_o   (ext_resp_v_o[SOUTH_PORT]),
    .fout_req_o   (int_req_v[SOUTH_PORT]),
    .fout_resp_i  (int_resp_v[SOUTH_PORT]),
    .router_port_o(int_route_v[SOUTH_PORT])
  );

  input_module # (
    .ROUTER_X_ID(ROUTER_X_ID),
    .ROUTER_Y_ID(ROUTER_Y_ID)
  ) u_input_west (
    .clk          (clk),
    .arst         (arst),
    .fin_req_i    (ext_req_v_i[WEST_PORT]),
    .fin_resp_o   (ext_resp_v_o[WEST_PORT]),
    .fout_req_o   (int_req_v[WEST_PORT]),
    .fout_resp_i  (int_resp_v[WEST_PORT]),
    .router_port_o(int_route_v[WEST_PORT])
  );

  input_module # (
    .ROUTER_X_ID(ROUTER_X_ID),
    .ROUTER_Y_ID(ROUTER_Y_ID)
  ) u_input_east (
    .clk          (clk),
    .arst         (arst),
    .fin_req_i    (ext_req_v_i[EAST_PORT]),
    .fin_resp_o   (ext_resp_v_o[EAST_PORT]),
    .fout_req_o   (int_req_v[EAST_PORT]),
    .fout_resp_i  (int_resp_v[EAST_PORT]),
    .router_port_o(int_route_v[EAST_PORT])
  );

  input_module # (
    .ROUTER_X_ID(ROUTER_X_ID),
    .ROUTER_Y_ID(ROUTER_Y_ID)
  ) u_input_local (
    .clk          (clk),
    .arst         (arst),
    .fin_req_i    (ext_req_v_i[LOCAL_PORT]),
    .fin_resp_o   (ext_resp_v_o[LOCAL_PORT]),
    .fout_req_o   (int_req_v[LOCAL_PORT]),
    .fout_resp_i  (int_resp_v[LOCAL_PORT]),
    .router_port_o(int_route_v[LOCAL_PORT])
  );

  output_module u_output_north (
    .clk(clk),
    .arst(arst),
    .fin_req_i(int_map_req_v[NORTH_PORT]),
    .fin_resp_o(int_map_resp_v[NORTH_PORT]),
    .fout_req_o(ext_req_v_o[NORTH_PORT]),
    .fout_resp_i(ext_resp_v_i[NORTH_PORT])
  );

  output_module u_output_south (
    .clk(clk),
    .arst(arst),
    .fin_req_i(int_map_req_v[SOUTH_PORT]),
    .fin_resp_o(int_map_resp_v[SOUTH_PORT]),
    .fout_req_o(ext_req_v_o[SOUTH_PORT]),
    .fout_resp_i(ext_resp_v_i[SOUTH_PORT])
  );

  output_module u_output_west (
    .clk(clk),
    .arst(arst),
    .fin_req_i(int_map_req_v[WEST_PORT]),
    .fin_resp_o(int_map_resp_v[WEST_PORT]),
    .fout_req_o(ext_req_v_o[WEST_PORT]),
    .fout_resp_i(ext_resp_v_i[WEST_PORT])
  );

  output_module u_output_east (
    .clk(clk),
    .arst(arst),
    .fin_req_i(int_map_req_v[EAST_PORT]),
    .fin_resp_o(int_map_resp_v[EAST_PORT]),
    .fout_req_o(ext_req_v_o[EAST_PORT]),
    .fout_resp_i(ext_resp_v_i[EAST_PORT])
  );

  output_module u_output_local (
    .clk(clk),
    .arst(arst),
    .fin_req_i(int_map_req_v[LOCAL_PORT]),
    .fin_resp_o(int_map_resp_v[LOCAL_PORT]),
    .fout_req_o(ext_req_v_o[LOCAL_PORT]),
    .fout_resp_i(ext_resp_v_i[LOCAL_PORT])
  );

  always_comb begin : mapping_input_ports
    ext_req_v_i[NORTH_PORT] = north_recv.req;
    north_recv.resp = ext_resp_v_o[NORTH_PORT];
    ext_req_v_i[SOUTH_PORT] = south_recv.req;
    south_recv.resp = ext_resp_v_o[SOUTH_PORT];
    ext_req_v_i[WEST_PORT] = west_recv.req;
    west_recv.resp = ext_resp_v_o[WEST_PORT];
    ext_req_v_i[EAST_PORT] = east_recv.req;
    east_recv.resp = ext_resp_v_o[EAST_PORT];

    north_send.req = ext_req_v_o[NORTH_PORT];
    ext_resp_v_i[NORTH_PORT] = north_send.resp;
    south_send.req = ext_req_v_o[SOUTH_PORT];
    ext_resp_v_i[SOUTH_PORT] = south_send.resp;
    west_send.req = ext_req_v_o[WEST_PORT];
    ext_resp_v_i[WEST_PORT] = west_send.resp;
    east_send.req = ext_req_v_o[EAST_PORT];
    ext_resp_v_i[EAST_PORT] = east_send.resp;

    // Local interface
    local_recv.resp = ext_resp_v_o[LOCAL_PORT];
    ext_req_v_i[LOCAL_PORT] = local_recv.req;
    local_send.req = ext_req_v_o[LOCAL_PORT];
    ext_resp_v_i[LOCAL_PORT] = local_send.resp;
  end

  always_comb begin : mapping_output_ports
    int_resp_v = '0;
    int_map_req_v = '0;

    // NORTH - Output module flit in / flit out
    int_map_req_v[NORTH_PORT] = {int_route_v[SOUTH_PORT].north_req ? int_req_v[SOUTH_PORT] : '0,
                                 int_route_v[WEST_PORT].north_req  ? int_req_v[WEST_PORT]  : '0,
                                 int_route_v[EAST_PORT].north_req  ? int_req_v[EAST_PORT]  : '0,
                                 int_route_v[LOCAL_PORT].north_req ? int_req_v[LOCAL_PORT] : '0};

    if (int_route_v[SOUTH_PORT].north_req)
      int_resp_v[SOUTH_PORT] = int_map_resp_v[NORTH_PORT][3];
    if (int_route_v[WEST_PORT].north_req)
      int_resp_v[WEST_PORT]  = int_map_resp_v[NORTH_PORT][2];
    if (int_route_v[EAST_PORT].north_req)
      int_resp_v[EAST_PORT]  = int_map_resp_v[NORTH_PORT][1];
    if (int_route_v[LOCAL_PORT].north_req)
      int_resp_v[LOCAL_PORT] = int_map_resp_v[NORTH_PORT][0];

    // SOUTH - Output module flit in / flit out
    int_map_req_v[SOUTH_PORT] = {int_route_v[WEST_PORT].south_req  ? int_req_v[WEST_PORT]  : '0,
                                 int_route_v[EAST_PORT].south_req  ? int_req_v[EAST_PORT]  : '0,
                                 int_route_v[LOCAL_PORT].south_req ? int_req_v[LOCAL_PORT] : '0,
                                 int_route_v[NORTH_PORT].south_req ? int_req_v[NORTH_PORT] : '0};

    if (int_route_v[WEST_PORT].south_req)
      int_resp_v[WEST_PORT]  = int_map_resp_v[SOUTH_PORT][3];
    if (int_route_v[EAST_PORT].south_req)
      int_resp_v[EAST_PORT]  = int_map_resp_v[SOUTH_PORT][2];
    if (int_route_v[LOCAL_PORT].south_req)
      int_resp_v[LOCAL_PORT] = int_map_resp_v[SOUTH_PORT][1];
    if (int_route_v[NORTH_PORT].south_req)
      int_resp_v[NORTH_PORT] = int_map_resp_v[SOUTH_PORT][0];

    // WEST - Output module flit in / flit out
    int_map_req_v[WEST_PORT]  = {int_route_v[EAST_PORT].west_req   ? int_req_v[EAST_PORT]  : '0,
                                 int_route_v[LOCAL_PORT].west_req  ? int_req_v[LOCAL_PORT] : '0,
                                 int_route_v[NORTH_PORT].west_req  ? int_req_v[NORTH_PORT] : '0,
                                 int_route_v[SOUTH_PORT].west_req  ? int_req_v[SOUTH_PORT] : '0};

    if (int_route_v[EAST_PORT].west_req)
      int_resp_v[EAST_PORT]  = int_map_resp_v[WEST_PORT][3];
    if (int_route_v[LOCAL_PORT].west_req)
      int_resp_v[LOCAL_PORT] = int_map_resp_v[WEST_PORT][2];
    if (int_route_v[NORTH_PORT].west_req)
      int_resp_v[NORTH_PORT] = int_map_resp_v[WEST_PORT][1];
    if (int_route_v[SOUTH_PORT].west_req)
      int_resp_v[SOUTH_PORT] = int_map_resp_v[WEST_PORT][0];

    // EAST - Output module flit in / flit out
    int_map_req_v[EAST_PORT]  = {int_route_v[LOCAL_PORT].east_req  ? int_req_v[LOCAL_PORT] : '0,
                                 int_route_v[NORTH_PORT].east_req  ? int_req_v[NORTH_PORT] : '0,
                                 int_route_v[SOUTH_PORT].east_req  ? int_req_v[SOUTH_PORT] : '0,
                                 int_route_v[WEST_PORT].east_req   ? int_req_v[WEST_PORT]  : '0};

    if (int_route_v[LOCAL_PORT].east_req)
      int_resp_v[LOCAL_PORT] = int_map_resp_v[EAST_PORT][3];
    if (int_route_v[NORTH_PORT].east_req)
      int_resp_v[NORTH_PORT] = int_map_resp_v[EAST_PORT][2];
    if (int_route_v[SOUTH_PORT].east_req)
      int_resp_v[SOUTH_PORT] = int_map_resp_v[EAST_PORT][1];
    if (int_route_v[WEST_PORT].east_req)
      int_resp_v[WEST_PORT]  = int_map_resp_v[EAST_PORT][0];

    // LOCAL - Output module flit in / flit out
    int_map_req_v[LOCAL_PORT] = {int_route_v[NORTH_PORT].local_req  ? int_req_v[NORTH_PORT] : '0,
                                 int_route_v[SOUTH_PORT].local_req  ? int_req_v[SOUTH_PORT] : '0,
                                 int_route_v[WEST_PORT].local_req   ? int_req_v[WEST_PORT]  : '0,
                                 int_route_v[EAST_PORT].local_req   ? int_req_v[EAST_PORT]  : '0};

    if (int_route_v[NORTH_PORT].local_req)
      int_resp_v[NORTH_PORT] = int_map_resp_v[LOCAL_PORT][3];
    if (int_route_v[SOUTH_PORT].local_req)
      int_resp_v[SOUTH_PORT] = int_map_resp_v[LOCAL_PORT][2];
    if (int_route_v[WEST_PORT].local_req)
      int_resp_v[WEST_PORT]  = int_map_resp_v[LOCAL_PORT][1];
    if (int_route_v[EAST_PORT].local_req)
      int_resp_v[EAST_PORT]  = int_map_resp_v[LOCAL_PORT][0];
  end
endmodule
