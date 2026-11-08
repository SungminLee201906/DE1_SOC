module read_pointer(
  input logic rd_clk,
  input logic rd_rst,
  input logic rd_inc,
  input logic [4:0] wr_ptr,
  
  output logic rd_empty,
  output logic [4:0] rd_ptr,
  output logic [3:0] rd_addr
);
  
  logic rd_empty_val;
  logic [4:0]rd_bin_next, rd_gptr_next;
  logic [4:0]rd_bin;
  
  always @ (posedge rd_clk or posedge rd_rst) begin
    if(rd_rst) begin
      rd_empty<=1;
      rd_ptr<=0;
      rd_bin<=0;
    end else begin
      rd_empty<=rd_empty_val;
      rd_ptr<=rd_gptr_next;
      rd_bin<=rd_bin_next;
    end
end
    
//assign statements

// Next binary read pointer: advance by one only if a read is requested
// and the FIFO is not empty; otherwise hold the current value.
assign rd_bin_next = (rd_inc && !rd_empty)? (rd_bin+rd_inc) : rd_bin;

// Memory read address: lower 4 bits of the binary pointer (16 slots).
// The top bit is the wrap bit, used only for full/empty comparison.
assign rd_addr = rd_bin[3:0];

// Convert the next binary pointer to Gray code (bin XOR bin>>1) so only
// one bit changes per increment and it is safe to cross clock domains.
assign rd_gptr_next = rd_bin_next ^ (rd_bin_next>>1);

// Empty when the next Gray read pointer equals the synchronized Gray
// write pointer, i.e. the reader has caught up with the writer.
assign rd_empty_val = (rd_gptr_next == wr_ptr);

endmodule