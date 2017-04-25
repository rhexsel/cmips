	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: la    $15, x_DATA_BASE_ADDR
	la    $16, x_IO_BASE_ADDR
	la    $3,  32774
	la    $20, 32760
	la    $9,  5
	ori   $5,$0,4
	nop
snd:	sh   $3, 0($15)
	sh   $9, 2($15)
	addi $3,$3,-1
	addi $9,$3,+16
	#lhu   $4, 0($15)
	#lhu   $6, 2($15)
	lh   $4, 0($15)	
	lh   $6, 2($15)	
	addi $15,$15,2
	sw   $4, 4($16)
	sw   $6, 0($16)
	bne  $3,$20,snd
	nop
	nop
	nop
	wait
	nop
	.end _start

# ffff8006 00000005 ffff8005 ffff8015 ffff8004 ffff8014 ffff8003 ffff8013 ffff8002 ffff8012 ffff8001 ffff8011 ffff8000 ffff8010 00007fff ffff800f 00007ffe ffff800e 00007ffd ffff800d 00007ffc ffff800c 00007ffb ffff800b 00007ffa ffff800a 00007ff9 ffff8009
	