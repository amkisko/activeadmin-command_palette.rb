# frozen_string_literal: true

require "spec_helper"
require_relative "../../usr/bin/license_audit"

RSpec.describe LicenseAudit do
  it "uses installed gem licenses when present" do
    specification = instance_double(Gem::Specification, licenses: ["MIT"])
    allow(Gem::Specification).to receive(:find_by_name).with("example", "1.0.0").and_return(specification)

    expect(described_class.licenses_for("example", "1.0.0")).to eq(["MIT"])
  end

  it "falls back to the remote gemspec when local licenses are unavailable" do
    missing = Gem::MissingSpecError.new("example", Gem::Requirement.new("1.0.0"))
    allow(Gem::Specification).to receive(:find_by_name).and_raise(missing)
    remote_spec = instance_double(Gem::Specification, licenses: ["Apache-2.0"])
    fetcher = instance_double(Gem::SpecFetcher)
    allow(Gem::SpecFetcher).to receive(:new).and_return(fetcher)
    allow(fetcher).to receive(:spec_for_dependency).and_return([[[remote_spec]]])

    expect(described_class.licenses_for("example", "1.0.0")).to eq(["Apache-2.0"])
  end
end
