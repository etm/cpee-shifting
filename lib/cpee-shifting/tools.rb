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

class TInfo #{{{
  attr_accessor :shift_start, :shift_duration
  attr_reader :id, :uuid, :start, :end, :duration
  def initialize(id,uuid)
    @id = id
    @uuid = uuid
    @start = nil
    @end = nil
    @duration = 0
    @shift_start = nil
    @shift_duration = 0
  end

  def finished?
    @shift_start && @shift_duration
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
    tend = finished? ? (@shift_start + @shift_duration).xmlschema(2)[8..-7] : 0
    ss =  @shift_start&.xmlschema(2)[8..-7] rescue nil
    '<%s: %s,%s,%s>' % [@id,ss,@shift_duration.to_s,tend]
  end

  def shift_end
    finished? ? @shift_start + @shift_duration : nil
  end
end #}}}

module CPEE
  module Shifting
    def self::rec_clean(traces) #{{{
      traces.delete_if do |t|
        if t.is_a? Array
          Shifting::rec_clean(t)
          false
        elsif t.is_a? String
          true
        else
          false
        end
      end
    end #}}}

    def self::init_time(fragment,start,shift) #{{{
      fragment.each do |f|
        if f.is_a? Array
          Shifting::init_time(f,start,shift)
        else
          fact = ChronicDuration::parse(start['factor'],:keep_zero => true)
          f.shift_start = Chronic::parse(start['start']) + fact * start['modifier'].to_f
          f.shift_duration = f.duration * fact
          if shift[f.id] && shift[f.id]['type'] == 'Ends'
            # puts f.id + ': ' + shift[f.id]['expression']
            duration = Chronic::parse(shift[f.id]['expression'], :now => f.shift_start) - f.shift_start
            f.shift_duration = duration < 0 ? 0 : duration
          end
          if shift[f.id] && shift[f.id]['type'] == 'Duration'
            # puts f.id + ': ' + shift[f.id]['expression']
            f.shift_duration = ChronicDuration.parse(shift[f.id]['expression'], :keep_zero => true)
          end
          return
        end
      end
    end #}}}

    def self::rec_shift(traces,shift,factor,endtimes=nil,top=true) #{{{
      endtimescoll = []
      traces.each do |f|
        if f.is_a? Array
          if top
            endtimes = Shifting::rec_shift(f,shift,factor,endtimes,false) # on the highest level it is all a sequence, all sublevels are parallels?
          else
            endtimescoll << Shifting::rec_shift(f,shift,factor,endtimes,false) # we need to save the endtimes of all branches on order to find the max
          end
        else
          if f.finished?
            endtimes = f.shift_end
          else
            f.shift_start = endtimes
            f.shift_duration = f.duration * factor
            if shift[f.id] && shift[f.id]['type'] == 'Ends'
              # puts f.id + ': ' + shift[f.id]['expression']
              duration = Chronic::parse(shift[f.id]['expression'], :now => endtimes) - f.shift_start
              f.shift_duration = duration < 0 ? 0 : duration
            end
            if shift[f.id] && shift[f.id]['type'] == 'Duration'
              # puts f.id + ': ' + shift[f.id]['expression']
              f.shift_duration = ChronicDuration.parse(shift[f.id]['expression'], :keep_zero => true)
            end
            endtimes = f.shift_end
          end
        end
      end
      endtimes = endtimescoll.max if endtimescoll.any?
      endtimes
     end #}}}

    def self::generate_shifted_log(aname,bname,xname)
      shifts =  JSON::load(File.open(aname))
      branches = JSON::load(File.open(bname)) rescue []
      nname = xname.sub(/\.xes\./,'.xes.shift.')

      events = {}
      YAML::load_stream(File.read(xname)) do |e| #{{{
        if e['event']
          if e['event']['cpee:lifecycle:transition'] == 'activity/calling'
            events[e['event']['cpee:activity_uuid']] ||= TInfo.new(e['event']['id:id'],e['event']['cpee:activity_uuid'])
            events[e['event']['cpee:activity_uuid']].start = Time.parse(e['event']['time:timestamp'])
          elsif e['event']['cpee:lifecycle:transition'] == 'activity/done'
            events[e['event']['cpee:activity_uuid']] ||= TInfo.new(e['event']['id:id'],e['event']['cpee:activity_uuid'])
            events[e['event']['cpee:activity_uuid']].end = Time.parse(e['event']['time:timestamp'])
          end
        end
      end #}}}

      events.sort_by{|k,v| v.start}.to_h
      cs = Chronic::parse(shifts['start']['start'])
      cf = ChronicDuration::parse(shifts['start']['factor'], :keep_zero => true)
      csm = shifts['start']['modifier'].to_f

      traces = []
      laststate = :sequence
      events.each do |k,v|
        # add branches to traces tree
        branches.each do |b|
          b.each do |bid,bra|
            if bra.include? v.id
              traces.append(b.map{|tbid,tbra|tbra})
              branches.delete b
              laststate = :parallel
            end
          end
        end
        # search through last entry in traces tree
        if laststate == :parallel
          found = false
          traces.last.each do |b|
            if b.include? v.id
              b.append v
              found = true
            end
          end
          unless found
            traces << []
            laststate = :sequence
            traces.last.append v
          end
        else
          traces << [] unless traces.last
          traces.last.append v
        end
      end

      Shifting::rec_clean(traces) # remove string

      Shifting::init_time(traces[0],shifts['start'],shifts)
      Shifting::rec_shift(traces,shifts,ChronicDuration::parse(shifts['start']['factor'],:keep_zero => true))

      # print out before flatten so see the fragments
      traces.flatten!

      //pp traces

      YAML::load_stream(File.read(xname)) do |e|
        if e['log']
          e.dig('log','extension')['shift'] = 'https://cpee.org/time-shifting/time-shifting.xesext'
          File.open(nname,'w') do |f|
            f << e.to_yaml
          end
        elsif e['event']
          if e['event']['cpee:lifecycle:transition'] == 'activity/calling'
            uuid = e['event']['cpee:activity_uuid']
            e['event']['shift:timestamp'] = traces.find{|t| t.uuid == uuid}&.shift_start.xmlschema(2)
            File.open(nname,'a') do |f|
              f << e.to_yaml
            end
          elsif e['event']['cpee:lifecycle:transition'] == 'activity/done'
            uuid = e['event']['cpee:activity_uuid']
            e['event']['shift:timestamp'] = traces.find{|t| t.uuid == uuid}&.shift_end.xmlschema(2)
            File.open(nname,'a') do |f|
              f << e.to_yaml
            end
          else
            File.open(nname,'a') do |f|
              f << e.to_yaml
            end
          end
        end
      end
      nname
    end
  end
end
