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

void mergeSort(int numbers[], int temp[], int array_size);
void m_sort(int numbers[], int temp[], int left, int right);
void merge(int numbers[], int temp[], int left, int mid, int right);

// cMIPS file I/O
int  readInt(int *n);
void writeInt(int n);
void writeClose(void);
void print(int n);


int temp[NUM_ITEMS];
int buf[NUM_ITEMS];

void main() {
  int val,i,j;

  i=0;
  while ( readInt(&val) == 0 ) { // read input data from file input.data
    buf[i] = val;
    i = i+1;
  }

  //perform merge sort on array
  mergeSort(buf, temp, i);

  //write sorted numbers
  for (j=0; j<i; j++) {
    writeInt(buf[j]);
    print(buf[j]);
  }

  writeClose();
}


void mergeSort(int numbers[], int temp[], int array_size) {
  m_sort(numbers, temp, 0, array_size - 1);
}

void m_sort(int numbers[], int temp[], int left, int right) {
  int mid;

  if (right > left) {
    mid = (right + left) >> 1;
    m_sort(numbers, temp, left, mid);
    m_sort(numbers, temp, mid+1, right);

    merge(numbers, temp, left, mid+1, right);
  }
}

void merge(int numbers[], int temp[], int left, int mid, int right) {
  int i, left_end, num_elements, tmp_pos;

  left_end = mid - 1;
  tmp_pos = left;
  num_elements = right - left + 1;

  while ((left <= left_end) && (mid <= right)) {
    if (numbers[left] <= numbers[mid]) {
      temp[tmp_pos] = numbers[left];
      tmp_pos = tmp_pos + 1;
      left = left +1;
    } else {
      temp[tmp_pos] = numbers[mid];
      tmp_pos = tmp_pos + 1;
      mid = mid + 1;
    }
  }

  while (left <= left_end) {
    temp[tmp_pos] = numbers[left];
    left = left + 1;
    tmp_pos = tmp_pos + 1;
  }
  while (mid <= right) {
    temp[tmp_pos] = numbers[mid];
    mid = mid + 1;
    tmp_pos = tmp_pos + 1;
  }

  for (i=0; i <= num_elements; i++) {
    numbers[right] = temp[right];
    right = right - 1;
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
