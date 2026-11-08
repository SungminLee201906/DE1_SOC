//assume address size is 4
//depth = 2^(Address size) - depth is always 2^N
module write_pointer(
  input logic wrclk, //clock for the write domain
  input logic wr_rst,//reset for the write domain
  input logic wr_inc,//increment to next address to write
  input logic [4:0] r_ptr,
  
  output logic wr_full,
  output logic [4:0] wr_ptr,
  output logic [3:0] wr_addr
);
  
logic wr_full_temp;
  logic [4:0] wr_gptr_next,wr_bin_next; //There is a wrap around bit
  logic [4:0] wr_bin; //There is a wrap around bit
  
//synchronizing the output signals  
  always @(posedge wrclk or posedge wr_rst) begin 
  if(wr_rst) begin
     wr_bin<=0;
     wr_ptr<=0;
     wr_full<=0;
  end else begin
     wr_bin<=wr_bin_next;
     wr_ptr<=wr_gptr_next;
     wr_full<=wr_full_temp;
    
  end
end
  

//For address
assign wr_bin_next = (wr_inc && !wr_full) ? (wr_bin+wr_inc) : wr_bin;
assign wr_addr = wr_bin[3:0];
//convert to gray pointer
assign wr_gptr_next = wr_bin_next ^(wr_bin_next>>1);   
//For full check
assign wr_full_temp = wr_gptr_next == ({~r_ptr[4],~r_ptr[3],r_ptr[2:0]});
  
endmodule