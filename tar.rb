#!/usr/bin/env ruby
require 'bindata'

=begin
Field Offset  Field Size  Field
0   100   File name
100   8   File mode
108   8   Owner's numeric user ID
116   8   Group's numeric user ID
124   12  File size in bytes (Numerics are stored as octal ASCII)
136   12  Last modification time in numeric Unix time format
148   8   Checksum for header block
156   1   Link indicator (file type)
157   100   Name of linked file

USTAR extention
Field Offset  Field Size  Field
0   156   (as in old format)
156   1   Type flag
157   100   (as in old format)
257   6   UStar indicator "ustar"
263   2   UStar version "00"
265   32  Owner user name
297   32  Owner group name
329   8   Device major number
337   8   Device minor number
345   155   Filename prefix
=end

class PaddedString < BinData::String
  default_parameters :pad_byte => "\0"
end

class TarHeader < BinData::Record
  string :name,     :length => 100  #name of file
  string :mode,     :length => 8    #file mode
  string :uid,      :length => 8    #owner user ID
  string :gid,      :length => 8    #owner group ID
  string :file_size_raw,:length => 12   #length of file in bytes
  string :mtime,    :length => 12   #modify time of file
  string :chksum,   :length => 8    #checksum for header
  string :link,     :length => 1    #indicator for links
  string :linkname, :length => 100  #name of linked file 

  def file_size
    # Change an octal ASCII string to an int
    self.file_size_raw.to_i(8)
  end

  def file_size=(v)
    # Change an int into an octal ASCII NULL terminated string and padded it out with 0's 
    raw = v.to_s(8)
    leading_zeros = "0" * [11,11 - raw.length].min
    self.file_size_raw = leading_zeros + raw + "\0"
  end
end

class USTARHeader < BinData::Record
  string :ustar_version, :length => 2 #"00"
  string :owner_user_name, :length => 32
  string :owner_group_name, :length => 32
  string :device_major_number, :length => 8
  string :device_minor_number, :length => 8
  PaddedString :filename_prefix, :length => 155
  string :padding, :length => 12, :pad_byte => "\0"
end

class TarFile < BinData::Record
  TarHeader :header
  string :ustar_indicator, :length => 6 #"ustar"
  choice :ustar_header, :selection => lambda { ustar_indicator.include? "ustar" } do
    USTARHeader true
    string false, :length => 225
  end
  string :file, :length => lambda { header.file_size }
  string :padding, :length => lambda { ((file.length / 512.0).ceil * 512) - file.length } 
end

class Tar < BinData::Record
  array :files, :type => TarFile, :initial_length => 1
end

io = File.open(ARGV[0])
tar = Tar.read(io).files[0]
puts tar.header.file_size
tar.header.file_size = 500
print tar.header.file_size_raw.inspect
