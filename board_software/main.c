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

#include <avr/interrupt.h>
#include "usb_serial/usb_serial.h"
#include "frequency.h"

#include "state.h"

#include "lights.h"
#include "ir_comm.h"
#include "pc_comm.h"

/**
 * The relative brightnesses for a bright and dim beacon LED,
 * in terms of percent duty cycle.
 */ 
static const uint8_t Bright = 100;
static const uint8_t Dim = 5;

/**
 * Stores the current state for the board.
 * See state.h for more information.
 */
volatile board_state beacon = {.id = 0, .owner = OwnerNone};

/**
 * Connects the beacon board to the host PC.
 * Will wait until the host PC is connected.
 */ 
inline void connect_to_pc();

/**
 * Applies the provided "beacon state" object to the
 * board, replacing the current state, and updating all peripherals.
 */ 
void apply_state(board_state new_state);

/**
 * Enforces the current beacon board state, which determines the
 * current state of the beacon LEDs and IR comm.
 */ 
void enforce_state();

void handle_pc_comm();


/**
 * Main beacon control routines.
 */ 
int main() {


  //Ensure we're running at 16MHz.
  CPU_PRESCALE(CPU_16MHz);

  //Set up the board's peripherals...
  set_up_lights();
  set_up_ir_comm();
  connect_to_pc();
  sei();

  while(1) {
    handle_pc_comm();
  }

  //This code is unreachable, but avr-gcc throws a
  //warning if we don't return an integer.
  return 0;

}

/**
 * Handles all requests (and commands) recieved from the PC.
 */
void handle_pc_comm() {

  board_state new_state;

  //Wait until we have a request...
  while(!usb_serial_available());

  //Receive the new board state.
  new_state = receive_state_from_pc();

  //If we don't a "request" state, update the
  //internal state. 
  if(new_state.id != 31) {
     apply_state(new_state);
  }

  //Send the beacon's current state to the PC.
  //(If this was a request, the PC will use this to update its display. 
  // If this was a change, it will use this to verify that the change 
  // went through correctly.)
  send_state_to_pc(beacon);
}

/**
 * Applies the provided "beacon state" object to the
 * board, replacing the current state, and updating all peripherals.
 */ 
void apply_state(board_state new_state) {
  beacon = new_state;
  enforce_state();
}


/**
 * Enforces the current beacon board state, which determines the
 * current state of the beacon LEDs and IR comm.
 */ 
void enforce_state() {

  turn_off_lights();

  // If the beacon has an invalid ID, turn off all peripherals
  // and wait to be assigned an ID.
  if(beacon.id == 0 || beacon.id == 31) {
    return;
  }

  // Set the color of the beacon's light according to which team
  // owns the beacon; or use white if no one owns the beacon.
  switch(beacon.owner) {
 
    case OwnerGreen:
      turn_on_light(Green);
      break;

    case OwnerRed:
      turn_on_light(Red);
      break;

    default:
      turn_on_light(White);
      break;

  }

  // If the beacon is owned by the robot that's playing on this beacon's
  // side of the board, dim the light so it's a less attractive target.
  // Otherwise, turn on the light at full brightness.
  if((uint8_t)beacon.owner == (uint8_t)beacon.affiliation) {
    set_light_brightness(Dim);
  } else {
    set_light_brightness(Bright);
  }

  //TODO: Handle IR communication accordingly?


}


/**
 * Sets up communications with the host PC.
 *
 * If the beacon board isn't connected to a PC, this will
 * "hang" here forever. In the future, PC-less single-beacon
 * operation may be desirable, in which case this function
 * will have to be reworked.
 */ 
inline void connect_to_pc() {

  //Initialize USB communications...
  usb_init();

  //... and wait for the USB port to be configured.
  while(!usb_configured());

}
