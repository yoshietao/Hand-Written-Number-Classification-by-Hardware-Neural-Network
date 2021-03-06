module n2 ( 
	input clk, 
	input rst, 
	input Input_Valid,
	input  [14933:0] wgt,		//785*19
	input  [7859:0]  pix,		//785*10
	output [25:0] Out_neuron, 
	output Output_Valid
	//output [9:0] PixelPort_M00,
	//output [8:0] Count
	//output [25:0] Output_AA1,
	//output [18:0] WeightPort_M00
	//output [25:0] Output_M00,
	//output [25:0] in_1ww
);
wire [25:0] Output_A0;
reg [25:0] Output_A0_r;
wire [25:0] Output_A1;
reg  [25:0] Output_a1;

reg [18:0] WeightPort_M0;
reg [18:0] WeightPort_M1;

reg [9:0] PixelPort_M0;
reg [9:0] PixelPort_M1;

wire [25:0] Output_M0;
wire [25:0] Output_M1;

reg start_r, start_w;
reg [8:0] count_r, count_w;
reg out_valid_r, out_valid_w;

reg [25:0] in_1r, in_1w;

///////////////test//////////////////////////
//assign Count = count_r;
//assign Output_AA1 = Output_A1;
//assign WeightPort_M00 = WeightPort_M0;
//assign Output_M00 = Output_M0;
//assign in_1ww = in_1w;
//assign PixelPort_M00 = PixelPort_M0;
/////////////////////////////////////////////

FixedPointMultiplier M0 ( clk, rst, WeightPort_M0, PixelPort_M0, Output_M0);	//neuron multiplier split to 2
FixedPointMultiplier M1 ( clk, rst, WeightPort_M1, PixelPort_M1, Output_M1);	//neuron multiplier

FixedPointAdder A1 ( clk, rst, Output_M0, Output_M1, Output_A0);			//adder level 1

FixedPointAdder ACC ( clk, rst, Output_A0_r, Output_a1, Output_A1);		//accumulator

FixedPointAdder PA1 ( clk, rst, Output_A1, in_1w, Out_neuron);		//post accumulator adder level 1

assign Output_Valid = out_valid_r;

always@(*) begin
	case(count_r)
		9'b0000_0000_0: begin
			in_1w = 26'b0;
			count_w = 7'b0;
			start_w = 1'b0;
			out_valid_w   = 1'b0;
			WeightPort_M0 = 19'b0;
			WeightPort_M1 = 19'b0;
			PixelPort_M0  = 10'b0;
			PixelPort_M1  = 10'b0;
			Output_A0_r   = 26'b0;
			Output_a1     = 26'b0;
		end
		9'b1100_1000_1:begin				//401
			in_1w = Output_A1;
			count_w = count_r;
			start_w = start_r;
			out_valid_w   = out_valid_r;
			WeightPort_M0 = 19'b0;
			WeightPort_M1 = 19'b0;
			PixelPort_M0  = 10'b0;
			PixelPort_M1  = 10'b0;
			Output_A0_r   = Output_A0;
			Output_a1     = Output_A1;
		end
		9'b1100_1001_1:begin				//403---make output valid be one at 404
			in_1w = in_1r;
			count_w = count_r;
			start_w = start_r;
			out_valid_w   = 1'b1;
			WeightPort_M0 = 19'b0;
			WeightPort_M1 = 19'b0;
			PixelPort_M0  = 10'b0;
			PixelPort_M1  = 10'b0;
			Output_A0_r   = Output_A0;
			Output_a1     = Output_A1;
		end
		9'b1100_1010_0:begin				//404 reset
			in_1w = 26'b0;
			count_w = 7'b0;
			start_w = 1'b0;
			out_valid_w   = 1'b0;
			WeightPort_M0 = 19'b0;
			WeightPort_M1 = 19'b0;
			PixelPort_M0  = 10'b0;
			PixelPort_M1  = 10'b0;
			Output_A0_r   = 26'b0;
			Output_a1     = 26'b0;
		end
		default:begin
			in_1w = in_1r;
			count_w = count_r;
			start_w = start_r;
			out_valid_w   = out_valid_r;
			WeightPort_M0 = wgt[-38+count_r*38+:19];
			WeightPort_M1 = wgt[-19+count_r*38+:19];
			PixelPort_M0  = pix[-20+count_r*20+:10];
			PixelPort_M1  = pix[-10+count_r*20+:10];
			Output_A0_r   = Output_A0;
			Output_a1     = Output_A1;
		end
	endcase
end

always@(posedge clk or posedge rst) begin
	if(rst) begin
		count_r		<= 11'b0;
		start_r		<= 1'b0;
		out_valid_r <= 1'b0;
		in_1r 		<= 26'b0;
	end
	else begin
		if (Input_Valid)begin
			count_r 	<= count_w + 1'b1;
			start_r 	<= 1'b1;
			out_valid_r <= out_valid_w;
			in_1r 		<= in_1w;
		end
		else if (start_w) begin
			count_r 	<= count_w + 1'b1;	
			start_r 	<= start_w;
			out_valid_r <= out_valid_w;
			in_1r 		<= in_1w;
		end
		else begin
			count_r 	<= count_w;	
			start_r 	<= start_w;
			out_valid_r <= out_valid_w;
			in_1r 		<= in_1w;
		end
 	end
end

endmodule
