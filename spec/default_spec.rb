require "r509/ocsp/stats/default"

describe R509::Ocsp::Stats::Default do
    before :all do
        @stats = R509::Ocsp::Stats::Default.new
    end

    context "valid" do
        it "does nothing" do
            @stats.record("issuer", "serial", "VALID")
        end
    end

    context "revoked" do
        it "does nothing" do
            @stats.record("issuer", "serial", "REVOKED")
        end
    end

    context "unknown" do
        it "does nothing" do
            @stats.record("issuer", "serial", "UNKNOWN")
        end
    end

    context "retrieve" do
        it "does nothing, should be empty" do
            result = @stats.retrieve
            result.should == {}
        end
    end
end
