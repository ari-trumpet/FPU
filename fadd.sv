`timescale 1ns/1ps

module fadd (
	 	input logic clk, // 外部からのclock
    input logic[31:0] a, // 第一オペランド
    input logic[31:0] b, // 第二オペランド
    output logic[31:0] c, // 加算結果
    output logic[8:0] DIFF,
    output logic SIGN1,
    output logic[26:0] SHIFT_MB
);

// reg
  logic[31:0] input1,input2;  //ok
  logic[26:0] shift_mb;       //ok

// wire
  logic[31:0] in1,in2;  //ok
  logic[3:0] flag1,flag2;		// コーナーケースのフラグ isnan,isinf,isninf,exp0 の順
  logic[7:0] flag12;
  logic[2:0] flag;					// 000:normal 001:nan 010:inf 011:ninf 100:zero 101:a 110:b
  logic sign1,sign2;
  logic[7:0] exp1,exp2;
  logic[22:0] mant1,mant2;
  logic[4:0] returncase;		// コーナーケース以外の特殊ケース 
  													// 00000:normal 00001:return big(l44) 00010:
  logic[8:0] expdiff;  //ok// 9bit
  logic[26:0] ma,mb; //ok
  logic[27:0] maplus1,maminus1;  // ok 
  logic[7:0] expsub,expselect,expselect3;
  logic[8:0] expsub2,expselect2;
  logic[26:0] maplus2,maminus2,maselect,maselect3;
  logic[27:0] maselect2;
  logic pattern1,pattern2,pattern3;
  logic[8:0] expplus;  //ok
  logic[31:0] returnbits;
  
// int
	integer i;  
//______________________________________________________________________

/**/
function ISNAN ( input logic[31:0] IN );
begin
	if(IN[30:23] == 8'b11111111 && IN[22:0] != 23'b00000000000000000000000)
	  ISNAN = 1'b1;
	else
	  ISNAN = 1'b0;
end
endfunction

/**/
function ISINF ( input logic[31:0] IN );
begin
	if(IN == 32'h7f800000)
	  ISINF = 1'b1;
	else
	  ISINF = 1'b0;
end
endfunction

/**/
function ISNINF ( input logic[31:0] IN );
begin
	if(IN == 32'hff800000)
	  ISNINF = 1'b1;
	else
	  ISNINF = 1'b0;
end
endfunction

function EXP0 ( input logic[31:0] IN );
begin
	if(IN[30:23] == 8'h00)
		EXP0 = 1'b1;
	else
		EXP0 = 1'b0;
end
endfunction

function SIGN ( input logic[31:0] IN );
begin
	SIGN = IN[31];
end
endfunction

function logic[7:0] EXP ( input logic[31:0] IN );
begin
	EXP[7:0] = IN[30:23];
end
endfunction

function logic[22:0] MANT ( input logic[31:0] IN );
begin
	MANT[22:0] = IN[22:0];
end
endfunction
//______________________________________________________________________

/* in1 >= in2 となるようa,bを代入 */
always_ff @(posedge clk) 
begin
	input1 <= a;
	input2 <= b;
end


/* コーナーケースのフラグを立てる */
	assign flag1[3] = ISNAN(input1);
	assign flag1[2] = ISINF(input1);
	assign flag1[1] = ISNINF(input1);
	assign flag1[0] = EXP0(input1);
	assign flag2[3] = ISNAN(input2);
	assign flag2[2] = ISINF(input2);
	assign flag2[1] = ISNINF(input2);
	assign flag2[0] = EXP0(input2);

    assign flag12 = {flag1,flag2};
    
function logic[2:0] FLAG ( input logic[7:0] flags );
	begin
		if(flags[7] == 1'b1 || flags[3] == 1'b1) /* nanのinput */
			FLAG = 3'b001;		// nan
		else if((flags[6]==1'b1&&flags[1]==1'b1)||(flags[5]==1'b1&&flags[2]==1'b1)) /*  */
			FLAG = 3'b001;		// nan
		else if(flags[6]==1'b1||flags[2]==1'b1)
			FLAG = 3'b010;		// inf
		else if(flags[5]==1'b1||flags[1]==1'b1)
			FLAG = 3'b011;		// ninf
		else if(flags[4]==1'b1&&flags[0]==1'b1)
			FLAG = 3'b100;		// zero
		else if(flags[4]==1'b1)
			FLAG = 3'b110;		// b
		else if(flags[0]==1'b1)
			FLAG = 3'b101;		// a
		else
			FLAG = 3'b000;		// normal
	end
endfunction 

	assign flag = FLAG(flag12);
	                               //  ここまで検証済み
/* 入力を大小入れ替え */
	always_comb
	begin
		if(input1[30:0] >= input2[30:0])
		begin
			in1 = input1;
			in2 = input2;
		end
		else
		begin
			in1 = input2;
			in2 = input1;
		end
	end

	assign sign1 = in1[31];
	assign exp1  = EXP(in1);
	assign mant1 = MANT(in1);	
	assign sign2 = in2[31];
	assign exp2  = EXP(in2);
	assign mant2 = MANT(in2);

	assign expdiff = (exp1 - exp2);    // 本当に大丈夫なのか？
	
	assign DIFF = expdiff[8:0];  // ok
	assign SIGN1 = sign1;        // ok
	
	always_comb
	begin
		if( expdiff[7:0] > 8'd26)
			returncase[0] = 1'b1;
		else
			returncase[0] = 1'b0;
	end

	assign ma = {1'b1,mant1,3'b000};
	assign mb = {1'b1,mant2,3'b000};

/*
	always_latch @(expdiff,mb,shift_mb)
	begin
		for(i = 0; i < expdiff; ++i) begin
		  if(i==0)
			shift_mb <= mb;
		  else
			shift_mb <= {shift_mb[26:2],&shift_mb[1:0]};
		end
	end
*/
    function logic[26:0] SHIFTMB ( input logic[26:0] mantissab, logic[7:0] diff );
    begin
      priority case(diff)
        27'd0:    SHIFTMB = mantissab;
        27'd1:    SHIFTMB = {(mantissab[26:1] >> 1),|mantissab[1:0]};
        27'd2:    SHIFTMB = {(mantissab[26:1] >> 2),|mantissab[2:0]};
        27'd3:    SHIFTMB = {(mantissab[26:1] >> 3),|mantissab[3:0]};
        27'd4:    SHIFTMB = {(mantissab[26:1] >> 4),|mantissab[4:0]};
        27'd5:    SHIFTMB = {(mantissab[26:1] >> 5),|mantissab[5:0]};
        27'd6:    SHIFTMB = {(mantissab[26:1] >> 6),|mantissab[6:0]};
        27'd7:    SHIFTMB = {(mantissab[26:1] >> 7),|mantissab[7:0]};
        27'd8:    SHIFTMB = {(mantissab[26:1] >> 8),|mantissab[8:0]};
        27'd9:    SHIFTMB = {(mantissab[26:1] >> 9),|mantissab[9:0]};
        27'd10:    SHIFTMB ={(mantissab[26:1] >> 10),|mantissab[10:0]};
        27'd11:    SHIFTMB = {(mantissab[26:1] >> 11),|mantissab[11:0]};
        27'd12:    SHIFTMB = {(mantissab[26:1] >> 12),|mantissab[12:0]};
        27'd13:    SHIFTMB = {(mantissab[26:1] >> 13),|mantissab[13:0]};
        27'd14:    SHIFTMB = {(mantissab[26:1] >> 14),|mantissab[14:0]};
        27'd15:    SHIFTMB = {(mantissab[26:1] >> 15),|mantissab[15:0]};
        27'd16:    SHIFTMB = {(mantissab[26:1] >> 16),|mantissab[16:0]};
        27'd17:    SHIFTMB = {(mantissab[26:1] >> 17),|mantissab[17:0]};
        27'd18:    SHIFTMB = {(mantissab[26:1] >> 18),|mantissab[18:0]};
        27'd19:    SHIFTMB = {(mantissab[26:1] >> 19),|mantissab[19:0]};
        27'd20:    SHIFTMB = {(mantissab[26:1] >> 20),|mantissab[20:0]};
        27'd21:    SHIFTMB = {(mantissab[26:1] >> 21),|mantissab[21:0]};
        27'd22:    SHIFTMB = {(mantissab[26:1] >> 22),|mantissab[22:0]};
        27'd23:    SHIFTMB = {(mantissab[26:1] >> 23),|mantissab[23:0]};
        27'd24:    SHIFTMB = {(mantissab[26:1] >> 24),|mantissab[24:0]};
        27'd25:    SHIFTMB = {(mantissab[26:1] >> 25),|mantissab[25:0]};
        27'd26:    SHIFTMB = {(mantissab[26:1] >> 26),|mantissab[26:0]};
   default:    SHIFTMB = 1'b0; 
     endcase
   end
 endfunction   
        
    assign shift_mb = SHIFTMB(mb,expdiff[7:0]);
                
    assign SHIFT_MB = shift_mb; //ok           
                
    always_comb  /* fadd.c l:55 */
    begin
      if(sign1 == sign2) 
        pattern1 = 1'b1;
      else
        pattern1 = 1'b0;
    end
	
	always_comb  /* fadd.c l:56 */
    begin
     if(pattern1 == 1'b1) 
      maplus1 = ma + shift_mb;  // 28bit = 27bit + 27bit 
     else
      maplus1 = 28'b0;
     end
    
    always_comb
    begin
      if(pattern1 == 1'b1 && maplus1[27] == 1'b1)
        pattern2 = 1'b1;
      else
        pattern2 = 1'b0;
    end
    
    always_comb  /* fadd.c l:58 */
    begin
      if(pattern2 == 1'b1)
        expplus = exp1 + 1;  
      else
        expplus = 1'b0;
    end
    
    always_comb  /* fadd.c l:59 */
     begin
       if(pattern2 == 1'b1)
         maplus2 = {maplus1[27:2],|maplus1[1:0]};
       else
         maplus2 = 1'b0;
     end    
     
	always_comb  /* fadd.c l:62 */
	begin
	  if(pattern1 == 1'b0)
		  maminus1 = ma - shift_mb;   // ここをミスってたのかああああ！！！	x ma - mb;	  
	  else 
		  maminus1 = 28'b0;            // 
    end
    
    always_comb  /* fadd.c l:63 */
    begin
	  if(pattern1 == 1'b0 && maminus1 == 28'b0)
		returncase[1] = 1'b1;
	  else
	    returncase[1] = 1'b0;
	end
	
	function logic[7:0] EXPMINUS ( input logic[27:0] IN );
    begin
      if(IN[26]==1'b1)
        EXPMINUS = 8'h00;
      else if(IN[25]==1'b1)
        EXPMINUS = 8'h01;
      else if(IN[24]==1'b1)
        EXPMINUS = 8'h02;
      else if(IN[23]==1'b1)
        EXPMINUS = 8'h03;
      else if(IN[22]==1'b1)
        EXPMINUS = 8'h04;
      else if(IN[21]==1'b1)
        EXPMINUS = 8'h05;
      else if(IN[20]==1'b1)
        EXPMINUS = 8'h06;
      else if(IN[19]==1'b1)
        EXPMINUS = 8'h07;
      else if(IN[18]==1'b1)
        EXPMINUS = 8'h08;            
      else if(IN[17]==1'b1)
        EXPMINUS = 8'h09;
      else if(IN[16]==1'b1)
        EXPMINUS = 8'h0a;
      else if(IN[15]==1'b1)  
        EXPMINUS = 8'h0b;
      else if(IN[14]==1'b1)  
        EXPMINUS = 8'h0c;
      else if(IN[13]==1'b1)  
        EXPMINUS = 8'h0d;
      else if(IN[12]==1'b1)  
        EXPMINUS = 8'h0e;
      else if(IN[11]==1'b1)  
        EXPMINUS = 8'h0f;
      else if(IN[10]==1'b1)  
        EXPMINUS = 8'h10;
      else if(IN[9]==1'b1)  
        EXPMINUS = 8'h11;
      else if(IN[8]==1'b1)  
        EXPMINUS = 8'h12;
      else if(IN[7]==1'b1)  
        EXPMINUS = 8'h13;
      else if(IN[6]==1'b1)  
        EXPMINUS = 8'h14;
      else if(IN[5]==1'b1)  
        EXPMINUS = 8'h15;
      else if(IN[4]==1'b1)  
        EXPMINUS = 8'h16;
      else if(IN[3]==1'b1)  
        EXPMINUS = 8'h17;
      else if(IN[2]==1'b1)  
        EXPMINUS = 8'h18;
      else if(IN[1]==1'b1)  
        EXPMINUS = 8'h19;
      else if(IN[0]==1'b1)  
        EXPMINUS = 8'h1a;
      else  
        EXPMINUS = 8'hff;
    end
    endfunction
	
	function logic[26:0] MAMINUS ( input logic[27:0] IN );
    begin
      if(IN[26]==1'b1)
        MAMINUS = IN[26:0];
      else if(IN[25]==1'b1)
        MAMINUS = {IN[25:0],1'b0};    
      else if(IN[24]==1'b1)
        MAMINUS = {IN[24:0],2'b0};
      else if(IN[23]==1'b1)
        MAMINUS = {IN[23:0],3'b0};
      else if(IN[22]==1'b1)
        MAMINUS = {IN[22:0],4'b0};
      else if(IN[21]==1'b1)
        MAMINUS = {IN[21:0],5'b0};
      else if(IN[20]==1'b1)
        MAMINUS = {IN[20:0],6'b0};
      else if(IN[19]==1'b1)
        MAMINUS = {IN[19:0],7'b0};
      else if(IN[18]==1'b1)
        MAMINUS = {IN[18:0],8'b0};
      else if(IN[17]==1'b1)
        MAMINUS = {IN[17:0],9'b0};
      else if(IN[16]==1'b1)
        MAMINUS = {IN[16:0],10'b0};
      else if(IN[15]==1'b1)
        MAMINUS = {IN[15:0],11'b0};
      else if(IN[14]==1'b1)
        MAMINUS = {IN[14:0],12'b0};
      else if(IN[13]==1'b1)
        MAMINUS = {IN[13:0],13'b0};
      else if(IN[12]==1'b1)
        MAMINUS = {IN[12:0],14'b0};
      else if(IN[11]==1'b1)
        MAMINUS = {IN[11:0],15'b0};
      else if(IN[10]==1'b1)
        MAMINUS = {IN[10:0],16'b0};
      else if(IN[9]==1'b1)
        MAMINUS = {IN[9:0],17'b0};
      else if(IN[8]==1'b1)
        MAMINUS = {IN[8:0],18'b0};
      else if(IN[7]==1'b1)
        MAMINUS = {IN[7:0],19'b0};
      else if(IN[6]==1'b1)
        MAMINUS = {IN[6:0],20'b0};
      else if(IN[5]==1'b1)
        MAMINUS = {IN[5:0],21'b0};
      else if(IN[4]==1'b1)
        MAMINUS = {IN[4:0],22'b0};
      else if(IN[3]==1'b1)
        MAMINUS = {IN[3:0],23'b0};
      else if(IN[2]==1'b1)
        MAMINUS = {IN[2:0],24'b0};
      else if(IN[1]==1'b1)
        MAMINUS = {IN[1:0],25'b0};
      else if(IN[0]==1'b1)
        MAMINUS = {IN[0],26'b0};
      else 
        MAMINUS = 27'b0;
    end
    endfunction  
        
          
	always_comb  /* fadd.c l:66 */
	begin
	  if(pattern1 == 1'b0)
	    expsub = EXPMINUS(maminus1);
	  else
	    expsub = 1'b0;
	end
	
	always_comb  /* fadd.c l:69 */
	begin
	  if(pattern1 == 1'b0)
	    maminus2 = MAMINUS(maminus1);
	  else
	    maminus2 = 1'b0;
	end
	
	always_comb  /* fadd.c l:67 */
	begin
	  if(pattern1==1'b0 && exp1 <= expsub)
	    returncase[2] = 1'b1;
	  else
	    returncase[2] = 1'b0;
	end
	
	
	/* fadd.c l:73 maの選択 */
    always_comb
    begin
      if(pattern2 == 1'b1)
        maselect = maplus2;
      else if(pattern1 == 1'b1)
        maselect = maplus1[26:0];
      else 
        maselect = maminus2;
    end

    assign expsub2 = exp1 - expsub;

    /* fadd.c l:73 expの選択 */
	always_comb 
	begin
      if(pattern2 == 1'b1)
		expselect = expplus[7:0];
	  else if(pattern1 == 1'b1)
		expselect = exp1;
	  else 
		expselect = expsub2[7:0];
	end
	
	/* fadd.c l:74 */
	always_comb
	begin
	  if((maselect[2] == 1'b1) && ((maselect[3:0] & 4'b1011) != 4'b0000))
	    maselect2 = maselect + 4'b1000;
      else
        maselect2 = {1'b0,maselect};
    end
    
    /* fadd.c l:76 */
	always_comb
	begin
	  if(maselect2[26]==1'b1)
	    maselect3 = maselect2[27:1];
	  else
	    maselect3 = maselect2[26:0];
	end
	
	/* fadd.c l:77 */
	always_comb
	begin
	  if(maselect2[26]==1'b1)
	    expselect2 = expselect + 1'b1;
	  else
	    expselect2 = expselect;
	end
	
	assign expselect3 = expselect2[7:0];
	
	always_comb
	begin 
		if(flag == 3'b001)
			returnbits = 32'h7fffffff;
		else if(flag == 3'b010)
			returnbits = 32'h7f800000;
		else if(flag == 3'b011)
			returnbits = 32'hff800000;
		else if(flag == 3'b100)
			returnbits = 32'h00000000;
		else if(flag == 3'b110)
			returnbits = input2;
		else if(flag == 3'b101)
			returnbits = input1;					//ここまでコーナーケース
		else if(returncase[0] == 1'b1)
			returnbits = in1;
		else if(returncase[1] == 1'b1)
			returnbits = 1'b0;
		else if(returncase[2] == 1'b1)
			returnbits = 1'b0;						// 
		else if(expselect3 == 8'hff)
			returnbits = {sign1,31'b1111111100000000000000000000000};
		else if(expselect3 == 8'h00)
			returnbits = {sign1,31'b0000000000000000000000000000000};
		else
			//returnbits = {sign1,8'b11111111,23'b11111111111111111111111};
			returnbits = {sign1,expselect3,maselect3};
	end                            /*expselect3 maselect3*/
				
	assign c = returnbits;

endmodule
