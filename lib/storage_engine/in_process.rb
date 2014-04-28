module Lawnchair
  module StorageEngine
    class InProcess < Abstract
      @@data_store = {}
      class << self

        def data_store
          @@data_store
        end

        def set(key, value, options={})
          if options[:raw]
            data_store[key] = value
          else
            data_store[key] = Marshal.dump(value)
          end
        end

        def exists?(key)
          data_store.has_key?(key)
        end

        def expire!(key)
          start_time = Time.now
          data_store.delete(key)
          log("EXPIRATION", key, Time.now-start_time)
        end
      end
    end
  end
end
