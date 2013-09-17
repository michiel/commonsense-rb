#!/usr/bin/env ruby

require 'commonsense/sense-ng'

@sense = Commonsense::SenseNG.new
@sense.verbose = true
@sense.set_server :live
@sense.login(ENV['SENSE_USER'], ENV['SENSE_PASS'])

[:sensors, :domains, :groups].each do |type|
  res = @sense.get_all(type)
  items = res[type.to_s]
  puts "#{items.size} elements of type #{type}"
  puts "Fetching eatch item (if any) individually..."
  items.each do |item|
    @sense.get(type, item['id'])
  end
end


