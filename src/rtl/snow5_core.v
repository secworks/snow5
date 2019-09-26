//======================================================================
//
// snow5_core.v
// ------------
// The SNOW-V core.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2019, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module snow5_core(
                  input wire            clk,
                  input wire            reset_n,

                  input wire            init,
                  input wire            next,

                  input wire [255 : 0]  key,
                  input wire [127 : 0]  iv,

                  output wire [127 : 0] keystream,
                  output wire           ready
                 );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam AES_128_BIT_KEY = 1'h0;
  localparam AES_256_BIT_KEY = 1'h1;

  localparam AES128_ROUNDS = 4'ha;
  localparam AES256_ROUNDS = 4'he;

  localparam NO_UPDATE    = 3'h0;
  localparam INIT_UPDATE  = 3'h1;
  localparam SBOX_UPDATE  = 3'h2;
  localparam MAIN_UPDATE  = 3'h3;
  localparam FINAL_UPDATE = 3'h4;

  localparam CTRL_IDLE  = 3'h0;
  localparam CTRL_INIT  = 3'h1;
  localparam CTRL_NEXT  = 3'h2;
  localparam CTRL_DONE  = 3'h4;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg           ready_reg;
  reg           ready_new;
  reg           ready_we;

  reg [127 : 0] r1_reg;
  reg [127 : 0] r1_new;
  reg [127 : 0] r2_reg;
  reg [127 : 0] r2_new;
  reg [127 : 0] r3_reg;
  reg [127 : 0] r3_new;
  reg           r_we;

  reg [2 : 0]   snow5_ctrl_reg;
  reg [2 : 0]   snow5_ctrl_new;
  reg           snow5_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [2 : 0]  update_type;
  reg [31 : 0] muxed_sboxw;

  wire [127 : 0] round0_round_key;
  wire [127 : 0] round0_in;
  wire [127 : 0] round0_out;

  wire [127 : 0] round1_round_key;
  wire [127 : 0] round1_in;
  wire [127 : 0] round1_out;


  //----------------------------------------------------------------
  // Module instantions.
  //----------------------------------------------------------------
  snow5_aes_round round0(
                        .round_key(round0_round_key),
                        .in(round0_in),
                        .out(round0_out)
                        );


  snow5_aes_round round1(
                        .round_key(round1_round_key),
                        .in(round1_in),
                        .out(round1_out)
                        );

  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign keystream = 128'h0;
  assign ready     = ready_reg;


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin: reg_update
      if (!reset_n)
        begin
          ready_reg      <= 1'b1;
          snow5_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (ready_we)
            ready_reg <= ready_new;

          if (snow5_ctrl_we)
            snow5_ctrl_reg <= snow5_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // snow5_core_ctrl
  //----------------------------------------------------------------
  always @*
    begin: snow5_core_ctrl
      snow5_ctrl_new  = CTRL_IDLE;
      snow5_ctrl_we   = 1'b0;

      case(snow5_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                snow5_ctrl_new = CTRL_INIT;
                snow5_ctrl_we  = 1'h1;
              end

            if (next)
              begin
                snow5_ctrl_new = CTRL_NEXT;
                snow5_ctrl_we  = 1'h1;
              end
          end

        CTRL_INIT:
          begin
            snow5_ctrl_new = CTRL_DONE;
            snow5_ctrl_we  = 1'h1;
          end

        CTRL_NEXT:
          begin
            snow5_ctrl_new = CTRL_DONE;
            snow5_ctrl_we  = 1'h1;
          end

        CTRL_DONE:
          begin
            snow5_ctrl_new = CTRL_IDLE;
            snow5_ctrl_we  = 1'h1;
          end

        default:
          begin
          end
      endcase // case (snow5_ctrl_reg)
    end // snow5_core_ctrl
endmodule // snow5_core

//======================================================================
// EOF snow5_core.v
//======================================================================
