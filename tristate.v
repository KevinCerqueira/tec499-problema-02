module tristate(
	inout port,
	input dir,
	input send,
	output read
);

assign port = dir ? send : 1'bZ;
assign read = dir ? 1'bZ : port;

endmodule
