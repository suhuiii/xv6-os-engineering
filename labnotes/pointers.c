#include <stdio.h>
#include <stdlib.h>

void
f(void)
{
    int a[4];
    int *b = malloc(16);
    int *c;
    int i;

    printf("1: a = %p, b = %p, c = %p\n", a, b, c);

    c = a;
    for (i = 0; i < 4; i++)
	a[i] = 100 + i;
    c[0] = 200;
    printf("2: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    c[1] = 300;
    *(c + 2) = 301;
    3[c] = 302;
    printf("3: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    c = c + 1;
    *c = 400;
    printf("4: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    c = (int *) ((char *) c + 1);
    *c = 500;
    printf("5: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    b = (int *) a + 1;
    c = (int *) ((char *) a + 1);
    printf("6: a = %p, b = %p, c = %p\n", a, b, c);
}

int
main(int ac, char **av)
{
    f();
    return 0;
    /*

	1: a = 0x7ffcc90f7800, b = 0x17ad010, c = (nil)
	//memory address of a array, memory address of b, c not assigned.

	2: a[0] = 200, a[1] = 101, a[2] = 102, a[3] = 103
        // c points to memory address of a. a = [100,101, 102, 103]. c[0] = a[0] = 200

	3: a[0] = 200, a[1] = 300, a[2] = 301, a[3] = 302
        // c[1] = a[1] = 300; *(c+2) = memory address of a[2] = 301; 3[c] = ?

	4: a[0] = 200, a[1] = 400, a[2] = 301, a[3] = 302
	// c = c + 1, now c points to a[1] so *c = 400 = a[1] = 400.

	5: a[0] = 200, a[1] = 128144, a[2] = 256, a[3] = 302
	// type casting to c results in incrementing pointer by 1 byte instead of 4 for int.
	// x86 is little endian so..
	//originally:
	// a = C800 0000  | 9001 0000 | 2D01 0000 | 2E01 0000
	// 		   c^------->

	// ((char*) c + 1) 	
	// a = C800 0000  | 9001 0000 | 2D01 0000 | 2E01 0000
	// 		     c^--->


	// (int*) ((char*) c + 1) 	
	// a = C800 0000  | 9001 0000 | 2D01 0000 | 2E01 0000
	// 		     c^---------->

	// *c = 500 = 0x0000 01F4 -> F401 0000
	// a = C800 0000  | 90f4 0100 | 0001 0000 | 2E01 0000
	// 		     c^---------->

	// a =  200 | 128144 | 256 | 302

	6: a = 0x7ffcc90f7800, b = 0x7ffcc90f7804, c = 0x7ffcc90f7801
	// b = (int *) a + 1;
	// a = C800 0000  | 90f4 0100 | 0001 0000 | 2E01 0000
	// 		     c^---------->
	//		   b^------->

	// c = (int *) ((char *) a + 1);
	// a = C800 0000  | 90f4 0100 | 0001 0000 | 2E01 0000
	//      c^--------->
	//		   b^------->

    */
}
