# frozen_string_literal: true

require "test_helper"

module Primer
  module Alpha
    class ActionListTest < Minitest::Test
      include Primer::ComponentTestHelpers

      def test_list
        render_preview(:list)
      end

      def test_lists
        render_preview(:lists)
      end

      def test_item
        render_preview(:item)
      end

      def test_divider
        render_preview(:divider)
      end

      def test_heading
        render_preview(:heading)
      end

      def test_item_with_leading_icon
        render_preview(:item, params: { leading_visual_icon: "arrow-down" })

        assert_selector(".octicon-arrow-down")
      end
    end
  end
end
