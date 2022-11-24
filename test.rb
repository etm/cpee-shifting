#!/usr/bin/ruby
require_relative 'tools'

log_dir = 'logs'
instance = '295d096e-197f-4842-989f-fbc5611d1769'

aname = File.join(__dir__,log_dir,instance + '.shift.json')
bname = File.join(__dir__,log_dir,instance + '.branches.json')
xname = File.join(__dir__,log_dir,instance + '.xes.yaml')

CPEE::Shifting::generate_shifted_log(aname,bname,xname)


