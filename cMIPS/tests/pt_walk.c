//
// This program references a wide range of addresses to do a walk over
//   several entries of the Page Table (PT).
// As the pages are referenced, the TLB must be refilled with entries from
//   the PT.
//
// This program needs a large (simulated) RAM.  RAM must be allocated
//   so that the bottom half is "usable memory" and the top half is
//   allocated to the Page Table.  The base address and RAM size must
//   be set on file  vhdl/packageMemory.vhd.
//
//   x_DATA_BASE_ADDR : reg32   := x"00040000";
//   x_DATA_MEM_SZ    : reg32   := x"00020000";
//
// With this much memory, simulations run slowly.  No free lunch.


//-----------------------------------------------------------------------
// decide on the tests to run
#define WALK_THE_PT  1
#define TLB_MODIFIED 0
#define DOUBLE_FAULT 0

// these will abort the simulation when the fault is detected/handled
#define PROT_VIOL 0
#define SEG_FAULT 0
#define MEM_SEC   0
//-----------------------------------------------------------------------


#include "cMIPS.h"

extern void PT_update(void *V_addr, int component, int new_value);
extern  int TLB_purge(void *V_addr);
static void print_str(char *);

#define MAX_RAM ( x_DATA_BASE_ADDR + (x_DATA_MEM_SZ / 2) )

#define NUM_RAM_PAGES  ( (x_DATA_MEM_SZ / 2) / 4096 )




int main(void) {
  int i, rsp, new_value;
  volatile int *walker;


#if WALK_THE_PT
  //-----------------------------------------------------------------
  // write to the middle of all datapages
  //   this will cause some TLB refill exceptions, which should be
  //   handled smoothly by the handler at excp_0000 (include/start/s)
  //-----------------------------------------------------------------
  walker = (int *)(x_DATA_BASE_ADDR + 1024);

  for (i = 0 ; i < NUM_RAM_PAGES; i++) {
    *walker = i;
    walker = (int *)((int)walker + 4096);
  }

  // and now read what was written
  walker = (int *)(x_DATA_BASE_ADDR + 1024);

  for (i = 0 ; i < NUM_RAM_PAGES; i++) {
    print( *walker );
    walker = (int *)((int)walker + 4096);
  }

  print_str("\n\twalked\n");
#endif



#define PG_NUM 10



#if TLB_MODIFIED
  //-------------------------------------------------------------------
  // let's change a mapping to cause a TLB-Modified exception
  //
  // in fact, there will be TWO exceptions: 
  // (1) a TLB-Refill will copy the mapping from the PT and retry the
  //     instruction;
  // (2) when the sw is retried, it will cause a TLB-Modified
  //     exception, which checks PT's protection bits, then fixes the
  //     dirty bit in the TLB, and retries again, succeeding this time.
  //-------------------------------------------------------------------
  // ( ( (x_DATA_BASE_ADDR + n*4096) >>12 )<<6 ) || 0b000111  d,v,g

  walker = (int *)(x_DATA_BASE_ADDR + PG_NUM*4096);

  // first, remove V_addr from the TLB, to ensure the PT is searched
  if ( TLB_purge((void *)walker) == 0 ) {
    print_str("\n\tTLB entry purged\n\n");
  } else {
    print_str("\n\tTLB miss\n\n");
  }

  new_value = ( ((x_DATA_BASE_ADDR + PG_NUM*4096)>>12) <<6) | 0b000011; // d=0
  PT_update( (int *)walker, 0, new_value);

  new_value = 0x00000009;                    // writable, mapped
  PT_update( (int *)walker, 1, new_value);

  *walker = 0x99;              // cause a TLBrefill, then a TLBmod

  if ( *walker == 0x99 ) {
    print( *walker );
    print_str("\n\tMod ok\n");
  } else {
    print_str("\n\tMod err\n");
 }
#endif




#if DOUBLE_FAULT
  //--------------------------------------------------------------------
  // let's remove from the TLB the mapping for the PT itself and cause
  // a double-fault:
  //
  // (1) on the 1st reference, TLB-refill does not find a mapping for
  //     the PT on the TLB; this causes a TLBL (load) exception;
  // (2) routine handle_TLBL writes a new mapping on the PT, refills
  //     the TLB, then retries the reference;
  // (3) the page referenced is not on the TLB, so there is another
  //     TLB-refill, which loads the mapping, the store is retried
  //     and succeeds.
  //--------------------------------------------------------------------

  // remove the TLB entry for datum to be referenced
  walker = (int *)(x_DATA_BASE_ADDR + PG_NUM*4096 + 1024);
  if ( TLB_purge((void *)walker) == 0 ) {
    print_str("\taddr purged from TLB\n");
  } else {
    print_str("\tTLB miss\n");
  }

  // this is the base of the page table
  walker = (int *)(x_DATA_BASE_ADDR + (x_DATA_MEM_SZ/2));

  // remove the TLB entry which points to the PT
  if ( TLB_purge((void *)walker) == 0 ) {
    print_str("\tPT purged from TLB\n");
  } else {
    print_str("\twtf?\n");
  }

  // now reference a mapped page, to cause the double fault
  walker = (int *)(x_DATA_BASE_ADDR + PG_NUM*4096 + 1024);
  *walker = 0x88;              // cause a TLBrefill then a TLBload

  if ( *walker == 0x88 ) {
    print( *walker );
    print_str("\tdouble ok\n");
  } else {
    print_str("\tdouble err\n");
 }
#endif




#if PROT_VIOL
  //----------------------------------------------------------------------
  // let's cause a protection violation -- write to a write-protected page
  //   this will abort the simulation
  //----------------------------------------------------------------------

  walker = (int *)(x_DATA_BASE_ADDR + PG_NUM*4096);

  // first, remove V_addr from the TLB, to ensure the PT is searched
  if ( TLB_purge((void *)walker) == 0 ) {
    print_str("\tpurged\n");
  } else {
    print_str("\tTLB miss\n");
  }

  // change a PT element so it is data, NON-writable, page is mapped in PT
  new_value = ( ((x_DATA_BASE_ADDR + PG_NUM*4096)>>12) <<6) | 0b000011; // d=0
  PT_update( (int *)walker, 0, new_value);
  new_value = 0x00000001;                          // NOT-writable, mapped
  PT_update( (int *)walker, 1, new_value);

  *walker = 0x77;

  // will never get here -- protection violation on the store
  if ( *walker == 0x77 ) {
    print( *walker );
    print_str("\tprot viol not ok\n");
  } else {
    print_str("\tprot viol err\n");
 }
#endif




#if SEG_FAULT
  //-----------------------------------------------------------------
  // let's cause a segmentation fault -- reference to page not mapped
  //   this will abort the simulation
  //-----------------------------------------------------------------

#define PG_UNMAPPED 20

  // pick a page that is not mapped
  walker = (int *)(x_DATA_BASE_ADDR + PG_UNMAPPED*4096); // page not mapped

  // first, remove V_addr from the TLB, to ensure the PT will be searched
  if ( TLB_purge((void *)walker) == 0 ) {
    print_str("\tpurged\n");
  } else {
    print_str("\tTLB miss\n");
  }

  // add a new PT element for an address range with RAM but UN-mapped
  //   this address is above the page table
  new_value =
    (((x_DATA_BASE_ADDR + PG_UNMAPPED*4096)>>12) <<6) | 0b000011; // d=0
  PT_update( (int *)walker, 0, new_value);
  PT_update( (int *)walker, 1, 0);              // mark as unmapped
  new_value =
    (((x_DATA_BASE_ADDR + (PG_UNMAPPED+1)*4096)>>12) <<6) | 0b000011; // d=0
  PT_update( (int *)walker, 2, new_value);
  PT_update( (int *)walker, 3, 0);              // mark as unmapped

  *walker = 0x66;

  // will never get here -- seg fault on the store
  if ( *walker == 0x66 ) {
    print( *walker );
    print_str("\tseg fault not ok\n");
  } else {
    print_str("\tseg fault err\n");
 }
#endif



#if MEM_SEC
  //--------------------------------------------------------------------
  // let's cause a segmentation fault with  a reference to a page which
  //   is mapped but not in RAM; pretend it is in secondary memory 
  // this will abort the simulation
  //--------------------------------------------------------------------

#define PG_MEM_SEC 12

  // pick a page and mark int as in secondary memory
  walker = (int *)(x_DATA_BASE_ADDR + PG_MEM_SEC*4096); // page not in RAM

  // first, remove V_addr from the TLB, to ensure the PT will be searched
  if ( TLB_purge((void *)walker) == 0 ) {
    print_str("\tpurged\n");
  } else {
    print_str("\tTLB miss\n");
  }

  // change the PT element so it indicates range not in RAM but mapped
  //   and in secondary memory
  // TLB entryLo0 says mapping is invalid;  
  // TLB-invalid exception will abort simulation for page not loaded in RAM
  new_value =
    (((x_DATA_BASE_ADDR + PG_MEM_SEC*4096)>>12) <<6) | 0b000101; // v=0
  PT_update( (int *)walker, 0, new_value);
  PT_update( (int *)walker, 1, 0x0a);          // U=M=0, W=1, X=0, S=10 = a

  *walker = 0x55;

  // will never get here -- seg fault on the store
  if ( *walker == 0x55 ) {
    print( *walker );
    print_str("\tseg fault not in RAM not ok\n");
  } else {
    print_str("\tseg fault not in RAM err\n");
 }
#endif


  to_stdout('\n');

  return((int)walker);
}
//----------------------------------------------------------------------


void print_str(char *s) {
  int i;
  i = 0;
  while (s[i] != '\0') {
    to_stdout(s[i]);
    i = i + 1;
  }
}
