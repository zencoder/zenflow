module Zenflow
  module Changelog
    class << self

      def exist?
        File.exist?("CHANGELOG.md")
      end

      def update(options={})
        return unless exist?
        change = prompt_for_change(options)
        if change
          prepend_change_to_changelog("* #{change}", options)
        else
          rotate(:commit => true) if options[:rotate]
        end
        change
      end

      def prompt_for_change(options={})
        required = ' (optional)' if options[:required] == false
        Zenflow::Ask("Add one line to the changelog#{required}:", :required => !(options[:required] == false))
      end

      def prepend_change_to_changelog(change, options={})
        return unless exist?
        new_changes = Zenflow::Shell.shell_escape_for_single_quoting(change)
        prepended_changelog = prepended_changelog(new_changes)
        File.open("CHANGELOG.md", "w") do |f|
          f.write prepended_changelog
        end
        rotate(:name => options[:name]) if options[:rotate]
        Zenflow::Shell["git add CHANGELOG.md && git commit -m 'Adding line to CHANGELOG: #{new_changes}'"]
      end

      def prepended_changelog(new_changes)
        existing_changes, changelog = get_changes

        <<-EOS
#{new_changes}
#{existing_changes}
#{changelog}
        EOS
      end

      def rotate(options={})
        return unless changelog = rotated_changelog(options)
        Zenflow::Log("Managing changelog for version #{Zenflow::Version.current} / #{Time.now.strftime('%Y-%m-%d')} #{"/ " + options[:name] + " " if options[:name]}")

        File.open("CHANGELOG.md", "w") do |f|
          f.write changelog
        end
        Zenflow::Shell["git add CHANGELOG.md && git commit -m 'Rotating CHANGELOG.'"] if options[:commit]
      end

      def rotated_changelog(options={})
        changes, changelog = get_changes
        return if changes.nil?
        <<-EOS
#{changelog}

#{row_name(options[:name])}
#{changes}
        EOS
      end

      def get_changes
        return unless exist?
        changelog = File.read("CHANGELOG.md").strip
        changes = changelog.split("--------------------------------------------------------------------------------")[0]
        changelog = changelog.sub(changes, "") if changes
        return changes.to_s.strip, changelog
      end

      def row_name(name=nil)
        formatted_name = "/ #{name} " if name
        "---- #{Zenflow::Version.current} / #{Time.now.strftime('%Y-%m-%d')} #{formatted_name}".ljust(80, "-")
      end

      def create
        File.open("CHANGELOG.md", "w") do |f|
          f.write changelog_template
        end
      end

      def changelog_template
        <<-EOS
--------------------------------------------------------------------------------
                        ^ ADD NEW CHANGES ABOVE ^
--------------------------------------------------------------------------------

CHANGELOG
=========

        EOS
      end
    end
  end
end
