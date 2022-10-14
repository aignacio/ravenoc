/**
 * File: output_module.sv
 * Description: Output module to route flits from input
 *              module to the outputs.
 *
 * Author: Anderson Ignacio da Silva <anderson@aignacio.com>
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
module output_module
  import amba_axi_pkg::*;
  import ravenoc_pkg::*;
(
  input                       clk,
  input                       arst,
  // From input modules
  input   s_flit_req_t  [3:0] fin_req_i,
  output  s_flit_resp_t [3:0] fin_resp_o,
  // To external of router
  output  s_flit_req_t        fout_req_o,
  input   s_flit_resp_t       fout_resp_i
);
  logic [NumVirtChn-1:0]  [3:0]  valid_from_im;
  logic [NumVirtChn-1:0]  [3:0]  grant_im;
  logic [NumVirtChn-1:0]         tail_flit_im;
  logic [VcWidth-1:0]            vc_ch_act_out;
  logic                          req_out;
  s_flit_head_data_t             head_flit;

  for(genvar vc_id=0;vc_id<NumVirtChn;vc_id++) begin : gen_rr_arbiters
    rr_arbiter#(
      .N_OF_INPUTS(4)
    ) u_round_robin_arbiter (
      .clk     (clk),
      .arst    (arst),
      .update_i(tail_flit_im[vc_id[VcWidth-1:0]]),
      .req_i   (valid_from_im[vc_id[VcWidth-1:0]]),
      .grant_o (grant_im[vc_id[VcWidth-1:0]])
    );
  end

  always_comb begin : input_setup
    valid_from_im = '0;
    head_flit = '0;
    tail_flit_im = '0;

    // To connect all 4x input module to the arbiters
    for (int in_mod=0;in_mod<4;in_mod++) begin
      for (int vc_channel=0;vc_channel<NumVirtChn;vc_channel++) begin
        if (fin_req_i[in_mod[1:0]].valid &&
            (fin_req_i[in_mod[1:0]].vc_id == vc_channel[VcWidth-1:0]))
          valid_from_im[vc_channel[VcWidth-1:0]][in_mod[1:0]] = 1'b1;
      end
    end

    // Generate the single bit pulse when the tail flit passes through or when
    // flit is single (i.e size = 0, only head flit)
    for (int vc_channel=0;vc_channel<NumVirtChn;vc_channel++) begin
      for (int in_mod=0;in_mod<4;in_mod++) begin
        if (grant_im[vc_channel[VcWidth-1:0]][in_mod[1:0]]) begin
          head_flit = fin_req_i[in_mod[1:0]].fdata;
          tail_flit_im[vc_channel[VcWidth-1:0]] = fout_resp_i.ready &&
                                                  ((head_flit.type_f == TAIL_FLIT) ||
                                                  ((head_flit.type_f == HEAD_FLIT) &&
                                                  (head_flit.pkt_size == 'h0)));
          break;
        end
      end
    end
  end

  // Mux for the output winner input_module
  always_comb begin : output_mux_winner_hp
    fout_req_o = '0;
    vc_ch_act_out = '0;
    req_out = '0;
    fin_resp_o = '0;

    if (HighPriority == ZeroLowPrior) begin
      for (int i=NumVirtChn-1;i>=0;i--)
        if (|grant_im[i[VcWidth-1:0]]) begin
          vc_ch_act_out = i[VcWidth-1:0];
          req_out = 1;
          break;
        end
    end
    else begin
      for (int i=0;i<NumVirtChn;i++)
        if (|grant_im[i[VcWidth-1:0]]) begin
          vc_ch_act_out = i[VcWidth-1:0];
          req_out = 1;
          break;
        end
    end

    if (req_out) begin
      for (int i=0;i<4;i++) begin
        if (grant_im[vc_ch_act_out][i[1:0]]) begin
          fout_req_o.fdata = fin_req_i[i[1:0]].fdata;
          fout_req_o.valid = fin_req_i[i[1:0]].valid;
          fout_req_o.vc_id = vc_ch_act_out;
          fin_resp_o[i[1:0]] = fout_resp_i;
          break;
        end
      end
    end
  end
endmodule
