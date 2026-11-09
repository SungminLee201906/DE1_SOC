`timescale 1ns/1ps

module async_fifo_tb;

  logic       wr_clk = 0, rd_clk = 0;
  logic       wr_rst, rd_rst;
  logic       wr_inc = 0, rd_inc = 0;
  logic [7:0] wr_data = 0;
  logic [7:0] rd_data;
  logic       wr_full, rd_empty;

  int errors = 0;

  async_FIFO dut (.*);

  always #10   wr_clk = ~wr_clk;   // 50 MHz
  always #13.5 rd_clk = ~rd_clk;   // ~37 MHz

  initial begin
    // Reset
    wr_rst = 1; rd_rst = 1;
    repeat (4) @(posedge wr_clk);
    @(negedge wr_clk); wr_rst = 0;
    @(negedge rd_clk); rd_rst = 0;
    repeat (2) @(negedge rd_clk);

    if (!rd_empty) begin errors++; $display("FAIL: not empty after reset"); end

    // Write 8 words: 10, 20, 30, ...
    for (int i = 1; i <= 8; i++) begin
      @(negedge wr_clk);
      wr_data = i * 10;
      wr_inc  = 1;
      @(negedge wr_clk);
      wr_inc  = 0;
    end

    // Read them back and check
    for (int i = 1; i <= 8; i++) begin
      @(negedge rd_clk);
      while (rd_empty) @(negedge rd_clk);
      if (rd_data !== 8'(i * 10)) begin
        errors++;
        $display("FAIL: read %0d, expected %0d", rd_data, i * 10);
      end
      rd_inc = 1;
      @(negedge rd_clk);
      rd_inc = 0;
    end

    repeat (4) @(negedge rd_clk);
    if (!rd_empty) begin errors++; $display("FAIL: not empty at the end"); end

    if (errors == 0) $display("PASS");
    else             $display("FAIL: %0d error(s)", errors);
    $finish;
  end

  initial begin
    #100_000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
