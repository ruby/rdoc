class RDoc::Stats::Formatter::Text

  ##
  # Text Formatter for RDoc::Stats

  def initialize stats
    @stats = stats
  end
  
  ##
  # A report that says you did a great job!

  def great_job
    report = []
    report << '100% documentation!'
    report << nil
    report << 'Great Job!'

    report.join "\n"
  end
  
  ##
  # Returns a report on undocumented items in ClassModule +cm+

  def report_class_module cm
    report = []

    if cm.in_files.empty? then
      report << "# #{cm.definition} is referenced but empty."
      report << '#'
      report << '# It probably came from another project.  ' \
        "I'm sorry I'm holding it against you."
      report << nil

      return report
    elsif cm.documented? then
      documented = true
      report << "#{cm.definition} # is documented"
    else
      report << '# in files:'

      cm.in_files.each do |file|
        report << "#   #{file.full_name}"
      end

      report << nil

      report << "#{cm.definition}"
    end

    body = yield.flatten # HACK remove #flatten

    return if body.empty? and documented

    report << nil << body unless body.empty?

    report << 'end'
    report << nil

    report
  end
  
  ##
  # Returns a report on undocumented constants in ClassModule +cm+

  def report_constants cm
    report = []

    cm.each_constant do |constant|
      # TODO constant aliases are listed in the summary but not reported
      # figure out what to do here
      next if constant.documented? || constant.is_alias_for
      report << "  # in file #{constant.file.full_name}"
      report << "  #{constant.name} = nil"
    end

    report
  end

  ##
  # Returns a report on missing method params.

  def report_params(undoc)
    if undoc
      undoc = undoc.map do |param| "+#{param}+" end
      "  # #{undoc.join ', '} is not documented"
    end
  end

  ##
  # Returns a report on undocumented methods in ClassModule +cm+
  
  def report_methods cm
    report = []

    cm.each_method do |method|
      param_report = report_params @stats.calculate_undoc_params(method)

      next if method.documented? and not param_report
      report << "  # in file #{method.file.full_name}"
      report << param_report if param_report
      scope = method.singleton ? 'self.' : nil
      report << "  def #{scope}#{method.name}#{method.params}; end"
      report << nil
    end

    report
  end

  ##
  # Returns a summary of the collected statistics.

  def summary
    run_stats = @stats.run_stats
    num_width = [@stats.num_files, run_stats.num_items].max.to_s.length
    undoc_width = [
      run_stats.undoc_attributes,
      run_stats.undoc_classes,
      run_stats.undoc_constants,
      run_stats.undoc_items,
      run_stats.undoc_methods,
      run_stats.undoc_modules,
      run_stats.undoc_params,
    ].max.to_s.length

    report = []
    report << 'Files:      %*d' % [num_width, @stats.num_files]

    report << nil

    report << 'Classes:    %*d (%*d undocumented)' % [
      num_width, run_stats.num_classes, undoc_width, run_stats.undoc_classes]
    report << 'Modules:    %*d (%*d undocumented)' % [
      num_width, run_stats.num_modules, undoc_width, run_stats.undoc_modules]
    report << 'Constants:  %*d (%*d undocumented)' % [
      num_width, run_stats.num_constants, undoc_width, run_stats.undoc_constants]
    report << 'Attributes: %*d (%*d undocumented)' % [
      num_width, run_stats.num_attributes, undoc_width, run_stats.undoc_attributes]
    report << 'Methods:    %*d (%*d undocumented)' % [
      num_width, run_stats.num_methods, undoc_width, run_stats.undoc_methods]
    report << 'Parameters: %*d (%*d undocumented)' % [
      num_width, run_stats.num_params, undoc_width, run_stats.undoc_params] if
        @stats.coverage_level > 0

    report << nil

    report << 'Total:      %*d (%*d undocumented)' % [
      num_width, run_stats.num_items, undoc_width, run_stats.undoc_items]

    report << '%6.2f%% documented' % @stats.percent_doc
    report << nil
    report << 'Elapsed: %0.1fs' % (Time.now - @stats.start)

    report.join "\n"
  end

end
