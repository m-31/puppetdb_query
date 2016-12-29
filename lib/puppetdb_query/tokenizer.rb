require_relative "logging"

module PuppetDBQuery
  # tokenize puppetdb queries
  # FIXME: distinguish between language tokens and other tokens
  # rubocop:disable Metrics/ClassLength
  class Tokenizer
    include Logging
    include Enumerable

    SINGLE_CHAR_TO_TOKEN = {
      "!" => :_not,
      "=" => :_equal,
      "(" => :_begin,
      ")" => :_end,
      "[" => :_list_begin,
      "]" => :_list_end,
      "<" => :_less,
      ">" => :_greater,
      "~" => :_match,
      "," => :_comma,
    }.freeze

    DOUBLE_CHAR_TO_TOKEN = {
      "!=" => :_not_equal,
      "!~" => :_not_match,
      "~>" => :_match_array,
      "<=" => :_less_or_equal,
      ">=" => :_greater_or_equal,
    }.freeze

    STRING_TO_TOKEN = {
      "not"   => :_not,
      "or"    => :_or,
      "and"   => :_and,
      "in"    => :_in,
      "is"    => :_is,
      "null"  => :null,
      "true"  => :true,
      "false" => :false,
    }.freeze

    LANGUAGE_TOKENS = SINGLE_CHAR_TO_TOKEN.merge(DOUBLE_CHAR_TO_TOKEN).merge(STRING_TO_TOKEN).freeze
    LANGUAGE_STRINGS = LANGUAGE_TOKENS.invert.freeze

    def self.symbols(query)
      r = []
      tokenizer = Tokenizer.new(query)
      r << tokenizer.next_token until tokenizer.empty?
      r
    end

    def self.query(symbols)
      symbols.map { |v| symbol_to_string(v) }.join(" ")
    end

    def self.symbol_to_string(s)
      (LANGUAGE_STRINGS[s] || (s.is_a?(Symbol) ? s.to_s : nil) || s.inspect).to_s
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

    def each
      yield next_token until empty?
    end

    private

    def read_token
      logger.debug "read token"
      skip_whitespace
      return nil if empty?
      s = text[position, 2]
      if DOUBLE_CHAR_TO_TOKEN.include?(s)
        increase
        increase
        logger.debug "  resulting symbol: #{DOUBLE_CHAR_TO_TOKEN[s]}"
        return DOUBLE_CHAR_TO_TOKEN[s]
      end
      c = text[position]
      if SINGLE_CHAR_TO_TOKEN.include?(c)
        increase
        logger.debug "  resulting symbol: #{SINGLE_CHAR_TO_TOKEN[c]}"
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

    # rubocop:disable Metrics/PerceivedComplexity,Style/ConditionalAssignment
    def read_quoted
      logger.debug "  read quoted"
      skip_whitespace
      q = text[position] # quote character
      increase
      r = ""
      while !empty? && (c = text[position]) != q
        if c == "\\"
          increase
          c = text[position] unless empty?
          case c
          when 'r'
            c = "\r"
          when 'n'
            c = "\n"
          when '\''
            c = "\'"
          when '\\'
            c = "\\"
          else
            c = "\\" + c
          end
        end
        r << c
        increase
      end
      error("I expected '#{q}' but I got '#{c}'") if c != q
      increase
      logger.debug "  resulting string: '#{r}'"
      r
    end
    # rubocop:enable Metrics/PerceivedComplexity,Style/ConditionalAssignment

    def read_symbol
      logger.debug "  read symbol"
      skip_whitespace
      r = ""
      while !empty? && (c = text[position]) =~ /[-a-zA-Z_0-9]/
        r << c
        increase
      end
      s = STRING_TO_TOKEN[r]
      s = r.to_sym unless s
      logger.debug "  resulting symbol: #{s}"
      s
    end

    def read_number
      logger.debug "  read number"
      skip_whitespace
      r = ""
      while !empty? && (c = text[position]) =~ /[-0-9\.E]/
        r << c
        increase
      end
      logger.debug "  resulting number: '#{r}'"
      Integer(r)
    rescue
      Float(r)
    end

    def skip_whitespace
      # logger.debug "skip whitespace"
      return if empty?
      increase until empty? || text[position] !~ /\s/
    end

    def increase
      # logger.debug "increase"
      @position += 1
      # logger.debug position
    end

    def error(message)
      raise "tokenizing query failed\n#{message}\n\n#{text}\n#{' ' * position}^"
    end
  end
end
