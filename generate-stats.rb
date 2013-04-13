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

require "rubygems"
require "date"
require "json"
require "yaml"

# Load the configuration file.
config = YAML.load_file('config.yml')

# Generate the CVS history log.
# logfile = File.open("logfile.txt", "r")
if config["server"] == "localhost" || config["server"] == "127.0.0.1" || config["server"].empty?
   logfile = `cd #{config["repo_path"]} && cvs history -a -x AM -D #{Date.today-6}"`.split("\n")
else
   logfile = `ssh #{config["server"]} "cd #{config["repo_path"]} && cvs history -a -x AM -D #{Date.today-6}"`.split("\n")
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
   days[date] = Integer(days[date]) + 1
}

# Create the Status Board JSON.
output = {
   "graph" => {
      "title" => "Commits Per Day",
      "datasequences" => [
         "title" => config["title"],
         "color" => config["color"],
         "datapoints" => Array.new(days.length) { |i|
            {
               # I prefer seeing a day name, but you could do the month and day instead.
               # "title" => Date.parse(days.keys[i]).strftime("%b %d"),
               "title" => Date.parse(days.keys[i]).strftime("%a %d"),
               "value" => days.values[i]
            }
         }.sort_by { |o|
            o["title"].split(%r/\s+/)[1]
         }
      ]
   }
}

# Save the file
File.open(File.expand_path("#{config["export_path"]}/commits_per_day.json"), "w+") { |file|
   file.write(
      JSON.pretty_generate(output)
   )
}