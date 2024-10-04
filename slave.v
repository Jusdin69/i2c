module i2c_slave_controller #(
    parameter SLAVE_ADDR = 7'b1001100,
    parameter DIVIDE_BY = 2
)(  
    input           clk,
    input           rst,
    inout           sda,
    inout           scl,
    input  [7:0]    data,
    input           scl_stretch
);
localparam IDLE = 0,
           RADDR = 1,
           RACK = 2,
           RDATA = 3,
           WDATA = 4,
           WACK = 5,           
           ADDRACK = 6;

reg     [2:0]   cnt;
reg     [7:0]   addr;
reg     [7:0]   in_data;
reg     [7:0]   o_data;
reg             start;
reg             stop;
reg     [3:0]   cs;
reg     [2:0]   state;
reg             sda_out;
reg             sda_prev;
reg             scl_prev;
reg             wen;
reg             stretching;
reg [7:0] scl_counter;
reg  i2c_clk;

assign sda = wen & (!sda_out) ? 0 : 1'bz;
assign scl = stretching ? 0: 1'bz;

//set SDA output value
always@(*) begin
    if(state == RDATA) sda_out = o_data[cnt];
    else sda_out = 0;
end

// read address/data from SDA
always@(posedge clk or negedge rst) begin
    if(!rst) begin
        in_data <= 0;
        addr    <= 0;
    end
    else begin
        case(state)
            RADDR: addr[cnt]    <= sda;
            WDATA: in_data[cnt] <= sda;
            default: begin
                addr    <= addr;
                in_data <= in_data;
            end
        endcase
    end
end

// FSM, write enable control
always @(negedge scl or negedge rst) begin
    if(!rst ) begin
        wen <= 0;
        cnt <= 0;
        state <= 0;
        o_data  <=  0;   
    end
    else begin
        o_data  <=  data;
        case(state)
            IDLE: begin
                if(start) begin
                    state   <= RADDR;
                    cnt     <= 7;
                    wen     <= 0;
                end
                else begin
                    state   <= IDLE;
                    cnt     <= 0;
                    wen     <= 0; 
                end
            end
            RADDR: begin
                if(cnt == 0) begin
                    if(addr[7:1] == SLAVE_ADDR) begin
                        wen <= 1;
                        state <= ADDRACK;
                    end
                    else begin
                        wen <= 0;
                        state <= IDLE;
                    end
                end
                else wen <= 0;
                cnt <= cnt -1;
            end
            RACK: begin
                if(sda) begin
                    state <= IDLE;
                    wen <= 0;
                end
                else begin
                    state <= RDATA;
                    wen <= 1;
                end
            end
            RDATA: begin
                if(!stretching) begin
                    if(cnt == 0) begin
                        state <= RACK;
                        wen <= 0;
                    end
                    else wen <= 1;
                    cnt <= cnt -1; 
                end
            end
            WDATA: begin
                if(!stretching) begin
                    if(start) begin
                        state <= RADDR;
                        cnt <= 7;
                    end else if(stop) state <= IDLE;
                    else begin
                        if(cnt == 0) begin
                            state   <= WACK;
                            wen     <= 1;
                        end
                        else wen <= 0;
                        cnt <= cnt -1;
                    end
                end
            end
            WACK: begin
                state <= WDATA;
                wen = 0;
            end
            ADDRACK: begin
                if(addr[0]) begin
                    state <= RDATA;  
                    wen <= 1;
                end
                else begin
                    state <= WDATA;
                    wen <= 0;
                end   
            end
        endcase
    end
end

//clock stretching
always @(negedge clk or negedge rst) begin
    if(!rst) begin
        stretching  <=   0;
    end
    else begin
        case(state)
            WDATA: begin
                stretching  <=  scl_stretch;
            end
            RDATA: begin
                stretching  <=  scl_stretch;
            end
            default: stretching <=  0;
        endcase
    end
end

//check start, stop signal 
always @(posedge clk or negedge rst ) begin
    if(~rst) begin
        sda_prev    <= 0;
        start       <= 0;
        scl_prev    <=  0;
        stop        <= 0;
    end
    else begin
        if(sda_prev && !sda && scl && scl_prev ) start <= 1;
        else if(~scl)start <= 0;
        if ((~sda_prev && sda && scl && scl_prev)) stop <= 1;
        else if(~sda) stop <= 0;
        if(scl && !scl_prev) i2c_clk <= 1;
        else i2c_clk <= 0;
        sda_prev <= sda;
        scl_prev <= scl;
    end 
end

//i2c clk generator
// always @(posedge clk or negedge rst) begin
//     if(!rst) begin
//         scl_counter <= 0;
//         i2c_clk <= 0;
//     end
//     else begin
//         if (scl_counter == DIVIDE_BY - 1) begin
//             i2c_clk <= ~i2c_clk;
//             scl_counter <= 0;
//         end
//         else scl_counter <= scl_counter + 1;
//     end
// end 

endmodule