#
# The MIT License (MIT)
# 
# Copyright (c) 2014 Kyle J. Temkin <ktemkin@binghamton.edu>
# Copyright (c) 2014 Binghamton University
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'jd_beacon'

describe JDBeacon::Competition do

  subject { JDBeacon::Competition.new }

  describe "#initiate_beacon_connections" do

    let(:connections) { subject.send(:initiate_beacon_connections) }
    
    it "should return an array of beacon connections" do
      expect(connections).to be_a Array
      expect(connections.count.zero?).to be_false
      connections.each { |element| expect(element).to be_a JDBeacon::Board }
    end

  end

  describe "#create_paired_connections" do

    it "should populate @board_pairs with sets of hashes, each containing a red and green beacon" do
      subject.send(:create_paired_connections)

      subject.board_pairs.each do |pair|
        expect(pair).to include :red
        expect(pair).to include :green
        expect(pair[:red]).to be_a JDBeacon::Board
        expect(pair[:green]).to be_a JDBeacon::Board
      end
    end



  end
 

end
