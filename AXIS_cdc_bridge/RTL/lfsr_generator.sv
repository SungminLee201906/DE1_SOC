module lfsr_generator (
  input  logic        clk,
  input  logic        rst,
  input  logic        clear,       // reload the seed, zero the counter
  input  logic        enable,
  input  logic [7:0]  seed,        // must be non-zero
  input  logic [7:0]  throttle,    // 0 = never pause, higher = pause more

  output logic [7:0]  m_tdata,
  output logic        m_tvalid,
  input  logic        m_tready,

  output logic [31:0] sent_count
);

  logic [7:0] lfsr, lfsr_nxt;
  logic [7:0] gap, gap_nxt;        // free-running LFSR used as a random source
  logic       go;

  lfsr_step u_data (.cur(lfsr), .nxt(lfsr_nxt));
  lfsr_step u_gap  (.cur(gap),  .nxt(gap_nxt));

  assign go      = enable && (gap >= throttle);
  assign m_tdata = lfsr;

  always_ff @(posedge clk) begin
    if (rst) gap <= 8'h5A;
    else     gap <= gap_nxt;
  end

  always_ff @(posedge clk) begin
    if (rst || clear) begin
      lfsr       <= seed;
      m_tvalid   <= 1'b0;
      sent_count <= '0;
    end else if (m_tvalid && m_tready) begin
      // word accepted: step to the next value
      lfsr       <= lfsr_nxt;
      sent_count <= sent_count + 1'b1;
      m_tvalid   <= go;
    end else if (!m_tvalid) begin
      m_tvalid   <= go;
    end
    // else: valid and stalled, hold everything
  end

endmodule
