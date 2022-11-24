#!/usr/bin/ruby
#
# This file is part of CPEE-SHIFTING.
#
# CPEE-SHIFTING is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# CPEE-SHIFTING is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with CPEE-SHIFTING (file COPYING in the main directory). If not, see
# <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'yaml'
require 'json'
require 'time'
require 'chronic'
require 'chronic_duration'

class TInfo
  attr_accessor :shift_start, :shift_duration
  attr_reader :id, :start, :end, :duration
  def initialize(id)
    @id = id
    @start = nil
    @end = nil
    @duration = nil
    @shift_start = nil
    @shift_duration = nil
  end

  def start=(val)
    @start = val
    if @end
      @duration = @end - @start
    end
  end
  def end=(val)
    @end = val
    if @start
      @duration = @end - @start
    end
  end
  def inspect
    "<%s: %s,%s,%s,%s>" % [@id,@start.xmlschema(3),@duration,@shift_start&.xmlschema(3),@shift_duration.to_s]
  end
end

module CPEE
  module Shifting
    def self::generate_shifted_log(aname,bname,xname)
      shifts =  JSON::load(File.open(aname))
      branches = JSON::load(File.open(bname))
      nname = xname.sub(/\.xes\./,'.xes.shift.')

      events = {}
      YAML::load_stream(File.read(xname)) do |e|
        if e['log']
          File.open(nname,'w') do |f|
            f << e.to_yaml
          end
        elsif e['event']
          if e['event']['cpee:lifecycle:transition'] == 'activity/calling'
            events[e['event']['cpee:activity_uuid']] ||= TInfo.new(e['event']['id:id'])
            events[e['event']['cpee:activity_uuid']].start = Time.parse(e['event']['time:timestamp'])
          elsif e['event']['cpee:lifecycle:transition'] == 'activity/done'
            events[e['event']['cpee:activity_uuid']] ||= TInfo.new(e['event']['id:id'])
            events[e['event']['cpee:activity_uuid']].end = Time.parse(e['event']['time:timestamp'])
          end
        end
      end


      events.sort_by{|k,v| v.start}.to_h
      cs = Chronic::parse(shifts['start']['start'])
      cf = ChronicDuration::parse(shifts['start']['factor'], :keep_zero => true)
      csm = shifts['start']['modifier'].to_f

      p events.first
      events.first.shift_start = cs + cf * csm
      events.first.shift_duration = events[0].duration * csm
      pp events
    end
  end
end
