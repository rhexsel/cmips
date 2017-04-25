	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start
_start: li $31,255	 # do not start with a NOP
	la $15, x_IO_BASE_ADDR
	addi $3,$0,1
	addi $4,$0,5
	li   $20,20
	move $5,$zero
	move $6,$zero
	move $8,$zero

	nop
snd:
        add $4,$4,$3     # $4 + 1
        # sw  $4, 0($15) #  $4 <- 6,7,8,9,a,b,c,d,f,e,10,11,12,13,14
        add $5,$5,$4     # $5 + $4  
	#sw  $5, 0($15)  #  $5 <- 6,d,15,1e,28,33,3f,4c,5a,69,79,8a,9c,af,c3
        add $6,$6,$5     # $6 + $5
        #sw  $6, 0($15)  #  $6 <- 6,13,28,46,6e,a1,e0,12c,186,1ef,268,2f2,38e,
	add  $8,$8,$3    # $8 + 1
	#sw   $8, 0($15) # $8 <- 1,8,10,19,23,2e,3a,47,55,64,74,85,97,aa,be
	add  $8,$8,$4    # $8 + $4
	#sw   $8, 0($15) # $8 <- 7,f,18,22,2d,39,46,54,63,73,84,96,a9,bd,d2
	add  $9,$8,$8    # $9 + 2*$8
	sw   $9, 0($15)  # $9<-e,1e,30,44,5a,72,8c,a8,c6,e6,108,12c,152,17a,1a4
	nop
	slt $30,$4,$20
	bne $30,$0,snd
	nop
	wait
	nop
	.end _start

#awk echo | awk -f fwd.awk
#awk END{
#awk     r3=1; r4=5; r5=0; r6=0; r8=0; r9=0;
#awk     for (i=0; r4<20; i++) {
#awk 	r4=r4+r3;
#awk 	r5=r5+r4;
#awk 	r6=r6+r5;
#awk 	r8=r8+r3;
#awk 	r8=r8+r4;
#awk 	r9=r8+r8;
#awk 	printf("%x,", r9);
#awk     }
#awk }
