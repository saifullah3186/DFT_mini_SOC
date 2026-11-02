// Behavioral model of a 64x8 single-port synchronous RAM (1RW).
// Stand-in for a GPDK RAM macro: replace this file + the .tcd_memory with the
// real macro's Verilog model and memory description (same port names/functions).
// Q holds its value when CE=0 or during a write.
module SYNC_1RW_64x8 (
  input  wire       CLK,
  input  wire       CE,
  input  wire       WE,
  input  wire [5:0] A,
  input  wire [7:0] D,
  output reg  [7:0] Q
);
  reg [7:0] mem [0:63];
  always @(posedge CLK) begin
    if (CE) begin
      if (WE) mem[A] <= D;
      else    Q     <= mem[A];
    end
  end
endmodule
