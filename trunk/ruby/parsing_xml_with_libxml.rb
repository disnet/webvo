require 'rubygems' # if installed via Gems
require_gem 'xml/libxml', ">=0.3.8"

puts "here"
doc = XML::Document.new()
doc.root = XML::Node.new('root_node')
root = doc.root

root << elem1 = XML::Node.new('elem1')
elem1['attr1'] = 'val1'
elem1['attr2'] = 'val2'

root << elem2 = XML::Node.new('elem2')
elem2['attr1'] = 'val1'
elem2['attr2'] = 'val2'

root << elem3 = XML::Node.new('elem3')
elem3 << elem4 = XML::Node.new('elem4')
elem3 << elem5 = XML::Node.new('elem5')

elem5 << elem6 = XML::Node.new('elem6')
elem6 << 'Content for element 6'

elem3['attr'] = 'baz'

# Namespace hack to reduce the numer of times XML:: is typed
#include XML
#root << elem7 = Node.new('foo')
#1.upto(10) do |i|
#elem7 << n = Node.new('bar')
#n << i
#end

format = true
doc.save('output2.xml', format)