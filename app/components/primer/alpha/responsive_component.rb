# frozen_string_literal: true

module Primer
  module Alpha
    # Base class for Responsive Components
    class ResponsiveComponent < Primer::BaseComponent
      extend ActionView::Helpers::TagHelper
      extend Primer::Responsive::HtmlAttributesHelper
      extend Primer::Responsive::ArgumentsDefinitionHelper
      extend Primer::Responsive::StyleClassMapHelper

      attr_reader :argument_values, :html_attributes

      # class instance variables
      @strictly_allowed_html_attributes = nil
      @added_allowed_html_attributes = nil
      @arguments = nil
      @style_map = nil

      # Declares a list of exclusively allowed HTML attributes to be used when validating/sanitizing the attributes
      def self.allowed_html_attributes(*allowed_html_attributes)
        allowed_html_attributes = allowed_html_attributes.flatten if allowed_html_attributes.is_a? Array
        @strictly_allowed_html_attributes = allowed_html_attributes
      end

      # Declares a list of additional allowed HTML attributes to be used when validating/sanitizing the attributes
      # The base allowed list can be found in Primer::Responsive::HtmlAttributesHelper
      def self.additional_allowed_html_attributes(*additional_allowed_html_attributes)
        additional_allowed_html_attributes.flatten! if additional_allowed_html_attributes.is_a? Array
        @added_allowed_html_attributes = additional_allowed_html_attributes
      end

      # Defines all arguments part of the component args API
      def self.arguments_definition(all_arguments_definition)
        @arguments = arguments_definition_builder(all_arguments_definition)
      end

      # Adds argument definitions to the componennt args API
      # To be used in child components that want to reuse its parent's argument definitions
      # - if an argument with the same name is added, it'll overwrite the parent's argument definition
      # NOTE: favor composition over inheritance when creating components whenever possible.
      #       This method is supposed to be used with "abstract" or "base" parent component classes
      def self.add_arguments_definition(new_arguments_definition)
        new_arguments = arguments_definition_builder(new_arguments_definition)
        @arguments = !superclass.respond_to?(:arguments) || superclass.arguments.nil? ? new_arguments : { **superclass.arguments, **new_arguments }
      end

      # Declares the class map of a component.
      # NOTE: It'll overwrite the current class map if it already exists
      #
      # @param general [Hash] map without responsive support
      # @param responsive [Hash] replaces the map with its responsive variants
      # @param with_responsive [Hash] adds responsive variants to the hash map while keeping its original structure
      def self.style_class_map(general: {}, responsive: {}, with_responsive: {})
        @style_map = general.present? ? { **general } : {}
        @style_map.deep_merge!(add_responsive_variants(responsive, remove_initial: true)) if responsive.present?
        @style_map.deep_merge!(add_responsive_variants(with_responsive)) if with_responsive.present?

        @style_map.freeze
      end

      # Adds style map to the parent style map if it exists
      # To be used in child components that want to reuse its parent's style map
      #
      # @param general [Hash] map without responsive support
      # @param responsive [Hash] replaces the map with its responsive variants
      # @param with_responsive [Hash] adds responsive variants to the map while keeping its original structure
      def self.add_style_class_map(general: {}, responsive: {}, with_responsive: {})
        existing_style_map = superclass.respond_to?(:style_map) && !superclass.style_map.nil? ? superclass.style_map : {}
        existing_style_map = existing_style_map.deep_merge(@style_map) if @style_map.present?

        @style_map = { **existing_style_map }
        @style_map.deep_merge!(general) if general.present?
        @style_map.deep_merge!(add_responsive_variants(responsive, remove_initial: true)) if responsive.present?
        @style_map.deep_merge!(add_responsive_variants(with_responsive)) if with_responsive.present?

        @style_map.freeze
      end

      class << self
        attr_accessor :arguments, :style_map, :strictly_allowed_html_attributes, :added_allowed_html_attributes
      end

      # @param argument_values: [Hash] component argument values
      # @param html_attributes: [Hash] html_attributes to be added to the component root element
      #
      # NOTE: use a argument named :tag to support custom tags, since the definition can also be used to valid what tags are allowed
      def initialize(argument_values: {}, html_attributes: {})
        @argument_values = argument_values
        @html_attributes = html_attributes

        validate_html_attributes if should_raise_error?
        sanitize_html_attributes!

        tag = argument_values.fetch(:tag, nil)
        super(tag: tag)

        @html_attributes[:"data-view-component"] = true
        @html_attributes = add_test_selector(@html_attributes)

        # support for the old Primer behavior
        return unless @html_attributes.key? :classes

        @html_attributes[:class] = @html_attributes[:classes]
        @html_attributes.delete(:classes)
      end

      # Validate html attributes
      def validate_html_attributes(html_attributes = nil)
        html_attributes = @html_attributes if html_attributes.nil?

        unless self.class.strictly_allowed_html_attributes.nil?
          self.class.strict_validate_html_attributes(html_attributes, allowed_attributes: self.class.strictly_allowed_html_attributes)
          return
        end

        self.class.validate_html_attributes(html_attributes, additional_allowed_attributes: self.class.added_allowed_html_attributes || [])
      end

      # Sanitizes @html_attributes or a custom html_attributes, if provided
      def sanitize_html_attributes(html_attributes = nil)
        html_attributes = @html_attributes if html_attributes.nil?

        unless self.class.strictly_allowed_html_attributes.nil?
          return self.class.strict_sanitize_html_attributes(
            html_attributes,
            allowed_attributes: self.class.strictly_allowed_html_attributes
          )
        end

        self.class.sanitize_html_attributes(
          html_attributes,
          additional_allowed_attributes: self.class.added_allowed_attributes
        )
      end

      # Sanitizes and updates @html_attributes
      def sanitize_html_attributes!
        @html_attributes = sanitize_html_attributes(@html_attributes)
      end

      # @param html_attibutes [Hash] defaults to instance @html_attributes
      def render_html_attributes(html_attributes = nil)
        html_attributes = @html_attributes if html_attributes.nil?
        self.class.tag.attributes(html_attributes)
      end

      # Normalizes the argument_values by component arguments_definition
      def normalize_values(argument_values: {}, fallback_to_default: true)
        self.class.normalize_argument_values!(
          arguments_definition: self.class.arguments,
          argument_values: argument_values,
          fallback_to_default: fallback_to_default || Primer::Responsive::ArgumentsDefinitionHelper.production_env?
        )
      end

      # Normalizes and updates the argument_values by component arguments_definition
      def normalize_values!(fallback_to_default: true)
        @argument_values = normalize_values(
          argument_values: @argument_values,
          fallback_to_default: fallback_to_default
        )
      end

      def validate_values(argument_values = nil)
        argument_values = @argument_values if argument_values.nil?
        self.class.validate_argument_values(
          arguments_definition: self.class.arguments,
          argument_values: argument_values
        )
      end

      def style_class_map
        self.class.style_map
      end

      def filtered_style_class_map!(force_recalculation: false)
        @filtered_map unless @filtered_map.nil? || force_recalculation

        @filtered_map = filter_style_class_map(@argument_values)
      end

      def filter_style_class_map(argument_values = nil)
        {} if self.class.style_map.nil?

        argument_values = @argument_values if argument_values.nil?
        self.class.apply_values_to_style_map(self.class.style_map, argument_values)
      end
    end
  end
end
