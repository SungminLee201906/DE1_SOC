module skid_buffer #(
  parameter WIDTH = 8
)(
  input  logic             clk,
  input  logic             rst,          // active high, synchronous

  // slave side (data in)
  input  logic [WIDTH-1:0] s_tdata,
  input  logic             s_tvalid,
  output logic             s_tready,

  // master side (data out)
  output logic [WIDTH-1:0] m_tdata,
  output logic             m_tvalid,
  input  logic             m_tready
);

  logic [WIDTH-1:0] skid_data;
  logic             skid_valid; //flag to identify if the skid buffer is holding a valid word

  // Registered ready: depends only on a flip-flop, never on m_tready
  assign s_tready = !skid_valid;

  always_ff @(posedge clk) begin
    if (rst) begin
      m_tvalid   <= 1'b0;
      skid_valid <= 1'b0;
    end else begin
      if (s_tvalid && s_tready) begin
        // A word is arriving
        if (!m_tvalid || m_tready) begin
          // Output slot is free or being emptied: pass straight through
          m_tdata  <= s_tdata;
          m_tvalid <= 1'b1;
        end else begin
          // Output is stalled: park the word in the skid slot
          skid_data  <= s_tdata;
          skid_valid <= 1'b1;
        end
      end else if (!m_tvalid || m_tready) begin
        // No new word, and the output is free: refill from the skid slot
        if (skid_valid) begin
          m_tdata    <= skid_data;
          m_tvalid   <= 1'b1;
          skid_valid <= 1'b0;
        end else begin
          m_tvalid   <= 1'b0;
        end
      end
    end
  end

endmodule
