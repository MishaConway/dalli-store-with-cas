require 'active_support/cache/dalli_store'
require 'dalli/cas/client'

module ActiveSupport
	module Cache
		class DalliStoreWithCas < DalliStore
			DALLI_STORE_WITH_CAS_VERSION = "0.0.3"

			def cas(name, options = {})
				cas_multi(name, options) { |kv| { kv.keys.first => yield(kv.values.first) } }
			end

			def cas_multi(*names, **options)
				return if names.empty?

				namespaced_keys = names.map { |name| namespaced_key(name, options) }
				using_single_cas = 1 == namespaced_keys.size


				instrument_with_log((using_single_cas ? :cas : :cas_multi), names, options) do
					with do |c|
						keys_to_value_and_cas = if using_single_cas
							                        key_value, key_cas = c.get_cas(*namespaced_keys)
							                        { namespaced_keys.first => [key_value, key_cas] } if key_value
							                      else
								                      c.get_multi_cas(*namespaced_keys)
						                        end

						if keys_to_value_and_cas.present?
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
						else
							true
						end
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


