module PuppetDBQuery

  class Tokenizer

    SINGLE_CHAR_TO_TOKEN = {
      "!" => :not,
      "=" => :equal,
      "(" => :begin,
      ")" => :end,
      "[" => :list_begin,
      "]" => :list_end,
      "<" => :less,
      ">" => :greater,
      "~" => :match,
      "," => :comma,
    }

    DOUBLE_CHAR_TO_TOKEN = {
      "!=" => :not_equal,
      "!~" => :not_match,
      "~>" => :match_array,
      "<=" => :less_or_equal,
      ">=" => :greater_or_equal,
    }

    STRING_TO_TOKEN = {
      "not"   => :not,
      "or"    => :or,
      "and"   => :and,
      "in"    => :in,
      "is"    => :is,
      "null"  => :null,
      "true"  => :true,
      "false" => :false,
    }

    LANGUAGE_TOKENS = SINGLE_CHAR_TO_TOKEN.merge(DOUBLE_CHAR_TO_TOKEN).merge(STRING_TO_TOKEN)
    LANGUAGE_STRINGS = LANGUAGE_TOKENS.invert

    def self.symbols(query)
      r = []
      tokenizer = Tokenizer.new(query)
      while !tokenizer.empty?
        r << tokenizer.next_token
      end
      r
    end

    def self.query(symbols)
      symbols.map{ |v| symbol_to_string(v) }.join(" ")
    end

    def self.symbol_to_string(symbol)
      (LANGUAGE_STRINGS[symbol] || (symbol.is_a?(Symbol) ? symbol.to_s : nil) || symbol.inspect).to_s
    end

    def self.idem(query)
      query(symbols(query))
    end

    attr_reader :position
    attr_reader :text

    def initialize(text)
      @text = text
      @position = 0
    end

    def next_token
      skip_whitespace
      return nil if empty?
      read_token
    end

    def empty?
      position >= text.size
    end

    private

    def read_token
      debug "read token"
      skip_whitespace
      return nil if empty?
      s = text[position, 2]
      if DOUBLE_CHAR_TO_TOKEN.include?(s)
        increase
        increase
        return DOUBLE_CHAR_TO_TOKEN[s]
      end
      c = text[position]
      if SINGLE_CHAR_TO_TOKEN.include?(c)
        increase
        return SINGLE_CHAR_TO_TOKEN[c]
      end
      case c
      when /[a-zA-Z]/
        return read_symbol
      when "'", '"'
        return read_quoted
      when /[-0-9]/
        return read_number
      else
        error("unknown kind of token: '#{c}'")
      end
    end

    def read_quoted
      # FIXME read escaped characters
      debug "read quoted"
      skip_whitespace
      q = text[position]
      increase
      r = ""
      while !empty? && (c = text[position]) != q
        r << c
        increase
      end
      error("I expected '#{q}' but I got '#{c}'") if c != q
      increase
      debug "resulting symbol: '#{r}'"
      return r
    end

    def read_symbol
      debug "read symbol"
      skip_whitespace
      r = ""
      while !empty? && (c = text[position]) =~ /[-a-zA-Z_0-9]/
        r << c
        increase
      end
      debug "resulting symbol: '#{r}'"
      return r.to_sym
    end

    def read_number
      debug "read number"
      skip_whitespace
      r = ""
      while !empty? && (c = text[position]) =~ /[-0-9\.E]/
        r << c
        increase
      end
      debug "resulting symbol: '#{r}'"
      return Integer(r)
    rescue
      return Float(r)
    end

    def skip_whitespace
      #puts "skip whitespace"
      return if empty?
      while !empty? && text[position] =~ /\s/
        increase
      end
    end

    def increase
      debug "increase"
      @position += 1
      debug position
    end

    def error(message)
      raise "tokenizing query failed\n#{message}\n\n#{text}\n#{' ' * position}^"
    end

    def debug(*message)
      # puts "    #{message}"
    end
  end
end
