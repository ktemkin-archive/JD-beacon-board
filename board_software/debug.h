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


#ifndef __DEBUG_H__
#define __DEBUG_H__

#include <avr/io.h>
#include <stdio.h>

//Specifies the port which this chip utilizes for SPI...
#define SPI_DDR  DDRB
#define SPI_PORT PORTB

//... and each of the relevant pin locations.
//Note that we use PB3 as a "slave select", as 
//this pin is connected to our ISP connector.
#define SS_PIN   PB0
#define SCK_PIN  PB1
#define MOSI_PIN PB2 


/**
 * Enables the debug backend, which communicates debug information
 * over the board's SPI port. Intended for low-profile assistance in 
 * assembling student-assembled designs.
 */
void enable_debug_backend();

/**
 * Enables the use of the standard output functions (e.g. printf
 * and friends) to exchange debugging information. Be warned: the
 * AVR's implementation of these is blocking, and will grind the
 * whole microcontroller to a halt!
 */
void enable_stdout_over_spi();

/**
 * Put a single byte of data onto the system's debug output;
 * but does not block.
 */
inline void debug_put_byte(uint8_t byte);

/**
 * Blocks until the debug line has finished transmitting the
 * current byte.
 */ 
inline void wait_for_debug_ready();

/**
 * Put a single byte of data onto the system's debug output;
 * and blocks until the transmit is complete.
 */
inline void debug_put_byte_blocking(uint8_t byte);

#endif
