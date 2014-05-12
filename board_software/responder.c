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
#include <util/delay.h>

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
 * Configures the AVR's unused I/O pins to inputs with pull-up
 * resistors, to save power. This isn't an optimal configuration
 * (it would be better to use external pull-ups, or set these up
 *  as outputs), but it reduces the amount of soldering inherent
 *  to the first method, and reduces the risk of a short inherent
 *  to the second.
 */ 
void pull_up_unused_pins();


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
  pull_up_unused_pins();
  set_up_lights();
  set_up_ir_comm();

  //In addition, turn on the "transmit complete" interrupt, which we use
  //to turn off modulation when we're done transmitting.
  
  //... and enable the UART receive interrupt.
  UCSR1B |= (1 << TXCIE1);

  //Turn on the green "power" light..
  #ifndef SILENT_OPERATION
    turn_on_light(Green);
  #else
    turn_off_lights();
  #endif

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
 * Configures the AVR's unused I/O pins to inputs with pull-up
 * resistors, to save power. This isn't an optimal configuration
 * (it would be better to use external pull-ups, or set these up
 *  as outputs), but it reduces the amount of soldering inherent
 *  to the first method, and reduces the risk of a short inherent
 *  to the second.
 */ 
void pull_up_unused_pins() {

  //Specify which of the values correspond to unused ports;
  //these will be configured as inputs with internal pull-ups.
  const uint8_t port_f_unused = 0b11111111;
  const uint8_t port_e_unused = 0b11111111;
  const uint8_t port_d_unused = 0b10110011;
  const uint8_t port_b_unused = 0b10001110;

 
  //Apply the port values themselves.
  DDRF  &= ~port_f_unused;
  PORTF |=  port_f_unused;

  DDRE  &= ~port_e_unused;
  PORTE &=  port_e_unused;

  DDRD  &= ~port_d_unused;
  PORTD &=  port_d_unused;

  DDRB  &= ~port_b_unused;
  PORTB &=  port_b_unused;
}

/**
 * Function which handles the receipt of an IR value from
 * the beacon board under test. When a n IR value is received,
 * we transmit the inverse back as soon as we can.
 */
void handle_IR_receive(uint8_t value) {

  //If the "silent operation" flag wasn't defined
  //at compile time, indicate that the beacon has received IR.
  #ifndef SILENT_OPERATION
      toggle_lights();
  #endif

  //Transmit the claim code...
  ir_transmit(~value);

}


