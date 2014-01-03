#!/usr/bin/env ruby

require 'mechanize'
require 'csv'

#
# Generic method which requests information for a given supplier.
#
def info_for_supplier(supplier, supplier_part_number, manufacturer_part_number=nil, quantity=nil)
  send("info_for_#{supplier.downcase}", supplier_part_number, manufacturer_part_number, quantity)
end


#
# Get information about the given Digi-key part number.
#
def info_for_digikey(part_number, manufacturer_part_number=nil, quantity=nil)
 
  #Fetch the Digi-key page for the given part number.
  page = if manufacturer_part_number
     Mechanize.new.get("http://www.digikey.com/product-detail/en/#{manufacturer_part_number}/#{part_number}")
  else
     Mechanize.new.get("http://search.digikey.com/scripts/DkSearch/dksus.dll?lang=en&site=US&x=0&y=0&keywords=#{part_number}")
  end

  #Get the quantity of the part in stock.
  quantity_in_stock = page.search('//*[@id="quantityavailable"]/text()[1]').text.split.last || '-1'
  quantity_in_stock = quantity_in_stock.gsub(',', '').to_i

  #Get the quantity available.
  { :stock => quantity_in_stock }

end

#
# Get information about the given Digi-key part number.
#
def info_for_newark(part_number, manufacturer_part_number=nil, quantity=nil)
 
  #Fetch the Digi-key page for the given part number.
  page = Mechanize.new.get("http://www.newark.com/#{part_number}")

  #Get the quantity available.
  { :stock =>  page.search('//*[@id="priceWrap"]/div[1]/div/p/text()').text.split.last.to_i }

end

#
# Ret
# 
def to_price_break_quantity(quantity)
  quantity
end

#
# Get information about a given sparkfun part number.
#
def info_for_sparkfun(part_number, manufacturer_part_number=nil, quantity=nil)

  #Apply a heuristic to convert SFE part numbers to URLs.
  part_number = part_number.gsub(/COM-0/, '')
  part_number.strip!

  #Fetch the Digi-key page for the given part number.
  page = Mechanize.new.get("https://www.sparkfun.com/products/#{part_number}")

  #Return the disabled stock.
  { :stock => page.search('//*[@id="quantity-discounts"]/table/tr[2]/td[2]').text.split.first.to_i }

end

#Main "stock verification" code.
unless ARGV[0]
  puts "Usage: #{$0} <bill_of_materials_csv>"
  exit
end

#Parse the provided CSV file.
CSV.foreach(ARGV[0], :headers => true) do |row|

  #Skip any parts which don't have an explicit supplier.
  next unless row["Supplier P/N"] and row["Manufacturer P/N"]

  #Convert the provided quantity to a price-break quantity.
  quantity = to_price_break_quantity(row["Qty to Purchase"].to_i)

  #Get infor for the given part.
  info = info_for_supplier(row["Supplier"], row["Supplier P/N"], row["Manufacturer P/N"], quantity)

  #If there's insufficient stock, throw a warning!
  if row["Qty to Purchase"].to_i > info[:stock]
    puts "WARNING: Insufficient stock of #{row["Manufacturer P/N"]} at #{row["Supplier"]}. Only #{info[:stock]} of the needed #{row["Qty to Purchase"]} are available."
  end

end
