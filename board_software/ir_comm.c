/**
 * ir_comm.c
 * Library for UART IR communications over a
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

#include <avr/io.h>
#include <avr/interrupt.h>

//DEBUG ONLY
#include <util/delay.h>

#include "ir_comm.h"

/**
 * Specifies the carrier frequency which should be used for IR communications.
 * This is typically 38 kHz, which is the NEC standard carrier frequency.
 */
static const unsigned long carrier_frequency = 38000UL;


/**
 * Specifies the signaling rate ("symbol" or "baud" rate) for the UART.
 * In this case, this is roughly equal to the number of bits transmitted
 * per second, including the protocol overhead ("start" and "stop bits").
 */
static const unsigned long uart_baud_rate = 300;


/**
 * Static "pseudo-global" that stores the value used for continuous transmission.
 */
static volatile uint8_t value_to_continuously_transmit;

/**
 * Static "pseudo-global" that stores the function which should be called on a
 * succesful reciept of IR data.
 */
static volatile ReceiveHandler receive_handler = 0;


/**
 * Static "pseudo-global" that stores the function which should be called to
 * determine which value to transmit.
 */
static volatile TransmitProvider transmit_provider = 0;

/**
 * Flag which indicates whether receipt over the IR line
 * should be enabled. (Unlike RXEN, this does not "go low"
 * if the IR line temporarily disabled for transmission.)
 */ 
static uint8_t ir_receive_enabled = 0;


/**
 * Sets up Timer 3 to produce a 38kHz "carrier" square wave,
 * for use in IR communications. This is externally AND'd with
 * our UART signal to produce our final IR communication.
 */
static void set_up_pwm_timer();


/**
 * Sets up the AVR's UART to produce the raw data for our
 * communication. This is externally AND'd with a carrier wave,
 * producing our final IR signal.
 */
static void set_up_uart();


/**
 * Sends the "continuous transmission" value; this should
 * be called repeatedly to enact continuous transmission mode.
 */
static void ir_perform_continuous_transmission();


/**
 * Prepares the microcontroller for UART communications
 * using an IR LED.
 */
void set_up_ir_comm() {

  //Set up the internal PWM timer to create our carrier wave.
  set_up_pwm_timer();

  //Set up the UART.
  set_up_uart();

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


  /**
   * Specifies the frequency of the infrared carrier wave,
   * by specifying the amount of _half periods_ in timer cycles.
   *
   * This is equal to (F_CPU / desired_carrier_frequency) / 2:
   * the resultant period of the wave is equal to the ratio of
   * the faster to the slower clocks; which we here divide by two.
   */
  OCR3A = ((F_CPU / carrier_frequency) / 2UL); // Should equal 210 for 38kHz.


  // Place Timer 3 into Clear on Timer Compare mode,
  // which essentially configures it to use OCR3A as
  // upper bound on how high Timer 3 can count;
  // and set the upper bound to half of our
  // period.
  TCCR3B |= (1 << WGM32);

  // Configure the timer to automatically invert the OC3A
  // pin, which happens to be PC6, each time the timer reaches
  // its maximum value. This is what actually generates our
  // square-wave.
  TCCR3A |= (1 << COM3A0);

}


/**
 * Sets up the AVR's UART to produce the raw data for our
 * communication. This is externally AND'd with a carrier wave,
 * producing our final IR signal.
 */
void set_up_uart() {

  UCSR1A = 0;

  //Enable the two core UART components: the transmitter and the reciever.
  UCSR1B = ((1 << RXEN1) | (1 << TXEN1));

  //Specify the frame format for the subsequent UART communcations:
  //8 bits of data; no parity; one stop bit.
	UCSR1C = (1 << UCSZ11) | (1 << UCSZ10);

  //Compute the baud rate, determining the UART counter value which will
  //trigger a send/receive event. See page 189 of the AtMega32u4 datasheet.
  UBRR1 = (F_CPU / (16UL * uart_baud_rate)) - 1;

  //Enable the "transmission complete" interrupt.
  UCSR1B |= (1 << UDRE1);

}


/**
 * Enables receipt of IR data.
 */ 
void ir_enable_receive() {

  //Set the IR recieve flag,
  //which indicates that we should be 
  //recieveing.
  ir_receive_enabled = 1;

  //And enable IR receipt itself.
  UCSR1B |= (1 << RXEN1);

}


/**
 * Disables receipt of IR data.
 */ 
void ir_disable_receive() {

  //Clear the IR recieve flag,
  //which indicates that we should not  
  //be recieveing.
  ir_receive_enabled = 0;

  //And disable receipt itself.
  UCSR1B &= ~(1 << RXEN1);

}

/**
 * Disables receipt of IR data until the next transmission is complete.
 *
 * This should be called prior to transmission when the transmitter
 * and receiver and using the same modulation, as to prevent receiving
 * one's own data.
 */ 
void ir_disable_receive_until_transmit_complete() {
  UCSR1B &= ~(1 << RXEN1);
}


/**
 * Non-blocking function which begins a process of repeatedly transmitting
 * a single value. This is driven by interrupts, and thus effecitvely runs
 * "in the background".
 *
 * Note that the baud rate may need to be relatively low to ensure
 * that the other end can keep up with all the data we're sending!
 */
void ir_start_continuously_transmitting() {

  //Sets up the IR "continous transmission" function such that
  //it will be called approximately once per second.
  register_slow_tick_handler(ir_perform_continuous_transmission);

}


/**
 * Sends the "continuous transmission" value; this should
 * be called repeatedly to enact continuous transmission mode.
 */
static void ir_perform_continuous_transmission() {

  //If we don't have a transmission provider function,
  //return without transmitting.
  if(!transmit_provider) {
    return;
  }

  //Ensure that we don't try to receive during transmit.
  ir_disable_receive_until_transmit_complete();

  //Push the desired value into the UART data register,
  //queuing it for transmission.
  UDR1 = transmit_provider();

}


/**
 * Stops any transmission operations which are currently being performed
 * (e.g. start_continuously_transmitting). If the transmission is currently
 * transmitting a frame, transmission will be halted after that frame's stop bit.
 */
void ir_stop_transmitting() {

  //Disable the slow tick handler, disabling any current continuous transmission.
  register_slow_tick_handler(0); 

}


/**
 * Registers a given function to act as a "recieve handler",
 * which will be called whenever a new byte of data has been
 * received over the IR channel.
 */
void register_receive_handler(ReceiveHandler handler) {

  //Store the receive handler...
  receive_handler = handler;

  //... and enable the UART receive interrupt.
  UCSR1B |= (1 << RXCIE1);

}

/**
 * Registers a given function to act as a "transmit provider",
 * which will be called whenever a new byte of data is about
 * to be transmitted. This function should return the data
 * to be transmitted.
 */
void register_transmit_provider(TransmitProvider provider) {
  transmit_provider = provider;
}


/**
 * Interrupt handler which is executed whenever the UART is ready
 * for to transmit a new piece of data while in continuous transmission mode.
 */
ISR(USART1_UDRE_vect) {

  //If receipt should be enabled, but we've disabled reciept
  //during transmission, re-enable receipt.
  if(ir_receive_enabled) {
    ir_enable_receive();
  }

}

/**
 * Interrupt handler which is executed whenever the UART
 * receives a valid piece of data.
 */
ISR(USART1_RX_vect) {

  //Always read in the value that was received,
  //as this has the side effect of allowing reciept
  //to continue.
  uint8_t received = UDR1;

  //TODO: Check for framing errors.

  //If a receive handler was registered, call it.
  if(receive_handler) {
    receive_handler(received);
  }

}
