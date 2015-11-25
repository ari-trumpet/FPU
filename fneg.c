#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "def.h"

uint32_t fneg(uint32_t a) {
  union data_32bit a_32bit;
  a_32bit.uint32 = a;
  a_32bit.sign = ~(a_32bit.sign);
  return (a_32bit.uint32);
}
