# frozen_string_literal: true

class PromptDiffer
  class << self
    def call(old_text, new_text, old_title: nil, new_title: nil)
      old_lines = split_lines(old_text.to_s)
      new_lines = split_lines(new_text.to_s)

      diff_lines = compute_lcs_diff(old_lines, new_lines)

      additions = diff_lines.count { |l| l[:type] == :added }
      deletions = diff_lines.count { |l| l[:type] == :removed }
      unchanged = diff_lines.count { |l| l[:type] == :unchanged }

      {
        title_changed: old_title.present? && new_title.present? && old_title != new_title,
        old_title: old_title,
        new_title: new_title,
        lines: diff_lines,
        stats: {
          additions: additions,
          deletions: deletions,
          unchanged: unchanged
        }
      }
    end

    private

    def split_lines(text)
      return [] if text.empty?

      text.split(/\r?\n/, -1)
    end

    def compute_lcs_diff(old_lines, new_lines)
      m = old_lines.length
      n = new_lines.length

      dp = Array.new(m + 1) { Array.new(n + 1, 0) }

      (m - 1).downto(0) do |i|
        (n - 1).downto(0) do |j|
          dp[i][j] = if old_lines[i] == new_lines[j]
            1 + dp[i + 1][j + 1]
          else
            dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]
          end
        end
      end

      result = []
      i = 0
      j = 0
      old_ln = 1
      new_ln = 1

      while i < m && j < n
        if old_lines[i] == new_lines[j]
          result << {
            type: :unchanged,
            old_line_number: old_ln,
            new_line_number: new_ln,
            content: old_lines[i]
          }
          i += 1
          j += 1
          old_ln += 1
          new_ln += 1
        elsif dp[i + 1][j] >= dp[i][j + 1]
          result << {
            type: :removed,
            old_line_number: old_ln,
            new_line_number: nil,
            content: old_lines[i]
          }
          i += 1
          old_ln += 1
        else
          result << {
            type: :added,
            old_line_number: nil,
            new_line_number: new_ln,
            content: new_lines[j]
          }
          j += 1
          new_ln += 1
        end
      end

      while i < m
        result << {
          type: :removed,
          old_line_number: old_ln,
          new_line_number: nil,
          content: old_lines[i]
        }
        i += 1
        old_ln += 1
      end

      while j < n
        result << {
          type: :added,
          old_line_number: nil,
          new_line_number: new_ln,
          content: new_lines[j]
        }
        j += 1
        new_ln += 1
      end

      result
    end
  end
end
