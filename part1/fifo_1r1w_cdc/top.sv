// Top-level design file for the icebreaker FPGA board
module top
  (input [0:0] clk_12mhz_i
  // n: Negative Polarity (0 when pressed, 1 otherwise)
  // async: Not synchronized to clock
  // unsafe: Not De-Bounced
  ,input [0:0] reset_n_async_unsafe_i
  // async: Not synchronized to clock
  // unsafe: Not De-Bounced
  ,input [3:1] button_async_unsafe_i

  // Line Out (Green)
  // Main clock (for synchronization)
  ,output tx_main_clk_o
  // Selects between L/R channels, but called a "clock"
  ,output tx_lr_clk_o
  // Data clock
  ,output tx_data_clk_o
  // Output Data
  ,output tx_data_o

  // Line In (Blue)
  // Main clock (for synchronization)
  ,output rx_main_clk_o
  // Selects between L/R channels, but called a "clock"
  ,output rx_lr_clk_o
  // Data clock
  ,output rx_data_clk_o
  // Input data
  ,input  rx_data_i

  ,output [5:1] led_o);

   wire        clk_o;

   // These two D Flip Flops form what is known as a Synchronizer. We
   // will learn about these in Week 5, but you can see more here:
   // https://inst.eecs.berkeley.edu/~cs150/sp12/agenda/lec/lec16-synch.pdf
   wire reset_25_n_sync_r;
   wire reset_25_sync_r;
   wire reset_25_r; // Use this as your reset_signal

   wire reset_12_n_sync_r;
   wire reset_12_sync_r;
   wire reset_12_r; // Use this as your reset_signal

   dff
     #()
   sync_a_25
     (.clk_i(clk_25mhz_o)
     ,.reset_i(1'b0)
     ,.en_i(1'b1)
     ,.d_i(reset_n_async_unsafe_i)
     ,.q_o(reset_25_n_sync_r));

   inv
     #()
   inv_25
     (.a_i(reset_25_n_sync_r)
     ,.b_o(reset_25_sync_r));

   dff
     #()
   sync_b_25
     (.clk_i(clk_25mhz_o)
     ,.reset_i(1'b0)
     ,.en_i(1'b1)
     ,.d_i(reset_25_sync_r)
     ,.q_o(reset_25_r));


   dff
     #()
   sync_a_12
     (.clk_i(clk_12mhz_o)
     ,.reset_i(1'b0)
     ,.en_i(1'b1)
     ,.d_i(reset_n_async_unsafe_i)
     ,.q_o(reset_12_n_sync_r));

   inv
     #()
   inv_12
     (.a_i(reset_12_n_sync_r)
     ,.b_o(reset_12_sync_r));

   dff
     #()
   sync_b_12
     (.clk_i(clk_12mhz_o)
     ,.reset_i(1'b0)
     ,.en_i(1'b1)
     ,.d_i(reset_12_sync_r)
     ,.q_o(reset_12_r));
       
   wire [31:0] axis_tx_data;
   wire        axis_tx_valid;
   wire        axis_tx_ready;
   wire        axis_tx_last;
   
   wire [31:0] axis_rx_data;
   wire        axis_rx_valid;
   wire        axis_rx_ready;
   wire        axis_rx_last;


  (* blackbox *)
  SB_PLL40_2_PAD
    #(.FEEDBACK_PATH("SIMPLE")
     ,.DIVR(4'b0000)
     ,.DIVF(7'd59)
     ,.DIVQ(3'd5)
     ,.FILTER_RANGE(3'b001)
     )
   pll_inst
     (.PACKAGEPIN(clk_12mhz_i)
     ,.PLLOUTGLOBALA(clk_12mhz_o)
     ,.PLLOUTGLOBALB(clk_25mhz_o)
     ,.RESETB(1'b1)
     ,.BYPASS(1'b0)
     );
   assign axis_clk = clk_25mhz_o;

   assign axis_tx_data[31:24] = 8'b0;
   axis_i2s2 
     #()
   i2s2_inst
     (.axis_clk(axis_clk)
     ,.axis_resetn(~reset_25_r)
      
     ,.tx_axis_c_data(axis_tx_data)
     ,.tx_axis_c_valid(axis_tx_valid)
     ,.tx_axis_c_ready(axis_tx_ready)
     ,.tx_axis_c_last(axis_tx_last)
     
     ,.rx_axis_p_data(axis_rx_data)
     ,.rx_axis_p_valid(axis_rx_valid)
     ,.rx_axis_p_ready(axis_rx_ready)
     ,.rx_axis_p_last(axis_rx_last)
     
     ,.tx_mclk(tx_main_clk_o)
     ,.tx_lrck(tx_lr_clk_o)
     ,.tx_sclk(tx_data_clk_o)
     ,.tx_sdout(tx_data_o)
     ,.rx_mclk(rx_main_clk_o)
     ,.rx_lrck(rx_lr_clk_o)
     ,.rx_sclk(rx_data_clk_o)
     ,.rx_sdin(rx_data_i)
     );


/*   assign axis_tx_data = axis_rx_data;
   assign axis_tx_last = axis_rx_last;
   assign axis_tx_valid = axis_rx_valid;
   assign axis_rx_ready = axis_tx_ready;
   assign axis_tx_data = axis_rx_data;
*/
   // Input Interface (l for local)
   wire [0:0]        valid_li;
   wire [0:0]        ready_lo;

   wire [23:0] data_right_li;
   wire [23:0] data_left_li;

   // Output Interface (l for local)
   wire [0:0]        valid_lo;
   wire [0:0]        ready_li;        

   wire [23:0] data_right_lo;
   wire [23:0] data_left_lo;

   // Serial in, Parallel out
   sipo
    #()
   sipo_inst
     (.clk_i                            (clk_25mhz_o)
     ,.reset_i                          (reset_25_r)
      // Outputs (Input Interface to your module)
     ,.\data_o[1]                       (data_right_li)
     ,.\data_o[0]                       (data_left_li)
     ,.v_o                              (valid_li)
     ,.ready_i                          (ready_lo & valid_li)
     // Inputs (Don't worry about these)
     ,.ready_and_o                      (axis_rx_ready)
     ,.data_i                           (axis_rx_data[23:0])
     ,.v_i                              (axis_rx_valid)
     );

   // Parallel in, Serial out
   piso
    #()
   piso_inst
     (.clk_i                            (clk_25mhz_o)
     ,.reset_i                          (reset_25_r)
     // Outputs (Don't worry about these)
     // Use the low-order bit to signal last
     ,.data_o                           ({axis_tx_data[23:0], axis_tx_last})
     ,.valid_o                          (axis_tx_valid)
     ,.ready_i                          (axis_tx_ready)
     // Inputs (Output interface from your module)
     ,.\data_i[1]                       ({data_right_lo, 1'b1})
     ,.\data_i[0]                       ({data_left_lo, 1'b0})
     ,.valid_i                          (valid_lo)
     ,.ready_and_o                      (ready_li)
     );

   // Your code goes here

   wire        _ready_o;

   wire        _valid_o;
   wire [47:0] _data_o;

   fifo_1r1w_cdc
     #(// Parameters
       .width_p                         (24),
       .depth_log2_p                    (4))
   fifo_down
     (.cready_o                         (ready_lo),
      .cclk_i                           (clk_25mhz_o),
      .creset_i                         (reset_25_r),
      .cdata_i                          ({data_left_li, data_right_li}),
      .cvalid_i                         (valid_li),

      .pclk_i                           (clk_12mhz_o),
      .preset_i                         (reset_12_r),
      .pdata_o                          (_data_o),
      .pvalid_o                         (_valid_o),
      .pready_i                         (_ready_o));

   fifo_1r1w_cdc
     #(// Parameters
       .width_p                         (24),
       .depth_log2_p                    (4))
   fifo_up
     (.cready_o                         (_ready_o),
      .cclk_i                           (clk_12mhz_o),
      .creset_i                         (reset_12_r),
      .cdata_i                          (_data_o),
      .cvalid_i                         (_valid_o),

      .pvalid_o                         (valid_lo),
      .pdata_o                          ({data_left_lo, data_right_lo}),
      .pclk_i                           (clk_25mhz_o),
      .preset_i                         (reset_25_r),
      .pready_i                         (ready_li));

                         
endmodule
