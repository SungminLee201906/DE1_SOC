`timescale 1ns/1ps

module skid_buffer_tb;

  localparam int N = 50;           // words to send

  logic       clk = 0, rst = 1;
  logic [7:0] s_tdata;
  logic       s_tvalid, s_tready;
  logic [7:0] m_tdata;
  logic       m_tvalid, m_tready;

  skid_buffer #(.WIDTH(8)) dut (.*);

  always #5 clk = ~clk;

  // ---- source: sends 0..N-1 with random gaps, holds data until accepted ----
  logic [7:0] next_val;
  always_ff @(posedge clk) begin
    if (rst) begin
      s_tvalid <= 0; s_tdata <= 0; next_val <= 0;
    end else if (!s_tvalid || s_tready) begin
      if (next_val < N && $urandom_range(0,99) < 70) begin
        s_tvalid <= 1; s_tdata <= next_val; next_val <= next_val + 1;
      end else begin
        s_tvalid <= 0;
      end
    end
  end

  // ---- sink: random backpressure ----
  always_ff @(posedge clk)
    m_tready <= ($urandom_range(0,99) < 60);

  // ---- checker ----
  int         errors = 0, received = 0;
  logic [7:0] expected = 0;
  logic       prev_stall = 0;
  logic [7:0] prev_data;

  always_ff @(posedge clk) begin
    if (!rst) begin
      // data must arrive in order
      if (m_tvalid && m_tready) begin
        if (m_tdata !== expected) begin
          errors++;
          $display("[%0t] FAIL: got %0d, expected %0d", $time, m_tdata, expected);
        end
        expected <= expected + 1;
        received <= received + 1;
      end
      // while stalled, valid and data must hold steady
      if (prev_stall && !(m_tvalid && m_tdata === prev_data)) begin
        errors++;
        $display("[%0t] FAIL: output changed while stalled", $time);
      end
      prev_stall <= m_tvalid && !m_tready;
      prev_data  <= m_tdata;
    end
  end

  initial begin
    repeat (4) @(posedge clk);
    rst <= 0;
    wait (received == N);
    repeat (5) @(posedge clk);
    if (errors == 0) $display("PASS: %0d words transferred", received);
    else             $display("FAIL: %0d error(s)", errors);
    $finish;
  end

  initial begin
    #100_000;
    $display("TIMEOUT: received %0d of %0d", received, N);
    $finish;
  end

endmodule
