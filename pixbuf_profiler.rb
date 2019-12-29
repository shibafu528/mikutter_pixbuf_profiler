# -*- coding:utf-8 -*-
# (forked from memory_profiler)

Plugin.create :pixbuf_profiler do
  def object_counts(output_dir)
    notice "pixbuf_profiler: start"
    ObjectSpace.garbage_collect

    notice "pixbuf_profiler: counting objects..."
    pbs = ObjectSpace.each_object(GdkPixbuf::Pixbuf).group_by(&:born).map do |k,v|
      {count: v.count, byte_length: v.sum(&:byte_length), tag: k}
    end.sort_by { |h| -h[:count] }

    dump = {
      pbstats: pbs,
      rss: `ps -o rss= -p #{Process.pid}`.chomp,
    }

    output = File.join(output_dir, Time.now.strftime("%Y-%m-%d-%H%M.json"))
    notice "pixbuf_profiler: done. writing file #{output}"

    File.open(output, 'w') do |ostream|
      JSON.dump(dump, ostream)
    end
    notice "pixbuf_profiler: wrote #{output}."
  ensure
    profile(output_dir)
  end

  def profile(output_dir)
    FileUtils.mkdir_p(output_dir)
    time = Reserver.new(60 * 5){ Plugin.call(:spectrum_set, -> { object_counts(output_dir) }) }
    notice "reserve to next time " + time.to_s
  end

  on_spectrum_set do |spectrum|
    notice "receive spectrum_set"
    @lock << spectrum end

  @lock = Queue.new

  Thread.new{
    loop{
      begin
        @lock.pop.call
      rescue => e
        error e end } }

  profile(File.join(Environment::LOGDIR, self.spec[:slug].to_s, defined_time.strftime("%Y/%m/%d/#{Environment::VERSION}-#{Process.pid}")).freeze)
end
