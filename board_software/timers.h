/**
 * timers.c
 * Timer functions for the JD Beacon Board; which control precisely timed
 * events (such as the dimming of LEDs, and the trigger to transmit over IR.)
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

#ifndef __TIMERS_H__
#define __TIMERS_H__

#include <avr/interrupt.h>

/**
 * Define the RecieveHandler type, which stores a pointer to a function which
 * should handle any recieved bytes.
 */
typedef void (*TimerEventHandler)();

/**
 * Set up each of the internal hardware timers for use by the timer module.
 * This enables use of the various timer functions provided below.
 *
 * This function is designed to be idempotent-- that is, you can call it
 * multiple times with no ill effects. This means that multiple modules which
 * depend on timer functions can all call this initialization function.
 */
void set_up_timers();

/**
 * Registers a function which will be called whenever a "fast tick"
 * occurs. These events are called approximately 150 times per second.
 *
 * handler: A pointer to the function which will be called approximately
 *    150 times per second.
 */
void register_fast_tick_handler(TimerEventHandler handler);

/**
 * Registers a function which will be called whenever a "slow tick"
 * occurs. These events are called approximately once per second.
 *
 * handler: A pointer to the function which will be called approximately
 *    once per second; or null to disable the slow tick handler.
 */
void register_slow_tick_handler(TimerEventHandler handler);



#endif
