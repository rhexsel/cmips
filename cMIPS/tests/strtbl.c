
#include "cMIPS.h"

void MSYS_Free( void * );
void *MSYS_Alloc( unsigned );
void MSYS_Init( void *, unsigned );

extern int *myheap;

#ifndef MALLOC_BASE_ADDRESS
  #define MALLOC_BASE_ADDRESS (x_DATA_BASE_ADDR + 0x00002000)
  #define MALLOC_SIZE         0x00001000
#endif

#ifndef TRUE
  #define TRUE  (0 == 0)
  #define FALSE (0 == 1)
#endif

#define NULL 0

#define free(p)    MSYS_Free(p)
#define malloc(s)  MSYS_Alloc(s)

int random(void);

int strcpy(const char *, char *);
int strcat(char *, const char *);
int strlen(const char *);

int insert(char *);     // returns index at vector of addresses
char *show(int);        // print string at index, or ERROR
void printall(void);    // prints all strings in the stringTable
void printstr(char *);  // print string
int  remove(int);       // delete string at index, return TRUE if was present


char *err="ERROR\n";

#define STR_SZ 16

#define TBL_SZ 10

int *myheap;

char s[STR_SZ+1];

void main(void) {

  int i,j,k;
  char c;

  myheap = (int *)MALLOC_BASE_ADDRESS;

  MSYS_Init( (void *)MALLOC_BASE_ADDRESS, (unsigned)MALLOC_SIZE );

  // insert TBL_SZ random strings
  for (i=0; i < TBL_SZ; i++) {
    j = (random() >>8) & 0xf; // % STR_SZ;
    print(j);
    for (k=0; k < j; k++) {
      c = ('a' + i + k) & 0x7f; // % 127
      to_stdout(c);
      s[k] = c;
    }
    to_stdout('\n');
    print(k);
    s[k] = '\0';
    printstr(s);
    // insert(s);
  }

  printall(); // show full table

  // now remove 3 randomly chosen strings
  for (k=0; k < 3; k++) {
    j = random() % TBL_SZ;
    if ( remove(j) == FALSE )
      printstr(err);
  }

  printall(); // show table minus items removed

  exit(0);

}

static index = 0;
static char *strVector[TBL_SZ];

// returns index at vector of addresses
int insert(char *s) {
  int size;
  char *where;

  size = strlen(s);

  where = (char *)malloc(size);

  strcpy(s, where);

  if (index < TBL_SZ) {
    strVector[index] = where;
    index += 1;
    return(index - 1);
  } else {
    printstr(err);
    return(-1);
  }
}


// remove string from vector
int remove(int i) {
  int size;
  char *where;

  if ( strVector[i] != 0) {
    where = strVector[i];
    free(where);
    strVector[i] = (char *)0;
    return(TRUE);
  } else {
    printstr(err);
    return(FALSE);
  }
}



// return pointer to string, if it exists, else NULL
char *show(int i) {

  if ( strVector[i] != (char *)0) {
    return(strVector[i]);
  } else {
    return(NULL);
  }
}


// write string to simulator's stdout
void printstr(char *s) {
  char c;

  while( (c = *s) != '\0' )
    to_stdout(c);
  to_stdout('\n'); // end of string to GHDL simulator
}


void printall(void) {
  int i;
  char *s;

  for (i=0; i < TBL_SZ; i++)
    if ( (s = show(i)) != NULL )
      printstr(s);
}


/***************************************************************
 * rand() [after Kelley & Pohl pp 81]
 ***************************************************************/

#define ABS(x) ( ((x) < 0) ? -(x) : (x) )

static int m_w = 177;    /* must not be zero, nor 0x464fffff */
static int m_z = 311;    /* must not be zero, nor 0x9068ffff */

int random(void) {
  m_z = 36969 * (m_z & 65535) + (m_z >> 16);
  m_w = 18000 * (m_w & 65535) + (m_w >> 16);
  return ((m_z << 16) + m_w);  /* 32-bit result */
}




int strcpy(const char *y, char *x)
{
  int i=0;
  while ( (*x++ = *y++) != '\0' ) // copia e testa final
    i = i+1;
  *x = '\0';
  return(i+1);
}


int strcat(char *si, const char *sf)
{
  char *p = si;
  int n=0;
  while (*p != '\0') {
    ++p;
    n++;
  }
  while ( (*p++ = *sf++) )
    n++;
  return(n+1);
}


int strlen(const char *s)
{
  int n=0;

  do {
    ++n;
  } while (*s++ != '\0');
    
  return(n);
}




#define USED       1

/* http://www.flipcode.com/archives/Simple_Malloc_Free_Functions.shtml */


typedef struct {
  unsigned size;
} UNIT;

typedef struct {
  UNIT* free;
  UNIT* heap;
} MSYS;

static MSYS msys;

static UNIT* compact( UNIT *p, unsigned nsize ) {
  unsigned bsize, psize;
  UNIT *best;
  
  best = p;
  bsize = 0;
  
  while( psize = p->size, psize ) {
    if( psize & USED ) {
      if( bsize != 0 ) {
	best->size = bsize;
	if( bsize >= nsize ) {
	  return best;
	}
      }
      bsize = 0;
      best = p = (UNIT *)( (unsigned)p + (psize & ~USED) );
    } else {
      bsize += psize;
      p = (UNIT *)( (unsigned)p + psize );
    }
  }
  
  if( bsize != 0 ) {
    best->size = bsize;
    if( bsize >= nsize ) {
      return best;
    }
  }
  
  return 0;
}

void MSYS_Free( void *ptr ) { 
  if( ptr ) {
    UNIT *p;
    
    p = (UNIT *)( (unsigned)ptr - sizeof(UNIT) );
    p->size &= ~USED;
  }
}

void *MSYS_Alloc( unsigned size ) {
  unsigned fsize;
  UNIT *p;
  
  if( size == 0 ) return 0;
  
  size  += 3 + sizeof(UNIT);
  size >>= 2;
  size <<= 2;
  
  if( msys.free == 0 || size > msys.free->size ) {
    msys.free = compact( msys.heap, size );
    if( msys.free == 0 ) return 0;
  }

  p = msys.free;
  fsize = msys.free->size;
  
  if( fsize >= size + sizeof(UNIT) ) {
    msys.free = (UNIT *)( (unsigned)p + size );
    msys.free->size = fsize - size;
  } else {
    msys.free = 0;
    size = fsize;
  }

  p->size = size | USED;
  
  return (void *)( (unsigned)p + sizeof(UNIT) );
}

void MSYS_Init( void *heap, unsigned len ) {
  len  += 3;
  len >>= 2;
  len <<= 2;
  msys.free = msys.heap = (UNIT *) heap;
  msys.free->size = msys.heap->size = len - sizeof(UNIT);
  *(unsigned *)((char *)heap + len - 4) = 0;
}

void MSYS_Compact( void ) {
  msys.free = compact( msys.heap, 0x7fffffff );
}

