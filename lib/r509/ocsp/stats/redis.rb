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

                    redis.hincrby("stats:" + issuer, status, 1)
                    redis.sadd("stat-keys:issuer", "stats:" + issuer)
                end

                def retrieve
                    issuers = Hash.new{|hash,key| hash[key] = {:valid=>0,:revoked=>0,:unknown=>0,:serials=>[]}}
                    redis.smembers("stat-keys:issuer").each do |key|
                        hits = redis.hgetall(key)
                        issuer = key.gsub("stats:", "")
                        issuers[issuer] = {
                            :valid => hits["VALID"].to_i,
                            :revoked => hits["REVOKED"].to_i,
                            :unknown => hits["UNKNOWN"].to_i,
                            :serials => []
                        }
                        redis.del(key)
                        redis.srem("stat-keys:issuer", key)
                    end

                    redis.smembers("stat-keys:issuer+serial").each do |key|
                        hits = redis.hgetall(key)
                        issuers[hits["issuer"]][:serials] << {
                            :serial => hits["serial"],
                            :valid => hits["VALID"].to_i,
                            :revoked => hits["REVOKED"].to_i,
                            :unknown => hits["UNKNOWN"].to_i
                        }
                        redis.del(key)
                        redis.srem("stat-keys:issuer+serial", key)
                    end

                    issuers
                end
            end
        end
    end
end
