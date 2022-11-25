#!/usr/bin/ruby
require_relative 'tools'

log_dir = 'logs'
  instance = 'f9a22df6-7c78-4c44-b757-1de78c578757'

aname = File.join(__dir__,log_dir,instance + '.shift.json')
bname = File.join(__dir__,log_dir,instance + '.branches.json')
xname = File.join(__dir__,log_dir,instance + '.xes.yaml')

p CPEE::Shifting::generate_shifted_log(aname,bname,xname)
