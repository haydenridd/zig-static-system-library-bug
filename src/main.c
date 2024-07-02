#include <stdio.h>
#include "staticlib/staticlib.h"
#include "sys_lib.h"

int main()
{
    printf("staticLibFunc: %d\n", staticLibFunc());
    printf("sysLibFunc: %d\n", sysLibFunc());
    return 0;
}