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
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef __MAIN_H__
#define __MAIN_H__

#include <avr/interrupt.h>
#include <stdbool.h>
#include <stdlib.h>

#include "usb_serial/usb_serial.h"
#include "frequency.h"

#include "state.h"

#include "lights.h"
#include "ir_comm.h"
#include "pc_comm.h"

/**
 * Connects the beacon board to the host PC.
 * Will wait until the host PC is connected.
 */ 
inline void connect_to_pc();

/**
 * Applies the provided "beacon state" object to the
 * board, replacing the current state, and updating all peripherals.
 */ 
void apply_state(BoardState new_state);

/**
 * Enforces the current beacon board state, which determines the
 * current state of the beacon LEDs and IR comm.
 */ 
void enforce_state();

/**
 * Handles all requests (and commands) recieved from the PC.
 */
void handle_pc_comm();

/**
 * Returns true iff this beacon can be claimed;
 * that is, if it isn't owned by the current team.
 */
bool beacon_can_be_claimed();

/**
 * Returns true iff the given beacon is _disabled_,
 * and thus not being used in this round.
 */ 
bool beacon_is_disabled();


/**
 * Sets up the board's peripherals and communications channels.
 */
void set_up_hardware();


/**
 * Configures the AVR's unused I/O pins to inputs with pull-up
 * resistors, to save power. This isn't an optimal configuration
 * (it would be better to use external pull-ups, or set these up
 *  as outputs), but it reduces the amount of soldering inherent
 *  to the first method, and reduces the risk of a short inherent
 *  to the second.
 */ 
void pull_up_unused_pins();


/**
 * Starts the repeated transmission of a "claim code", a code which is
 * transmitted to the competing robots. If a robot is able to respond
 * with a modification of this code, it can claim the beacon.
 */ 
void start_transmitting_claim_code();


/**
 * Function which handles the receipt of an IR value from
 * the competing robot. This function is called from within
 * an interrupt, and thus is assumed to be uninterruptable.
 */ 
void handle_IR_receive(uint8_t value);


/**
 * Functions which determines the value that should be transmitted
 * over IR. This is called roughly once per second by the IR module.
 */ 
uint8_t value_to_transmit();


#endif
