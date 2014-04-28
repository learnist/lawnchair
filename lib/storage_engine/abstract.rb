module Lawnchair
  module StorageEngine
    class Abstract
      class << self
        attr_reader :data_store

        def data_store
          @data_store ||= {}
        end

        def fetch(key, options={}, &block)
          start_time = Time.now
          if value = get(key, options)
            log("HIT", key, Time.now-start_time)
            return value
          else
            value = block.call
            set(key, value, options)
            log("MISS", key, Time.now-start_time)
            return value
          end
        end

        def get(key, options={})
          raise "Missing key" if key.nil? || key.empty?
          if options[:raw]
            data_store[key]
          else
            value = data_store[key]
            value.nil? ? nil : Marshal.load(value)
          end
        end

        def db_connection?
          true
        end

        def log(message, key, elapsed)
          Lawnchair.redis.hincrby(message, key, 1)
          ActionController::Base.logger.info("Lawnchair Cache: #{message} (%0.6f secs): #{key}" % elapsed) if defined? ::ActionController::Base
        end
      end
    end
  end
end
