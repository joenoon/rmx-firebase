# to get models to show up in Instruments, for some reason need to < UIResponder 
class RMXFirebaseModel

  include RMXFirebaseSignalHelpers
  
  def self.get(opts=nil)
    new(opts)
  end

  def self.property(name)
    define_method(name) do
      valueForKeyPath(name)
    end
  end

  property :root

  LOADED_KEY = "loaded"
  CHECK_SIGNAL_KEY = "checkSignal"

  attr_accessor :loaded, :checkSignal

  attr_reader :opts

  # readySignal will next true when:
  #   it is ready
  #   it becomes ready
  #   it changes
  #
  attr_reader :readySignal

  # changedSignal will next true when:
  #   it changes
  attr_reader :changedSignal

  def initialize(opts=nil)
    RMX.log_dealloc(self)
    @dep_signals = NSMutableSet.new
    @deps = {}
    @opts = opts

    @checkSignal = RACSignal.never
    
    @readySignal = RACReplaySubject.replaySubjectWithCapacity(1)
    @changedSignal = RMX(self).racObserve("loaded").skip(1).filter(->(s) { s }.weak!)
    @changedSignal.subscribe(@readySignal)

    RMX(self).rac("loaded").signal = RMX(self).racObserve("checkSignal")
    .switchToLatest
    .map(->(s) { check == true }.weak!)

    setup
    check
  end

  def loaded?
    !!@loaded
  end

  def ready?
    loaded? && hasValue?
  end

  def check
    # p "check", RACScheduler.currentScheduler, RMX.mainThread?
    changed = false
    @deps.each_pair do |name, hash|
      opts = hash[:opts]
      # p "check", name, opts
      if model_klass = opts[:model] and keypath = opts[:keypath]
        if model_opts = valueForKeyPath(keypath)
          existing = hash[:value]
          if !existing || existing.opts != model_opts
            if existing
              sig = existing.readySignal
              if @dep_signals.containsObject(sig)
                @dep_signals.removeObject(sig)
                changed = true
                # p "check delete signal", name, opts, sig
              end
            end
            hash[:value] = model_klass.get(model_opts)
          end
        end
      end
      if v = hash[:value]
        sig = v.readySignal
        unless @dep_signals.containsObject(sig)
          @dep_signals.addObject(sig)
          changed = true
          # p "check add signal", name, opts, sig
        end
      end
      # p "check done", name, opts
    end
    if changed
      # p "check send signals", @dep_signals.count
      self.checkSignal = RACSignal.combineLatest(@dep_signals.allObjects)
    end
    changed == false
  end

  def depend(name, opts)
    dep = @deps[name] = {}
    if v = opts.delete(:value)
      dep[:value] = v
    end
    dep[:opts] = opts
  end

  def attr(keypath)
    root.attr(keypath)
  end

  def hasValue?
    root.hasValue?
  end

  def value
    root.value
  end

  def fullValue
    res = @deps.keys.inject({}) do |ret, k|
      if dep = @deps[k]
        if v = dep[:value]
          ret[k] = v.value
        end
      end
      ret
    end
    res
  end

  def setup
    raise "unimplemented: #{className}#setup"
  end

  def hash
    [ className, @opts ].hash
  end

  def isEqual(other)
    hash == other.hash
  end

  alias_method :==, :isEqual
  alias_method :eql?, :isEqual

  def valueForKey(key)
    case key
    when LOADED_KEY
      loaded
    when CHECK_SIGNAL_KEY
      checkSignal
    else
      if d = @deps[key.to_sym]
        d[:value]
      end
    end
  end

  def valueForUndefinedKey(key)
    nil
  end

end
