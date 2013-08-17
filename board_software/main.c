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
#include <stdbool.h>
#include <stdlib.h>

#include "usb_serial/usb_serial.h"
#include "frequency.h"

#include "state.h"

#include "lights.h"
#include "ir_comm.h"
#include "pc_comm.h"

#include "main.h"

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
static volatile BoardState beacon = {.id = 0, .owner = OwnerNone};

/**
 * Stores a "claim code", which is the code that needs to be transmitted to 
 * claim the beacon. This should be populated with a random number once the
 * beacon is assigned an ID.
 */
static volatile uint8_t claim_code = 0;

/**
 * Main beacon control routines.
 */ 
int main() {

  //Set up the board's peripherals...
  set_up_hardware();

  //Handle communications with the host PC forever.
  //Note that all other functions are interrupt driven;
  //so PC communication is both the lowest priority and
  //the only task running in the "main loop".
  while(1) {
    handle_pc_comm();
  }

  //This code is unreachable, but avr-gcc throws a
  //warning if we don't return an integer.
  return 0;

}


/**
 * sets up the board's peripherals and communications channels.
 */
void set_up_hardware() {

  //Ensure we're running at 16MHz.
  CPU_PRESCALE(CPU_16MHz);

  //Set up all of the peripherals...
  set_up_lights();
  set_up_ir_comm();

  //Set up the PC connection
  connect_to_pc();

  //And enable interrupts, starting the main device functions.
  sei();
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


/**
 * Handles all requests (and commands) recieved from the PC.
 */
void handle_pc_comm() {

  BoardState new_state;

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
void apply_state(BoardState new_state) {

  //Apply the new state itself...
  beacon = new_state;

  //Seed the internal random number generator using
  //the current value of Timer 1 (which is run by the light
  //module). This allows us to use the PC communications erratic 
  //timings as a source of pseudo-randomness.
  srand(TCNT1);

  //And apply the state's effects.
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

  // If the beacon can be claimed, ensure the beacon's lights
  // is running at full brightness, and the IR channel is on.
  // Otherwise, dim the light so it's a less attractive target,
  // and disable IR transmission.
  if(beacon_can_be_claimed()) {
    set_light_brightness(Bright);
    start_transmitting_claim_code();
  } else {
    set_light_brightness(Dim);
    ir_stop_transmitting();
  }
}

/**
 * Starts the repeated transmission of a "claim code", a code which is
 * transmitted to the competing robots. If a robot is able to respond
 * with a modification of this code, it can claim the beacon.
 */ 
void start_transmitting_claim_code() {
  ir_start_continuously_transmitting(rand());
}

/**
 * Returns true iff this beacon can be claimed;
 * that is, if it isn't owned by the current team.
 */
bool beacon_can_be_claimed() {
  return (uint8_t)beacon.owner != (uint8_t)beacon.affiliation;
}


