module RMXFirebase

  def self.scheduler
    RMXRACHelper.schedulerWithHighPriority
  end

  def self.rac_schedulerFor(_scheduler)
    case _scheduler
    when nil, :main
      RACScheduler.mainThreadScheduler
    when :async
      scheduler
    when RACScheduler
      _scheduler
    else
      raise "unknown scheduler: #{_scheduler.inspect}"
    end
  end

end
