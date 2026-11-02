// mini_soc: tiny single-clock block for studying MBIST, IJTAG and OCC insertion.
// Behaviour: on 'start' it writes 64 LFSR values into the RAM, reads them back
// and accumulates a checksum. 26 flops + one 64x8 RAM. Synchronous reset only.
module mini_soc (
  input  wire       clk,       // functional clock (OCC will intercept this)
  input  wire       rst_n,     // synchronous, active low
  input  wire       start,
  input  wire [7:0] seed,
  output wire       busy,
  output wire       done,
  output wire [7:0] checksum
);
  localparam [2:0] S_IDLE = 3'd0, S_WRITE = 3'd1, S_READ = 3'd2,
                   S_FLUSH = 3'd3, S_DONE = 3'd4;

  reg [2:0] state;
  reg [5:0] addr;
  reg [7:0] lfsr;
  reg [7:0] sum;
  reg       rd_vld;

  wire       ram_ce = (state == S_WRITE) || (state == S_READ);
  wire       ram_we = (state == S_WRITE);
  wire [7:0] ram_q;

  SYNC_1RW_64x8 u_ram (
    .CLK(clk), .CE(ram_ce), .WE(ram_we), .A(addr), .D(lfsr), .Q(ram_q)
  );

  wire [7:0] lfsr_nxt = {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};

  always @(posedge clk) begin
    if (!rst_n) begin
      state  <= S_IDLE;
      addr   <= 6'd0;
      lfsr   <= 8'h01;
      sum    <= 8'h00;
      rd_vld <= 1'b0;
    end else begin
      case (state)
        S_IDLE: if (start) begin
          lfsr   <= (seed == 8'h00) ? 8'h01 : seed;
          addr   <= 6'd0;
          sum    <= 8'h00;
          rd_vld <= 1'b0;
          state  <= S_WRITE;
        end
        S_WRITE: begin
          lfsr <= lfsr_nxt;
          addr <= addr + 6'd1;
          if (addr == 6'd63) state <= S_READ;
        end
        S_READ: begin
          addr   <= addr + 6'd1;
          rd_vld <= 1'b1;
          if (rd_vld) sum <= sum + ram_q;
          if (addr == 6'd63) state <= S_FLUSH;
        end
        S_FLUSH: begin
          sum   <= sum + ram_q;
          state <= S_DONE;
        end
        S_DONE: if (!start) state <= S_IDLE;
        default: state <= S_IDLE;
      endcase
    end
  end

  assign busy     = (state != S_IDLE) && (state != S_DONE);
  assign done     = (state == S_DONE);
  assign checksum = sum;
endmodule
