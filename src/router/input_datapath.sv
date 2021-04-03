/**
 * File: input_datapath.sv
 * Description: Input datapath, it connects all the virtual
 *              channels with the mux/demux that controls the
 *              priority of access. Also it instances all the
 *              flit's fifos to the muxes.
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
module input_datapath import ravenoc_pkg::*; (
  input                     clk,
  input                     arst,
  // Input interface - from external input module
  input   s_flit_req_t      fin_req_i,
  output  s_flit_resp_t     fin_resp_o,
  // Output Interface - Output module
  output  s_flit_req_t      fout_req_o,
  input   s_flit_resp_t     fout_resp_i
);
  s_flit_req_t  [N_VIRT_CHN-1:0]  from_input_req;
  s_flit_resp_t [N_VIRT_CHN-1:0]  from_input_resp;

  s_flit_req_t  [N_VIRT_CHN-1:0]  to_output_req;
  s_flit_resp_t [N_VIRT_CHN-1:0]  to_output_resp;

  logic [VC_WIDTH-1:0]  vc_ch_act_in;
  logic                                          req_in;

  logic [VC_WIDTH-1:0]  vc_ch_act_out;
  logic                                          req_out;

  genvar vc_id;
  generate
    for(vc_id=0;vc_id<N_VIRT_CHN;vc_id++) begin : virtual_channels
      vc_buffer u_virtual_channel_fifo (
        .clk    (clk),
        .arst   (arst),
        .vc_id_i(vc_id[VC_WIDTH-1:0]),
        .vc_id_o(to_output_req[vc_id].vc_id),
        // In
        .fdata_i(from_input_req[vc_id].fdata),
        .valid_i(from_input_req[vc_id].valid),
        .ready_o(from_input_resp[vc_id].ready),
        // Out
        .fdata_o(to_output_req[vc_id].fdata),
        .valid_o(to_output_req[vc_id].valid),
        .ready_i(to_output_resp[vc_id].ready)
      );
    end
  endgenerate

  // Input mux
  always_comb begin : input_mux
    from_input_req = '0;
    vc_ch_act_in = '0;
    req_in = '0;
    fin_resp_o = '0;

    for (int i=N_VIRT_CHN-1;i>=0;i--) begin
      from_input_req[i[VC_WIDTH-1:0]].fdata = fin_req_i.fdata;

      if (fin_req_i.vc_id == i[VC_WIDTH-1:0] && fin_req_i.valid && ~req_in) begin
        vc_ch_act_in = i[VC_WIDTH-1:0];
        req_in = 1;
      end
    end

    if (req_in) begin
      from_input_req[vc_ch_act_in].valid = fin_req_i.valid;
      from_input_req[vc_ch_act_in].vc_id = vc_ch_act_in;
      fin_resp_o.ready = from_input_resp[vc_ch_act_in].ready;
    end
    else begin
      fin_resp_o.ready = '1;
    end
  end

  // Output mux
  always_comb begin : router_mux
    fout_req_o = '0;
    vc_ch_act_out = '0;
    req_out = '0;
    to_output_resp = '0;

    if (H_PRIORITY == ZERO_LOW_PRIOR) begin
      for (int i=N_VIRT_CHN-1;i>=0;i--)
        if (to_output_req[i].valid) begin
          vc_ch_act_out = i[VC_WIDTH-1:0];
          req_out = 1;
          break;
        end
    end
    else begin
      for (int i=0;i<N_VIRT_CHN;i++)
        if (to_output_req[i].valid) begin
          vc_ch_act_out = i[VC_WIDTH-1:0];
          req_out = 1;
          break;
        end
    end

    if (req_out) begin
      fout_req_o.fdata = to_output_req[vc_ch_act_out].fdata;
      fout_req_o.valid = to_output_req[vc_ch_act_out].valid;
      fout_req_o.vc_id = to_output_req[vc_ch_act_out].vc_id;
      to_output_resp[vc_ch_act_out] = fout_resp_i;
    end
  end
endmodule
