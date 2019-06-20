# These Liquid Filters are from the Jekyll project.
# They were copied here from Jekyll 4.0.0.pre.alpha1 source
# Modifications mostly consist of removals
# Would prefer keeping this in sync by using only select filters from a jekyll
#  dependency gem, but I was unable to implement at this time. See
# ‘Forked’ at commit:
# https://github.com/jekyll/jekyll/tree/551014eb05f0c3eed3c8196b6d1e04e7ae433679

module Jekyll
  module GroupingFilters
    # Group an array of items by a property
    #
    # input - the inputted Enumerable
    # property - the property
    #
    # Returns an array of Hashes, each looking something like this:
    #  {"name"  => "larry"
    #   "items" => [...] } # all the items where `property` == "larry"
    def group_by(input, property)
      if groupable?(input)
        groups = input.group_by { |item| item_property(item, property).to_s }
        grouped_array(groups)
      else
        input
      end
    end

    # Group an array of items by an expression
    #
    # input - the object array
    # variable - the variable to assign each item to in the expression
    # expression -a Liquid comparison expression passed in as a string
    #
    # Returns the filtered array of objects
    def group_by_exp(input, variable, expression)
      return input unless groupable?(input)

      parsed_expr = parse_expression(expression)
      @context.stack do
        groups = input.group_by do |item|
          @context[variable] = item
          parsed_expr.render(@context)
        end
        grouped_array(groups)
      end
    end

    private
    def parse_expression(str)
      Liquid::Variable.new(str, Liquid::ParseContext.new)
    end

    private
    def groupable?(element)
      element.respond_to?(:group_by)
    end

    private
    def grouped_array(groups)
      groups.each_with_object([]) do |item, array|
        array << {
          "name"  => item.first,
          "items" => item.last,
          "size"  => item.last.size,
        }
      end
    end
  end

  module DateFilters
    # Format a date in short format e.g. "27 Jan 2011".
    # Ordinal format is also supported, in both the UK
    # (e.g. "27th Jan 2011") and US ("e.g. Jan 27th, 2011") formats.
    # UK format is the default.
    #
    # date - the Time to format.
    # type - if "ordinal" the returned String will be in ordinal format
    # style - if "US" the returned String will be in US format.
    #         Otherwise it will be in UK format.
    #
    # Returns the formatting String.
    def date_to_string(date, type = nil, style = nil)
      stringify_date(date, "%b", type, style)
    end

    # Format a date in long format e.g. "27 January 2011".
    # Ordinal format is also supported, in both the UK
    # (e.g. "27th January 2011") and US ("e.g. January 27th, 2011") formats.
    # UK format is the default.
    #
    # date - the Time to format.
    # type - if "ordinal" the returned String will be in ordinal format
    # style - if "US" the returned String will be in US format.
    #         Otherwise it will be in UK format.
    #
    # Returns the formatted String.
    def date_to_long_string(date, type = nil, style = nil)
      stringify_date(date, "%B", type, style)
    end

    # Format a date for use in XML.
    #
    # date - The Time to format.
    #
    # Examples
    #
    #   date_to_xmlschema(Time.now)
    #   # => "2011-04-24T20:34:46+08:00"
    #
    # Returns the formatted String.
    def date_to_xmlschema(date)
      return date if date.to_s.empty?
      time(date).xmlschema
    end

    # Format a date according to RFC-822
    #
    # date - The Time to format.
    #
    # Examples
    #
    #   date_to_rfc822(Time.now)
    #   # => "Sun, 24 Apr 2011 12:34:46 +0000"
    #
    # Returns the formatted String.
    def date_to_rfc822(date)
      return date if date.to_s.empty?
      time(date).rfc822
    end

    private
    # month_type: Notations that evaluate to 'Month' via `Time#strftime` ("%b", "%B")
    # type: nil (default) or "ordinal"
    # style: nil (default) or "US"
    #
    # Returns a stringified date or the empty input.
    def stringify_date(date, month_type, type = nil, style = nil)
      return date if date.to_s.empty?
      time = time(date)
      if type == "ordinal"
        day = time.day
        ordinal_day = "#{day}#{ordinal(day)}"
        return time.strftime("#{month_type} #{ordinal_day}, %Y") if style == "US"
        return time.strftime("#{ordinal_day} #{month_type} %Y")
      end
      time.strftime("%d #{month_type} %Y")
    end

    private
    def ordinal(number)
      return "th" if (11..13).cover?(number)

      case number % 10
      when 1 then "st"
      when 2 then "nd"
      when 3 then "rd"
      else "th"
      end
    end

    private
    def time(input)
      date = Liquid::Utils.to_date(input)
      unless date.respond_to?(:to_time)
        raise "Invalid Date: '#{input.inspect}' is not a valid datetime."
      end
      date.to_time.dup.localtime
    end
  end

  module Filters

    # XML escape a string for use. Replaces any special characters with
    # appropriate HTML entity replacements.
    #
    # input - The String to escape.
    #
    # Examples
    #
    #   xml_escape('foo "bar" <baz>')
    #   # => "foo &quot;bar&quot; &lt;baz&gt;"
    #
    # Returns the escaped String.
    def xml_escape(input)
      input.to_s.encode(:xml => :attr).gsub(%r!\A"|"\Z!, "")
    end

    # CGI escape a string for use in a URL. Replaces any special characters
    # with appropriate %XX replacements.
    #
    # input - The String to escape.
    #
    # Examples
    #
    #   cgi_escape('foo,bar;baz?')
    #   # => "foo%2Cbar%3Bbaz%3F"
    #
    # Returns the escaped String.
    def cgi_escape(input)
      CGI.escape(input)
    end

    # URI escape a string.
    #
    # input - The String to escape.
    #
    # Examples
    #
    #   uri_escape('foo, bar \\baz?')
    #   # => "foo,%20bar%20%5Cbaz?"
    #
    # Returns the escaped String.
    def uri_escape(input)
      Addressable::URI.normalize_component(input)
    end

    # Replace any whitespace in the input string with a single space
    #
    # input - The String on which to operate.
    #
    # Returns the formatted String
    def normalize_whitespace(input)
      input.to_s.gsub(%r!\s+!, " ").strip
    end

    # Count the number of words in the input string.
    #
    # input - The String on which to operate.
    #
    # Returns the Integer word count.
    def number_of_words(input)
      input.split.length
    end

    # Join an array of things into a string by separating with commas and the
    # word "and" for the last one.
    #
    # Based on but differs from array_to_sentence_string, not available to LiquiDoc
    #
    # array - The Array of Strings to join.
    # connector - Word used to connect the last 2 items in the array
    #
    # Examples
    #
    #   array_to_serial(["apples", "oranges", "grapes"])
    #   # => "apples, oranges, and grapes"
    #   array_to_serial(["apples", "oranges", "grapes"], "")
    #   # => "apples, oranges, grapes"
    #   Improved behavior::
    #   array_to_serial(["apples", "oranges"], "")
    #   # => "apples, oranges"
    #
    # Returns the formatted String.
    def array_to_serial(array, connector="and", serializer=", ")
      con = " #{connector} " unless connector.empty?
      case array.length
      when 0
        out = ""
      when 1
        out = array[0].to_s
      when 2
        ser = serializer if connector.empty?
        out = "#{array[0]}#{ser}#{con}#{array[1]}"
      else
        out = "#{array[0...-1].join(serializer)}#{serializer}#{con}#{array[-1]}"
      end
      out
    end

    # Convert the input into json string
    #
    # input - The Array or Hash to be converted
    #
    # Returns the converted json string
    def jsonify(input)
      as_liquid(input).to_json
    end

    # Filter an array of objects
    #
    # input - the object array
    # property - property within each object to filter by
    # value - desired value
    #
    # Returns the filtered array of objects
    def where(input, property, value)
      return input if property.nil? || value.nil?
      return input unless input.respond_to?(:select)
      input    = input.values if input.is_a?(Hash)
      input_id = input.hash

      # implement a hash based on method parameters to cache the end-result
      # for given parameters.
      @where_filter_cache ||= {}
      @where_filter_cache[input_id] ||= {}
      @where_filter_cache[input_id][property] ||= {}

      # stash or retrive results to return
      @where_filter_cache[input_id][property][value] ||= begin
        input.select do |object|
          Array(item_property(object, property)).map!(&:to_s).include?(value.to_s)
        end || []
      end
    end

    # Filters an array of objects against an expression
    #
    # input - the object array
    # variable - the variable to assign each item to in the expression
    # expression - a Liquid comparison expression passed in as a string
    #
    # Returns the filtered array of objects
    def where_exp(input, variable, expression)
      return input unless input.respond_to?(:select)
      input = input.values if input.is_a?(Hash) # FIXME

      condition = parse_condition(expression)
      @context.stack do
        input.select do |object|
          @context[variable] = object
          condition.evaluate(@context)
        end
      end || []
    end

    # Convert the input into integer
    #
    # input - the object string
    #
    # Returns the integer value
    def to_integer(input)
      return 1 if input == true
      return 0 if input == false
      input.to_i
    end

    # Sort an array of objects
    #
    # input - the object array
    # property - property within each object to filter by
    # nils ('first' | 'last') - nils appear before or after non-nil values
    #
    # Returns the filtered array of objects
    def sort(input, property = nil, nils = "first")
      if input.nil?
        raise ArgumentError, "Cannot sort a null object."
      end
      if property.nil?
        input.sort
      else
        if nils == "first"
          order = - 1
        elsif nils == "last"
          order = + 1
        else
          raise ArgumentError, "Invalid nils order: " \
            "'#{nils}' is not a valid nils order. It must be 'first' or 'last'."
        end

        sort_input(input, property, order)
      end
    end

    def pop(array, num = 1)
      return array unless array.is_a?(Array)
      num = Liquid::Utils.to_integer(num)
      new_ary = array.dup
      new_ary.pop(num)
      new_ary
    end

    def push(array, input)
      return array unless array.is_a?(Array)
      new_ary = array.dup
      new_ary.push(input)
      new_ary
    end

    def shift(array, num = 1)
      return array unless array.is_a?(Array)
      num = Liquid::Utils.to_integer(num)
      new_ary = array.dup
      new_ary.shift(num)
      new_ary
    end

    def unshift(array, input)
      return array unless array.is_a?(Array)
      new_ary = array.dup
      new_ary.unshift(input)
      new_ary
    end

    def sample(input, num = 1)
      return input unless input.respond_to?(:sample)
      num = Liquid::Utils.to_integer(num) rescue 1
      if num == 1
        input.sample
      else
        input.sample(num)
      end
    end

    # Convert an object into its String representation for debugging
    #
    # input - The Object to be converted
    #
    # Returns a String representation of the object.
    def inspect(input)
      xml_escape(input.inspect)
    end

    private

    # Sort the input Enumerable by the given property.
    # If the property doesn't exist, return the sort order respective of
    # which item doesn't have the property.
    # We also utilize the Schwartzian transform to make this more efficient.
    def sort_input(input, property, order)
      input.map { |item| [item_property(item, property), item] }
        .sort! do |apple_info, orange_info|
          apple_property = apple_info.first
          orange_property = orange_info.first

          if !apple_property.nil? && orange_property.nil?
            - order
          elsif apple_property.nil? && !orange_property.nil?
            + order
          else
            apple_property <=> orange_property
          end
        end
        .map!(&:last)
    end

    private
    def item_property(item, property)
      if item.respond_to?(:to_liquid)
        property.to_s.split(".").reduce(item.to_liquid) do |subvalue, attribute|
          subvalue[attribute]
        end
      elsif item.respond_to?(:data)
        item.data[property.to_s]
      else
        item[property.to_s]
      end
    end

    private
    def as_liquid(item)
      case item
      when Hash
        pairs = item.map { |k, v| as_liquid([k, v]) }
        Hash[pairs]
      when Array
        item.map { |i| as_liquid(i) }
      else
        if item.respond_to?(:to_liquid)
          liquidated = item.to_liquid
          # prevent infinite recursion for simple types (which return `self`)
          if liquidated == item
            item
          else
            as_liquid(liquidated)
          end
        else
          item
        end
      end
    end

    # Parse a string to a Liquid Condition
    private
    def parse_condition(exp)
      parser = Liquid::Parser.new(exp)
      left_expr = parser.expression
      operator = parser.consume?(:comparison)
      condition =
        if operator
          Liquid::Condition.new(Liquid::Expression.parse(left_expr),
                                operator,
                                Liquid::Expression.parse(parser.expression))
        else
          Liquid::Condition.new(Liquid::Expression.parse(left_expr))
        end
      parser.consume(:end_of_string)

      condition
    end

  end
end

Liquid::Template.register_filter(Jekyll::GroupingFilters)
Liquid::Template.register_filter(Jekyll::DateFilters)
Liquid::Template.register_filter(Jekyll::Filters)
