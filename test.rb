#!/usr/bin/ruby
require_relative 'tools'

log_dir = 'logs'
instance = '05366221-e3a1-4ef3-b746-159b55497bf2'

aname = File.join(__dir__,log_dir,instance + '.shift.json')
bname = File.join(__dir__,log_dir,instance + '.branches.json')
xname = File.join(__dir__,log_dir,instance + '.xes.yaml')

CPEE::Shifting::generate_shifted_log(aname,bname,xname)


