require 'sequel'
require 'redcloth'

def sort_2_booleans one, other
  if one != other
    sort = -1 if one
    sort = 1  if other
  else
    sort = 0
  end
  sort
end

def sort_2_columns one, other
  attrs1, attrs2 = one[1], other[1]
  sort = sort_2_booleans one[1][:primary_key], other[1][:primary_key]
  sort = sort_2_booleans other[1][:allow_null], one[1][:allow_null] if sort == 0
  sort = one[0] <=> other[0] if sort == 0
  sort
end

def textile_for_column column, dataset
  column_descr = "|*#{column[0]}*|"
  attrs = column[1]
  column_descr << "|#{attrs[:type]}|"
  column_descr << ' pk ' if attrs[:primary_key]
  column_descr << ' null allowed ' if attrs[:allow_null]
  column_descr << "|"
  dataset.each { |one_piece| 
    column_descr << one_piece[column[0]].to_s << '|' 
  }
  column_descr << "\n"
end

def convert_textile_to_html source_file, target_file
  textile_file = File.open source_file
  content = textile_file.read
  textile_file.close
  
  html = RedCloth.new( content ).to_html
  html_file = File.open target_file, 'w'
  html_file.write html
  html_file.close
end

raise "usage run.sh db_url target_dir" if(ARGV.length < 2) 
DB = Sequel.connect ARGV[0]
target_dir = ARGV[1]

overview = File.open target_dir + '/index.textile', 'w'
overview.write "h1. All tables\n\n"

puts "reading database"
tables = DB.tables
tables.sort!

puts "generating textile"
tables.each do |t|
  overview.write "\"#{t}\":#{t}.html\n"  # "tablename":/tablename.html

  detail = File.open "#{target_dir}/#{t}.textile", 'w'
  detail.write "h1. #{t.to_s}\n\n"
  
  schema = DB.schema t

  schema.sort! { |c1, c2| sort_2_columns c1, c2 }

  first_ten = DB[t].reverse.first(10)  
  schema.each { |c| detail.write( textile_for_column c, first_ten ) }
  
  detail.close
  print '.'
end

overview.close

puts "\nconverting to html"

textiles = Dir.new( target_dir ).select {|filename| filename.end_with? 'textile'}

textiles.each do |one_file|
  source_file = "#{target_dir}/#{one_file}"
  target_file = "#{target_dir}/#{one_file.split('.')[0]}.html"
  
  convert_textile_to_html source_file, target_file
end
