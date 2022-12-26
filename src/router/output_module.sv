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
  logic [NumVirtChn-1:0][3:0]   req;
  logic [NumVirtChn-1:0][3:0]   grant_im;
  logic [VcWidth-1:0]           vc_ch_act_out;
  logic                         req_out;
  logic [NumVirtChn-1:0]        update;
  logic [NumVirtChn-1:0]        lock_ff, next_lock;
  s_flit_head_data_t            hflit;
  logic                         sflit_done;
  logic                         nflit_done;

  /* verilator lint_off WIDTH */
  for(genvar vc_id=0; vc_id<NumVirtChn; vc_id++) begin : gen_rr_arbiters
    rr_arbiter#(
      .N_OF_INPUTS(4)
    ) u_round_robin_arbiter (
      .clk     (clk),
      .arst    (arst),
      .update_i(update[vc_id]),
      .req_i   (req[vc_id]),
      .grant_o (grant_im[vc_id])
    );
  end : gen_rr_arbiters

  always_comb begin : input_setup
    req = '0;
    hflit = '0;
    update = '0;
    next_lock = lock_ff;
    sflit_done = 1'b0;
    nflit_done = 1'b0;

    // Connect all 4x input modules to the respective arbiters
    for (int in_mod=0; in_mod<4; in_mod++) begin
      for (int vc_channel=0; vc_channel<NumVirtChn; vc_channel++) begin
        if (fin_req_i[in_mod].valid & (fin_req_i[in_mod].vc_id == vc_channel)) begin
          req[vc_channel][in_mod] = 1'b1;
        end
      end
    end

    for (int vc_channel=0; vc_channel<NumVirtChn; vc_channel++) begin
      // While we have no flits moving around, we let the arbiter to run full time
      if (lock_ff[vc_channel] == 1'b0) begin
        update[vc_channel] = 1'b1;
      end

      // If we have a request, lock the arbiter till end of the flit
      if (|req[vc_channel]) begin
        next_lock[vc_channel] = 1'b1;
      end

      if (lock_ff[vc_channel]) begin
        for (int i=0; i<4; i++) begin
          if (grant_im[vc_channel][i] == 1'b1) begin
            hflit = fin_req_i[i].fdata;
            sflit_done =  (hflit.type_f == HEAD_FLIT) &&
                          (hflit.pkt_size == 'd0)     &&
                          fin_resp_o[i].ready;
            nflit_done =  (hflit.type_f == TAIL_FLIT) &&
                          fin_resp_o[i].ready;
            if (sflit_done || nflit_done)  begin
              next_lock[vc_channel] = 1'b0;
            end
          end
        end
      end
    end
  end : input_setup

  // Mux for the output winner input_module
  /*verilator coverage_off*/
  always_comb begin : output_mux_winner_hp
    fout_req_o = '0;
    vc_ch_act_out = '0;
    req_out = '0;
    fin_resp_o = '0;

    if (HighPriority == ZeroLowPrior) begin
      for (int i=NumVirtChn-1;i>=0;i--)
        if (|grant_im[i] && lock_ff[i]) begin
          vc_ch_act_out = i;
          req_out = 1;
          break;
        end
    end
    else begin
      for (int i=0;i<NumVirtChn;i++) begin
        if (|grant_im[i] && lock_ff[i]) begin
          vc_ch_act_out = i;
          req_out = 1;
          break;
        end
      end
    end

    if (req_out) begin
      for (int i=0;i<4;i++) begin
        if (grant_im[vc_ch_act_out][i] && (fin_req_i[i].vc_id == vc_ch_act_out)) begin
          fout_req_o.fdata = fin_req_i[i].fdata;
          fout_req_o.valid = fin_req_i[i].valid;
          fout_req_o.vc_id = vc_ch_act_out;
          fin_resp_o[i]    = fout_resp_i;
          break;
        end
      end
    end
  end : output_mux_winner_hp
  /*verilator coverage_on*/
  /* verilator lint_on WIDTH */

  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      lock_ff <= '0;
    end
    else begin
      lock_ff <= next_lock;
    end
  end
endmodule
