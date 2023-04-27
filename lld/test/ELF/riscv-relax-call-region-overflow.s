# REQUIRES: riscv

# RUN: rm -rf %t && split-file %s %t && cd %t

## Check that relaxation prevents region overflow

# RUN: llvm-mc -filetype=obj -triple=riscv32 -mattr=+c,+relax a.s -o a.32c.o
# RUN: llvm-mc -filetype=obj -triple=riscv32 -mattr=+c,+relax b.s -o b.32c.o
# RUN: ld.lld -T lds a.32c.o b.32c.o -o 32c
# RUN: llvm-objdump --section-headers 32c | FileCheck %s --check-prefixes=RELAX_SECTIONS
# RELAX_SECTIONS:   1 .text         0000000a 00000000 TEXT

## Check that we still overflow with relaxation disabled

# RUN: not ld.lld -T lds a.32c.o b.32c.o --no-relax -o /dev/null 2>&1 | FileCheck --check-prefix=ERR0 %s
# ERR0: ld.lld: error: section '.text' will not fit in region 'ROM'

#--- a.s
.global _start
_start:
  # These calls can be relaxed to be much smaller, enough to fit within the
  # tiny ROM region
  call bar
  call bar
  call bar
  call bar

#--- b.s
.globl bar
bar:
  ret

#--- lds
MEMORY {
  ROM (rx) : ORIGIN = 0, LENGTH = 12
}
SECTIONS {
  .text 0x00000 : { *(.text) } > ROM
}
