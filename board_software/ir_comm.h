/**
 * ir_comm.c 
 * Library for UART IR communications over a 38kHz 
 * carrier square-wave.
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
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef __IR_COMM_H__
#define __IR_COMM_H__

#include <avr/io.h>
#include <avr/interrupt.h>

#include "timers.h"

/**
 * Define the RecieveHandler type, which stores a pointer to a function which
 * should handle any recieved bytes.
 */ 
typedef void (*ReceiveHandler)(uint8_t);

/**
 * Define the TransmitProvider type, which stores a pointer to a function which
 * should return a byte to be transmitted.
 */ 
typedef uint8_t (*TransmitProvider)();


/**
 * Prepares the microcontroller for UART communications
 * using an IR LED.
 */ 
void set_up_ir_comm();

/**
 * Enables receipt of IR data.
 */ 
void ir_enable_receive();

/**
 * Disables receipt of IR data.
 *
 * This should be called prior to transmission when the transmitter
 * and receiver and using the same modulation, as to prevent receiving
 * one's own data.
 */ 
void ir_disable_receive();

/**
 * Disables receipt of IR data until the next transmission is complete.
 *
 * This should be called prior to transmission when the transmitter
 * and receiver and using the same modulation, as to prevent receiving
 * one's own data.
 */ 
void ir_disable_receive_until_transmit_complete();

/**
 * Non-blocking function which begins a process of repeatedly transmitting
 * This is driven by interrupts, and thus effecitvely runs "in the background".
 */ 
void ir_start_continuously_transmitting();

/**
 * Transmits the given value over the board's IR.
 */ 
void ir_transmit(uint8_t value);


/**
 * Stops any transmission operations which are currently being performed
 * (e.g. start_continuously_transmitting). If the transmission is currently
 * transmitting a frame, transmission will be halted after that frame's stop bit.
 */ 
void ir_stop_transmitting();

/**
 * Registers a given function to act as a "recieve handler",
 * which will be called whenever a new byte of data has been
 * received over the IR channel.
 */ 
void register_receive_handler(ReceiveHandler handler);

/**
 * Registers a given function to act as a "frame error handler",
 * which will be called whenever a framing error has occurred.
 */
void register_frame_error_handler(ReceiveHandler handler);

/**
 * Registers a given function to act as a "transmit provider",
 * which will be called whenever a new byte of data is about
 * to be transmitted. This function should return the data
 * to be transmitted.
 */
void register_transmit_provider(TransmitProvider provider);


/**
 * Disables the IR carrier wave, disabling IR transmission.
 */
void disable_modulation();

/**
 * Enables the IR carrier wave, enable IR transmission.
 */
void enable_modulation();

#endif
