#!/usr/bin/ruby
require_relative 'tools'

log_dir = 'logs'
  instance = 'b100ed6e-c783-4176-81ea-069c35b6d3ca'

aname = File.join(__dir__,log_dir,instance + '.shift.json')
bname = File.join(__dir__,log_dir,instance + '.branches.json')
xname = File.join(__dir__,log_dir,instance + '.xes.yaml')

p CPEE::Shifting::generate_shifted_log(aname,bname,xname)
