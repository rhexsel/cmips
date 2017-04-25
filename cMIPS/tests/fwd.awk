END{
    r3=1; r4=5; r5=0; r6=0; r8=0; r9=0;
    for (i=0; r4<20; i++) {
	r4=r4+r3;
	r5=r5+r4;
	r6=r6+r5;
	r8=r8+r3;
	r8=r8+r4;
	r9=r8+r8;
	printf("%x,", r9);
    }
}
