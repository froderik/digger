require 'sequel'
require 'redcloth'

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
  schema.sort! do |c1, c2|
    if c1[1][:primary_key] != c2[1][:primary_key]
      sort = -1 if c1[1][:primary_key]
      sort = 1  if c2[1][:primary_key]
    else
      sort = 0
    end
    if c1[1][:allow_null] != c2[1][:allow_null]
      sort = 1  if c1[1][:allow_null]
      sort = -1 if c2[1][:allow_null]
    else
      sort = 0
    end
    if sort == 0
      sort = c1[0] <=> c2[0]
    end
    sort
  end
  schema.each do |c|
    detail.write "|*#{c[0]}*|"
    attrs = c[1]
    detail.write "|#{attrs[:type]}|"
    detail.write ' pk ' if attrs[:primary_key] #== 'true'
    detail.write ' null allowed ' if attrs[:allow_null] #== 'true'
    detail.write "|\n"
    print '.'
  end
  
  detail.close
end

overview.close

puts "\nconverting to html"

textiles = Dir.new( target_dir ).select {|filename| filename.end_with? 'textile'}

textiles.each do |one_file|
  textile_file = File.open "#{target_dir}/#{one_file}"
  content = textile_file.read
  textile_file.close
  
  html = RedCloth.new( content ).to_html
  html_file = File.open "#{target_dir}/#{one_file.split('.')[0]}.html", 'w'
  html_file.write html
  html_file.close
end