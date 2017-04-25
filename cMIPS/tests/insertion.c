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
 * This program demonstrates the use of the insertion sort algorithm.  For
 * more information about this and other sorting algorithms, see
 * http://linux.wku.edu/~lamonml/kb.html
 *
 */

#ifdef cMIPS
  #include "cMIPS.h"
#else
  #include <stdio.h>
#endif

// #include "sortData.h"

#define NUM_ITEMS 20
// #define NUM_ITEMS 1000

void insertionSort(int numbers[], int array_size);
void myprint(int numbers[], int n);

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

  //perform insertion sort on array
  insertionSort(buf, NUM_ITEMS);
  myprint(buf, NUM_ITEMS);

}

void insertionSort(int numbers[], int array_size)
{
  int i, j, index;

  for (i=1; i < array_size; i++) {
    index = numbers[i];
    j = i;
    while ((j > 0) && (numbers[j-1] > index)) {
      numbers[j] = numbers[j-1];
      j = j - 1;
    }
    numbers[j] = index;
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
