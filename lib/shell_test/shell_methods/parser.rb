require 'strscan'

module ShellTest
  module ShellMethods
    class Parser
      attr_reader :ps1
      attr_reader :ps1r
      attr_reader :ps2
      attr_reader :ps2r
      attr_reader :promptr

      def initialize(opts={})
        opts = {
          'PS1' => '$ ',
          'PS2' => '> '
        }.merge(opts)

        @ps1 = opts['PS1']
        @ps1r = /^#{Regexp.escape(@ps1)}/
        @ps2 = opts['PS2']
        @ps2r = /^#{Regexp.escape(@ps2)}/
        @promptr = /(#{@ps1r}|#{@ps2r}|{{(.*?)}})/
      end

      # Parses an input string into steps.
      def parse(str)
        scanner = StringScanner.new(str)

        steps   = []
        last_max_run_time = nil
        while output = scanner.scan_until(promptr)
          match = scanner[1]
          input = scanner[2].to_s + scanner.scan_until(/\n/)

          max_run_time = -1
          input.sub!(/\#\s*\[(\d+(?:\.\d+)?)\]/) do
            max_run_time = $1.to_f
            nil
          end

          case match
          when ps1
            prompt = ps1r
            if max_run_time == -1
              max_run_time = nil
            end
          when ps2
            prompt = ps2r
          else
            output = output.chomp(match)
            start  = output.rindex("\n") || 0
            length = output.length - start
            prompt = /^#{output[start, length]}\z/
          end

          steps << [output, input, prompt, last_max_run_time]
          last_max_run_time = max_run_time
        end

        steps << [scanner.rest, nil, nil, last_max_run_time]
        steps
      end
    end
  end
end