#!/usr/bin/env ruby
#
# Copyright (c) 2013 Matthew Price, http://mattprice.me/
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

require 'rubygems'
require 'date'
require 'json'
require 'yaml'

# Load the configuration file.
config = YAML.load_file('config.yml')

# Generate the CVS history log.
# logfile = File.open("logfile.txt", "r")
if config['server'] == 'localhost' || config['server'].empty?
   logfile = `cd #{config['repo_path']} && cvs history -a -x AM -D #{Date.today-6}`.split("\n")
else
   logfile = `ssh -o ConnectTimeout=10 #{config['server']} "cd #{config['repo_path']} && cvs history -a -x AM -D #{Date.today-6}"`.split("\n")
end

# Prefill the days array. This is incase you have days with no commits.
days = {}
for i in 0..6
   days["#{Date.today - i}"] = 0
end

# Loop through each log entry.
logfile.each { |entry|
   entry = entry.split(%r/\s+/)
   date = entry[1]

   # Our prefilled days hash contains the only dates we want.
   # Ignore any other dates that `cvs history` returned or this will error.
   if days.has_key?(date)
      days[date] = Integer(days[date]) + 1
   end
}

# Create the Status Board JSON.
output = {
   'graph' => {
      'title' => '',
      'datasequences' => [
         'title' => config['daily']['title'],
         'color' => config['daily']['color'],
         'datapoints' => Array.new(days.length) { |i|
            {
               # I prefer seeing a day name, but you could do the month and day instead.
               # 'title' => Date.parse(days.keys[i]).strftime('%b %d'),
               'title' => Date.parse(days.keys[i]).strftime('%a %d'),
               'value' => days.values[i],

               # This is a total hack for getting Ruby to sort the dates correctly.
               # Status Board doesn't use it.
               'sort_by' => days.keys[i]
            }
         }.sort_by { |o|
            o['sort_by']
         }
      ]
   }
}

# Save the file
File.open(File.expand_path("#{config['export_path']}/#{config['daily']['file']}"), 'w+') { |file|
   file.write(
      JSON.pretty_generate(output)
   )
}