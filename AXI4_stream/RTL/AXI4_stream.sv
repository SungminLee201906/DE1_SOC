module AXI4_stream #(parameter WIDTH = 8) (
  input  logic             clk,
  input  logic             rst,          // active high, synchronous

  // slave side (data in) From Master view
  input  logic [WIDTH-1:0] s_tdata,
  input  logic             s_tvalid,
  output logic             s_tready,

  // master side (data out) From Slave View

  output logic [WIDTH-1:0] m_tdata,
  output logic             m_tvalid,
  input  logic             m_tready
);

  // We can accept a new word if the slot is empty or is being emptied this cycle
  assign s_tready = !m_tvalid || m_tready;

  always_ff @(posedge clk) begin
    if (rst) begin
      m_tvalid <= 1'b0;
    end else if (s_tready) begin
      m_tvalid <= s_tvalid;
      m_tdata  <= s_tdata;
    end
  end

endmodule
