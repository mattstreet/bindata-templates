require 'bindata'

class RecSize < BinData::Record
  endian :little
  uint16 :width
  uint16 :height
end

class Rectangle < BinData::Record
  endian :little
  uint16 :len, :value => lambda { name.length } 
  string :name, :read_length => :len
  RecSize :r_size
end

def read(filename)
  io = File.open(filename)
  r = Rectangle.read(io)
  puts "Rectangle #{r.name} is #{r.r_size.width} x #{r.r_size.height}"
end

def create(filename,name=nil,width=nil,height=nil)
  io = File.open(filename,'w+')
  r = Rectangle.new()
  s = RecSize.new()
  r.name   = name             ||= "TEST"
  s.width  = width            ||= 100
  s.height = height           ||= 200
  r.r_size = s
  r.write(io)
  io.close()
end

class Main < Rectangle
end
#create
#read
