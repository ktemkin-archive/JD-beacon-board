/**
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Kyle J. Temkin <ktemkin@binghamton.edu>
 * Copyright (c) 2014 Binghamton University
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "debug.h"

FILE spi_debug_channel = FDEV_SETUP_STREAM(debug_put_byte_blocking, NULL, _FDEV_SETUP_RW); 

/**
 * Enables the debug backend, which communicates debug information
 * over the board's SPI port. Intended for low-profile assistance in 
 * assembling student-assembled designs.
 */
void enable_debug_backend() {

  //Set the utilized SPI pins to output mode.
  SPI_DDR  |= (1 << SS_PIN) | (1 << SCK_PIN) | (1 << MOSI_PIN);

  //Ensure that the "slave select" line always reads high.
  SPI_PORT |= (1 << SS_PIN);

  //Enable SPI at 1MHz, the maximum frequency allowed by the Bus
  //Pirate (and our transmission lines!)
  SPCR = (1 << SPE) | (1 << MSTR) | (1 << SPR1);

  //Enable stdout over SPI, which allows the "printf" function
  //to be used to exchange debug information.
  //WARNING: Printf is blocking-- the whole microcontroller will
  //grind to a halt during transmission!
  enable_stdout_over_spi();

}

/**
 * Enables the use of the standard output functions (e.g. printf
 * and friends) to exchange debugging information. Be warned: the
 * AVR's implementation of these is blocking, and will grind the
 * whole microcontroller to a halt!
 */
void enable_stdout_over_spi() {
  stdout = &spi_debug_channel;
}

/**
 * Put a single byte of data onto the system's debug output;
 * but does not block.
 */
inline void debug_put_byte(uint8_t byte) {
  SPDR = byte;
}

/**
 * Blocks until the debug line has finished transmitting the
 * current byte.
 */ 
inline void wait_for_debug_ready() {
  while(!(SPSR & (1<<SPIF)));
}

/**
 * Put a single byte of data onto the system's debug output;
 * and blocks until the transmit is complete.
 */
void debug_put_byte_blocking(uint8_t byte) {
  debug_put_byte(byte);
  wait_for_debug_ready();
}
