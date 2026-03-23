/*
* Square Shift Register module for uniform delay of input
* */
module square_sreg #(parameter type dtype = logic[31:0], parameter block_size = 5)(
	input logic clk,
	input logic rst,
	input dtype inp[block_size - 1:0],

	output dtype out[block_size - 1:0]
);

dtype sreg_grid [block_size - 1:0][block_size - 1:0];


always_ff @(posedge clk)begin
	if(rst)begin
		for(int i = 0; i < block_size; i++)begin
			for(int j = 0; j < block_size; j++)begin
				sreg_grid[i][j] <= 0;
			end
		end
	end else begin
		sreg_grid[0]		<= inp;
		for(int i = 1; i < block_size; i++)begin
			sreg_grid[i]	<= sreg_grid[i-1];
		end
	end

end

assign out = sreg_grid[block_size - 1];

endmodule
