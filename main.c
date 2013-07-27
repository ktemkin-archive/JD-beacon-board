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

#include "lights.h"
#include "ir_comm.h"

inline void connect_to_pc();

int main() {

  //Ensure we're running at 16MHz.
  CPU_PRESCALE(CPU_16MHz);

  //Set up the board's peripherals...
  set_up_lights();
  set_up_ir_comm();
  connect_to_pc();
  sei();

  turn_on_light(Red);

  while(1) {

    //Recieve a single byte from the PC, for testing.
    int16_t byte = usb_serial_getchar();

    if(byte < 0) {
      continue;
    }

    switch(byte) {
      case 'r':
        turn_off_lights();
        turn_on_light(Red);
        break;
      case 'g':
        turn_off_lights();
        turn_on_light(Green);
        break;
      case 'w':
        turn_off_lights();
        turn_on_light(White);
        break;
      case 'o':
        turn_off_lights();
        break;
      case 'h':
        set_light_brightness(100);
        break;
      case 'l':
        set_light_brightness(5);
        break;
    }
  }

  //This code is unreachable, but avr-gcc throws a
  //warning if we don't return an integer.
  return 0;

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
