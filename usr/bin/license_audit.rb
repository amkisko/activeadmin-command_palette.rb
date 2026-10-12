#!/usr/bin/env ruby

require "bundler"
require "pathname"
require "rubygems"

module LicenseAudit
  ROOT = Pathname(__dir__).join("../..").expand_path
  MANIFEST = ROOT.join("docs/THIRD_PARTY_LICENSE_MANIFEST.tsv")

  module_function

  def locked_specs_for(gemfile_path)
    gemfile = Pathname(gemfile_path)
    lockfile = gemfile.dirname.join("Gemfile.lock")
    raise "Missing lockfile: #{lockfile}" unless lockfile.exist?

    Bundler::LockfileParser.new(lockfile.read).specs.sort_by(&:name)
  end

  def licenses_from_project_gemspec(gem_name)
    gemspec_path = ROOT.glob("*.gemspec").find { |path| File.basename(path, ".gemspec") == gem_name }
    return [] unless gemspec_path

    Gem::Specification.load(gemspec_path.to_s).licenses
  end

  def installed_licenses(gem_name, version)
    Gem::Specification.find_by_name(gem_name, version.to_s).licenses || []
  rescue Gem::MissingSpecError
    []
  end

  def remote_licenses(gem_name, version)
    spec_fetcher = (@spec_fetcher ||= Gem::SpecFetcher.new)
    dependency = Gem::Dependency.new(gem_name, version.to_s)
    remote_spec = spec_fetcher.spec_for_dependency(dependency).first&.first&.first
    remote_spec&.licenses || []
  end

  def licenses_for(gem_name, version)
    licenses = installed_licenses(gem_name, version)
    return licenses if licenses.any?

    project_licenses = licenses_from_project_gemspec(gem_name)
    return project_licenses if project_licenses.any?

    remote_licenses(gem_name, version)
  end

  def report_progress(bundle_label, index, total, gem_name)
    message = "License audit: #{bundle_label} #{index}/#{total} #{gem_name}"
    if $stderr.tty?
      $stderr.print("\r\e[2K#{message}")
      $stderr.flush
    elsif index == 1 || index == total || (index % 25).zero?
      warn(message)
    end
  end

  def finish_progress
    $stderr.puts if $stderr.tty?
  end

  def rows_for(bundle_label, gemfile_path)
    specs = locked_specs_for(gemfile_path)
    total = specs.size

    specs.map.with_index(1) do |spec, index|
      report_progress(bundle_label, index, total, spec.name)
      [bundle_label, spec.name, spec.version.to_s, licenses_for(spec.name, spec.version).join("|")]
    end
  end

  def manifest_rows
    rows = [["bundle", "gem", "version", "licenses"]]
    rows.concat(rows_for("root", ROOT.join("Gemfile")))

    demo_gemfile = ROOT.join("examples/rails_demo/Gemfile")
    rows.concat(rows_for("rails_demo", demo_gemfile)) if demo_gemfile.exist?
    rows
  end

  def write_manifest
    rows = manifest_rows
    finish_progress

    MANIFEST.dirname.mkpath
    MANIFEST.write(rows.map { |row| row.join("\t") }.join("\n") + "\n")
    puts "Wrote #{MANIFEST}"
  end
end

LicenseAudit.write_manifest if $PROGRAM_NAME == __FILE__
