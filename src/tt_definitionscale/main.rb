require 'sketchup.rb'

require 'tt_definitionscale/debug'

module TT::Plugins::DefinitionScale

  # @param [Numeric] scale
  def self.scale_selected_definitions(scale)
    model = Sketchup.active_model
    return if model.nil?

    components = model.selection.grep(Sketchup::ComponentInstance)
    groups = model.selection.grep(Sketchup::Group)
    definitions = (components + groups).map(&:definition)
    return if definitions.empty?

    direction_name = scale < 0 ? 'Down' : 'Up'
    operation_name = "Scale #{direction_name} (#{scale}x)"

    s = scale < 0 ? 1.0 / scale : scale
    definition_transformation = Geom::Transformation.scaling(s, s, s)
    instance_transformation = definition_transformation.inverse

    model.start_operation(operation_name, true)
    definitions.each { |definition|
      definition.entities.transform_entities(definition_transformation, definition.entities.to_a)
      definition.instances.each { |instance|
        instance.transform!(instance_transformation)
      }
    }
    model.commit_operation
  end

  unless file_loaded?(__FILE__)
    cmd = UI::Command.new('Scale Up (10x)') {
      self.scale_selected_definitions(10)
    }
    cmd_scale_up_10 = cmd

    cmd = UI::Command.new('Scale Down (10x)'){
      self.scale_selected_definitions(-10)
    }
    cmd_scale_down_10 = cmd

    menu = UI.menu('Plugins').add_submenu(EXTENSION[:name])
    menu.add_item(cmd_scale_up_10)
    menu.add_item(cmd_scale_down_10)

    menu_position = 20 # TODO: Set based on SketchUp 2021, Windows

    UI.add_context_menu_handler do |context_menu|
      model = Sketchup.active_model
      next if model.nil?

      show_menu = model.selection.size > 10_000
      show_menu ||= model.selection.grep(Sketchup::ComponentInstance).empty?
      show_menu ||= model.selection.grep(Sketchup::Group).empty?
      next if !show_menu

      menu = context_menu.add_submenu(EXTENSION[:name], menu_position)
      menu.add_item(cmd_scale_up_10)
      menu.add_item(cmd_scale_down_10)
    end

    file_loaded(__FILE__)
  end

end # module
