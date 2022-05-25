module uart_main(clock, reset, rx, rxEn, out, rxDone, rxBusy, rxErr, tx, txEn, txStart, in, txDone, txBusy);

input clock, reset;
wire uartClk;

// rx

input wire rx, rxEn;
output wire [0:7] out;
output wire rxDone, rxBusy, rxErr;

// tx

output wire tx;
input wire txEn, txStart;
input wire [0:7] in;
output wire txDone, txBusy;

uart_rx uart_rx(clock, rx, rxDone, out);
uart_tx uart_tx(clock, txEn, in, txBusy, tx, txDone);
	
endmodule
