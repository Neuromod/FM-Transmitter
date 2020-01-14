// Little endian demux

module Demux(clk, reset, enable, inData, available, outData);
    parameter blockSize = 2;
    
    input  wire                         clk;
    input  wire                         reset;
    input  wire                         enable;
    input  wire [7 : 0]                 inData;
    output reg                          available = 0;
    output reg  [8 * blockSize - 1 : 0] outData   = 0;
    
    reg [$clog2(blockSize) - 1 : 0]   index  = 0;
    reg [8 * (blockSize - 1) - 1 : 0] buffer = 0;
    
    always @(posedge clk)
    begin
        if (reset)
        begin
            available <= 0;
            outData   <= 0;
            index     <= 0;
        end
        else
        begin
            if (enable)
            begin
                if (index != blockSize - 1)
                begin
                    buffer    <= {inData, buffer[blockSize * 8 - 9 : 8]};
                    index     <= index + 1;
                    available <= 0;
                end
                else    
                begin
                    outData   <= {inData, buffer};
                    index     <= 0;
                    available <= 1;
                end
            end
        end
    end
endmodule

