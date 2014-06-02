Gem::Specification.new do |s|
  s.name    = "gemoji"
  s.version = "1.5.0"
  s.summary = "Emoji conversion and image assets"
  s.description = "Image assets and character information for emoji."

  s.authors  = ["GitHub"]
  s.email    = "support@github.com"
  s.homepage = "https://github.com/github/gemoji"
  s.licenses = ["MIT"]

  s.files = Dir[
    "README.md",
    "images/**/*.png",
    "db/emoji.txt",
    "lib/**/*.rb",
    "lib/tasks/*.rake"
  ]
end
