module bin2gray
  #(parameter width_p = 5)
   // You must fill these in with width_p
  (input [width_p-1:0] bin_i
  ,output [width_p-1:0] gray_o);

   // Your code here
  
  logic [width_p-1:0] gray_l;

  always_comb begin
    gray_l = bin_i ^ (bin_i >> 1);
  end

  assign gray_o = gray_l;

endmodule