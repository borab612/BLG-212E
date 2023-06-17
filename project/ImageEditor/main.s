Stack_Size       EQU     0x400;
	
				 AREA    STACK, NOINIT, READWRITE, ALIGN=3
Stack_Mem        SPACE   Stack_Size
__initial_sp

				 AREA    RESET, DATA, READONLY
                 EXPORT  __Vectors
                 EXPORT  __Vectors_End

__Vectors        DCD     __initial_sp               ; Top of Stack
                 DCD     Reset_Handler              ; Reset Handler
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	Button_Handler					 
__Vectors_End    

				 AREA    |.text|, CODE, READONLY
Reset_Handler    PROC
                 EXPORT  Reset_Handler
				 ldr	 r0, =0xE000E100
				 movs	 r1,#1	
				 str	 r1,[r0]						 
			     CPSIE	 i					 
                 LDR     R0, =__main
                 BX      R0
                 ENDP				 
			
			     AREA    button, CODE, READONLY
Button_Handler   PROC
                 EXPORT  Button_Handler	
			     push    {lr}
				 ldr     r0, =0x40010010
				 ldr     r1, [r0]
				 movs    r2, #0x00000030 
				 ands    r1, r1, r2       ;isolate the up/down button bits
               	 ldr     r0, =0x20000000
				 ldr     r3, [r0]         ;get the option select value
				 cmp     r1, #32
                 bne 	 dontIncrease
                 cmp     r3, #5
                 beq     dontIncrease
                 adds    r3, r3, #1   	  ;increase option select when down is hit and option select < 5
                 str     r3, [r0]
				 bl      menuCursor 	  ;draw the menu cursor according to new option select value			 
dontIncrease     cmp     r1, #16
                 bne 	 dontDecrease
                 cmp     r3, #1
                 beq     dontDecrease
                 subs    r3, r3, #1		  ;decrease option select when up is hit and option select > 1
                 str     r3, [r0]
				 bl      menuCursor 	  ;draw the menu cursor according to new option select value	 
dontDecrease	 cmp     r3, #1           ;check if option select is 1
                 bne     skipOpt1         ;if not, function of option 1 won't be executed
                 ldr     r0, =0x40010010
                 ldr     r1, [r0]
				 movs    r2, #0x0000000C
				 ands    r1, r1, r2       ;isolate the A/B button bits
                 cmp     r1, #4           ;if A is pressed, reflect horizontally and draw the new image
				 bne     dontRefHorz
                 bl      reflectHorz
				 ldr     r0, =110         
                 ldr     r5, =0x20000004     
				 ldr     r2, =0x20000640  	
				 ldr     r3, [r5]		  ;get the row and column no. of current image     
				 ldr     r4, [r5, #0x4]
				 ldr     r1, =320
				 subs    r1, r1, r4
				 lsrs    r1, r1, #1       ;we want to draw the image horizontally in the middle
				 bl      drawImg 
dontRefHorz		 cmp     r1, #8           ;if B is pressed, reflect vertically and draw the new image
                 bne     skipOpt1
				 bl      reflectVert
				 ldr     r0, =110         
                 ldr     r5, =0x20000004     
				 ldr     r2, =0x20000640  	
				 ldr     r3, [r5]		  ;get the row and column no. of current image     
				 ldr     r4, [r5, #0x4]
				 ldr     r1, =320
				 subs    r1, r1, r4
				 lsrs    r1, r1, #1       ;we want to draw the image horizontally in the middle
				 bl      drawImg 				     
skipOpt1         ldr     r2, =0x80000000
				 ldr     r0, =0x40010010
				 str     r2, [r0]     
				 pop     {pc}
				 ENDP
				 
                 AREA    main, CODE, READONLY
                 EXPORT	 __main			  ;make __main visible to linker
				 IMPORT  image
			     IMPORT  options
				 IMPORT  nums
                 ENTRY
reflectVert      PROC
                 ;Rearranges the color values in memory such that when drawImg is called
                 ;with the vertically reflected current image's row and column values,
                 ;it draws the vertically reflected current image on screen.
				 movs    r3, #0           ;initialize reflected column count
				 ldr     r0, =0x20000640  ;first index
				 ldr     r1 , =0x20000004  
				 ldr     r2, [r1]         ;get row no. of current image
				 subs    r2, r2, #1
				 ldr     r4, [r1, #0x4]   ;get column no. of current image
				 movs    r1, #4
				 muls    r2, r1, r2
				 muls    r2, r4, r2
				 adds    r1, r0, r2       ;second index = first index + 4*column no*(row no. - 1)   
reflectCol		 ldr     r2, [r1]         ;color value of second index
             	 movs    r5, r2    
				 ldr     r2, [r0]         ;color value of first index
                 str     r5, [r0]         ;store color value of second index to location of first index				 
				 str     r2, [r1]         ;store color value of first index to location of second index
				 movs    r5, #4
				 muls    r5, r4, r5
				 adds    r0, r0, r5       ;increment the first index by column no*4
				 subs    r1, r1, r5       ;decrement the second index by column no*4
				 cmp     r1, r0           ;check if the whole column has been reflected or not (i.e. if r1<=r0)
				 bgt     reflectCol
				 adds    r3, r3, #1       ;if column is reflected, increase reflected column count
				 cmp     r4, r3           ;check if all columns have been reflected, if they have, end the loop
				 bne     nextCol     
				 bx      lr
nextCol          ldr     r0, =0x20000640  
				 movs    r1, #4
				 muls    r1, r3, r1
				 adds    r0, r0, r1       ;new initial first index = previous initial first index + 4
				 ldr     r1 , =0x20000004  
				 ldr     r2, [r1]         ;get row no. again
				 subs    r2, r2, #1
				 movs    r1, #4
				 muls    r2, r1, r2
				 muls    r2, r4, r2
				 adds    r1, r0, r2       ;new initial second index = previous initial second index + 4
				 b       reflectCol
				 ENDP					 
reflectHorz      PROC
                 ;Rearranges the color values in memory such that when drawImg is called
                 ;with the horizontally reflected current image's row and column values,
                 ;it draws the horizontally reflected current image on screen.
				 movs    r3, #0           ;initialize reflected row count
				 ldr     r0, =0x20000640  ;first index
				 ldr     r1 , =0x20000008  
				 ldr     r2, [r1]         ;get column no. of current image
				 movs    r1, #4
				 muls    r2, r1, r2
				 adds    r1, r0, r2       
				 subs    r1, r1, #4       ;second index = first index + 4*column no - 4.
reflectRow		 ldr     r2, [r1]         ;color value of second index
             	 movs    r4, r2    
				 ldr     r2, [r0]         ;color value of first index
                 str     r4, [r0]         ;store color value of second index to location of first index				 
				 str     r2, [r1]         ;store color value of first index to location of second index
				 adds    r0, r0, #4       ;increment the first index by 4
				 subs    r1, r1, #4       ;decrement the second index by 4
				 cmp     r1, r0           ;check if the whole row has been reflected or not (i.e. if r1<=r0)
				 bgt     reflectRow
				 adds    r3, r3, #1       ;if row is reflected, increase reflected row count
				 ldr     r1 , =0x20000004 
				 ldr     r2, [r1]         ;get row no. of current image
				 cmp     r2, r3           ;check if all rows have been reflected, if they have, end the loop
				 bne     nextRow     
				 bx      lr
nextRow          ldr     r0, =0x20000640
                 ldr     r2, [r1, #0x4]   ;get column no. again 
                 movs    r1, #4
				 muls    r2, r1, r2
				 adds    r1, r0, r2       
				 subs    r1, r1, #4
				 muls    r2, r3, r2           
                 adds    r0, r0, r2       ;new initial first index = previous initial first index + 4*row count*column no.
				 adds    r1, r1, r2       ;new initial second index = previous initial second index + 4*row count*column no.
				 b       reflectRow
				 ENDP
menuCursor		 PROC
				 ;Draws the menu cursor based on option select.
				 ldr     r0, =0x40010000 
				 ldr     r1, =25          ;start painting black from row 25
				 ldr     r2, =177         ;start painting black from column 177
				 str     r1, [r0]         
				 str     r2, [r0, #0x4]   
paintBlack		 ldr     r3, =0xff000000  ;paint black to remove previous cursor
		         str     r3, [r0, #0x8]
				 adds    r2, r2, #1
				 cmp     r2, #182         ;paint black until column 182
				 bne     nc2
				 ldr     r2, =170         ;reset the column index
				 adds    r1, r1, #1
				 cmp     r1, #100         ;paint black until row 100
				 bne     nr2
				 b       paintCursor
nr2              str     r1, [r0]		  
nc2              str     r2, [r0, #0x4]   		
                 b       paintBlack
paintCursor      ldr     r1, =0x20000000
                 ldr     r4, [r1]         ;get the option select value
                 movs    r1, #20           
                 movs    r2, #177         ;start painting green from column 177
				 movs    r3, #12 
				 muls    r3, r4, r3       ;start painting green from row 12*r4 + 20
				 adds    r1, r1, r3
				 movs    r3, #5           ;cursor length and width are 5
				 adds    r3, r1, r3       
   				 push    {r3}             ;save the final row index to paint to (initial index + 5)
				 str     r1, [r0]         
				 str     r2, [r0, #0x4]   
paintGreen		 ldr     r3, =0xff00ff00
		         str     r3, [r0, #0x8]
				 ldr     r3, =182         ;paint green until column 182
				 adds    r2, r2, #1
				 cmp     r2, r3            
				 bne     nc3
				 ldr     r2,=177          ;reset column index to 177           
				 adds    r1, r1, #1
				 pop     {r3}
				 cmp     r1, r3           ;paint green until final row index
				 push    {r3}
				 bne     nr3
				 pop     {r3}
				 movs    r3, #1
				 str     r3, [r0, #0xC]   ;refresh the screen
				 bx      lr
nr3              str     r1, [r0]		  
nc3              str     r2, [r0, #0x4]
                 b       paintGreen
				 ENDP
drawImg		     PROC		                                                  
				 ;Draws the image onto the LCD screen. Arguments are: r0,r1,r2,r3,r4 => 
				 ;initial row index,initial column index,address of first rgba value, 
				 ;row no. of image, column no. of image respectively. All register values
				 ;except for r2 are preserved after operation.
				 push    {r0}	
	             push    {r1}     
				 adds    r3, r3, r0       ;r3 holds the maximum row index
				 adds    r4, r4, r1       ;r4 holds the maximum column index	             
	             ldr	 r5, [r2]		  ;r5 has the first bgra value
				 rev     r5, r5  		  ;revert and shift to get rgba from bgra 
				 movs    r6, #0x8
				 rors    r5, r5, r6
				 ldr     r6, =0x40010000
				 str     r0, [r6]         ;update row register with first row count
				 str     r1, [r6, #0x4]   ;update column register with first column count
				 
paint            ldr     r6, =0x40010000
               	 str     r5, [r6, #0x8]   ;write the color to screen at current row and column using color register
				 adds    r2, r2, #0x4     ;get the address for the next color value	
				 ldr	 r5, [r2]
				 rev     r5, r5			  ;revert and shift to get rgba from bgra
				 movs    r6, #0x8
				 rors    r5, r5, r6
				 adds    r1, r1, #1       ;increment the column counter						 
				 cmp     r1, r4           ;check if we have reached the end of current row
				 bne     nc				 
				 pop     {r6}
				 movs    r1, r6           ;reset the column counter (move to the beginning of the row)
				 push    {r6}
                 adds    r0, r0, #1       ;increment the row counter 
				 cmp     r0, r3           ;check if we have reached the end of the screen
                 bne     nr              
                 movs    r1, #1
				 ldr     r6, =0x40010000
				 str     r1, [r6, #0xC]   ;refresh the screen
                 pop     {r1}
				 pop     {r0}
				 subs    r3, r3, r0
				 subs    r4, r4, r1
				 bx      lr				 
nr               ldr     r6, =0x40010000
                 str     r0, [r6]		  ;update the row register
nc               ldr     r6, =0x40010000
                 str     r1, [r6, #0x4]   ;update the column register		
                 b       paint
				 ENDP  

__main           PROC
	             movs    r0, #0
				 ldr     r1, =4800
				 ldr     r2, =image
				 ldr     r3, =0x20000640
loop     		 ldr     r4, [r2]         ;store the image in RAM, starting from address 0x20000640
				 str     r4, [r3]
				 adds    r0, r0, #1
				 adds    r2, r2, #4
                 adds    r3, r3, #4
				 cmp     r0, r1
           		 bne     loop
                 ldr     r0, =110         ;initial row index for the image to be drawn (always 110)
                 ldr     r1, =120         ;initial column index for the image to be drawn (always chosen so that image is in the middle)			 
				 ldr     r2, =0x20000640  ;r2 has the image's color values' initial address	(always 0x20000640)	
				 ldr     r3, =60          ;row no. of the current image (always kept in 0x20000004)
				 ldr     r5, =0x20000004
				 str     r3, [r5]
				 ldr     r4, =80          ;column no. of the current image (always kept in 0x20000008)			 
				 str     r4, [r5, #0x4]
				 BL      drawImg          ;draw the original image
				 ldr     r0, =5           
                 ldr     r1, =120         
				 ldr     r2, =options     		
				 ldr     r3, =20         
				 ldr     r4, =80          			 
                 BL      drawImg          ;draw the options sign
				 ldr     r0, =30          
                 ldr     r1, =185         
				 ldr     r2, =nums        		
				 ldr     r3, =60         
				 ldr     r4, =15          				 
                 BL      drawImg          ;draw the option numbers 
				 movs    r0, #1           ;menu option select is initially 1 (option select value is always kept in 0x20000000)
                 ldr     r1, =0x20000000
				 str     r0, [r1]
				 BL      menuCursor		  ;draw the menu cursor  		 
				 
				 
				 
;loop2           ldr     r1, =10000000
;wait		     subs    r1, r1, #1
;                cmp     r1, #1
;			     bge     wait
;			     b       loop2
wait             b       wait
				 ENDP
                 END