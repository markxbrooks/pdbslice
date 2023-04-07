#!/usr/bin/env ruby
# == Synopsis
#
#  Script to generate subfragments from a PDB file
#
# == Usage
#
#  pdbslice.rb -i <infile> -b [beginning_residue] -e [last_residue] -c [chain] -o <outfile>
#
# -h, --help:       show help       (Optional)
#
# --infile, -i      Name of the input file  (Required)
#
# --outfile, -o     Name of the output file (Optional)
# Default:    infile-chain-begin-end.pdb
# --begin, -b       Beginning position    (Optional)
# Default:      1
# --end, -e         End position    (Optional)
# Default:    10000
# --chain, -c       Chain identifier    (Optional)
#   Default:    Chain A
# --delete, -d      Delete section of sequence? (true/false) (Optional)
#       Default:    False
# --sequence, -s    Output sequence?            (true/false) (Optional)
#       Default:    False

require 'rubygems'
require 'getoptlong'
require 'bio'


# https://stackoverflow.com/questions/846923/replacement-for-rdoc-usage
module BB
    def BB::usage( exit_code )
        File::open( $0, 'r').readlines.each_with_index do | line, idx |
            next if idx == 0
            if( line =~ /^#/ )
                puts line.gsub(/^#\ ?/,'')
            else
                puts #RDoc adds extra line so we do too
                exit( exit_code )
            end
        end
    end
end


if ( (ARGV.length != 4) && (ARGV.length != 6) && (ARGV.length != 8) && (ARGV.length != 10))
  puts ARGV.length.to_s + " args"
  puts "Missing argument(s)"
     BB::usage(-1)
end


opts = GetoptLong.new(
  ['--infile',     '-i',   GetoptLong::REQUIRED_ARGUMENT],
  ['--outfile',    '-o',   GetoptLong::OPTIONAL_ARGUMENT],
  ['--begin',      '-b',   GetoptLong::OPTIONAL_ARGUMENT],
  ['--end',        '-e',   GetoptLong::OPTIONAL_ARGUMENT],
  ['--chain',      '-c',   GetoptLong::OPTIONAL_ARGUMENT],
  ['--delete',     '-d',   GetoptLong::OPTIONAL_ARGUMENT],
  ['--sequence',   '-s',   GetoptLong::OPTIONAL_ARGUMENT],
  ['--help',       '-h',   GetoptLong::NO_ARGUMENT]
)


infile = nil
outfile = nil
sequence = nil
delete = nil
chain = "A"
first = 1
last = 100000
opts.each do |opt, arg|
  case opt
  when '--help'
    exit
    #   RDoc::usage
  when '--infile'
    infile = arg.to_s
  when '--outfile'
    outfile = arg.to_s
  when '--begin'
    first = arg.to_i
  when '--end'
    last = arg.to_i
  when '--chain'
    chain = arg.to_s
  when '--delete'
    delete = arg.to_s
  when '--sequence'
    sequence = arg.to_s
  end
end
if (first != 1)
  firstname =  "-" + first.to_s
else
  firstname = ""
end
if (last != 100000)
  lastname  =  "-" + last.to_s
else
  lastname = ""
end

infilebase = infile.gsub('.pdb','')
if File.exists?(infile)
  puts "Found file"
else
  system "wget \"http://www.rcsb.org/pdb//cgi/export.cgi/#{infilebase}.pdb.gz?format=PDB&pdbId=#{infilebase}&compression=gz\" -O #{infilebase}.pdb.gz"
  if File.exists?("#{infilebase}.pdb.gz")
    system "gunzip #{infilebase}.pdb.gz"
  else
    puts "Could not find file at RCSB.org"
  end
end
if File.exists?(infile)
  file = File.new(infile).gets(nil)
  structure = Bio::PDB.new(file)
  fragment = ""
  if (sequence)
    #This choice for outputting sequence
    fragment = ">#{infilebase} "+ structure[nil][chain].aaseq.molecular_weight.round.to_s + " Da\n" + structure[nil][chain].aaseq
    suffixout = ".pir"
  else
    #Here for writing coordinates
    if (delete)
      puts "delete mode\n"
      #if chain
      structure[nil][chain].each {|residue| fragment << residue.to_s unless residue.residue_id.to_i.between?(first,last)}
      #else
      #  structure[nil][nil].each {|residue| fragment << residue.to_s unless residue.residue_id.to_i.between?(first,last)}
      #end
    else
      structure[nil][chain].each {|residue| fragment << residue.to_s if residue.residue_id.to_i.between?(first,last)}
    end
    suffixout = ".pdb"
  end
  outfile ||= infilebase + "-" + chain + firstname + lastname + suffixout
  outFh = File.new(outfile, 'w')
  puts "Writing result to: #{outfile}"
  outFh.puts fragment
  outFh.close
else
  #system "wget \"http://www.rcsb.org/pdb//cgi/export.cgi/#{infilebase}.pdb.gz?format=PDB&pdbId=#{infilebase}&compression=gz\" -O #{infilebase}.pdb.gz"
  #system "gunzip #{infilebase}.pdb.gz"
  #puts "File #{infile} not found"
end
