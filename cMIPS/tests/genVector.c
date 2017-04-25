#include <stdio.h>
#include <stdlib.h>

extern char *optarg;

int main(int argc, char *argv[]) {
  int i;
  int number = 4;
  int seed = 7;

  int n;

  while((i = getopt(argc,argv,"hn:s:")) != EOF) {
    switch(i) {
    case 'n':
      number = atoi(optarg);
      break;
    case 's':
      seed = atoi(optarg);
      break;
    case 'h':
      fprintf(stderr, "usage: %s -n howMany -s seed\n", argv[0]);
      exit(1);
    default:
      fprintf(stderr, "usage: %s -n howMany -s seed\n", argv[0]);
      exit(1);
    }
  }

  srandom(seed);
  for (i=0; i<number; i++) {
    n = (random() | (i%2)<<31) & 0xffffffff; // 32 bits
    //n = random() & 0xffffffff;  // 31 bits
    fwrite(&n, sizeof(int), 1, stdout);
  }
  return(0);
}
