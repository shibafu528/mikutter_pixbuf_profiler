# frozen_string_literal: true

require 'json'
require 'csv'

TARGET_DIR = ARGV[0]
FILE_SELECTOR = File.join(TARGET_DIR, '????-??-??-????.json')
output = STDOUT

mark_conditions = {
  'mp:473:main_icon' => ->(pbstat) {
    pbstat[:tag].is_a?(Array) &&
      pbstat[:tag].include?("/home/shibafu/git/mikutter/core/mui/cairo_miracle_painter.rb:473:in `main_icon'") &&
      !pbstat[:tag].include?("/home/shibafu/git/mikutter/core/mui/gtk_tree_view_pretty_scroll.rb:41:in `block (2 levels) in initialize'")
  },
  'mp:473:main_icon(pretty)' => ->(pbstat) {
    pbstat[:tag].is_a?(Array) &&
      pbstat[:tag].include?("/home/shibafu/git/mikutter/core/mui/cairo_miracle_painter.rb:473:in `main_icon'") &&
      pbstat[:tag].include?("/home/shibafu/git/mikutter/core/mui/gtk_tree_view_pretty_scroll.rb:41:in `block (2 levels) in initialize'")
  },
  'moguno' => ->(pbstat) { pbstat[:tag] == 'moguno' },
  'mp:gen_pixbuf' => ->(pbstat) { pbstat[:tag] == 'miracle_painter__gen_pixbuf' },
}

output.puts(CSV.generate_line(['date', 'rss [KB]', *mark_conditions.keys.sort.flat_map { |k| [k, "#{k} [KB]"] }]))

Dir.glob(FILE_SELECTOR).sort.each do |file|
  m = %r<(?<version>[^/]+)\-\d+/(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})-(?<hour>\d{2})(?<minute>\d{2})\.json\Z>.match(file)
  line = ["#{m[:day]}_#{m[:hour]}:#{m[:minute]}"]

  json = JSON.parse(File.open(file).read, symbolize_names: true)
  line << json[:rss]

  mark_counts = Hash.new(0)
  mark_bytes = Hash.new(0)
  json[:pbstats].each do |pbstat|
    mark = mark_conditions.find { |k, cond| cond.(pbstat) }
    if mark
      mark_counts[mark.first] += pbstat[:count]
      mark_bytes[mark.first] += pbstat[:byte_length] / 1024
    end
  end
  mark_conditions.keys.sort.each do |k|
    line << mark_counts[k]
    line << mark_bytes[k]
  end

  output.puts(CSV.generate_line(line))
end
