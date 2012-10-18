require "dependo"
require "r509/ocsp/stats/default"

module R509
    module Ocsp
        module Stats
            class Redis < R509::Ocsp::Stats::Default
                include Dependo::Mixin

                def record(issuer, serial, status)
                    key = "stats:" + issuer + "+" + serial

                    redis.hsetnx(key, "issuer", issuer)
                    redis.hsetnx(key, "serial", serial)
                    redis.hincrby(key, status, 1)
                    redis.sadd("stat-keys:issuer+serial", key)

                    redis.hsetnx("stats:" + issuer, "issuer", issuer)
                    redis.hincrby("stats:" + issuer, status, 1)
                    redis.sadd("stat-keys:issuer", "stats:" + issuer)
                end

                def retrieve
                    issuers = Hash.new{|hash,key| hash[key] = {:valid=>0,:revoked=>0,:unknown=>0,:serials=>[]}}
                    issuer_keys = redis.smembers("stat-keys:issuer")
                    issuer_results = redis.pipelined do
                        issuer_keys.each do |key|
                            redis.hgetall(key)
                        end
                    end
                    issuer_results.each do |hits|
                        if hits.has_key?("issuer")
                            issuer = hits["issuer"]
                        else
                            issuer = "?"
                        end
                        issuers[issuer] = {
                            :valid => hits["VALID"].to_i,
                            :revoked => hits["REVOKED"].to_i,
                            :unknown => hits["UNKNOWN"].to_i,
                            :serials => []
                        }
                    end
                    redis.pipelined do
                        issuer_keys.each do |key|
                            redis.del(key)
                            redis.srem("stat-keys:issuer", key)
                        end
                    end

                    serial_keys = redis.smembers("stat-keys:issuer+serial")
                    serial_results = redis.pipelined do
                        serial_keys.each do |key|
                            redis.hgetall(key)
                        end
                    end
                    serial_results.each do |hits|
                        issuers[hits["issuer"]][:serials] << {
                            :serial => hits["serial"],
                            :valid => hits["VALID"].to_i,
                            :revoked => hits["REVOKED"].to_i,
                            :unknown => hits["UNKNOWN"].to_i
                        }
                    end
                    redis.pipelined do
                        serial_keys.each do |key|
                            redis.del(key)
                            redis.srem("stat-keys:issuer+serial", key)
                        end
                    end

                    issuers
                end
            end
        end
    end
end
