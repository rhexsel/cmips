// Test stdin and stdout of the VHDL simulator -- echo characters read
//   from the simulator's stdin to the simulator's stdout.
//   Test ends when a '%' (percent) is read/typed.
//
//   from_stdin() returns LF (0x0a) if there is nothing on stdin.
// 
// Keep in mind that the terminal itself does echoing -- characters are
//   displayed AFTER a second NewLine because of the terminal also echoes
//   what you just typed in  :(
//
// Also note that the VHDL language only prints full lines of text, that end
//   with a '\n'.  Engineers  :(
//

#include "cMIPS.h"

void main(void) {

  char c;

  // the first char read by the simulator is from an empty line,
  //   hence the model returns a '\n'
  
  do {

    c = (char)from_stdin();

    to_stdout(c);

  } while (c != '%');

  to_stdout('\n');  // so VHDL will flush to stdout the last chars typed

  exit(0);

}
