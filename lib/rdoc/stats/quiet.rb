##
# Stats printer that prints nothing

class RDoc::Stats::Quiet

  def initialize num_files
    @num_files = num_files
  end

  ##
  # Prints a message at the beginning of parsing

  def begin_adding(*) end

  ##
  # Prints when an alias is added

  def print_alias(*) end

  ##
  # Prints when a class is added

  def print_class(*) end

  ##
  # Prints when a constant is added

  def print_constant(*) end

  ##
  # Prints when a file is added

  def print_file(*) end

  ##
  # Prints when a method is added

  def print_method(*) end

  ##
  # Prints when a module is added

  def print_module(*) end

  ##
  # Prints when RDoc is done

  def done_adding(*) end

end

