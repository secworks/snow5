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

  localparam CTRL_IDLE        = 3'h0;
  localparam CTRL_INIT        = 3'h1;
  localparam CTRL_NEXT        = 3'h2;
  localparam CTRL_FSM_UPDATE  = 3'h3;
  localparam CTRL_LFSR_UPDATE = 3'h4;
  localparam CTRL_OUTPUT      = 3'h5;
  localparam CTRL_DONE        = 3'h6;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg           ready_reg;
  reg           ready_new;
  reg           ready_we;

  reg [15 : 0]  a_reg [0 : 15];
  reg [15 : 0]  a_new [0 : 15];
  reg           a_we;

  reg [15 : 0]  b_reg [0 : 15];
  reg [15 : 0]  b_new [0 : 15];
  reg           b_we;

  reg           lfsr_we;

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
  wire [127 : 0] round0_round_key;
  wire [127 : 0] round0_in;
  wire [127 : 0] round0_out;

  wire [127 : 0] round1_round_key;
  wire [127 : 0] round1_in;
  wire [127 : 0] round1_out;

  reg  [127 : 0] t1;
  reg  [127 : 0] t2;

  reg init_state;
  reg update_state;


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

  assign round0_round_key = 128'h0;
  assign round0_in        = r1_reg;

  assign round1_round_key = 128'h0;
  assign round1_in        = r2_reg;


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin: reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0 ; i < 16 ; i = i + 1)
            begin
              a_reg[i] <= 16'h0;
              b_reg[i] <= 16'h0;
            end

          r1_reg         <= 128'h0;
          r2_reg         <= 128'h0;
          r3_reg         <= 128'h0;
          ready_reg      <= 1'b1;
          snow5_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (r_we)
            begin
              r1_reg <= r1_new;
              r2_reg <= r2_new;
              r3_reg <= r3_new;
            end

          if (a_we)
            begin
              for (i = 0; i < 16 ; i = i + 1)
                a_reg[i] <= a_new[i];
            end

          if (b_we)
            begin
              for (i = 0; i < 16 ; i = i + 1)
                b_reg[i] <= b_new[i];
            end

          if (ready_we)
            ready_reg <= ready_new;

          if (snow5_ctrl_we)
            snow5_ctrl_reg <= snow5_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // lfsr_logic
  //----------------------------------------------------------------
  always @*
    begin : lfsr_logic
      integer i;
      reg [15 : 0] tmp_a;
      reg [15 : 0] tmp_b;

      for (i = 0 ; i < 16 ; i = i + 1)
        begin
          a_new[i] = 16'h0;
          b_new[i] = 16'h0;
        end


      t1 = {b_reg[15], b_reg[14], b_reg[13], b_reg[12],
            b_reg[11], b_reg[10], b_reg[09], b_reg[08]};

      t2 = {a_reg[07], a_reg[06], a_reg[05], a_reg[04],
            a_reg[03], a_reg[02], a_reg[01], a_reg[00]};


      tmp_a = 16'h0;

      tmp_b = 16'h0;


      if (init_state)
        begin
          a_new[15] = key[127 : 112];
          a_new[14] = key[111 : 096];
          a_new[13] = key[095 : 080];
          a_new[12] = key[079 : 064];
          a_new[11] = key[063 : 048];
          a_new[10] = key[047 : 032];
          a_new[09] = key[031 : 016];
          a_new[08] = key[015 : 000];
          a_new[07] = iv[127 : 112];
          a_new[06] = iv[111 : 096];
          a_new[05] = iv[095 : 080];
          a_new[04] = iv[079 : 064];
          a_new[03] = iv[063 : 048];
          a_new[02] = iv[047 : 032];
          a_new[01] = iv[031 : 016];
          a_new[00] = iv[015 : 000];
          a_we      = 1'h1;

          b_new[15] = key[255 : 240];
          b_new[14] = key[239 : 224];
          b_new[13] = key[223 : 208];
          b_new[12] = key[207 : 192];
          b_new[11] = key[191 : 176];
          b_new[10] = key[175 : 160];
          b_new[09] = key[159 : 144];
          b_new[08] = key[143 : 128];
          b_new[07] = 16'h0;
          b_new[06] = 16'h0;
          b_new[05] = 16'h0;
          b_new[04] = 16'h0;
          b_new[03] = 16'h0;
          b_new[02] = 16'h0;
          b_new[01] = 16'h0;
          b_new[00] = 16'h0;
          b_we      = 1'h1;
        end

      if (update_state)
        begin
          for (i = 0 ; i < 15 ; i = i + 1)
              a_new[i] = a_reg[(i + i)];
          a_new[15] = tmp_a;
          a_we      = 1'h1;

          for (i = 0 ; i < 15 ; i = i + 1)
              b_new[i] = b_reg[(i + i)];
          b_new[15] = tmp_b;
          b_we      = 1'h1;
        end
    end


  //----------------------------------------------------------------
  // fsm_logic
  //----------------------------------------------------------------
  always @*
    begin : fsm_logic
      reg [127 : 0] tmp0, tmp1, tmp2;
      reg [7 : 0] b00, b01, b02, b03, b04, b05, b06, b07;
      reg [7 : 0] b08, b09, b10, b11, b12, b13, b14, b15;

      r1_new = 128'h0;
      r2_new = 128'h0;
      r3_new = 128'h0;
      r_we   = 1'h0;


      tmp0 = r3_reg ^ t2;

      tmp1   = {r2_reg[127 : 096] + tmp_a[127 : 096],
                r2_reg[095 : 064] + tmp_a[095 : 064],
                r2_reg[063 : 032] + tmp_a[063 : 032],
                r2_reg[031 : 000] + tmp_a[031 : 000]};

      b00 = tmp1[007 : 000];
      b01 = tmp1[015 : 008];
      b02 = tmp1[023 : 016];
      b03 = tmp1[031 : 024];
      b04 = tmp1[039 : 032];
      b05 = tmp1[047 : 040];
      b06 = tmp1[055 : 048];
      b07 = tmp1[063 : 056];
      b08 = tmp1[071 : 064];
      b09 = tmp1[079 : 072];
      b10 = tmp1[087 : 080];
      b11 = tmp1[095 : 088];
      b12 = tmp1[103 : 096];
      b13 = tmp1[111 : 104];
      b14 = tmp1[119 : 112];
      b15 = tmp1[127 : 120];

      tmp2 = {b00, b04, b08, b12, b01, b05, b09, b13,
              b02, b06, b10, b14, b03, b07, b11, b15};


      if (init_state)
        begin
          r1_new = 128'h0;
          r2_new = 128'h0;
          r3_new = 128'h0;
          r_we   = 1'h1;
        end

      if (update_state)
        begin
          r1_new = tmp2;
          r2_new = round0_out;
          r3_new = round1_out;
          r_we   = 1'h1;
        end
    end


  //----------------------------------------------------------------
  // output_logic
  //----------------------------------------------------------------
  always @*
    begin : output_logic

      if (init_state)
        begin
        end

      if (update_state)
        begin
        end
    end


  //----------------------------------------------------------------
  // snow5_core_ctrl
  //----------------------------------------------------------------
  always @*
    begin: snow5_core_ctrl
      ready_new      = 1'h0;
      ready_we       = 1'h0;
      init_state     = 1'h0;
      update_state   = 1'h0;
      snow5_ctrl_new = CTRL_IDLE;
      snow5_ctrl_we  = 1'h0;

      case(snow5_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                ready_new      = 1'h0;
                ready_we       = 1'h1;
                snow5_ctrl_new = CTRL_INIT;
                snow5_ctrl_we  = 1'h1;
              end

            if (next)
              begin
                ready_new      = 1'h0;
                ready_we       = 1'h1;
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


        CTRL_FSM_UPDATE:
          begin
            snow5_ctrl_new = CTRL_DONE;
            snow5_ctrl_we  = 1'h1;
          end


        CTRL_LFSR_UPDATE:
          begin
            snow5_ctrl_new = CTRL_DONE;
            snow5_ctrl_we  = 1'h1;
          end


        CTRL_DONE:
          begin
            ready_new      = 1'h1;
            ready_we       = 1'h1;
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
