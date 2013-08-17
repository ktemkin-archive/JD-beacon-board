/**
 * lights.c 
 * Beacon light control functions:
 * functions which specify the color and brightness of the lights.
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

#ifndef __LIGHTS_H__
#define __LIGHTS_H__

#include <avr/io.h>
#include <avr/interrupt.h>

#define WHITE_LIGHT_PIN 0
#define RED_LIGHT_PIN   1
#define GREEN_LIGHT_PIN 7

enum color {
  White  = WHITE_LIGHT_PIN,
  Red    = RED_LIGHT_PIN,
  Green  = GREEN_LIGHT_PIN
}; 


/**
 * Configures the AVR so it can control each of the 
 * beacon's visible lights.
 */ 
void set_up_lights();

/**
 * Turns on the light of the specified color; all other lights remain as they were.
 */ 
void turn_on_light(enum color light_color);

/**
 * Turns off the light of the specified color; all other lights remain as they were.
 */ 
void turn_off_light(enum color light_color);

/**
 * Turns off all of the beacon board's lights.
 */
void turn_off_lights();

/**
 * Sets the percent brightness of the given light.
 */ 
void set_light_brightness(uint8_t percent);


#endif
