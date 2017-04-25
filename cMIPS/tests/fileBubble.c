/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * This program demonstrates the use of the merge sort algorithm.  For
 * more information about this and other sorting algorithms, see
 * http://linux.wku.edu/~lamonml/kb.html
 *
 */

#include "cMIPS.h"



#define NUM_ITEMS 128

void sort(int buf[], int n);

// cMIPS file I/O
int  readInt(int *n);
void writeInt(int n);
void writeClose(void);
void print(int n);

int buf[NUM_ITEMS];

void main() {
  int val,i,j;

  i=0;
  while ( readInt(&val) == 0 ) { // read input data from file input.data
    buf[i] = val;
    i = i+1;
  }

  //perform bubble sort on array
  sort(buf, i);

  //write sorted numbers
  for (j=0; j<i; j++) {
    writeInt(buf[j]);
    print(buf[j]);
  }

  writeClose();
}


void sort(int buf[], int n) {
  int i, j, t;
  
  for(i=0; i < n; i++) {
    for(j=i; j < n; j++) {
      if( buf[i] > buf[j] ) {
        t = buf[i];
        buf[i] = buf[j];
        buf[j] = t;
      }
    }
  }
}



int readInt(int *n) { // read integer from file, status==1 if EOF, 0 otw
  int *IO = (int *)IO_READ_BOT_ADDR;
  int status, value;

  value  = *IO;
  status = *(IO + 1);

  if (status == 0) {
    *n = value;
  }
  return status;
}


void writeInt(int n) { // write integer to output file
  int *IO = (int *)IO_WRITE_BOT_ADDR;

  *IO = n;
}

void writeClose(void) { // close output file
  int *IO = (int *)IO_READ_BOT_ADDR;

  *(IO + 1) = 1;
}

void print(int n) { // write to VHDL simulator's standard output
  int *IO = (int *)x_IO_BASE_ADDR;

  *IO = n;
}
