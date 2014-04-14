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

#ifndef __PC_COMM_H__
#define __PC_COMM_H__

#include "state.h"

/**
 *
 * Transmits the provided bytee to the PC.
 *
 * @param uint16_t The byte to be transmitted.
 */
void send_byte_to_pc(uint8_t byte);

/**
 * Transmits the provided word to the PC.
 *
 * @param uint16_t The word to be provided.
 */
void send_word_to_pc(uint16_t word);

/** 
 * Generic invalid state constant.
 */ 
static const BoardState invalid_state = { .mode = MODE_ERROR };

/**
 * Transmits the provided board state to the PC.
 *
 * state: The current state to be transmitted.
 */
void send_state_to_pc(BoardState state);

/*
 * Receives a board state from the PC. If no board state is available,
 * returns a board state with a beacon ID of all ones.
 */ 
BoardState receive_state_from_pc();


#endif
