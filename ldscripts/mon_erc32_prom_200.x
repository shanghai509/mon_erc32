/*
 *   模拟PROM固化的加载器，便于今后用加载器加载加载器。
 *   引导代码模拟PROM，放在2000000，然后自举到erc32_mon真正所在的1.75M区域运行
 */

OUTPUT_FORMAT("ihex")
SEARCH_DIR("/opt/erc32-ada/erc-elf/lib");
/**************************************************************************
 *
 * Filename:
 *
 *   This file is automatically generated from erc32_prom.sc
 *
 * Description:
 *
 *   Linker script for ERC32, with art0.S loader and code in boot PROM.
 *
 * Revision:
 *
 *   : erc32_prom.sc,v 1.1 2010-09-28 22:31:17 nettleto Exp $
 *
 **************************************************************************/
STARTUP("art0.o") /* 使用私有art0.o */
ENTRY(__cold_start)
/*
 * Set _STACK_SIZE to the size in bytes of the main stack. The main stack is
 * used by the main function and any other functions it calls. The minimum size
 * is the size of one frame plus the size of one interrupt frame, i.e. 396 bytes.
 * Add 104 bytes plus local data for each frame.
 */
_STACK_SIZE = 16K;
/*
 * Set _ISTACK_SIZE to the size of the interrupt stack. This stack is used by
 * all interrupt handlers so you must allow space for at least 14 interrupt
 * frames, i.e. 5544 bytes. Add to this the size of any local data, remembering
 * that library functions such as printf (that you may want to use for debugging)
 * use quite a lot.
 */
_ISTACK_SIZE = 16K;
/*
 * Set _PROM_SIZE to the size of the boot PROM. If you have no boot PROM then
 * use the value zero. Permissable sizes are: 128K, 256K, 512K, 1M, 2M, 4M, 8M
 * and 16M. Be sure to initialize the memory configuration register
 * with the same size.
 */
_PROM_SIZE = 32K;
/*
 * Set _RAM_SIZE to the size of the RAM. Permissable values are 256K, 512K,
 * 1MB, 2Mb, 4Mb, 8Mb, 16Mb, and 32Mb. Be sure to initialize the memory
 * configuration register with the same size.
 */
_RAM_SIZE = 2M;
/*
 * Set _RAM_START to the address of the first location in RAM. For the ERC32
 * chipset from Temic, this address is always 0x02000000.
 */
_RAM_START = 0x02000000;
/*
 * Set _RAM_START to the address of the first location in RAM. For the ERC32
 * chipset from Temic, this address is always 0x00000000.
 */
_PROM_START = 0x00000000;
/*
 * This is the default memory layout. You may change this as necessary by
 * editing the SECTIONS statements that follow:
 *
 * 0x00000000  +--------------------+
 *             | .init              |
 *             |        *(.init)    |
 *             +--------------------+
 *             | .itext             |  PROM copy of .text
 *             |                    |
 *             |                    |
 *             +--------------------+
 *             | .irodata           |  PROM copy of .rodata
 *             |                    |
 *             |                    |
 *             +--------------------+
 *             | .idata             |  PROM copy of .data
 *             |                    |
 *             |                    |
 *             +--------------------+
 *             /                    /
 *             /                    /
 *             +--------------------+
 * 0x02000000  | .text              |
 *             |        _stext      |
 *             |        *(.text)    |  program instructions
 *             |        _etext      |
 *             |        _endtext    |
 *             +--------------------+
 *             | .rodata            |
 *             |        _srodata    |
 *             |        *(.rodata)  | read only data sections
 *             |        ctor list   | constructors
 *             |        dtor list   | destructors
 *             |        -erodata    |
 *             +--------------------+
 *             | .data              |
 *             |        _sdata      |
 *             |        *(.data)    | initialized data sections
 *             |        _edata      |
 *             +--------------------+
 *             | .bss               |
 *             |        __bss_start | start of bss, cleared by crt0
 *             |        *(.bss)     | unitialized data sections
 *             +--------------------+
 *             |        _end        | start of heap, used by sbrk()
 *             |        _sheap      |
 *             |    heap space      |
 *             /                    /
 *             /                    /
 * 0x021dfff8  |        _eheap      |
 *             +--------------------+
 * 0x021e0000  | main stack         |
 *             |        _sstack     |
 *             |   (64K)            |
 *             |                    |
 * 0x021efff8  |        _estack     |
 *             +--------------------+
 * 0x021f0000  | interrupt stack    |
 *             |        _sistack    |
 *             |   (64K)            |
 *             |                    |
 * 0x021ffff8  +--------------------+
 * 0x02200000
 */
_RAM_END = _RAM_START + _RAM_SIZE;

/*
 * 加载器躲在1728K-1792K空间内
 */
_ERC32_MON_END   = _RAM_END - 256K;
_ERC32_MON_START = _ERC32_MON_END - 64K ;

/*
 * Start and end of interrupt stack
 */
_eistack = _ERC32_MON_END - 8;
_sistack = _ERC32_MON_END - _ISTACK_SIZE;
/*
 * Start and end of main stack
 */
_estack = _sistack - 8;
_sstack = _sistack - _STACK_SIZE;
/*
 * End of heap
 */
_eheap = _sstack - 8;
SECTIONS
{
  /* 注意引导自举代码在这里，RAM区 */
  .init _RAM_START : {
    *(.init)
    *(.fini)
  }
  _sitext = .;
  .text _ERC32_MON_START : AT (ADDR (.init) + SIZEOF (.init)) {
     _stext  =  .;
    *(.text)
    *(.text.*)
     . = ALIGN(8);
     _etext  =  .;
  }
  _sirodata = ADDR (.init) + SIZEOF (.init) + SIZEOF (.text) ;
  .rodata : AT (_sirodata) {
     . = ALIGN(8);
     _srodata  =  .;
    *(.rodata)
    . = ALIGN(4);
     __CTOR_LIST__ = .;
     LONG((__CTOR_END__ - __CTOR_LIST__) / 4 - 2)
     *(.ctors)
     LONG(0)
     __CTOR_END__ = .;
     __DTOR_LIST__ = .;
     LONG((__DTOR_END__ - __DTOR_LIST__) / 4 - 2)
     *(.dtors)
     LONG(0)
     __DTOR_END__ = .;
     . = ALIGN(8);
     _erodata  =  .;
  }

  _sidata  =  ADDR (.init) + SIZEOF (.init) + SIZEOF (.text) + SIZEOF (.rodata);

  .data _ERC32_MON_START + 16K : AT (_sidata) {
     . = ALIGN(8);
     _sdata  =  .;
    *(.data)
     . = ALIGN(8);
     _edata  =  .;
  }
  .bss : {
     . = ALIGN(8);
     __bss_start = .;
    *(.bss)
    *(COMMON)
     _end = .;
     . = ALIGN(8);
     _sheap = .;
  }
  .stab  0 (NOLOAD) :
  {
    [ .stab ]
  }
  .stabstr  0 (NOLOAD) :
  {
    [ .stabstr ]
  }
}
