require 'sequel'
require 'redcloth'

raise "usage run.sh db_url target_dir" if(ARGV.length < 2) 
DB = Sequel.connect ARGV[0]
target_dir = ARGV[1]

overview = File.open target_dir + '/index.textile', 'w'
overview.write "h1. All tables\n\n"

puts "reading database"

tables = DB.tables
puts "generating textile"
tables.each do |t|
  overview.write "\"#{t}\":#{t}.html\n"  # "tablename":/tablename.html

  detail = File.open "#{target_dir}/#{t}.textile", 'w'
  detail.write "h1. #{t.to_s}\n\n"
  
  schema = DB.schema t
  schema.each do |c|
    detail.write "h2. #{c[0]}\n\n"
    detail.write "|_. Key|_. Value|\n"
    attrs = c[1]
    attrs.each do |k,v|
      detail.write "|#{k}|#{v}|\n"
    end
    detail.write "\n"
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