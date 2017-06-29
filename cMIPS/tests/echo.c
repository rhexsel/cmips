// Test stdin and stdout -- echo characters read from stdin to stdout
//   test ends when '%' (percent) is read/typed.
//   from_stdin() returns LF (0x0a) the there is nothing on stdin
// 
// Keep in mind that the terminal itself does echoing -- characters are
//  displayed AFTER a second NewLine because of the terminal also echoes
//  what you just typed in  :(

#include "cMIPS.h"

void main(void) {

  char c;

  // the first read by the simulator is from an ampty line,
  //   thus the model returns a '\n'
  
  do {

    c = (char)from_stdin();

    to_stdout(c);

  } while (c != '%');

  to_stdout('\n');

  exit(0);

}
