/**
* PC Communications Functions
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

#include "usb_serial/usb_serial.h"
#include "pc_comm.h"

/**
* Transmits the provided board state to the PC.
*
* state: The current state to be transmitted.
*/
void send_state_to_pc(BoardState state) {
  usb_serial_putchar(state.raw_data);
}


/**
* Receives a board state from the PC. If no board state is available,
* returns a board state with a beacon ID of all ones.
*/
BoardState receive_state_from_pc() {

  //Receive the board state from the PC, and return it.
  BoardState state = { .raw_data = usb_serial_getchar() };
  return state;

}


