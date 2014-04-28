module Lawnchair
  module StorageEngine
    class Redis < Abstract
      class << self
        def data_store
          Lawnchair.redis
        end

        def set(key, value, options={})
          ttl   = options[:expires_in] || 3600
          value = Marshal.dump(value) unless options[:raw]

          data_store.set(key, value)
          data_store.expireat(key, (Time.now + ttl).to_i)
        end

        def exists?(key)
          data_store.exists(key)
        end

        def expire!(key)
          start_time = Time.now
          data_store.del(key)
          log("EXPIRATION", key, Time.now-start_time)
        end
      end
    end
  end
end
