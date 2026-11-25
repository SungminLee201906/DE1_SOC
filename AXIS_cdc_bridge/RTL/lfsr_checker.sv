module lfsr_checker (
  input  logic        clk,
  input  logic        rst,         
  input  logic        clear,       
  input  logic        enable,
  input  logic [7:0]  seed,        
  input  logic [7:0]  throttle,    

  input  logic [7:0]  s_tdata,
  input  logic        s_tvalid,
  output logic        s_tready,

  output logic [31:0] word_count,
  output logic [31:0] err_count,
  output logic        error_seen   
);

  logic [7:0] expected, expected_nxt;
  logic [7:0] gap, gap_nxt;        
  logic       seed_loaded;         

  lfsr_step u_exp (.cur(expected), .nxt(expected_nxt));
  lfsr_step u_gap (.cur(gap),      .nxt(gap_nxt));

  always_ff @(posedge clk or posedge rst) begin
    if (rst) gap <= 8'hC3;
    else     gap <= gap_nxt;
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      expected    <= 8'h01;        
      seed_loaded <= 1'b0;
      s_tready    <= 1'b0;
      word_count  <= '0;
      err_count   <= '0;
      error_seen  <= 1'b0;
    end else begin
      // LFSR and handshake
      if (!seed_loaded) begin
        expected    <= seed;       
        seed_loaded <= 1'b1;
        s_tready    <= 1'b0;       
      end else begin
        s_tready <= enable && (gap >= throttle);
        if (s_tvalid && s_tready)
          expected <= expected_nxt;   
      end

      
      if (clear) begin
        word_count <= '0;
        err_count  <= '0;
        error_seen <= 1'b0;
      end else if (s_tvalid && s_tready) begin
        word_count <= word_count + 1;
        if (s_tdata != expected) begin
          err_count  <= err_count + 1;
          error_seen <= 1'b1;
        end
      end
    end
  end

endmodule
