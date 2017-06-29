//-------------------------------------------------------------------------
// test if COUNT register counts up monotonically
// returns error if the time to compute every 11th element of the Fibonacci
//    sequence, as measured by COUNT, is not monotonically increasing
//-------------------------------------------------------------------------

#include "cMIPS.h"

//---------------------------------------------------------------------
int fibonacci(int n) {
  int i;
  int f1 = 0;
  int f2 = 1;
  int fi = 0;;
  
  if (n == 0)
    return 0;
  if(n == 1)
    return 1;
  
  for(i = 2 ; i <= n ; i++ ) {
    fi = f1 + f2;
    f1 = f2;
    f2 = fi;
  }
  return fi;
}

//=====================================================================
int main() {
  int i, new, old, monotonic;

  print( startCount() );         // start COUNT
  monotonic = TRUE;

  for (i=0; i < 44; i += 11) {
    old = readCount();           // COUNT before computing fib(i)
    print( fibonacci(i) );
    new = readCount();           // COUNT after  computing fib(i)
    monotonic = monotonic && ( (new - old) > 0 );
    if ( monotonic == FALSE ) {
      to_stdout('e'); to_stdout('r'); to_stdout('r'); to_stdout('\n');
      print(new);
      exit(new);
    }
    // print(new);
  }
  // print(new);
  to_stdout('o'); to_stdout('k'); to_stdout('\n');

  to_stdout('\n');  // separate tests

  // now disable COUNT and make sure that it has stopped
  print( stopCount() );          // stop COUNT
  old = readCount();             // COUNT before computing fib(i)
  print( fibonacci(5) );
  new = readCount();             // COUNT after  computing fib(i)
  monotonic = monotonic && ( (new - old) > 0 );
  if ( monotonic == TRUE ) {
    to_stdout('e'); to_stdout('r'); to_stdout('r'); to_stdout('\n');
    print(new);
  } else {
    // print(new);
    to_stdout('o'); to_stdout('k'); to_stdout('\n');
  }
  exit(new);
}
//=====================================================================
