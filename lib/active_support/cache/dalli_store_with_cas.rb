require 'active_support/cache/dalli_store'
require 'dalli/cas/client'

module ActiveSupport
	module Cache
		class DalliStoreWithCas < DalliStore
			DALLI_STORE_WITH_CAS_VERSION = "0.0.1"

			def cas(name, options = {})
				return cas_multi(name, options){ |kv| { kv.keys.first => yield(kv.values.first) } }

				name = namespaced_key(name, options)
				expiry = expiration(options)

				key_existed, was_updated = instrument_with_log(:cas_core_with_existence, name, expiry) do
					with do |c|
						c.cas_core_with_existence(name, true, expiry) do |raw_value|
							value = yield raw_value
							value
						end
					end
				end

				key_existed && was_updated
			end

			def cas_multi(*names, **options)
				return if names.empty?

				keys_to_names = Hash[names.map { |name| [namespaced_key(name, options), name] }]

				instrument_with_log(:cas_multi, names, options) do
					with do |c|
						keys_to_value_and_cas = c.get_multi_cas(keys_to_names.keys)

						values_to_yield = keys_to_value_and_cas.map do |key, value_and_cas|
							[key, value_and_cas.first]
						end.to_h
						new_values = yield values_to_yield

						successfully_updated_values = {}
						found_corresponding_key = false

						new_values.each do |k, v|
							value_and_cas = keys_to_value_and_cas[k]
							if value_and_cas
								found_corresponding_key = true
								current_cas = value_and_cas.last
								if c.set_cas(k, v, current_cas, nil, options)
									successfully_updated_values[k] = v
								end
							end
						end

						!found_corresponding_key || successfully_updated_values.present?
					end
				end

			rescue Dalli::DalliError => e
				log_dalli_error(e)
				instrument_error(e) if instrument_errors?
				raise if raise_errors?
				false
				


			end
		end
	end
end

module Dalli
	class Client

		def cas_core_with_existence(key, always_set, ttl=nil, options=nil)
			puts "inside cas_core_with_existence and always set is #{always_set}"

			(value, cas) = perform(:cas, key)
			value = (!value || value == 'Not found') ? nil : value

			puts "made it to part blah"

			key_does_not_exist = value.nil?
			return !key_does_not_exist, false if key_does_not_exist && !always_set

			puts "made it to part blah 2"


			newvalue = yield(value)
			puts "setting newvalue of #{newvalue}"
			puts "key does not exist here is #{key_does_not_exist}"
			perform_result = perform(:set, key, newvalue, ttl_or_default(ttl), cas, options)

			puts "perfor result is #{perform_result}"

			return !key_does_not_exist, perform_result
		end

	end
end
