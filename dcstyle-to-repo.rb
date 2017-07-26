require 'json'
require 'fileutils'
require 'open-uri'

if ARGV.count < 1
  puts "Usage: dcstyle-to-repo.rb <dcstyle-file> [forum URL]"
  puts "  dcstyle-file is a theme file exported from Discourse"
  puts "  forum-URL (optional) is the forum URL that can be used to download assets"
  exit
end

fnmap = { 
  "after_header"  => "after_header.html",
  "body_tag"      => "body_tag.html",
  "embedded_scss" => "embedded.scss",
  "footer"        => "footer.html",
  "header"        => "header.html",
  "head_tag"      => "head_tag.html",
  "scss"          => "#destination#.scss"
}

filename = ARGV[0]
discourse_url = ARGV[1].chomp('/') unless ARGV.count < 2

about = {
  "about_url" => "",
  "license_url" => ""
}
assets = {}

destdir = File.basename(filename, '.dcstyle.json')
FileUtils.mkdir_p(destdir) unless File.directory?(destdir)

File.open(filename) do |file|
  json = JSON::parse(file.read)
  theme = json['theme']
  about['name'] = theme['name']

  theme["theme_fields"]&.each do |field|
     if field['type_id'] < 2
       FileUtils.mkdir_p("#{destdir}/#{field['target']}") unless File.directory?("#{destdir}/#{field['target']}")
       fn = fnmap[field["name"]].sub "#destination#", field['target']
     
       destfile = "#{destdir}/#{field["target"]}/#{fn}"
       File.open(destfile,'w') { |file| file.write(field['value']) }
       puts "Creating #{destfile}"
     elsif field['type_id'] = 2
       if ARGV.count < 2 
         puts "Error: assets present but no forum URL given"
         exit
       end
       FileUtils.mkdir_p("#{destdir}/assets") unless File.directory?("#{destdir}/assets")
       local = "assets/#{field['filename']}"
       remote = "#{discourse_url}#{field['url']}"
       download = open(remote)
       IO.copy_stream(download, "#{destdir}/#{local}")
       assets[field['name']] = local
       puts "Copying #{remote} to #{destdir}/#{local}"
     end
  end
  about['assets'] = assets unless assets.empty?
end
puts "Creating #{destdir}/about.json"
File.open("#{destdir}/about.json", "w") do |file|
  file.write JSON.pretty_generate(about)
end
