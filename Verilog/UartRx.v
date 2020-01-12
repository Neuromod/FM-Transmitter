// 8-N-1 Uart module
// clockRate should be at least twice the baudRate

module UartRx(clk, uart, available, data);
    parameter integer clockRate = 76_800_000;
    parameter integer uartRate  = 12_000_000;
    
    input  wire         clk;
    input  wire         uart;
    output reg          available = 0;
    output reg  [7 : 0] data      = 0;

    localparam integer scaledClockRate = clockRate / gcd(clockRate, uartRate);
    localparam integer scaledUartRate  = uartRate  / gcd(clockRate, uartRate); 
    localparam real    period          = $itor(scaledClockRate) / $itor(scaledUartRate);
    
    localparam integer preciseTick     = 2 * scaledUartRate;
    localparam integer approximateTick = period > 2 ? $rtoi($ceil(20.0 / (period - 2))) : clockRate;
    localparam integer tick            = preciseTick < approximateTick ? preciseTick : approximateTick;

    localparam integer tick10bit       = $rtoi(1.0 * period * tick + 0.5);             // 1.0 bits in arbitrary time units
    localparam integer tick15bit       = $rtoi(1.5 * period * tick + 0.5);             // 1.5 bits in arbitrary time units

    localparam integer tickWaitBits    = $clog2(tick15bit + 1) + 1;
    
    reg signed [tickWaitBits - 1 : 0] tickWait = 0;
    reg        [3 : 0]                bitIndex = 0;
    reg                               t0       = 1;
    reg                               t1       = 1;
    reg                               t2       = 1;
    reg        [6 : 0]                buffer   = 0;

    function integer gcd;
        input integer a;
        input integer b;
    
        integer r;
    
        begin
            {a, b} = (a < b) ? {b, a} : {a, b};
    
            begin : loop
                forever
                begin
                    r = a % b;
    
                    if (r == 0)
                        disable loop;
    
                    a = b;
                    b = r;
                end
            end
            
            gcd = b;
        end
    endfunction

    always @(posedge clk)
    begin
        t0 <= uart;
        t1 <= t0;
        t2 <= t1;
    
        case (bitIndex)
        0:                                           // Stop or idle
            begin
                if (!t1 && t2)                       // If beginning of start bit (falling edge) 
                begin
                    bitIndex <= 1;
                    tickWait <= tick15bit - tick;
                end
                
                available <= 0;
            end
    
        8:
            if (tickWait < 0)                       // If sampling position of bit 7
            begin
                bitIndex  <= 0;
                data      <= {t2, buffer};
                available <= 1;
            end
            else
                tickWait <= tickWait - tick;
  
        default:
            if (tickWait < 0)                       // If sampling position of bit (bitIndex - 1)
            begin
                bitIndex             <= bitIndex + 1; 
                buffer[bitIndex - 1] <= t2;
                tickWait             <= tickWait - tick + tick10bit;
            end
            else
                tickWait <= tickWait - tick;
        endcase
    end
endmodule
