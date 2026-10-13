require 'rake/clean'
require 'json'

module PersonalPdfWorkflow
  ROOT = 'README/personal'
  CUSTOM_JSON = File.join(ROOT, 'base-layer-diagram-QWERTY.json')
  CUSTOM_PNG = File.join(ROOT, 'base-layer-diagram-QWERTY.png')

  VARIANTS = {
    'all' => %w[
      base-layer-diagram
      base-layer-diagram-Enthium
      base-layer-diagram-Dvorak
      base-layer-diagram-Colemak
      base-layer-diagram-QWERTY
      repeat-layer-diagram
      typing-layer-diagram
      gaming-layer-diagram
      cursor-layer-diagram
      number-layer-diagram
      function-layer-diagram
      symbol-layer-diagram
      mouse-layer-diagram
      system-layer-diagram
      emoji-layer-diagram
      world-layer-diagram
      lower-layer-diagram
      magic-layer-diagram
      factory-layer-diagram
    ],
    'all_non_alpha' => %w[
      base-layer-diagram-QWERTY
      repeat-layer-diagram
      typing-layer-diagram
      gaming-layer-diagram
      cursor-layer-diagram
      number-layer-diagram
      function-layer-diagram
      symbol-layer-diagram
      mouse-layer-diagram
      system-layer-diagram
      emoji-layer-diagram
      world-layer-diagram
      lower-layer-diagram
      magic-layer-diagram
      factory-layer-diagram
    ],
    'core' => %w[
      base-layer-diagram-QWERTY
      cursor-layer-diagram
      number-layer-diagram
      function-layer-diagram
      symbol-layer-diagram
      mouse-layer-diagram
      system-layer-diagram
      lower-layer-diagram
      magic-layer-diagram
    ],
    'personalized' => %w[
      base-layer-diagram-QWERTY
      cursor-layer-diagram
      number-layer-diagram
      function-layer-diagram
      symbol-layer-diagram
      mouse-layer-diagram
    ]
  }.freeze

  # Preserve the page order of the existing personal dark reference PDF.
  DARK_ALL_NON_ALPHA_LAYERS = %w[
    base-layer-diagram-QWERTY
    symbol-layer-diagram
    number-layer-diagram
    cursor-layer-diagram
    function-layer-diagram
    mouse-layer-diagram
    system-layer-diagram
    repeat-layer-diagram
    gaming-layer-diagram
    lower-layer-diagram
    magic-layer-diagram
    factory-layer-diagram
    world-layer-diagram
    emoji-layer-diagram
    typing-layer-diagram
  ].freeze

  THEMES = %w[light dark].freeze

  module_function

  def source_png(layer)
    return CUSTOM_PNG if layer == 'base-layer-diagram-QWERTY'

    File.join('README', "#{layer}.png")
  end

  def source_json(layer)
    return CUSTOM_JSON if layer == 'base-layer-diagram-QWERTY'

    File.join('README', "#{layer}.json")
  end

  def page_png(layer, theme)
    return source_png(layer) if theme == 'light'

    File.join(ROOT, "#{layer}.dark.png")
  end

  def page_pdf(layer, theme)
    suffix = theme == 'light' ? '' : '.dark'
    File.join(ROOT, "#{layer}#{suffix}.page.pdf")
  end

  def final_pdf(variant, theme)
    suffix = theme == 'light' ? '' : '-dark'
    filename_variant = variant.tr('_', '-')
    File.join(ROOT, "#{filename_variant}-layer-diagrams#{suffix}.pdf")
  end

  def layers_for(variant, theme = 'light')
    return DARK_ALL_NON_ALPHA_LAYERS if variant == 'all_non_alpha' && theme == 'dark'

    VARIANTS.fetch(variant)
  end

  def variants_for(theme)
    VARIANTS.keys.map { |variant| final_pdf(variant, theme) }
  end

  def all_final_pdfs
    THEMES.flat_map { |theme| variants_for(theme) }
  end

  def all_source_layers
    VARIANTS.values.flatten.uniq
  end

  def validate!
    missing_pngs = all_source_layers.map { |layer| source_png(layer) }.reject do |png|
      File.file?(png)
    end

    unless missing_pngs.empty?
      raise <<~ERROR
        Cannot build personal PDFs because these layer PNGs are missing:
        #{missing_pngs.map { |png| "  - #{png}" }.join("\n")}

        For a missing custom diagram, upload #{CUSTOM_JSON} to the KLE app,
        then capture the #keyboard-bg element as #{CUSTOM_PNG}.
        Capture each missing upstream diagram from its matching JSON in README/.
      ERROR
    end

    stale_pairs = all_source_layers.each_with_object([]) do |layer, pairs|
      png = source_png(layer)
      json = source_json(layer)
      pairs << [png, json] if File.file?(json) && File.mtime(png) < File.mtime(json)
    end

    unless stale_pairs.empty?
      details = stale_pairs.map { |png, json| "  - #{png} is older than #{json}" }
      raise <<~ERROR
        Cannot build personal PDFs because these screenshots are stale:
        #{details.join("\n")}

        Re-upload the matching JSON to the KLE app and recapture the
        #keyboard-bg element. The custom QWERTY capture must be saved as
        #{CUSTOM_PNG}.
      ERROR
    end

    JSON.parse(File.read(CUSTOM_JSON))
  rescue JSON::ParserError => e
    raise "Cannot build personal PDFs because #{CUSTOM_JSON} is not valid KLE JSON: #{e.message}"
  end
end

personal_validation_task = 'personal:pdf:validate'

PersonalPdfWorkflow::THEMES.each do |theme|
  PersonalPdfWorkflow.all_source_layers.each do |layer|
    png = PersonalPdfWorkflow.page_png(layer, theme)
    pdf = PersonalPdfWorkflow.page_pdf(layer, theme)

    if theme == 'dark'
      file png => [PersonalPdfWorkflow.source_png(layer), __FILE__] do |t|
        source = t.prerequisites.find { |prerequisite| prerequisite.end_with?('.png') }
        sh 'gm', 'convert', source,
           '-colorspace', 'HSL',
           '-operator', 'Blue', 'Multiply', '0.84',
           '-operator', 'Blue', 'Negate', '0',
           '-operator', 'Blue', 'Subtract', '8%',
           '-colorspace', 'RGB',
           t.name
      end
    end

    file pdf => [png, __FILE__] do |t|
      source = t.prerequisites.find { |prerequisite| prerequisite.end_with?('.png') }
      sh 'gm', 'convert', source, t.name
    end

    CLEAN.include pdf
    CLEAN.include png if theme == 'dark'
  end
end

PersonalPdfWorkflow::THEMES.each do |theme|
  PersonalPdfWorkflow::VARIANTS.each_key do |variant|
    page_pdfs = PersonalPdfWorkflow.layers_for(variant, theme).map do |layer|
      PersonalPdfWorkflow.page_pdf(layer, theme)
    end
    final_pdf = PersonalPdfWorkflow.final_pdf(variant, theme)
    file final_pdf => [*page_pdfs, __FILE__] do |t|
      pages = t.prerequisites.select { |prerequisite| prerequisite.end_with?('.page.pdf') }
      sh 'pdfunite', *pages, t.name
    end
    CLOBBER.include final_pdf
  end
end

namespace :personal do
  desc 'Build all personal layer-diagram PDFs in light and dark themes'
  task :pdf => ['personal:pdf:light', 'personal:pdf:dark']

  namespace :pdf do
    desc 'Validate personal diagram PNGs and their KLE JSON sources'
    task :validate do
      PersonalPdfWorkflow.validate!
    end

    desc 'Build all four personal PDF variants in the light theme'
    task :light => [personal_validation_task, *PersonalPdfWorkflow.variants_for('light')]

    desc 'Build all four personal PDF variants in the dark theme'
    task :dark => [personal_validation_task, *PersonalPdfWorkflow.variants_for('dark')]

    PersonalPdfWorkflow::VARIANTS.each_key do |variant|
      desc "Build the #{variant} personal PDF variant in both themes"
      task variant => [
        personal_validation_task,
        PersonalPdfWorkflow.final_pdf(variant, 'light'),
        PersonalPdfWorkflow.final_pdf(variant, 'dark')
      ]
    end
  end
end
