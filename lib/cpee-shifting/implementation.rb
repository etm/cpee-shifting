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
require 'riddl/server'
require 'weel'
require 'json'
require_relative 'tools'

module CPEE
  module Shifting

    SERVER = File.expand_path(File.join(__dir__,'shifting.xml'))

    def self::extract_annotation(activity,xml)
      ret = {}
      XML::Smart::string(xml) do |doc|
        doc.register_namespace 'd', 'http://cpee.org/ns/description/1.0'
        ret = { activity => {} }
        if activity == 'start'
          ret[activity]['factor'] = doc.find('string(//d:_shifting_factor)') if doc.find('string(//d:_shifting_factor)').strip != ''
          ret[activity]['start'] = doc.find('string(//d:_shifting_start)')  if doc.find('string(//d:_shifting_start)').strip != ''
          ret[activity]['modifier'] = doc.find('string(//d:_shifting_modifier)') if doc.find('string(//d:_shifting_modifier)').strip != ''
        else
          if doc.find('string(//d:_shifting_expression)').strip != ''
            ret[activity]['type'] = doc.find('string(//d:_shifting_type)')
            ret[activity]['expression'] = doc.find('string(//d:_shifting_expression)')
          end
        end
      end
      ret[activity].any? ? ret : {}
    end

    class Handler < Riddl::Implementation
      def response
        opts       = @a[0]
        type       = @p[0].value
        topic      = @p[1].value
        event_name = @p[2].value
        payload    = @p[3].value.read

        notification = JSON.parse(payload)
        instance = notification['instance-uuid']
        return unless instance

        instancenr = notification['instance']
        content    = notification['content']
        activity   = content['activity']

        log_dir = opts[:log_dir]

        aname = File.join(log_dir,instance + '.shift.json')
        bname = File.join(log_dir,instance + '.branches.json')
        xname = File.join(log_dir,instance + '.xes.yaml')

        if topic == 'annotation' and event_name == 'change'
          ret = content['annotation'] ? CPEE::Shifting::extract_annotation(activity,content['annotation']) : {}
          if ret.any?
            dname = File.join(log_dir,instance + '.data.json')
            shifting = if File.exist?(aname)
              JSON::parse(File.read(aname))
            else
              {}
            end
            ['start','modifier','expression'].each do |e|
              if ret[activity][e] && ret[activity][e][0] == '!'
                rs = WEEL::ReadStructure.new(File.exist?(dname) ? JSON::load(File::open(dname)) : {},{},{},{})
                ret[activity][e] = rs.instance_eval(ret[activity][e][1..-1],'e',1)
              end
            end
            shifting.merge!(ret)
            File.write(aname,JSON::pretty_generate(shifting))
          end
        end
        if topic == 'state' and event_name == 'change'
          if content['state'] == 'finished' && File.exist?(aname)
            EM.defer do
              Shifting::generate_shifted_log(aname,bname,xname)
            end
          end
        end

        if topic == 'gateway' and event_name == 'join'
          ret = content['branches']
          if ret && ret.any?
            branches = if File.exist?(bname)
              JSON::parse(File.read(bname))
            else
              []
            end
            branches.append(ret)
            File.write(bname,JSON::pretty_generate(branches))
          end
        end

        nil
      end
    end

    def self::implementation(opts)
      opts[:log_dir] ||= File.expand_path(File.join(__dir__,'logs'))

      Proc.new do
        interface 'events' do
          run Handler, opts if post 'event'
        end
      end
    end

  end
end
