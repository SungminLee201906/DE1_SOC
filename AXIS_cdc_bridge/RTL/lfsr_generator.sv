module lfsr_generator (
  input  logic        clk,
  input  logic        rst,
  input  logic        clear,       
  input  logic        enable,
  input  logic [7:0]  seed,       
  input  logic [7:0]  throttle,  
  input  logic        inject,         

  output logic [7:0]  m_tdata,
  output logic        m_tvalid,
  input  logic        m_tready,

  output logic [31:0] sent_count
);

  logic [7:0]         lfsr, lfsr_nxt;
  logic [7:0]         gap, gap_nxt;        
  logic               go;
  logic               seed_loaded;
  logic               inject_req;
  logic               corrupt;

  lfsr_step u_data (.cur(lfsr), .nxt(lfsr_nxt));
  lfsr_step u_gap  (.cur(gap),  .nxt(gap_nxt));

  assign go      = enable && (gap >= throttle);
  assign m_tdata = lfsr ^ {7'b0, corrupt};  


  always_ff @(posedge clk or posedge rst) begin
    if (rst) gap <= 8'h5A;
    else     gap <= gap_nxt;
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      lfsr       <= 8'h01;
      m_tvalid   <= 1'b0;
      sent_count <= '0;
      seed_loaded <= 1'b0;
       end else begin
      if (!seed_loaded) begin
        lfsr        <= seed;
        seed_loaded <= 1'b1;
      end else if (m_tvalid && m_tready) begin
        lfsr     <= lfsr_nxt;
        m_tvalid <= go;
      end else if (!m_tvalid) begin
        m_tvalid <= go;
      end

      if (clear)
        sent_count <= '0;
      else if (m_tvalid && m_tready)
        sent_count <= sent_count + 1;
    end
  end


//Error injection
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      inject_req <= 1'b0;
      corrupt    <= 1'b0;
    end else begin
      if (m_tvalid && m_tready) begin
        corrupt <= inject_req | inject;
        inject_req <= 1'b0;
      end else if (!m_tvalid) begin
         corrupt     <= corrupt | inject_req | inject; // idle: arm for the next word offered
         inject_req <= 1'b0;
      end else if (inject) begin
        inject_req <=1'b1;
    end
  end
  end


endmodule
