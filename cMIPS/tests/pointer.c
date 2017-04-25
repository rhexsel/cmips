#include <cMIPS.h>

#define NIL ((void *)0)

typedef struct elem { 
  struct elem *next; 
  int  vet[3]; 
} elemType;

elemType strct[16];
elemType *head;

elemType *insert(elemType *h, elemType *e) {
  elemType *p;

  p = h;
  while ((void *)p->next != NIL) {
    p = p->next;
  }
  p->next = e;
  e->next = NIL;
  return e;
}


int main(void) {
  int i,j;
  elemType *x;

  head = &(strct[0]);

  for (i=0; i < 5; i++) { // initialize 5 elements, not in sequence
    j = 2*i + 5;
    // print((int)&(strct[j]));  // print address of strct's element
    x = insert(head, &(strct[j]));
    x->vet[1] = j;
  }

  to_stdout('\n');  // print blank line

  x = head->next;   // get first element
  for (i=0; i < 5; i++) {
    print(x->vet[1]);
    x = x->next;    // get next element
  }

  to_stdout('\n');  // print blank line

}
