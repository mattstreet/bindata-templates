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

class TarHeader < BinData::Record
  string :name,     :length => 100  #name of file
  string :mode,     :length => 8    #file mode
  string :uid,      :length => 8    #owner user ID
  string :gid,      :length => 8    #owner group ID
  string :file_size,     :length => 12   #length of file in bytes
  string :mtime,    :length => 12   #modify time of file
  string :chksum,   :length => 8    #checksum for header
  string :link,     :length => 1    #indicator for links
  string :linkname, :length => 100  #name of linked file 
end

class USTARHeader < BinData::Record
  string :ustar_version, :length => 2 #"00"
  string :owner_user_name, :length => 32
  string :owner_group_name, :length => 32
  string :device_major_number, :length => 8
  string :device_minor_number, :length => 8
  string :filename_prefix, :length => 155
  skip :length => 12
end

class TarFile < BinData::Record
  TarHeader :header
  string :ustar_indicator, :length => 6 #"ustar"
  choice :ustar_header, :selection => lambda { ustar_indicator.include? "ustar" } do
    USTARHeader true
    skip false, :length => 225
  end
  string :file, :length => lambda { header.file_size.to_i(8) }
  skip :length => lambda { ((file.length / 512.0).ceil * 512) - file.length } 
end

class Tar < BinData::Record
  #TarFile :tarfile
  array :files, :type => TarFile, :initial_length => 1
end

io = File.open(ARGV[0])
tar = Tar.read(io)
puts tar

