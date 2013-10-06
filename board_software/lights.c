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

#include "lights.h"

//static const uint16_t cycles_per_pwm = 512;

volatile static uint8_t current_light_mask = 0;
volatile static uint8_t percent_brightness = 100;

/**
 * Configures the AVR so it can control each of the
 * beacon's visible lights.
 */
void set_up_lights() {

  //Set the light pins to output mode.
  LIGHT_DDR |= ((1 << WHITE_LIGHT_PIN) | (1 << GREEN_LIGHT_PIN) | (1 << RED_LIGHT_PIN));

  //Set up the timers, which handle PWM.
  //Note that this function is idempotent, and thus won't clash with any other
  //units which are using the timers library.
  set_up_timers();

  //Register our PWM timer handler, so the internal timers module
  //will call it regularly, and we can dim LEDs.
  register_fast_tick_handler(handle_pwm_timer_event);

}

/**
 * Turns on the light of the specified color; all other lights remain as they were.
 */
void turn_on_light(enum color light_color) {

  //Adust the mask which determines the currently active LEDs.
  current_light_mask |= 1 << light_color;

  //And "turn on" all of the currently active LEDs.
  LIGHT_PORT |= current_light_mask;
}

/**
 * Turns off the light of the specified color; all other lights remain as they were.
 */
void turn_off_light(enum color light_color) {
  current_light_mask &= ~(1 << light_color);
  LIGHT_PORT &= ~(1 << light_color);
}

/**
 * Turns off all of the beacon board's lights.
 */
void turn_off_lights() {
  //Turn off all three of the lights.
  turn_off_light(Red);
  turn_off_light(White);
  turn_off_light(Green);
}

/**
 * Sets the percent brightness of the given light.
 */
void set_light_brightness(uint8_t percent) {
  percent_brightness = percent;
}


/**
 * Handles PWM timer events, which occur roughly 150 times
 * per second; these events are used to enact dimming of
 * the board's LEDS.
 */
void handle_pwm_timer_event() {

  static uint8_t ticks = 0;

  //Count a single overflow "tick".
  ticks = (ticks + 1) % 100;

  //If we've reached the turn-off time, disable the light.
  if(ticks == percent_brightness) {
    LIGHT_PORT &= ~current_light_mask;
  }
  //Otheriwse, if we've just started a new cycle,
  //turn the light on.
  else if (ticks == 0) {
    LIGHT_PORT |= current_light_mask;
  }

}
