# frozen_string_literal: true

require "spec_helper"
require "open3"
require_relative "../../usr/lib/release_version_check"

RSpec.describe ReleaseVersionCheck do
  describe ".confirmation_accepted?" do
    it "accepts an explicit yes or an interactive default" do
      expect(described_class.confirmation_accepted?("y\n")).to be(true)
      expect(described_class.confirmation_accepted?("Y\n")).to be(true)
      expect(described_class.confirmation_accepted?("\n")).to be(true)
    end

    it "rejects EOF and other answers" do
      expect(described_class.confirmation_accepted?(nil)).to be(false)
      expect(described_class.confirmation_accepted?("n\n")).to be(false)
    end
  end

  describe "release confirmation process boundary" do
    let(:bootstrap) do
      <<~RUBY
        require_relative "usr/lib/release_version_check"
        module ReleaseVersionCheck
          def self.warn_if_already_released(**); end
          def self.require_changelog_version!(**); end
        end
        Kernel.prepend(Module.new do
          def system(*command)
            puts "EXEC:\#{command.last}"
            true
          end

          def `(command)
            ""
          end
        end)
        load "usr/bin/release.rb"
      RUBY
    end

    it "refuses to publish when standard input ends without an answer" do
      output, error, status = Open3.capture3(Gem.ruby, "-e", bootstrap, stdin_data: "")

      aggregate_failures do
        expect(status.exitstatus).to eq(1), error
        expect(output).not_to include("EXEC:gem push")
      end
    end

    it "accepts the displayed default after an explicit Enter" do
      output, error, status = Open3.capture3(Gem.ruby, "-e", bootstrap, stdin_data: "\n")

      aggregate_failures do
        expect(status).to be_success, error
        expect(output).to include("EXEC:gem push")
      end
    end
  end
end
