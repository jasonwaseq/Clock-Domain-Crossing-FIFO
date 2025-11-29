module fifo_1r1w_cdc
 #(parameter [31:0] width_p = 32
  ,parameter [31:0] depth_log2_p = 8
  )
   // To emphasize that the two interfaces are in different clock
   // domains i've annotated the two sides of the fifo with "c" for
   // consumer, and "p" for producer. 
  (input [0:0] cclk_i
  ,input [0:0] creset_i
  ,input [width_p - 1:0] cdata_i
  ,input [0:0] cvalid_i
  ,output [0:0] cready_o 

  ,input [0:0] pclk_i
  ,input [0:0] preset_i
  ,output [0:0] pvalid_o 
  ,output [width_p - 1:0] pdata_o 
  ,input [0:0] pready_i
  );
   
  logic [depth_log2_p:0] wr_ptr, rd_ptr;

  logic wr_en;
  assign wr_en = cvalid_i & cready_o;

  always_ff @(posedge cclk_i) begin
    if (creset_i) begin
      wr_ptr <= '0;
    end
    else begin
      if (wr_en) begin
        wr_ptr <= wr_ptr + 1;
      end
    end
  end

  logic [depth_log2_p:0] wr_ptr_good;
  always_ff @(posedge cclk_i) begin
    if (creset_i) begin
      wr_ptr_good <= '0;
    end
    else begin
      wr_ptr_good <= wr_ptr;
    end
  end

  logic [depth_log2_p:0] wr_ptr_gray;
  bin2gray
  #(.width_p(depth_log2_p+1))
  bin2graywr (
    .bin_i(wr_ptr_good),
    .gray_o(wr_ptr_gray)
  );

  logic [depth_log2_p:0] wr_ptr_gray1;
  always_ff @(posedge pclk_i) begin
    if (preset_i) begin
      wr_ptr_gray1 <= '0;
    end
    else begin
      wr_ptr_gray1 <= wr_ptr_gray;
    end
  end

  logic [depth_log2_p:0] wr_ptr_gray2;
  always_ff @(posedge pclk_i) begin
    if (preset_i) begin
      wr_ptr_gray2 <= '0;
    end
    else begin
      wr_ptr_gray2 <= wr_ptr_gray1;
    end
  end

  logic [depth_log2_p:0] wr_ptr_bin;
  gray2bin
  #(.width_p(depth_log2_p+1))
  gray2binywr (
    .gray_i(wr_ptr_gray2),
    .bin_o(wr_ptr_bin)
  );

  logic rd_en;
  assign rd_en = pvalid_o & pready_i;

  always_ff @(posedge pclk_i) begin
    if (preset_i) begin
      rd_ptr <= '0;
    end
    else begin
      if (rd_en) begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end

  logic [depth_log2_p:0] rd_ptr_gray;
  bin2gray
  #(.width_p(depth_log2_p+1))
  bin2grayrd (
    .bin_i(rd_ptr),
    .gray_o(rd_ptr_gray)
  );
    
  logic [depth_log2_p:0] rd_ptr_gray1;
  always_ff @(posedge cclk_i) begin
    if (creset_i) begin
      rd_ptr_gray1 <= '0;
    end
    else begin
      rd_ptr_gray1 <= rd_ptr_gray;
    end
  end

  logic [depth_log2_p:0] rd_ptr_gray2;
  always_ff @(posedge cclk_i) begin
    if (creset_i) begin
      rd_ptr_gray2 <= '0;
    end
    else begin
      rd_ptr_gray2 <= rd_ptr_gray1;
    end
  end

  logic [depth_log2_p:0] rd_ptr_bin;
  gray2bin
  #(.width_p(depth_log2_p+1))
  gray2binrd (
    .gray_i(rd_ptr_gray2),
    .bin_o(rd_ptr_bin)
  );

  logic [0:0] full;
  assign full = (wr_ptr[depth_log2_p] ^ rd_ptr_bin[depth_log2_p]) 
                && (wr_ptr[depth_log2_p-1:0] == rd_ptr_bin[depth_log2_p-1:0]);

  assign cready_o = ~full;

  logic [0:0] empty;
  assign empty = ~(wr_ptr_bin[depth_log2_p] ^ rd_ptr[depth_log2_p]) 
                 && (wr_ptr_bin[depth_log2_p-1:0] == rd_ptr[depth_log2_p-1:0]);

  assign pvalid_o = ~empty;

  logic [width_p-1:0] rd_data_l;
  logic [depth_log2_p:0] bypass;
  assign bypass = (rd_en) ? (rd_ptr + 1) : rd_ptr;
  ram_1r1w_sync #(
    .width_p(width_p),
    .depth_p(1<<depth_log2_p),
    .filename_p("")
  ) ram_inst (
    .wclk_i(cclk_i),
    .creset_i(creset_i),
    .wr_valid_i(wr_en),
    .wr_data_i(cdata_i),
    .wr_addr_i(wr_ptr[depth_log2_p-1:0]),

    .rclk_i(pclk_i),
    .preset_i(preset_i),
    .rd_valid_i(1'b1),
    .rd_addr_i(bypass[depth_log2_p-1:0]),
    .rd_data_o(rd_data_l)
  );

  assign pdata_o = rd_data_l;
   
endmodule

