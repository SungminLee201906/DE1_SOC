module wr_regs (
  input  logic        clk,                // wr_clk
  input  logic        rst,                // hard reset only (soft reset must not clear the registers)

  // Avalon-MM slave (word addresses, read latency 1, no waitrequest)
  input  logic [1:0]  avs_s0_address,
  input  logic        avs_s0_write,
  input  logic [31:0] avs_s0_writedata,
  input  logic        avs_s0_read,
  output logic [31:0] avs_s0_readdata,

  // to / from the write side of the bridge
  output logic        enable,             // CTRL[0]
  output logic        soft_reset,         // CTRL[1]
  output logic        inject,             // CTRL[2], 1-cycle pulse
  output logic        counter_clear,      // CTRL[3], 1-cycle pulse
  output logic [7:0]  seed,               // SEED[7:0]
  output logic [7:0]  throttle,           // THROTTLE[7:0]
  input  logic [31:0] sent_count          // SENT_COUNT
);

  // Word addresses (byte offset / 4)
  localparam logic [1:0] A_CTRL     = 2'd0;   // 0x00
  localparam logic [1:0] A_SEED     = 2'd1;   // 0x04
  localparam logic [1:0] A_THROTTLE = 2'd2;   // 0x08
  localparam logic [1:0] A_SENT     = 2'd3;   // 0x0C

  // ---- writes ----
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      enable        <= 1'b0;
      soft_reset    <= 1'b0;
      inject        <= 1'b0;
      counter_clear <= 1'b0;
      seed          <= 8'h01;
      throttle      <= 8'h00;
    end else begin
      inject        <= 1'b0;              // self-clearing: back to 0 every cycle
      counter_clear <= 1'b0;              // unless written to 1 this cycle

      if (avs_s0_write) begin
        case (avs_s0_address)
          A_CTRL: begin
            enable        <= avs_s0_writedata[0];
            soft_reset    <= avs_s0_writedata[1];
            inject        <= avs_s0_writedata[2];
            counter_clear <= avs_s0_writedata[3];
          end
          A_SEED:     seed     <= avs_s0_writedata[7:0];
          A_THROTTLE: throttle <= avs_s0_writedata[7:0];
          default: ;                      // SENT_COUNT is read-only
        endcase
      end
    end
  end

  // ---- reads (data valid one clock after avs_s0_read) ----
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      avs_s0_readdata <= '0;
    else if (avs_s0_read) begin
      case (avs_s0_address)
        A_CTRL:     avs_s0_readdata <= {28'b0, 1'b0, 1'b0, soft_reset, enable};  // pulse bits read 0
        A_SEED:     avs_s0_readdata <= {24'b0, seed};
        A_THROTTLE: avs_s0_readdata <= {24'b0, throttle};
        A_SENT:     avs_s0_readdata <= sent_count;
      endcase
    end
  end

endmodule
