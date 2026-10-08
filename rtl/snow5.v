//======================================================================
//
// snow5.v
// -------
// Top level wrapper for the SNOW-V stream cipher core.
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

module snow5(
           input wire           clk,
           input wire           reset_n,

           input wire           cs,
           input wire           we,
           input wire  [7 : 0]  address,
           input wire  [31 : 0] write_data,
           output wire [31 : 0] read_data
          );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ADDR_NAME0       = 8'h00;
  localparam ADDR_NAME1       = 8'h01;
  localparam ADDR_VERSION     = 8'h02;

  localparam ADDR_CTRL        = 8'h08;
  localparam CTRL_INIT_BIT    = 0;
  localparam CTRL_NEXT_BIT    = 1;

  localparam ADDR_STATUS      = 8'h09;
  localparam STATUS_READY_BIT = 0;

  localparam ADDR_KEY0        = 8'h10;
  localparam ADDR_KEY7        = 8'h17;

  localparam ADDR_IV0         = 8'h20;
  localparam ADDR_IV3         = 8'h23;

  localparam ADDR_KEYSTREAM0  = 8'h40;
  localparam ADDR_KEYSTREAM3  = 8'h43;

  localparam CORE_NAME0       = 32'h736e6f77; // "snow"
  localparam CORE_NAME1       = 32'h2d762020; // "-v  "
  localparam CORE_VERSION     = 32'h302e3130; // "0.10"


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg init_reg;
  reg init_new;

  reg next_reg;
  reg next_new;

  reg [31 : 0] iv [0 : 3];
  reg          iv_we;

  reg [31 : 0] key [0 : 7];
  reg          key_we;

  reg [127 : 0] keystream_reg;

  reg           ready_reg;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0]   tmp_read_data;

  wire           core_init;
  wire           core_next;
  wire           core_ready;
  wire [255 : 0] core_key;
  wire [127 : 0] core_iv;
  wire [127 : 0] core_keystream;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data = tmp_read_data;

  assign core_key = {key[0], key[1], key[2], key[3],
                     key[4], key[5], key[6], key[7]};

  assign core_iv     = {iv[0], iv[1], iv[2], iv[3]};
  assign core_init   = init_reg;
  assign core_next   = next_reg;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  snow5_core core(
                  .clk(clk),
                  .reset_n(reset_n),

                  .init(core_init),
                  .next(core_next),

                  .key(core_key),
                  .iv(core_iv),

                  .keystream(core_keystream),
                  .ready(core_ready)
                 );


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0 ; i < 4 ; i = i + 1)
            iv[i] <= 32'h0;

          for (i = 0 ; i < 8 ; i = i + 1)
            key[i] <= 32'h0;

          init_reg      <= 1'h0;
          next_reg      <= 1'h0;
          keystream_reg <= 128'h0;
          ready_reg     <= 1'h0;
        end
      else
        begin
          ready_reg     <= core_ready;
          keystream_reg <= core_keystream;
          init_reg      <= init_new;
          next_reg      <= next_new;

          if (key_we)
            key[address[2 : 0]] <= write_data;

          if (iv_we)
            iv[address[1 : 0]] <= write_data;
        end
    end // reg_update


  //----------------------------------------------------------------
  // api
  //----------------------------------------------------------------
  always @*
    begin : api
      init_new      = 1'h0;
      next_new      = 1'h0;
      key_we        = 1'h0;
      iv_we         = 1'h0;
      tmp_read_data = 32'h0;

      if (cs)
        begin
          if (we)
            begin
              if (address == ADDR_CTRL)
                begin
                  init_new = write_data[CTRL_INIT_BIT];
                  next_new = write_data[CTRL_NEXT_BIT];
                end

              if ((address >= ADDR_KEY0) && (address <= ADDR_KEY7))
                key_we = 1'h1;

              if ((address >= ADDR_IV0) && (address <= ADDR_IV3))
                iv_we = 1'h1;
            end // if (we)

          else
            begin
              case (address)
                ADDR_NAME0:   tmp_read_data = CORE_NAME0;
                ADDR_NAME1:   tmp_read_data = CORE_NAME1;
                ADDR_VERSION: tmp_read_data = CORE_VERSION;
                ADDR_STATUS:  tmp_read_data = {31'h0, ready_reg};

                default:
                  begin
                  end
              endcase // case (address)

              if ((address >= ADDR_KEYSTREAM0) && (address <= ADDR_KEYSTREAM3))
                tmp_read_data = keystream_reg[(3 - (address - ADDR_KEYSTREAM0)) * 32 +: 32];
            end
        end
    end // addr_decoder
endmodule // snow5

//======================================================================
// EOF snow5.v
//======================================================================
