module lfsr_checker (
  input  logic        clk,
  input  logic        rst,
  input  logic        clear,
  input  logic        enable,
  input  logic [7:0]  seed,        // must match the generator
  input  logic [7:0]  throttle,    // 0 = always ready, higher = more backpressure

  input  logic [7:0]  s_tdata,
  input  logic        s_tvalid,
  output logic        s_tready,

  output logic [31:0] word_count,
  output logic [31:0] err_count,
  output logic        error_seen   // sticky
);

  logic [7:0] expected, expected_nxt;
  logic [7:0] gap, gap_nxt;

  lfsr_step u_exp (.cur(expected), .nxt(expected_nxt));
  lfsr_step u_gap (.cur(gap),      .nxt(gap_nxt));

  always_ff @(posedge clk) begin
    if (rst) gap <= 8'hC3;
    else     gap <= gap_nxt;
  end

  always_ff @(posedge clk) begin
    if (rst || clear) begin
      expected   <= seed;
      word_count <= '0;
      err_count  <= '0;
      error_seen <= 1'b0;
      s_tready   <= 1'b0;
    end else begin
      s_tready <= enable && (gap >= throttle);

      if (s_tvalid && s_tready) begin
        expected   <= expected_nxt;               // follow our own sequence
        word_count <= word_count + 1'b1;
        if (s_tdata != expected) begin
          err_count  <= err_count + 1'b1;
          error_seen <= 1'b1;
        end
      end
    end
  end

endmodule
