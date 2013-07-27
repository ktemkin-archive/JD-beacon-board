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

#include "ir_comm.h"

static void set_up_pwm_timer();

static const uint8_t half_period_in_cycles = 210; 


/**
 * Prepares the microcontroller for UART communications
 * using an IR LED.
 */ 
void set_up_ir_comm() {
 
  //Set up the internal PWM timer to create our carrier wave.
  set_up_pwm_timer();  

}

/**
 * Sets up Timer 3 to produce a 38kHz PWM waveform,
 * for use in IR communications.
 */ 
void set_up_pwm_timer() {

  // Set the OC4D pin (PD7) into output mode.
  DDRC |= (1 << PC6);

  // Place Timer 3 into PWM generation mode; which 
  // produces a waveform that's very close to 38kHz.
  //
  // This waveform is used as a carrier wafe for IR
  // communciations.
  TCCR3B |= (0 << CS11 | 1 << CS10);
  
  // Place Timer 3 into Clear on Timer Compare mode,
  // which essentially configures it to use OCR3A as
  // upper bound on how high Timer 3 can count;
  // and set the upper bound to half of our 
  // period.
  OCR3A = half_period_in_cycles;
  TCCR3B |= (1 << WGM32);

  // Configure the timer to automatically invert the OC3A
  // pin, which happens to be PC6, each time the timer reaches
  // its maximum value. This is what actually generates our
  // square-wave.
  TCCR3A |= (1 << COM3A0);

}
