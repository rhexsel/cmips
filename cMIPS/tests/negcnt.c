/*
 * Copyright (c) 1999-2000 Tony Givargis.  Permission to copy is granted
 * provided that this header remains intact.  This software is provided
 * with no warranties.
 *
 * Version : 2.8
 */

/*---------------------------------------------------------------------------*/
#include "cMIPS.h"

#ifndef cMIPS
  #include <stdio.h>
#endif


/*---------------------------------------------------------------------------*/

int main() {
    
  int i;

   
  for(i=-960; i < -950; i++) {
#ifdef cMIPS
    print(i);
#endif
  }

  return(1);

}
