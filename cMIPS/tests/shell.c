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
 * This program demonstrates the use of the shell sort algorithm.  For
 * more information about this and other sorting algorithms, see
 * http://linux.wku.edu/~lamonml/kb.html
 *
 */

#ifdef cMIPS
  #include "cMIPS.h"
#else
  #include <stdio.h>
#endif

#define NUM_ITEMS 50
//#define NUM_ITEMS 1000

void shellSort(int numbers[], int array_size);
void myprint(int buf[], int n);

// #include "sortData.h"

void main() {

#ifdef cMIPS
  int *buf = (int *)x_DATA_BASE_ADDR;
#else
  int buf[NUM_ITEMS];
#endif

  int *ptr = buf;
  unsigned int i, m_w, m_z;

  // from wikipedia
  m_w = 17;    /* must not be zero, nor 0x464fffff */
  m_z = 31;    /* must not be zero, nor 0x9068ffff */

  for (i=0; i < NUM_ITEMS; i++, ptr++) {
    m_z = 36969 * (m_z & 65535) + (m_z >> 16);
    m_w = 18000 * (m_w & 65535) + (m_w >> 16);
    *ptr = (m_z << 16) + m_w;  /* 32-bit result */
  }

  //perform shell sort on array
  shellSort(buf, NUM_ITEMS);

  myprint(buf, NUM_ITEMS);

}

void shellSort(int numbers[], int array_size) {
  int i, j, increment, temp;

  increment = 3;
  while (increment > 0) {
    for (i=0; i < array_size; i++) {
      j = i;
      temp = numbers[i];
      while ((j >= increment) && (numbers[j-increment] > temp)) {
        numbers[j] = numbers[j - increment];
        j = j - increment;
      }
      numbers[j] = temp;
    }
    if ((increment >> 1) != 0)
      increment = increment >> 1;
    else if (increment == 1)
      increment = 0;
    else
      increment = 1;
  }
}


void myprint(int buf[], int n) {
    int i;

  for(i=0; i < n; i++) {

#ifdef cMIPS
    print( buf[i] );
#else
    printf("%08x\n",buf[i]);
#endif

    }
}
