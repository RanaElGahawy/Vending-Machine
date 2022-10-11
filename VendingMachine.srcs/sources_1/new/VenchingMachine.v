`timescale 1ns / 1ps

module money (input [3:0] num, output reg [6:0] seg);

always @(num)
begin
    case (num) 
        0 : seg = 7'b0000001;
        1 : seg = 7'b1001111;
        2 : seg = 7'b0010010;
        3 : seg = 7'b0000110;
        4 : seg = 7'b1001100;
        5 : seg = 7'b0100100;
        6 : seg = 7'b0100000;
        7 : seg = 7'b0001111;
        8 : seg = 7'b0000000;
        9 : seg = 7'b0000100;
    endcase
end  
endmodule

module CC #(parameter n=50000000) ( input clk, rst, output reg clk_out);

reg [31:0] count;

always@ (posedge clk or posedge rst)
begin
    if (rst) count <= 0;
    else if (count == n-1) count <= 0;
    else count <= count +1;
end

always@ (posedge clk)
begin
    if (count == n-1) clk_out = ~clk_out;
    else clk_out <= clk_out;
end
endmodule



module sync ( input clk, button, output reg out);
reg Q1;

always @(posedge clk)
begin
    Q1 <= button;
    out <= Q1;
end
endmodule

module deb (input clk, button, output out);
reg Q1,Q2,Q3;

always@(posedge(clk))
begin
Q1 <= button;
Q2 <= Q1;
Q3 <= Q2;
end
assign out = Q1 && Q2 && Q3;
endmodule



module RisingEdge ( input clk, rst, button, output out);

parameter A = 2'b00,B = 2'b01 ,C =2'b10;
reg [1:0] state , nextState;

always @(state)
begin
    case(state)
    A: begin
    if (button) nextState <= B;
    else nextState <= A;
    end
    B: begin
    if (button) nextState <= C;
    else nextState <= A;
    end    
    C: begin
    if (button) nextState <= C;
    else nextState <= A;
    end   
    endcase
end


always@(posedge clk or posedge rst)
begin
    if (rst) state <= A;
    else state <= nextState;
end
assign out = (state == B);
endmodule


module VendingMachine(input clk, rst, [2:0] buttons,output led, reg [6:0] bcd, reg [3:0] sel);

wire syn1, syn2, syn3, d1, d2, d3, e1, e2, e3;
wire clk_div;



sync S1 (clk, buttons[0], syn1);
deb D1 (clk, syn1, d1);
RisingEdge E1 (clk, rst , d1, e1);

sync S2 (clk, buttons[1], syn2);
deb D2 (clk, syn2, d2);
RisingEdge E2 (clk, rst , d2, e2);

sync S3 (clk, buttons[2], syn3);
deb D (clk, syn3, d3);
RisingEdge E3 (clk, rst , d3, e3);


CC #(50000) L (clk, rst, clk_div);

reg [6:0] total;
initial total <= 0;

always @( posedge clk or posedge rst)
begin
    if (rst) total <= 0;
    else if (e1) begin total <= (total >= 50)? total -50 +5: total +5; end
    else if (e2) begin total <= (total >= 50)? total -50 +10: total + 10; end
    else if (e3) begin total <= (total >= 50)? total -50 +15: total + 15;  end
end

assign led = (total >= 50); 

wire [3:0] N1, N2;
wire [6:0] NU1, NU2;

assign N1 = total %10;
assign N2 = (total/10) % 10;

money M1 (N1, NU1);
money M2 (N2, NU2);

reg [1:0] count ; 
always @( posedge clk_div or posedge rst)
begin
    if (rst) begin
    sel <= 4'b0000;
    bcd <= 7'b0000001;
    count <= 0;
    end
    else begin
    count <= count +1;
    if (count == 0)
    begin
    sel <= 4'b1110;
    bcd = NU1;   
    end
    if (count == 1)
    begin
    sel <= 4'b1101;
    bcd = NU2;     
    end 
    if (count == 2)
    begin
    sel <= 4'b1011;
    bcd = 7'b0000001;     
    end 
    if (count == 3)
    begin
    sel <= 4'b0111;
    bcd = 7'b0000001;  
    end         
end
end
endmodule
