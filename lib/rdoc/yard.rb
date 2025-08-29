# frozen_string_literal: true

##
# YARD compatibility module for RDoc
#
# This module provides support for parsing YARD tags in RDoc comments.
# Currently supports:
# - @yield [params] - Describes block parameters
# - @private - Marks method/class as private
# - @api private - Alternative private marking

class RDoc::YARD

  ##
  # Processes YARD tags in the given comment text for a code object
  #
  # Returns modified comment text with YARD tags processed
  def self.process(comment, code_object)
    new(comment, code_object).process
  end

  attr_reader :comment, :code_object, :text

  def initialize(comment, code_object)
    @comment = comment
    @code_object = code_object
  end

  def process
    return comment unless comment && code_object

    # Only process RDoc::Comment objects to avoid modifying plain strings
    # that aren't actually documentation comments
    return comment unless comment.is_a?(RDoc::Comment)

    # Skip processing if comment is in TomDoc format
    return comment if comment.format == 'tomdoc'

    @text = comment.text.dup

    # Process @yield tags
    process_yield_tags

    # Process @private tags
    process_private_tags

    # Process @api tags
    process_api_tags

    # Only update comment.text if we actually modified it
    # This preserves the @document for comments created from parsed documents
    if text != comment.text
      comment.text = text
    end

    comment
  end

  private

  ##
  # Process @yield tags to extract block parameters
  def process_yield_tags
    return unless code_object.respond_to?(:block_params=)

    # Skip if already has block_params from :yields: directive
    return if code_object.block_params && !code_object.block_params.empty?

    # Match @yield [params] description
    if text =~ /^\s*#?\s*@yield\s*(?:\[([^\]]*)\])?\s*(.*?)$/
      params = $1

      if params && !params.empty?
        # Clean up the params - remove types if present
        clean_params = extract_param_names(params)
        code_object.block_params = clean_params unless clean_params.empty?
      end

      # Remove the @yield line from comment
      text.gsub!(/^\s*#?\s*@yield.*?$\n?/, '')
    end
  end

  ##
  # Process @private tags to set visibility
  def process_private_tags
    return unless code_object.respond_to?(:visibility=)

    if text =~ /^\s*#?\s*@private\s*$/
      code_object.visibility = :private

      # Remove the @private line from comment
      text.gsub!(/^\s*#?\s*@private\s*$\n?/, '')
    end
  end

  ##
  # Process @api tags (specifically @api private)
  def process_api_tags
    return unless code_object.respond_to?(:visibility=)

    if text =~ /^\s*#?\s*@api\s+private\s*$/
      code_object.visibility = :private

      # Remove the @api private line from comment
      text.gsub!(/^\s*#?\s*@api\s+private\s*$\n?/, '')
    end
  end

  ##
  # Extract parameter names from YARD type specification
  # e.g., "[String, Integer]" -> "value1, value2"
  # e.g., "[item, index]" -> "item, index"
  def extract_param_names(params_string)
    return '' if params_string.nil? || params_string.empty?

    # If params look like variable names (lowercase start), use them
    if params_string =~ /^[a-z_]/
      params_string.split(',').map(&:strip).join(', ')
    else
      # If they look like types (uppercase start), generate generic names
      types = params_string.split(',').map(&:strip)
      types.each_with_index.map do |type, i|
        if type =~ /^[A-Z]/
          # It's a type, generate a generic param name
          "arg#{i + 1}"
        else
          # It's already a param name
          type
        end
      end.join(', ')
    end
  end
end
