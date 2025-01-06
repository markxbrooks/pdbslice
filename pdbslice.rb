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


if ARGV.empty?
  puts "Missing arguments"
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
def download_pdb_file(infile, infilebase)
  puts "Attempting to download #{infile} from RCSB.org..."
  system "curl \"https://files.rcsb.org/download/#{infilebase}.pdb\" -o #{infilebase}.pdb"
  if File.exist?(infile)
    puts "Download complete of #{infile}"
    true
  else
    puts "Could not find file at RCSB.org"
    false
  end
end

if !File.exist?(infile)
  exit unless download_pdb_file(infile, infilebase)
end

if File.exist?(infile)
  begin
    file = File.new(infile).gets(nil)
    structure = Bio::PDB.new(file)
    
    fragment, suffixout = process_structure(structure, chain, first, last, sequence, delete)
    
    outfile ||= "#{infilebase}-#{chain}#{firstname}#{lastname}#{suffixout}"
    File.write(outfile, fragment)
    puts "Writing result to: #{outfile}"
  rescue => e
    puts "Error processing PDB file: #{e.message}"
    exit 1
  end
else
  puts "File #{infile} not found"
  system "curl \"https://files.rcsb.org/download/#{infilebase}.pdb\" -o #{infilebase}.pdb"
end

def process_structure(structure, chain, first, last, sequence, delete)
  if sequence
    fragment = ">#{infilebase} #{structure[nil][chain].aaseq.molecular_weight.round} Da\n#{structure[nil][chain].aaseq}"
    [fragment, ".pir"]
  else
    fragment = if delete
      structure[nil][chain].map { |residue| 
        residue.to_s unless residue.residue_id.to_i.between?(first, last)
      }.compact.join
    else
      structure[nil][chain].map { |residue| 
        residue.to_s if residue.residue_id.to_i.between?(first, last)
      }.compact.join
    end
    [fragment, ".pdb"]
  end
end

