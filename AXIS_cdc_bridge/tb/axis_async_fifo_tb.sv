`timescale 1ns/1ps

module axis_async_fifo_tb;

  localparam int N   = 200;   // words to send
  localparam int PKT = 8;     // tlast on every 8th word

  logic       s_clk = 0, m_clk = 0;
  logic       s_rst = 1, m_rst = 1;
  logic [7:0] s_tdata, m_tdata;
  logic       s_tlast, m_tlast;
  logic       s_tvalid, s_tready, m_tvalid, m_tready;

  axis_async_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) dut (.*);

  always #5   s_clk = ~s_clk;   // 100 MHz
  always #8.5 m_clk = ~m_clk;   // ~59 MHz, unrelated to s_clk

  // resets, each released on its own clock
  initial begin repeat (4) @(posedge s_clk); s_rst <= 0; end
  initial begin repeat (4) @(posedge m_clk); m_rst <= 0; end

  // source (write clock domain)
  int sent = 0;
  always_ff @(posedge s_clk) begin
    if (s_rst) begin
      s_tvalid <= 0; s_tdata <= 0; s_tlast <= 0; sent <= 0;
    end else if (!s_tvalid || s_tready) begin
      if (sent < N && $urandom_range(0,99) < 70) begin
        s_tvalid <= 1;
        s_tdata  <= 8'(sent);
        s_tlast  <= ((sent % PKT) == PKT-1);
        sent     <= sent + 1;
      end else begin
        s_tvalid <= 0;
      end
    end
  end

  // sink (read clock domain): random backpressure
  always_ff @(posedge m_clk)
    m_tready <= ($urandom_range(0,99) < 60);

  // checker (read clock domain)
  int         errors = 0, received = 0;
  logic       prev_stall = 0;
  logic [7:0] prev_data;
  logic       prev_last;

  always_ff @(posedge m_clk) begin
    if (!m_rst) begin
      if (m_tvalid && m_tready) begin
        if (m_tdata !== 8'(received)) begin
          errors++;
          $display("[%0t] FAIL: got %0d, expected %0d", $time, m_tdata, 8'(received));
        end
        if (m_tlast !== ((received % PKT) == PKT-1)) begin
          errors++;
          $display("[%0t] FAIL: wrong tlast on word %0d", $time, received);
        end
        received <= received + 1;
      end
      if (prev_stall && !(m_tvalid && m_tdata === prev_data && m_tlast === prev_last)) begin
        errors++;
        $display("[%0t] FAIL: output changed while stalled", $time);
      end
      prev_stall <= m_tvalid && !m_tready;
      prev_data  <= m_tdata;
      prev_last  <= m_tlast;
    end
  end

  initial begin
    wait (received == N);
    repeat (10) @(posedge m_clk);
    if (errors == 0) $display("PASS: %0d words transferred", received);
    else             $display("FAIL: %0d error(s)", errors);
    $finish;
  end

  initial begin
    #1_000_000;
    $display("TIMEOUT: received %0d of %0d", received, N);
    $finish;
  end

endmodule
