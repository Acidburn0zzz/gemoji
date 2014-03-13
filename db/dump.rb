require 'emoji'

names_list = File.expand_path('../NamesList.txt', __FILE__)

class UnicodeCharacter
  attr_reader :code, :description, :aliases

  @index = {}
  class << self
    attr_reader :index

    def fetch(code, *args, &block)
      code = code.to_s(16).rjust(4, '0') if code.is_a?(Integer)
      index.fetch(code, *args, &block)
    end
  end

  def initialize(code, description)
    @code = code.downcase
    @description = description.downcase
    @aliases = []
    @references = []

    self.class.index[@code] = self
  end

  def add_alias(string)
    @aliases.concat string.split(/\s*,\s*/)
  end

  def add_reference(code)
    @references << code.downcase
  end
end

char = nil

File.foreach(names_list) do |line|
  case line
  when /^[A-F0-9]{4,5}\t/
    code, desc = line.chomp.split("\t", 2)
    codepoint = code.hex
    char = UnicodeCharacter.new(code, desc)
  when /^\t= /
    char.add_alias($')
  when /^\tx .+ - ([A-F0-9]{4,5})\)$/
    char.add_reference($1)
  end
end

trap(:PIPE) { abort }

for emoji in Emoji.all
  aliases = emoji.aliases
  tags = emoji.tags
  unicodes = emoji.unicode_aliases
  unicodes = unicodes[1..-1] if emoji.variation?

  if emoji.custom?
    aliases = aliases[1..-1]
    spec_aliases = []
    puts "#{emoji.name} (custom)"
  else
    variation_codepoint = Emoji::Character::VARIATION_SELECTOR_16.codepoints[0]
    chars = emoji.raw.codepoints.map { |code| UnicodeCharacter.fetch(code) unless code == variation_codepoint }.compact
    spec_aliases = chars.each.flat_map(&:aliases)
    puts "#{emoji.raw}  (#{emoji.hex_inspect}) #{chars.map(&:description).join(' + ')}"
  end

  puts "  = #{aliases.join(', ')}" if aliases.any?
  puts "  ~ #{tags.join(', ')}" if tags.any?
  puts "  + #{unicodes.map{|u| Emoji::Character.hex_inspect(u) }.join(', ')}" if unicodes.any?
  # puts "  * #{spec_aliases.join(', ')}" if spec_aliases.any?
end
