require "spec_helper"
require "dependo"
require "r509/ocsp/stats/redis"

describe R509::Ocsp::Stats::Redis do
    before :each do
        # clear the dependo before each test
        Dependo::Registry.clear
        Dependo::Registry[:log] = Logger.new(nil)

        # we always want to mock with a new redis
        @redis = double("redis")
        Dependo::Registry[:redis] = @redis

        @stats = R509::Ocsp::Stats::Redis.new
    end

    context "valid" do
        it "increments the valid key" do
            @redis.should_receive(:hsetnx).with("stats:my issuer+my serial", "issuer", "my issuer")
            @redis.should_receive(:hsetnx).with("stats:my issuer+my serial", "serial", "my serial")
            @redis.should_receive(:hincrby).with("stats:my issuer+my serial", "VALID", 1)
            @redis.should_receive(:sadd).with("stat-keys:issuer+serial", "stats:my issuer+my serial")

            @redis.should_receive(:hsetnx).with("stats:my issuer", "issuer", "my issuer")
            @redis.should_receive(:hincrby).with("stats:my issuer", "VALID", 1)
            @redis.should_receive(:sadd).with("stat-keys:issuer", "stats:my issuer")

            @stats.record("my issuer", "my serial", "VALID")
        end
    end

    context "revoked" do
        it "increments the revoked key" do
            @redis.should_receive(:hsetnx).with("stats:my issuer+my serial", "issuer", "my issuer")
            @redis.should_receive(:hsetnx).with("stats:my issuer+my serial", "serial", "my serial")
            @redis.should_receive(:hincrby).with("stats:my issuer+my serial", "REVOKED", 1)
            @redis.should_receive(:sadd).with("stat-keys:issuer+serial", "stats:my issuer+my serial")

            @redis.should_receive(:hsetnx).with("stats:my issuer", "issuer", "my issuer")
            @redis.should_receive(:hincrby).with("stats:my issuer", "REVOKED", 1)
            @redis.should_receive(:sadd).with("stat-keys:issuer", "stats:my issuer")

            @stats.record("my issuer", "my serial", "REVOKED")
        end
    end

    context "unknown" do
        it "increments the unknown key" do
            @redis.should_receive(:hsetnx).with("stats:my issuer+my serial", "issuer", "my issuer")
            @redis.should_receive(:hsetnx).with("stats:my issuer+my serial", "serial", "my serial")
            @redis.should_receive(:hincrby).with("stats:my issuer+my serial", "UNKNOWN", 1)
            @redis.should_receive(:sadd).with("stat-keys:issuer+serial", "stats:my issuer+my serial")

            @redis.should_receive(:hsetnx).with("stats:my issuer", "issuer", "my issuer")
            @redis.should_receive(:hincrby).with("stats:my issuer", "UNKNOWN", 1)
            @redis.should_receive(:sadd).with("stat-keys:issuer", "stats:my issuer")

            @stats.record("my issuer", "my serial", "UNKNOWN")
        end
    end

    context "retrieve" do
        it "has no data" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return([])
            @redis.should_receive(:pipelined).and_return([])
            @redis.should_receive(:pipelined)
            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return([])
            @redis.should_receive(:pipelined).and_return([])
            @redis.should_receive(:pipelined)

            results = @stats.retrieve
            results.should == {}
        end

=begin
# I don't know how to test this now that we're using Redis pipelines.
# Does anyone have any bright ideas?

        it "issuer key starts with stats:" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["stats:issuer1"])
            #@redis.should_receive(:pipelined).and_return([{"issuer" => "issuer1", "VALID"=>"1","REVOKED"=>"2","UNKNOWN"=>"3"}])
            @redis.should_receive(:pipelined){
                @redis.should_receive(:hgetall).with("stats:issuer2")
            }.and_return([{"issuer" => "issuer1", "VALID"=>"1","REVOKED"=>"2","UNKNOWN"=>"3"}])
            @redis.should_receive(:pipelined)#{
                #@redis.should_receive(:del).with("stats:issuer1")
                #@redis.should_receive(:srem).with("stat-keys:issuer", "stats:issuer1")
            #}
            #@redis.should_receive(:hgetall).with("stats:issuer1").and_return()

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer1+serial1"])
            @redis.should_receive(:pipelined).and_return([{"issuer" => "issuer1", "serial" => "serial1", "VALID"=>"4","REVOKED"=>"5","UNKNOWN"=>"6"}])
            #@redis.should_receive(:hgetall).with("issuer1+serial1").and_return({"issuer"=>"issuer1","serial"=>"serial1","VALID"=>"4","REVOKED"=>"5","UNKNOWN"=>"6"})
            @redis.should_receive(:pipelined)
            #@redis.should_receive(:del).with("issuer1+serial1")
            #@redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial1")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 1,
                    :revoked => 2,
                    :unknown => 3,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 4,
                            :revoked => 5,
                            :unknown => 6
                        }
                    ]
                }
            }
        end

        it "has 1 issuer and 1 serial, all valid/revoked/unknown are present" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["issuer1"])
            @redis.should_receive(:hgetall).with("issuer1").and_return({"VALID"=>"1","REVOKED"=>"2","UNKNOWN"=>"3"})
            @redis.should_receive(:del).with("issuer1")
            @redis.should_receive(:srem).with("stat-keys:issuer", "issuer1")

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer1+serial1"])
            @redis.should_receive(:hgetall).with("issuer1+serial1").and_return({"issuer"=>"issuer1","serial"=>"serial1","VALID"=>"4","REVOKED"=>"5","UNKNOWN"=>"6"})
            @redis.should_receive(:del).with("issuer1+serial1")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial1")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 1,
                    :revoked => 2,
                    :unknown => 3,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 4,
                            :revoked => 5,
                            :unknown => 6
                        }
                    ]
                }
            }
        end

        it "has a serial with an issuer that wasn't found" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["issuer1"])
            @redis.should_receive(:hgetall).with("issuer1").and_return({"VALID"=>"1","REVOKED"=>"2","UNKNOWN"=>"3"})
            @redis.should_receive(:del).with("issuer1")
            @redis.should_receive(:srem).with("stat-keys:issuer", "issuer1")

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer2+serial1"])
            @redis.should_receive(:hgetall).with("issuer2+serial1").and_return({"issuer"=>"issuer2","serial"=>"serial1","VALID"=>"4","REVOKED"=>"5","UNKNOWN"=>"6"})
            @redis.should_receive(:del).with("issuer2+serial1")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer2+serial1")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 1,
                    :revoked => 2,
                    :unknown => 3,
                    :serials => []
                },
                "issuer2" => {
                    :valid => 0,
                    :revoked => 0,
                    :unknown => 0,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 4,
                            :revoked => 5,
                            :unknown => 6
                        }
                    ]
                }
            }
        end

        it "when the issuer has no valid" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["issuer1"])
            @redis.should_receive(:hgetall).with("issuer1").and_return({"REVOKED"=>"2","UNKNOWN"=>"3"})
            @redis.should_receive(:del).with("issuer1")
            @redis.should_receive(:srem).with("stat-keys:issuer", "issuer1")

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer1+serial1"])
            @redis.should_receive(:hgetall).with("issuer1+serial1").and_return({"issuer"=>"issuer1","serial"=>"serial1","VALID"=>"4","REVOKED"=>"5","UNKNOWN"=>"6"})
            @redis.should_receive(:del).with("issuer1+serial1")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial1")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 0,
                    :revoked => 2,
                    :unknown => 3,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 4,
                            :revoked => 5,
                            :unknown => 6
                        }
                    ]
                }
            }
        end

        it "when the issuer has no revoked" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["issuer1"])
            @redis.should_receive(:hgetall).with("issuer1").and_return({"VALID"=>"1","UNKNOWN"=>"3"})
            @redis.should_receive(:del).with("issuer1")
            @redis.should_receive(:srem).with("stat-keys:issuer", "issuer1")

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer1+serial1"])
            @redis.should_receive(:hgetall).with("issuer1+serial1").and_return({"issuer"=>"issuer1","serial"=>"serial1","VALID"=>"4","REVOKED"=>"5","UNKNOWN"=>"6"})
            @redis.should_receive(:del).with("issuer1+serial1")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial1")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 1,
                    :revoked => 0,
                    :unknown => 3,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 4,
                            :revoked => 5,
                            :unknown => 6
                        }
                    ]
                }
            }
        end

        it "when the issuer has no unknown" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["issuer1"])
            @redis.should_receive(:hgetall).with("issuer1").and_return({"VALID"=>"1","REVOKED"=>"2"})
            @redis.should_receive(:del).with("issuer1")
            @redis.should_receive(:srem).with("stat-keys:issuer", "issuer1")

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer1+serial1"])
            @redis.should_receive(:hgetall).with("issuer1+serial1").and_return({"issuer"=>"issuer1","serial"=>"serial1","VALID"=>"4","REVOKED"=>"5","UNKNOWN"=>"6"})
            @redis.should_receive(:del).with("issuer1+serial1")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial1")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 1,
                    :revoked => 2,
                    :unknown => 0,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 4,
                            :revoked => 5,
                            :unknown => 6
                        }
                    ]
                }
            }
        end

        it "when the serial has no valid" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["issuer1"])
            @redis.should_receive(:hgetall).with("issuer1").and_return({"VALID"=>"1","REVOKED"=>"2","UNKNOWN"=>"3"})
            @redis.should_receive(:del).with("issuer1")
            @redis.should_receive(:srem).with("stat-keys:issuer", "issuer1")

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer1+serial1"])
            @redis.should_receive(:hgetall).with("issuer1+serial1").and_return({"issuer"=>"issuer1","serial"=>"serial1","REVOKED"=>"5","UNKNOWN"=>"6"})
            @redis.should_receive(:del).with("issuer1+serial1")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial1")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 1,
                    :revoked => 2,
                    :unknown => 3,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 0,
                            :revoked => 5,
                            :unknown => 6
                        }
                    ]
                }
            }
        end

        it "when the serial has no revoked" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["issuer1"])
            @redis.should_receive(:hgetall).with("issuer1").and_return({"VALID"=>"1","REVOKED"=>"2","UNKNOWN"=>"3"})
            @redis.should_receive(:del).with("issuer1")
            @redis.should_receive(:srem).with("stat-keys:issuer", "issuer1")

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer1+serial1"])
            @redis.should_receive(:hgetall).with("issuer1+serial1").and_return({"issuer"=>"issuer1","serial"=>"serial1","VALID"=>"4","UNKNOWN"=>"6"})
            @redis.should_receive(:del).with("issuer1+serial1")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial1")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 1,
                    :revoked => 2,
                    :unknown => 3,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 4,
                            :revoked => 0,
                            :unknown => 6
                        }
                    ]
                }
            }
        end

        it "when the serial has no unknown" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["issuer1"])
            @redis.should_receive(:hgetall).with("issuer1").and_return({"VALID"=>"1","REVOKED"=>"2","UNKNOWN"=>"3"})
            @redis.should_receive(:del).with("issuer1")
            @redis.should_receive(:srem).with("stat-keys:issuer", "issuer1")

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer1+serial1"])
            @redis.should_receive(:hgetall).with("issuer1+serial1").and_return({"issuer"=>"issuer1","serial"=>"serial1","VALID"=>"4","REVOKED"=>"5"})
            @redis.should_receive(:del).with("issuer1+serial1")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial1")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 1,
                    :revoked => 2,
                    :unknown => 3,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 4,
                            :revoked => 5,
                            :unknown => 0
                        }
                    ]
                }
            }
        end

        it "when an issuer has 2 serials" do
            @redis.should_receive(:smembers).with("stat-keys:issuer").and_return(["issuer1"])
            @redis.should_receive(:hgetall).with("issuer1").and_return({"VALID"=>"1","REVOKED"=>"2","UNKNOWN"=>"3"})
            @redis.should_receive(:del).with("issuer1")
            @redis.should_receive(:srem).with("stat-keys:issuer", "issuer1")

            @redis.should_receive(:smembers).with("stat-keys:issuer+serial").and_return(["issuer1+serial1","issuer1+serial2"])
            @redis.should_receive(:hgetall).with("issuer1+serial1").and_return({"issuer"=>"issuer1","serial"=>"serial1","VALID"=>"4","REVOKED"=>"5","UNKNOWN"=>"6"})
            @redis.should_receive(:del).with("issuer1+serial1")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial1")

            @redis.should_receive(:hgetall).with("issuer1+serial2").and_return({"issuer"=>"issuer1","serial"=>"serial2","VALID"=>"7","REVOKED"=>"8","UNKNOWN"=>"9"})
            @redis.should_receive(:del).with("issuer1+serial2")
            @redis.should_receive(:srem).with("stat-keys:issuer+serial", "issuer1+serial2")

            results = @stats.retrieve
            results.should == {
                "issuer1" => {
                    :valid => 1,
                    :revoked => 2,
                    :unknown => 3,
                    :serials => [
                        {
                            :serial => "serial1",
                            :valid => 4,
                            :revoked => 5,
                            :unknown => 6
                        },
                        {
                            :serial => "serial2",
                            :valid => 7,
                            :revoked => 8,
                            :unknown => 9
                        }
                    ]
                }
            }
        end
=end
    end
end
