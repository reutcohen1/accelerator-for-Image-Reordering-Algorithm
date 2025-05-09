/*------------------------------------------------------------------------------
 * File          : test_top.sv
 * Project       : RTL
 * Author        : epnsrc
 * Creation date : Dec 14, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ns

module test_top;

// Parameters
localparam [15:0] NUM_IMAGES = 10;
localparam CLK_PERIOD = 10;

logic clk;
logic reset;

logic [7:0] pixel_data;
logic pixel_valid;
logic start;
logic [15:0] num_images;
logic [15:0] image_header;
logic [15:0] reordered_indices [0:65535];
logic finish_reordering;
logic [15:0] temp_new_reference;
logic [15:0] count_image;
logic new_reference_is_done;
logic image_buffer_valid;
logic hash_calc_done;  
logic [15:0] last_image;
logic CEB1, CEB2;
logic OEB1, OEB2;
logic CSB1, CSB2;

// Instantiate the DUT (Device Under Test)
top dut (
	.clk(clk),
	.reset(reset),
	.pixel_data(pixel_data),
	.pixel_valid(pixel_valid),
	.image_buffer_valid(image_buffer_valid),
	.start(start),
	.image_header(image_header),
	.num_images(NUM_IMAGES),
	.hash_calc_done(hash_calc_done),
	.finish_reordering(finish_reordering),
	.temp_new_reference(temp_new_reference),
	.new_reference_is_done(new_reference_is_done),
	.count_image(count_image),
	.last_image(last_image),
	.CEB1(CEB1),
	.CEB2(CEB2),
	.OEB1(OEB1),
	.OEB2(OEB2),
	.CSB1(CSB1),
	.CSB2(CSB2)
);

// Clock generation
initial begin
	clk = 1;
	CEB1 = 1;
	CEB2 = 1;
	forever #(CLK_PERIOD / 2) clk = ~clk;
end

always #5 CEB1 = ~CEB1; // 10ns clock period for Port 1
always #5 CEB2 = ~CEB2; // 10ns clock period for Port 2

// Test procedure
initial begin
	// Initialize inputs
	reset = 1;
	start = 0;
	pixel_data = 0;
	pixel_valid = 0;
	OEB1 = 0;
	OEB2 = 0;
	CSB1 = 0;
	CSB2 = 0;
	reordered_indices [0] = 0;
	
	// Release reset after a few cycles
	#(2 * CLK_PERIOD);
	reset = 0;

	// Start the system
	#(2 * CLK_PERIOD);
	start = 1;

	// Simulate images
	for (image_header = 0; image_header < NUM_IMAGES; image_header++) begin
		$display("Sending Image %0d", image_header);
		// Send pixel data for one image
		for (int px = 0; px < 256; px++) begin
			pixel_data = $random % 256; // Random pixel data
			pixel_valid = 1;
			#(CLK_PERIOD*1);
		end
		#(CLK_PERIOD*1);
		pixel_valid = 0;

		// Wait for the image buffer to process the image
		wait (dut.image_buffer_valid); 
		#(CLK_PERIOD);
		// Wait for hash calculation for the current image
		wait (dut.hash_calc_done);  
		#(CLK_PERIOD);
	end
	
	// update the new ordering
	while (!dut.finish_reordering) begin
		wait (dut.new_reference_is_done);
		reordered_indices[count_image+1] = temp_new_reference;
		#(CLK_PERIOD);
	end 

		
	// Wait for reordering to finish
	wait (dut.finish_reordering); 
	reordered_indices[count_image+1] = last_image;
	$display("Reordering complete. Reordered indices:");
	for (int i = 0; i < NUM_IMAGES; i++) begin
		$display("Index %0d -> %0d", i, reordered_indices[i]);
	end
	$stop;
end



endmodule
