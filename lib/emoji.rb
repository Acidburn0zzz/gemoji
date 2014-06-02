require 'emoji/character'

module Emoji
  extend self

  NotFound = Class.new(IndexError)

  def data_file
    File.expand_path('../../db/emoji.txt', __FILE__)
  end

  def images_path
    File.expand_path("../../images", __FILE__)
  end

  def all
    @all ||= parse_data_file
  end

  def find_by_alias(name)
    names_index.fetch(name) {
      if block_given? then yield name
      else raise NotFound, "Emoji not found by name: %s" % name.inspect
      end
    }
  end

  def find_by_unicode(unicode)
    unicodes_index.fetch(unicode) {
      if block_given? then yield unicode
      else raise NotFound, "Emoji not found from unicode: %s" % Emoji::Character.hex_inspect(unicode)
      end
    }
  end

  def names
    @names ||= names_index.keys.sort
  end

  def unicodes
    @unicodes ||= unicodes_index.keys
  end

  def custom
    @custom ||= all.map { |emoji|
      emoji.aliases if emoji.custom?
    }.compact.flatten.sort
  end

  def unicode_for(name)
    emoji = find_by_alias(name) { return nil }
    emoji.raw
  end

  def name_for(unicode)
    emoji = find_by_unicode(unicode) { return nil }
    emoji.name
  end

  def names_for(unicode)
    emoji = find_by_unicode(unicode) { return nil }
    emoji.aliases
  end

  private
    def create_index
      index = Hash.new { |hash, key| hash[key] = [] }
      yield index
      index
    end

    def parse_data_file
      emojis = []

      File.open(data_file, 'r:UTF-8') do |file|
        char = nil
        file.each_line do |line|
          case line
          when /^(\S+)\s+\((.+?)\)/
            emoji, hex = $1, $2
            name, emoji = emoji, nil if 'custom' == hex
            char = Emoji::Character.new(emoji)
            char.add_alias(name) if name
            emojis << char
          when /^\s*=/
            aliases = $'.strip.split(/\s*,\s*/)
            aliases.each { |name| char.add_alias(name) }
          when /^\s*~/
            tags = $'.strip.split(/\s*,\s*/)
            tags.each { |name| char.add_tag(name) }
          when /^\s*\+/
            unicodes = $'.strip.split(/\s*,\s*/)
            unicodes.each { |codes|
              raw = codes.split('-').map(&:hex).pack('U*')
              char.add_unicode_alias(raw)
            }
          else
            raise line.inspect
          end
        end
      end

      emojis
    end

    def names_index
      @names_index ||= create_index do |mapping|
        all.each do |emoji|
          unicodes = emoji.unicode_aliases.dup
          unicodes << emoji.raw unless emoji.custom?
          emoji.aliases.each do |name|
            mapping[name] = emoji
          end
        end
      end
    end

    def unicodes_index
      @unicodes_index ||= create_index do |mapping|
        all.each do |emoji|
          unicodes = emoji.unicode_aliases.dup
          unicodes << emoji.raw unless emoji.custom?
          unicodes.each do |unicode|
            mapping[unicode] = emoji
          end
        end
      end
    end
end
