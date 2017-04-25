/*
 * Copyright (c) 1999-2000 Tony Givargis.  Permission to copy is granted
 * provided that this header remains intact.  This software is provided
 * with no warranties.
 *
 * Version : 2.8
 */

/*---------------------------------------------------------------------------*/

#include "cMIPS.h"

//#undef cMIPS

#ifndef cMIPS
  #include <stdio.h>
#endif

/*---------------------------------------------------------------------------*/

void main() {
    
    unsigned int x=121, y=11;

#ifdef cMIPS
  int *IO = (int *)x_IO_BASE_ADDR;
#endif
    
  while( x != y ) {
        
    if( x > y ) {
            
      x -= y;
#ifdef cMIPS
      print(x);
#else
      printf("%08x ",x);
#endif
    } else {
            
      y -= x;
#ifdef cMIPS
      print(y);
#else
      printf("%08x ",y);
#endif

    }
  }
#ifdef cMIPS
  print(x);
#else
  printf("%08x ",x);
#endif

}

// 0000006e 00000063 00000058 0000004d 00000042 00000037 0000002c 00000021 00000016 0000000b 0000000b
