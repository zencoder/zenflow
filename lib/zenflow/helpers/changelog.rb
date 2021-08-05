module Zenflow
  # Changelog manipulation
  module Changelog
    class << self
      def exist?
        File.exist?("CHANGELOG.md")
      end

      def update(options = {})
        return unless exist?

        change = prompt_for_change(options)
        if change
          prepend_change_to_changelog("* #{change}", options)
        elsif options[:rotate]
          rotate(commit: true)
        end
        change
      end

      def prompt_for_change(options = {})
        required = ' (optional)' if options[:required] == false
        Zenflow::Requests.ask(
          "Add one line to the changelog#{required}:",
          required: options[:required] != false
        )
      end

      def prepend_change_to_changelog(change, options = {})
        return unless exist?

        new_changes = Zenflow::Shell.shell_escape_for_single_quoting(change)
        prepended_changelog = prepended_changelog(new_changes)
        File.open("CHANGELOG.md", "w") do |f|
          f.write prepended_changelog
        end
        rotate(name: options[:name]) if options[:rotate]
        Zenflow::Shell["git add CHANGELOG.md && git commit -m 'Adding line to CHANGELOG: #{new_changes}'"]
      end

      def prepended_changelog(new_changes)
        existing_changes, changelog = changes

        <<~CHANGELOG
          #{new_changes}
          #{existing_changes}
          #{changelog}
        CHANGELOG
      end

      def rotate(options = {})
        return unless changelog = rotated_changelog(options)

        append_line = "/#{options[:name]} " if options[:name]
        timestamp = "#{Zenflow::Version.current} / #{Time.now.strftime('%Y-%m-%d')}"

        Zenflow::Log("Managing changelog for version #{timestamp} #{append_line}")

        File.open("CHANGELOG.md", "w") do |f|
          f.write changelog
        end
        Zenflow::Shell["git add CHANGELOG.md && git commit -m 'Rotating CHANGELOG.'"] if options[:commit]
      end

      def rotated_changelog(options = {})
        changes_str, changelog = changes
        return if changes_str.nil?

        <<~CHANGELOG
          #{changelog}

          #{row_name(options[:name])}
          #{changes_str}
        CHANGELOG
      end

      def changes
        return unless exist?

        changelog = File.read("CHANGELOG.md").strip
        changes = changelog.split('-'.ljust(80, '-'))[0]
        changelog = changelog.sub(changes, "") if changes

        [changes.to_s.strip, changelog]
      end

      def row_name(name = nil)
        formatted_name = "/ #{name} " if name
        "---- #{Zenflow::Version.current} / #{Time.now.strftime('%Y-%m-%d')} #{formatted_name}".ljust(80, "-")
      end

      def create
        File.open("CHANGELOG.md", "w") do |f|
          f.write changelog_template
        end
      end

      def changelog_template
        <<~CHANGE
          --------------------------------------------------------------------------------
            ^ ADD NEW CHANGES ABOVE ^
          --------------------------------------------------------------------------------

            CHANGELOG
          =========

        CHANGE
      end
    end
  end
end
