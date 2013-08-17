/**
 *
 * Beacon board state.
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

#ifndef __STATE_H__
#define __STATE_H__

#include <stdint.h>

/**
 * Enumerated type which specifies possible owners of the 
 * current beacon.
 */ 
enum board_owner_enum {
  OwnerGreen = 0,
  OwnerRed   = 1,
  OwnerNone  = 2
};
typedef enum board_owner_enum BoardOwner;



/** 
 * Enumerated type which specifies the possible "sides" that
 * this board can be on; that is, which robot the board is affiliated
 * with.
 */ 
enum board_affiliation_enum {
  AffiliationGreen = 0,
  AffiliationRed   = 1
};
typedef enum board_affiliation_enum BoardAffiliation;



/**
 * Data structure which represents the current state of a beacon board.
 * Note that this structure uses two unusual C features:
 *  - A union, which allows a single piece of memory to be interpreted in multiple 
 *    ways. Here, we can choose to interpret this piece of memory as a structure of
 *    individual board state elements, or as a single "whole" value. This allows us
 *    to either work with the individual pieces of the board state, or with the 
 *    whole piece of memory-- which allows us to easily transmit these states.
 *  - A bitfield structure, which allows us to actually create variables which are
 *    smaller than a byte! Note that, since the AVR CPU doesn't directly support
 *    addressing values that aren't smaller than a byte (with limited exception),
 *    the C compiler will actually automatically create the masking code _for_ you.
 */ 
union board_state_union {

  //
  // The main data structure for the board's state. 
  // This breaks the whole bit-field down into easily accessible pieces.
  //
  struct {
    // The unique ID number for this beacon.
    //
    // A beacon value of zero means that this beacon has not yet been assigned an 
    // ID by its host, and a beacon value of 31 (all 1's) is prohibited, to ensure
    // that this value is always distinguishable from the sync byte. Any other 
    // value is a defined beacon ID.
    unsigned id : 5; 

    // The affiliation of the beacon. 
    // This indicates which side of the board the beacon is on:
    //
    // 0 = Green robot side,
    // 1 = Red robot side
    BoardAffiliation affiliation : 1;

    // Indicates which team currently owns the beacon, if any.
    //
    // 0 = Green robot owns the beacon.
    // 1 = Red robot owns the beacon.
    // 2 = Neither robot owns the beacon.
    BoardOwner owner : 2;
  };

  // An equivalent representation of the same memory,
  // which allows the whole packed bitfield to be accessed as a whole, 
  // e.g. for sending to a host PC.
  uint8_t raw_data;

};

typedef union board_state_union BoardState;

#endif
