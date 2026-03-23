/*
* Shift Register module to apply input skew for systolic array inputs
**/
module sreg #(parameter type dtype = logic[31:0], parameter block_size = 5) (
	input logic clk,    
	input logic rst,
	input dtype a_in[block_size - 1: 0],

	output dtype a_out[block_size - 1:0]

);

dtype shift_reg[(block_size*(block_size - 1))/2];


always_ff @(posedge clk) begin 
	if(rst) begin
		for(int k = 0; k < (block_size*(block_size - 1))/2; k++)
			shift_reg[k] <= 0;	
	end else begin

		for(int i = 1; i < block_size; i++) begin
			shift_reg[(i*(i-1))/2] <= a_in[i];
			for(int j = (i*(i-1))/2 + 1; j < (i*(i+1))/2; j++) begin  
				shift_reg[j] <= shift_reg[j - 1];
			end	
		end
	end
end

always_comb begin
		a_out[0] = a_in[0];
		for(int i = 1; i < block_size; i++) begin
			a_out[i] = shift_reg[((i*(i+1))/2) - 1];
		end
end

endmodule : sreg
