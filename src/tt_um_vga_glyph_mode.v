/*
 * Copyright (c) 2024-2025 James Ross
 * Modified: keeps the original Matrix digital-rain "falling code" physics,
 * but the glyphs drawn are the letters of "COLEGIO DE MUNTINLUPA " instead
 * of the standard glyph set, rendered with a small built-in font.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_glyph_mode(
	input  wire [7:0] ui_in,    // Dedicated inputs
	output wire [7:0] uo_out,   // Dedicated outputs
	input  wire [7:0] uio_in,   // IOs: Input path
	output wire [7:0] uio_out,  // IOs: Output path
	output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
	input  wire       ena,      // always 1 when the design is powered, so you can ignore it
	input  wire       clk,      // clock
	input  wire       rst_n     // reset_n - low to reset
);

	// VGA signals
	wire hsync, vsync, display_on;
	wire [10:0] hpos;
	wire [9:0] vpos;

	// TinyVGA PMOD
	assign uo_out = {hsync, RGB[0], RGB[2], RGB[4], vsync, RGB[1], RGB[3], RGB[5]};

	// Unused outputs assigned to 0.
	assign uio_out = 0;
	assign uio_oe  = 0;

	wire [7:0] xb = hpos[10:3];
	wire [6:0] x_mix = {xb[7] ^ xb[3], xb[1], xb[4], xb[1], xb[6], xb[0], xb[2]};
	wire [2:0] g_x = hpos[2:0];
	wire [5:0] yb;
	wire [3:0] _unused;
	assign {_unused, yb} = vpos / 10'd12;
	wire [5:0] g_unused;
	wire [3:0] g_y;
	assign {g_unused, g_y} = vpos - {yb, 3'b000} - {1'b0, yb, 2'b00};
	wire hl;

	// Suppress unused signals warning
	wire _unused_ok = &{ena, ui_in[5:2], uio_in};

	reg [9:0] frame;
	reg rst_drop;

	// VGA output
	hvsync_generator hvsync_gen(
		.clk(clk),
		.reset(~rst_n),
		.mode(ui_in[7:6]),
		.hsync(hsync),
		.vsync(vsync),
		.display_on(display_on),
		.hpos(hpos),
		.vpos(vpos)
	);

	// ------------------------------------------------------------------
	// Glyph selection: instead of 39 stock glyphs, cycle through the
	// letters of "COLEGIO DE MUNTINLUPA " (22 symbols incl. trailing space)
	// ------------------------------------------------------------------
	localparam MSG_LEN = 22;
	wire [4:0] glyph_index = (yb + xb) % MSG_LEN;

	// symbol ids: 0=A 1=C 2=D 3=E 4=G 5=I 6=L 7=M 8=N 9=O 10=P 11=T 12=U 13=space
	reg [3:0] sym_id;
	always @(*) begin
		case (glyph_index)
			5'd0:  sym_id = 4'd1;  // C
			5'd1:  sym_id = 4'd9;  // O
			5'd2:  sym_id = 4'd6;  // L
			5'd3:  sym_id = 4'd3;  // E
			5'd4:  sym_id = 4'd4;  // G
			5'd5:  sym_id = 4'd5;  // I
			5'd6:  sym_id = 4'd9;  // O
			5'd7:  sym_id = 4'd13; // (space)
			5'd8:  sym_id = 4'd2;  // D
			5'd9:  sym_id = 4'd3;  // E
			5'd10: sym_id = 4'd13; // (space)
			5'd11: sym_id = 4'd7;  // M
			5'd12: sym_id = 4'd12; // U
			5'd13: sym_id = 4'd8;  // N
			5'd14: sym_id = 4'd11; // T
			5'd15: sym_id = 4'd5;  // I
			5'd16: sym_id = 4'd8;  // N
			5'd17: sym_id = 4'd6;  // L
			5'd18: sym_id = 4'd12; // U
			5'd19: sym_id = 4'd10; // P
			5'd20: sym_id = 4'd0;  // A
			default: sym_id = 4'd13; // index 21 -> trailing space
		endcase
	end

	// 5x7 block font, addressed by symbol id and row (0..6); rows 7..11 (g_y) are blank line-spacing
	reg [4:0] font_bits;
	always @(*) begin
		case ({sym_id, g_y[2:0]})
			// A
			{4'd0,3'd0}: font_bits = 5'b01110;
			{4'd0,3'd1}: font_bits = 5'b10001;
			{4'd0,3'd2}: font_bits = 5'b10001;
			{4'd0,3'd3}: font_bits = 5'b11111;
			{4'd0,3'd4}: font_bits = 5'b10001;
			{4'd0,3'd5}: font_bits = 5'b10001;
			{4'd0,3'd6}: font_bits = 5'b10001;
			// C
			{4'd1,3'd0}: font_bits = 5'b01111;
			{4'd1,3'd1}: font_bits = 5'b10000;
			{4'd1,3'd2}: font_bits = 5'b10000;
			{4'd1,3'd3}: font_bits = 5'b10000;
			{4'd1,3'd4}: font_bits = 5'b10000;
			{4'd1,3'd5}: font_bits = 5'b10000;
			{4'd1,3'd6}: font_bits = 5'b01111;
			// D
			{4'd2,3'd0}: font_bits = 5'b11110;
			{4'd2,3'd1}: font_bits = 5'b10001;
			{4'd2,3'd2}: font_bits = 5'b10001;
			{4'd2,3'd3}: font_bits = 5'b10001;
			{4'd2,3'd4}: font_bits = 5'b10001;
			{4'd2,3'd5}: font_bits = 5'b10001;
			{4'd2,3'd6}: font_bits = 5'b11110;
			// E
			{4'd3,3'd0}: font_bits = 5'b11111;
			{4'd3,3'd1}: font_bits = 5'b10000;
			{4'd3,3'd2}: font_bits = 5'b10000;
			{4'd3,3'd3}: font_bits = 5'b11110;
			{4'd3,3'd4}: font_bits = 5'b10000;
			{4'd3,3'd5}: font_bits = 5'b10000;
			{4'd3,3'd6}: font_bits = 5'b11111;
			// G
			{4'd4,3'd0}: font_bits = 5'b01111;
			{4'd4,3'd1}: font_bits = 5'b10000;
			{4'd4,3'd2}: font_bits = 5'b10000;
			{4'd4,3'd3}: font_bits = 5'b10011;
			{4'd4,3'd4}: font_bits = 5'b10001;
			{4'd4,3'd5}: font_bits = 5'b10001;
			{4'd4,3'd6}: font_bits = 5'b01111;
			// I
			{4'd5,3'd0}: font_bits = 5'b11111;
			{4'd5,3'd1}: font_bits = 5'b00100;
			{4'd5,3'd2}: font_bits = 5'b00100;
			{4'd5,3'd3}: font_bits = 5'b00100;
			{4'd5,3'd4}: font_bits = 5'b00100;
			{4'd5,3'd5}: font_bits = 5'b00100;
			{4'd5,3'd6}: font_bits = 5'b11111;
			// L
			{4'd6,3'd0}: font_bits = 5'b10000;
			{4'd6,3'd1}: font_bits = 5'b10000;
			{4'd6,3'd2}: font_bits = 5'b10000;
			{4'd6,3'd3}: font_bits = 5'b10000;
			{4'd6,3'd4}: font_bits = 5'b10000;
			{4'd6,3'd5}: font_bits = 5'b10000;
			{4'd6,3'd6}: font_bits = 5'b11111;
			// M
			{4'd7,3'd0}: font_bits = 5'b10001;
			{4'd7,3'd1}: font_bits = 5'b11011;
			{4'd7,3'd2}: font_bits = 5'b10101;
			{4'd7,3'd3}: font_bits = 5'b10101;
			{4'd7,3'd4}: font_bits = 5'b10001;
			{4'd7,3'd5}: font_bits = 5'b10001;
			{4'd7,3'd6}: font_bits = 5'b10001;
			// N
			{4'd8,3'd0}: font_bits = 5'b10001;
			{4'd8,3'd1}: font_bits = 5'b11001;
			{4'd8,3'd2}: font_bits = 5'b10101;
			{4'd8,3'd3}: font_bits = 5'b10101;
			{4'd8,3'd4}: font_bits = 5'b10011;
			{4'd8,3'd5}: font_bits = 5'b10001;
			{4'd8,3'd6}: font_bits = 5'b10001;
			// O
			{4'd9,3'd0}: font_bits = 5'b01110;
			{4'd9,3'd1}: font_bits = 5'b10001;
			{4'd9,3'd2}: font_bits = 5'b10001;
			{4'd9,3'd3}: font_bits = 5'b10001;
			{4'd9,3'd4}: font_bits = 5'b10001;
			{4'd9,3'd5}: font_bits = 5'b10001;
			{4'd9,3'd6}: font_bits = 5'b01110;
			// P
			{4'd10,3'd0}: font_bits = 5'b11110;
			{4'd10,3'd1}: font_bits = 5'b10001;
			{4'd10,3'd2}: font_bits = 5'b10001;
			{4'd10,3'd3}: font_bits = 5'b11110;
			{4'd10,3'd4}: font_bits = 5'b10000;
			{4'd10,3'd5}: font_bits = 5'b10000;
			{4'd10,3'd6}: font_bits = 5'b10000;
			// T
			{4'd11,3'd0}: font_bits = 5'b11111;
			{4'd11,3'd1}: font_bits = 5'b00100;
			{4'd11,3'd2}: font_bits = 5'b00100;
			{4'd11,3'd3}: font_bits = 5'b00100;
			{4'd11,3'd4}: font_bits = 5'b00100;
			{4'd11,3'd5}: font_bits = 5'b00100;
			{4'd11,3'd6}: font_bits = 5'b00100;
			// U
			{4'd12,3'd0}: font_bits = 5'b10001;
			{4'd12,3'd1}: font_bits = 5'b10001;
			{4'd12,3'd2}: font_bits = 5'b10001;
			{4'd12,3'd3}: font_bits = 5'b10001;
			{4'd12,3'd4}: font_bits = 5'b10001;
			{4'd12,3'd5}: font_bits = 5'b10001;
			{4'd12,3'd6}: font_bits = 5'b01110;
			default: font_bits = 5'b00000; // space, and blank line-spacing rows
		endcase
	end

	// g_y >= 7 is blank line spacing; g_x >= 5 is blank column spacing (font is 5 wide)
	assign hl = (g_y < 4'd7) && (g_x < 3'd5) && font_bits[4 - g_x];

	// ------------------------------------------------------------------
	// Palette: small built-in brightness ramp (green/red/blue/pride)
	// standing in for the original palette ROM, driven by the same
	// pseudo-random "y" brightness index as the original design.
	// ------------------------------------------------------------------
	reg [5:0] color;
	always @(*) begin
		case (ui_in[1:0])
			2'd1: color = {y[2:1], 2'b00, 2'b00};       // red ramp
			2'd2: color = {2'b00, 2'b00, y[2:1]};       // blue ramp
			2'd3: begin                                  // pride: cycle hues
				case (y[1:0])
					2'd0: color = 6'b100100; // warm
					2'd1: color = 6'b001000; // green
					2'd2: color = 6'b000010; // blue
					default: color = 6'b100010; // magenta
				endcase
			end
			default: color = {2'b00, y[2:1], 2'b00};    // green ramp (default)
		endcase
	end

	// there are 22 message glyphs; keep the original falling/flicker math unchanged
	wire [1:0] a = xb[1:0];
	wire [3:0] b = xb[5:2];
	wire [2:0] d = xb[3:2] + 2'd3;

	// column features
	wire s = ^xb[6:0]; // speed of rain
	wire n = xb[1] ^ xb[3] ^ xb[5]; // lit on or off

	wire [6:0] v = (s ? frame[8:2] : frame[9:3]) - yb - x_mix;
	wire [3:0] c = {1'b0, a} + d;
	wire [6:0] e = {3'b000, b} << c;
	wire [6:0] f = v & e;
	wire [6:0] x = v >> a;
	wire [2:0] y = ~x[2:0];
	wire [9:0] drop = {1'b0, yb, 3'd0} >> s;
	wire drop_bit = ({3'd0, x_mix} + drop > frame) & ~rst_drop;
	wire [5:0] glyph_color = {6{drop_bit}} ^ color;

	wire [5:0] z = (&(~v[2:0]) & &(y)) ? 6'd63 : glyph_color;

	wire [5:0] RGB = (display_on & hl & ~(|f | n | drop_bit)) ? z : 6'd0;

	always @(posedge vsync, negedge rst_n) begin
		if (~rst_n) begin
			rst_drop <= 0;
			frame <= 0;
		end else begin
			if (&frame) begin
				rst_drop <= 1;
			end
			frame <= frame + 1;
		end
	end

endmodule
