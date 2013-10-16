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

#include <avr/interrupt.h>

#include "frequency.h"
#include "ir_comm.h"
#include "lights.h"

void set_up_hardware();
void handle_IR_receive(uint8_t value);

/**
 * The relative brightnesses for a bright and dim beacon LED,
 * in terms of percent duty cycle.
 */
static const uint8_t Bright = 100;
static const uint8_t Dim = 5;


/**
 * Main beacon control routines.
 */
int main() {

  //Set up the board's peripherals...
  set_up_hardware();

  //Start listening for data from the competing robots.
  //In this case, receipt of any signals will trigger the "handle IR receive" function.
  register_receive_handler(handle_IR_receive);

  //Wait forever, allowing the IR interrupts to occur
  //when appropriate.
  while(1);

  //This code is unreachable, but avr-gcc throws a
  //warning if we don't return an integer.
  return 0;

}


/**
 * Sets up the board's peripherals and communications channels.
 */
void set_up_hardware() {

  //Ensure we're running at 16MHz.
  CPU_PRESCALE(CPU_16MHz);

  //Set up all of the peripherals...
  set_up_lights();
  set_up_ir_comm();

  //Turn on the green "power" light..
  turn_on_light(Green);

  //And enable interrupts, starting the main device functions.
  sei();
}


void toggle_lights() {

  static uint8_t bright = 0;

  //toggle the "bright light" flag
  bright = bright + 128;

  //If we're in bright mode, turn on the light.
  if(bright) {
    set_light_brightness(Bright);
  } else {
    set_light_brightness(Dim);
  }

}


/**
 * Function which handles the receipt of an IR value from
 * the beacon board under test. When a n IR value is received,
 * we transmit the inverse back as soon as we can.
 */
void handle_IR_receive(uint8_t value) {
  toggle_lights();
  ir_transmit(~value);
}
