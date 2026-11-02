`timescale 1ns/1ps
module tb_mini_soc;
  reg clk = 0, rst_n = 0, start = 0;
  reg [7:0] seed = 8'hA5;
  wire busy, done;
  wire [7:0] checksum;
  integer i;
  reg [7:0] expect_sum;

  mini_soc dut (.clk(clk), .rst_n(rst_n), .start(start), .seed(seed),
                .busy(busy), .done(done), .checksum(checksum));

  always #5 clk = ~clk;

  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1;
    @(posedge clk); start = 1;
    wait (done);
    expect_sum = 8'h00;
    for (i = 0; i < 64; i = i + 1) expect_sum = expect_sum + dut.u_ram.mem[i];
    if (checksum === expect_sum)
      $display("PASS: checksum=%h", checksum);
    else
      $display("FAIL: checksum=%h expected=%h", checksum, expect_sum);
    start = 0;
    repeat (3) @(posedge clk);
    $finish;
  end
endmodule
