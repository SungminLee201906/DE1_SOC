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
      rd_empty<=0;
      rd_ptr<=0;
      rd_bin<=0;
    end else begin
      rd_empty<=rd_empty_val;
      rd_ptr<=rd_gptr_next;
      rd_bin<=rd_bin_next;
    end
end
    
//assign statements
assign rd_bin_next = (rd_inc && !rd_empty)? (rd_bin+rd_inc) : rd_bin;
assign rd_addr = rd_bin[3:0];
assign rd_gptr_next = rd_bin_next ^ (rd_bin_next>>1);
assign rd_empty_temp = (rd_gptr_next == wr_ptr);

endmodule