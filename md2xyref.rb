# -*- encoding: utf-8 -*-

require "erb"
require "pp"

module XyReference
  class Chapter
    attr_accessor :title, :type, :arguments, :package, :description, :seealso, :link, :section, :file

    SECTION_MAP = {
      "Package" => "パッケージ",
      "Variable" => "変数と定数",
      "Constant" => "変数と定数",
      "Codition" => "データ型",
      "Struct" => "データ型",
      "Accessor " => "データ型",
      "Command " => "関数",
      "Function" => "関数",
      "Macro" => "マクロ",
    }

    def initialize(type, title, arguments, package, desc, seealso, file)
      self.section = SECTION_MAP[type]
      self.title = title
      self.type = type
      self.arguments = arguments
      self.package = package
      self.description = desc
      self.seealso = seealso || []
      self.file = file
    end
  end

  class FileIndex
    attr_accessor :index

    def initialize(src_dir)
      self.index = {}
      scan(src_dir) if src_dir
    end

    def scan(src_dir)
      Dir.chdir(src_dir) do
        Dir.glob("**/*.l") do |src_file|
          next if src_file =~ /\/tests?\//
          next if src_file =~ /\/t\//
          src = File.read(src_file)
          src.scan(/^[ \t]*\(def[a-z0-9-]+\s+[(:]*([^\s()]+)/m) do |m|
            self.index[m[0]] = src_file
          end
        end
      end
    end

    def lookup(type, title)
      file = self.index[title]
      return file if file

      if type == "Accessor"
        parent = title.gsub(/-[^-]+$/, "")
        file = lookup(type, parent) if parent != title
      end
      warn "Unknown src file: #{title}" unless file

      file
    end

  end

  class MarkdownParser
    attr_accessor :book, :file_index

    def initialize(file_index)
      self.book = []
      self.file_index = file_index
    end

    def parse(md)
      package = nil
      md.scan(/^### (.+?): (.+?)\n(.+?)(?=(^###? |\z))/m) do |md|
        type, arguments, desc = [$1, $2, $3].map{|e| cleanup(e) }
        if arguments =~ / /
          title = arguments.split(/ /).first
        else
          title, arguments = arguments, nil
        end

        desc, seealso = desc.split(/See Also:/, 2)
        seealso = seealso.scan(/^ *\* (\S*)/).map{|e| e[0] } if seealso

        file = self.file_index.lookup(type, title)

        c = Chapter.new(type, title, arguments, package, desc.strip, seealso, file)
        self.book << c

        if type == "Package"
          package = title
        end
      end
    end

    def cleanup(md)
      r = ""
      md.split(/^ *```[a-z]*\n/).each_with_index do |e,i|
        if i % 2 == 0
          # 説明
          e.gsub!(/<[^<>]+>/, "")
          e.gsub!(/\[(.+?)\]\(\#.+?\)/) { $1 }
          e.gsub!(/\[(.+?)\]/) { $1 }
          e.gsub!(/^---+\n/, "")
          e.gsub!(/__(.+?)__/) { $1 }
          e.gsub!(/`(.+?)`/) { $1 }
          e.gsub!(/\\(.)/) { $1 }
        else
          # コードサンプル
          e.gsub!(/^/, "    ")
        end
        e.gsub!(/^ +$/, "")
        r << e
      end
      r.strip
    end
  end

  class Generator
    include ERB::Util

    TEMPLATE = File.join(File.dirname(__FILE__), "template.xml")

    def generate(book)
      puts ERB.new(read_template, nil, "<>").result(binding)
    end

    def read_template
      File.open(TEMPLATE, "r:utf-8"){|f| f.read }
    end
  end

end

if ARGV.length < 1 or 2 < ARGV.length
  $stderr.puts "Usage: #{$0} foo.md [src_dir]"
  exit 1
end

file, src_dir = *ARGV

md = open(file, "r:utf-8"){|f| f.read }
file_index = XyReference::FileIndex.new(src_dir)
#pp file_index

parser = XyReference::MarkdownParser.new(file_index)
parser.parse(md)
#pp parser

generator = XyReference::Generator.new
generator.generate(parser.book)
